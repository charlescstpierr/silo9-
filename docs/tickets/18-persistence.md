# Ticket 18 : persistance des traces de combat

La caisse de Décontamination se brise sous un tir D9 et conserve trois panneaux au sol. Les six robots laissent une carcasse à leur position et orientation de mort. Le verrou ARC reste éteint après chargement, avec son invite inactive et sans barrière. La porte du cœur est immédiatement ouverte quand une sauvegarde l'exige.

La source de production est `c105da61b2b490546f01c9d67703bfb405a2a44f`. Les onze fichiers de production et de test correspondent aux [empreintes finales](media/18/implementation/frozen-sources.json). La [revue du code](media/18/code-review.md) et le [rapport rouge](media/18/red-report.md) précisent les vérifications.

## État sauvegardé

Le schéma 4 ajoute un booléen de caisse et jusqu'à six poses de mort. Il conserve les circuits et accepte les sauvegardes des schémas 2 et 3. Les anciens builds qui ne connaissent que ces deux schémas refusent une sauvegarde de schéma 4. Un ancien robot vaincu sans pose reste absent, sans lui inventer une carcasse au point de départ. Les effets temporaires, les particules et les douilles ne sont pas sérialisés.

La sauvegarde refuse un JSON de plus de 65 536 octets UTF-8 avant d'ouvrir le fichier temporaire. Elle relit ce fichier avant de le renommer. Les données invalides ne remplacent ni la sauvegarde précédente ni le monde actif.

Le niveau reste une scène unique. La revisite traverse les passages réels, mais aucun déchargement automatique de secteur n'est ajouté. La reconstruction complète est exercée par le chargement de sauvegarde.

## Tests exécutés

Les suites ciblées passent après une relance indépendante. Elles comptent 179 assertions d'état, 58 de monde et 93 de géométrie, soit 330. Le cycle rouge initial conservait 21 échecs d'état et 24 de monde. Les erreurs initiales de fixture et de compilation restent exclues de cette preuve.

Le correctif de géométrie inverse les indices des pattes construites avec une échelle négative. Le test durable comprend un témoin qui inverse volontairement de vrais triangles. Le résultat final ne contient aucun triangle inversé selon ce contrôle des buffers générés. Ce contrôle ne compte pas les triangles effectivement dessinés par le GPU.

Les tests voisins des circuits, les deux conclusions, les restrictions d'arme pendant les menus et les douilles passent aussi. Le test monde conserve quatre références ObjectDB à l'arrêt. Les diagnostics antérieurs identifient des ressources et lectures audio. Cette livraison ne prétend pas supprimer ces avertissements.

## Parcours source et sauvegarde

Deux parcours complets passent avec les outils figés et la source inchangée. Les commandes individuelles du jeu et leurs validateurs terminent avec code 0.

| Parcours | Qualité | Distance physique | Santé finale | Sauvegarde |
| --- | --- | ---: | ---: | ---: |
| MÈRE | Normal | 525,484 m | 70 | 1 511 octets |
| N-7 | Low | 524,672 m | 70 | 1 511 octets |

Chaque parcours casse la caisse, tue sentinel_1 loin de son point de départ et désactive le verrou ARC. Il revisite les objets après retour au refuge, sauvegarde avec F5, recharge avec F9, les revisite de nouveau et termine la mission. Player et World ont de nouveaux identifiants après chargement. Une douille est active avant et après F5, puis aucune après F9. Les circuits mixtes, le cœur déjà pris et l'inventaire restent cohérents.

Le second tir ARC après chargement débite l'énergie et émet un seul changement d'état. Les snapshots pris dans ce callback montrent uniquement ce débit. Aucun nouveau signal de désactivation, souvenir, fait ou message du verrou n'est observé.

La marche utilise Input et la physique. L'orientation est scriptée et les tirs appellent Player.fire. E, F, F5 et F9 passent par X11. Ce sont des parcours automatisés du jeu source, pas une session entièrement jouée à la souris ni une mesure de durée de première partie humaine.

Le [résumé des preuves](media/18/native-summary.json) distingue les sorties réelles. Le superviseur extérieur de la campagne a retourné 143, sans cause établie. Les deux commandes enfants consignées, l'enregistreur vidéo et le décodage intégral ont chacun retourné 0. Aucun succès global de ce superviseur n'est revendiqué.

## Images et vidéo

La [revue artistique](media/18/art-review.md) ouvre 44 images, dont les douze extraites du film. Les parcours produisent douze images par qualité avec une caméra contrôlée séparée. La caisse et le verrou restent lisibles avant puis après les modifications. Les six images terminales de sentinel_1 sont occultées par un panneau. Elles sont conservées comme limites de capture, sans les présenter comme preuves de silhouette. Le HUD reste celui de la vraie position du joueur et quelques vues montrent son arme dans le champ de la caméra séparée.

Le supplément montre notamment la [sentinelle Normal](media/18/visual-supplement/normal/sentinel_back.png), la [sentinelle Low](media/18/visual-supplement/low/sentinel_back.png), la [caisse](media/18/visual-supplement/normal/crate.png) et le [verrou éteint](media/18/visual-supplement/normal/arc.png). Il reconstruit chacun des deux vrais fichiers sauvegardés et montre la sentinelle depuis deux angles dégagés, ainsi que la caisse et le verrou. Le HUD et le rig du joueur sont masqués pour ces huit images. Les hashes des sauvegardes et les poses observées sont conservés. Ce supplément démontre la reconstruction visible, pas une nouvelle marche ni un nouveau combat.

La [vidéo Normal](media/18/native-film/mother.mp4) dure 145,733 secondes et contient 2 186 images en 1280 × 720 à 15 images par seconde, sans audio. Son décodage intégral passe. Douze images en ont été extraites pour la revue ; un visionnage continu n'est pas revendiqué. Les timings des parcours avec captures ou enregistrement sont exclus de la campagne de performance.

## Rechargements répétés

Le [contrôle des allocations](media/18/reload-budget/report.md) exécute 22 reconstructions de Main, dont deux d'échauffement et vingt mesurées. Les 186 assertions et huit contre-exemples du validateur passent. Les six carcasses conservent les mêmes six ArrayMesh et trois matériaux, avec dix-neuf instances visibles en comptant les panneaux. Les compteurs restent à 105 ressources et 624 nœuds, sans nœud orphelin. Aucun Enemy n'est recréé.

La mémoire statique augmente de 862 032 octets pendant la collecte. Le rapport accumule aussi ses données ; la part du jeu n'est pas isolée. La preuve établit donc la stabilité des ressources ciblées, pas une mémoire totale strictement constante. Aucun avertissement ObjectDB n'apparaît dans cette séquence verbose. Les avertissements d'autres scénarios restent conservés, dont deux à la fermeture du supplément Normal.

## Exécutables

L'export Linux a été exécuté avec seize entrées X11 et douze captures ouvertes par une [revue indépendante](media/18/package-visual-review.md). Démarrage, déplacement, lampe, scan, F5, F9, pause, reprise, retour au menu et sortie propre sont observés. Le chargement conserve les valeurs du HUD et retire les marqueurs du scan. Cette vérification du binaire ne rejoue pas la mission complète ni les combats.

Le fichier Windows x64 est exporté et identifié comme PE32+. Il n'a pas été exécuté sous Windows.

## Coût graphique

La [revue indépendante](media/18/perf-review.md) valide vingt runs, cinq paires par qualité, sans erreur. Chaque run parcourt 92,433 m avec lampe ON. Les six morts réelles et le tir D9 sur la caisse précèdent la chauffe monotone d'au moins deux secondes. Les effets transitoires ont expiré avant mesure. L'audit recoupe 7 666 intervalles et 7 686 frames, les fixtures, les versions et les observations hôte.

| Temps médian par image, cinq runs | Référence p50 | Candidat p50 | Médiane des différences appariées |
| --- | ---: | ---: | ---: |
| Normal | 76,899 ms | 78,687 ms | +1,982 ms, plage de −2,040 à +2,480 ms |
| Low | 41,537 ms | 43,023 ms | +1,810 ms, plage de +1,420 à +2,799 ms |

Le coût Low p50 est reproduit dans les cinq paires, avec une différence appariée médiane de +4,39 %. Le résultat Normal et les queues p95/p99 restent non concluants. La [décision de coût](media/18/performance-decision.md) accepte ce surcoût local pour conserver les traces dans le budget statique retenu. Aucun gain de performance n'est revendiqué. Le [détail des résultats](media/18/perf-summary.json) conserve médianes, plages et chaque différence.

Les maxima de drawcalls augmentent de six dans les deux qualités. Ce nombre est observé par le moteur et ne dérive pas du plafond de dix-neuf instances. Le profil séparé, exclu des paires, attribue 92,1 % du CPU de Godot aux threads llvmpipe pendant cinq secondes du trajet Normal. Il ne mesure pas isolément le coût des carcasses et ne constitue pas un profil Low.

La première paire interrompue par le superviseur est entièrement exclue, y compris sa référence réussie. Les diagnostics d'outillage restent aussi exclus. Huit runs retenus signalent quatre références ObjectDB à la fermeture, sans attribution de classe à partir de ces journaux non verbose. Les vingt runs conservent l'avertissement du pilote sur V-Sync.

Le principe de vérification sur l'artefact réel a conduit à refuser les captures de sentinelle occultées et à produire le supplément visible. Les quarante selfchecks des outils et les huit contre-exemples indépendants contrôlent le validateur ; ils ne remplacent pas les exécutions du jeu.

## Limites

Les panneaux de la caisse restent sommaires et la finition globale reste éloignée de Fortnite. La revue du film relève aussi des textes de décor inversés vus depuis leur dos, sans attribuer ce défaut au changement de persistance. La caisse n'ajoute ni butin ni explosion. Les carcasses ne bloquent pas le passage et ne simulent aucune physique. Les autres objets du décor ne deviennent pas destructibles.

Les mesures de cette machine utilisent le rendu logiciel llvmpipe sous Linux. Elles ne certifient ni une carte graphique de joueur ni Windows. Le pilote audio Dummy ne prouve pas l'écoute sur un périphérique physique.

## Relancer les contrôles

Depuis le projet sous Linux, avec le moteur attendu disponible :

```sh
./tools/godot.sh --headless --path . --script tests/test_persistence_state.gd
./tools/godot.sh --headless --path . --script tests/test_world_persistence.gd
./tools/godot.sh --headless --path . --script tests/test_remains_geometry.gd
python3 tools/selfcheck_sector_power.py
```

Le wrapper `tools/prove_sector_power.py --help` décrit les parcours X11 et leurs arguments obligatoires. Les outils de campagne archivés sous `media/18` conservent les chemins du workspace original pour la provenance. Ils ne sont pas présentés comme des commandes portables sans adaptation.

Le probe et le wrapper publiés sont identiques aux versions figées de la campagne. Le selfcheck publié remplace uniquement un chemin temporaire propre au workspace par TemporaryDirectory standard. Le contrôle exécuté depuis le projet a d'abord échoué sur ce chemin, puis les quarante tests ont passé. La [trace de publication](media/18/publication-tool-change.json) conserve les empreintes et les deux sorties. Aucun comportement du jeu ni de la mesure n'a changé.
