# Revue indépendante de l'outil géométrique — ticket 10

Verdict : calculs statiques/Python PASS sur les cas exécutés ; un défaut P2 de validation de preuve à corriger avant de traiter `bounded_pass` comme validation autonome du contrat 12 segments / 18 volumes. Aucun verdict Godot ni résultat base09/candidat10.

## R1 — P2 : un dump incomplet peut obtenir `bounded_pass=true`

Références : `proof-tools/geometry_check.py:75`, `:78`, `:90`, `:108` ; `proof-tools/extract_world_geometry.gd:36`, `:43`.

Le validateur exige seulement des listes non vides. Il n'exige pas les douze identifiants de segments et dix-huit réserves annoncés, ni les champs de provenance de l'extracteur. La fixture réelle `sample()` du fichier de tests, contenant un seul segment et un seul volume, aucun moteur, aucune empreinte de source et aucun inventaire, obtient `bounded_pass=true` lorsqu'elle est comparée à sa copie. Les colliders de cette fixture omettent également `disabled` et `margin`. Une variante avec `disabled="not a bool"`, `margin=-10` et `stats.decor.triangles=-999` passe aussi.

Scénario : une capture partielle produite dans les deux projets par le même extracteur défectueux, ou deux fichiers de preuve tronqués de façon identique, est acceptée comme preuve valide et ne contrôle plus une partie des sas/visées. L'égalité des réserves entre captures ne suffit pas : elle prouve seulement que les omissions sont identiques. L'extracteur n'impose lui-même aucun décompte final ou ensemble d'identifiants avant l'écriture. Le comportement Python est reproduit ; aucune panne GDScript particulière n'est prétendue observée.

Correction : faire porter au validateur de preuve (ou à une enveloppe stricte dédiée SILO9) le manifeste attendu des 12 segments/18 réserves, les champs indispensables de capture et la validité des champs collider/statistiques exportés. Garder les primitives mathématiques réutilisables et permettre les petites fixtures au niveau de ces primitives. Ajouter un rejet explicite de capture partielle avant émission du dump. Pour cette livraison, un contrôle indépendant des identifiants complets et de la provenance peut également servir de garde, mais le booléen actuel ne fournit pas seul cette garantie.

Garde interne minimale de couverture : exiger exactement les segments `relay`, `breaker_maintenance`, `breaker_archives`, `n7`, `evidence`, `component_0`, `component_1`, `component_2`, `combat_sentinel_1`, `combat_crawler_1`, `combat_sentinel_2`, `combat_crawler_2` ; les huit réserves `approach_` correspondant aux huit premiers identifiants, `central_route`, `arc_bypass`, quatre `patrol_` correspondant aux quatre ennemis et les quatre `door_sweep_{maintenance,archives}_{SasGauche,SasDroit}`. Contrôler l'ensemble exact, pas seulement le total. Gardes de données : `disabled` booléen présent, `margin` numérique fini non négatif présent, statistiques de comptes numériques entières non négatives et cohérence des triangles décor exportés.

Contrôle externe distinct annoncé par le parent : captures dans des dossiers neufs, commandes et codes de retour enregistrés, empreintes source/moteur/outils vérifiées. Ce contrôle peut établir la provenance sans prétendre que `validate()` l'a vérifiée ; il ne remplace pas automatiquement le contrôle des 12/18 identifiants ci-dessus.

Certitude : élevée, reproduction Python déterministe dans `geometry-review/review_probes.py`, sortie `geometry-review/probes.log`.

## Contrôles positifs et limites

- Les dix tests fournis passent. Une deuxième implémentation par découpage du triangle contre les six plans de la boîte concorde avec SAT sur 10 000 triangles déterministes (seed 1042). Ce contrôle ne prouve pas tous les cas numériques extrêmes.
- Les segments rejettent les triangles derrière les deux extrémités, dans les deux sens de parcours et pour les deux orientations des triangles. Les extrémités exactes sont exclues par le code, hors branche coplanaire conservatrice déjà déclarée.
- Une retessellation d'une surface triangulaire strictement identique produit un échec avec nouveaux triangles : ce faux positif est réel et déjà déclaré. La liste des hits préexistants est conservée, sans exclusion globale d'une salle. Les triangles superposés partagent une signature ; les chemins des occurrences restent dans le hit. L'empreinte collider conserve sa multiplicité.
- Lecture statique : `global_transform * get_instance_transform(i)` compose correctement les transforms MultiMesh ; les faces locales passent ensuite dans cette transformation. Les instances construites, y compris invisibles, sont comptées comme potentielles. `visible_instance_count` est conservé séparément. Rien ici ne mesure les triangles rendus, drawcalls, GPU ou occultation perceptuelle.
- Les sources `world.gd`, `player.gd` et `data/power_consumers.gd` sont identiques entre les worktrees 09/10 au moment de la lecture. Les approches et offsets correspondent aux probes existants ; les portes actuelles ont une base sans rotation/échelle et vont de y=5,1 à y=1,7, compatible avec les réserves construites. Cette formule n'est pas une boîte orientée générale pour de futures portes tournées.
- Le domaine d'intersection est bien le sous-arbre `world.art`. Les consoles que `build_console()` attache sous les objets World sont classées statiques et ne sont pas exportées dans ces triangles ; le rotor du cœur est classé animé. Cela correspond à la limite déclarée « sous world.art », et ne doit pas être reformulé comme toute la géométrie produite par chaque méthode de `world_art.gd`.
- L'enfermement intégral dans un mesh fermé, les intersections coplanaires conservatrices, les états animés, les pixels, tous les angles de tir et les parcours IA universels restent hors preuve, comme annoncé. Le commentaire « Central route includes all rooms » est plus large que les coordonnées réelles 7..-56 : cette réserve n'explore pas tout le réacteur. Les bornes réelles doivent rester la référence du rapport.
- L'extraction lit les formes StaticBody actuelles et préserve transform, type, dimensions, disabled, marge, layer/mask. Elle ne doit pas être présentée comme une analyse physique complète des acteurs ou de tous les types de shape possibles.

## Preuves et libération

Commande tests : `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s .cstack/orchestrate/silo9/issue10/proof-tools -p 'test_geometry_check.py' -v` — 10 tests, OK.

Commande complémentaire : `PYTHONDONTWRITEBYTECODE=1 python3 .cstack/orchestrate/silo9/issue10/geometry-review/review_probes.py` — 10 000 comparaisons SAT, segments bornés et retessellation confirmés ; R1 reproduit.

Les trois SHA256 sont identiques à ceux du rapport d'auteur : geometry_check `8f1bad1aedae5e2dd556f8e448b3b8f00487ef70f73dc96ba4cf2c1d375e53ab`, tests `f3cc66b0f926c282276d41ca38481c5ee39608db0b8e7cd791564cbfab599365`, extracteur `e9678d1a96be24ebbca704bde4846fb4e3ee86d0a1217d873c8cd139116caadd`.

Aucun moteur, Godot, X11, ffmpeg, Git, PR ou descendant lancé. Aucun outil gelé modifié. L'extracteur n'a pas été exécuté et sa syntaxe n'est pas certifiée. Écritures limitées à ce rapport et `issue10/geometry-review/`. Aucun worktree créé, aucune branche/HEAD revérifiés par Git ; worktrees 09 et 10 seulement lus. Tous les processus de cette tranche sont terminés et le périmètre est libéré pour le parent.
