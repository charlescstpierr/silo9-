# Ticket 8, implémentation livrée au coordinateur

Commit local : `efc2a581fd329321a852507d775af6fcda0a9cb1`.
Branche : `feat/issue-08-materials`.
Worktree : `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-08`.

Les fichiers suivis sont propres après commit. Les seuls fichiers non suivis sont des UID de tests/outils générés par Godot, exclus du commit et laissés intacts. Aucun nouveau worktree, descendant ou processus persistant créé par ce délégué. Le runtime :100 et la propriété d’écriture du worktree ont été remis au parent. Aucun push ni PR effectué.

## Changement

Les deux builders chargent neuf `StandardMaterial3D` partagés : peintures D9/ARC, acier, isolant, contacts, deux signaux, gant et tissu. Les matériaux ordinaires ne sont plus émissifs ; les deux signaux gardent une émission 0,8. Les boîtes/tubes manuels projettent leurs UV d’après leur normale finale ; les lofts déroulent leur couture et suivent leur longueur cumulée au repos, avec UV plans et couleur explicite aux caps. Géométrie développée, normales, skinning, transforms et marqueurs restent identiques à la référence.

Le choix final est le look A sans les cartes peinture : D9 bleu pétrole, ARC ocre, gants graphite, manches bleues. La paire peinture a été retirée après comparaison frontale avec un témoin isolant son effet, puis décision du parent et de sa revue artistique. Les scalaires restent identiques au témoin. Quatre images L8 de 128² pour gant/tissu restent en production, avec mipmaps et génération hors ligne reproductible. Le plafond conservateur RGBA8 avec chaîne complète vaut 349 520 octets. Ce n’est pas une mesure VRAM. Aucun asset tiers ni licence inventée.

Chemins livrés : `scripts/weapon_visual.gd`, `scripts/fps_hand_mesh.gd`, `assets/fps/README.md`, neuf `assets/fps/materials/*.tres`, quatre PNG et leurs imports sous `assets/fps/textures/`, `assets/fps/textures.json`, `tools/generate_fps_materials.py`, ajout de provenance dans `docs/OPEN_SOURCE.md`. Aucun Player, rig, gameplay, système de qualité ni test modifié.

## Vérification

Le parent a reproduit 9 PASS et 15 échecs sémantiques avant cette assignation. Les hashes du test et de la référence restent identiques au gate. `green-final/verification.json` contient les commandes, environnement, codes de sortie et hashes des logs. `green-final/manifest.json` contient les hashes des sources/ressources vérifiés inchangés avant commit.

| Contrôle final | Résultat |
|---|---|
| Import Godot 4.7.2 | exit 0, aucune erreur technique |
| `test_fps_materials.gd` | 24 PASS, 0 FAIL |
| `test_visual_geometry.gd` | failures=0, bras 1 664 sommets / 2 400 triangles / 35 os / 2 surfaces |
| `test_fps_rig.gd` | failures=0 |
| `test_d9_geometry.gd` | failures=0 |
| `test_arc_geometry.gd` | failures=0 |
| `test_arc_indicator.gd` | 13 PASS, 0 FAIL |
| `test_ads_geometry.gd` | 161 PASS, 0 FAIL, X11 avec renderer dummy |
| Génération répétée | quatre PNG strictement identiques, `offline-generation-final.json` |
| Diff et staging | `git diff --check` et `git diff --cached --check` sans sortie |

Les quatre suites géométrie/rig n’impriment pas de compteur PASS ; leur sortie finale et leur exit 0 sont conservés. Aucune campagne globale de 38 suites n’a été relancée.

Le budget matériel concerne les armes/bras. Le vrai jeu ajoute deux matériaux Muzzle préexistants : l’inventaire du rig complet en contient onze. Les campagnes rendu ont confirmé les quatre images conservées au format L8, sept niveaux mip et 21 845 octets d’image chacune. Les ressources sont stables à travers R/B/ADS et changement d’arme selon le test final. Le contrôle de deux rigs construit séparément démontre leur partage.

## Comparaisons de présentation

Cinq campagnes ont chacune 17 PNG, exit 0, `failures=[]` et aucun hash source modifié pendant le run :

- `look-a` et `look-b`, palettes distinctes avec six cartes initiales.
- `look-a-no-maps`, témoin A sans aucune liaison de cartes.
- `look-a-frontal`, même A avec la sonde du parent déplaçant uniquement la lumière de Z5 à Z8.
- `look-a-frontal-no-paint`, même frontal A avec seules les quatre liaisons de peinture retirées, deux par matériau.

Chaque dossier conserve commande, environnement, sonde, hashes de projet et moteur, snapshot exact des fichiers modifiés, inventaire et PNG non retouchés. La suppression finale des déclarations inutiles et fichiers peinture ne change pas le rendu du dernier témoin, mais le parent réalise les captures et le film sur le commit final pour établir cette preuve directement.

J’ai inspecté les originaux suivants : A/D9 froid hip, A/ARC refuge Normal, B/D9 rouge hip, B/ARC refuge Normal, A sans cartes/ARC refuge Normal, A/D9 rouge ADS, A frontal/D9 rouge hip, A frontal/ARC froid ADS et A frontal sans peinture/ARC froid ADS. Le choix artistique indépendant est coordonné et documenté par le parent. Je n’ai pas visionné de film continu.

## Deslop et limites

Tous les hunks ajoutés/modifiés, ressources natives, imports, générateur et texte de provenance ont été relus avant commit. La passe n’ajoute aucune abstraction.

| Catégorie | Chemin | Retrait | Motif |
|---|---|---|---|
| Allocation et attribut inutile | `scripts/weapon_visual.gd` | `set_color(Color.WHITE)` de la première version privée | Les matériaux d’armes ne lisent pas les couleurs de vertices. Retrait avant les campagnes vertes. |
| Ancienne construction par instance | `scripts/weapon_visual.gd`, `scripts/fps_hand_mesh.gd` | Fabrique et instanciations de matériaux | Remplacées par les ressources partagées exigées. |
| Variante non retenue | `assets/fps/`, générateur | Deux cartes peinture, imports, déclarations et branche de génération | Comparaison isolée et décision visuelle du parent ; aucune variante inutilisée livrée. |

Aucune ligne gardée comme incertaine, aucun retrait de logique non couvert déclaré. Les caps blancs des bras sont conservés car leurs matériaux lisent les couleurs de vertices. Les vérifications finales ont été exécutées après les retraits et aucun changement de production n’a suivi.

Le parent prend en charge film, preuve finale du rendu, performance avec cinq paires alternées, exports et publication. Ce rapport ne revendique ni gain GPU joueur, ni 60 FPS, ni exécution Windows, ni essai de manette physique, ni parité Fortnite.
