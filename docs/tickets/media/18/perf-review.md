# Revue indépendante de performance du ticket 18

**PASS pour la validité des vingt runs retenus. Coût p50 Low reproduit dans les cinq paires ; différence Normal et queues p95/p99 non concluantes. Aucun gain revendiqué.** En Low, la différence appariée candidat moins référence vaut une médiane de **+1,810 ms, soit +4,39 %**, avec cinq écarts positifs de +1,420 à +2,799 ms. Il s'agit du coût observé de cette fonctionnalité dans cette campagne locale, pas d'une estimation sur le GPU d'un joueur.

Le profil séparé est valide : les threads llvmpipe représentent 92,1 % de la consommation CPU de Godot pendant cinq secondes du trajet Normal. Ce résultat situe le travail dominant dans le rendu logiciel. Il ne mesure pas le coût marginal de chaque carcasse et ne constitue pas un profil Low.

## Données retenues et intégrité

Référence : `28e402821469655598c6a84bc415d8ea04da97c2`, worktree `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-10`. Candidat : `c105da61b2b490546f01c9d67703bfb405a2a44f`, worktree voisin `silo9-issue-18`, branche `feat/issue-18-world-persistence`.

`perf-audit/audit_campaign.py` a été exécuté après la fin des vingt runs. Il n'importe ni le lanceur ni le validateur de l'auteur. Il a lu les rapports, les journaux et les manifestes de chaque run, recalculé les résultats et comparé les fichiers réels au gel. Résultat : vingt runs, dix paires, zéro erreur d'audit, code 0. `perf-audit/campaign-audit.json` contient les contrôles, chaque run et toutes les distributions ; `perf-summary.json` est la synthèse chiffrée.

Le gel SHA-256 `17857f5b48a0dddab62a5087f0c0c9d8ffb04e8e05c3a4a26d73860156d8bbb5` concorde avec le moteur, le lanceur, les trois copies indépendantes des outils et les 2 591 fichiers de référence / 2 602 du candidat. Les manifestes avant/après concordent pour tous les runs. Les commandes réelles pointent vers les copies figées de `proof-tools`, sans substitution par les outils suivis d'un projet. La source candidate reste inchangée.

La paire initiale sous `perf-interrupted-01` est entièrement exclue, y compris sa référence terminée. Son reçu décrit une sortie 143 du superviseur pendant le candidat et une cause non établie. Aucun de ses temps ne figure dans les calculs. Les diagnostics antérieurs sous `proof-tool-tests`, dont la chauffe candidate de 1,961 s refusée, sont également exclus. Le profil est exécuté après la dernière paire et ne compte jamais comme une répétition de campagne.

## Réalité du parcours et des états

Les cinq paires Normal puis les cinq Low alternent l'ordre référence/candidat. Leurs fenêtres sont sérialisées. Chaque run utilise Godot 4.7.2, X11 Compatibility, llvmpipe et une fenêtre 1280×720. Les commandes demandent séparément lampe ON, circuits et éclairage ; les observations confirment une lampe visible, voulue, émissive et mobile à chaque callback. Le mode Low réel applique une échelle 3D de 0,67 et coupe l'ombre de lampe ; Normal garde l'échelle 1 et son ombre.

La préparation, hors mesure, est identique entre versions et répétitions : six vraies instances Enemy identifiées, vivantes avant `receive_hit`, à leurs positions réelles, puis santé nulle, collision coupée, traitement physique arrêté et défaite inscrite. La caisse reçoit un vrai Player.fire D9 : cible et bounds identifiés, rayon/impact liés, munitions de 12 à 11 et énergie inchangée. La référence garde sa caisse intacte et bloquante ; le candidat présente ses trois panneaux sans collision. Cette différence terminale est intentionnelle.

Avant chauffe et avant mesure : six défaites, aucun ennemi vivant, six traces côté candidat / zéro côté référence, départ restauré immobile, zéro douille et aucun impact, muzzle, beam ou lumière transitoire actif. La chauffe monotone observée va de 2 001,248 à 2 076,546 ms. À la fin, les dix-huit meshes réels des six traces candidates sont visibles, trois par robot, aux lieux de mort et partagent trois matériaux ; aucune trace n'est inventée sur la référence.

Chaque run parcourt les neuf stations dans l'ordre pour 92,433439 m. L'audit a recoupé **7 666 intervalles bruts et 7 686 frames dessinées** avec leurs timestamps, étapes et bornes de mesure. Le nombre d'intervalles par run varie de 252 à 276 en Normal et de 479 à 509 en Low ; ces tailles restent visibles dans les résultats, sans fusion artificielle des runs. La somme des intervalles vaut environ 20,90 à 21,14 s par trajet.

La preuve distincte `reload-budget/report.md`, au même candidat, confirme six mêmes ArrayMesh, trois matériaux robot et dix-neuf instances de restes stables après deux échauffements et vingt rechargements réels. Elle ne remplace pas les observations de chaque run de performance.

## Quantiles et différences appariées

Valeurs en millisecondes. Chaque case donne la médiane des cinq runs, puis leur plage. La dernière colonne est la médiane des **cinq différences appariées**, puis leur plage ; elle n'est pas la soustraction des deux médianes précédentes.

| Qualité / quantile | Référence, médiane [min ; max] | Candidat, médiane [min ; max] | Candidat − référence par paire |
| --- | ---: | ---: | ---: |
| Normal p50 | 76,899 [75,768 ; 79,405] | 78,687 [76,834 ; 80,280] | +1,982 [−2,040 ; +2,480] |
| Normal p95 | 96,050 [92,635 ; 97,744] | 95,650 [94,448 ; 108,343] | +1,193 [−2,512 ; +10,599] |
| Normal p99 | 105,359 [99,464 ; 122,602] | 105,074 [102,307 ; 121,884] | +3,360 [−10,993 ; +7,121] |
| Low p50 | 41,537 [40,861 ; 41,603] | 43,023 [42,973 ; 44,381] | +1,810 [+1,420 ; +2,799] |
| Low p95 | 53,612 [51,451 ; 54,490] | 56,464 [52,174 ; 57,846] | +3,209 [−2,316 ; +5,663] |
| Low p99 | 60,854 [56,480 ; 65,024] | 63,360 [55,808 ; 72,299] | +4,304 [−5,046 ; +12,388] |

Les quantiles sont recalculés depuis les intervalles triés, à l'index floor(n×p), borné à n−1, exactement comme le producteur. Médianes et plages sont ensuite calculées entre runs. Les dix paires et leurs différences individuelles, y compris les pourcentages, restent dans les JSON.

Pour Low p50, les cinq écarts sont +1,644 / +2,799 / +1,810 / +2,112 / +1,420 ms, soit +3,96 / +6,73 / +4,39 / +5,17 / +3,41 %. Les plages des cinq p50 ne se chevauchent pas. Cela justifie de rapporter un coût reproduit dans ces cinq paires. Le faible effectif ne donne pas à lui seul une garantie statistique sur une population de machines ou de futures exécutions. Les autres métriques changent de signe et présentent des plages chevauchantes ; leur différence reste non concluante.

## Compteurs et profil séparé

Les maxima observés sont identiques au sein de chaque groupe :

| Compteur | Référence | Candidat |
| --- | ---: | ---: |
| Drawcalls maximum Normal | 305 | 311 |
| Drawcalls maximum Low | 267 | 273 |
| Nœuds maximum, deux qualités | 600 | 624 |
| Ressources maximum, deux qualités | 101 | 104 |

Les six drawcalls supplémentaires au maximum sont un relevé de Performance, pas une déduction depuis le plafond structurel de dix-neuf instances. Les séries brutes de drawcalls par frame n'existent pas dans ce rapport ; la provenance de ces maxima est vérifiée par lecture du code et des champs observés, sans prétendre les recalculer depuis les intervalles.

`perf-audit/audit_profile.py` a validé indépendamment le run `profile-route-candidate`, son manifeste, son journal, `profile-route-link.json` et le pidstat. Même HEAD et source candidate figée, mêmes wrapper et selfcheck ; l'unique différence du probe est un print à l'entrée de performance_route. Le parent a attendu ce marqueur, identifié le Godot enfant et échantillonné ce PID pendant cinq secondes. Les deux sorties valent 0, les cinq échantillons CPU existent et le trajet se termine avec zéro échec. `perf-audit/profile-audit.json` conserve ces vérifications.

Godot consomme en moyenne 446,4 % CPU, dont 411,0 % pour les huit threads llvmpipe et 30,8 % pour son thread principal. Ici 100 % représente un cœur logique. Les threads llvmpipe totalisent donc **92,07 % du CPU du processus**. Ce profil montre une consommation dominée par le rendu logiciel sur cet hôte à huit CPU logiques. Il ne compare pas référence et candidat au niveau des fonctions, ne profile pas Low et n'attribue pas exactement les +1,810 ms aux traces. Ses temps de frames sont exclus des tableaux ci-dessus.

## Hôte, avertissements et limites

Les 764 échantillons hôte retiennent PID, PPid, nom, charge et nombre de CPU. Aucun processus ciblé inattendu ; au plus un Godot, enfant du wrapper enregistré ; aucun moteur/encodeur/profil ciblé avant ou après chaque run. L'écart maximal entre prélèvements vaut 1,060 s. La charge à une minute varie de 1,53 à 5,30 sur huit CPU logiques. Cette surveillance ponctuelle n'exclut pas tout travail concurrent entre deux prélèvements ni tous les programmes non ciblés. Son léger coût s'applique aux deux versions.

Zéro erreur moteur ou validateur dans les vingt runs. L'avertissement V-Sync du pilote apparaît dans les vingt sorties. Cinq références et trois candidats signalent quatre instances ObjectDB à la fermeture ; ces avertissements sont conservés. Le diagnostic audio antérieur n'est pas recyclé en identification de classe pour ces huit sorties non verbose. Le profil séparé ne signale que V-Sync.

Ce sont des projets source instrumentés, avec fixture de combat hors mesure et route sans IA vivante, lampe ON seulement. Les intervalles sont des temps muraux entre callbacks, pas des temps GPU. Aucun résultat de GPU physique, Windows, audio audible, export release, mission entière ou 60 FPS 1080p ne se déduit de cette campagne.

Le contrat demande qu'un coût reproduit soit optimisé ou assumé explicitement. La revue transmet le coût Low p50 au parent pour sa décision de livraison ; elle ne masque pas ce coût et ne modifie pas la production. Le parent a indiqué qu'il documenterait ce compromis pour les traces persistantes à budget borné. Aucun gain n'est annoncé.

## Reproduction de l'audit et libération

```sh
python3 .cstack/orchestrate/silo9/issue18/perf-audit/audit_campaign.py
python3 .cstack/orchestrate/silo9/issue18/perf-audit/audit_profile.py
```

Les vingt contrôles synthétiques préparatoires restent dans `perf-audit/selfcheck.json` et testent seulement le validateur. Ils ne comptent pas comme des runs de jeu.

Écritures exclusivement dans `perf-audit/`, `perf-review.md` et `perf-summary.json`. Aucun moteur, profil, capture, encodeur, descendant, commit ou changement de source/outils lancé par cette revue. Aucun runtime détenu à libérer ; les worktrees sont relâchés au parent et conservés en place. Ce verdict porte sur la campagne examinée, pas sur une livraison finale du ticket.
