# Ticket 7 — revue indépendante du code

**PASS dans le périmètre de revue du code.** Aucun défaut concret restant identifié dans le delta examiné. Ce verdict ne remplace ni la revue des pixels, ni le parcours natif, ni les mesures de performance.

Head examiné : `1f36f01eea2e5d34dafee7f46a665c013370cbb4`, branche `feat/issue-07-ads`, base `2818e15a617760dcb98b93927eb563d7af05ba17`.
Worktree : `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-07`.
Relecteur indépendant du builder, avec un seul modèle ; aucune diversité de modèles revendiquée.

## Périmètre et examen

Lecture du delta complet des sept fichiers de production, des nouveaux tests, des quatre migrations de tests et de `tools/verify.sh`, puis des appelants voisins dans Player/Main, du rig et de WeaponHandling. Lecture de la conception acceptée, des gates tests-only et saut, de la décision réticule et du rapport d’implémentation. Recherche des anciens contrats `Pose.AIM` et `_rest_fov` : aucun appelant restant dans scripts/tests/tools. `git diff --check` passe.

- Player possède l’unique progression ADS. Le poids lissé alimente le rig, le FOV et la sensibilité ; les recompositions de rendu ne l’avancent pas. L’impulsion FOV reste un canal indépendant ; son annulation recompose les options actuelles. Le rayon de tir continue de dépendre du transform caméra, sans rotation de recul.
- La calibration du rig incorpore le produit mount/modèle et donc l’échelle réelle. Elle utilise les références liées aux organes dessinés, une base rigide validée et la distance de hausse par arme. Le bind HIDDEN restaure d’abord les pièces ; aucun solve ni nouveau mesh/material n’est ajouté par frame. Le rig reste auteur des mains, pièces et marqueurs.
- Le poignet ADS s’interpole avec la pose de hanche puis avec la pose complète de manipulation. À poids 1, le bob/sway/crouch ne déplace plus les mires. Le recul demeure axial et réduit pendant la manipulation. LOWER_ABORT conserve le gel existant ; le rebind caché ne remet pas directement le poids/FOV Player à zéro.
- Les gardes aim/fire interrogent aussi les sources physiques souris et joypad0, ce qui conserve une source tenue quand Godot reçoit la libération de l’autre. Les tests couvrent les deux ordres de libération pour aim et les interruptions. Le support manette est explicitement borné au périphérique 0 ; il ne constitue pas un remapping général.
- Le verrou saut consomme l’activation GUI à la reprise et s’efface après observation d’une entrée neutre sans nouveau front. Une fois armé, le saut utilise bien `is_action_just_pressed`, même si le tap est déjà relâché. Le test de régression vérifie une vraie capsule au sol, l’élévation, le contrôle tenu et l’absence de double saut.
- Les trois options ADS sont validées à la lecture de la configuration : type numérique non booléen, finitude puis bornes. Elles sont persistées hors sauvegarde gameplay et réappliquées au Player remplacé. La validation endpoint précède leur mutation à Apply. Le changement WASD/ZQSD préserve les bindings manette ; les ajouts GUI évitent les doublons. La garde de visibilité du bouton demeure en place.
- Le réticule lit le poids ADS sans état dupliqué et actualise son alpha avant le throttle textuel du HUD. L’inspection des pixels et de sa lisibilité est une preuve séparée, non déduite de cette lecture.

## Tests et intégrité des preuves

Contrôle indépendant par lecture des fichiers et recalcul SHA-256, sans exécuter Godot :

- Les **107 hashes** du manifeste final correspondent aux fichiers présents et aux blobs Git du head examiné.
- Le binaire déclaré correspond au hash `8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e`.
- `verification-final.json` contient **39 invocations** : import + **38 suites**, toutes sorties 0. Les hashes des 39 logs correspondent ; aucun `SCRIPT ERROR`, `Parse Error`, `ERROR:`, `FAIL:` ou `GUARDED:`. Le total recalculé est **1 277 assertions PASS**.
- Cette campagne précède le dernier déplacement visuel de la pastille du guidon. La comparaison des manifests confirme que **seul `scripts/weapon_visual.gd` change ensuite**. La copie antérieure correspond à son hash de campagne ; le patch déplace une seule coordonnée de la pastille de 9 mm, sans changer hauteur, marqueurs, logique ni contrat ADS.
- Après ce delta, **trois suites** sont archivées sur la source finale : géométrie ADS, rig et géométrie visuelle. Hashes des trois logs corrects, sorties 0, aucune erreur/échec/garde. **Les 38 suites n’ont pas été toutes relancées sur le head final.**
- Les **33 artefacts** référencés dans la preuve de calibration finale (32 PNG + observations JSON) ont les hashes annoncés. Ceci vérifie leur intégrité, pas leur qualité visuelle.

Les migrations des tests existants conservent leur objet : matrice rig de trois poses, déplacement des deux mains/arme, assertions de recul avec configuration publique du FOV, stabilité ADS remplaçant le sway historique. Les nouveaux tests contrôlent alignement des mires et vrais impacts à plusieurs distances/FOV, ressources de combat, transitions irrégulières, deltas nuls, cycles, interruptions, manipulations, réglages et événements joypad logiciels. Les deux corrections de harnais/régression ont des gates distincts ; aucun affaiblissement silencieux des nouveaux tests constaté.

## Commentaires et limites

Passe commentaires/deslop indépendante : aucun commentaire ajouté redondant, contrat périmé, code mort commenté ou contournement nécessitant une correction relevé dans le delta. Aucun changement de style demandé.

Je n’ai lancé aucun Godot, X11, ffmpeg ni benchmark et n’ai pas utilisé l’affichage réservé au parcours natif. Les résultats runtime ci-dessus proviennent des logs archivés vérifiés, pas d’une réexécution personnelle. Aucune conclusion sur Windows, manette physique, GPU cible, collisions générales arme/décor, rendu continu ou parité Fortnite. Ces limites ne sont pas transformées en défauts de code hors périmètre.

## Libération

Seul ce rapport a été écrit. Aucun fichier source/test modifié, aucun commit/push, aucun descendant ni processus de jeu lancé. Worktree relâché par ce relecteur, head inchangé `1f36f01eea2e5d34dafee7f46a665c013370cbb4`. L’agent natif conserve la propriété de son affichage et de ses processus.
