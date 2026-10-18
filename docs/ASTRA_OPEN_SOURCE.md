# Mission Astra : ressources et provenance

Audit du 18 octobre 2026 pour Godot 4.7.2. La tranche conserve les kits CC0 déjà intégrés, le rig original de SILO 9 et les matériaux natifs Godot. Aucun nouvel addon graphique ni logiciel d'auteur n'est installé. Les liens épinglés désignent les versions examinées, pas des dépendances du jeu.

## Projets évalués

Les coûts sont des estimations d'intégration. Les mesures du jeu et les captures relèvent de [validation Astra](ASTRA_VALIDATION.md). Une compatibilité annoncée ne vaut pas un test moteur.

| Projet et source examinée | Licence, version et maintenance observées | Compatibilité, bénéfice et coût | Décision |
| --- | --- | --- | --- |
| [Blender](https://github.com/blender/blender/blob/v5.2.2/COPYING) | GPL. Tag `v5.2.2`, 14 septembre 2026. Dépôt actif le 17 octobre. Le site de téléchargement a répondu 403. | Export GLB recommandé par la [documentation Godot 4.7](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/assets_pipeline/importing_3d_scenes/available_formats.rst). Permet de régler anatomie et poids. Coût d'auteur, aucune dépendance runtime si le GLB est livré. Export non testé ici. | Non installé. Le rig existant évite de remplacer le pipeline des mains pendant cette tranche. |
| [Rigify](https://github.com/blender/blender/blob/v5.2.2/scripts/addons_core/rigify/__init__.py) | GPL-2.0-or-later. `0.6.10` dans Blender `v5.2.2`, composant officiel. | Outil Blender. Les contraintes doivent devenir des animations exportables pour Godot. Utile pour un personnage complet, plus de réglages qu'un rig limité aux avant-bras. | Non installé. Aucun script Rigify requis par le jeu. |
| [Godot Demo Projects](https://github.com/godotengine/godot-demo-projects/blob/4.7-6ad6167/3d/ik/README.md) | MIT générale. Tag `4.7-6ad6167`, 7 juillet 2026. Dépôt actif le 8 octobre. | La démo IK déclare Forward+ et utilise SkeletonIK3D ou FABRIK via SADE. Référence pour les animations, sans preuve de compatibilité avec le rendu Compatibility de SILO 9. | Référence uniquement. Aucune scène, extension ou ressource copiée. |
| [Material Maker](https://github.com/RodZill4/material-maker/blob/1.7/LICENSE.md) | MIT. Release GitHub `1.7`, 14 juillet 2026. Dépôt actif le 15 octobre. | Son [projet](https://github.com/RodZill4/material-maker/blob/1.7/project.godot) déclare Godot 4.7. Export de cartes PBR sans dépendance runtime. Peut produire usure et textiles, mais ajoute un outil d'auteur à maintenir. | Non installé. Générateurs déterministes du dépôt conservés. |
| [Poly Haven](https://github.com/Poly-Haven/polyhaven.com/blob/b1a6aa13afc03ae00860f6ac5fe6d5daf8e95356/public/locales/en/license.json) | Assets CC0, distincts du code du site sous AGPL. Source de licence vérifiée au commit du 23 septembre 2026. Aucun asset individuel épinglé. | Cartes PBR indépendantes de Godot, utiles pour acier et oxydation. Résolution et échantillonnage déterminent le coût. Site et API bloqués par HTTP 403 pendant l'audit. | Aucun asset importé. Les cartes existantes permettent de commencer sans téléchargement. |
| [ambientCG](https://docs.ambientcg.com/license/) | CC0-1.0. Catalogue sans version globale. API active, avec Fabric085 publié le 10 octobre et Clay009 le 15 octobre 2026. | [Metal027](https://ambientcg.com/a/Metal027), [Rubber004](https://ambientcg.com/a/Rubber004) et [Fabric085](https://ambientcg.com/a/Fabric085) identifiés par API. Cartes intéressantes pour métal, caoutchouc et tissu, à limiter à 512 ou 1024 pixels. Fichiers non téléchargés ni testés. | Candidats documentés, non intégrés. Les nouveaux microdétails sont originaux. |
| [Cyclops Level Builder](https://github.com/blackears/cyclopsLevelBuilder/blob/v1.5.1/README.md) | [MIT](https://github.com/blackears/cyclopsLevelBuilder/blob/v1.5.1/LICENSE.txt). Release `v1.5.1`, 13 octobre 2026. Dépôt actif le 17 octobre. | L'auteur annonce Godot 4.7 et suivants pour la série 1.5. Addon avec CyclopsAutoload et possibles migrations de scènes. Utile pour éditer les volumes, sans test 4.7.2 ici. | Non retenu. Le niveau dispose déjà de volumes, collisions et placements par scripts. |
| [Proton Scatter](https://github.com/HungryProton/scatter/blob/7198cc00078ebde61307578137c3f35223c6e438/README.md) | [MIT](https://github.com/HungryProton/scatter/blob/4.0/LICENSE.md) pour l'addon. Release `4.0`, 23 octobre 2023. Head actif le 27 septembre 2026. | Godot 4 annoncé, 4.7.2 non testé. Dispersion de débris possible, mais ajoute un système de placement à celui du niveau. Les textures de démo Textures.com ont des conditions distinctes et ne sont pas redistribuables seules. | Non retenu. Aucune copie de la démo. |
| [Quaternius Modular Sci-Fi MegaKit](https://quaternius.com/packs/modularscifimegakit.html) | CC0, édition Standard gratuite. Archive épinglée ci-dessous. La page ne donne pas de version stable du pack. | Six modèles glTF déjà intégrés. Câbles, cadres et machines adaptés à la palette. De 272 à 942 triangles par modèle selon le manifeste local. | Conservé. Ni édition Source payante ni shaders propres à d'autres moteurs. |
| [Quaternius Sci-Fi Essentials Kit](https://quaternius.com/packs/scifiessentialskit.html) | CC0 et usage commercial annoncés sur la page officielle consultée le 18 octobre 2026. Pas de version chiffrée ni date de mise à jour du pack indiquée. | La page annonce 65 modèles, dont robots et écrans animés, armes et accessoires, en FBX/OBJ/Blend/glTF. Elle précise que seulement 60–70 % du pack est gratuit ; la répartition des fichiers gratuits n’a pas été vérifiée. Import Godot 4.7.2 et retargeting non testés. | Non intégré dans cette tranche. Les robots existants ont été articulés sans changer leurs silhouettes ni leur IA. Le prototype d’import demandé par [#81](https://github.com/charlescstpierr/silo9-/issues/81) reste ouvert. |
| [Kenney Factory Kit](https://kenney.nl/assets/factory-kit) | CC0, `3.0`. Notice du 1er mai 2026. La page officielle confirme 140 ressources. | Quatre GLB et leur colormap déjà intégrés. Formes industrielles stylisées, aucune dépendance de gameplay. | Conservé, avec les collisions propres au niveau. |
| [chafmere Godot4-FPS-Template](https://github.com/chafmere/Godot4-FPS-Template/blob/71309293911f57b124cf1b4be751df311b20b48c/README.md) | [MIT](https://github.com/chafmere/Godot4-FPS-Template/blob/71309293911f57b124cf1b4be751df311b20b48c/LICENSE). Head du 1er février 2026. Dernière release retournée par GitHub : `v2.0.3`, 2 mars 2024. | Le head déclare Godot 4.6 et Forward+. Ressources d'armes et événements d'animation utiles comme référence. L'import complet imposerait d'autres contrats de cibles, munitions et projectiles. Non exécuté sous 4.7.2. | Référence pour [#84](https://github.com/charlescstpierr/silo9-/issues/84). Aucun code ou asset copié. |

Les dates d'activité ci-dessus proviennent des métadonnées des dépôts officiels consultées le 18 octobre. « Release GitHub » décrit la réponse de l'API, sans affirmer qu'il s'agit de la dernière distribution disponible ailleurs. La licence des outils ne remplace pas celle des assets qu'ils manipulent.

## Provenance des ressources intégrées

### Quaternius : six modèles conservés

Auteur : Quaternius. Distribution : [Modular Sci-Fi MegaKit Standard sur itch.io](https://quaternius.itch.io/modular-sci-fi-megakit), upload gratuit `13454739`. SHA-256 de l'archive d'origine : `6fae60cf5189e44dff0bd91097f094a765acc6d57d64a85a0cc0dd56e03035e3`.

La [licence CC0 originale](../assets/quaternius/LICENSE.txt), la [provenance](../assets/quaternius/PROVENANCE.json) et le [manifeste](../assets/quaternius/asset-manifest.json) accompagnent les modèles. La sélection contient `WallAstra_Straight`, `WallAstra_Straight_Window`, `TopCables_Straight`, `Door_Frame_SquareTall`, `Prop_Vent_Big` et `Prop_Computer`.

Les géométries et images originales restent inchangées. Godot active les mipmaps à l'import. Le jeu clone les matériaux pour sa palette et regroupe les surfaces statiques. L'import et le rendu 4.7.2 sont documentés dans le [registre initial](OPEN_SOURCE.md), indépendamment de l'évaluation des addons non installés.

### Kenney : quatre modèles conservés

Auteur : Kenney. Version : Factory Kit 3.0. Source : [archive officielle](https://kenney.nl/media/pages/assets/factory-kit/edaac9d4f6-1777639602/kenney_factory-kit_3.0.zip). SHA-256 de l'archive d'origine : `7e31fb2308e90304672bd15cd18fa9d9f02c03731a8cbc57a8e3e1c181dfb0a7`.

La [licence CC0 originale](../assets/kenney/LICENSE.txt) accompagne `machine.glb`, `machine-fortified.glb`, `box-large.glb` et `pipe-large-valve.glb`. Leur dépendance `Textures/colormap.png` est conservée. Ces fichiers restent inchangés. Aucun bundle payant n'est requis. L'import et le rendu 4.7.2 sont documentés dans le registre initial.

### Mains et rig originaux de SILO 9

Le rig existant a été repris depuis le commit [`301c2fde11e0254f962665cf696f4723f1983f72`](https://github.com/charlescstpierr/silo9-/commit/301c2fde11e0254f962665cf696f4723f1983f72). [fps_rig.gd](../scripts/fps_rig.gd) construit un `Skeleton3D`, et [fps_hand_mesh.gd](../scripts/fps_hand_mesh.gd) produit le maillage et ses poids.

Le squelette compte 35 os : une racine et 17 os par bras, dont trois articulations par doigt et deux pour le pouce. [test_fps_rig.gd](../tests/test_fps_rig.gd) vérifie ce compte. Les sources sont originales au projet. Aucun modèle humain tiers, rig Blender ou code Rigify n'est incorporé. Ce choix conserve une génération reproductible et évite une nouvelle dépendance d'import.

### Textures originales et matériaux

Les familles `panel`, `deck`, `alloy` et `grate` contiennent chacune albedo, normales tangentes et rugosité à 512 × 512 pixels. [generate_textures.py](../assets/industrial/generate_textures.py) les reproduit avec des graines fixes, Pillow et NumPy. Ces bibliothèques sont des outils de génération, pas des dépendances du jeu exporté.

`painted_panel_v2.png` a été créé avec imagegen le 17 octobre 2026. Il ne vient pas d'une banque d'assets et le générateur procédural ne le reproduit pas. La distinction figure dans le [README des surfaces](../assets/industrial/README.md).

Les familles `worn_steel` et `weave` ajoutées pour Astra sont des textures originales déterministes de 256 × 256 pixels. [generate_detail_materials.py](../assets/industrial/generate_detail_materials.py) les reproduit avec la graine `9009`. Elles n'utilisent aucun pixel téléchargé ni image tierce. La géométrie donne les silhouettes, tandis que ces cartes donnent le détail de surface. Les matériaux utilisent les canaux albedo, normale et rugosité disponibles dans `StandardMaterial3D`.

Le profil léger conserve l'albedo et désactive les détails coûteux selon le matériau. La résolution des cartes et leur provenance ne constituent pas une mesure de coût GPU. Les images générées restent dans le dépôt pour éviter de rendre la compilation du jeu dépendante des outils d'auteur.

## Écart avec le template FPS, ticket #84

Les fichiers [WeaponResource](https://github.com/chafmere/Godot4-FPS-Template/blob/71309293911f57b124cf1b4be751df311b20b48c/Player_Controller/scripts/Weapon_State_Machine/weapon_resource.gd), [Weapon_State_Machine](https://github.com/chafmere/Godot4-FPS-Template/blob/71309293911f57b124cf1b4be751df311b20b48c/Player_Controller/scripts/Weapon_State_Machine/Weapon_State_Machine.gd) et [Projectile](https://github.com/chafmere/Godot4-FPS-Template/blob/71309293911f57b124cf1b4be751df311b20b48c/Player_Controller/scripts/Projectiles/Projectile.gd) ont été lus au même commit.

| Fonction | Template examiné | Choix pour SILO 9 |
| --- | --- | --- |
| Définition d'arme | Statistiques et noms d'animations dans WeaponResource. | Conserver [WeaponSpec](../scripts/weapon_spec.gd) et les ressources D9 et ARC-3. |
| Munitions | Chargeur et réserve dans chaque WeaponSlot. | Conserver [RunState](../scripts/run_state.gd), propriétaire des cartouches et de l'énergie commune à l'ARC-3 et au Scan Écho. |
| Recharge | AnimationPlayer déclenche `calculate_reload` en fin d'animation normale. Le mode incrémental permet un appel depuis une piste d'animation. | Retenir un événement de transfert unique sur la chronologie du chargeur. Vérifier les interruptions avant et après cet événement. |
| Changement d'arme | Animation mise en file, puis changement à sa fin. | Préserver l'annulation explicite et les règles de pause et de décès du joueur. |
| Projectiles | Un composant par tir, avec hitscan, corps rigide et interfaces `Target` et `Hit_Successful`. | Préserver le raycast et `receive_hit`, déjà reliés aux ennemis du jeu. |

Cette comparaison remplit la partie documentaire de #84. La démonstration D9 et les tests de cohérence et d'interruption restent des preuves séparées dans la validation. L'audit ne justifie pas, à lui seul, de fermer le ticket.
