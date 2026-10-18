# Preuves finales matériaux — ticket8

Source exécutée : `efc2a581fd329321a852507d775af6fcda0a9cb1`, worktree `.worktrees/silo9-issue-08`, branche `feat/issue-08-materials`. Lecture seule du projet, aucun commit ni descendant. Runtime et fichiers relâchés ; aucun Godot, ffmpeg ou tesseract lancé par cette tâche ne subsiste.

## Résultat mécanique

- Inspection originale Z5 : **exit0,17 PNG,0échec**, code/tests/assets/outils/binaire inchangés avant/après. Matrice12 vues, refuge2 Normal et2 Low, plus warmup. Santé100, FOVhip76/ADS64,0131 ; Low enregistré0,67.
- Film frontal Z8 : **exit0,6segments,1080observations,13PNG,0échec**. Même source figée, seuls l’éclairage déclaré et la garde MovieMaker diffèrent de la sonde originale. Chaque segment mesure environ1,333m de déplacement,30° yaw et10° pitch ; valeurs finies et frames strictement croissantes.
- Trois R acceptés et transferts8/48→12/44 ; trois B acceptés et transferts40/2→100/1. L’initialisation des ressources est explicitement faite par le fixture. ADS termine à1 après chaque manipulation.
- MP4 :1280×720,30/1fps,1236images,41,2s,3820263octets. Conversion, décodage complet et ffprobe exit0 ; aucun message d’erreur dans leurs logs. Le film à30fps fixes **n’est pas une mesure de performance**.

Le relevé brut du rig compte11matériaux :9ressources de finition nommées et2matériaux anonymes existants sous Muzzle. Quatre textures FPS128²,L8,mipmaps7 niveaux supplémentaires ;21845octets de données chacune. Estimation conservatrice RGBA8 mipmaps complètes349520octets (0,333MiB). Identités et propriétés matériaux/textures identiques avant/après les parcours. Les compteurs mémoire moteur concernent tout le viewport ; ils ne donnent pas la VRAM des seuls matériaux FPS.

## Séquences pour revue artistique

Les72PNG bruts sont répartis en six fenêtres de12images consécutives. Les overlays des72images ont été lus par OCR et vérifiés contre les labels de la télémétrie. Le mapping observé est **index vidéo zéro-based n = Engine.frames_drawn**. Le premier extracteur utilisait sample.frame−1 ; les fenêtres conservées commencent donc un tick avant celui demandé initialement. Aucun renommage trompeur ni retouche des PNG ; les vrais index sont dans les noms et le tableau.

| Fenêtre | Index vidéo n inclusifs | Overlays observés |
|---|---:|---|
| d9-reload | 79–90 | `film-w0-cold-frame-039` → `film-w0-cold-frame-050` |
| arc-cell | 701–712 | `film-w1-cold-frame-049` → `film-w1-cold-frame-060` |
| arc-camera | 1193–1204 | `film-w1-dim-frame-139` → `film-w1-dim-frame-150` |
| d9-red | 280–291 | `film-w0-red-frame-039` → `film-w0-red-frame-050` |
| d9-dim | 581–592 | `film-w0-dim-frame-139` → `film-w0-dim-frame-150` |
| arc-red | 902–913 | `film-w1-red-frame-049` → `film-w1-red-frame-060` |

Chaque répertoire de fenêtre se trouve sous `film-final/`. Ces fenêtres couvrent les deux armes et les trois lumières, avec R/B et caméra/ADS. Elles doivent encore recevoir un verdict artistique indépendant. Mon inspection visuelle directe s’est limitée au warmup et à `d9-reload/movie-000079.png` ; les72contrôles OCR vérifient des labels, pas les matériaux. Aucun visionnage continu ni écoute du film n’est revendiqué. Le décodage intégral ne remplace pas cette inspection.

## Échec conservé et correction bornée

`film/` contient la tentative initiale réelle : MovieMaker actif mais garde fondée sur `OS.get_cmdline_args()` rejetant à tort des arguments consommés par le moteur. Exit1,0capture,1frame vidéo ; cette tentative n’est pas utilisée comme preuve artistique.

Le parent a reproduit le rouge puis fait corriger par un acteur distinct une nouvelle copie `probe_materials_film.gd`. Sa garde utilise `Engine.get_write_movie_path()` ; son négatif sans MovieMaker est conservé ailleurs par le parent. L’API est attestée dans `issue06/api/Engine.xml:203` et `parent-api-manifest.json`, URL Godot4.7.2-stable, SHA256`8a4205ff0f3d4a6d3ba10c94c10472418d1e1abe3c0a6aa44b7106cb1f0f1936` vérifié. La garde prouve MovieMaker ; le30fps effectif est confirmé séparément par la commande et ffprobe.

Sonde inspection : SHA256`0bbd18e20811ed92723f7c7101abd48698c1b93928c61b723617a037626af319`.
Sonde film final : SHA256`44ad5e220bfb29672a6e8e3a7683278316c62a1d3ed85758e0a71b708d4b9570`.

Les anciens runners ont été archivés sous inspection/ et film/ avant adaptation du lanceur. Les commandes exactes,timeout360s,userdata isolés,logs,codes et SHA avant/après sont dans chaque manifest. `media-manifest.json` contient conversion/décodage/extractions et empreintes ; `overlay-checks.json` contient les72correspondances. L’AVI reste local. Le parent choisit les fichiers publics.

Aucune preuve d’entrée native, Windows, manette physique, GPU joueur ou parité Fortnite ; aucune mesure de performance tirée du film. Aucun fichier de production ou test modifié.
