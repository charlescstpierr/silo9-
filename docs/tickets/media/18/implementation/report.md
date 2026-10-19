# Ticket 18 : implémentation locale prête pour revue

La caisse cassée, les carcasses à la pose de mort, le verrou ARC et la porte reconstruite satisfont maintenant les tests comportementaux autorisés. Schéma 4 et frontière de fichier sont implémentés. Les contrôles ci-dessous passent réellement ; la preuve native complète, les mesures de coût graphique et les exports restent au parent.

Worktree : `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-18`. Branche `feat/issue-18-world-persistence`, HEAD inchangé `28e402821469655598c6a84bc415d8ea04da97c2`. Aucun commit, push, PR, descendant ni nouveau worktree. Diff complet relu ; `git diff --check` passe.

## Changements

- `run_state.gd` possède le booléen privé de caisse et les six poses facultatives, copiées en entrée/sortie. Défaite et pose sont publiées ensemble. Les poses sont finies, bornées et le yaw est normalisé. ARC ajoute fait et souvenir avant une notification unique. Les données sont converties avant application lors du chargement.
- `data/robot_spec.gd` centralise les six identités, variantes et spawns. Les 128 places historiques sont distinctes des six robots dans le schéma 4. Les schémas 2/3 gardent leurs anciennes clés, bornes et règles de circuits.
- `save_game` produit une chaîne JSON, refuse plus de 65 536 octets UTF-8 avant d'ouvrir le temporaire, vérifie les erreurs d'écriture, relit et valide le temporaire avant rename. Les refus testés conservent l'ancien fichier.
- `destructible_crate.gd` réunit l'ancien modèle Kenney, son unique collider et trois panneaux MultiMesh. Un dommage balistique positif casse la caisse ; l'ARC ne la casse pas. Couche et masque de collision deviennent nuls. Le collider frère historique a disparu.
- `enemy.gd` capture la pose réelle, coupe collision et physique, masque le vivant, enregistre la défaite puis libère le nœud. `world.gd` crée les traces avec `robot_visual.gd`, en réutilisant les mêmes ressources au combat et à la reconstruction. Aucun Enemy n'est créé pour un ID déjà défait ; une vieille défaite sans pose n'invente pas de carcasse.
- World projette ensemble booléen, invite et matériau sombre du verrou ARC. La barrière coupe sa couche de collision avant suppression. La porte et son collider sont placés à leur pose ouverte dès construction si le relais est réparé ; l'ouverture jouée conserve son tween.

`interactable.gd`, `main.gd`, outils du projet, assets, configuration et anciens tests autres que `test_sector_power_state.gd` sont préservés. Ce dernier retire explicitement les nouvelles clés de ses fixtures 2/3, conserve leurs refus et ajoute le roundtrip du schéma 4. Aucun système ou gestionnaire supplémentaire.

## Preuves rouge puis vert

Le gate parent précédent est `../red-tests/parent-gate.json`. Les assertions rouges initiales ne sont pas affaiblies : `integrity.json` prouve que retirer les deux seules lignes ajoutées au test monde reconstitue exactement son SHA-256 rouge. Le test état et la fixture sont byte-for-byte identiques. Les deux lignes ajoutent une protection après libération d'un robot.

| Suite finale | Résultat |
| --- | --- |
| `test_persistence_state.gd` | 179 assertions, 0 échec |
| `test_world_persistence.gd` | 58 assertions, 0 échec |
| `test_remains_geometry.gd` | 93 assertions, 0 échec |

`final-checks.json` fournit commandes, codes 0, durées, hashes des tests, erreurs et avertissements. Les fichiers `*-final.log` sont les sorties correspondantes. Les copies de poses, la normalisation, le second décès et les sous-arbres des traces, non exercés sur la baseline, ont effectivement été parcourus pendant le vert.

La lecture du diff a révélé un défaut de géométrie : la fusion d'une patte avec une échelle X négative inversait l'ordre de ses faces. `winding-red.log` conserve l'assertion échouée : 416 triangles inversés pour la sentinelle, 648 pour le rampant, contre zéro pour les pattes source. Le même probe dans `winding-green.log` passe après inversion des indices des seules pattes miroir. La géométrie conservée reste limitée à six ArrayMesh. `test_remains_geometry.gd` contrôle les buffers réellement **générés**, sans prétendre compter les triangles effectivement dessinés par le GPU ; son contrôle négatif inverse des indices réels et vérifie que le défaut est détecté.

L'hypothèse d'une commande de circuit cassée après la libération d'un Enemy a été infirmée. Le fichier historiquement nommé `death-circuit-red.log` contient **58 assertions vertes**, pas une preuve rouge. La boucle de production reste inchangée. Les deux assertions supplémentaires protègent ce parcours.

## Contrôles voisins exécutés

`checks.json` contient les commandes et journaux de `state`, `world`, `sector_power_state`, `sector_power_commands`, `sector_power_effects`, `sector_power_dialogue`, `journey` et `d9_modal_save`, tous code 0 sans assertion en échec ni erreur de script. Le parcours `journey` couvre les deux fins : 184,7 m parcourus, 15 tirs, santé finale 77. Ces valeurs décrivent le parcours de test, pas une mesure de performance.

Ces suites voisines ont précédé la dernière correction de l’ordre des faces des pattes. Après cette correction, la géométrie, les deux suites de persistance et les deux captures ont été exécutées de nouveau ; aucune autre production n’a changé.

Les douilles passent sous X11 avec rendu logiciel et audio Dummy : `shot_casings-x11-dummy-run.json`, code 0, `SHOT CASINGS FAILURES: 0`. L'essai headless a été arrêté à l'attente de `RenderingServer.frame_post_draw`, avant la suite des assertions ; il ne constitue pas un échec de production ni un résultat passant. Un premier essai X11 sans audio Dummy avait une erreur d'ouverture du pilote audio puis terminait ses assertions. La relance Dummy n'a aucune erreur moteur. `run_checks.py` utilise désormais ce chemin X11 pour les douilles lorsqu'il est rejoué.

Avertissements conservés : quatre références ObjectDB à la fermeture du dernier test monde, six sur `sector_power_effects` et huit sur `journey`. Le diagnostic verbose de la phase rouge identifiait les quatre références du monde comme audio ; les nombres six/huit ne sont pas attribués à une classe sans diagnostic. Aucun correctif audio hors périmètre. Les exécutions X11 finales n'ont que l'avertissement du pilote llvmpipe sur V-Sync. Les tests état, géométrie et D9 modal/save finaux n'ont pas d'avertissement.

## Aperçu et budget structurel

Les captures finales sont `remains-normal.png` et `remains-low.png`, recapturées après le correctif de faces. Je les ai ouvertes. La sentinelle couchée et le rampant sont reconnaissables ; les panneaux restent sommaires. Le parent avait déjà accepté le premier aperçu pour poursuivre la revue, sans validation finale du mouvement ou de la reconstruction.

`preview.gd` construit le vrai jeu, place deux robots autour de la caisse et déclenche leurs APIs de dégâts. Une caméra de preuve indépendante montre la même composition dans les deux qualités. Ce n'est pas un parcours joueur natif ni une preuve de tir pour ces captures. Caméra, poses, état, paramètres de qualité et sortie PNG sont consignés dans `preview-measurements.json`; commande, rendu llvmpipe, environnement X11 et hash du script dans `final-checks.json`. `frozen-sources.json` lie l'aperçu aux sources finales. Le script n'est pas un validateur général de livraison.

Le relevé des six carcasses confirme :

- trois MeshInstance3D par carcasse, chacun avec une surface ArrayMesh ; six ArrayMesh partagés entre les deux variantes et trois matériaux robot partagés ;
- zéro collision, lumière, timer ou traitement par frame dans chaque trace ; ombres OFF et portée locale 45 m ;
- une instance MultiMesh de caisse, trois panneaux, BoxMesh partagé, couche et masque nuls, ombres OFF et portée 45 m ;
- 19 instances graphiques de traces au maximum. Jusqu'à 19 soumissions couleur théoriques, **pas un compteur GPU mesuré** ;
- les six ressources ArrayMesh représentent 3 153 sommets, 11 028 indices et 195 456 octets de tableaux d'attributs/index récupérés côté CPU. Cela n'inclut pas les en-têtes de ressources, les caches du pilote, les allocations temporaires ou la mémoire totale du processus.

La stabilité sous 20 refresh est vérifiée pour les traces des deux variantes dans le test monde. Aucune campagne de 20 runs, coût GPU, stabilité sous de nombreux reloads, audio matériel, export ou validation Windows n'est revendiquée. Aucune garantie de résistance à une coupure électrique. La relecture du temporaire est implémentée et inspectée, mais n'a toujours pas de rouge indépendant : les refus d'E/S existants ne sont pas recyclés en preuve de cette nouvelle garde.

Le premier script d'aperçu a été arrêté après ses images parce qu'une conversion de référence Enemy déjà libérée vers Node échouait dans sa boucle de mesure. La fixture a été corrigée ; la dernière exécution complète termine avec code 0 et sans erreur. Les anciens journaux restent disponibles et ne sont pas retenus comme preuve finale.

## Intégrité et libération

`integrity.json` compare les 2 557 fichiers suivis à la base : seuls `enemy.gd`, `robot_visual.gd`, `run_state.gd`, `world.gd` et `test_sector_power_state.gd` ont changé. Les nouveaux scripts et tests autorisés sont énumérés avec SHA-256 dans `frozen-sources.json`. Les UID non suivis préexistants sont préservés. Aucun changement de production après le gel ; seule la formulation « generated geometry » du test court a été corrigée à la demande du parent, puis ce test et son hash ont été actualisés.

`runtime-release.json` confirme l'absence de Godot résiduel. Aucun serveur X11 lancé ou arrêté et aucun descendant. Les sources, tests, runtime headless et réservation X11 :100 sont libérés au parent pour la revue indépendante. Le worktree est conservé en place.
