# Prépublication initiale — ticket 8

**Outil : lecture favorable sous son contrat d'exécution. Publication finale : verdict en attente.** Le fichier public et le document final n'existent pas encore ; ce rapport ne leur attribue pas un PASS anticipé.

Périmètre : sonde `visual-proof/probe_materials_film.gd`, protocole historique, brouillon de rapport, manifestes finaux et revue artistique. Indépendance sur cet outil et ces textes, dont je ne suis pas l'auteur. Aucun moteur, ffmpeg, générateur, commit, édition de production ni descendant ; seulement lecture et présent rapport. Aucun calcul lourd pendant les mesures du parent. Accès relâchés. Cette mission ne compte pas comme revue indépendante des tests que j'ai écrits.

## Corrections factuelles pour la documentation publique

1. **Contrat 30 fps — protocole historique ligne 19.** « La sonde exige ces arguments » est devenu inexact après la correction de garde. Le code valide le chemin MovieWriter actif via `Engine.get_write_movie_path()`, mais n'impose pas `--fixed-fps 30`. L'overlay et `limits` déclarent 30 fps comme précondition du parcours. Documenter explicitement que l'opérateur doit fournir cette cadence et la vérifier dans le fichier produit ; ne pas affirmer que la sonde rejette une autre cadence. Le film livré respecte bien cette précondition : argv avec `--fixed-fps 30`, ffprobe enregistré `30/1`, 1 236 images, 41,2 s. Le brouillon ligne 25 distingue déjà correctement la vérification externe.
2. **Lampe z5 / z8 — protocole historique ligne 30 et reproduction du brouillon ligne 36.** Le futur outil public (`44ad5e…`) place sa lampe en `(1001.2, 2.5, 8)`, pour ses deux modes. Les 17 PNG de l'inspection finale ont été produits par l'autre sonde (`0bbd18…`) avec z5. Le film final emploie z8. La commande publique du brouillon ne reproduira donc pas exactement la lumière des PNG fixes archivés. Nommer les deux variantes et le choix z8 du nouvel outil public, ou fournir un moyen explicite de reproduire l'ancienne variante. Aucune modification des images ni des manifestes historiques n'est requise.

Le protocole historique est un document de livraison initiale ; sa ligne 7 précise encore que le rendu reste à exécuter. Ce statut ne doit pas être recopié comme état final dans la documentation publique. Le conserver comme preuve datée est cohérent.

## Compléments avant publication

Le brouillon porte encore `PERFORMANCE_PENDING` et aucun lien vers un artefact de performance final : attendu pendant cette revue, à résoudre avant le verdict final. Pour la reproduction publique, reprendre les deux précautions déjà présentes au protocole : un `XDG_DATA_HOME` neuf par parcours et un timeout externe. Ajouter la commande film avec MovieWriter, `--fixed-fps 30` et une vérification ffprobe rendra la preuve vidéo directement reproductible. Ce sont des compléments de publication ; aucune nouvelle exécution n'a été faite ici.

## Lecture de l'outil

Le script charge la vraie scène et les constructeurs. Les changements de fixture sont déclarés : sol/lumière de laboratoire, environnement copié, callbacks ennemis arrêtés, valeurs de ressources de départ et commandes logicielles. Les matériaux et meshes FPS ne sont pas remplacés. Les modes, renderer, boucle de rendu et MovieWriter sont vérifiés avant le parcours ; l'avancement des rendus est contrôlé et le watchdog couvre leur arrêt après initialisation. Un timeout externe reste nécessaire avant cette installation.

Les observations utilisent les valeurs réelles de caméra, position, état, inventaire et manipulations. R/B appelle Player, les transferts finaux sont vérifiés et les six segments enregistrent 1 080 observations. Les captures ont un nom et un overlay communs avant le rendu. Les images et propriétés des matériaux sont inventoriées hors de la boucle de chaque image. Les compteurs mémoire sont explicitement distingués du budget texel RGBA8. Les instance IDs ne doivent être comparés que dans un processus, comme le dit le protocole.

La sonde n'est pas un lecteur autonome de sa propre preuve : le hash source, le contenu de vidéo, sa cadence, les états avant/après et l'appréciation visuelle relèvent des vérifications externes déclarées. Je n'ai pas trouvé de défaut concret bloquant dans ce périmètre sous l'invocation prescrite.

## Concordance des preuves lues

- Deux manifestes sur `efc2a581fd329321a852507d775af6fcda0a9cb1`, avant/après, sortie enregistrée 0 et sources/outils inchangés.
- `materials.json` : inspection 17 captures ; film 13 captures, 6 segments, 1 080 observations ; aucune failure, quatre textures finales.
- Les trois segments D9 finissent 12/44 depuis 8/48 ; les trois ARC finissent 100/1 depuis 40/2 ; tous acceptés et ADS final 1.
- Commande MovieWriter à 30 fps, ffprobe enregistré 1280×720, 30/1, 1 236 images, 41,2 s. Les logs de conversion, décodage intégral et ffprobe ont été lus et vérifiés par SHA-256 ; aucun de ces programmes n'a été relancé.
- Le brouillon rapporte fidèlement les limites de la revue artistique : six fenêtres de douze images, 13 captures film et 17 captures fixes ; pas de visionnage continu ni de garantie contre le scintillement subtil. Cette lecture de son rapport n'est pas une seconde inspection des pixels. Les citations d'observation restent attribuées à l'art reviewer.

## No-comments

Le commentaire de tête borne la portée de la sonde au vrai rig sans override ; il est exact malgré la géométrie de laboratoire ajoutée à côté. Aucun commentaire mort, suppression de contrôle ou revendication non prouvée cachée dans le code. Zéro suppression proposée/appliquée, zéro restauration, zéro correctif, aucun encodage à demander. Les réserves 30 fps concernent les chaînes d'overlay et le contrat documentaire, pas un commentaire à supprimer.

## Empreintes lues

| Fichier | SHA-256 |
|---|---|
| `visual-proof/probe_materials_film.gd` | `44ad5e220bfb29672a6e8e3a7683278316c62a1d3ed85758e0a71b708d4b9570` |
| `visual-proof/protocol.md` | `e43288fd988e58982d1a41fe6604f799e1de7e12b1eed5114b35c0ca46495e05` |
| `report-draft.md` | `5e656268e2f3c54002767022da4044923ba9d069af1a658840fa2702b12e0914` |
| `art-review-final.md` | `662a2eb530ea4c0debd9be27dec96759d7e88896a1060b67cf6d937e0048c66c` |
| `render-final/inspection/manifest.json` | `28e1e0b3e05f8f49a3175651a16cc15da4604008a7adb3b30821868a2d0fbdee` |
| `render-final/film-final/manifest.json` | `bfd2208d3b54603e0d04beff222dc997d3b424c8be994767da3700fa8f5eed58` |
| `render-final/film-final/media-manifest.json` | `1bb565702d18c5a4acac5027ecfc56c9d6f2d2d53d6468c049358e8d7e2bc01a` |

Verdict final à rendre uniquement après le HEAD et les chemins publics définitifs, avec liens, hashes et section performance effectivement présents.
