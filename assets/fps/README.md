# Matériaux FPS de SILO 9

Les neuf ressources `materials/*.tres` sont créées pour SILO 9. Les quatre images sous `textures/` sont originales, dessinées par des fonctions périodiques dans `tools/generate_fps_materials.py`. Aucun asset tiers ni contenu Fortnite n’entre dans cet ensemble. Le dépôt ne déclare pas de licence générale ; cette provenance ne lui attribue pas une licence CC0 ou MIT.

Reproduction depuis la racine du projet :

```sh
python3 tools/generate_fps_materials.py
```

Le générateur utilise uniquement la bibliothèque standard Python. Il produit des PNG gris 8 bits de 128×128 et `textures.json`, qui consigne leurs empreintes SHA-256. Aucun travail de génération ne se fait pendant le jeu. Les paramètres et motifs sont dans le générateur : quadrillage diagonal du gant, tissage du tissu. Les cartes restent neutres pour que la couleur soit éditable dans les ressources.

Gant et tissu ont chacun une paire albédo/rugosité. Peinture D9 et ARC, acier, isolant et contacts utilisent des valeurs scalaires. La paire de cartes peinture a été écartée après comparaison à cadrage égal : son léger marbrage ne justifiait pas deux images supplémentaires. Les signaux conservent leur émission 0,8 ; les autres matériaux ne sont pas émissifs. Les ressources préchargées sont partagées entre toutes les instances et ne changent pas pendant les animations.

Les UV des pièces manuelles sont projetés à partir de leur normale finale, à huit répétitions par unité locale. Les cylindres conservent les UV Godot. Les lofts ont une couture angulaire doublée U=0/1 et V suivant la longueur cumulée au repos, à huit répétitions par unité. Leurs caps utilisent une projection plane. Les UV suivent donc les vertices animés ; aucune projection par frame ni normal map n’est nécessaire.

Quatre cartes 128×128 avec chaîne mipmap complète représentent au plus **349 520 octets de texels RGBA8**. Ce plafond volontairement conservateur n’est ni la taille des PNG ni une mesure de VRAM. Les paramètres d’import activent les mipmaps et le filtrage linéaire avec mipmaps. Il n’y a pas de variante Low supplémentaire : les mêmes petites cartes servent aux deux qualités.
