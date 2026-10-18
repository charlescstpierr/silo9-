# Outil de géométrie bornée du ticket 10

Statut intermédiaire : outil Python testé, extracteur Godot préparé mais non exécuté. Aucun moteur, X11, benchmark, ffmpeg, descendant, Git ou fichier du worktree modifié. Le builder conserve le runtime. Aucun résultat géométrique base09/candidat10 n'est encore acquis.

## Forme exacte

`proof-tools/extract_world_geometry.gd` instancie les vrais Player, RunState et World, puis désactive leurs traitements avant le premier tick. Il lit les triangles finaux de chaque MeshInstance/MultiMesh sous `world.art`, applique les transformations monde et les transformations de chaque instance. Aucune copie des placements artistiques, injection dans World, surcharge de méthode ou API de production. Les nœuds déjà en destruction différée sont ignorés.

L'inventaire sépare décor, statique, acteurs CharacterBody et rotors animés. Il compte MeshInstance, nœuds MultiMesh, instances, surfaces et triangles construits/potentiels. Ce ne sont pas des triangles réellement rendus, des drawcalls ou un coût GPU. Il conserve aussi visibilité déclarée et portée. Les colliders sous StaticBody hors acteurs gardent type, dimensions, transformation mondiale, layer, mask, disabled et margin ; une forme non prise en charge produit une erreur. Leur empreinte ignore les noms de nœuds automatiques, pas leur multiplicité.

Les 12 segments bornés vont de l'œil réel Player vers huit cibles World et quatre ennemis construits. Les cibles sont relais, deux disjoncteurs, N7, preuve, trois composants de la mission courte ; les quatre visées de combat utilisent les premières positions ennemies Maintenance/Archives depuis l'axe à quatre mètres en amont. Les positions d'approche viennent de `tests/test_journey.gd` et `tools/probe_sector_power.gd`, la hauteur caméra de l'objet Player construit et les cibles des transforms réels. Les offsets de visée reprennent les tests existants.

Les 18 volumes couvrent huit approches latérales, axe principal, détour ARC, quatre premiers segments de patrouille et quatre débattements des sas. Les réserves de marche sont des boîtes de contrôle y0,12..1,85, rayon horizontal0,35 ou0,4m. Le débattement utilise les feuilles construites et le déplacement fermé/ouvert de3,4m de `power_consumers.gd`. Ces réserves sont un échantillonnage déclaré, pas un nouveau contrat de navigation.

`proof-tools/geometry_check.py` est l'unique validateur. AABB élimine les candidats lointains ; segment/triangle bidirectionnel borne le paramètre à l'intervalle caméra-cible ; SAT triangle/boîte teste les volumes. Chaque contrôle conserve tous les triangles préexistants, restants, retirés et ajoutés. Une nouvelle intersection échoue même si cette réserve avait déjà un défaut. Les signatures géométriques sont arrondies au micromètre et indépendantes du batching. Les cibles/réserves doivent être identiques entre captures. Toute différence de collider échoue.

## Rouge et vert exécutés

Commande : `python3 -m unittest discover -s .cstack/orchestrate/silo9/issue10/proof-tools -p 'test_geometry_check.py' -v`.

- `proof-tools/red.log` : huit tests, six échecs sur le point d'entrée initial sans gardes ; plaque devant relais, bord dans réserve, données invalides, comparaison des défauts et colliders démontrent l'absence des contrôles avant implémentation. La plaque derrière cible et le témoin sans vraie intersection passent.
- Réserve rotation : le premier triangle était mal choisi, son plan ne traversait pas la boîte. Cette fixture a été corrigée après la première implémentation SAT. Son rouge initial n'est donc pas revendiqué comme preuve TDD valable de rotation. Le cas corrigé traverse réellement la boîte et passe.
- `proof-tools/red-validation.log` : après ajout des tests de collider malformé et de dump sans triangles, deux échecs attendus avant leurs gardes.
- `proof-tools/green.log` : dix tests passent. Plaque devant/derrière, bord entrant avec centroïde extérieur, rotation, faux positif AABB évité par SAT, données non finies/malformées, vide, défaut préexistant versus nouveau et collider modifié.

## Exécution encore requise

Après libération explicite du moteur, lancer le même script externe sur `.worktrees/silo9-issue-09` et `.worktrees/silo9-issue-10`, avec la même version Godot :

```bash
GODOT --headless --path PROJECT --script ABSOLUTE_PATH/proof-tools/extract_world_geometry.gd -- ABSOLUTE_OUTPUT.json
python3 proof-tools/geometry_check.py BASE.json CANDIDATE.json COMPARISON.json
```

`GODOT`, `PROJECT` et les chemins sont des paramètres à remplacer. Le script n'a pas encore reçu de vérification syntaxique Godot. Valider ses transformations et son inventaire sur le runtime avant d'adopter la preuve. Les empreintes SHA256 des sources et la version moteur sont inscrites dans chaque dump. Le code de retour du comparateur vaut0 pour aucune nouvelle intersection sur cet échantillon et colliders identiques,1 pour régression,2 pour preuve invalide.

## Limites

La preuve observe uniquement les surfaces triangulées finales WorldArt et les contrôles déclarés. Elle ne couvre pas tous les loots, angles de tir ou chemins IA. Elle ne détecte pas une réserve entièrement enfermée dans un mesh fermé sans croisement d'une de ses surfaces. Un segment coplanaire utilise une intersection AABB conservatrice, susceptible de signaler un faux positif à inspecter. Les volumes d'approche sont des approximations conservatrices des parcours. Une retessellation peut signaler une nouvelle intersection au même endroit et exige une inspection explicite. Les pixels, ombres, transparences, perception humaine et faux abris restent à vérifier. Aucun défaut préexistant n'est exclu par salle.

## Fichiers et SHA256

- `proof-tools/geometry_check.py` : `8f1bad1aedae5e2dd556f8e448b3b8f00487ef70f73dc96ba4cf2c1d375e53ab`
- `proof-tools/test_geometry_check.py` : `f3cc66b0f926c282276d41ca38481c5ee39608db0b8e7cd791564cbfab599365`
- `proof-tools/extract_world_geometry.gd` : `e9678d1a96be24ebbca704bde4846fb4e3ee86d0a1217d873c8cd139116caadd`

Aucun worktree créé, aucun processus gardé actif. Périmètre d'écriture limité à `issue10/proof-tools/` et ce rapport. Worktree candidat lu à `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-10`, branche/HEAD annoncés par le parent `feat/issue-10-environment` / `0297cf78827e180a10b16648cf7e411499f531d4` ; aucune commande Git exécutée par cette tranche pour les revérifier. Attente de l'autorisation runtime du parent.
