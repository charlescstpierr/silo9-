# Audit indépendant des performances — ticket 7

**Verdict : aucune différence mesurable démontrée dans cette campagne ; performance de production non déterminée.** Les plages se chevauchent et les deltas appariés changent de signe. Ces résultats ne justifient ni un gain de vitesse ni une garantie d'absence de régression sur un PC de jeu.

Audit exécuté après notification de fin des dix runs. Aucun Godot, rendu, profilage ou ffmpeg lancé par cet auditeur. Relecture indépendante du runner, de la sonde et du collecteur CPU ; recalcul par `audit.py`, sans importer leurs fonctions de validation. Exécution finale : **473 contrôles, sortie 0** (`audit.log`, résultats détaillés dans `audit.json`). Une première exécution de l'auditeur a rencontré le pathspec Git absent `scenes` ; corrigé en archivant les seuls chemins renvoyés par `git ls-tree`. Aucun artefact mesuré n'a été modifié.

## Mesure et répétabilité

Cinq runs par version, cinq paires d'ordre alterné : A/B, B/A, A/B, B/A, A/B. Les chiffres ci-dessous sont les médianes des percentiles calculés pour chaque run, avec leur plage entre runs ; ce ne sont pas les percentiles d'un regroupement de toutes les frames.

| Intervalle de frame | Avant `2818e15` | Après `1f36f01` |
|---|---:|---:|
| P50, médiane [min–max] | 94,823 ms [93,618–103,501] | 94,664 ms [92,953–96,453] |
| P95, médiane [min–max] | 119,371 ms [111,863–133,695] | 113,132 ms [108,130–116,632] |

Le calcul reprend exactement la convention documentée : valeur triée à l'indice `floor(n × fraction)`. Les valeurs recalculées et les agrégats correspondent aux dix journaux et à `performance.json`. Test exact de rang-somme, 252 répartitions : p bilatéral 0,421 pour P50 et 0,310 pour P95. Ce petit échantillon ne prouve pas l'équivalence ; il ne donne pas de gagnant. Les cinq deltas appariés du P50 sont −1,870 / −7,048 / −3,140 / +0,053 / +1,094 ms.

Les 141 à 156 intervalles de chaque run couvrent environ 14,69 à 15,05 secondes du parcours. Ils incluent tout le travail entre callbacks, l'ordonnancement et le VSync éventuel. Import, création initiale du monde et capture de chauffe sont hors de cette fenêtre. Le temps total de lancement n'est pas présenté comme la mesure du parcours.

## Travail et intégrité

- Dix sorties 0, zéro erreur moteur détectée et aucune panne de parcours. Chaque run accomplit six tirs D9 et deux tirs ARC, huit impacts et 246 dégâts, avec consommation de munitions/énergie vérifiée événement par événement.
- Mouvement horizontal +X recalculé depuis les positions ; rechargement R observé : chargeur 8 → 12 et réserve 48 → 44. La sonde vérifie la cellule consommée et l'énergie restaurée par B ; les événements enregistrés montrent ensuite 76 → 100 d'énergie.
- Source lue depuis Git et disque : 187 fichiers avant, 192 après. Les deux révisions et les empreintes de chaque manifeste concordent. Les copies du runner et de la sonde au lancement concordent avec les fichiers finaux. Le binaire Godot correspond à l'empreinte de campagne.
- Godot 4.7.2, X11, Compatibility/OpenGL, llvmpipe LLVM 21.1.8, 1280 × 720, qualité normale. Rendu actif et nombre de frames dessinées croissant. Enveloppes PNG de chauffe valides ; cet audit ne remplace pas leur revue visuelle.
- Aucun mode film, cadence fixe ou headless dans les dix commandes mesurées. Le profil séparé valide aussi huit impacts et 246 dégâts et utilise la même source et la même sonde. Il n'entre dans aucun agrégat comparatif. L'ancien profil à sept impacts est exclu.

## Limiteur et portée

Le profil séparé contient 40 échantillons de threads. Recalcul indépendant : 400,57 % de CPU processus moyen, dont **85,97 % du temps CPU observé dans les threads llvmpipe**. Sur les 24 échantillons centraux : 471,03 % de CPU et 90,02 % dans llvmpipe. Le rendu logiciel domine le travail CPU observé. Ce relevé ne mesure pas la pile d'appels, la totalité des attentes ni un GPU physique : il ne prouve pas que llvmpipe est l'unique limite. Les huit CPU visibles et cette consommation restent cohérents ; aucun débit matériel impossible n'est revendiqué.

Les charges à une minute enregistrées avant/après les runs vont de 1,85 à 5,92 sur huit CPU visibles. L'alternance réduit le biais temporel sans supprimer le bruit de la machine. L'absence de processus concurrents n'est pas reconstructible indépendamment à partir de ces seuls manifestes ; l'isolation d'exécution reste la vérification du coordinateur.

Il s'agit du projet source lancé avec le binaire éditeur, pas d'un export de production optimisé. Les callbacks des ennemis sont gelés et une cible de preuve est ajoutée dans le SILO réel. La distance parcourue varie de 1,067 à 1,267 m, les attentes en secondes étant quantifiées aux ticks ; le zoom ADS change également le volume visible. Les maxima sont 377 appels de dessin avant, 376–377 après, 682 → 686 nœuds et 83 ressources des deux côtés. Ces mesures ne permettent pas d'isoler le coût du calcul ADS.

**Aucune affirmation Windows, manette physique, GPU cible, 60 FPS, amélioration perceptible ou coût ADS nul.** L'audit accepte l'intégrité de cette campagne et sa conclusion limitée, pas un objectif de performance produit.

## Reproduction et libération

Depuis la racine du dépôt :

```sh
python3 .cstack/orchestrate/silo9/issue07/perf-audit/audit.py
```

Chemins écrits exclusivement sous `.cstack/orchestrate/silo9/issue07/perf-audit/` : `audit.py`, `audit.json`, `audit.log`, `report.md`. Aucun worktree créé, aucun commit, aucune source modifiée. Worktree lu : `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-07`, branche `feat/issue-07-ads`, source `1f36f01eea2e5d34dafee7f46a665c013370cbb4`. Aucun descendant ou processus persistant ; tous les fichiers sont relâchés.
