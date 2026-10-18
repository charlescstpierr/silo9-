# Correction du validateur géométrique R1

R1 est corrigé dans les outils attribués. Les 18 tests Python passent. Les extractions réelles base09/candidat10 terminent avec code 0, puis la comparaison termine avec code 0 : aucune nouvelle intersection sur les 12 segments et 18 volumes déclarés, 76 colliders identiques. Les 160 intersections préexistantes dans les débattements de portes sont conservées dans le rapport, sans exclusion. Ce résultat reste borné à ces contrôles et aux triangles WorldArt exportés.

## Changements

Seuls `proof-tools/geometry_check.py`, `proof-tools/test_geometry_check.py`, `proof-tools/extract_world_geometry.gd` et les preuves sous `geometry-fix/` ont été écrits. Aucun fichier de production ou test du jeu, aucune archive `proof-tools-initial`, aucun Git ou descendant.

Le validateur exige les ensembles exacts des 12 segments et 18 volumes de la revue. Retirer, ajouter, remplacer ou dupliquer un identifiant est rejeté. Les colliders exigent `disabled` booléen et `margin` numérique fini non négatif. Les statistiques exigent tous les compteurs entiers non négatifs ; les nombres JSON tels que `12.0` restent acceptés. Les sommes de l'inventaire doivent correspondre aux statistiques, chaque mesh décor doit correspondre à son inventaire et son nombre de triangles exportés.

Les champs de capture `project`, `engine`, `measurement`, `source_sha256`, `targets` et `mesh_inventory` sont exigés et leur forme contrôlée. Les huit cibles sont exactes et leur `aim` doit correspondre à l'extrémité du segment. Le format SHA256 ne prouve pas à lui seul l'origine du fichier : les commandes et empreintes externes sont consignées séparément dans les manifestes d'exécution. Le validateur n'authentifie pas une capture et ne prétend pas le faire.

Les huit fonctions mathématiques et de signature sont inchangées, vérification de leur texte par AST dans `verification.json`. Les petites fixtures testent directement segment/triangle et triangle/boîte. Les tests de comparaison passent toujours par la validation complète avec une capture synthétique explicitement complète, sans option pour contourner les gardes.

L'extracteur refuse un catalogue incomplet ou inattendu avant d'ouvrir le fichier de sortie. Son commentaire indique désormais que `central_route` couvre z=7 à z=-56, sans prétendre couvrir tout le réacteur.

## Chronologie et tests

1. Les nouveaux tests ont été écrits et exécutés contre le module `proof-tools-initial/geometry_check.py` avant les gardes : `run_initial_tests.py`, `red.log`, 18 tests, 135 sous-cas échouants avec `AssertionError: ValueError not raised`, code 1. Les cas complets valides et les calculs mathématiques passent déjà.
2. `run_initial_review.py` exécute les probes indépendants en important les outils archivés, sans les modifier. `initial-review.log` confirme les deux reproductions R1, 10 000 accords SAT/découpage et les contrôles de segments. Code 0.
3. Gardes Python ajoutées puis même suite sur le module corrigé : `green.log`, 18 tests, `OK`, code 0. Commande : `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s .cstack/orchestrate/silo9/issue10/proof-tools -p test_geometry_check.py -v`.
4. Après autorisation explicite du runtime par le parent, extractions réelles des deux projets et comparaison : `runtime/attempt-01/`. Les commandes complètes, codes, empreintes avant/après et empreintes des sorties sont dans `base.manifest.json`, `candidate.manifest.json`, `comparison-command.json`. Aucun parse-fix nécessaire.
5. Vérification runtime supplémentaire de la garde de l'extracteur, effectuée après son implémentation : `check_extractor_guard.py` génère des copies temporaires qui retirent un segment ou renomment un volume après `build_checks()`. `runtime/guard-checks/results.json` contient les quatre commandes et leurs résultats. Les deux copies initiales écrivent une capture avec code 0 ; les deux copies corrigées quittent avec code 2 et aucun fichier de sortie. Ces copies de faute injectée sont distinctes de la preuve réelle `attempt-01`. Cette vérification GDScript après implémentation n'est pas revendiquée comme rouge runtime avant implémentation. L'indisponibilité initiale du runtime avait été enregistrée dans `runtime-exception.md` ; l'autorisation est arrivée avant l'écriture de la garde GDScript.
6. Contrôle de la vraie CLI Python : capture complète code 0 et rapport créé ; capture tronquée, collider invalide ou statistiques négatives code 2 et aucun rapport. Détails dans `verification.json` et `cli/*.log`.

## Résultat réel

Moteur partagé : Godot `4.7.2-stable (official)`, SHA256 `8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e`.

Base : `.worktrees/silo9-issue-09`, `world_art.gd` SHA256 `aca907353cb6a26c1eb508602d49dc3d8560c7c5c2a83daecdc16d2b1bc65475`.

Candidat : `.worktrees/silo9-issue-10`, `world_art.gd` SHA256 `c3a973b5774ba521a29deff13dd9234db260c5e0329a0ecfc20da3d53b866cf0`, conforme au SHA attendu par le parent.

Chaque manifeste vérifie avant/après le moteur, les trois outils et 84 fichiers source/configuration du projet. Tous sont inchangés pendant chaque capture. Les HEAD `0297cf78827e180a10b16648cf7e411499f531d4` des deux worktrees sont ceux annoncés par le parent ; aucune vérification Git par cette tranche.

| Groupe | Instances base → candidat | Surfaces base → candidat | Triangles base → candidat |
| --- | --- | --- | --- |
| Décor | 105 → 98 | 105 → 98 | 60 644 → 42 068 |
| Statique | 396 → 396 | 400 → 400 | 8 940 → 8 940 |
| Acteurs | 142 → 142 | 143 → 143 | 22 896 → 22 896 |
| Animé | 9 → 9 | 9 → 9 | 1 088 → 1 088 |

Ce sont des instances/surfaces/triangles construits ou potentiels, pas des triangles rendus, des drawcalls ou une mesure GPU. Les quatre groupes sont réellement présents dans les dumps.

Les 12 segments et 14 autres volumes ont zéro intersection. Chaque `door_sweep_{maintenance,archives}_{SasGauche,SasDroit}` a 40 intersections préexistantes et restantes, zéro ajout/retrait. Les 76 colliders ont la même empreinte `027fdcaf4eca80c51b4e92dee5a022cfb94e2258e0e2e350852d41b69d058e03`.

Dumps : base SHA256 `455832459189f4413eeb9e65d0b8c741fdfc3bd05a3d1321b784c85d4dab83cb`, candidat `76e0326fffc7443f2c1ceb3365ec52cec5d8d9f3007c521a43ee81b5a53e428a`. Résultat détaillé : `runtime/attempt-01/comparison.json`.

## Limites et libération

Les limites de la revue restent applicables : sous-arbre WorldArt seulement, animation et pixels hors preuve, échantillon borné de trajets/visées, coplanarité conservatrice, retessellation pouvant créer un faux positif, réserve entièrement enfermée sans croisement de surface non détectée. Le contrôle des débattements reste adapté aux portes actuelles sans rotation/échelle. Aucun changement mathématique n'élargit ce domaine.

Runtime Godot/headless et DISPLAY :100 explicitement libérés au parent ; tous les processus lancés sont terminés. Xvfb parent conservé intact. Aucun worktree créé ou supprimé, aucun rédacteur ou descendant restant. Rapport d'auteur remis pour revue indépendante, sans prétendre constituer cette revue.

SHA256 finaux :

- `geometry_check.py` : `906218a8261f9dc65c9ccaffcab0d6b55f35747162c4bfe1c27b1a95dbc294a1`
- `test_geometry_check.py` : `de5393bb9cf2f3434bfbb3f8d46401df01823f68e63d7bccedbb41acd1d5e4b7`
- `extract_world_geometry.gd` : `acff3e7e7bc4d09e8266027130de316c7bcea86e77f357f9bab5d4969af73fc1`

Les trois archives correspondent exactement aux SHA du rapport initial, contrôle dans `verification.json`.
