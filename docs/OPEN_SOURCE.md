# Ressources open source de SILO 9

La [recherche graphique Mission Astra du 18 octobre 2026](ASTRA_OPEN_SOURCE.md) complète ce registre avec les choix de matériaux, de rig et d'animation.

Audit du 17 octobre 2026. Ce registre distingue les composants utilisés, les références consultées et les candidats non intégrés. Les licences, README, métadonnées de version et fichiers de code cités ont été examinés. Une compatibilité annoncée par un auteur ne constitue pas un test d'exécution dans SILO 9.

Aucun addon de gameplay tiers n'est importé. Le contrôleur, les machines à états ennemies, les dialogues déterministes et les tests headless utilisent les API natives de Godot. Aucun projet amont complet n'est incorporé. Les pins ci-dessous identifient les versions examinées, pas des dépendances implicitement installées.

## Godot, moteur utilisé

- Version retenue : **4.7.2 stable**, tag `4.7.2-stable`, commit `ed1daf0bf001b61586d9930840f2f1394092c079`.
- Vérification moteur effectuée pendant la construction : téléchargement officiel, contrôle SHA de l'archive et exécution de `--version`, qui identifie `ed1daf0bf`. Les tests du jeu constituent une vérification séparée.
- Archive moteur contrôlée, SHA-256 : `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`.
- Licence : **MIT**, Godot Engine contributors et Juan Linietsky / Ariel Manzur. Le moteur embarque aussi des bibliothèques tierces dont les notices accompagnent sa distribution.
- Usage : GDScript typé, scènes 3D, collisions, rendu, interface et `HTTPRequest`. Le projet n'exige pas la variante .NET.
- Modifications du moteur : aucune.
- Sources : [version publiée](https://github.com/godotengine/godot/releases/tag/4.7.2-stable), [licence épinglée](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/LICENSE.txt), [notices tierces](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/COPYRIGHT.txt), [CharacterBody3D 4.7](https://docs.godotengine.org/en/4.7/classes/class_characterbody3d.html), [HTTPRequest 4.7](https://docs.godotengine.org/en/4.7/classes/class_httprequest.html).

## FirstPersonStarter, référence consultée

- Dépôt : `Whimfoome/godot-FirstPersonStarter`.
- Pin examiné : `893db99a10eedadbd8189c040fb4d41fdf6ca46a`, head `main` du 25 avril 2024. Le dernier tag listé est `v1.3`, commit `c9f77c321f63d37ad2d6067107c9c930aa1fae18`, distinct de la version examinée.
- Licence : **MIT**, Dimitar "Whimfoome" Dimitrov.
- Compatibilité annoncée : **Godot 4.2** dans le README et `project.godot`. Aucun essai de cet amont sous 4.7.2 n'est revendiqué.
- Code examiné : `Player/MovementController.gd`, `Player/Head.gd`, `Player/Sprint.gd` et `Levels/Main/L_Main.gd`.
- Fonctionnement : `CharacterBody3D.move_and_slide()`, accélération et décélération horizontales, caméra à pitch limité, sprint configurable. Aucun plugin externe n'est requis par ces scripts. La scène de démonstration référence des textures Kenney qui ne sont pas importées.
- Limites : le code examiné ne comporte pas de résolution explicite des marches ni d'accroupissement. Échap ferme directement la démonstration. Ce gestionnaire ne convient pas au menu pause du jeu.
- Décision : référence de contrôle FPS, non importée. SILO 9 conserve un contrôleur natif adapté aux interactions, à la pause et aux armes. Aucun fichier amont modifié.
- Sources : [README](https://github.com/Whimfoome/godot-FirstPersonStarter/blob/893db99a10eedadbd8189c040fb4d41fdf6ca46a/README.md), [mouvement](https://github.com/Whimfoome/godot-FirstPersonStarter/blob/893db99a10eedadbd8189c040fb4d41fdf6ca46a/Player/MovementController.gd), [licence](https://github.com/Whimfoome/godot-FirstPersonStarter/blob/893db99a10eedadbd8189c040fb4d41fdf6ca46a/LICENSE).

## Beehave, addon non retenu

- Pin examiné : `v2.9.3`, commit `773a5f6dd9b3433cdb8735ab35e9043d4cd60674`.
- Activité observée : head `godot-4.x` à `fe589153fa780a3f88989578ceb5f539afffb7c2`, daté du 20 septembre 2026. Le dépôt n'est pas archivé.
- Licence : **MIT**, bitbrain.
- Compatibilité : le README du tag associe 2.9.x à Godot 4.1 et 2.10+ à Godot 4.5+. Son `project.godot` déclare pourtant 4.7. Cette divergence impose un test moteur avant toute intégration. Aucun résultat d'exécution de Beehave sous 4.7.2 n'est revendiqué.
- Code examiné : `blackboard.gd` et `nodes/beehave_tree.gd`. L'arbre traite des nœuds de comportement, partage un blackboard et expose un débogueur ainsi que des mesures.
- Dépendances : les autoloads internes `BeehaveGlobalMetrics` et `BeehaveGlobalDebugger` sont utilisés par le runtime. Le dépôt inclut gdUnit4 pour ses tests. Une intégration éventuelle porterait sur `addons/beehave` et ses templates nécessaires, pas sur le dépôt entier.
- Décision : non retenu pour deux types d'ennemis. Des états nommés rendent patrouille, investigation, poursuite, attaque et recherche directement testables. Aucun fichier importé ou modifié.
- Sources : [README](https://github.com/bitbrain/beehave/blob/773a5f6dd9b3433cdb8735ab35e9043d4cd60674/README.md), [arbre runtime](https://github.com/bitbrain/beehave/blob/773a5f6dd9b3433cdb8735ab35e9043d4cd60674/addons/beehave/nodes/beehave_tree.gd), [licence](https://github.com/bitbrain/beehave/blob/773a5f6dd9b3433cdb8735ab35e9043d4cd60674/LICENSE).

## Dialogue Manager, addon non retenu

- Pin examiné : `v4.1.0`, commit `a719088aea342572f29b5559fd8726896c9519b2`.
- Activité observée : head `main` à `7a72dcf64cfec8673d398606f2991d4cf81f2d11`, daté du 17 octobre 2026. Le dépôt n'est pas archivé.
- Licence : **MIT**, Nathan Hoad et Dialogue Manager contributors.
- Compatibilité annoncée : **Godot 4.6+**. Le projet de tests déclare 4.7 et active C#. Le runtime comprend du GDScript et un wrapper C# optionnel. Le projet de tests n'est pas une dépendance du jeu.
- Code examiné : `addons/dialogue_manager/dialogue_manager.gd`, débogueur et manifeste du plugin. Le composant apporte un éditeur, un interpréteur de dialogues à embranchements et des mutations d'état.
- Frontière de confiance : le runtime autorise par défaut des appels aux singletons, aux classes et aux ressources. `load_from_within_dialogue` vaut `load` et le filtre `validate_member_access` autorise tout par défaut. Ce système ne doit pas interpréter une réponse LLM comme du code de dialogue.
- Décision : non retenu pour le MVP. Les dialogues hors ligne restent des données déterministes. Les réponses du modèle passent par un schéma et une liste d'actions autorisées, sans évaluation d'expressions. Aucun fichier importé ou modifié. L'éditeur pourra être réévalué si le volume de dialogues justifie cette dépendance.
- Sources : [README](https://github.com/nathanhoad/godot_dialogue_manager/blob/a719088aea342572f29b5559fd8726896c9519b2/README.md), [runtime](https://github.com/nathanhoad/godot_dialogue_manager/blob/a719088aea342572f29b5559fd8726896c9519b2/addons/dialogue_manager/dialogue_manager.gd), [licence](https://github.com/nathanhoad/godot_dialogue_manager/blob/a719088aea342572f29b5559fd8726896c9519b2/LICENSE).

## Démos officielles Godot, références consultées

- Pin examiné : tag `4.7-6ad6167`, commit `6ad6167e0577fe3622c18546138f456b107ce93c`.
- Activité observée : head `master` à `b761b4cd5718a7118f2c95eb55f181d0a5f004f1`, daté du 8 octobre 2026.
- Licence générale : **MIT**, Godot Engine contributors et Juan Linietsky / Ariel Manzur. Les ressources d'une démo nécessitent aussi la lecture de leurs éventuelles notices propres avant copie.
- Compatibilité : le README réserve `master` au moteur en développement. Le tag 4.7 évite de dépendre de changements destinés à une version suivante.
- Code examiné : `3d/kinematic_character/player/cubio.gd`, `3d/navigation/character.gd`, `3d/ik/fps/example_player.gd` et `simple_bullet.gd`.
- Enseignements retenus : collision avec `CharacterBody3D`, lecture du chemin de `NavigationAgent3D`, remise à zéro de l'interpolation après téléportation. La démo de navigation déplace directement un `Marker3D` et ne remplace pas un ennemi physique.
- Décision : références uniquement. Aucune scène, texture, extension IK ni dépendance de démonstration importée. Aucun fichier amont modifié.
- Sources : [README](https://github.com/godotengine/godot-demo-projects/blob/6ad6167e0577fe3622c18546138f456b107ce93c/README.md), [personnage](https://github.com/godotengine/godot-demo-projects/blob/6ad6167e0577fe3622c18546138f456b107ce93c/3d/kinematic_character/player/cubio.gd), [navigation](https://github.com/godotengine/godot-demo-projects/blob/6ad6167e0577fe3622c18546138f456b107ce93c/3d/navigation/character.gd), [licence](https://github.com/godotengine/godot-demo-projects/blob/6ad6167e0577fe3622c18546138f456b107ce93c/LICENSE.md).

## gdUnit4, outil de test non retenu

- Pin examiné : `v6.2.2`, commit `0127a55f4543dfc24746f6e5c7ba6f94105d51f2`, publication du 7 octobre 2026.
- Activité observée : head `master` à `e7aaa13df0bac10b18308af2fa6a3839cedaaab6`, daté du 17 octobre 2026.
- Licence : **MIT**, Mike Schulze.
- Compatibilité annoncée : la table 6.2.x inclut Godot 4.5 à 4.7.1. Le patch 4.7.2 n'y apparaît pas explicitement. Aucun essai de l'addon sur ce patch n'est revendiqué.
- Dépendances : addon intégré à Godot, avec support GDScript et outillage C# facultatif. Le jeu ne dépend ni de son éditeur de tests ni de son intégration .NET.
- Décision : non installé. Des scripts de test headless natifs couvrent les comportements déterministes sans ajouter d'addon au projet. Cette décision ne constitue pas une évaluation négative de sa qualité. Aucun fichier importé ou modifié.
- Sources : [version](https://github.com/godot-gdunit-labs/gdUnit4/releases/tag/v6.2.2), [compatibilité](https://github.com/godot-gdunit-labs/gdUnit4/blob/0127a55f4543dfc24746f6e5c7ba6f94105d51f2/README.md), [licence](https://github.com/godot-gdunit-labs/gdUnit4/blob/0127a55f4543dfc24746f6e5c7ba6f94105d51f2/LICENSE).

## llama.cpp, serveur externe facultatif

- Pin examiné : `b11716`, commit `797de63b2fa7396dcc8caca76834c699ac84e1c3`, publication du 17 octobre 2026.
- Licence du logiciel : **MIT**, The ggml authors. La licence du logiciel ne couvre pas les poids d'un modèle.
- Compatibilité : indépendante de la version Godot via HTTP. Le serveur expose notamment `/v1/models` et `/v1/chat/completions` compatibles avec les API de conversation de type OpenAI.
- Dépendances : exécutable serveur, poids GGUF et ressources mémoire adaptées au modèle. Une compilation utilise CMake et une chaîne C/C++ ; les backends CUDA, Metal, Vulkan et autres sont optionnels selon le matériel.
- Décision : cible d'adaptateur facultative, non incorporée au jeu. Un petit modèle local a ensuite été téléchargé et testé ; voir la section de vérification ci-dessous. Le mode scénarisé doit fonctionner sans serveur et après timeout ou réponse invalide.
- Sécurité : aucune clé secrète de service payant distribuée avec le jeu. Une réponse réseau ne fournit que du texte et des propositions d'actions validées par le moteur. Aucun accès arbitraire au système de fichiers ou exécution de code.
- Modifications amont : aucune.
- Sources : [version](https://github.com/ggml-org/llama.cpp/releases/tag/b11716), [serveur](https://github.com/ggml-org/llama.cpp/blob/797de63b2fa7396dcc8caca76834c699ac84e1c3/tools/server/README.md), [licence](https://github.com/ggml-org/llama.cpp/blob/797de63b2fa7396dcc8caca76834c699ac84e1c3/LICENSE).

## Quaternius Modular Sci-Fi MegaKit, édition Standard utilisée

- Source gratuite : [page du pack](https://quaternius.com/packs/modularscifimegakit.html) et [distribution itch.io](https://quaternius.itch.io/modular-sci-fi-megakit).
- Licence **CC0-1.0**, confirmée dans la notice interne de l'archive Standard. Pro et Source payants ne sont pas utilisés.
- Archive Standard, SHA-256 : `6fae60cf5189e44dff0bd91097f094a765acc6d57d64a85a0cc0dd56e03035e3`.
- Dix-huit modèles ont été examinés et instanciés sous Godot 4.7.2. Les six utilisés sont conservés : `WallAstra_Straight`, `WallAstra_Straight_Window`, `TopCables_Straight`, `Door_Frame_SquareTall`, `Prop_Vent_Big`, `Prop_Computer`.
- Les images et géométries originales sont inchangées. Le jeu clone leurs matériaux pour appliquer sa palette stylisée. Les paramètres d'import Godot activent les mipmaps.
- [Licence conservée](../assets/quaternius/LICENSE.txt), [provenance](../assets/quaternius/PROVENANCE.json) et [inventaire des dépendances](../assets/quaternius/asset-manifest.json).
- Les autres éléments du décor, les armes et les robots sont construits pour SILO 9. Les textures procédurales sont reproductibles avec `assets/industrial/generate_textures.py`. Le panneau peint `painted_panel_v2.png` a été généré spécialement avec imagegen ; ce script ne le reproduit pas. Sa provenance figure dans `assets/industrial/README.md`.

## Kenney Factory Kit, sous-ensemble utilisé

- Version examinée : **3.0**, annoncée le 1er mai 2026, 140 ressources sur la [page officielle](https://kenney.nl/assets/factory-kit).
- Archive gratuite identifiée : [kenney_factory-kit_3.0.zip](https://kenney.nl/media/pages/assets/factory-kit/edaac9d4f6-1777639602/kenney_factory-kit_3.0.zip).
- Licence annoncée : **CC0-1.0**. Le téléchargement gratuit du pack est distinct du bundle All-in-1 proposé séparément.
- Archive épinglée, SHA-256 : `7e31fb2308e90304672bd15cd18fa9d9f02c03731a8cbc57a8e3e1c181dfb0a7`.
- Fichiers retenus : `assets/kenney/machine.glb`, `machine-fortified.glb`, `box-large.glb` et `pipe-large-valve.glb`. Les quatre fichiers originaux et leur texture externe `assets/kenney/Textures/colormap.png` restent non modifiés. Le fichier [LICENSE.txt original](../assets/kenney/LICENSE.txt) est conservé. La sélection et la provenance figurent dans `.cstack/silo9/evidence/kenney-import.json`.
- Compatibilité : quatre modèles GLB, sans addon de gameplay requis. Import et rendu sous Godot 4.7.2 vérifiés dans le niveau ; la texture externe requise est conservée.
- Décision : sous-ensemble gratuit copié pour le décor industriel. Aucun achat du bundle. Les collisions et placements du niveau restent propres à SILO 9.
- Licence de référence : [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/).

## Crédits et limites de vérification

Les copies substantielles de code MIT conservent le copyright et le texte de permission. Les avis de Godot et de ses bibliothèques doivent accompagner les distributions du moteur. CC0 n'impose pas d'attribution, mais la provenance des ressources utilisées reste inscrite dans ce registre et dans les notices livrées avec le jeu.

Les références examinées n'ajoutent aucun droit sur les assets des jeux cités comme inspirations. Aucun contenu de Subnautica, S.T.A.L.K.E.R., Prey, Alien: Isolation ou BioShock n'est réutilisé.

Cet audit vérifie les sources et les conditions d'intégration. Il ne prétend pas que les addons non installés ont passé les tests du jeu ni que l'exécutable Windows a été exécuté sur Windows. Ces preuves relèvent de la vérification de livraison.

## Modèle local utilisé pour la vérification

Qwen2.5-0.5B-Instruct-GGUF, révision `9217f5db79a29953eb74d5343926648285ec7e67`, fichier `qwen2.5-0.5b-instruct-q4_k_m.gguf`, [source officielle](https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/tree/9217f5db79a29953eb74d5343926648285ec7e67), licence Apache-2.0. SHA-256 : `74a4da8c9fdbcd15bd1f6d01d621410d31c6fc00986f5eb687824e7b93d7a9db`. Le modèle et llama.cpp restent des outils locaux de QA, exclus des exécutables et archives source distribués. Les licences sont conservées avec eux dans `.tools/llama/`. Les deux personnages ont reçu une réponse du vrai modèle via le jeu. Le test initial de prose libre a révélé des inventions. La version finale affiche uniquement des réactions approuvées et les faits canoniques sélectionnés par le modèle ; deux essais répétés avec MÈRE et N-7 ont validé cette connexion encadrée.
