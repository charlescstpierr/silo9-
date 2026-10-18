# Revue finale indépendante du harnais ADS

Verdict : **PASS limité au code et au protocole**. Les deux constats de review.md sont clos. Aucun constat actionnable restant dans le périmètre relu. La compilation GDScript, les parcours Godot et la revue des pixels restent à effectuer ; ce verdict ne certifie ni le rendu ni les performances.

Le déplacement est désormais observé avant/après l'action, sans téléportation entre ces observations. La sonde conserve les positions, la direction et les distances, exige des vecteurs finis et la direction +X. Python recalcule la distance dans le plan X/Z, refuse un déplacement inférieur à 0,1 m ou supérieur à 3 m, exige au moins 0,1 m vers +X et un cosinus de direction de 0,9. Les valeurs rapportées sont comparées aux positions. Une chute seule, l'immobilité et un déplacement inversé échouent. Les trois composantes de chaque vecteur sont validées ; les booléens et les valeurs non finies sont refusés. Le contrôle précède le réalignement de la cible.

Le rechargement vérifie maintenant les valeurs réellement observées avant R et après READY : chargeur 8→12, réserve 48→44. Le retour booléen de reload_weapon() ne suffit plus. Les quatre tirs D9 qui précèdent R, l'état initial 12/48 et reload_rounds au commit de base 2818e15a617760dcb98b93927eb563d7af05ba17 concordent avec ce transfert. Aucun crédit artificiel de munitions n'a été introduit dans perf/film. Les deux événements lifecycle restent distincts des tirs et sont obligatoires dans leur ordre pour perf et film.

La charge n'a pas été réduite pour satisfaire les contrôles : 8 tirs/246 dégâts, dont 6 D9 et 2 ARC, en perf/film ; 18 tirs/603 dégâts en inspection. Le parcours conserve le SILO à (0,0,7), le yaw zéro du teleport et la marche à droite avant ADS. Les bornes sont cohérentes avec le contrôleur de base (4 m/s, accélération/décélération 25 m/s², action pendant 0,25 s puis attente 0,3 s). Leur satisfaction effective sur le candidat doit encore être observée dans le moteur. L'inspection conserve son arène explicitement séparée et son renouvellement de ressources par cas.

Lecture complète de probe_ads.gd et prove_ads.py, du protocole, des selfchecks et des rapports antérieurs. Comparaison du runner courant à fix/runner-before.py.txt : seuls validate_lifecycle et son appel ont été ajoutés. Les frontières de gel source/tests/commit/outils/binaire, l'archivage des outils utilisés, les vérifications avant/après invocation, les imports avant mesure, le PNG après frame_post_draw hors intervalle mesuré, les refus de renderer/dessin invalide et le recalcul des percentiles restent présents. Le verdict performance demeure explicitement en attente de revue. Aucun commentaire mort, affirmation trompeuse ou contournement à supprimer identifié.

Contrôle exécuté indépendamment :

```text
PYTHONDONTWRITEBYTECODE=1 python3 .cstack/orchestrate/silo9/issue07/proof-tools/selfcheck.py
Ran 16 tests in 5.524s
OK
exit 0
```

Ces contrôles utilisent des dépôts temporaires et un exécutable Python factice. Ils prouvent uniquement les acceptations/refus du validateur Python ; aucune preuve de jeu n'en est déduite. Les 11 hashes de fichiers énumérés dans manifest.json ont été recalculés et concordent.

Identité contrôlée :

- probe_ads.gd : `5cc699787c2ba306a8c4d9563edda4b9beb31cd1accb6b1b346201ffb9ad4b75`
- prove_ads.py : `9e480f622584876b83a9413ca50ca07b75b0006e4433cef71c211e0655e44386`
- selfcheck.py : `4dc92d3322eb247028df620301a8717eb6fe3134ce9b6e2f36ee72c426d88ef3`

Worktree observé : `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-07`, branche `feat/issue-07-ads`, HEAD observé `0ad803050dee20d29b78899572aeb64c52c3c289`. Le builder reste propriétaire du candidat en cours ; ce HEAD n'est pas certifié par cette revue. Aucun worktree créé, aucun descendant, aucun moteur, serveur X11 ou ffmpeg lancé. Seule écriture : ce rapport. Aucun processus persistant. Tranche de revue libérée au parent.
