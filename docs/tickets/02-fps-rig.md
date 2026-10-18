# Mains et avant-bras du ticket 2

Le contrôleur utilise deux mains gantées et deux bras déformés par un `Skeleton3D`. Les armes ne contiennent plus les anciennes mains fusionnées. Les matériaux des bras sont mats, non métalliques et sans émission. Le clic droit rapproche la prise. Il ne modifie ni la précision, ni le champ de vision. L'ADS complet appartient au ticket 7.

## Propriété et repères

`SiloPlayer` conserve les déplacements, la caméra, les raycasts, les ressources, le délai de tir et l'unique horloge de recharge. Il réutilise `SiloFpsRig.ViewFrame`, avec une pose `REST`, `RUN` ou `AIM`, la progression de recharge, le recul et le mouvement de marche.

`SiloFpsRig` possède les transforms des bras, des armes et de la bouche. L'arme logique et le modèle visible changent immédiatement ensemble. La main gauche suit une trajectoire de dégagement de 0,22 seconde. Le tir n'attend pas cette transition. La mort, la désactivation et la téléportation restaurent la prise courante.

Les modèles exposent `GripRight`, `GripLeft` et `Muzzle`. L'échelle 0,76 et le décalage historique restent sur le modèle d'arme. Le montage sous `BoneAttachment3D` utilise l'inverse du repère droit déjà transformé par le modèle, avec sa base orthonormalisée. Il conserve donc l'échelle de géométrie sans la compenser deux fois. Le rig résout main droite, montage, main gauche et bouche dans le même appel.

Les bras mesurent 0,32 m et les avant-bras 0,30 m. Le solveur place le coude vers le bas et l'extérieur. Une cible inaccessible échoue à la calibration et laisse les os dans leur pose précédente. Elle n'étire pas les segments.

## Géométrie originale

Le modèle est construit une fois au démarrage par sections elliptiques. La manche continue jusqu'à l'épaule, hors du cadre FPS. Les sections de manche et de gant se rejoignent au même anneau. Les poids mélangent avant-bras et main autour du poignet. Les quatre doigts ont des longueurs distinctes. Le pouce est opposé et la main droite présente son index vers la détente.

Le squelette contient 35 os.

| Côté | Bras | Avant-bras | Main | Phalanges des quatre doigts | Pouce |
|---|---|---|---|---|---|
| Droit | 1 | 2 | 3 | 4 à 15 | 16 et 17 |
| Gauche | 18 | 19 | 20 | 21 à 32 | 33 et 34 |

L'os 0 est la racine. Les deux bras réunis comptent 1 564 sommets, 2 400 triangles et deux surfaces. Le budget est de 24 000 sommets, 16 000 triangles et 48 os. L'arme visible ajoute cinq surfaces. Aucune géométrie ni aucun matériau n'est reconstruit pendant `update_visual()`.

L'ARC possède une poignée de support reliée au corps sous le canon. Un rayon depuis la paume gauche vérifie un contact avec les triangles réels de ce support, en plus des tests de marqueurs.

La poignée commune a été ramenée à 4,94 cm de large et 10,26 cm de haut pour correspondre aux mains. Les dimensions des armes n'influencent pas les raycasts de dégâts. Le contrôle géométrique a aussi révélé des triangles dégénérés dans les anciens petits biseaux. Leur rayon de coin est maintenant borné par la section disponible.

## Vérifications reproductibles

```bash
./tools/verify.sh
DISPLAY=:97 python3 tools/prove_fps_rig.py --video --inspect
DISPLAY=:97 python3 tools/prove_fps_rig.py --measure --baseline .cstack/issue-02/baseline-source --runs 5
```

Le troisième appel attend une copie de la base `30ce44768d45d976d45f51caa2503cece08e23c1`, importée par le même Godot, avec `tools/probe_fps_rig.gd` copié depuis la branche courante. Les preuves locales se trouvent dans `.cstack/issue-02/proof/`. Le script enregistre les empreintes SHA256 des sources, la résolution, le backend, les sorties Godot et les mesures brutes.

Les huit suites vérifient les régressions de gameplay et le nouveau rig. Le test de rig échantillonne 186 états de pose, recharge et recul pour les deux armes. Il vérifie contacts à 2 mm et 2 degrés, longueurs constantes, origine de bouche dans le même tick, changements répétés, interruptions et refus d'une cible impossible. Le contrôle géométrique parcourt récursivement toutes les surfaces et vérifie indices, normales, triangles, poids normalisés et indices d'os.

Le test initial échouait sur les six marqueurs absents avant l'implémentation. Le contrôle des triangles a échoué avant la correction des biseaux. Un test a ensuite reproduit une progression de recharge visuelle périmée dans le tick du changement d'arme. La correction remet cette progression à -1 dans l'annulation autoritaire. Les assertions de visée et d'annulation du nouveau rig ont été ajoutées après leur implémentation. Elles fournissent une preuve de régression, pas une preuve complète de développement test-first.

La vidéo utilise le jeu et les vraies actions du contrôleur. Elle montre chaque arme au repos, en marche, en course, en visée, au tir et lors de changements rapides. Le D9 effectue sa recharge temporisée existante. L'ARC refuse cette recharge et consomme 12 points d'énergie au tir. Les manipulations de chargeur et de cellule restent aux tickets 3 et 4. Des captures en maintenance montrent aussi les gants dans une zone plus sombre.

## Limites des mesures

La scène comparée est l'ascenseur, à 1 280 × 720, en qualité normale, sous Godot 4.7.2 Compatibility. Le serveur utilise llvmpipe. Il n'y a aucune mesure de GPU matériel ni preuve d'exécution Windows.

La comparaison avant/après conserve tout le jeu visible. Le masque des mains est disponible uniquement sur le nouveau rig. Il masque les deux surfaces skinnées, conserve les armes et continue les mises à jour de squelette. Le temps `rig_update_call_p50_ms` mesure un appel CPU à `update_visual()`. Il ne mesure pas le CPU total d'une image de gameplay à 60 Hz. Les temps d'image incluent le rendu logiciel et l'attente du pilote. Ils ne constituent pas des temps GPU.

Cinq exécutions par version ont alterné avant puis après, sans enregistrement vidéo concurrent. La médiane du temps d'image ne montre pas de différence mesurable au regard de la dispersion des runs.

| Scène | Médiane des p50 | Étendue des p50 | Appels de dessin | Triangles |
|---|---|---|---|---|
| Base visible | 95,148 ms | 92,181 à 99,748 ms | 326 | 52 576 |
| Nouveau rig visible | 94,056 ms | 91,775 à 100,840 ms | 327 | 54 080 |
| Nouveau rig, mains masquées | 95,172 ms | 89,367 à 96,824 ms | 325 | 51 680 |

Un appel de mise à jour du rig prend une médiane de 0,118 ms, avec des médianes par run de 0,115 à 0,131 ms. Le masque retire exactement deux appels de dessin et 2 400 triangles. Il ne démontre aucun gain de temps d'image dans ces runs. Ces résultats concernent le rendu logiciel d'une seule scène. Ils ne remplacent pas le benchmark global ni une validation à 60 FPS sur matériel cible.

Les empreintes des sources par run sont dans `proof/measurements.json`. Le commit de départ était `30ce447`, avec la modification locale enregistrée par ces empreintes. Les mesures ne doivent pas être présentées comme des résultats du code inchangé de ce commit.

Les images, la vidéo et les contrôles géométriques sont des critères distincts. Les écarts de prise mesurés ne prouvent pas l'absence de pénétration. La qualité anatomique reste soumise à la revue visuelle indépendante du ticket.
