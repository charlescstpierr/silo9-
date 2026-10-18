# Correction de cadrage de la lampe — terminée

Worktree : `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-09`. Branche `feat/issue-09-lighting`, HEAD `e691f5fcea4824a379f362e85e69baa325a0b0bb` inchangé. Aucun commit, push, PR ni descendant. Runtime :100 libéré ; aucun Godot/ffmpeg de cette tranche ne reste actif. Xvfb préservé.

## Modification

Deux constantes seulement dans `_build_flashlight`, fichier `scripts/player.gd`. Boîtier déplacé de (0.12,-0.10,-0.10) à (0.38,-0.30,-0.55), source de (0.12,-0.10,-0.15) à (0.38,-0.30,-0.60). Source toujours à l’ouverture de 5cm du cylindre. Dimensions, rotation, FOV, caméra, mains, énergie, portée, angle, ombres et input inchangés. Voir [diff](player.diff).

La première position proposée (.26,-.25,-.50) supprimait l'obstruction, mais cachait le boîtier derrière le rig. Un déplacement modeste vers la droite garde le petit cylindre visible près de la main droite. Les captures finales remplacent cet essai exploratoire non archivé.

## Vérification

- Exception TDD : présentation seule, aucun nouveau comportement. cstack-agent et deslop appliqués ; aucun commentaire, branchement ou abstraction ajouté.
- Vraie `Main`, Godot 4.7.2, X11 :100, 1280×720 Compatibility/llvmpipe : sonde [preview.gd](preview.gd), [commande](command.json), [journal](preview.log), exit0, 8 captures, zéro échec. Sonde temporaire issue du parcours existant, limitée à Refuge/Maintenance, mêmes poses et caméra que render-first.
- Inspection visuelle de quatre images finales : [Maintenance OFF](maintenance_power_off_flash_off.png), [Maintenance ON](maintenance_power_off_flash_on.png), [Refuge OFF](refuge_power_on_flash_off.png), [Refuge ON](refuge_power_on_flash_on.png). Comparaison directe avec `../render-first/maintenance_power_off_flash_off.png` et `../render-baseline/maintenance_power_off_flash_off.png`. Le grand volume bas droit a disparu ; socle orange et sol redeviennent visibles. Le cylindre reste petit à côté de la main droite ; éclairage ON effectif sur sol/façades.
- [test_flashlight_input](test_flashlight_input.log) : X11/dummy, exit0, `FLASHLIGHT INPUT FAILURES: 0`.
- [test_lighting_composition](test_lighting_composition.log) : headless, exit0, `SECTOR POWER: 0 failures`. Avertissement final de cinq instances ObjectDB conservé dans le log ; non investigué dans cette tranche de placement.
- [Commandes et sorties tests](tests.json). Aucun test ni autre source modifié par cette tranche ; UID préexistants préservés.

## Limites

Poses téléportées avec acteurs vivants figés, pas un parcours natif ni une mission. Qualité normale seulement. Aucun benchmark ni chiffre FPS ; aucun GPU joueur ou Windows validé. L’offset de source modifie naturellement la parallaxe du faisceau, sans changement de ses paramètres. Pas d'écoute audio (driver Dummy).

Preuves gelées dans ce dossier. [SHA256](SHA256.json) couvre les fichiers du dossier hors données utilisateur et inclut la source modifiée, le moteur et la sonde originale.
