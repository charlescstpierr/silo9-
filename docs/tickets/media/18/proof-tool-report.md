# Outils de preuve 18 : rapport de l'auteur

Statut : outils gelés pour revue indépendante. Compilation finale et 40 selfchecks passent ; le parcours avec les derniers champs d'identité doit être relancé par le parent. Aucun diagnostic ci-dessous n'est une mesure de livraison.

## Périmètre et provenance

Les trois fichiers `proof-tools/probe_sector_power.gd`, `prove_sector_power.py`, `selfcheck_sector_power.py` sont issus exactement de `28e402821469655598c6a84bc415d8ea04da97c2:tools/`. Les SHA initiaux sont dans `proof-tool-tests/baseline.json` ; le diff final est `proof-tool-tests/final.diff`.
Aucun outil suivi, script gameplay, test du jeu, asset, configuration, branche ou commit n'a été modifié. Écritures seulement dans les répertoires de preuve attribués et ce rapport.
Skills lus : cstack TDD, règles communes, délégué, how, ponytail, unslop et réception de revue. Aucun descendant lancé. Le parent a explicitement transféré puis repris chaque périmètre runtime.

## Contrats livrés

- Modes historiques conservés, avec 24 selfchecks historiques toujours passants. Nouveau `--mode persistence` ; nouveau `--mode perf --terminal-variant reference|candidate --flashlight-on`.
- Le perf terminal neutralise six vraies instances par `Enemy.receive_hit`, IA figée aux poses réelles, hors chauffe/mesure. Aucun `mark_defeated` injecté ni suppression pour simuler une victoire. Cette préparation et ses téléports sont déclarés comme fixture.
- La caisse reçoit un vrai `Player.fire` dans les deux versions, avec munition débitée, rayon réellement composé, impact neuf et bounds du collider observés. L'intact reste visible sur la référence et les panneaux apparaissent sur le candidat.
- Le perf vérifie avant chauffe et avant mesure les six IDs, morts/collisions/poses, traces, caisse, lampe ON, qualité, départ immobile et absence de douilles, impact, muzzle, beam et lumière transitoire. L'horloge monotone impose au moins deux secondes de chauffe, indépendamment de l'arrondi du timer moteur.
- La route neuf stations reste celle d'origine. Les intervalles bruts, timestamps de callbacks, compteur réel de frames, étapes et bornes sont recoupés. Les vingt runs ne sont pas lancés par ces outils automatiquement.
- Le parcours suit caisse, sentinel_1 et ARC, puis modifié/revisité/restauré. Porte, circuits mixtes, cœur et inventaire sont contrôlés. Les actions sont liées aux IDs des instances initiales, aux bounds/poses réels, et pour le robot à sa pose létale distincte du spawn.
- La marche utilise le helper Input/physique existant, avec échantillons continus, ordre des visites, retour par le refuge, rejet des sauts et une seule reconstruction permise. Les caméras contrôlées des douze PNG sont déclarées séparément ; elles ne comptent pas comme déplacement et les vues modifié/revisité/restauré doivent correspondre.
- F5/F9 sont envoyés par X11. Le probe attend le fichier nouveau puis les deux nouveaux IDs avec échéance monotone, sans supposer qu'une seule frame a traité la file d'entrée. Des douilles doivent être actives avant et après F5, puis absentes après F9.
- Après reconstruction, un nouveau tir ARC doit viser la nouvelle instance et être horodaté après l'observation restaurée. Il produit exactement le changement de consommation d'énergie. Chaque callback changed capture un snapshot profond ; aucun autre delta de snapshot, fait, souvenir, disabled ou message du verrou n'est accepté.
- Le validateur ferme les types, champs inconnus, objets/étapes manquants, horodatages, chemins, PNG décodables et sauvegarde hachée. Le lanceur compare les demandes sans réécrire les observations. Moteur, source, probe, wrapper, selfcheck et helper X11 sont hachés avant/après.

## Frontière numérique et snapshots

`main.load_run` reconstruit les positions sauvegardées en Vector3. Le validateur reproduit exactement cette conversion IEEE float32 pour `player_position` et les positions `death_poses`. Il n'emploie aucun epsilon pour comparer les snapshots. Inventaire, progression, listes, booléens, yaw et autres champs restent exacts ; seul elapsed est exclu de la comparaison avant/après chargement puisqu'il avance pendant le jeu.
Le fichier sauvegardé garde son hash et sa taille exacte. Sa comparaison au snapshot observé applique seulement la même conversion des positions, avec elapsed exact cette fois. Les autres comparaisons de positions scéniques utilisent les tolérances explicites déjà définies pour les poses physiques et cadrages.
La référence JSON4.7.2 archivée documente `stringify(..., full_precision=true)`. Ce mode est activé pour le rapport, mais le micro-test a réfuté l'hypothèse qu'il annulerait toute différence décimale après `parse_string`. Cet échec est conservé dans `json-roundtrip-validation.json`. La conversion Vector3 exacte, vérifiée sur le même vrai fichier, passe dans `json-roundtrip-vector3-validation.json`.
Le snapshot restauré est maintenant copié profondément immédiatement : des listes retournées par `_snapshot()` ne peuvent plus recevoir les faits/souvenirs de la fin choisie plus tard.

## Vérifications Python et revue

Commande finale : `python3 .cstack/orchestrate/silo9/issue18/proof-tools/selfcheck_sector_power.py`.
Résultat : 40 tests, OK, dont les 24 historiques. Sortie `proof-tool-tests/green-final.log`.
Les preuves rouges utiles avant implémentation sont `red.log` : 22 échecs, états terminaux ignorés et mode nouveau absent ; `red-boundaries.log` : deux échecs sur artefact absent et demande non observée ; `red-finite.log` : valeur non finie acceptée ; `red-review.log` : les six mutants indépendants acceptés ; `red-types.log` : booléen accepté comme santé.
Les autres journaux intermédiaires documentent les ajouts successifs de champs et les fixtures synthétiques. Une fixture synthétique passante ne constitue jamais une preuve d'exécution du jeu.
Les six mutants repris couvrent second ARC avant F9, cible éloignée sans lien à l'objet, caméra restaurée déplacée, même instance ARC après reconstruction, timestamps incompatibles avec les intervalles et champ top-level inconnu. Les types bool/number signalés ensuite sont également rejetés.
La fixture ARC valide a été corrigée : instance initiale103, restaurée1103 et second tir à3500 après observation restaurée3001. Le mutant indépendant qui ne faisait aucune mutation doit maintenant assigner explicitement l'ancienne instance pour rester un cas négatif.

## Diagnostics conservés, tous exclus de livraison

| Dossier sous proof-tool-tests | Résultat observé |
| --- | --- |
| diag-candidate-01 | Six morts réelles, six traces, caisse cassée et route92,433m. Refus de validation : chauffe observée1,961s. Le probe attend désormais l'horloge monotone. |
| diag-reference-01 | Validation passée à cette version d'outil ; six morts réelles, caisse intacte touchée, neuf stations92,433m. Warning moteur : quatre ObjectDB instances à la fermeture. |
| diag-persistence-01 | Trois vraies modifications et cœur récupéré, puis approche diagonale bloquée par mobilier archives. Refus moteur/probe. Route corrigée par l'allée centrale, sans téléport. |
| diag-persistence-02 | Modifications et revisites réalisées,376,2m. F5 vérifié avant traitement X11 ; refus de preuve. Attente conditionnelle bornée ajoutée. |
| diag-persistence-03 | Mission terminée,525,3m, failures=[], douilles et nouveaux acteurs observés. Refus final des snapshots : listes restaurées aliasées jusqu'à la fin et décimales de positions. Corrections ci-dessus ; aucun PASS rétroactif attribué. |

Les préparations robots et le rayon/impact/munition caisse des deux premiers diagnostics perf concordent hors IDs d'instance. Ce constat ne remplace pas une paire exécutée avec la version finale figée.
`compile-01.log` et `compile-02.log` conservent deux erreurs de préparation GDScript corrigées. `compile-03.log` puis `compile-final.log` passent sous Godot4.7.2. Le micro-test `json_roundtrip.gd` a seulement chargé le vrai save de diag03 et écrit ses observations ; `json-roundtrip-engine.log` ne contient aucune erreur.
Les derniers ajouts GDScript d'identité, snapshot profond et précision du rapport sont inclus dans `compile-final.log`. Aucun nouveau parcours/rendu/perf depuis la libération du diagnostic03. Le parent exécutera les parcours finaux et la campagne après revue.

## Gel et libération

SHA-256 finaux :
- `probe_sector_power.gd` : `92fa2c5f61b5b6ece8b8421ce86a0751a099c72facd581ba87f0c5b94f666cf0`
- `prove_sector_power.py` : `6a5b699bb008c890bc394bc67da33d753b74825ff185086880931a098d2d8c81`
- `selfcheck_sector_power.py` : `ab7a711aae3606668bd53c9f9f3ca47298328199b2a6567708ca27e2404cb5fa`

Worktree candidat lu : `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-18`, branche `feat/issue-18-world-persistence`, HEAD fourni et contrôlé par le parent/reviewer `c105da61b2b490546f01c9d67703bfb405a2a44f`. Référence : worktree issue10, HEAD28e4028. Aucun worktree créé ou supprimé.
Tous mes processus sont terminés ; aucun descendant. Écritures des trois outils libérées et runtime headless/X11 explicitement rendu au parent. Aucun merge, publication, export ou campagne effectué par cette tranche.
Limites : diagnostic source Linux X11 Compatibility llvmpipe1280×720. Pas de preuve Windows, GPU joueur, audio audible, ni comparaison de performance finale. Lisibilité des captures à revoir indépendamment ; les outils seuls ne certifient pas un producteur arbitraire.
