# Ticket 09 — revue visuelle finale Normal

Verdict : **PASS borné aux poses Normal examinées**, avec des limites de finition explicites. Le défaut P2 de cadrage est corrigé. La lampe révèle les équipements proches et produit une ombre visible derrière le levier du disjoncteur. Les secteurs coupés restent orientables. Le rendu sans lampe est toutefois plus sombre et moins modelé que la baseline ; ce ticket ne constitue pas une amélioration uniforme de tous les pixels, ni une qualité Fortnite atteinte.

Revue indépendante de production, effectuée par ouverture réelle avec `view_image` de **22 PNG finales, 14 PNG baseline et une PNG historique de la preview**, soit **37 images distinctes**. Toutes les images finales/baseline examinées sont en 1280×720. Aucun Godot, ffmpeg, parcours, benchmark, descendant ou modification de source lancé. Seul ce rapport est écrit.

Skills appliqués : cstack, contrat cstack-agent, prove-it-works, unslop. Playbook Investigation limité à la tranche visuelle. Throughput checkpoint: n/a, read-only investigation. Le principe prove-it-works a conduit à comparer les pixels et à sélectionner le minimum du néon depuis les observations réelles, sans déduire son effet visible de son énergie seule.

- [x] Lire la conception retenue, la preview et le rapport de correction du cadrage.
- [x] Vérifier provenance, poses, qualité et résultats des deux séries.
- [x] Comparer cinq zones, secteurs coupés, trois équipements critiques, cœur, alarmes et néon.
- [x] Recontrôler le P2 et publier le périmètre exact de la revue.

## Provenance et méthode

Candidate : `653e2a79c7f36e9ac7422335c85cef3b937ed0f9`, branche `feat/issue-09-lighting`, worktree `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-09`. Baseline : `e5b0bafa7b8bad369e6767a908b1d8391343b9f2`.

J'ai lu les champs utiles des [manifest candidate](render-final-normal/manifest.json), [journey candidate](render-final-normal/journey.json), [manifest baseline](render-baseline/manifest.json) et [journey baseline](render-baseline/journey.json). Les deux manifests déclarent exit0, source inchangée et aucune erreur de validation. Les journeys portent `low_quality=false` et aucune failure. Une comparaison directe des données retrouve les mêmes positions caméra, rotations et FOV pour les **44 labels appariés**. Ce contrôle valide l'appariement des poses ; il ne constitue pas une nouvelle exécution indépendante du moteur.

La baseline n'a pas de lampe : `flashlight=null`. Ses fichiers nommés `flash_on` ne prouvent donc aucun éclairage de lampe. Les comparaisons de lampe ci-dessous utilisent les états OFF/ON de la candidate et la baseline OFF à pose identique. Aucun fichier baseline `flash_on` n'est compté comme examiné.

La [conception](design/accepted.md) et le [rapport de cadrage](lamp-framing/report.md) expliquent l'intention. Leurs affirmations n'ont pas remplacé les observations visuelles. Les poses contiennent des robots vivants figés selon le dispositif de capture ; ces PNG ne prouvent pas leur visibilité en mouvement ni leur comportement.

## Comparaisons

Dans ce tableau, les noms désignent les PNG de même nom dans `render-baseline` et `render-final-normal`, sauf mention contraire.

| Paire examinée | Résultat visible et limite |
|---|---|
| `refuge_power_on_flash_off` | Le passage, le titre Décontamination, la borne énergie et MÈRE restent identifiables. Les montants blancs et la borne MÈRE perdent une partie de leur éclairage par rapport à la baseline. Les traits centraux deviennent pâles/cyan et restent continus jusqu'à la sortie. La candidate conserve une hiérarchie lisible malgré la baisse de relief latéral. |
| `decontamination_power_on_flash_off` | La grande nappe bleue brillante du sol de la baseline disparaît. Le sol, la flèche et les lignes du passage restent visibles, mais les faces proches sont plus uniformes. Le diffuseur passe d'orange à froid, cohérent avec cette zone. Le HUD masque encore une partie du plafonnier dans les deux poses ; cette vue ne permet pas d'inspecter tout son montage. |
| `maintenance_power_on_flash_off` | Le plafonnier devient crème, avec un centre plus clair dans son boîtier. La forte lumière rouge latérale de la baseline disparaît ; le rampant et les objets de l'établi sont moins contrastés, mais encore discernables. Le disjoncteur ON et la sortie Archives restent lisibles. Aucun gain global de détail n'est revendiqué sans lampe. |
| `archives_power_on_flash_off` | Le plafonnier bleu froid se distingue de Maintenance. Sentinelle, N-7 et sol sont plus sombres que dans la baseline ; leurs silhouettes restent séparées du décor dans cette pose. La porte rouge du cœur garde sa priorité visuelle. Les pieds du robot restent le point le moins contrasté. |
| `core_power_on_flash_off` | Le réacteur cyan, les quatre colonnes et les bandes rouges organisent la pièce. Le robot central et le rampant gauche restent reconnaissables, mais les avant-plans et le torse du robot ont moins de modelé que dans la baseline. Le centre du plafond et le socle du réacteur portent des accents cohérents avec les sources visibles. |
| `maintenance_power_off_flash_off` | Le diffuseur est sombre dans les deux versions. Le passage central est plus facile à suivre grâce aux bandes pâles. Le rampant reste sombre à gauche ; il n'est pas confondu avec un passage, mais cette pose ne garantit pas sa détection rapide. Le socle orange du disjoncteur est de nouveau dégagé. |
| `archives_power_off_flash_off` | Plafonnier éteint, texte OFF et destination du cœur lisibles. Les bandes centrales restent visibles. La silhouette de la sentinelle se détache faiblement, N-7 reste reconnaissable à gauche. Pas de trou noir rendant la direction ambiguë dans cette pose. |
| `critical_breaker_maintenance_flash_off`, puis candidate `flash_on` | OFF, le texte et le levier restent repérables. ON, le faisceau circulaire révèle le fond et les montants ; une ombre sombre du levier apparaît à gauche sur le fond, cohérente avec une source à droite de la caméra. La face du levier est très claire, mais son contour reste lisible. Cette paire prouve une ombre rendue à cette pose, pas sa stabilité lors d'un mouvement. |
| `critical_evidence_flash_off`, puis candidate `flash_on` | L'écran cyan est repérable sans lampe dans les deux versions. La lampe révèle les faces latérales de la borne, la table, les grilles et les joints du sol. Le texte derrière la borne est déjà partiellement occulté dans la baseline ; aucune régression nouvelle de texte attribuée au ticket09. |
| `critical_relay_flash_off`, puis candidate `flash_on` | La lampe donne du volume au cylindre, au terminal incliné, au mur et à la table. Le texte cyan croisant le panneau d'objectif existe déjà dans la baseline. Il reste un défaut de présentation préexistant, pas un défaut causé par la lampe. |
| Candidate `core_power_on_flash_on` / `core_power_on_flash_off` | Les faces de la sentinelle, ses articulations, le rampant et le socle deviennent plus clairs. Le faisceau apporte un bénéfice visible sans blanchir toute la pièce ; les colonnes latérales restent sombres. |
| Candidate `maintenance_power_off_flash_on` et `archives_power_off_flash_on`, comparées à leurs OFF | Le faisceau éclaire surtout le passage central et le montant proche à droite. Il ne révèle pas automatiquement le rampant hors axe ; cette limitation directionnelle est visible. Le robot des Archives gagne un peu de relief. Les surfaces orange proches sont lumineuses mais conservent leurs contours. |
| `alarm_active` / `alarm_expired`, deux versions | La baseline montre essentiellement une lentille jaune active. La candidate montre une lentille rouge/orange et une illumination locale réelle du haut du disjoncteur, du levier et du sol droit. Dans la capture expirée, la lentille et cette nappe rouge ont disparu. Le principal reste éteint. Deux poses ne prouvent ni la durée, ni l'enveloppe temporelle, ni l'extinction au premier frame. |

## Correction du cadrage

J'ai rouvert la [preview Maintenance OFF](render-first/maintenance_power_off_flash_off.png), puis comparé la [finale](render-final-normal/maintenance_power_off_flash_off.png) et la [baseline](render-baseline/maintenance_power_off_flash_off.png). Le grand volume bleu de la preview qui occupait le bas droit est absent de la finale. Le pied orange du disjoncteur et le sol sont à nouveau visibles, avec une arme et des mains de même cadrage apparent. Un petit cylindre sombre demeure près de la main droite, sans atteindre le réticule ni masquer le texte du HUD. **P2 résolu visuellement dans la pose de reproduction.** Les autres vues critiques finales ne montrent pas le retour de cette obstruction.

Le rapport de correction indique un déplacement du boîtier et de la source, sans changement de dimensions ni de FOV. Je ne certifie pas ce diff de production depuis la revue d'images ; je certifie le résultat visible décrit ci-dessus.

## Néon et mode réduit

Les extrema enregistrés dans les treize observations `neon_*` sont **1,5** pour `ceiling_maintenance` (notamment `neon_00`) et **1,1411** pour `neon_06`. J'ai ouvert ces deux images candidates et leurs deux homologues baseline.

La candidate `neon_06` est légèrement moins claire sur le diffuseur et les surfaces environnantes que `neon_00`. La différence demeure discrète à l'échelle de l'image entière ; elle ne suffit pas à qualifier visuellement ce luminaire de franchement défaillant. Je ne transforme pas la baisse numérique d'énergie en preuve de clignotement convaincant. Les deux homologues baseline montrent le plafonnier orange et l'éclairage latéral plus fort, sans variation flagrante entre eux.

Les candidates `reduced_00` et `reduced_02` paraissent stables et proches de l'état haut ; les observations donnent 1,5 dans les trois échantillons réduits. Cela concorde avec l'intention de stabilisation mais ne prouve pas le confort temporel, l'absence de scintillement en continu ou l'accessibilité du cycle animé. Ces points restent hors du verdict PNG.

## Cohérence, HUD et limites

Les zones froides Décontamination/Archives et le plafonnier chaud de Maintenance se distinguent mieux par leurs diffuseurs. Les accents rouges actifs sont localisés autour de l'alarme visible. Je ne vois pas de grande nappe lumineuse inexplicable éloignée de son équipement dans les vues examinées. Le rayon de lampe et l'ombre du levier sont compatibles avec une origine proche du côté droit de la caméra. Les chiffres de position et l'alignement exact source/diffuseur restent du ressort de la revue de code et des tests.

Le HUD VIE/ÉNERGIE, les munitions, l'aide F/R3 et la mention LAMPE ON sont lisibles. Les captures ON affichent une énergie joueur à zéro avec un éclairage visible ; ce constat ne remplace pas le test des commandes ou de consommation. Aucun nouvel artefact de face manquante, de transparence ou de clipping du réticule n'apparaît dans cet échantillon.

Le décor conserve de grandes faces simples et les ennemis ont peu de contraste hors faisceau. La lecture des matières et du relief reste loin de la finition Fortnite demandée à long terme. Le PASS valide la correction de cadrage, la cohérence et l'utilité de l'éclairage dans les poses testées ; il ne valide ni la qualité artistique finale du jeu entier, ni Low, ni Windows, ni un GPU joueur, ni une performance, ni un parcours ou film continu.

## Inventaire exact des images ouvertes

**22 finales**, toutes sous `render-final-normal/` :

1. `refuge_power_on_flash_off.png`
2. `decontamination_power_on_flash_off.png`
3. `maintenance_power_on_flash_off.png`
4. `archives_power_on_flash_off.png`
5. `core_power_on_flash_off.png`
6. `maintenance_power_off_flash_off.png`
7. `archives_power_off_flash_off.png`
8. `critical_breaker_maintenance_flash_off.png`
9. `critical_evidence_flash_off.png`
10. `critical_relay_flash_off.png`
11. `critical_breaker_maintenance_flash_on.png`
12. `critical_evidence_flash_on.png`
13. `critical_relay_flash_on.png`
14. `core_power_on_flash_on.png`
15. `alarm_active.png`
16. `alarm_expired.png`
17. `maintenance_power_off_flash_on.png`
18. `archives_power_off_flash_on.png`
19. `neon_00.png`
20. `neon_06.png`
21. `reduced_00.png`
22. `reduced_02.png`

**14 baseline**, sous `render-baseline/` : mêmes noms que les entrées finales 1 à 10, 15, 16, 19 et 20.

**Une historique** : `render-first/maintenance_power_off_flash_off.png`, utilisée uniquement pour recontrôler le P2.

Aucun worktree créé ou détenu en écriture. Tous les fichiers consultés sont relâchés. Aucun processus ou descendant de cette tranche ne demeure actif. Seul chemin modifié : `.cstack/orchestrate/silo9/issue09/art-normal.md`.
