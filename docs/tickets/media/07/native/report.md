# Ticket 7 — parcours natif

PASS sur le parcours borné ci-dessous, exécuté sur `1f36f01eea2e5d34dafee7f46a665c013370cbb4`, branche `feat/issue-07-ads`. Le jeu réel est lancé depuis `.worktrees/silo9-issue-07` avec Godot 4.7.2 officiel, X11, Compatibility/OpenGL, llvmpipe, 1280×720 et audio Dummy. Toutes les commandes viennent de XTest via `input.py` ; aucun événement ou état injecté dans Godot, aucun probe moteur, aucune modification de production.

Les 773 fichiers suivis sont identiques avant/après et correspondent aux objets Git du HEAD. `source-verification.json` en donne le résultat. Les deux processus quittent depuis le vrai bouton Quitter avec code 0 : premier statut d'attente conservé depuis `/proc`, second `Popen.wait()`. Aucun ERROR moteur dans `game.log` ni `restart.log`. Seul avertissement : VSync non pris en charge.

## Commandes et résultats observés

- Entrée initiale par Return : D9 à la hanche, puis clic droit maintenu centre l'arme et resserre le champ. Un mouvement relatif XTest déplace le décor ; relâcher remet l'arme à la hanche. Captures 01–04 inspectées.
- Tir réel D9 : sauvegarde 01 ammo12, sauvegarde 02 ammo11. R avec clic droit maintenu : sauvegarde 03 ammo12/réserve47, capture05 revenue en visée.
- Touche2, clic droit, tir ARC : capture07 en visée ; sauvegarde04 énergie88. Touche1 puis B avec visée tenue : capture08 montre ARC et transfert, capture09 D9 revenu en visée ; sauvegarde05 énergie100/cellules1 contre2 auparavant.
- Les ennemis attirés par le tir ont fini par tuer le joueur après ce transfert. Les captures10–13 ne prouvent donc pas la reprise modale. Une nouvelle partie sans tir fournit les captures acceptées15/16 : reprise depuis Pause avec clic droit toujours physiquement maintenu à la hanche, puis relâchement/nouvel appui rétablit la visée.
- Réglages ouvert par souris : les trois nouvelles options sont immédiatement visibles en haut (18), aucun saut initial en bas observé. Clics réels et End/Home règlent FOV100, grossissement1.6, sensibilité0.2. Le jeu écrit ces valeurs exactes dans `settings-first-apply.cfg` puis `settings-applied.cfg` ; captures22/23 montrent le champ élargi à la hanche puis resserré en visée.
- F5 puis F9 avec clic droit maintenu : capture26 à la hanche, capture27 en visée après relâchement/nouvel appui. Les réglages restent appliqués. Cette preuve ne mesure pas numériquement le FOV caméra.
- Reprise avec bouton gauche physiquement maintenu : sauvegardes07/08 gardent ammo12 pendant maintien et après relâchement ; seul le nouveau clic donne11 dans sauvegarde09.
- Vérification non ambiguë de Nouvelle partie après redémarrage du processus : sauvegarde09 sur disque contient ammo11. Le nouveau menu est activé par Return avec clic droit maintenu ; sauvegarde10 donne ammo12, nouvelle progression, capture37 à la hanche. Capture39 en visée après relâchement/nouvel appui. Les options100/1.6/.2 ont été relues depuis le fichier réel et le champ visible est conservé.

## Tentatives conservées et limites

Le premier clic Nouvelle partie après retour au menu n'a pas activé la partie ; les captures29/30 montrent encore le menu et F5 a correctement échoué. Les captures33/34 correspondent probablement à une reprise de session : elles sont exclues de la preuve Nouvelle partie. La preuve acceptée est le redémarrage37/39 avec ammo11→12, pas une déduction fondée seulement sur elapsed.

La molette au-dessus de sliders a modifié accidentellement les anciens réglages impulsion/lumière (.4/.9). La seconde visite les a remis à .5/1 par la vraie GUI, puis a utilisé un glissement de barre de défilement. Les deux fichiers cfg sont conservés ; aucun état n'a été écrit artificiellement. Ce comportement de molette est signalé au parent, sans correction dans cette tranche.

Les secondes dans `events.jsonl` sont relatives à chaque import du helper ; l'ordre des lignes constitue l'ordre global. Des captures immédiatement après Home peuvent encore montrer l'image du frame précédent ; les fichiers cfg et la réouverture24 montrent la valeur effectivement appliquée.

Aucune continuité fine d'animation, justesse géométrique des rayons, fréquence d'images, exécution Windows, écoute audio ou essai matériel de manette n'est affirmé. Les captures espacées établissent des poses et états observables ; les suites logiques et le film déterministe restent des preuves distinctes. La sensibilité est persistée, sans mesure native chiffrée de rotation par pixel.

Runtime libéré : plus aucun Godot lancé par cette tranche, aucun processus de capture persistant. Xvfb2472984/:100 laissé en fonctionnement pour le parent. Aucun worktree créé, aucun commit/push, aucun descendant. Tous les fichiers écrits sont sous `.cstack/orchestrate/silo9/issue07/native/`.
