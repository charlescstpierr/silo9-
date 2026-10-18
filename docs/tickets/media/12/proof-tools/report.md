# Outil de preuve ticket 12

Outil prêt pour un premier essai par le parent ; aucune exécution Godot, X11 ou capture n'a été lancée par cette tranche. La syntaxe GDScript et la faisabilité du parcours restent donc à valider dans le moteur. Seul le validateur Python est exécuté et passant.

Propriété exclusive : `.cstack/orchestrate/silo9/issue12/proof-tools/`. Production et tests du builder intacts. Source étudiée : `.worktrees/silo9-issue-12`, branche `feat/issue-12-sector-power`, HEAD observé `6126e4cdc0c5c89122627789ce394d8a1f1b521e`. Aucun worktree créé, aucun commit, aucun descendant ni processus persistant. Tous les fichiers de cette tranche sont libérés pour le parent.

## Fichiers et preuves

- `probe_sector_power.gd` : sonde SceneTree externe au projet.
- `run_probe.py` : lanceur avec répertoire de sortie neuf, délai maximal, journal moteur, manifeste des commandes et hashes avant/après incluant les fichiers non suivis, validation fermée des erreurs/rendu/parcours.
- `test_runner.py`, `red.log`, `green.log` : trois tests comportementaux du validateur. Première implémentation permissive : neuf assertions échouent. Après implémentation : trois tests passent. `py_compile` passe aussi.
- `hashes.txt` : SHA256 de la sonde, du lanceur et des tests au transfert.

La sonde est elle-même un outil de test d'intégration, pas une modification de production. Son exécution est réservée au parent qui possède la ressource moteur partagée. Aucune preuve GDScript verte ou parcours hors TDD vérifié n'est revendiquée avant cet essai. Une première erreur de parse ou de navigation doit être corrigée et rejouée avant livraison du ticket.

## Contrat des modes

`perf` marche depuis le spawn normal de refuge jusqu'aux Archives puis revient, avec neuf stations fixes et des pauses de 0,5 s identiques. Deux secondes de warmup sont exclues. Aucun disjoncteur n'est utilisé : le scénario comparable conserve les deux circuits ON lorsqu'ils existent. Les ennemis sont retirés uniquement dans ce banc isolé. Les collisions du monde et du joueur restent actives. Aucun screenshot dans ce mode. Le JSON conserve tous les intervalles de frame, leur étape, p50/p95/p99, frames rendues et maxima draw calls/nœuds/ressources. Ce banc ne prouve pas une mission jouable.

`mission` conserve ennemis, collisions, inventaire et dégâts réels. Les trois composants du relais sont ramassés physiquement ; scan, réparation, N-7, archive, cœur et ascenseur restent requis. Chaque commande disponible est coupée, rétablie et recoupée par E XTest, avec contrôle du rayon immédiatement avant E, du bit, de la révision et du prompt après. Les deux circuits restent coupés pendant la suite du parcours. La fin MÈRE passe par le détour ; la fin N-7 tire réellement à l'ARC sur le verrou. Deux commandes du lanceur créent deux parties neuves indépendantes. Les soins consomment uniquement les trousses initiales via la mécanique normale ; aucune affectation de santé ou ressource n'est utilisée. Marcher et tirer utilisent les actions/API joueur existantes ; seul E est garanti natif OS.

`capture` suit une mission et ajoute des PNG, jamais qualifiés de vidéo. Avant/après chaque bascule, la caméra vise successivement le sas et le ventilateur depuis la position réellement atteinte, avec trois images du rotor espacées de 0,2 s, puis retrouve le levier. Les menaces visibles sont combattues avant ces vues. Le parent peut enregistrer une vidéo X11 séparément. Les captures et le combat supplémentaire invalident toute comparaison de performance issue de ce mode.

Les observations avant/après chaque E incluent timestamps, objets/nœuds/ressources, lumières, transformations/visibilité/collisions/audio des sous-arbres nommés fan/sas/alarm/breaker et émissions/albedo des matériaux actifs, dédupliqués par ID. Ces données sont des observations à lire, pas un verdict automatique sur toutes les familles de consommateurs.

`--low` applique Low avant warmup et l'inscrit dans le JSON. Sans ce flag, qualité normale. `--require-circuits` fait échouer une campagne candidat sans API électrique ; la base peut tourner sans les nouvelles commandes.

## Essais proposés depuis la racine

`GODOT_BIN` doit désigner le binaire Godot 4.7.2 déjà validé par le parent. Le lanceur emploie DISPLAY=:100, X11, Compatibility, 1280×720 et Dummy audio. Il ne crée ni n'arrête Xvfb. L'audio Dummy ne prouve pas l'audibilité ; renderer réel indiqué dans JSON, aucune prétention GPU cible ou Windows.

```bash
python3 .cstack/orchestrate/silo9/issue12/proof-tools/run_probe.py --godot "$GODOT_BIN" --project .worktrees/silo9-issue-08 --mode perf --output .cstack/orchestrate/silo9/issue12/proof-tools/runs/baseline-normal-1
python3 .cstack/orchestrate/silo9/issue12/proof-tools/run_probe.py --godot "$GODOT_BIN" --project .worktrees/silo9-issue-12 --mode perf --require-circuits --output .cstack/orchestrate/silo9/issue12/proof-tools/runs/candidate-normal-1
python3 .cstack/orchestrate/silo9/issue12/proof-tools/run_probe.py --godot "$GODOT_BIN" --project .worktrees/silo9-issue-12 --mode mission --ending mother --require-circuits --output .cstack/orchestrate/silo9/issue12/proof-tools/runs/mission-mother
python3 .cstack/orchestrate/silo9/issue12/proof-tools/run_probe.py --godot "$GODOT_BIN" --project .worktrees/silo9-issue-12 --mode mission --ending n7 --require-circuits --output .cstack/orchestrate/silo9/issue12/proof-tools/runs/mission-n7
python3 .cstack/orchestrate/silo9/issue12/proof-tools/run_probe.py --godot "$GODOT_BIN" --project .worktrees/silo9-issue-12 --mode capture --ending mother --require-circuits --output .cstack/orchestrate/silo9/issue12/proof-tools/runs/captures-mother
```

Répéter les paires perf dans un ordre alterné avec sorties neuves, puis avec `--low`. Ne pas modifier la source ni exécuter un autre moteur pendant une campagne ; une mutation détectée invalide le manifeste. Le délai est borné à 900 s par défaut.

## Limites encore à couvrir

Cette sonde ne remplace pas les suites de sauvegarde/migration, état mixte restauré, fermeture occupée joueur/robots, colosse et dialogue réseau injecté. Le parent doit réconcilier ces preuves avec les tests dédiés et la revue des captures. Les snapshots de sous-arbres dépendent des noms finaux du builder ; leur contenu devra être contrôlé sur le candidat. Aucun hook de production ajouté.

Point de contrôle de débit : lecture de la conception et contrats avant écriture ; tranche indépendante du builder ; moteur X11 partagé laissé au parent ; un seul rédacteur pour les trois fichiers outils, sans sous-agent. Principe domaine : modes explicites `perf/mission/capture`, état de campagne dans un manifeste simple, sans framework de campagne dupliqué.
