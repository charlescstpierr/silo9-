# Verdict visuel final — ticket 8

**FAVORABLE sur les preuves visuelles inspectées.** Conserver le look A, les cartes gant/tissu et les peintures sans cartes. Aucun correctif artistique bloquant identifié sur ces images. Ce verdict porte sur les matériaux et leur lisibilité, pas sur la validation technique globale, les performances ou une parité Fortnite.

Révision bornée : `efc2a581fd329321a852507d775af6fcda0a9cb1`, branche `feat/issue-08-materials`, worktree `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-08`. Les manifestes de `render-final/inspection` et `render-final/film-final` déclarent ce même HEAD avant/après, sources/outils inchangés et sortie 0. Leurs `materials.json` déclarent respectivement 17 et 13 captures, aucune erreur et quatre textures FPS. Environnement rendu : OpenGL3/llvmpipe Linux. Je n'ai lancé aucun moteur, test ou benchmark.

Vidéo examinée par images extraites : `render-final/film-final/materials.mp4`. SHA-256 recalculé sur le fichier : `8019a953652f6bae3d53ad532ed77c9f2617a4eb0a9b2a6e754646969afd743f`. Le manifeste média annonce 1236 images, 41,2 secondes, 30 images/s ; je n'ai pas exécuté de décodage vidéo. Les SHA-256 des 72 PNG extraits concordent avec ce manifeste. Les 30 captures PNG directes concordent également avec leurs manifestes de capture.

## Pixels effectivement inspectés

Les six fenêtres ont été lues dans l'ordre, image par image sur 18 planches contenant quatre recadrages natifs chacune. Elles couvrent 72 images consécutives au total, soit six fenêtres de 0,4 seconde. Aucune interpolation, correction de couleur ou retouche ; uniquement recadrage et légendes extérieures. `art-review/manifest.json` consigne chaque source, son empreinte et le rectangle. L'ordre de lecture est gauche→droite puis haut→bas.

| Fenêtre | Indices film inclus | Overlays de segment inclus | Observation |
|---|---|---|---|
| `d9-reload` | 79–90 | froid D9 039–050 | Retrait/descente du chargeur, gant gauche et poignet droit visibles |
| `d9-red` | 280–291 | rouge D9 039–050 | Même phase de recharge sous lumière rouge |
| `d9-dim` | 581–592 | faible D9 139–150 | Rotation lente en ADS, mires et deux gants |
| `arc-cell` | 701–712 | froid ARC 049–060 | Retrait de cellule, rotation de la main gauche, manche proche caméra |
| `arc-red` | 902–913 | rouge ARC 049–060 | Retrait de cellule sous lumière rouge |
| `arc-camera` | 1193–1204 | faible ARC 139–150 | Rotation lente en ADS, signal cyan et mires |

Les indices et overlays suivent `media-manifest.json` et `overlay-checks.json` : l'indice film zéro-based correspond à `Engine.frames_drawn`. L'extraction commence un tick avant la demande initiale ; les plages ci-dessus utilisent les indices réellement extraits. Je n'ai pas refait l'OCR. Les overlays ont aussi été lus sur les originaux critiques ouverts.

J'ai également inspecté les 12 captures directes `film-w{0,1}-{cold,red,dim}-{start,end}.png` sur deux planches, plus le warmup original ; puis les 16 captures utiles de `render-final/inspection` sur deux planches et son warmup original. L'inspection fixe comprend les deux armes, froid/rouge/faible en hip/ADS, et le refuge SILO réel Normal/Low.

Huit originaux finaux 1280×720 ouverts directement :

- Film : `d9-reload/movie-000079.png`, `arc-cell/movie-000701.png`, `arc-cell/movie-000706.png`, `arc-camera/movie-001204.png`, `film-w0-red-end.png`, `renderer-warmup.png`.
- Inspection : `silo-w1-low-hip.png`, `renderer-warmup.png`.

Les 64 comparaisons initiales base/A/B/A sans cartes et les 48 comparaisons frontales base/A/A sans peinture sont documentées dans `art-review/report.md`. Elles ont été réellement inspectées dans cette même mission ; elles ne sont pas assimilées aux images finales de ce HEAD.

## Résultat

**Le gain par rapport à la base est réel et surtout porté par la séparation des matières.** Les anciens gants beiges pouvaient se lire comme des mains nues ; les gants graphite et leur matelassage évoquent désormais une protection. Les manches ont une modulation textile douce, particulièrement visible lorsque le bras gauche s'approche de la caméra pendant le changement de cellule. La peau évoquée dans le premier avis est une impression de l'ancien matériau, pas l'affirmation d'un modèle de peau distinct.

Le D9 turquoise et l'ARC ocre conservent des aplats propres, distincts des structures métalliques sombres et des isolants. Le contraste ocre/noir/cyan aide l'ARC à ressortir du décor bleu du refuge. Les biseaux métalliques réagissent davantage à la lumière que les peintures ; les tissus restent mats. Le témoin sans peinture a démontré que le marbrage retiré n'améliorait pas cette lecture. La version finale conserve les bénéfices des cartes gant/tissu sans le marbrage des armes.

**Aucune couture de texture flagrante ni changement brutal de motif ou de teinte repéré entre les images adjacentes des six fenêtres.** Le quadrillage des gants accompagne les rotations visibles de la main ; la modulation de manche reste attachée au bras. Les aplats des armes restent stables pendant les gestes. Les traits sombres entre certaines parties des mains restent visibles, mais existaient déjà dans la base fixe ; aucune régression de mapping n'est établie à cet endroit.

**Les signaux et mires restent lisibles.** Le cyan ARC conserve son encadrement sombre, y compris en lumière rouge et en ADS faible. Les petits repères de mire restent visibles ; aucun motif de tissu ou de gant ne les recouvre. Les états de départ/fin montrent aussi la barre d'énergie ARC courte puis remplie. Cette observation des pixels ne vaut pas validation des règles de gameplay ou de l'alignement géométrique ADS.

Dans le refuge Low, la réduction de définition épaissit les marches d'escalier comme sur la base, mais les familles de matériaux et le signal restent reconnaissables. Le quadrillage des gants ne produit pas de grille envahissante sur les captures examinées. Je ne recommande pas d'ajouter du détail ou d'augmenter le contraste des motifs.

## Limites et clôture de cette revue

Il s'agit d'une inspection de séquences d'images et de captures fixes, **pas d'un visionnage continu des 41,2 secondes**, ni d'une écoute. Les fenêtres de 0,4 seconde permettent de repérer des sauts grossiers ; elles ne prouvent pas l'absence de scintillement subtil sur le film entier. La compression MP4 peut également atténuer les détails fins. Les poses du film offrent des vues obliques pendant R/B, mais ne couvrent pas tous les angles rasants possibles.

Le film utilise le laboratoire isolé avec lampe frontale z8 ; l'inspection fixe finale utilise le laboratoire original z5 et le refuge réel. Le mode faible conserve la lumière FPS. Les gestes passent par les API de production selon le protocole ; caméra pilotée et entrées logicielles ne constituent pas une preuve de souris/manette physique. Le film à cadence fixée n'est pas un benchmark. Aucune conclusion sur 60 FPS, GPU joueur, Windows ou parité Fortnite.

Acteur distinct du constructeur, modèle hérité ; aucune diversité de modèles revendiquée. Fichiers produits uniquement : présent rapport et fichiers de revue sous `issue08/art-review/`. Aucun fichier source modifié, aucun commit, worktree ou descendant créé ; aucun processus laissé actif. Le worktree de production appartient au parent et n'a pas été supprimé ni libéré par cette revue.
