# Revue visuelle indépendante issue 12

PASS pour le périmètre visuel examiné. Aucun problème concret bloquant observé dans les images finales. Ce verdict ne couvre ni la performance, ni Windows, ni le GPU cible, ni une équivalence visuelle avec Fortnite.

Candidat vérifié par Git et par les deux manifests : `2c205f59520d935e09c921574a20e42379999348`, branche `feat/issue-12-sector-power`, worktree `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-12`.

Racine des chemins de preuve ci-dessous : `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.cstack/orchestrate/silo9/issue12/`.

Contrat lu : `design/accepted.md`. Les répertoires examinés sont exclusivement `proof-tools/runs/final-mother-capture/` et `proof-tools/runs/final-n7-low-capture/`. L'ancien `candidate-mother-capture` n'entre pas dans ce verdict.

## Provenance et parcours

Lecture ciblée des `manifest.json` et `journey.json` dans chacun des deux répertoires. Les manifests portent le même HEAD attendu, `source_unchanged=true`, `exit_code=0` et `validation_errors=[]`. Les journeys portent `failures=[]`, `phase=4`, la fin attendue et obtenue `mother` en normal et `n7` en Low. Ils déclarent respectivement 31 et 30 waypoints terminés.

Chaque journey contient exactement six commandes de disjoncteur, trois Maintenance puis trois Archives. Chaque commande a `native=true`, `aim_valid=true`, `changed=true`, `prompt_changed=true`. Les bits suivent ON vers OFF, OFF vers ON, ON vers OFF pour chaque circuit. Les prompts passent entre « Couper maintenance/archives » et « Rétablir maintenance/archives ».

Ce sont des parcours automatisés avec déplacement par Input, orientation scriptée et touche E native OS, sous Linux X11, Godot 4.7.2, gl_compatibility, llvmpipe LLVM 21.1.8, sortie 1280 × 720. Les deux journeys indiquent `performance_valid=false`. Audio Dummy, sans preuve d'audibilité. Les snapshots complètent les images mais ne remplacent pas une revue physique complète des collisions.

## Observations directes dans view_image

Les fichiers suivants ont été ouverts individuellement avec `view_image`, dans chacun des deux répertoires de capture finale :

- `before_03_breaker_maintenance.png` et `after_04_breaker_maintenance.png`.
- `before_07_breaker_archives.png` et `after_08_breaker_archives.png`.
- `before_03_maintenance_sas.png` et `after_04_maintenance_sas.png`.
- `before_07_archives_sas.png` et `after_08_archives_sas.png`.
- `before_03_maintenance_fan_0.png`, `after_04_maintenance_fan_0.png` et `after_05_maintenance_fan_0.png`.
- `before_07_archives_fan_0.png`, `after_08_archives_fan_0.png` et `after_09_archives_fan_0.png`.

Les disjoncteurs portent une étiquette à leur échelle, lisible à cette distance. Les états « ON · SOUS TENSION » et « OFF · HORS TENSION » sont distinguables dans les deux qualités. Le levier change de pose. Le prompt français reste lisible et ne recouvre ni le nom du circuit ni son état. L'arme ne masque pas le levier visé.

La coupure assombrit nettement le sol, les panneaux et les meubles. Les bandes cyan des Archives et les plafonniers cessent d'émettre visuellement ; leur retour est visible dans les vues des ventilateurs après rétablissement. Les éléments conservés sur réserve restent reconnaissables. La différence ON/OFF ne dépend donc pas uniquement du texte du disjoncteur.

Les vues des sas montrent les deux feuilles latérales abaissées, puis relevées hors du passage visible après coupure. Le passage central demeure dégagé. Le rapprochement des snapshots confirme le passage de y=1,7 à y=5,1, puis le retour à y=1,7 au rétablissement. Les images ne constituent pas une preuve d'absence d'écrasement ou de collision défectueuse.

Les ventilateurs à pales restent identifiables sur les meubles, avec châssis visible dans les états ON et OFF. Le ventilateur Archives est petit et oblique dans le cadrage de capture, mais identifiable. Aucun défaut de masquage fonctionnel n'est démontré. Des images fixes prises à des poses différentes ne prouvent pas seules l'arrêt ou la reprise : les valeurs ci-dessous apportent cette preuve temporelle complémentaire.

Le HUD français, les objectifs, les valeurs de vie/énergie, les munitions et les raccourcis sont lisibles et non masqués dans les vues examinées. Low rend les contours du monde plus crénelés, mais préserve la lecture du HUD et des commandes. Les panneaux métalliques, tuyaux, accents cyan/orange et silhouettes simplifiées restent cohérents avec le style industriel stylisé existant. Aucun défaut grossier nouveau n'apparaît dans cet échantillon ; aucune comparaison validée avec Fortnite n'a été effectuée.

## Arrêt et reprise des rotors dans les snapshots

Valeurs de rotation Z lues dans `journey.json`, chemin `Circuit_<circuit>/fan_<circuit>/Rotor` :

| Capture | Circuit | Angle après coupure et avant rétablissement | Angle après rétablissement | Angle avant coupure suivante |
| --- | --- | --- | --- | --- |
| final-mother-capture | Maintenance | 18,66 | 19,08 | 22,56 |
| final-mother-capture | Archives | 38,20 | 38,62 | 42,20 |
| final-n7-low-capture | Maintenance | 18,18 | 18,54062 | 21,92 |
| final-n7-low-capture | Archives | 37,00001 | 37,39735 | 40,70002 |

L'angle reste identique entre les captures espacées de l'état coupé et progresse après rétablissement. Les AudioStreamPlayer3D correspondants passent de `playing=true` à `false`, puis à `true`. Cela prouve l'état des lecteurs, pas un son entendu.

## Fins et film

Ouverture directe de `proof-tools/runs/final-mother-capture/conclusion_mother.png` et `proof-tools/runs/final-n7-low-capture/conclusion_n7.png`. Les panneaux « CONFINEMENT » et « ÉMANCIPATION » portent des textes français complets, des boutons lisibles et le message « Progression sauvegardée. ». Aucun chevauchement visible.

Les six images `native-film/review-frames/frame-01.png`, `frame-02.png`, `frame-03.png`, `frame-04.png`, `frame-05.png` et `frame-06.png` ont été ouvertes individuellement. Cet échantillonnage fourni toutes les 15 secondes montre le refuge, la Maintenance, le scan/relais, les Archives, le combat au Cœur et le retour vers l'ascenseur. Le HUD reste lisible. Les images ne montrent ni écran vide ni géométrie grossièrement corrompue.

`native-film/ffprobe-final.json` décrit `mother-final.mp4` en H.264, 1280 × 720, 15 images/s, 90,2 secondes et 1 353 images lues. `native-film/decode-final.log` est vide, donc aucune erreur de décodage n'y est consignée. `native-film/mother-final-recording.json` consigne `ffmpeg_exit=0` et `probe_exit=0`, sans audio. Ces éléments documentent le contrôle du fichier et le décodage archivé ; je n'ai ni relancé ffmpeg ni regardé la vidéo en continu. La revue visuelle porte sur les six images échantillonnées et les captures fixes supplémentaires, pas sur chaque image du film. La cadence du film et les temps de capture ne prouvent pas les performances du jeu.

## Exécution et libération

Skills lus : cstack, règles communes, contrat de délégué, investigation, how et unslop. `throughput checkpoint: n/a, read-only investigation`. Aucun descendant, moteur, ffmpeg ou processus persistant lancé. Aucun fichier suivi modifié ; seul ce rapport a été écrit. Aucun worktree créé. Worktree candidat relâché par ce reviewer ; son nettoyage appartient au parent.
