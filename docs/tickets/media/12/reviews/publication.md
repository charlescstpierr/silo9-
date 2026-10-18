# Revue de publication du ticket 12

Verdict **ISSUES**. Le paquet vérifié contient des preuves cohérentes et 167 empreintes valides, mais 16 liens Markdown du rapport de performance ne résolvent pas depuis leur emplacement publié. Aucun défaut de code de jeu n'est établi par cette revue de publication.

## Périmètre

Revue en lecture seule des nouveautés non committées de `.worktrees/silo9-issue-12` au HEAD `2c205f59520d935e09c921574a20e42379999348` : `docs/VALIDATION.md`, `docs/tickets/12-sector-power.md`, `docs/tickets/media/12/` et `tools/probe_sector_power.gd`, `tools/prove_sector_power.py`, `tools/selfcheck_sector_power.py`. Aucun moteur, ffmpeg, benchmark, export, descendant ou commit. Seul ce rapport a été écrit sous la racine `.cstack/orchestrate/silo9/issue12/`.

## Constat à corriger

**P2, liens de preuve cassés dans `docs/tickets/media/12/reviews/performance.md`, certitude élevée.** Un lecteur ouvre le rapport depuis le ticket et suit ses liens de preuve. Seize occurrences résolvent vers des fichiers ou dossiers absents, car les destinations gardent l'ancienne arborescence de travail. Les mentions générales de chemins historiques dans le ticket n'empêchent pas ces liens Markdown de pointer au mauvais endroit.

| Ligne | Cible actuelle | Correction attendue |
| --- | --- | --- |
| 15 | `perf` | `../perf` |
| 17 | `perf-plan.md` | `../performance/perf-plan.md` |
| 17 | `run_perf_pair.py` | Publier le script à un chemin relatif valide ou retirer le lien en identifiant la référence historique non embarquée. |
| 17 | `proof-tools/run_probe.py`, `proof-tools/probe_sector_power.gd` | Préfixer par `../`. |
| 19 | `perf/host-start.txt` | Publier le relevé et viser son chemin réel, ou nommer explicitement la référence historique non embarquée. |
| 25 | `proof-tools/hashes.txt` | `../proof-tools/hashes.txt` |
| 27 | `../issue08/performance-final/campaign.json`, `../issue08/performance-final/prepare-2/manifest.json` | Publier les pièces historiques ou retirer les liens en indiquant leur disponibilité limitée au checkout de construction. |
| 27 et 87 | `profile-link.json` | `../performance/profile-link.json` |
| 87 | `profile-cpu.log`, `profile-host.log` | Préfixer par `../performance/`. |
| 87 | `proof-tools/runs/profile-candidate` | Publier les données du profil séparé ou retirer le lien en signalant la référence historique non embarquée. |
| 98 | `shadow-prototype/hypothesis.md` | `../shadow-prototype/hypothesis.md` |
| 102 | `perf-audit/audit_perf.py` | `../perf-audit/audit_perf.py` |

Après correction du rapport ou ajout des pièces, recalculer `SHA256.json`. Aucun autre lien Markdown local cassé n'a été détecté dans les documents examinés.

## Contrôles réellement exécutés

- Recalcul SHA256 des 167 entrées de `docs/tickets/media/12/SHA256.json`. Zéro différence, fichier absent ou artefact non répertorié hors manifeste lui-même.
- Lecture et parsing de 66 fichiers JSON. Recherche des cibles des liens Markdown locaux dans `docs/VALIDATION.md`, le ticket et les Markdown du paquet. Recherche de caractères ESC/ANSI et de motifs de secrets dans les artefacts texte et outils : aucun ESC ni motif détecté. La recherche couvre notamment les clés privées PEM/OpenSSH, les préfixes usuels de tokens GitHub/OpenAI et les affectations de clés/Authorization ; elle ne certifie pas l'absence de tout secret de format inconnu.
- Lecture complète des trois outils publics. `cmp` établit l'identité byte à byte du probe et du wrapper avec les prototypes finaux de `.cstack/orchestrate/silo9/issue12/proof-tools/`. Le diff du selfcheck contient seulement le renommage de l'import `run_probe` vers `prove_sector_power`.
- Exécution de `python3 tools/selfcheck_sector_power.py` : trois tests, zéro échec, exit 0. Aucun moteur déclenché par ces tests.
- Recalcul des p50, p95 et p99 de chacun des vingt runs depuis leurs intervalles bruts triés, avec l'indice du probe. Contrôle des médianes de groupes contre `perf-audit/parent-audit.json`. Les 7 537 intervalles concordent avec les étapes enregistrées et les trames rendues moins un. Manifests aux SHA attendus, source_before identique à source_after, sorties 0 et erreurs vides. Les vingt routes atteignent neuf stations et 92,433439 m. Aucun audit exigeant le checkout historique propre n'a été relancé après ajout des documents.
- Contrôle des deux journeys et manifests finaux au SHA `2c205f59520d935e09c921574a20e42379999348`. MÈRE parcourt 193,363482 m, termine phase 4 avec santé 86 en Normal ; N-7 parcourt 187,469382 m, termine phase 4 avec santé 70 en Low. Chacun enregistre six commandes de disjoncteur natives, avec rayon valide, changement d'état et de prompt. Chaque circuit suit ON/OFF, OFF/ON, ON/OFF. Les chiffres arrondis du ticket correspondent.
- Lecture des métadonnées du film et de sa commande archivée. `ffprobe-final.json` donne 1280 × 720, 15/1 images/s, 90,200000 s et 1 353 images lues. L'enregistrement indique `-an`, `ffmpeg_exit=0` et `probe_exit=0`. `decode-final.log` est vide. Ces preuves archivées sont cohérentes ; aucun nouveau décodage ou visionnage n'a été effectué ici.
- Vérification du profil CPU dans les lignes Average de `profile-cpu.log` : huit threads llvmpipe totalisent 458,4 % CPU ; le processus indique 500,8 %, le thread principal 37,4 %. Le ticket limite correctement cette attribution au rendu logiciel du banc.

## Cohérence des conclusions et commentaires

Les médianes Normal recalculées sont 81,805 puis 83,699 ms au p50, 99,678 puis 106,725 ms au p95 et 109,758 puis 118,010 ms au p99. La régression Normal reste affichée dans le ticket, `perf-decision.md` et le verdict **ISSUES en Normal** du reviewer de performance. L'acceptation du coût par le coordinateur ne devient pas un PASS performance. En Low, les médianes concordent et aucun gain n'est promis.

La documentation distingue les parcours automatisés des sessions humaines, les commandes E natives de l'orientation scriptée, les appels du gestionnaire de choix final d'une interaction souris native, l'audio Dummy d'un son entendu, et llvmpipe d'un GPU cible. Les preuves des archives et du binaire Linux exporté ne sont pas encore revendiquées. Les deux parcours et le film restent rattachés au SHA mesuré, pas au futur commit documentaire.

Aucun commentaire source ajouté dans le probe GDScript ou le selfcheck. Le seul docstring du wrapper indique qu'il ne démarre ni n'arrête le serveur X ; le code vérifie cette affirmation. Aucun constat no-comments actionnable.

Aucun fichier de production ou test suivi modifié par ce reviewer. Aucun processus persistant et aucun worktree créé. Worktree libéré pour le parent ; recontrôle des liens et hashes requis après correction documentaire.

## Verdict final après correction des liens

Verdict final de publication **PASS**. Le constat P2 ci-dessus est corrigé. Le verdict initial reste conservé comme trace de la revue.

Contrôle limité au delta documentaire : les 16 destinations ont été corrigées et les 49 liens locaux présents dans les Markdown examinés résolvent désormais vers des fichiers ou dossiers existants. Une comparaison avec le rapport original établit que seules les destinations des liens ont changé dans la copie publiée de `reviews/performance.md` ; son verdict **ISSUES en Normal** et ses limites restent identiques.

Les cinq pièces ajoutées correspondent byte à byte aux originaux : `performance/run_perf_pair.py`, `perf/host-start.txt`, puis `manifest.json`, `journey.json` et `engine.log` sous `proof-tools/runs/profile-candidate/`. Aucun caractère ESC dans ces ajouts. Les deux nouvelles cibles relatives du ticket 08 existent et leurs JSON se parsèment.

Recalcul du paquet final : **172 empreintes correctes**, zéro fichier absent, zéro différence et zéro artefact non répertorié hors manifeste lui-même. SHA256 du manifeste contrôlé : `017b1b52f8b90437a69e813f87a353d163e699501b07d9f1104c9e58ed35b887`.

Les preuves et conclusions de la première passe restent applicables ; ni revue du code ni statistiques ni moteur n'ont été relancés. Le PASS concerne la publication des preuves et n'efface pas la régression performance acceptée. Les preuves du binaire exporté et des archives restent à ajouter séparément. Seul cet addendum a été écrit, aucun processus persistant. Worktree libéré pour le parent.

## Addendum final, exports et smoke Linux

Verdict de publication **PASS** pour ce dernier delta. Les documents distinguent correctement les deux missions depuis les sources, le smoke du Linux exporté et l'absence d'exécution Windows. Le HEAD d'export déclaré est `8727432731bb3743dfb54bae968f3804726eb8b7` ; la source de jeu reste rattachée à `2c205f59520d935e09c921574a20e42379999348`.

Les quatre captures publiées sous `exports/linux-native/` ont été ouvertes individuellement avec view_image. `menu.png` montre le menu initial et Nouvelle descente. `gameplay.png` montre le secteur 01 / Décontamination, le scan actif, le message de signatures révélées et une énergie de 80/100. `pause.png` montre Signal suspendu et les commandes de pause. `menu-return.png` montre le menu principal avec Reprendre la session et Quitter accessibles. Aucun défaut bloquant n'est visible dans cet échantillon.

Lecture de `verification.json`, de `driver.py`, de `engine.log`, de `exports/manifest.json` et de `excluded-attempts.json`. Le driver lance directement le binaire extrait, sans remplacement de projet ou sonde GDScript externe. Les neuf événements OS consignés sortent avec code 0, puis le jeu termine avec code 0. Le journal identifie Godot 4.7.2, X11/Compatibility et llvmpipe ; il ne consigne qu'un avertissement de V-Sync non modifiable. Audio Dummy, sans preuve de son entendu.

Les hashes ont été recalculés sur le fichier extrait désigné par `verification.json` et sur `builds/linux/SILO9.x86_64`. Les deux fichiers font 90 854 224 octets et portent exactement le SHA256 `08385f77fe8d723e7a269cb723a04ce591d3bff0100773581fc783f6d0aa28bc`, identique aux deux manifests. Le hash d'archive consigné identifie l'archive d'extraction initiale ; il ne prétend pas être celui des archives finales enrichies de documentation.

Les deux essais de sonde release et le premier essai de navigation restent explicitement marqués failed et exclus. Le smoke final n'est pas présenté comme une mission complète. Aucun lancement de Windows n'est revendiqué. Le log d'export compressé a été lu ; sa fin indique la complétion du savepack. Aucun export, moteur, test, ffmpeg ou benchmark n'a été relancé pour cet addendum.

Contrôle documentaire final : tous les liens locaux examinés résolvent. Les **183 empreintes** du paquet correspondent, sans fichier manquant ni artefact non répertorié hors manifeste lui-même. SHA256 du manifeste vérifié : `69476b646a9e483122fc495e578e97974a2e612bd92f289c3a24b8041007e837`.

Seul cet addendum dans le rapport racine a été écrit. Les copies publiques restent intactes pour archivage par le parent. Aucun processus persistant, worktree libéré.
