# Revue finale indépendante de la correction R1

Verdict : **PASS dans le périmètre déclaré**. R1 est corrigé. Aucun défaut concret bloquant ni commentaire actionnable trouvé dans les trois outils assignés. Ce verdict porte sur les gardes de preuve et sur la cohérence des artefacts archivés, pas sur une validation générale du jeu.

## Gardes et tests

Le validateur exige exactement les 12 segments et les 18 volumes demandés par R1. Le contrôle des doublons précède celui des ensembles. Les suppressions, remplacements, ajouts et doublons sont testés pour chaque position des deux catalogues. Les huit cibles sont également exactes, avec leurs points de visée reliés aux extrémités des segments.

Les champs `disabled` et `margin` sont présents et typés. Les compteurs statistiques sont entiers, finis et non négatifs, avec exclusion des booléens. Les sommes de l'inventaire correspondent aux statistiques et les triangles décor exportés correspondent aux chemins et nombres de l'inventaire. Les formes minimales des champs de capture sont vérifiées. Le commentaire qui distingue ces champs de la provenance externe est correct : la présence d'un SHA256 bien formé n'authentifie pas une capture.

Les petites fixtures mathématiques appellent directement les fonctions d'intersection. Les fixtures de comparaison sont complètes, synthétiques et explicitement nommées comme telles. `compare()` passe toujours par `inspect_dump()` puis `validate()`. Aucun branchement réservé aux tests, argument de contournement ou affaiblissement du validateur pour les fixtures n'a été trouvé.

Les 18 tests ont été réexécutés avec succès, code 0, dans `geometry-final-review/tests.log`. Le journal rouge archivé montre 18 tests et 135 sous-cas échouants. Son lanceur importe bien le module initial, tandis que le lanceur vert utilise le module corrigé. Cette lecture confirme le contraste comportemental archivé ; elle ne constitue pas une observation indépendante de la chronologie passée.

Les huit fonctions mathématiques et de signature sont identiques par AST entre versions initiale et corrigée. Les six empreintes des outils courants et archivés correspondent à `geometry-fix/verification.json`. Les 10 000 essais SAT de la première revue n'ont pas été relancés.

## Extracteur et preuves runtime

La garde GDScript compare les listes triées exactes, ce qui rejette aussi les doublons. Elle remplit `errors` avant l'ouverture de la sortie ; `run()` quitte alors avec code 2. Le commentaire sur `central_route` décrit maintenant ses bornes réelles z=7 à z=-56.

Les quatre copies d'injection archivées correspondent exactement à leur extracteur initial ou corrigé, plus l'injection annoncée après `build_checks()`. Leurs empreintes concordent. Pour le segment supprimé et le volume renommé, les journaux et résultats enregistrent une sortie initiale créée avec code 0, puis un rejet corrigé avec code 2 et sans sortie. Ce contrôle runtime a eu lieu après l'implémentation. Il ne démontre pas un TDD GDScript effectué avant la correction.

Les manifestes de `geometry-fix/runtime/attempt-01/` enregistrent deux extractions avec code 0, les commandes complètes et des empreintes avant/après identiques. Les 84 fichiers source/configuration de chaque capture correspondent encore à leurs empreintes au moment de cette revue. Les dumps correspondent aux empreintes annoncées et passent la validation corrigée. Les cinq empreintes embarquées dans chaque dump concordent avec son manifeste. L'empreinte moteur est cohérente dans les manifestes ; le binaire n'a pas été réexécuté ni réempreinté pendant cette revue.

Le candidat contient bien `world_art.gd` SHA256 `c3a973b5774ba521a29deff13dd9234db260c5e0329a0ecfc20da3d53b866cf0`. Le HEAD `0297cf78827e180a10b16648cf7e411499f531d4` est celui annoncé pour les captures, pas une vérification Git de cette revue. Le parent annonce depuis le commit de production `64a9485`. La correspondance des fichiers courants avec les empreintes de capture a été revérifiée sans Git ; aucun nouveau HEAD de capture n'est inventé.

## Résultat borné confirmé

Le fichier de comparaison contient exactement 30 contrôles et son manifeste enregistre un code 0. Les réserves et segments sont identiques entre les deux dumps. Le résultat archivé indique zéro ajout et zéro retrait. Les quatre débattements de porte conservent chacun 40 intersections, soit 160 au total. Les 26 autres contrôles n'en rapportent aucune.

Les 160 triangles rapportés ont été retrouvés dans les meshes référencés de chaque dump et leur intersection avec la réserve correspondante a été vérifiée. Leurs signatures mondiales sont identiques avant/après. Les chemins de nodes peuvent changer sans changer ces triangles. Aucun filtrage global d'une salle ni retrait des hits préexistants n'est utilisé. Le balayage exhaustif des deux dumps n'a pas été relancé pendant le film du parent : l'absence d'ajout provient de la comparaison archivée, dont le code et les entrées ont été contrôlés.

Les deux captures contiennent 76 colliders. Leurs empreintes ont été recalculées et valent toutes deux `027fdcaf4eca80c51b4e92dee5a022cfb94e2258e0e2e350852d41b69d058e03`.

Les quatre groupes statistiques sont présents. Le décor passe de 105 à 98 instances et surfaces, et de 60 644 à 42 068 triangles. Les groupes statique, acteur et animé restent respectivement à 8 940, 22 896 et 1 088 triangles. La cohérence inventaire/statistiques/export a été vérifiée. Il s'agit de géométrie construite ou potentielle, sans mesure des triangles rendus, des drawcalls, du GPU ou des pixels.

Les limites de la première revue restent applicables : triangles du sous-arbre WorldArt, état initial, trajets et visées déclarés seulement, coplanarité conservatrice, retessellation pouvant créer un faux positif, volume enfermé sans croisement de surface non détecté, débattements adaptés aux portes actuelles sans rotation/échelle. Le résultat n'efface pas les 160 intersections anciennes.

## Audit et libération

Audit relançable : `PYTHONDONTWRITEBYTECODE=1 python3 .cstack/orchestrate/silo9/issue10/geometry-final-review/audit.py`. Résultat code 0 dans `geometry-final-review/audit.json`. Le script contrôle les hashes, l'AST, les sources courantes, les dumps, les colliders, les résultats rapportés et les copies d'injection. Il ne lance aucun moteur.

La première exécution de ce script de revue comparait à tort les chemins des meshes avant/après ; cette assertion a été corrigée pour comparer leurs signatures mondiales et vérifier les chemins propres à chaque capture. Aucun outil de preuve ou artefact source n'a été changé pour obtenir le succès.

Écritures limitées à ce rapport et `geometry-final-review/`. Aucun Godot, X11, ffmpeg, benchmark, Git ou descendant lancé. Aucune source ni archive modifiée. Tous les processus de cette revue sont terminés ; périmètre libéré au parent.
