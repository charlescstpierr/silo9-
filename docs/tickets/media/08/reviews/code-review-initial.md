# Revue indépendante initiale — ticket 8

**PASS pour le code de production examiné. Aucun défaut concret trouvé.** Cette revue porte sur le working tree basé sur `5a0251378457e1223f5dcbe31caa1e35c0d88247`, branche `feat/issue-08-materials`. Les empreintes ci-dessous bornent le verdict ; une variation de palette, de cartes ou de source appelle une revue du delta final.

La revue est indépendante de l'auteur de production, avec le même modèle hérité. J'ai écrit le nouveau test du ticket : je ne revendique donc aucune revue indépendante de sa qualité. Aucun descendant, runtime Godot, générateur, édition de production ni commit n'a été lancé. Seul ce rapport est écrit. Fichiers et accès relâchés.

## Raisonnement vérifié

- `_triangle` conserve l'ordre des positions et le signe de normale existants. La projection choisit l'axe de la normale issue du produit vectoriel **après** correction du winding, puis calcule l'UV du même point qui est émis. Les deux triangles d'une face utilisent cette convention commune. Le chemin `_part` / `_bevel_box`, les tubes et les batches mixtes ont été lus ; `_cylinder` reste la primitive native.
- `_loft` garde les positions par modulo tout en laissant l'angle aller jusqu'à `SIDES` pour obtenir U=1 sur la dernière tranche. L'indexation ne fusionne donc pas les deux UV de la couture. V utilise les distances cumulées des centres de repos, sans dépendance à l'animation. Les caps définissent leur UV, couleur, normale, os et poids explicitement. Le changement de couleur des caps est volontaire ; le reste de la géométrie et du skinning reste identique au code antérieur.
- Neuf `StandardMaterial3D` sont préchargés directement ; pas de fabrique, registre ou classe ajoutée. Les slots et groupes mobiles sont inchangés. `FpsRig.update_visual` ne manipule que poses, visibilité et transformations. Les matériaux des départs de tir modifiés par `Player._attenuate` sont distincts et créés par Player. Le chemin Low touche les matériaux décoratifs propres à `WorldArt`, sans atteindre les nouvelles ressources FPS.
- Les ressources ordinaires n'activent pas l'émission ; les deux signaux conservent .8. Aucun shader, next_pass, transparence, normal map, AO, lumière, mesh ou propagation de qualité ajouté. Les cartes sont partagées, petites, filtrées avec mipmaps ; leur configuration d'import est explicite. La qualité perceptuelle du métal/isolant, les densités différentes des cylindres, les caps et le scintillement relèvent de la campagne visuelle, pas de cette lecture.
- Le générateur hors ligne utilise seulement la bibliothèque standard, avec motifs périodiques et PNG L8. Aucun appel au lancement n'existe dans les chemins lus. Ses six sorties ont été lues : IHDR 128×128 / gris 8 bits, CRC et données décompressées valides, empreintes identiques au manifeste. Je n'ai pas relancé le générateur ; la reproductibilité exécutée reste une preuve distincte. Les docs attribuent la création au projet sans inventer de licence, ne contiennent aucun asset tiers et distinguent estimation RGBA8 de VRAM mesurée.

## Preuves existantes examinées

Les huit logs (import et sept suites) correspondent à leurs SHA-256 dans `implementation/green-v1/verification.json`, sans FAIL ni erreur technique ; toutes leurs sorties enregistrées sont 0. Le log parent `parent-green/fps_materials.log` contient 24 PASS et 0 FAIL. Ces résultats ont été lus et leurs empreintes contrôlées, pas réexécutés pendant cette revue. Les sources du manifeste sont comparées aux fichiers examinés ci-dessous.

## Revue des commentaires

`cstack/no-comments` et le contrat du relecteur ont été lus. Aucun commentaire de production GDScript ajouté. La seule docstring du générateur explique la commande publique ; le shebang est une directive utile. Aucun contournement, suppression de lint ou assertion de sécurité cachée dans des commentaires. **0 suppression proposée, 0 suppression/restauration/correction appliquée, 0 relance, aucune contrainte non appliquée ni encodage à proposer.** Aucun descendant n'a été créé : cette assignation est déjà le délégué indépendant du parent.

## Limites

Ce PASS ne vaut ni approbation artistique, ni mesure de coût GPU, ni preuve de mips réellement chargés, ni validation Windows ou entrée native. Le parent garde les campagnes correspondantes. Aucun nouveau résultat d'exécution n'est revendiqué ici. Le verdict final doit nommer la version réellement retenue après revue artistique.

## Empreintes inspectées

Manifeste initial : 28 fichiers comparés ; différences actuelles : `[]`.

| Fichier | SHA-256 |
|---|---|
| `scripts/fps_hand_mesh.gd` | `2471b4f078075dc0b7637ea9649bd27eb57d3c8a44829a32b99a52c0adfa0cab` |
| `scripts/weapon_visual.gd` | `091da4558d1dcaa3aa7f8d0a085e844d0971ab356329231663c51082644c83e8` |
| `scripts/fps_rig.gd` | `d1813cada27a7e39cc5d15929e5ffd3b238d0aa4473133c59933018a789f3796` |
| `scripts/player.gd` | `42d8bce1728a082bc3972c12dfdad5c5e95bc6f3cfd5e5ab9730e9d533fa2514` |
| `scripts/world.gd` | `4935d30d5a317938c0d40a1c2261608650e5ef22b9cb102bb1ba231e61117717` |
| `scripts/world_art.gd` | `4a7024c31a6c88860e86524182734a3df7144d78b00966f83a32df857ed8415f` |
| `scripts/main.gd` | `c2c50911f4195ab398526b74409de82303f86e45a27deb726e37a654df72a738` |
| `tools/generate_fps_materials.py` | `31a78f40fb06ed27267ddc8f1d066da025178e75f1885c81788e6cc395bce3df` |
| `docs/OPEN_SOURCE.md` | `48d149dcaeb1361b103c882e53b593c334ee03b2d3e1678d6056b9da49c84f92` |
| `assets/fps/README.md` | `b6eb53599e52b0dcc8e5a2cecf3d0c20533f604f1c144731fcc0ff4b47b61c94` |
| `assets/fps/materials/cloth.tres` | `6a16ff7614fdf9ae8a9d1f1c21eb055b9d373345eb3143aa4f004fc969dbdac3` |
| `assets/fps/materials/contacts.tres` | `35aff1b156c03eab5d54949390c872d568e667e6511bea79f4548fd2e6ac87b1` |
| `assets/fps/materials/glove.tres` | `ec513851ea9c88ebf53f212ab6849f6d704b713bad86e66424d0d30e1256b258` |
| `assets/fps/materials/insulator.tres` | `e7b0edefd2acbbc91340993e6780d46b7d9b65171c09c4f63adb33f620954333` |
| `assets/fps/materials/paint_arc.tres` | `dc7f24834bdb68594a70133817e8ffb3de3c6d860fbf9a22ff155f1d42d94f82` |
| `assets/fps/materials/paint_d9.tres` | `e98d3c6c75160921dbb624d9af825e7b8b2e77fd903a5dc4bfce7c95cb05096e` |
| `assets/fps/materials/signal_arc.tres` | `ded9a049e6cdae1f0f92d0a56609f72b86b843556c5ad93928e79e70b9ebc3a1` |
| `assets/fps/materials/signal_d9.tres` | `2c7e3f48bd94dd68941f4b5e43f1f9c932a00349715bc23b96f13ea3ba104b26` |
| `assets/fps/materials/steel.tres` | `d8fb8f2db7a087b88de42908400eb0310d52bfa55beac74ab94aee46cd9ad834` |
| `assets/fps/textures/cloth_albedo.png` | `d1194276e9151d646f7a7fe710c9ca7b0a3a00e8cca6cf4888b2d512d2d2b6a2` |
| `assets/fps/textures/cloth_albedo.png.import` | `eed404d3a85f0bc39f69542f235f4688e3ad6cc72ddee4c338b58ff47ef940b0` |
| `assets/fps/textures/cloth_roughness.png` | `e4b016f2c4d5d748f7fb31a2ed966c7da33c00273f084bf2cead3bcc88226717` |
| `assets/fps/textures/cloth_roughness.png.import` | `e0b3e285e23ffe03b16d1632299b312bb302eccca095fe3245df5d20122ca979` |
| `assets/fps/textures/glove_albedo.png` | `1e47b6ff26c47e822cd498666bfc74ee7804c1bba449f65424f8fa8e80a64768` |
| `assets/fps/textures/glove_albedo.png.import` | `f1a988a91f42b312efa63abf06f3c08f4153f06e5834f0df1f8df5b748d15430` |
| `assets/fps/textures/glove_roughness.png` | `2ee40bdd7a2f46acddae1b916cde1a377b04c980800a06d2af07cdb98459a746` |
| `assets/fps/textures/glove_roughness.png.import` | `57b9f683ac64910e7205e30a1223147ab7a82356e4c3b2d26f79c5e9e6a5dced` |
| `assets/fps/textures/paint_albedo.png` | `02cfbc023ecf57d4c59ba77f3ba2cf8d284e25e0968029248a7aba4cb938056f` |
| `assets/fps/textures/paint_albedo.png.import` | `fd0b6423804262b5c906087131a97055f0c49a19c9bbfcc91c17754b7b34eb3e` |
| `assets/fps/textures/paint_roughness.png` | `da15215a1ff278c61bae644df01c79984b61edfddff37bd49eedf001e18c3993` |
| `assets/fps/textures/paint_roughness.png.import` | `7935e25205ffa6020ecbfd000014f2475bc3489a90f766e7a1f8c034362b5cb0` |
| `assets/fps/textures.json` | `205edf78613a095aeeaf14e9384660076a3d77f2b048131f29e57528aebbd1b8` |

Tests examinés seulement comme preuves existantes (auteur identique, aucune indépendance revendiquée) :

- `tests/test_fps_materials.gd` : `d625af40655015321e5aefd7ee2acd61ebfd1f7f88c8a56372fe246085f91fa4`
- `tests/fixtures/fps_geometry_98f2d4a.json` : `8b6073e2ed4915017c7c047a90044956e5ec375009d93289a842b9d57153b642`
