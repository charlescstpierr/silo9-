# Probe de rechargements répétés du ticket 18

Préparé pour HEAD `c105da61b2b490546f01c9d67703bfb405a2a44f`. Aucun résultat moteur revendiqué avant exécution autorisée. Les fichiers restent dans ce répertoire ; le jeu, les tests suivis et les outils des autres propriétaires sont inchangés.

Après transfert explicite du runtime :

```sh
python3 .cstack/orchestrate/silo9/issue18/reload-budget/run.py --execute
```

Le lanceur refuse un autre HEAD, une source suivie modifiée ou un Godot déjà présent. Il enregistre les hashes des fichiers suivis, du binaire et des trois outils, crée un userdata isolé et conserve chaque tentative dans un nouveau `run-<UTC>/`. Godot est headless et verbose pour conserver le diagnostic de fermeture. Aucun audio n'est arrêté ou remplacé par le probe. Timeout 180 secondes ; aucun export, capture, encodeur ou profil.

Le probe utilise la fixture existante pour construire le vrai Main. Il fige déplacements et IA, place le joueur devant la caisse, vérifie le collider visé et tire via Player.fire. Il déplace ensuite chacun des six vrais Enemy, capture sa pose et appelle receive_hit. Ces décès injectés ne constituent pas un parcours natif de combat. La caisse utilise le vrai hitscan, avec consommation de munition et impact vérifiés.

Après drainage des effets initiaux, deux rechargements échauffent le flux. Vingt autres passent par Main.save_run et Main.load_run, chacun avec nouveaux Player/World et six frames plus deux synchronisations physiques pour libérer les acteurs précédents. Vingt refresh sont appliqués avant chaque relevé. Les traces sont retrouvées dans la scène réelle, leurs poses comparées aux poses de décès, leurs ressources et sous-arbres inspectés. Aucun résultat n'est reconstruit à partir du seul registre privé de World.

La validation exige six traces sans Enemy, dix-neuf instances visibles de restes, six mêmes ArrayMesh à une surface et trois mêmes matériaux robot à travers les rechargements, sans collision/lumière/timer/traitement des traces. La caisse partage le BoxMesh et le matériau du World courant. Ces ressources de World sont reconstruites normalement ; leurs IDs ne sont pas censés rester identiques entre les chargements.

Le temps synchrone de sauvegarde, celui du chargement et le temps chargement plus drainage sont conservés séparément. Ce sont des diagnostics d'une séquence headless, sans comparaison à la base ni mesure GPU ou vitesse de mission. Les attentes de frames ne sont pas présentées comme du CPU pur. Les actions préparatoires et les inspections de géométrie sont hors de ces intervalles.

Les compteurs globaux objets/ressources/nœuds/orphelins/mémoire et le nombre de nœuds audio actifs sont conservés à chaque relevé. Les lignes ObjectDB et classes des références résiduelles restent dans runtime.log/result.json. Une hausse globale ne sera pas effacée parce que les ressources graphiques ciblées sont stables. La mémoire statique inclut aussi les données accumulées par le rapport ; elle ne permet pas, seule, d'attribuer une fuite au jeu.

Le validateur comprend huit contre-exemples appliqués aux mesures réelles après un passage positif : instance supplémentaire, mesh/matériau supplémentaire, acteurs non reconstruits, mauvaise pose, caisse bloquante, trace active et exécution incomplète. Ce sont des contrôles du validateur, pas des tests indépendants du gameplay.

Validation préparatoire effectuée : compilation Python des deux scripts. La syntaxe GDScript et le comportement du probe restent à vérifier pendant la tranche runtime autorisée.
