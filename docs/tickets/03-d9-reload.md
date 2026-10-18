# Ticket 3 : rechargement du D9

Le D9 montre maintenant la prise du chargeur, son extraction, son rangement sous le cadre, l'insertion, puis le retour à la prise normale. À vide, la main gauche tire et libère la culasse avant de revenir au support. Les deux pièces possèdent leurs propres meshes. Le canon reste fixe.

[Vidéo avec le son du moteur](media/03/d9-reload.mp4) · [Repos FPS](media/03/rest.png) · [Extraction](media/03/extraction.png) · [Culasse vue de côté](media/03/slide-side.png)

La vidéo est une capture déterministe du moteur à 30 images par seconde, pas une mesure de fluidité temps réel. Elle dure 18,27 secondes et montre les scénarios partiel, vide, interrompu par changement d'arme et interrompu par pause après insertion, puis la reprise. Les compteurs et les phases viennent du joueur réellement exécuté. Les quantités initiales sont des données de test.

## Règles du jeu

| Situation | Résultat |
| --- | --- |
| Chargeur partiel | Geste de 2,60 s, sans manipulation de culasse |
| Chargeur vide | Geste de 3,25 s avec réarmement |
| Fin du retour de main | Transfert unique `min(12 - ammo, reserve)` |
| Tir pendant la manipulation ou son annulation | Refus sans consommation |
| Changement d'arme pendant la manipulation | La pose courante descend, les pièces sont restaurées hors cadre, puis l'arme demandée remonte |
| Nouvelle destination avant la sortie du cadre | La dernière demande remplace la destination |
| Nouvelle destination pendant la remontée | La remontée termine, puis une nouvelle descente précède l'équipement |
| Pause, mort ou téléportation | Annulation sans transfert. La pause réelle fige la pose jusqu'à la reprise |
| Désactivation sans pause globale | La sortie continue et attend sous le cadre, y compris si elle interrompt une remontée |
| Sauvegarde pendant le geste | Seuls les compteurs déjà validés sont sauvegardés. Le chargement recrée un D9 prêt |

`D9Reload` possède l'horloge et les événements de manipulation. `SiloPlayer` reste seul auteur des munitions. `FpsRig.ViewFrame` transmet la vue réutilisée au rig. La main droite garde l'arme; la main gauche suit la prise de la pièce active. Les durées sont dans `data/weapons/d9.tres`.

Le son de manipulation dispose d'un lecteur précréé indépendant du tir et des dégâts. Retrait, insertion, traction et libération ont quatre sons synthétisés distincts. Un grand delta conserve l'ordre des événements et joue seulement le dernier son encore pertinent. Une annulation arrête le lecteur.

## Vérification

Les quatorze suites de `./tools/verify.sh` passent sur cette version. Le parcours de mission atteint 184,2 m, 15 tirs et 77 points de santé, sans échec.

Les [journaux de tests](media/03/test-evidence.txt) contiennent les rouges conservés et les résultats verts. Ils couvrent les ressources, les refus de tir sans effet de cooldown, les grands deltas, les changements de destination, les interruptions, les sons distincts et le déplacement des pièces.

Le test de scène principale utilise un vrai joueur. Il ouvre la pause pendant l'extraction, attend avec l'arbre suspendu, reprend, puis sauvegarde et charge avant et après le transfert. Il modifie les compteurs après chaque sauvegarde et vérifie le remplacement du joueur pour éviter qu'un chargement inactif fasse réussir le test. Cent cycles complets, alternativement vides et partiels, conservent le nombre de nœuds et les mêmes ressources de mesh.

Le parcours géométrique échantillonne 651 poses. Il vérifie les longueurs des deux bras même hors contact, la bouche courante, les prises actives et des rayons paume contre les vrais triangles. Les paumes de manipulation rencontrent les pièces entre 20,14 et 20,90 mm de leur centre, dans l'épaisseur du gant. Le déplacement maximal échantillonné est de 5,61 mm par pas de 5 ms. Ces contrôles ne remplacent pas l'inspection des doigts et des silhouettes.

Avant la restauration après annulation, tous les coins des AABB du chargeur et de la culasse se trouvent sous le plan inférieur de vue pour les FOV testés de 60°, 76° et 90°. Cette condition ne dépend pas du rapport largeur/hauteur. Les [empreintes des inspections](media/03/inspection-manifest.json) identifient les 24 captures locales et les sources utilisées. Les trois images liées en tête du rapport sont conservées dans le dépôt.

Le [PCM du mixeur](media/03/mixer.wav) provient d'`AudioEffectRecord`. La vidéo conserve aussi la [piste audio native de Movie Maker](media/03/movie-audio.wav). L'[analyse audio](media/03/audio-analysis.json) détecte les 13 attaques à 1,33–10,67 ms des événements de leur image. Ce sont des mesures du fichier capturé, pas de la latence des haut-parleurs. Le [manifeste vidéo](media/03/film-manifest.json) conserve la commande, le commit et les empreintes des sources.

Un premier brouillon non exécutable avait été écrit avant les tests dédiés au cas vide et aux événements sonores. Il a été rejeté et archivé. Les sources ont été remises à la base `301c2fd`; les 12 échecs du contrat ont ensuite été exécutés et revérifiés par le parent avant la reconstruction. Les journaux ne revendiquent pas un développement intégralement test-first depuis ce premier brouillon.

## Coût mesuré

Les cinq paires de passages alternent la base `301c2fd` et le candidat `fdd69b3`, dans le même ascenseur à 1280 × 720, en qualité normale. Chaque mode mesure 6,5 secondes après une seconde de préparation. Les deux versions exécutent le vrai contrôleur, sans capture vidéo concurrente. Tous les gestes sont observés pendant chaque passage actif du candidat. Le joueur reste à 100 points de santé.

| Temps de frame p50 | Base, médiane et plage | Candidat, médiane et plage |
| --- | --- | --- |
| Au repos | 96,336 ms, 95,575–106,010 | 95,033 ms, 92,595–100,576 |
| Pendant recharge | 94,734 ms, 92,575–100,800 | 97,431 ms, 93,686–101,844 |

Les plages se recouvrent. Cette mesure ne distingue pas un changement net de temps de frame de la variation entre passages. Les mouvements et le cadrage pendant la recharge diffèrent volontairement entre les versions. Le rendu llvmpipe sur CPU domine ce scénario; les 60 FPS ne sont pas atteints.

Le deuxième appel à `update_visual(0)` sur une pose déjà actualisée prend une médiane de 0,023 ms sur la base et 0,046 ms sur le candidat en recharge. Ce microcontrôle mesure une mise à jour chaude répétée, pas le coût CPU complet d'une frame ni celui de la première mise à jour physique. Le scénario complet reste dans la mesure de frame ci-dessus.

Les appels de rendu passent de 315 à 318–321 pendant le geste. Les triangles visibles passent de 52 886 à 52 822–53 014, selon que le chargeur est sous le cadre. Aucun nœud ou mesh n'est créé pendant une recharge. Les [mesures brutes](media/03/performance.json) contiennent 61–69 frames par mode et passage, les p95, les charges système et les empreintes des sources. Les p95 de ces petits échantillons ne certifient pas les saccades rares.

## Reproduction

Depuis le projet importé avec Godot 4.7.2 :

```bash
./tools/verify.sh
DISPLAY=:97 python3 tools/prove_d9_reload.py --film --inspect
DISPLAY=:97 python3 tools/prove_d9_reload.py --measure --baseline /chemin/vers/base-importee --runs 5
```

Le script refuse les erreurs moteur, conserve les empreintes et vérifie que toutes les phases de rechargement apparaissent dans les mesures actives. Movie Maker et les mesures sont exécutés séparément.

## Limites

Les preuves utilisent Linux, Godot 4.7.2, Compatibility et le rendu logiciel llvmpipe. Elles ne certifient ni Windows, ni une carte graphique de jeu, ni une parité visuelle avec Fortnite. Le geste conserve la direction stylisée du projet. L'ADS complet, les douilles et le rechargement ARC appartiennent aux tickets suivants.
