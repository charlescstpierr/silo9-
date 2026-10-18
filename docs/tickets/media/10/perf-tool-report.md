# Outil performance lampe ON/OFF

Extension locale prête pour revue, sans modification du jeu, commit, nouveau worktree ni descendant. Les trois outils sont copiés depuis `route-proof-tools/` vers `perf-proof-tools/`. Les originaux restent inchangés. Branche candidate inspectée `feat/issue-10-environment`, HEAD `64a948545d63764cb500f6ac1a02380c5d1513f3`. Base inspectée `0297cf78827e180a10b16648cf7e411499f531d4`.

## Comportement

`--flashlight-on` existe uniquement en mode `perf`. Sans ce flag, la demande demeure OFF. Les modes mission, capture, lighting et lighting-perf refusent le flag avant le lancement du moteur. Leurs parcours, données de lampe et schéma 2 restent identiques. Le wrapper transmet le flag à Godot et remet séparément la demande CLI au validateur existant. Il ne remplace aucune observation par la demande.

La sonde active la lampe par `toggle_flashlight()` avant la chauffe de deux secondes. Une lampe physique absente, un toggle refusé ou un état qui reste OFF invalident ON. Le parcours historique de neuf stations est inchangé, ainsi que le calcul des intervalles, quantiles et maximums.

Le mode perf utilise désormais le schéma 3. Il conserve tous les champs existants et ajoute `flashlight_requested`, `perf_flashlight_before_warmup` et `perf_flashlight_samples`. Chaque callback mesuré enregistre le tick monotone, l'étape et une lecture directe du SpotLight3D: visibilité réelle, énergie, ombre, position, masque et portée, plus l'intention `player.flashlight_on`. La lecture finale existante contient aussi cette intention. Aucune inspection lourde de la scène n'est ajoutée dans la fenêtre mesurée.

Le validateur contrôle la lampe avant chauffe, à chaque callback et en finale. Pour ON, elle doit être visible, déclarée ON dans le joueur, émettre avec une énergie et une portée positives finies, viser la couche du monde et respecter le budget d'ombre Normal/Low. Le nombre d'observations doit correspondre aux callbacks mesurés. Les rapports historiques OFF restent acceptés par l'API de validation sans demande explicite. Une nouvelle exécution via le wrapper exige le schéma 3 et les observations, même en OFF. L'absence physique de lampe reste acceptable pour un rapport OFF; elle ne peut jamais valider ON.

## TDD et vérifications

Commande rouge puis verte:

```sh
python3 .cstack/orchestrate/silo9/issue10/perf-proof-tools/selfcheck_sector_power.py
```

- `perf-tool-tests/red.log`: exécuté avant les gardes, 24 tests, 26 assertions en échec et une erreur correspondant à l'API de demande CLI absente. Les échecs portent notamment sur ON observé OFF, état changé en route, état avant chauffe, propriétés manquantes, émission/ombre invalides et refus du flag hors perf.
- `perf-tool-tests/green.log`: mêmes tests, 24 réussites. Les tests couvrent aussi la compatibilité du défaut OFF, l'acceptation ON Normal/Low et l'absence de réécriture du rapport par la validation.
- Compilation Python des deux fichiers réussie.
- `perf-tool-tests/diagnostic-validation.json`: relecture du vrai diagnostic par le validateur, puis mutations en mémoire. Demande CLI opposée, OFF en route, OFF final et lampe absente sont toutes rejetées. Aucun fichier du diagnostic n'a été falsifié.
- `perf-tool-tests/tools.diff`: diff complet par rapport aux copies originales.

## Diagnostic unique, exclu de la livraison

Commande réellement exécutée:

```sh
python3 .cstack/orchestrate/silo9/issue10/perf-proof-tools/prove_sector_power.py --project .worktrees/silo9-issue-10 --godot .tools/Godot_v4.7.2-stable_linux.x86_64 --output .cstack/orchestrate/silo9/issue10/perf-tool-diagnostic --mode perf --flashlight-on --require-circuits --require-lighting --display :100 --timeout 900
```

Godot 4.7.2, Compatibility, X11 :100, 1280×720, llvmpipe. Sortie 0, validation sans erreur. Neuf stations, 92,4334392547607 m, 260 callbacks `_process` et 259 intervalles. Lampe réellement ON avant chauffe, dans tous les callbacks et en finale: énergie 2,5, portée 14, masque 1, ombre Normal activée. La commande du manifest contient bien `--flashlight-on`.

Les 2205 fichiers recensés par le wrapper sont identiques avant/après, de même que moteur, wrapper et sonde. `perf-tool-diagnostic/manifest.json` contient les hashes, `journey.json` contient les observations. Ce diagnostic sert exclusivement à vérifier l'outil; il est exclu des chiffres de livraison. La campagne comparative de 40 runs appartient au parent après revue.

L'instrumentation ajoute une lecture légère et une petite structure par callback. La même version doit servir aux deux branches et aux deux états de lampe. Ces mesures restent des intervalles wall-clock sur rendu logiciel Linux, pas du temps GPU ni une preuve Windows ou 60 FPS en 1080p.

## Hashes figés

- `probe_sector_power.gd`: `0e0f03fd1eb922719bb4862f461b3a04355c83d22be28b5dffe24f7f803dda26`
- `prove_sector_power.py`: `1493110c32ec4ff8907b1a203071832969c010f575dbfcfefb0b733ec3c90a2b`
- `selfcheck_sector_power.py`: `6d68d3b1a6382e47fc76f12129aebab237c713bfd21b03ea0c6d477079aba082`
- Moteur: `8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e`.


## Libération

Aucun worktree créé ou modifié par cette tranche. Workspace absolu `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro`. Le seul moteur lancé, PID 3216593, et son wrapper PID 3216541 ont terminé. Aucun encodeur, profil ou autre moteur n'a été lancé. X11 :100 est explicitement libéré; le serveur Xvfb préexistant PID 2472984 est toujours actif et n'a jamais été redémarré. Tous les processus de cette tranche sont terminés.
