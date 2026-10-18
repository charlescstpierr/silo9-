# Revue finale indépendante des outils de preuve09

Verdict **PASS, limité à la lecture statique et aux contrôles Python exécutés**. Les deux P2 de `proof-tools-review.md` sont résolus dans le périmètre demandé. Le trou documenté des fenêtres coût est également corrigé. Aucun nouveau faux positif majeur trouvé dans les scénarios examinés. Ce verdict ne valide pas l'exécution de la sonde GDScript, les images ni les performances du jeu.

Skills appliqués : cstack, cstack-agent, no-comments avec le contrat comment-reviewer, unslop. Playbook Investigation, tranche indépendante sans descendant. Throughput checkpoint: n/a, read-only investigation.

- [x] Lire les constats initiaux et le rapport de correction.
- [x] Examiner intégralement les trois outils actuels.
- [x] Exécuter les selfchecks, reproduire les anciens faux positifs et contrôler la baseline.
- [x] Recalculer les hashes et comparer les onze fonctions historiques.
- [x] Produire ce rapport. Runtime réservé au parent.

## Résolution des constats

`prove_sector_power.py:35` confronte désormais les deux bits effectifs à `circuits_requested`, puis à l'état demandé par le nom de la pose. Cette validation s'applique aussi à la baseline. `probe_sector_power.gd:419` contrôle le résultat CHANGED/UNCHANGED de chaque commande de préparation et le bit final. Aucun appel de préparation ne conserve l'ancien résultat ignoré.

La lampe demandée ON doit être visible, avoir une énergie et une portée strictement positives et finies, et inclure le masque monde1. Les ombres suivent la qualité. Les essais Python supplémentaires avec énergie0,05, portée0,25 et masque3 passent séparément, ce qui confirme que ces paramètres artistiques ne sont pas figés à leur valeur de fixture.

`prove_sector_power.py:113` exige les44labels distincts :20poses,6vues critiques,13phases néon,3phases réduites et2états alarme. Les poses des paires critiques sont comparées. Les familles supprimées et la paire critique déplacée sont rejetées par les selfchecks exécutés.

Les fenêtres coût exigent les quatre observations dans l'ordre prévu et sansPNG. Elles contrôlent les intervalles positifs finis, leur nombre et la comptabilité des images. La somme des intervalles et la durée entre observations doivent chacune couvrir6000ms à un intervalle maximal près. L'observation après est obligatoire ; pose, qualité et énergie restent stables, courant et lampe sont revalidés. Les deux fenêtres Maintenance contrôlent la minuterie d'alarme avant/après et, sur le candidat, l'émission de la vraie lumière d'alarme. La baseline sans lampe et sans nouvelle Omni reste admissible quand `require_lighting` vaut false.

## Exécution indépendante

Commande exécutée avec `PYTHONDONTWRITEBYTECODE=1` :

```sh
python3 .cstack/orchestrate/silo9/issue09/proof-tools/selfcheck_sector_power.py
```

Résultat : `Ran 13 tests in 0.070s`, `OK`, exit0.

Un second programme Python exécuté en mémoire a vérifié séparément les cas historiques sur les fixtures fournies :

| Mutation ou contrôle | Résultat actuel |
|---|---|
| Tous les circuits effectifs et plafonds restent ON | Rejet |
| Toutes les lampes ont énergie0 | Rejet |
| Conserver seulement les20poses standard | Rejet |
| Quatre fenêtres de20intervalles à0,001ms, sans observation après | Rejet |
| Baseline lighting sans Flashlight et sans required | Acceptée |
| Baseline lighting-perf sans Flashlight et sans required | Acceptée |
| Modifier séparément énergie, portée et masque avec valeurs physiques valides | Accepté |

Les deux fixtures candidates complètes passent également. Ces résultats prouvent les gardes du validateur sur ces données synthétiques ; ils ne représentent pas des mesures du moteur.

Les hashes des trois fichiers recalculés concordent avec `proof-tools/SHA256.json` :

```text
probe_sector_power.gd     28e9cd57c0e56f0c06601539d5cd7d35154e1191eea2568d9e6cbe0d2e47bf44
prove_sector_power.py     bc45ab99e5dd1cf55401fe99d67385ad365588f4f8b63fe4b887762e050124cd
selfcheck_sector_power.py 93c80290ccf75d0f66cf496f6052f5ef63c73f68c7f3bfe3279af6436266b12a
```

Comparaison textuelle indépendante contre `tools/probe_sector_power.gd` du root : les corps de performance_route, mission_route, use_arc_lock, breaker_cycle, use_object, capture_consumers, visible_enemy, aim, _process, percentile et wait sont identiques, soit11/11. La comparaison extrait chaque fonction jusqu'à la prochaine déclaration et ignore seulement les espaces externes au corps.

## Limites conservées

Le parent doit encore compiler puis exécuter la sonde, notamment vérifier `get_script_constant_map()["PowerOutcome"]`, les préparations de circuits et les durées réellement produites. Aucun Godot, Xvfb, ffmpeg ou benchmark lancé par cette revue.

Le catalogue impose la présence des familles, pas la lisibilité de leurs pixels ni l'animation correcte du néon ou de l'accessibilité. Les observations et captures finales doivent encore être auditées. Les fenêtres coût demandent une alarme figée active ; elles ne prouvent pas son cycle temporel en jeu. La tolérance de durée est celle d'une image maximale observée, pas un budget de fluidité. Aucun résultat GPU cible, Windows ou performance joueur validé.

## Commentaires et libération

Aucun constat actionnable de commentaire. Les commentaires présents expliquent la nature contrôlée des fixtures, la séparation des mesures, l'expiration de l'alarme, l'avancement de l'horloge et la précision de sérialisation. Aucune suppression, restauration, relance ou correction appliquée. Aucune contrainte externe à encoder découverte.

Seul ce rapport a été écrit. Aucun outil, source, test ou rapport antérieur modifié, aucun commit/push/PR, aucun descendant ni processus laissé actif. Worktree identifié en lecture seule : `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-09`, branche `feat/issue-09-lighting`, HEAD observé `e691f5fcea4824a379f362e85e69baa325a0b0bb`. La production de ce worktree n'est pas couverte par ce verdict. Aucun worktree créé ; tranche relâchée. Aucune mémoire personnelle utilisée ou modifiée.
