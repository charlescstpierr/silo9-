# Revue indépendante des outils de preuve09

Verdict **ISSUES**, borné à la lecture statique et aux expériences Python. Les neuf selfchecks fournis passent, mais deux trous du validateur peuvent rendre une campagne incomplète ou mal préparée verte. Aucun Godot, Xvfb, ffmpeg ou benchmark lancé. La compilation et l'exécution GDScript restent au parent.

Skills appliqués : cstack, contrat cstack-agent, no-comments/comment-reviewer. Playbook Investigation, tranche indépendante sans descendant. Throughput checkpoint: n/a, read-only investigation. Lecture du checkpoint, du contrat accepted.md et de proof-grounding.md. Les trois outils ont été lus intégralement et comparés aux outils livrés12. Aucun fichier de production ou outil modifié.

## Constats

### 1. P2 — Les états demandés ne sont pas tous confrontés aux états effectifs

`proof-tools/prove_sector_power.py:65-100` vérifie les noms des quatre lignes par zone et ne vérifie l'extinction du plafond que **si le bit observé est déjà OFF**. Aucun contrôle n'impose que les deux circuits correspondent au suffixe `_power_on`/`_power_off`. `proof-tools/probe_sector_power.gd:416-419` ignore aussi le résultat de `set_circuit` et n'asserte pas le bit après la préparation. Une commande refusée ou une régression de préparation peut produire des vues intitulées OFF restées ON ; le wrapper les accepte. Certitude : faux positif Python reproduit.

Autre variante du même problème : la vérification lampe à `prove_sector_power.py:88-90` accepte un Spot visible et à ombres mais d'énergie0. L'observation contient pourtant l'énergie, le masque et la portée (`probe_sector_power.gd:340-341`). Une lampe sans éclairage effectif peut donc satisfaire la garde « physical flashlight » ; la revue des images reste nécessaire mais le contrôle automatisé peut déjà rejeter cette incohérence. Certitude : faux positif Python reproduit.

Correction proposée : encoder l'état électrique demandé dans chaque observation de fixture et comparer aux deux bits effectifs, y compris pour la baseline qui possède les circuits. Vérifier qu'une lampe demandée ON a une énergie positive finie, une portée positive et un masque incluant le monde, sans figer ses valeurs artistiques. Ajouter les deux cas rouges au selfcheck. Ne pas imposer de lampe à une baseline déclarée sans API.

### 2. P2 — Un run sans les captures critiques, néon, accessibilité et alarme est accepté

`proof-tools/prove_sector_power.py:65-73` exige seulement20captures, les quatre poses par zone. La fixture `selfcheck_sector_power.py:9-18` en contient exactement20 et passe. Elle n'a aucune des six vues critiques, aucune des13phases néon, aucune des trois phases réduites, ni les deux états d'alarme que la sonde doit produire à `probe_sector_power.gd:458-485`. Un arrêt anticipé sans erreur après les poses standard, ou un retrait accidentel de cette fin de route, conserve donc un résultat vert alors qu'il supprime précisément les preuves des comportements nouveaux. Certitude : fixture fournie exécutée et acceptée.

Correction proposée : faire du catalogue des captures attendues un contrat explicite du mode lighting, puis tester l'absence d'une vue de chaque famille. Vérifier les paires critiques à pose identique. Les phases et la lisibilité continuent de demander un audit des valeurs et des images ; ce contrôle ne remplace pas la revue visuelle.

## Reproduction Python indépendante

Commande fournie exécutée :

```sh
python3 .cstack/orchestrate/silo9/issue09/proof-tools/selfcheck_sector_power.py
```

Résultat : `Ran 9 tests in 0.004s`, `OK`, exit0.

Expériences complémentaires exécutées en mémoire, sans écrire les outils :

```python
from selfcheck_sector_power import lighting_fixture
from prove_sector_power import validate_result

r = lighting_fixture()
for row in r['lighting_samples']:
    row['observation']['circuits'] = {'maintenance': True, 'archives': True}
    for light in row['observation']['lights']:
        light['visible'] = True
        light['energy'] = 1
assert validate_result(r, 0, '') == []  # OFF demandé jamais réalisé.

r = lighting_fixture()
for row in r['lighting_samples']:
    row['observation']['flashlight']['energy'] = 0
assert validate_result(r, 0, '') == []  # Spot ON sans énergie.

r = lighting_fixture()
assert len(r['lighting_samples']) == 20
assert validate_result(r, 0, '') == []  # Aucune famille supplémentaire.
```

## Contrats correctement conservés

- Les hashes des trois outils concordent avec SHA256.json : sonde `abfd5bde540775cf0486c002f4daf00ce2886af97a145dd3e8b38d226b7335af`, wrapper `023adb28c05de3ee1a580a648ed21da9ad444b6958a740bb41f4169027ea09e0`, selfcheck `547b585c713bd8e298f8aa9862fb737c86ff61db698342a857db700211022abb`.
- Les onze corps de fonctions annoncés dans route-identity.json sont identiques à ceux du root : performance_route, mission_route, use_arc_lock, breaker_cycle, use_object, capture_consumers, visible_enemy, aim, _process, percentile et wait. Le delta de walk_to consigne la destination après vérification à0,3m ; ce sont les destinations atteintes, pas la position physique brute finale.
- Les neuf stations de performance restent physiques via Input, mêmes attentes et ennemi retiré. Les poses lighting sont explicitement téléportées, acteurs gelés vivants, phase1 et énergie0 ; leur route n'est pas vendue comme une mission. Le combat utilise le raycast, donc n'établit pas la lisibilité des pixels.
- Le mode perf n'appelle pas la capture PNG ; lighting-perf ne la déclenche pas non plus. Ses fenêtres individuelles réinitialisent l'origine du timer et les maxima, séparent les intervalles des quatre états, excluent les observations de la fenêtre mesurée. Leurs six secondes et l'égalité frames/intervalles restent à confirmer dans le runtime. Les timings globaux de ce mode ne sont pas comparatifs, correctement indiqué.
- F passe par le helper XTest réel de tools/x11_input.py, avec press/release et attente ; le code de sortie seul ne suffit pas, les états OFF→ON d'intention et de visibilité réelle sont aussi exigés. Cela prouve une activation avant la mission, pas les gardes de reprise/modale ou le gamepad ; ces dernières restent aux tests du jeu.
- Les observations lisent les vrais nœuds, matériaux, caméra, bits et valeurs du viewport. L'absence d'API lumière sur la baseline est consignée sans inventer un Spot. Le contrat de nom des neuf Omni est exigé pour le candidat seulement.
- Les hashes moteur/wrapper/sonde et source avant/après, l'absence de dossier de sortie préexistant, le moteur X11/Compatibility, résolution, identité mode/qualité et erreurs moteur constituent des gardes utiles. Le wrapper vérifie la signature PNG et la présence, sans prétendre décoder ou juger l'image.

## Limites restant à l'audit parent

Le validateur cost_windows vérifie ordre, nombre minimal d'intervalles et comptabilité frames, mais pas la durée totale, la liaison aux observations avant/après ni l'état alarme actif. Une expérience Python a confirmé que quatre fenêtres fictives de20intervalles à0,001ms sans observation_after sont acceptées. La sonde actuelle demande bien6s et écrit observation_after ; auditer ces champs sur les vrais résultats avant tout chiffre, ou renforcer le validateur. Ce n'est pas une mesure obtenue.

La sélection du modèle de couleur, la présence de silhouettes dans le champ, le cadrage des cibles, l'absence de noir bouché et les vraies ombres ne se déduisent pas des booléens. Les captures et leur revue indépendante restent obligatoires. Aucun GPU cible, Windows, audio audible ou FPS joueur validé par cette tranche.

## Commentaires et libération

Aucun constat actionnable de commentaire. Les commentaires justifient des choix non évidents de preuve : fixture non native, échantillonnage séparé, expiration avant comparaison OFF, horloge réelle et tolérance de sérialisation float. Aucun commentaire retiré, aucune correction appliquée, aucune contrainte externe non encodée découverte ; aucune relance nécessaire.

Seul fichier écrit : ce rapport. Aucun worktree créé, aucune branche modifiée, aucun commit/push/PR. Worktree source lu : `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-09`, branche `feat/issue-09-lighting`, HEAD observé `896f0447d5f3ba94a464cdae96735228bfd15368`. Son chantier de production n'a pas été audité. Aucun processus laissé actif, scope relâché. Recherche mémoire générale sans fait SILO9 utilisé ; les conclusions reposent sur le code et les expériences de cette tranche.
