# Corrections des outils de preuve09

Tranche gelée et libérée. cstack-agent et TDD appliqués. Aucun descendant, moteur, serveur graphique, encodeur, benchmark, commit, push ou PR. Aucun fichier jeu ni test Godot modifié. Le rapport indépendant et ses constats historiques restent intacts.

## Rouge puis vert exécutés

Commande: `python3 .cstack/orchestrate/silo9/issue09/proof-tools/selfcheck_sector_power.py`.

- `proof-tools/fix-red.log`: 13 tests, 18 échecs sémantiques avant modification du validateur. Courant demandé resté incorrect (candidat et baseline), lampe sans énergie/portée/masque monde, chacune des quatre familles supplémentaire absente, paire critique déplacée, fenêtres trop courtes/longues, après absent/incohérent et alarme inactive. Une erreur d'indentation initiale dans l'édition des tests a été corrigée avant cette exécution; elle ne constitue pas la preuve rouge.
- `proof-tools/fix-green.log`: mêmes 13 tests passent après correction. Les fixtures positives portent désormais les44observations et les propriétés physiques de lampe/alarme effectivement inspectées. Les assertions de rejet n'ont pas été affaiblies.
- `python3 -m py_compile` sur les deux Python: exit0.
- `proof-tools/fix-route-identity.json`: les11fonctions historiques annoncées restent identiques à celles du root, dont parcours performance, mission, combat, interactions, `_process`, percentile et attente.

## Contrat renforcé

Chaque observation comporte une demande électrique explicite distincte des bits effectifs. La validation confronte les deux circuits à cette demande, y compris baseline. Le suffixe courant des20poses et les scènes critiques/cost sont aussi confrontés au scénario. La lampeON doit être visible, à énergie et portée positives finies et inclure le masque monde1. Les ombres restent liées à la qualité. Une baseline sans API garde une observation lampe nulle.

Le catalogue impose exactement20poses,6critiques,13phases néon,3phases réduites et2états alarme. Les paires critiques doivent partager position/rotation/FOV. Ce contrat ne remplace pas la revue des pixels.

Les quatre fenêtres coût imposent leurs observations avant et après, leur identité et ordre, l'absence dePNG, la comptabilité frames, une somme des intervalles de6000ms à un intervalle maximal près, ainsi que la durée avant/après avec la même tolérance. Pose, qualité et énergie restent identiques; courant/lampe sont revalidés après. L'alarmeMaintenance doit conserver une minuterie positive avant/après; sur candidat sa vraie lumière doit être visible, positive et couvrir le monde. Sur baseline le timer est observé sans inventer une nouvelle Omni.

La sonde enregistre les minuteries réelles. `fixture_circuit` vérifie le résultat enum CHANGED/UNCHANGED de la commande et le bit final; aucun appel de préparation `set_circuit` n'ignore désormais un refus. Les valeurs enum viennent de la classe du monde, sans nombres magiques ni nouvelle API de jeu. Les trajectoires natives, F XTest, marqueurs de scènes contrôlées et séparation capture/mesure restent conservés.

## Limites

Aucun parse ou runtime GDScript exécuté, conformément à la propriété exclusive du builder. Le parent doit donc lancer la sonde, vérifier notamment la résolution du dictionnaire enum via `get_script_constant_map`, la durée observée et les poses/captures. Les fixtures Python prouvent le validateur; elles ne prouvent ni rendu, ni performance, ni succès du jeu. Aucun paramètre artistique d'énergie/portée n'a été fixé dans le validateur.

## Provenance et libération

Outils exclusivement dans `.cstack/orchestrate/silo9/issue09/proof-tools/`:

- sonde: `28e9cd57c0e56f0c06601539d5cd7d35154e1191eea2568d9e6cbe0d2e47bf44`
- wrapper: `bc45ab99e5dd1cf55401fe99d67385ad365588f4f8b63fe4b887762e050124cd`
- selfcheck: `93c80290ccf75d0f66cf496f6052f5ef63c73f68c7f3bfe3279af6436266b12a`

`proof-tools/SHA256.json` mis à jour. Le `report.md` initial décrit la tranche précédente; ce rapport est son correctif daté par la séquence de tâche. Worktree lu uniquement: `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-09`, branche `feat/issue-09-lighting`, HEAD observé `896f0447d5f3ba94a464cdae96735228bfd15368`. Aucun worktree créé, aucun processus restant; tous les fichiers de cette tranche sont relâchés. Aucune mémoire personnelle utilisée ou modifiée.
