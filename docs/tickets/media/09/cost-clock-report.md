# Correction de l’horloge des mesures complémentaires

Périmètre : seulement `cost-proof-tools/{probe_sector_power.gd,prove_sector_power.py,selfcheck_sector_power.py}`, copies des outils gelés. Aucun fichier de production, test du jeu, worktree, campagne passée ou commit modifié. Les trois hashes des outils gelés sont conformes à leur SHA256.json (`cost-proof-tools/frozen-identity.json`).

## Cause et correction

Le dernier volet de `cost-low-candidate/journey.json` mesure 5922,911 ms d’intervalles, avec un intervalle maximal de 75,440 ms et 6006,737 ms entre observations. L’ancien délai de six secondes commençait avant le premier callback mesuré. Ce premier délai absent des intervalles pouvait excéder leur maximum : la tolérance était incorrecte.

La nouvelle sonde active le relevé puis attend le premier `previous_usec` non nul, produit exclusivement par `_process`. Elle mémorise ce premier tick, attend que les callbacks réels atteignent premier tick + 6000000 µs, puis désactive le relevé. Les continuations `process_frame` consomment le tick du callback déjà réalisé ; elles ne fabriquent aucun tick. Les bornes `measurement_start_usec` et `measurement_end_usec` sont sérialisées avec la fenêtre. Un seul corps de fonction GDScript a changé : `lighting_route`. Toutes les autres fonctions, dont `_process`, parcours historiques et missions, sont identiques (`cost-proof-tools/function-identity.json`).

Le validateur exige des bornes monotones entières positives, leur encadrement par les observations before/after, et l’égalité somme des intervalles / différence des bornes à 0,01 µs près (tolérance de représentation flottante, inférieure à la résolution microseconde). Il exige une durée >= 6000000 µs et strictement < 6000000 µs + dernier intervalle : le callback précédent est donc encore avant l’échéance. La première latence non mesurée n’entre plus dans la durée comparée. `frames_drawn == len(intervals)+1`, séparation des quatre fenêtres et interdiction des captures restent contrôlées.

## TDD

Commande : `python3 .cstack/orchestrate/silo9/issue09/cost-proof-tools/selfcheck_sector_power.py`.

- Avant correction : exit1, 12 échecs attendus, 16 tests exécutés. `clock-red.log` et `clock-red.json` prouvent que sonde et validateur étaient encore identiques aux originaux.
- Après correction : exit0, 16 tests verts, `clock-green.log`.
- Cas : première latence légitime de 500 ms acceptée ; arrondi au dernier callback accepté ; durées courtes/longues, callback de trop, bornes absentes, déplacement de 1 µs incompatible avec somme, observations non encadrantes, booléens, NaN, négatifs et timestamp non entier refusés.

## Vérification runtime limitée

Commande exécutée une seule fois :

```sh
python3 .cstack/orchestrate/silo9/issue09/cost-proof-tools/prove_sector_power.py --project .worktrees/silo9-issue-09 --godot .tools/Godot_v4.7.2-stable_linux.x86_64 --output .cstack/orchestrate/silo9/issue09/cost-clock-check --mode lighting-perf --require-circuits --require-lighting --low --timeout 180
```

Session74259 : wrapper exit0, Godot exit0, validation sans erreur, sources inchangées, HEAD `653e2a79c7f36e9ac7422335c85cef3b937ed0f9`. Linux X11 :100, llvmpipe, audio Dummy. Aucun cycle Xvfb ni ffmpeg. C’est un diagnostic de l’outil exclu des mesures de livraison.

| Fenêtre | Intervalles | Frames | Somme = bornes (ms) | Dernier intervalle (ms) |
|---|---:|---:|---:|---:|
| core_off | 152 | 153 | 6029,608 | 34,695 |
| core_on | 134 | 135 | 6025,345 | 38,553 |
| maintenance_alarm_off | 106 | 107 | 6006,178 | 52,033 |
| maintenance_alarm_on | 100 | 101 | 6039,220 | 58,147 |

Les quatre bornes sont encadrées par leurs observations et les quatre identités frames/intervalles sont exactes. Détail dans `cost-clock-check/clock-audit.json`, commande et hashes moteur/outils dans `cost-clock-check/manifest.json`. Les hashes des trois outils corrigés sont dans `cost-proof-tools/SHA256.json`.

Les vingt runs primaires et les trois anciens compléments n’ont pas été réécrits. Les anciens compléments restent exclus ; le parent peut lancer quatre nouveaux compléments avec cette version corrigée. Ce diagnostic ne prouve ni FPS cible, ni Windows, ni performance GPU joueur.

## Libération

Runtime :100 libéré après sortie0 du seul Godot lancé. Aucun processus de cette tranche actif, aucun descendant, aucun worktree créé. Les trois outils corrigés et le rapport sont libérés pour revue parent ; aucun commit, push ou PR effectué.
