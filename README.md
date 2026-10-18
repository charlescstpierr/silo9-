# SILO 9 : La Descente

FPS solo en français sous Godot 4.7.2. Vous explorez quatre secteurs industriels, récupérez un noyau de contrôle et choisissez entre MÈRE et N-7.

## Jouer

Sur Windows, décompressez le paquet puis lancez `SILO9.exe`. Sur Linux, lancez `SILO9.x86_64` dans le paquet Linux. Le projet source s'ouvre avec `project.godot` dans Godot 4.7.2. Le rendu Compatibility vise aussi les machines modestes.

Depuis ce workspace Linux :

```sh
./tools/run.sh
```

| Commande | Action |
|---|---|
| WASD ou ZQSD | Déplacement, disposition dans Réglages |
| Souris | Regarder |
| Maj | Sprint |
| Espace | Saut |
| Ctrl | S'accroupir |
| Clic gauche | Tir |
| 1 / 2 | D9 / ARC-3 |
| R | Recharger le D9 |
| Q en WASD, A en ZQSD | SCAN ÉCHO |
| E | Interagir avec la cible |
| Tab | Inventaire |
| H / B | Trousse / cellule d'énergie |
| Échap | Pause, libération et reprise de la souris |
| F5 / F9 | Sauvegarder / charger |
| F3 | Afficher les performances |

Le scan et l'ARC-3 partagent la batterie. Le scan révèle le relais caché en maintenance et alerte les machines. L'ascenseur permet de recharger gratuitement ; ses améliorations et la réparation du relais consomment des composants.

## Conversations

Le jeu fonctionne entièrement hors ligne. Les réponses scénarisées et les indices immédiats restent disponibles en cas de panne du serveur IA.

Pour un serveur llama.cpp local, renseignez son adresse et son identifiant de modèle dans **Réglages**. Le jeu utilise `/v1/chat/completions`. Les serveurs locaux HTTP et les proxys HTTPS sont acceptés. Aucune clé de fournisseur n'est embarquée. Un service payant doit conserver sa clé côté serveur et contrôler ses accès et quotas.

Vous écrivez librement. Le modèle sélectionne les faits pertinents, une réaction autorisée du personnage et des intentions contrôlées. Le jeu compose la réponse depuis le canon et valide les actions. Cette formulation encadrée empêche l'affichage de zones ou d'objets inventés, avec une variété de réponses limitée dans ce MVP. Les indices immédiats restent scénarisés.

## Vérifier et exporter

```sh
./tools/verify.sh
./tools/export.sh
```

`GODOT_BIN` peut désigner un autre exécutable Godot 4.7.2. L'export utilise les modèles officiels de la même version placés dans `.tools/templates/`. Modifiez les chemins de modèles personnalisés dans `export_presets.cfg` pour une autre installation.

Le benchmark rend les quatre secteurs en 1080p, avec l'IA ennemie active et un scan en maintenance :

```sh
./tools/godot.sh --path . -- --benchmark --capture
./tools/godot.sh --path . -- --benchmark --low
```

Les résultats distinguent le moteur graphique, les temps de frame et les limites de la machine. Un test headless ne mesure pas les performances graphiques. Voir [les résultats de validation](docs/VALIDATION.md).

## Ressources et licences

Voir [l'audit open source](docs/OPEN_SOURCE.md), les licences CC0 des quatre modèles [Kenney](assets/kenney/LICENSE.txt) et des six modules [Quaternius](assets/quaternius/LICENSE.txt), ainsi que les [notices Godot](docs/licenses/GODOT.txt). Les armes, robots, interfaces et sons sont créés pour ce projet. Les textures industrielles comprennent des images procédurales et une image peinte générée pour SILO 9. Les poids d'un modèle conversationnel ne font pas partie du jeu distribué.
