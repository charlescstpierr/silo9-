# Ticket7 : implémentation ADS

Commit `1f36f01eea2e5d34dafee7f46a665c013370cbb4` sur `feat/issue-07-ads`.
Worktree `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-07`. Base tests-only finale `15cd4289bf5aeda3f1fa764765a7a8a290529a6b` ; les cinq nouveaux fichiers tests ADS/saut sont identiques à cette base.

## Comportement

- Player possède une progression ADS, le facteur souris/stick et la composition unique FOV optique + impulsion. `_rest_fov` supprimé. R/B/switch sortent et reviennent progressivement ; les interruptions réarment après relâchement des sources. Sprint remplacé par marche4m/s en visée, crouch2.2m/s conservé.
- FpsRig calibre un poignet rigide à partir des vraies références et du produit mount/model au bind. À poids1 les mires sont alignées sans sway/bob/crouch parasite ; recul axial et contacts restent composés par le rig. Manipulation interpolée vers sa pose complète.
- D9 possède hausse/guidon coplanaires sous Slide. ARC possède deux organes au-dessus du logement, avec supports fixes indépendants de la batterie. Pas de nouveaux meshes/materials par frame, de lumière ou de query monde.
- Main ajoute FOV60..100, zoom1..1.6, sensibilitéADS.2..1 ; validation type/finite/clamp ; Apply/new/load/settings.cfg. Stick gauche, stick droit radial.2 à2rad/s, LT/RT, A/X/Y/RB/LB/DpadRight/Start et GUIA/Dpad. Le clavier reste WASD/ZQSD. Un verrou d’activation consomme le front de saut GUI sans supprimer les taps gameplay entre deux ticks.
- Le réticule HUD a alpha `1-aim_weight` chaque frame avant throttle textuel. Player expose ce poids en lecture seule, sans nouvel état. La retouche visuelle est autorisée et documentée dans `../crosshair-visual-decision.md`.

## Vérification exécutée

Une campagne complète `tools/verify.sh` a fini exit0 avec import +38 scripts exit0, zéro erreur technique, zéro garde. `verification-final.json` contient commandes, environnement isolé, durées, logs/hashes et identité de chaque source. Logs complets : `suite-logs-final/`. Nouveaux contrôles : géométrie161PASS (18tirs réels), transitions95PASS, options/entrées95PASS, saut10PASS.

Après cette campagne, une retouche purement visuelle d’une seule ligne a déplacé la pastille du guidon de9mm en Z modèle jusqu’à la face visible de son support. Le centre lumineux était enfermé dans la masse du guidon, constaté dans les pixels ; hauteur, axes et marqueurs sont inchangés. Exception présentation pure annoncée au parent avant édition. Source exacte précédente conservée dans `source-before-sight-face/scripts/weapon_visual.gd`, hash vérifié contre la campagne38. Diff : `sight-face.patch`. Géométrie ADS, rig et géométrie visuelle relancées sur la source finale :3scripts exit0, zéro erreur/garde. `sight-face-verification.json` contient leurs commandes/logs/hashes. **Les38 scripts n’ont pas tous été relancés après cette ligne visuelle.** `manifest-final.json` vérifie que cette ligne est le seul delta source depuis la campagne38.

Le saut avait une vraie régression : l’exigence de touche encore tenue perdait un tap complet entre deux ticks. Parent a reproduit baseline10PASS/candidat2FAIL et fait ajouter `test_jump_tap` par un acteur distinct. Après gate, correction : verrou armé à activation, levé une fois absence de tenue et de front frais observée. Test figé désormais10PASS (vitesseY7, élévation.1174935m), contrôle tenu et absence double saut conservés. Main95PASS confirme GUIA sans saut.

## Calibration rendue

`calibration/` :12 captures avant effacement du réticule ; `calibration-final/` :32captures après effacement mais avant sortie de la pastille ; `calibration-sight-face/` :32captures de la source finale. Rendus1280×720, X11, Compatibility/OpenGL, llvmpipe ; exit0. Seul warning : changement VSync non supporté. Les deux armes sont capturées hanche/ADS à FOV60/76/100, plus5pas entrée/5pas sortie à76. Observations JSON : vrais FOV/poids/alpha/projections/frames drawn.

Alpha observé pour chaque arme : entrée1,.84375,.5,.15625,0 ; sortie0,.15625,.5,.84375,1. Inspection personnelle ciblée : avant D9/ARC76, D960/ARC100 ; après réticule D976/ARC100/entréeD9mi-course/retourhancheD9 ; après pastille D976/ARC100. Cran ouvert et masse ARC sous la ligne sont visibles, et le HUD central disparaît en visée puis revient à la hanche. Pas de verdict indépendant d’art, ni revue continue de film, ni mesure de performance dans cette tranche. Les cas de mur et film complets restent au parent.

## Migrations de tests existants

- `test_fps_rig.gd` : les trois anciens cas numériques REST/RUN/AIM deviennent REST/RUN/REST avec aim_weight1 au troisième ; matrice et tolérances conservées.
- `test_player.gd` : ancien enumAIM et offsethistorique remplacés par poids engagé + déplacement réel de plus10cm. Le premier brouillon imposait .99 au tick12, mais11pas effectifs produisent .980324 ; diagnostic conservé et seuil original10cm préservé.
- `test_shot_feedback.gd` : écritures caméraFOV60/90 migrées vers configure_aim ; assertions de recul inchangées.
- `test_weapon_look_direction.gd` : parent a approuvé la migration du contrat de sway résiduel à pleineAIM vers stabilitéADS à.00001 ; contrôles hanche, atténuation et clamp inchangés. Les4rouges de l’ancien contrat sont archivés, puis suite migrée verte et incluse dans campagne38.

Le harnais Main initial désactivait le process_mode du monde et supprimait donc ses collisions. La correction de freeze_run a été reproduite/approuvée/committée par un autre acteur (`0ad8030`). Cet acteur production n’a modifié aucun des nouveaux tests.

## Deslop et périmètre

Tous les hunks des11fichiers commités relus. Retrait de la poseAIM historique et des captures/restaurations FOV périmées, migration des appelants. Aucun alias de compatibilité, commentaire narratif ajouté, placeholder, dépendance ou refactor hors tranche. Pas de ligne incertaine conservée. Les gardes InputMap restent nécessaires pour les fixtures Player sans mapping Main ; elles n’avalent pas de panne. Vérification après passe : campagne38 ci-dessus, puis3suites après unique retouche visuelle. Revue indépendante de code/commentaires au parent, conformément à son assignation sans descendant.

18UID Godot non suivis et générés dans cette tranche supprimés après inspection/hash ; aucun UID suivi touché (`generated-uids-removed.json`). Sources finales copiées dans `source-final/`. Aucun descendant, push, PR, changement global ou dépendance. Windows, manette physique et performancesGPU cible non vérifiés. Le mapping minimum utilise le périphérique joypad0 ; pas de remapping général.

## Libération

Worktree et tous les fichiers relâchés. Tous mes Godot et drivers terminés ; serveurXvfb2472984/:100 laissé vivant au parent. Statut Git propre après commit. Aucun travail production restant dans cette tranche ; revue/proof/natif/perf/art appartiennent au parent.
