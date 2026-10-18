# Prévol indépendant de l'outil performance ticket 10

Verdict : **PASS avec limites explicites**. La campagne de 40 runs peut commencer avec les trois outils figés de `perf-proof-tools`. Ce verdict porte sur l'outil et le protocole, pas sur une amélioration de performance encore non mesurée.

- [x] Règles cstack 0.8.0 et `benchmark-checklist` lus.
- [x] Plan, wrapper de paires, sonde, validateur et diff comparés aux outils `route-proof-tools`.
- [x] 24 selfchecks relancés indépendamment : tous réussissent (`perf-audit/selfcheck.log`). Aucun moteur lancé par cette revue.
- [x] Diagnostic existant relu et validé indépendamment (`perf-audit/preflight-checks.json`), sans réutiliser ses timings dans les résultats comparatifs.
- [ ] Audit de la campagne : attendre la notification du parent et les 40 runs complets.

## Contrat vérifié

`--flashlight-on` est refusé hors mode perf avant lancement du moteur. En perf, le wrapper transmet la demande au moteur et séparément au validateur. Le rapport ne peut donc pas substituer sa propre demande à celle de la CLI. L'état OFF reste le défaut; l'API historique de lecture accepte les anciens rapports OFF, tandis que les nouvelles exécutions exigent le schéma 3.

La sonde recherche le vrai `SpotLight3D`, appelle `toggle_flashlight()` avant la chauffe et vérifie intention et visibilité. Les lectures avant chauffe, à chaque callback mesuré et en finale viennent directement de la lampe. Pour ON, le validateur exige visibilité, intention ON, énergie et portée positives finies, masque incluant le monde et ombre conforme à Normal/Low. Une lampe absente ou un changement d'état en route est rejeté. Le nombre de lectures est lié aux intervalles. La lecture légère est ajoutée aux deux versions; le parcours, les quantiles et les maximums ne changent pas.

Le diagnostic existant a 260 callbacks **`_process`**, 259 intervalles et 260 frames dessinées, neuf stations et 92,4334392547607 m. Ce ne sont pas des callbacks physiques. La lampe émet avant la chauffe, pendant tous les callbacks et en finale. Les ticks reconstruisent exactement les intervalles et leurs étapes; la finale suit le dernier tick. Les sources (2205 fichiers) et les trois artefacts moteur/wrapper/sonde sont identiques avant/après. Le diff stocké correspond exactement au diff actuel. Les hashes des trois outils correspondent au rapport de l'auteur.

La chauffe utilise le timer Godot de deux secondes déjà présent; le premier tick mesuré survient 1,995208 s après l'observation préalable dans ce diagnostic. Cette granularité au callback ne change pas l'extension et ne doit pas être présentée comme une borne monotone exacte d'au moins 2 s.

## Conditions de campagne et portée des résultats

Les quatre groupes Normal OFF, Normal ON, Low OFF et Low ON contiennent chacun cinq paires baseline/candidat, soit 40 runs. L'ordre des versions s'inverse une paire sur deux. `subprocess.run` sérialise les deux membres d'une paire; le parent doit également sérialiser les paires et conserver les heures de début/fin ainsi qu'une preuve de l'absence d'autre moteur, encodeur ou profil concurrent.

Baseline attendue : `0297cf78827e180a10b16648cf7e411499f531d4`. Candidat attendu : `64a948545d63764cb500f6ac1a02380c5d1513f3`, avec les hashes des sources réellement exécutées dans les manifests. Aucune écriture dans les worktrees pendant les mesures, y compris dans les preuves suivies par Git : les hashes complets les incluent.

Le validateur de l'outil ne recalcule pas lui-même les quantiles ni la cohérence temporelle des nouveaux ticks. L'audit de campagne doit donc le faire indépendamment et vérifier échelle, FOV, circuits, neuf stations, distance, frames, lampes, codes de sortie, source et artefacts pour chaque run. Ce contrôle supplémentaire n'exige pas de modifier la sonde figée.

Les comparaisons autorisées sont baseline contre candidat **à qualité et état de lampe fixes**. ON contre OFF entre groupes n'est pas une activation appariée dans le même run. Les 24 selfchecks et le diagnostic restent exclus des chiffres de livraison. La fenêtre CPU du ticket 09 ne permet pas d'attribuer un éventuel gain du ticket 10.

Ce protocole mesure les intervalles wall-clock entre callbacks `_process` sur llvmpipe Linux, en Compatibility 1280×720. Il ne mesure pas du temps GPU et ne prouve ni Windows ni 60 FPS en 1080p. Aucun résultat de performance de la campagne n'est encore validé ici.

## Libération du prévol

Aucun moteur, encodeur, benchmark, profil ou descendant lancé. Aucun worktree modifié. Les seuls fichiers écrits sont `perf-tool-review.md` et les preuves sous `perf-audit/`. L'agent reste disponible pour la seconde phase après notification explicite du parent.
