# Revue indépendante des outils de preuve18

**PASS borné aux outils gelés et relus ci-dessous. Aucun PASS fonctionnel du jeu, du parcours final ou de la campagne de vingt runs.**

Le gel du trio a été annoncé par son auteur avant la revue finale. Le dernier delta du runner a aussi été relu. Sources de référence et candidate uniquement lues ; aucun moteur Godot, X11, profil, export, campagne, commit, push ou descendant lancé par ce relecteur.

## Identités finales

| Fichier | SHA-256 |
| --- | --- |
| probe_sector_power.gd | `92fa2c5f61b5b6ece8b8421ce86a0751a099c72facd581ba87f0c5b94f666cf0` |
| prove_sector_power.py | `6a5b699bb008c890bc394bc67da33d753b74825ff185086880931a098d2d8c81` |
| selfcheck_sector_power.py | `ab7a711aae3606668bd53c9f9f3ca47298328199b2a6567708ca27e2404cb5fa` |
| run_perf_pair.py | `310a18a0188af2a335e6032936777821cfb9fc658082dc56018bc21096d4d14c` |

HEADs vérifiés : candidat `c105da61b2b490546f01c9d67703bfb405a2a44f`, référence `28e402821469655598c6a84bc415d8ea04da97c2`. Les sources pertinentes et le helper X11 ont leurs empreintes dans `proof-tool-review/source-hashes.json`, reconfirmées inchangées à la clôture. Copies initiales/finales et deltas conservés dans ce même dossier ; tout nouveau delta exige une nouvelle revue ciblée.

## Contrôles exécutés

- **40 selfchecks Python réussis**, lancés sur une copie indépendante finale ; les 24 historiques restent présents. Journal `final-selfchecks.log`. Le premier contrôle indépendant passait déjà 36 tests, mais acceptait les contre-exemples ci-dessous.
- **Huit mutants indépendants rejetés**, chacun après vérification que sa fixture de base est acceptée : `counterexamples.py`, `final-counterexamples.json`. Faux second ARC avant F9, tir de caisse sur cible distante, caméra restaurée hors scène, instance ARC antérieure réutilisée, horodatages de frames incohérents, champ racine inconnu, santé booléenne du rapport, santé booléenne du snapshot.
- **Trois tests indépendants du runner réussis** : `check_pair_runner.py`, `pair-selfchecks.log`. Ils exercent les rejets de manifeste/HEAD/source/moteur/helper altérés, les différences de fixture entre côtés et l'observation d'un faux `/proc` limité aux noms/PIDs/parents.

Les fixtures synthétiques ne constituent aucune preuve de partie exécutée. Aucun journal de diagnostic runtime tiers n'a servi de substitut à ces contrôles.

## Constats initiaux corrigés

| Constat concret | Correction relue et vérifiée |
| --- | --- |
| ARC répété accepté avant reconstruction | Instant après l'observation restaurée et ID du dispositif reconstruit exigés. |
| Tir/impact/bounds cohérents entre eux mais sans lien à la cible primaire | IDs réellement observés, centre de collider lié à la position cible, dimensions vérifiées ; position létale du robot lue avant le coup. |
| Caméra restaurée arbitraire acceptée | Caméras/FOV des vues revisitée et restaurée comparées à la vue modifiée. |
| Horodatages de frames ignorés | Deltas reliés aux intervalles bruts et bornes monotones de mesure ; compte frames/intervalles conservé. |
| Champ racine inconnu et booléens numériques acceptés | Champs autorisés fermés, types numériques exacts hors booléens, types de snapshot contrôlés. |
| Paires seulement liées par leurs codes retour | Identité de campagne figée, vérifiée avant/après chaque run, manifestes recoupés, fixtures observées comparées. |
| Incident hôte initial non conservé | Preflight écrit avant rejet ; observations périodiques et PID wrapper conservés ; concurrence détectée bloque la paire. |

Le contre-exemple initial « même instance ARC » reposait sur une fixture déjà invalide sur ce point. Le test final réassigne explicitement l'ancien ID au second tir, puisque la fixture corrigée utilise désormais deux instances distinctes.

## Lecture des chemins réels

La préparation terminale utilise six vrais appels `Enemy.receive_hit` sur les instances existantes, avec observations de santé, pose, collision et défaite. La caisse reçoit un vrai `Player.fire`, dont rayon et impact sont lus après le recul de production. Les téléports de cette fixture restent déclarés hors chauffe et mesure. Aucun mark_defeated injecté ne remplace une mort réelle.

Le parcours persistance utilise déplacement physique et combat, sans téléport de fixture. La caméra de capture est indépendante du joueur. F5/F9 passent par X11 ; les attentes conditionnelles sont bornées et l'absence de fichier/reconstruction échoue. Nouveaux Player/World et objets primaires, poses, collisions, ARC, circuits et inventaire sont recoupés. Les douilles sont observées actives autour de F5 puis absentes après F9. Le second ARC conserve les snapshots de chaque notification changed ; seule la consommation d'énergie est admise.

La chauffe dure au moins deux secondes nominales après préparation. Les effets impact/muzzle/beam/lumière et douilles sont absents aux frontières avant chauffe et mesure. Les neuf stations historiques et le compteur de frames restent contrôlés. Le coût mesuré exclut captures et combats préparatoires. Les snapshots convertissent exclusivement les positions Vector3 en float32, conformément à `run_state.gd`; l'inventaire ne reçoit pas de tolérance numérique générale.

Le wrapper refuse erreurs moteur, timeout, rapport absent/invalide, demandes différentes des observations, sources/outils modifiés, PNG invalides ou sortis du dossier, et sauvegarde non concordante. Le runner impose les deux HEADs, le même moteur/outillage figé et les mêmes préparations observées. Le contrôle hôte reste un échantillonnage à une seconde, pas une preuve d'absence de tout processus très bref entre deux échantillons.

## Limites et suite autorisée

Aucun défaut bloquant restant trouvé dans cette tranche. Le parent peut créer le gel de campagne depuis ces identités et exécuter les diagnostics/parcours finaux. Le verdict de livraison exige encore les sorties réelles acceptées, la revue des images Normal/Low, les coûts recalculés depuis les intervalles bruts et les limites Linux/llvmpipe explicitement conservées. Une compilation ou cette revue statique ne prouve pas la route native.

No-comments : aucune suppression effectuée par le relecteur ; les commentaires sur fixtures synthétiques, marqueur de tir et conversion Vector3 sont justifiés. Le texte périmé affirmant aucun téléport pour tout perf a été corrigé par l'auteur. Règles cstack, délégation, no-comments et prove-it-works appliquées sans descendants, conformément au périmètre du parent.

Libération : seuls `issue18/proof-tool-review.md` et `issue18/proof-tool-review/` ont été écrits. Aucun worktree créé ; référence et candidat conservés et relâchés. Aucun processus persistant détenu.
