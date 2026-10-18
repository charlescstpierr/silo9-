# Audit indépendant — éclairage, ticket 09

**Brouillon : campagne Low ciblée encore attendue.**

Le trajet principal montre des intervalles plus courts en Normal sur le rendu logiciel local, sans différence établie en Low. Les quatre compléments sont valides mais exploratoires ; ils révèlent un coût possible de la lampe avec alarme en Low, à confirmer. Cela ne valide aucun objectif de FPS sur PC joueur.

## Trajet principal : preuve PASS

Audit indépendant de vingt runs et dix paires : **3 658 contrôles, 7 452 intervalles, zéro erreur**. Les contrôles sont rejouables avec [audit.py](audit.py), les résultats détaillés dans [audit.json](audit.json) et [runs.tsv](runs.tsv). Ils n'exécutent aucun moteur.

Les quantiles sont recalculés depuis tous les intervalles bruts de chaque run : tri puis indice `min(int(n × fraction), n − 1)`, conforme à la sonde, sans interpolation. Le tableau donne la médiane des cinq quantiles par version, puis leur plage min–max. Il ne mélange pas les frames de plusieurs runs en un seul quantile.

| Qualité / quantile | Baseline, ms : médiane [plage] | Candidat, ms : médiane [plage] | Différence des médianes |
|---|---:|---:|---:|
| Normal p50 | 89,028 [87,161–91,738] | 74,142 [71,700–74,872] | −16,72 % |
| Normal p95 | 109,335 [107,468–130,702] | 89,879 [88,218–93,845] | −17,79 % |
| Normal p99 | 118,467 [115,025–140,839] | 100,519 [96,459–102,320] | −15,15 % |
| Low p50 | 43,990 [42,915–46,943] | 44,411 [43,865–46,053] | +0,96 % |
| Low p95 | 59,367 [56,923–62,212] | 58,840 [57,434–61,170] | −0,89 % |
| Low p99 | 69,464 [65,145–69,776] | 65,949 [64,420–72,988] | −5,06 % |

En Normal, les cinq différences appariées sont négatives et les plages sont séparées pour les trois quantiles. Les différences appariées p50 sont −17,516, −16,289, −14,156, −16,637 et −13,019 ms ; leur médiane est −16,289 ms. La médiane des différences appariées p95 est −20,302 ms. Le signal se reproduit dans cette campagne, sans revendication de significativité statistique à 95 % ni extrapolation matérielle.

En Low, les plages se recouvrent et les différences appariées changent de signe : p50 +1,361, −2,732, +0,704, −0,125 et +1,496 ms. Aucun gain ni régression établi sur ce trajet. La baisse de la médiane p99 seule ne suffit pas à conclure.

## Travail réellement exécuté et provenance

Les vingt moteurs et leurs wrappers finissent avec code 0, sans erreur de script/moteur ni échec de validation. Neuf coordonnées sont identiques dans l'ordre, pour 92,433439 m parcourus physiquement ; aucune téléportation après le démarrage normal. Les étapes comprennent la marche via Input, une orientation scriptée, huit frames physiques d'arrêt et 0,5 seconde d'attente à chaque station. Deux secondes de chauffe précèdent la mesure. La mesure couvre environ 20,895–21,176 secondes par run. Le nombre d'images dessinées est exactement le nombre d'intervalles + 1 dans chaque run.

Les paires impaires suivent baseline puis candidat ; les paires paires inversent cet ordre. Tous les intervalles de lancement sont sérialisés. Les deux qualités sont des campagnes distinctes, Normal puis Low. Les logs, commandes et sources ne contiennent pas de capture ou d'encodeur dans les régions mesurées. Le profil est exécuté séparément.

- Baseline : `e5b0bafa7b8bad369e6767a908b1d8391343b9f2`.
- Candidat : `653e2a79c7f36e9ac7422335c85cef3b937ed0f9`.
- Moteur SHA256 : `8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e`.
- Wrapper SHA256 : `bc45ab99e5dd1cf55401fe99d67385ad365588f4f8b63fe4b887762e050124cd`.
- Sonde primaire SHA256 : `28e9cd57c0e56f0c06601539d5cd7d35154e1191eea2568d9e6cbe0d2e47bf44`.

Les fingerprints source sont identiques avant/après et entre les runs d'une même version. Les hashes moteur/wrapper/sonde sont enregistrés avant et après chacun des vingt runs, concordent avec les fichiers vérifiés, et les worktrees suivis correspondent aux HEAD annoncés lors de l'audit. Les fichiers non suivis présents sont inclus dans les fingerprints de mesure. Aucun ancien timing du ticket 12 n'est réutilisé comme baseline.

## Mesure et limiteur

Godot 4.7.2 officiel, exécution du projet source avec sonde externe, X11 Compatibility, 1280 × 720, llvmpipe LLVM 21.1.8 sur hôte huit CPU. Normal utilise l'échelle 1 ; Low l'échelle 0,67. Audio Dummy. Le driver signale que le changement de V-Sync n'est pas pris en charge ; c'est un avertissement commun, pas une erreur de la campagne. Ce protocole compare les deux versions dans la même configuration locale ; il n'est pas un benchmark de l'exécutable release distribué.

La sonde mesure le temps mural entre callbacks `_process`, avec progression des images dessinées vérifiée. Elle ne mesure pas directement le temps GPU. Son instrumentation, les étapes de parcours et les attentes font partie du protocole commun ; aucune estimation de leur coût propre n'est soustraite.

Le [profil synchronisé](profile.json) couvre cinq secondes au début de la route du candidat Normal : Godot **443,91 % CPU**, dont **400,59 %** pour les huit threads llvmpipe, soit **90,24 % du CPU du processus** ; thread principal **38,12 %**. La charge dominante observée est donc le rendu logiciel. Ces pourcentages restent sous les 800 % théoriques de huit CPU. Les attentes d'ordonnancement et les autres occupants de l'hôte peuvent affecter les timings ; le serveur n'est pas dédié.

Le marqueur `PROFILE_ROUTE_BEGIN` est ajouté uniquement à l'entrée de `performance_route`, après construction et chauffe. Le lanceur attend son apparition avant de trouver le PID enfant et lancer `pidstat -t -u … 1 5`. Le marqueur est à 6,623 s de temps moteur, le lancement du profil à 6,720 s après le timestamp du wrapper ; les logs et le PID concordent. Le lanceur a été archivé après exécution. [audit_profile.py](audit_profile.py) vérifie l'unique delta de la sonde et les chiffres ; le wrapper reste identique. Le profil initial trop précoce est exclu de cette attribution, et aucun chiffre CPU du ticket 12 n'est repris.

Cette fenêtre identifie la catégorie de travail dominante, pas la contribution exacte d'une lumière, d'une ombre, d'un matériau ou d'une fonction. Aucun profil CPU comparable baseline/Low ni profil de chaque station n'est disponible. La baisse Normal est cohérente avec une baisse des draw calls, mais cette corrélation ne prouve pas une microcause.

Au départ de la campagne, la charge moyenne était 0,73 / 1,70 / 1,35 sur huit CPU (`perf/host-start.txt`). L'alternance limite un biais temporel ; elle ne rend pas l'hôte exclusif.

## Compteurs et limites de couverture

| Compteur maximum par run | Baseline Normal | Candidat Normal | Baseline Low | Candidat Low |
|---|---:|---:|---:|---:|
| Draw calls | 298–301 | 277 | 265 | 270 |
| Nœuds | 603 | 607 | 603 | 607 |
| Ressources | 101 | 101 | 101 | 101 |

Le compteur de ressources est un nombre d'objets Godot, pas de la mémoire ni de la VRAM. Les états finaux montrent neuf lumières fixes visibles baseline Normal contre sept candidat Normal, six contre six en Low. Il s'agit de visibilité dans l'arbre de scène, pas d'un décompte des lumières contributrices par frame ou visibles dans le frustum. La lampe candidat reste éteinte et les lumières fixes sont sans ombre dans ces états finaux.

Le trajet couvre refuge, Maintenance, Archives puis retour au refuge, circuits ON, alarme OFF et ennemis retirés. Il ne mesure pas le cœur, la lampe ON, les alarmes actives, le combat, la charge d'une mission entière ni le mode Windows. Le gain Normal ne doit donc pas être présenté comme un gain général du jeu. Les preuves de missions et les captures sont des vérifications distinctes ; elles n'étendent pas le périmètre de ces timings.

## Compléments exploratoires : preuve PASS, signal de coût à confirmer

Les quatre nouveaux runs `cost-final-*` passent **290 contrôles**, **16 fenêtres** et **1 640 intervalles**, sans erreur. [audit_cost.py](audit_cost.py) et [cost.json](cost.json) vérifient les bornes, les états et recalculent les quantiles. Une exécution par qualité/version : ces résultats servent à détecter un risque, sans établir un gain ou une régression.

Les anciens `cost-normal-*` et `cost-low-candidate` sont exclus, ainsi que le diagnostic `cost-clock-check`. L'ancien validateur rejetait à tort une fenêtre dont la latence du premier callback non mesuré dépassait le plus grand intervalle mesuré. La copie distincte `cost-proof-tools` ancre désormais les six secondes au premier callback réellement relevé ; elle sérialise début/fin, vérifie leur différence contre la somme des intervalles, leur encadrement par les observations et l'arrêt au premier callback atteignant l'échéance. Les vingt runs primaires et leurs outils restent inchangés.

Le delta GDScript est limité à ce mécanisme dans `lighting_route` ; `_process`, déplacements et parcours primaires restent identiques. Le validateur utilise une tolérance numérique de 0,01 microseconde pour la somme flottante, inférieure à la résolution de l'horloge. Toutes les fenêtres satisfont `frames_drawn = intervalles + 1`, durent au moins six secondes et moins de six secondes + leur dernier intervalle, avec des observations fixes avant/après. Matériaux, nœuds, ressources, pose, énergie, circuits, lumières et acteurs vivants sont stables entre les observations.

Les poses sont téléportées, les acteurs vivants et horloges d'éclairage sont figés ; l'alarme de Maintenance est maintenue active artificiellement. Les suffixes `_off`/`_on` désignent la lampe, **pas l'alarme**, active dans les deux fenêtres Maintenance. La baseline n'a pas de lampe : sa paire de fenêtres n'est pas une comparaison ON/OFF d'une lampe existante. Le candidat Normal utilise une seule ombre lorsque sa lampe est ON ; Low n'en utilise aucune. Ce sont des coûts de scènes contrôlées, pas des trajets ni la durée naturelle de l'alarme.

| Qualité / fenêtre | Baseline p50 / p95, ms | Candidat p50 / p95, ms |
|---|---:|---:|
| Normal cœur lampe OFF | 78,211 / 91,237 | 66,033 / 79,953 |
| Normal cœur lampe ON | 75,988 / 89,526 | 83,148 / 98,194 |
| Normal Maintenance alarme tenue, lampe OFF | 82,333 / 96,538 | 85,274 / 98,538 |
| Normal Maintenance alarme tenue, lampe ON | 79,745 / 91,689 | 92,440 / 105,634 |
| Low cœur lampe OFF | 38,833 / 47,423 | 38,223 / 46,870 |
| Low cœur lampe ON | 36,776 / 46,134 | 39,068 / 49,058 |
| Low Maintenance alarme tenue, lampe OFF | 52,719 / 65,574 | 54,137 / 67,667 |
| Low Maintenance alarme tenue, lampe ON | 52,094 / 61,686 | 63,224 / 90,505 |

Le signal Low en Maintenance, lampe ON, atteint +21,4 % au p50 et +46,7 % au p95 dans cet essai unique. Conformément au plan préalable, le parent a lancé cinq paires ciblées pour déterminer s'il se reproduit. Aucune conclusion finale de coût sur ce cas tant que ces dix runs ne sont pas audités.

## Portée de la revue

Aucun moteur, encodeur ou descendant lancé par le reviewer. Aucun changement dans les sources, outils de preuve, mesures, Git ou GitHub. Seuls `perf-audit/*` et le rapport final de revue appartiennent à cette tranche. Aucun worktree créé ni processus actif. Validation GPU cible et exécution Windows restent absentes.
