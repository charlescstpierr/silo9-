# Revue indépendante du code, ticket 12

Verdict **PASS** sur le code de `70d35729a0990b6f066b957338b717696c8bb99f`, comparé à `6126e4cdc0c5c89122627789ce394d8a1f1b521e`. Aucun défaut actionnable établi dans cette tranche. Ce verdict ne couvre pas le rendu, la jouabilité native ni la performance mesurée et n'autorise aucun merge.

Worktree `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-12`, branche `feat/issue-12-sector-power`. SHA vérifié avant et après la revue. Aucun fichier suivi modifié ; `git diff --exit-code` et `git diff --check 6126e4c..HEAD` sortent avec code 0.

## Méthode et preuves

Lecture intégrale du diff et des nouveaux composants, puis des flux connectés de `main.gd`, `player.gd`, `enemy.gd`, `run_state.gd`, `dialogue.gd`, `world.gd` et `world_art.gd`. Lecture de `design/accepted.md`, `grounding.md`, `tests-red-parent/gate.json`, `implementation/report.md` et des logs `parent-green/`. Les deux anciens échecs de préférences sont cohérents avec l'attente schema2 remplacée par schema3 ; les logs `updated-test_ads_settings_input.log` et `updated-test_shot_settings.log` affichent zéro échec. Les quatre logs électriques parent affichent zéro échec. Ces exécutions parent restent des preuves lues, pas des exécutions de ce reviewer.

Exécution indépendante ciblée du chemin réel `Main.save_run` puis `Main.load_run`, dans un XDG isolé. La sonde couvre les quatre combinaisons de circuits pour arrivée, relais découvert, relais réparé, noyau récupéré, fin MÈRE et fin N-7. Elle vérifie phase/faits/fin après coupure et après reconstruction, bits restaurés, machines, lumières coupées, silence des alarmes et fermeture des sas libres après pas physiques. Résultat mesuré : **24 cas, 252 assertions, zéro échec, exit 0**.

Commande, depuis le worktree :

```sh
XDG_DATA_HOME="$PWD/.cstack/issue12-review/data" ./tools/godot.sh --headless --path . --script .cstack/issue12-review/restore_probe.gd
```

Sonde et preuve dans le worktree : `.cstack/issue12-review/restore_probe.gd` et `.cstack/issue12-review/restore.log`. Cette sonde remplace les acteurs par les méthodes de production, mais désactive leur mouvement autonome. Elle ne prouve pas le trajet joueur ou une interaction E native.

## Contrats vérifiés

- Mission et restauration : `world.gd:527` ne modifie que les bits électriques via `_commit_circuit`. La réparation et ses faits conservent leurs transitions existantes. `run_state.gd:259` reprend exactement les bits schema3 ; `Main._start_run` reconstruit ensuite les consommateurs depuis cet état. La sonde indépendante confirme ces propriétés dans les 24 cas. La coupure ne régresse aucune phase testée et le chargement ne rallume aucun secteur sauvegardé OFF.
- Sauvegarde : `run_state.gd:268` exige les clés historiques exactes pour schema2, les deux booléens stricts et les clés exactes pour schema3, puis conserve les invariants phase/faits/fin. La validation précède toutes les affectations. Taille maximale et écriture temporaire suivie du renommage restent en place. La révision augmente après chaque chargement accepté sans provenir du fichier.
- Ordre et idempotence : `world.gd:527` garde la réentrance jusqu'à la fin de `changed.emit()`, refuse les commandes inactives et ne produit aucun effet pour une cible déjà satisfaite. Les consommateurs, lumières, émissions et prompts sont appliqués avant l'alarme puis la publication. Aucun `await` dans ce chemin. Le refresh déclenché par le signal ne rejoue pas l'alarme.
- Sas : `power_consumers.gd:72` construit un volume de contrôle élargi de 0,1 m sur chacune des faces. `power_consumers.gd:155` interroge les corps complets, bloque sur tout `CharacterBody3D` et ne ferme qu'au pas physique. La coupure ouvre les feuilles et retire leur couche physique ensemble, puis annule toute fermeture en attente. Le passage central de 3,2 m reste libre. Les preuves parent vérifient la capsule du joueur et tous les robots ; la sonde reviewer vérifie les sas reconstruits et libres.
- Dialogue : le résumé est filtré par personnage et distinct des faits/mémoires. `dialogue.gd:85` inclut la révision dans la clé, donc OFF puis ON invalide une réponse en vol avant l'application d'actions. Les actions autorisées restent hint/trust. La preuve HTTP parent est une réponse injectée sur loopback, sans modèle réel.
- Matériaux : les copies émissives sont privées par circuit et matériau source. Les identités de matériau parviennent aux lots finaux dans les deux chemins de batching. Les objets de mission, pickups, personnages et indicateurs alimentés sur réserve gardent les références séparées prévues. Les bascules ne reconstruisent pas la géométrie et ne dupliquent aucun matériau.
- Composition : `world.gd:559` possède les écritures finales des neuf Omni et du spot. OFF domine énergie et visibilité, Low conserve ses six premières Omni et coupe le spot, la fin domine la couleur. Le colosse ne pilote qu'un gain et ne modifie pas les émissions à chaque frame. N-7 arrête la physique ennemie ; aucun chemin électrique ne la réactive.
- Coût structurel : roster, neuf lumières et registre borné de matériaux seulement pendant une bascule ; aucune recherche d'arbre dans cette opération ou par frame. Les deux rotors réutilisent leurs MultiMesh et lecteurs. Les requêtes de sas cessent dès fermeture. Aucun chiffre de performance n'est déduit de cette inspection.

## Commentaires et limites

Aucun commentaire source ajouté ou changé dans le diff. Aucun constat actionnable pour la passe no-comments ; aucune suppression proposée.

La sonde produit elle aussi un avertissement ObjectDB à l'arrêt. Il reste hors du verdict de fuite persistante : cette revue n'établit ni accumulation pendant une session ni résolution du warning AudioStreamPlaybackWAV. L'investigation dédiée du builder reste à réconcilier par le parent.

Skills appliqués : cstack, règles communes, contrat délégué, investigation bornée, prompt comment-reviewer et unslop. Playbook de revue limité au périmètre assigné ; aucun descendant. Point de contrôle de débit : sans objet, revue en lecture seule avec sonde locale autorisée.

Seuls ce rapport et les artefacts ignorés `.cstack/issue12-review/` ont été écrits. Aucun commit, push, PR, rendu, GPU ou ffmpeg. Aucun worktree créé. Le processus Godot de la sonde est terminé avec exit 0 ; ce reviewer libère le worktree et ses fichiers pour le parent.

## Addendum au SHA final 2c205f5

Verdict **PASS** maintenu pour le code de `2c205f59520d935e09c921574a20e42379999348`. Le verdict et la sonde fonctionnelle ci-dessus restent rattachés à `70d35729a0990b6f066b957338b717696c8bb99f`. Le delta final lu intégralement ne contient que deux valeurs de `scripts/data/power_consumers.gd:36` et `:38` : la hauteur du Label3D passe de 1,95 à 1,6 m et son pixel_size de 0,009 à 0,002. Aucun changement de commande, collision, sauvegarde, dialogue, matériau, éclairage ou audio. Aucun commentaire ajouté.

Inspection directe de `label-preview-final.png` avec view_image : le nom Maintenance et l'état ON / SOUS TENSION sont lisibles et restent dans la largeur du disjoncteur au point de vue montré. La sonde de capture `label_preview.gd` place le joueur à `(2, 0, -16)`, face au levier, avec une inclinaison de caméra de -0,35 rad. `label-preview-final.log` identifie llvmpipe. Cette image établit la présentation à ce point de vue, sans remplacer les captures finales de parcours ni une validation des autres distances. Aucun moteur relancé par ce reviewer.

La réserve audio précédente est désormais réconciliée par lecture de `implementation/audio-lifetime-report.md`, de `probe_audio_lifetime.gd`, des lignes `AUDIO_LIFETIME` de `audio-lifetime-drained.log` et des commandes/exit codes de `audio-lifetime-checks.json`. La sonde conserve seulement des WeakRef sur les streams et playbacks du monde, puis détruit monde et joueur. Pour les huit reconstructions, toutes ces références sont libérées au contrôle à 250 ms et restent nulles à 750 ms. Après drainage, les compteurs restent à 1 nœud, 0 orphelin, 35 ressources et 1633 objets corrigés des WeakRef ; le dernier contrôle affiche 1631 objets. Le run drainé sort avec code 0 sans warning final.

Ces preuves appuient une libération audio différée et n'établissent aucune accumulation persistante sur les huit cycles observés. Elles ne déterminent pas le mécanisme interne du moteur et ne constituent pas une preuve générale d'absence de fuite. Aucun correctif audio n'a été appliqué ou n'est demandé par cette revue.

Les captures complètes finales et les mesures de performance restent hors de cet addendum. Seul ce rapport a été complété, aucun fichier suivi ni source modifié. Aucun processus lancé, worktree à nouveau libéré pour le parent.
