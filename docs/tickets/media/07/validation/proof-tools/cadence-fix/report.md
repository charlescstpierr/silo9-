# Attente de cadence ARC dans la preuve ADS

Rouge réel inspecté avant modification : `../../perf-profile/run/godot.log` refuse `arc-ADS-2`, puis échoue sur les quotas (7 tirs, 207 dégâts). Le parcours attendait 0,5 s alors que la cadence ARC exige 0,52 s.

Une seule ligne ajoutée après cette attente : `await ready_weapon(1)`. Le helper existant attend les frames physiques jusqu’à la fin effective de `_shot_time` et la disponibilité de l’arme. La temporisation minimale, les tirs, les quotas et les propriétés du jeu restent identiques. Aucun fichier de production modifié.

Contrôle effectué : comparaison exacte avant/après ; ajout unique de cette ligne. Aucun runtime Godot lancé conformément au périmètre. Le parent doit réexécuter le parcours réel pour établir le vert ; cette modification seule ne le prouve pas.

SHA-256 avant : `bce35a3a48b04717976bf15844c08b892bd70386eff63829a11c0f6f11df6985`

SHA-256 après : `a0322c3f6e7186033dc97763c082a20dc50537d1fa6a9d13519cd6ede956a56d`
