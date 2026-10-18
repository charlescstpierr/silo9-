# Audit indépendant de performance — ticket 8

**Aucune différence de performance détectable dans cette campagne Linux avec rendu logiciel.** Les 542 assertions de l’audit final passent. Cela valide les artefacts de ces dix mesures, pas une équivalence de performance ni une absence de régression sur GPU joueur.

Base : `98f2d4a735d7c2fe1ad6f3d8431ab86772db1e8a`. Candidat : `efc2a581fd329321a852507d775af6fcda0a9cb1`. Cinq paires complètes, ordre AB/BA/AB/BA/AB, données exclusivement issues de `performance-final/`.

| Mesure | Base : médiane [min–max] | Candidat : médiane [min–max] |
|---|---:|---:|
| p50 des intervalles de frames | 93,027 ms [90,327–95,993] | 91,925 ms [91,217–96,786] |
| p95 des intervalles de frames | 110,534 ms [107,561–115,877] | 109,625 ms [107,784–117,703] |
| Maximum de draw calls observé par run | 377 [377–377] | 377 [376–377] |
| Maximum de nœuds | 686 [686–686] | 686 [686–686] |
| Maximum de ressources | 83 [83–83] | 96 [96–96] |

Les médianes sont celles des cinq statistiques par version, pas un percentile calculé sur toutes les frames fusionnées. Le p50 baisse nominalement de 1,102 ms, soit environ 1,18 %, mais l’écart est inférieur aux variations entre runs. Les deltas candidat moins base des cinq paires sont +3,468 ; −4,092 ; +1,598 ; −0,074 ; −0,999 ms. Pour le p95 : +2,693 ; +1,826 ; −2,750 ; +1,196 ; +0,708 ms. Le p95 médian légèrement inférieur ne justifie donc pas davantage un gain.

Les tests de rang exacts sur les cinq valeurs de chaque côté donnent p=0,690476 pour le p50 et p=1 pour le p95, sur 252 permutations. Ce contrôle descriptif ne détecte pas de séparation ; il n’est ni un test d’équivalence ni un seuil de livraison prouvant l’absence de régression. Les paires et les plages brutes sont conservées dans `audit.json`.

## Travail effectivement vérifié

L’audit a relu et comparé les archives Git, les fichiers des projets mesurés, les SHA des outils et du moteur, les snapshots du probe/runner au lancement, les manifestes, les imports, les logs moteur, chaque `journey.json` et les agrégats. Les dix runs ont un exit 0, sans erreur moteur détectée, avec campagne inchangée. Le HEAD candidat actuel correspond au commit annoncé. Le SHA de `run_perf_pair.py` correspond à `pair-runner-sha256.txt` ; cet adaptateur réutilise `prove_ads.prepare/invoke` et les mêmes agrégations. Son hash latéral est vérifié actuellement, sans prétendre disposer d’un hash indépendant de l’adaptateur à chaque lancement.

Chaque run contient huit tirs acceptés et huit impacts, 246 dégâts, six D9 et deux ARC, les bons débits de munitions/énergie, des trajectoires finies et des impacts sur la cible. R transfère quatre cartouches (8→12, réserve 48→44). B est couvert par l’assertion moteur de consommation d’une cellule et recharge, sans failure, et par l’énergie observée 76→100 entre les tirs encadrants ; le JSON ne conserve pas une ligne brute dédiée au nombre de cellules avant/après B. Le déplacement réel vers +X vaut 1,067 à 1,200 m suivant les ticks. Les stages mouvement, R, B et retour au repos figurent dans les intervalles chronométrés.

Les valeurs p50/p95 ont été recalculées depuis les intervalles bruts avec la convention du probe : tri puis index floor(N×fraction). Les runs contiennent 149 à 160 intervalles et 14,581 à 14,868 s de temps cumulé. Les réglages sont identiques : Godot 4.7.2, X11, OpenGL Compatibility, 1280×720, qualité Normal, llvmpipe LLVM 21.1.8. Le rendu est actif et le compteur de frames dessinées progresse. Chaque PNG de chauffe est vérifié pour son enveloppe PNG et ses dimensions ; cet audit n’en inspecte pas les pixels.

L’augmentation de 13 ressources est mesurée. Ce compteur ne donne ni mémoire VRAM, ni octets de textures, ni coût attribuable à chaque ressource. Le plafond observé de draw calls reste 377 et le nombre de nœuds 686 ; un run candidat a culminé à 376. Cela ne prouve pas un gain d’un draw call à charge parfaitement identique.

## FOV et avertissement hérité

Les fichiers `player.gd`, `fps_rig.gd`, `weapon_handling.gd` et `project.godot` sont identiques octet pour octet entre les deux commits. Les dix journeys déclarent la même API ADS et un FOV de base 76 ; la capture de chauffe observe 76. Les observations de tirs stabilisés sont strictement identiques entre les dix runs : D9 hip 76,400002°, D9 ADS 64,413116°, ARC ADS 64,263115°. Ces observations incluent l’impulsion de recul propre à chaque arme.

Le warning générique « candidate zoom changes viewing volume » du runner/probe ne s’applique donc pas comme différence fonctionnelle à cette comparaison. Les tirs pendant entrée/inversion restent échantillonnés à des phases variables ; leurs valeurs complètes sont conservées, sans prétendre que chaque frame ou volume visible est identique. Les variations de déplacement/ticks constituent toujours une limite du parcours.

## Profil séparé et interprétation du coût

Le profil candidat est exclu des dix mesures. Son moteur, son probe, son runner et ses hashes de source correspondent à la campagne finale. Il termine sans erreur avec huit impacts et 246 dégâts. Le sampler lit les ticks CPU des threads via `/proc` environ toutes les 0,5 s ; il n’instrumente pas les fonctions du moteur.

Sur 40 observations couvrant 20,41 s, les threads llvmpipe représentent **85,55 % du CPU échantillonné du processus**, pour une somme moyenne de 396,20 % CPU. Sur les 24 observations centrales (12,06 s), ils représentent **89,86 %**, somme moyenne 461,21 %. À huit CPU logiques, ces sommes représentent environ 49,5 % et 57,7 % de la capacité théorique de l’hôte. La fenêtre centrale est une approximation de régime établi, pas une délimitation instrumentée de la région mesurée.

Le rendu logiciel est donc le travail CPU dominant observé. Ce profil ne prouve ni une saturation totale du processeur, ni l’exclusivité de ce facteur limitant, ni le coût exact des nouveaux matériaux. Les attentes, synchronisations, l’ordonnanceur et VSync restent inclus dans les intervalles muraux. La charge système à une minute relevée aux frontières des runs varie de 0,854 à 4,272 sur huit CPU ; l’alternance réduit le biais temporel, sans supprimer tout bruit.

## Portée, provenance et reproductibilité

Le parcours mesuré se déroule dans le SILO réel, avec ennemis figés et petite cible de preuve visible. Il couvre déplacement, visée, tirs, R/B et changements d’arme. Les imports et PNG de chauffe sont avant la région chronométrée ; ni film, ni capture répétée, ni profileur dans ces dix mesures selon les commandes et sources contrôlées. L’absence de tout processus externe concurrent n’est pas démontrée par les manifestes seuls : le coordinateur détient l’affichage et rapporte la sérialisation des captures. Le profil utilisé ici est une exécution distincte.

Les deux versions sont lancées depuis les sources avec le même moteur. Ce ne sont pas des exports release ni des mesures Windows ou GPU joueur. Aucun objectif de 60 FPS, gain de GPU ou parité graphique n’est établi. La revue visuelle des dix warmups rapportée par le parent reste une preuve séparée, non un résultat observé par cet auditeur.

La première campagne `performance/` a été interrompue par SIGTERM, exit 143, cause inconnue : quatre runs complets et un cinquième sans manifeste final. Elle est entièrement exclue, sans compléter ni sélectionner les runs de la campagne finale.

**Historique d’exécution de l’audit :** le premier lancement a échoué sur une assertion trop stricte de mon script, conservée dans `audit-attempt1.log`. `invoke` ajoute `project_identity` au résultat alors que `run/journey.json` reste brut. La correction vérifie maintenant séparément l’égalité de tous les champs bruts et l’identité ajoutée, qui doit correspondre exactement aux hashes candidat de la campagne finale. Aucun artefact mesuré n’a été modifié. Les passages ultérieurs ont réussi ; la dernière version ajoute aussi les contrôles des imports et de l’identité moteur/outils du profil et termine avec 542 assertions.

Commande réexécutable depuis la racine du projet :

```sh
python3 .cstack/orchestrate/silo9/issue08/perf-audit/audit.py
```

Résultats : `audit.json` (assertions, hashes, statistiques, FOV, profil et limites), `audit.log` (dernier passage exit 0), `audit-attempt1.log` (échec initial documenté). L’auditeur a exécuté Python et des lectures Git ; il n’a lancé aucun Godot, ffmpeg, profil ou benchmark. Aucun source de production, commit ou worktree modifié. Accès relâchés à la remise.
