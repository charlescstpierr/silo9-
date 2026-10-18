# Outils de preuve09 — remis au parent, runtime non exécuté

Les trois outils existants sont étendus dans ce dossier uniquement. Aucun fichier jeu, test Godot, worktree, commit ou processus Godot/ffmpeg modifié/lancé. Contrats cstack-agent et tdd lus. Pas de descendant. Dossier relâché après ce rapport pour revue et exécution parent.

## Comportement

- `perf`: corps des neuf stations inchangé, ennemis retirés comme auparavant, lampe par défaut OFF. Le validateur exige les neuf positions dans l'ordre, neuf points et `frames_drawn == intervalles + 1`.
- `mission/capture`: corps du parcours et combat inchangés. Avec `--require-lighting` seulement, F XTest avant le trajet et vérification de l'intention ainsi que de la vraie visibilité du Spot. L'événement et la sortie OS sont archivés. Les missions candidates sont donc lampe ON, pas un benchmark apparié.
- `lighting`: cinq poses identiques, chaque pose ON/OFF des deux circuits et lampe demandée ON/OFF, énergie0. Acteurs gelés vivants, phase1 pour le relais, caméra téléportée, événement colosse supprimé. Vues critiques relais/disjoncteur/preuve et séquences néon, effets réduits, alarme active/expirée. Ce sont des scènes inspectées, jamais une preuve de marche ou d'input natif. Le booléen demandé n'est pas présenté comme état effectif: la vraie Flashlight est enregistrée, ou null sur la baseline.
- `lighting-perf`: quatre fenêtres stationnaires séparées de six secondes : cœur lampeOFF/ON, Maintenance alarme tenue lampeOFF/ON. Aucune capture. Minuteries gelées volontairement à l'état de composition inspecté. Les intervalles, frames et maxima sont propres à chaque fenêtre. Ne pas utiliser les timings globaux de ce mode ni les fusionner à la route historique.
- Observations : Light3D réelles nommées, couleur/énergie/portée/ombre/masque/position, Spot réel, caméra/FOV/échelle effective, bits de courant, vivants/santé/pose, matériaux réels et associations des MeshInstance. Neuf sources et Flashlight requises seulement si demandé; absence consignée sur basee5b0baf.
- Provenance : hash moteur/wrapper/sonde avant et après, en plus des hashes source existants. Une dérive refuse le run. Mode/qualité demandés vérifiés; PNG réellement présent et signature PNG vérifiée dans le wrapper.

## TDD Python exécuté

Commande : `python3 .cstack/orchestrate/silo9/issue09/proof-tools/selfcheck_sector_power.py`.

- `validator-red.log`: sept échecs et quatre erreurs avant correction (route approximative acceptée, compteur frames incohérent, booléens comme intervalles, rapport malformé, éclairage vide accepté).
- `validator-pairs-red.log`: trois échecs distincts avant correction (paire manquante, pose modifiée, ombre sur source fixe).
- `validator-native-red.log`: un échec avant correction (mission require-lighting sans preuve F acceptée).
- `validator-green.log`: neuf tests passent, incluant acceptation d'une fixture d'observations éclairées et de la baseline sans fonction lumière, refus de cette baseline si required.
- `route-identity.json`: onze fonctions historiques identiques, dont performance_route, mission_route, combat, interactions et échantillonnage. walk_to ajoute seulement l'enregistrement des coordonnées atteintes.
- `python3 -m py_compile` exécuté sur les deux fichiers Python. Aucun parse/runtime GDScript revendiqué : parent seul possède ce runtime. Le premier run doit vérifier notamment la comptabilité frames des fenêtres isolées.

## Commandes parent

Chemin moteur doit désigner le binaire réel, pas `tools/godot.sh` ni un nom PATH (hash du moteur obligatoire). Depuis la racine, utiliser le binaire4.7.2 déjà présent :

```sh
python3 .cstack/orchestrate/silo9/issue09/proof-tools/prove_sector_power.py --project .worktrees/silo9-issue-09 --godot .tools/Godot_v4.7.2-stable_linux.x86_64 --output .cstack/orchestrate/silo9/issue09/run-lighting-normal --mode lighting --require-circuits --require-lighting
python3 .cstack/orchestrate/silo9/issue09/proof-tools/prove_sector_power.py --project .worktrees/silo9-issue-09 --godot .tools/Godot_v4.7.2-stable_linux.x86_64 --output .cstack/orchestrate/silo9/issue09/run-lighting-low --mode lighting --require-circuits --require-lighting --low
python3 .cstack/orchestrate/silo9/issue09/proof-tools/prove_sector_power.py --project .worktrees/silo9-issue-09 --godot .tools/Godot_v4.7.2-stable_linux.x86_64 --output .cstack/orchestrate/silo9/issue09/run-cost-normal --mode lighting-perf --require-circuits --require-lighting
```

Pour baseline : même copie des outils, projet au e5b0baf et omettre `--require-lighting`. Pour coût historique : `--mode perf`, même copie baseline/candidat, aucun PNG; qualité Low par `--low`. Pour mission candidate : `--mode capture --ending mother|n7 --require-lighting --require-circuits`.

## Limites restant à vérifier

Le validateur n'est pas un juge de pixels : lisibilité, cohérence diffuseur/source et phases d'animation requièrent encore inspection indépendante des images/observations et tests dédiés du jeu. Les IDs de matériaux viennent des instances réelles, mais sont propres au processus; comparer contenu/association, pas les nombres entre runs. Les MultiMesh sont inclus dans la table des matériaux, pas dépliés par instance dans mesh_materials. Les vues proposées et leurs cadrages ne sont pas encore inspectés. Aucun GPU cible ni Windows ni audio audible validé. Les quatre fenêtres coût sont des états tenus, pas une moyenne de la totalité d'une alarme animée.

SHA256 des trois outils dans `SHA256.json`. Aucun processus laissé actif. Aucune mémoire personnelle consultée ou modifiée.

Worktree lu uniquement : `.worktrees/silo9-issue-09`, branche `feat/issue-09-lighting`, HEAD observé au gel `896f0447d5f3ba94a464cdae96735228bfd15368`. Aucun worktree créé ni source écrite par cette tranche.
