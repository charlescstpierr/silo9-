# Revue visuelle indépendante du binaire Linux

Verdict : **PASS borné au parcours de vérification décrit ci-dessous.** Les 12 PNG ont été ouverts individuellement avec `view_image`, puis examinés. Aucun défaut visuel bloquant observé dans cette séquence. Aucun moteur, nouvelle capture ou test exécuté par ce réviseur.

Règles cstack runtime/base, unslop et principle-prove-it-works lus. La revue porte sur les images réelles et les journaux fournis, sans reprendre un verdict délégué.

## Provenance examinée

- Dossier des captures : `packaged-native-verified/`.
- `verification.json` consigne le lancement de l'export Linux, les entrées X11 horodatées, leurs sorties 0, la sortie finale du processus 0 et le source HEAD `c105da61b2b490546f01c9d67703bfb405a2a44f`.
- Le SHA-256 du fichier `builds/linux/SILO9.x86_64`, recalculé en lecture seule dans le worktree, correspond au manifeste : `7fe6e6f1299e1747323e52fbae4e2a18329b2aca1761a00f787e1a20012ebb71`. `file` identifie un ELF Linux x86-64. Le lien au source HEAD est celui consigné par le manifeste ; je n'ai pas refait l'export.
- `engine.log` contient Godot 4.7.2, OpenGL Compatibility et Mesa llvmpipe. Un avertissement indique que le pilote ne permet pas de régler V-Sync. Aucune autre erreur n'y apparaît. L'audio utilise le pilote Dummy.

## Liste exacte des PNG ouverts et observations

Tous les noms ci-dessous sont relatifs à `packaged-native-verified/`.

| PNG réellement ouvert | Observation visuelle et entrée correspondante |
| --- | --- |
| `menu.png` | Menu SILO 9, Nouvelle descente sélectionnée, Continuer désactivé. Le clic enregistré en 300,360 tombe dans Nouvelle descente. |
| `flashlight-off.png` | Jeu dans Décontamination, vue orientée vers Maintenance, sans mention LAMPE ON. Composition cohérente avec le démarrage et l'entrée W enregistrée. Vie 100, énergie 100, munitions 12/48. |
| `flashlight-on.png` | Après F, mention LAMPE ON et faisceau visible au sol et sur les panneaux, avec cadrage stable. |
| `scan.png` | Après Q, marqueurs cyan, repère orange du robot et message SCAN ÉCHO : signatures révélées. Énergie passée à 80, lampe toujours allumée. |
| `saved.png` | Après F5, message Progression sauvegardée. Vie 100, énergie 80, munitions 12/48 ; marqueurs du scan encore présents. |
| `loaded.png` | Après F9, message Progression restaurée, même cadrage du couloir et mêmes valeurs du HUD. Les marqueurs du scan ont disparu ; lampe éteinte. |
| `loaded-lamp-on.png` | Le F suivant rétablit LAMPE ON et le faisceau, après le chargement. |
| `pause-lamp-on.png` | Après Échap, menu Signal suspendu. Reprendre, Sauvegarder, Charger, Réglages et Menu principal sont lisibles et accessibles visuellement. |
| `resumed-lamp-on.png` | Après le second Échap, le menu disparaît. Jeu visible, LAMPE ON et faisceau conservés, énergie 80. |
| `flashlight-off-again.png` | Le F suivant retire LAMPE ON et le faisceau au sol. Cadrage et valeurs du HUD conservés. |
| `pause.png` | Nouvelle pression Échap, menu pause lisible. Le clic enregistré en 300,418 correspond à Menu principal. |
| `menu-return.png` | Retour au menu principal. Continuer la sauvegarde est actif et Reprendre la session apparaît. Quitter reste visible malgré la barre de défilement. Le clic final en 300,590 correspond à Quitter. |

Les actions enregistrées et les résultats visibles se correspondent. La différence de scène entre le menu initial et la première vue en jeu est cohérente avec le déplacement annoncé. Les captures n'isolent pas une vue en jeu avant W, donc elles ne mesurent ni la distance parcourue ni la continuité du mouvement.

## Défauts et limites

Aucun défaut concret de cadrage, de lisibilité des actions ou de correspondance entrée/résultat ne bloque ce parcours. La barre de défilement du menu après retour accompagne l'ajout de Reprendre la session ; les actions restent visibles. Elle ne suffit pas à établir un bug.

F5/F9 montre les confirmations, la conservation du cadrage et des valeurs affichées, et la disparition des marqueurs de scan. Cela ne prouve pas à lui seul le contenu intégral de la sauvegarde, les nouvelles identités Player/World, les migrations, ni l'absence de tous les effets transitoires. L'extinction de la lampe au chargement est observée ; sa réactivation par F fonctionne dans cette séquence.

La pause est visible et la reprise rend le jeu affiché de nouveau. Des images fixes ne démontrent pas que toute simulation était suspendue entre les deux. La sortie propre repose sur le code 0 du processus dans le manifeste, pas sur une capture après fermeture.

Le manifeste ne relie pas chaque PNG à un événement par identifiant ou empreinte d'image. La correspondance repose ici sur les noms, l'ordre des entrées et les changements visibles. Aucun nouveau contrôle du runtime n'a été effectué.

Cette revue ne valide aucun combat, caisse détruite, carcasse persistante, verrou ARC restauré, mission complète ou fin dans le binaire. Elle ne valide ni Windows, ni audio réel, ni rendu GPU cible, ni FPS ou latence. Aucun résultat de performance n'est déduit de llvmpipe ou des horodatages des entrées.

Libération : seul `issue18/package-visual-review.md` écrit. Aucun descendant, processus de jeu, capture, modification gameplay ou mutation Git. Le parent conserve l'exclusivité du runtime.
