# Revue indépendante de performance du ticket 12

Preuve : **PASS** pour la campagne bornée décrite ci-dessous. Les 20 exécutions, soit cinq par côté et par qualité, passent l'audit des fichiers bruts. Le parent a confirmé la fin de la collecte avant ce verdict.

Coût : **ISSUES en Normal**. Le candidat est plus lent sur cette scène llvmpipe : p50 médian +2,32 %, p95 +7,07 % et p99 +7,52 %. Les cinq deltas appariés sont positifs pour chacun des trois percentiles. Le p95 du candidat dépasse celui de toutes les exécutions de base. L'absence de GPU cible ne supprime pas cette régression locale.

Coût en Low : **pas de régression démontrée, différence de vitesse non concluante**. Les médianes p50, p95 et p99 baissent, mais les plages se recouvrent. Le p95 baisse dans les cinq paires, avec un test exact descriptif à p=0,05556. Cette tendance ne justifie pas de promettre un gain. Le p99 de la paire 4 augmente de 3,646 ms, malgré la baisse de sa médiane globale.

Aucun chiffre Windows, GPU cible, FPS joueur, mission complète ou audio audible n'est revendiqué. Le contre-factuel d'ombres est exclu de tous les calculs suivants.

## Périmètre figé et reproduction

- Base : `.worktrees/silo9-issue-08`, SHA `6126e4cdc0c5c89122627789ce394d8a1f1b521e`.
- Candidat : `.worktrees/silo9-issue-12`, SHA `2c205f59520d935e09c921574a20e42379999348`.
- Données : [perf](../perf), les dix fichiers `*-pair.json` et les vingt répertoires contenant `manifest.json`, `journey.json` et `engine.log`.
- Audit relançable sans moteur : `python3 .cstack/orchestrate/silo9/issue12/perf-audit/audit_perf.py`. Le script lit les preuves et les sources actuelles, vérifie leur identité et écrit son résultat JSON sur stdout.
- Plan préalable : [perf-plan.md](../performance/perf-plan.md). Ordonnancement lu dans [run_perf_pair.py](../performance/run_perf_pair.py). Le même outil [run_probe.py](../proof-tools/run_probe.py) appelle le même [probe_sector_power.gd](../proof-tools/probe_sector_power.gd).

La campagne commence par les cinq paires Normal, puis les cinq paires Low. Dans chaque qualité, les ordres sont base/candidat, candidat/base, base/candidat, candidat/base, base/candidat. Les timestamps confirment l'absence de chevauchement des exécutions de la campagne. Le relevé [host-start.txt](../perf/host-start.txt) indique huit CPU et des charges 1,18 / 2,47 / 1,93 au départ. Ce relevé ne constitue pas une surveillance continue de tous les processus tiers. Aucun moteur, encodeur ni profileur n'a été lancé par cette revue.

## Provenance et validation

Les manifests fixent le SHA de chaque worktree et 1 408 hashes de fichiers côté base, 1 426 côté candidat. Les dictionnaires avant/après sont identiques pour chaque exécution et stables entre toutes les répétitions d'un même côté. L'audit recalcule ces hashes sur les fichiers présents, confirme que tous les fichiers suivis sont couverts et vérifie `git diff --quiet <SHA>`. Les fichiers non suivis présents sont des artefacts de génération déjà inclus dans ces dictionnaires. Les caches ignorés tels que `.godot` ne sont pas figés par cette fonction.

Le probe possède le SHA256 `23fe1bd0a24df6dd40559792b20add6e9c75d39debfa2a9ef6a48a1b912fc971` dans les vingt manifests. Le SHA256 actuel du wrapper est `2269dc53977ac9f324168fa9327c12bafbda9f3c9281380a7f59b6d280f083a3`, identique au relevé préalable [proof-tools/hashes.txt](../proof-tools/hashes.txt).

Le moteur actuel possède le SHA256 `8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e`. Ce hash correspond aux relevés antérieurs du ticket 08, [campaign.json](../../08/performance/campaign.json) et [prepare-2/manifest.json](../../08/performance/prepare-2/manifest.json), avant et après préparation. [profile-link.json](../performance/profile-link.json) consigne le contrôle actuel. Les manifests du ticket 12 ne contiennent pas eux-mêmes le hash du moteur ou du wrapper. Il s'agit d'une provenance croisée, pas d'un contrôle binaire avant/après chaque exécution.

Les vingt rapports identifient Godot `4.7.2-stable (official)`, hash moteur `ed1daf0bf001b61586d9930840f2f1394092c079`, X11 `:100`, Compatibility, llvmpipe LLVM 21.1.8 et une fenêtre de 1 280 × 720. Les logs identifient Mesa 26.0.8. Chaque processus sort avec le code 0, aucun échec de validation ni erreur moteur n'est présent. Chaque log contient le même avertissement de V-Sync non modifiable par le pilote. Cette limite est commune aux deux côtés.

Le mode Low est cohérent entre argument, commande et rapport dans les dix exécutions concernées. `main.gd:695` applique le réglage au monde. `world.gd:507` réduit l'échelle 3D à 0,67 et coupe le brouillard ; `world.gd:559` masque les lumières prévues et la lumière d'ombre. L'instrument exporte le choix Low, pas un relevé séparé de chaque propriété finale. Les deux côtés utilisent le projet source, pas un export de production Windows. La comparaison porte donc sur ces configurations sources identiques hors ticket.

## Travail réellement exécuté

Les vingt rapports confirment exactement neuf points atteints, 92,433439 m parcourus, santé 100, zéro tir, zéro commande d'interaction et une route complète. Le probe enlève les ennemis des deux côtés avant le warmup de deux secondes. Il appelle `new_game()`, puis actionne `forward` et `sprint` pendant les pas physiques dans `walk_to`. Il règle l'orientation, mais n'écrit pas la position du joueur après le spawn normal.

Le chemin vise z=-10, -16, -22, -32, -36, -42, -32, -12 puis 7, avec une pause de 0,5 seconde par point. `walk_to` vérifie une distance horizontale inférieure à 0,3 m avant d'incrémenter le compteur. Les étiquettes de trames couvrent toutes les étapes attendues. Les rapports n'exportent pas les positions détaillées de chaque point : la preuve repose sur ces assertions exécutées, les étapes enregistrées, les distances et la source hashée.

Les circuits du candidat restent ON par défaut dans un nouvel état. Le probe vérifie leur API et n'exécute aucune bascule pendant le trajet. Les bits ON ne sont pas exportés séparément dans `journey.json` ; ce point est établi par le chemin d'initialisation et l'absence de commandes. Le test n'évalue pas le coût des alarmes, combats, bascules, menu, chargement initial ou conclusion. Les autres preuves de mission ne servent pas de mesures comparatives ici.

Chaque trame mesurée est un intervalle monotone entre deux appels `_process`, et non un chronométrage isolé du GPU. Les rapports contiennent 7 537 intervalles strictement positifs et finis au total. Dans chaque exécution, le nombre d'intervalles égale le nombre d'étapes enregistrées et le nombre de trames rendues moins un. Le premier intervalle exclut le warmup ; aucune capture d'écran n'est faite en mode perf.

## Résultats recalculés

Chaque percentile est recalculé depuis `frame_intervals_ms` trié, à l'indice `min(floor(n × fraction), n - 1)`, exactement comme le probe. Toutes les valeurs publiées dans les rapports concordent. Le tableau présente la médiane et la plage des cinq percentiles par exécution. Les trames ne sont pas mises en commun pour donner une fausse taille d'échantillon aux tests.

| Qualité | Mesure | Base, médiane [min ; max] ms | Candidat, médiane [min ; max] ms | Écart des médianes | p exact descriptif |
|---|---|---|---|---|---|
| normal | p50 | 81.805 [81.682 ; 83.331] | 83.699 [82.812 ; 84.614] | +2.32 % | 0.01587 |
| normal | p95 | 99.678 [97.743 ; 101.339] | 106.725 [103.500 ; 108.442] | +7.07 % | 0.00794 |
| normal | p99 | 109.758 [107.948 ; 115.847] | 118.010 [112.595 ; 138.827] | +7.52 % | 0.03175 |
| low | p50 | 43.639 [42.842 ; 44.726] | 43.100 [42.478 ; 43.653] | -1.24 % | 0.30952 |
| low | p95 | 58.475 [55.590 ; 59.340] | 55.121 [54.196 ; 57.463] | -5.74 % | 0.05556 |
| low | p99 | 65.111 [63.623 ; 69.004] | 62.052 [58.867 ; 69.189] | -4.70 % | 0.15079 |

Le test descriptif est une permutation bilatérale exacte de la statistique de Mann-Whitney sur les dix valeurs par qualité et percentile, soit 252 répartitions possibles. Les p-values sont exploratoires, sans correction pour comparaisons multiples. La cohérence des cinq paires et les plages séparées du p95 soutiennent le constat Normal. Cinq répétitions ne suffisent pas à garantir une amplitude stable, surtout pour le p99 qui porte sur quelques trames lentes par run.

La durée obtenue en additionnant les intervalles reste proche de 21 secondes. En Normal, sa médiane passe de 20,988 à 21,038 s ; en Low, de 21,028 à 21,010 s. Le déplacement avance selon le temps physique et la route impose des pauses. La hausse des intervalles produit surtout moins de trames, sans ralentissement équivalent du trajet. En Normal, la base rend 262 à 266 trames et le candidat 254 à 261. En Low, les plages sont 483 à 499 et 491 à 504. La cadence et la durée de mission sont deux mesures distinctes.

Les maxima d'appels de dessin passent de 259–263 à 298 en Normal et de 229 à 265 en Low. Les nœuds passent de 541 à 603 et les ressources de 96 à 101 dans chaque qualité. Ce sont des maxima échantillonnés par le probe, pas des moyennes ni une attribution du temps CPU. Ils confirment une charge graphique supplémentaire sans permettre de convertir un appel en millisecondes.

| Run | Intervalles | Trames rendues | p50 ms | p95 ms | p99 ms | Draw max | Nœuds max | Ressources max |
|---|---|---|---|---|---|---|---|---|
| normal-1-baseline | 262 | 263 | 82.176 | 97.743 | 107.948 | 263 | 541 | 96 |
| normal-1-candidate | 253 | 254 | 83.699 | 108.442 | 115.399 | 298 | 603 | 101 |
| normal-2-candidate | 260 | 261 | 82.812 | 107.292 | 138.827 | 298 | 603 | 101 |
| normal-2-baseline | 265 | 266 | 81.805 | 98.189 | 115.847 | 261 | 541 | 96 |
| normal-3-baseline | 265 | 266 | 81.682 | 99.678 | 108.452 | 263 | 541 | 96 |
| normal-3-candidate | 256 | 257 | 84.614 | 103.500 | 112.595 | 298 | 603 | 101 |
| normal-4-candidate | 259 | 260 | 83.459 | 104.582 | 118.010 | 298 | 603 | 101 |
| normal-4-baseline | 264 | 265 | 81.772 | 101.195 | 109.758 | 261 | 541 | 96 |
| normal-5-baseline | 261 | 262 | 83.331 | 101.339 | 111.593 | 259 | 541 | 96 |
| normal-5-candidate | 259 | 260 | 84.355 | 106.725 | 118.452 | 298 | 603 | 101 |
| low-1-baseline | 497 | 498 | 43.185 | 55.590 | 63.861 | 229 | 541 | 96 |
| low-1-candidate | 497 | 498 | 43.100 | 55.121 | 62.052 | 265 | 603 | 101 |
| low-2-candidate | 503 | 504 | 42.984 | 54.196 | 58.867 | 265 | 603 | 101 |
| low-2-baseline | 482 | 483 | 44.726 | 58.475 | 69.004 | 229 | 541 | 96 |
| low-3-baseline | 484 | 485 | 43.661 | 58.549 | 65.111 | 229 | 541 | 96 |
| low-3-candidate | 497 | 498 | 43.589 | 54.781 | 61.762 | 265 | 603 | 101 |
| low-4-candidate | 490 | 491 | 43.653 | 57.463 | 69.189 | 265 | 603 | 101 |
| low-4-baseline | 485 | 486 | 43.639 | 59.340 | 65.543 | 229 | 541 | 96 |
| low-5-baseline | 498 | 499 | 42.842 | 56.448 | 63.623 | 229 | 541 | 96 |
| low-5-candidate | 500 | 501 | 42.478 | 56.139 | 62.880 | 265 | 603 | 101 |

## Coût dominant et hypothèses limitées

[profile-cpu.log](../performance/profile-cpu.log) et [profile-host.log](../performance/profile-host.log) proviennent d'un run séparé [profile-candidate](../proof-tools/runs/profile-candidate), lié au PID 2955445 par [profile-link.json](../performance/profile-link.json). Son manifest correspond au même candidat, au même probe et à la qualité Normal, avec sortie 0 et aucune erreur. Il est exclu des vingt exécutions.

Sur les cinq secondes de pidstat, Godot consomme en moyenne 500,8 % CPU. Les huit threads llvmpipe totalisent 458,4 %, soit 91,5 % du CPU Godot observé. Le thread principal représente 37,4 %. Le rendu logiciel est donc le coût CPU dominant observé. Ce profil n'isole pas une fonction GDScript ni un coût par objet, et ne couvre pas toute la route ou Low. Les amplitudes mesurées restent compatibles avec ce coût ; aucune extrapolation de facteur d'accélération n'en découle.

Deux optimisations bornées sont plausibles, mais non mesurées dans cette revue :

1. Dans `scripts/data/power_consumers.gd:90`, les nouvelles pièces conservent les ombres par défaut. Retirer seulement les ombres des petits montants, leviers et rotors peut réduire les passes Normal. Les feuilles du sas et les gros boîtiers doivent conserver leurs ombres. Low masque déjà la lumière d'ombre, donc ce mécanisme ne prédit pas de gain Low. Une comparaison visuelle et des répétitions séparées sont nécessaires.
2. Les paires de montants jaunes `power_consumers.gd:27` et `:45` partagent parent et matériau. Un MultiMesh de deux instances par paire peut supprimer jusqu'à quatre instances de rendu sur les deux circuits, en suivant la structure du rotor `:53`. Ce plafond est petit face au reste de la scène ; aucun gain en temps n'est assuré.

Le découpage par circuit de `world_art.gd:89` ne justifie pas à lui seul de supprimer des groupes : `_make_batch` refusionne déjà les surfaces non émissives par identité du matériau à `world_art.gd:260`. Les clones émissifs restent distincts pour respecter les circuits. Aucun profil ne justifie de commencer par micro-optimiser les deux `_process` ou `_compose_lights`.

Le diff statique du [shadow-prototype](../shadow-prototype/hypothesis.md) ajoute uniquement un sélecteur, le retrait des ombres avant le warmup et les champs de preuve correspondants. Sur le SHA figé, il sélectionne sept petites pièces par circuit, soit quatorze. Son trajet et ses validations restent ceux du probe original. Ce constat statique ne vaut ni mesure ni validation visuelle et aucun résultat de prototype n'entre dans le verdict ci-dessus.

## Fin de revue

Les seuls fichiers écrits par cette tranche sont ce rapport et [audit_perf.py](../perf-audit/audit_perf.py). Aucun worktree créé ou modifié, aucun moteur lancé, aucun commit effectué. Le script de recalcul passe ses contrôles sur les vingt exécutions sans erreur. Le percentile par indice et les queues du test exact ont aussi été contrôlés avec des séries connues. La preuve est utilisable pour cette comparaison Linux ; le coût Normal reste un problème mesuré à traiter ou à accepter explicitement.
