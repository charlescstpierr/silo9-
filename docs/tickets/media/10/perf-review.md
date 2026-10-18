# Revue indépendante de performance ticket 10

Verdict : **PASS pour la campagne locale et son intégrité**. Le candidat présente des intervalles p50 et p95 plus courts dans les cinq paires de chacun des quatre groupes. L'amélioration observée est reproductible sur cet hôte llvmpipe; sa cause précise et sa transposition à un GPU joueur restent non établies. Aucun défaut de protocole bloquant trouvé dans les 40 runs.

## Résultats recalculés

Chaque groupe contient cinq paires de versions. Les valeurs p95 ci-dessous sont la médiane des cinq quantiles par run, suivie de leur plage minimum–maximum. Les différences sont calculées à l'intérieur de chaque paire candidat moins baseline, puis résumées. La médiane des pourcentages appariés n'est pas le ratio des deux médianes.

| Groupe | p95 baseline, ms [plage] | p95 candidat, ms [plage] | Δ p95 apparié médian, ms [plage] | Δ p95 apparié médian |
|---|---:|---:|---:|---:|
| Normal OFF | 89.894 [86.222–95.711] | 79.266 [76.198–83.944] | -10.982 [-16.249–-5.753] | -12.19% |
| Normal ON | 105.234 [100.093–108.836] | 91.156 [89.643–97.209] | -12.307 [-17.680–-2.884] | -11.97% |
| Low OFF | 56.408 [54.690–57.115] | 47.597 [46.330–51.608] | -7.200 [-10.785–-4.123] | -13.17% |
| Low ON | 62.739 [58.604–63.328] | 54.043 [50.082–55.329] | -8.599 [-13.199–-5.295] | -13.58% |

Les 20 différences appariées p95 sont négatives; les plages p95 des deux versions ne se chevauchent dans aucun groupe. Même constat pour p50. Les p99 sont plus dispersés : une paire Normal ON augmente de 5,562 ms (+5,23%) et une paire Low OFF augmente de 0,674 ms (+1,12%). Ne pas annoncer une amélioration systématique de chaque queue de distribution.

| Groupe | p50 baseline → candidat, ms | p99 baseline → candidat, ms | Δ p50 apparié médian | Δ p99 apparié médian |
|---|---:|---:|---:|---:|
| Normal OFF | 71.176 → 64.036 | 96.874 → 87.041 | -10.17% | -9.18% |
| Normal ON | 83.408 → 76.104 | 122.858 → 101.272 | -10.48% | -16.61% |
| Low OFF | 42.986 → 37.958 | 63.465 → 53.949 | -11.29% | -13.17% |
| Low ON | 47.058 → 42.371 | 71.492 → 63.074 | -9.85% | -12.68% |

`perf-audit/campaign-audit.json` conserve les 40 quantiles recalculés, toutes les plages p50/p95/p99 et les cinq différences appariées en ms et en pourcentage pour chaque groupe. Aucun intervalle de runs différents n'est fusionné avant le calcul. La règle est celle de la sonde : tri puis index `floor(n*p)`, plafonné à `n-1`.

Les médianes des maxima de drawcalls par run passent de 277 à 273 en Normal OFF, de 310 (plage 309–311) à 305 en Normal ON, et de 270 à 267 pour les deux groupes Low. Les maxima de nœuds passent de 607 à 600; ceux des ressources restent à 101. Ces compteurs ne mesurent pas le coût GPU ou le nombre de pixels traités.

## Travail exécuté et provenance

Les 40 dossiers attendus et uniquement eux sont analysés. Chaque wrapper et chaque moteur termine avec code 0, sans erreur de validation ni erreur moteur détectée. Tous les runs conservent les neuf stations exactes du contrat et 92,4334392547607 m de déplacement. Ils dessinent réellement entre 244 et 566 frames, avec exactement une frame de plus que d'intervalles. Les ticks monotones des observations reconstruisent chaque intervalle brut et chaque étape. L'échelle observée est 1,0 en Normal et environ 0,67 en Low; le FOV est 76; les deux circuits restent ON en finale, sans changement prévu par le trajet.

La lampe physique est conforme à la demande avant la chauffe, dans chaque callback `_process` mesuré et en finale. Les observations se déplacent réellement avec le joueur. En ON, visibilité, intention, émission, portée, masque du monde et budget d'ombre sont validés; en OFF, visibilité et intention restent fausses. Les neuf lumières fixes ne projettent pas d'ombre. Il s'agit d'un trajet sans ennemis, pas d'une mission de combat complète.

Baseline : `0297cf78827e180a10b16648cf7e411499f531d4`. Candidat : `64a948545d63764cb500f6ac1a02380c5d1513f3`. Les 2206 fichiers baseline et 2205 fichiers candidat recensés restent identiques avant/après chaque run et entre tous les runs de la même version. Le candidat conserve `scripts/world_art.gd` SHA256 `c3a973b5774ba521a29deff13dd9234db260c5e0329a0ecfc20da3d53b866cf0`. Les empreintes du moteur, du wrapper et de la sonde sont celles figées au prévol, identiques dans tous les manifests et revérifiées sur les artefacts locaux.

L'ordre baseline/candidat s'inverse à chaque paire. Les fenêtres du wrapper enveloppent celles du moteur; les 20 paires et les 40 exécutions ne se chevauchent pas. Le relevé initial indique huit CPU accessibles, une charge à une minute de 0,258 et aucun moteur/encodeur/profileur détecté. Les huit relevés ponctuels pendant ou autour de la campagne montrent au plus un moteur, appartenant au run attendu; cinq d'entre eux renseignent une charge comprise entre 4,855 et 5,523. Cela appuie l'isolement demandé, sans constituer une surveillance continue de toute charge externe.

## Limiteur et limites de l'explication

Le profil séparé commence après le dernier run de livraison. Son lanceur attend `PROFILE_ROUTE_BEGIN`, identifie le PID Godot enfant 3257986 et échantillonne cinq secondes avec `pidstat`. La copie de sonde ne diffère que par cette ligne de journal; le wrapper est identique. Le run Normal ON candidat termine avec codes 0 et le même ensemble de sources que les runs candidats. Son timing n'entre dans aucun résultat ci-dessus.

Dans cette fenêtre, le processus consomme en moyenne 514,4% CPU; les huit threads llvmpipe totalisent 478,4%, soit environ 93,0% du CPU du processus. Le thread principal est à 32,4%. Le travail CPU observé est donc largement consacré au rendu logiciel. Ce profil décrit seulement le début du trajet candidat Normal ON. Il ne localise pas une fonction graphique précise, ne profile pas la baseline et ne démontre pas que la réduction de triangles explique à elle seule la différence entre versions. La fenêtre du ticket 09 n'est pas utilisée pour attribuer un gain du ticket 10.

La revue géométrique indépendante rapporte un décor passant de 60 644 à 42 068 triangles construits, avec les autres catégories inchangées. C'est cohérent avec une charge de décor réduite, mais ce n'est ni un comptage des triangles effectivement rendus à chaque station ni une attribution causale de la baisse des intervalles. Les p50/p95 plus courts constituent ici l'observation étayée; la décomposition exacte du gain reste inconclusive.

Les quatre groupes restent séparés. Aucune différence ON/OFF entre groupes n'est présentée comme une activation appariée dans le même run. Les 24 selfchecks, le diagnostic de l'outil, le profil, les missions, les captures et les anciens timings du ticket 09 sont exclus des chiffres de livraison.

La comparaison utilise les deux projets source instrumentés, lancés avec le même binaire Godot; elle ne compare pas deux exécutables exportés release. Le test du binaire exporté reste un smoke test séparé et ne démontre aucune performance release.

Toutes ces mesures sont des intervalles wall-clock entre callbacks `_process` sous Linux/X11, Godot 4.7.2 Compatibility, llvmpipe et fenêtre 1280×720. Ce ne sont pas des temps GPU. Aucun résultat Windows, GPU joueur, 1080p ou 60 FPS n'est validé; même les médianes p50 candidates restent de 37,958 à 76,104 ms sur cet hôte.

## État postérieur et libération

Le parent a publié les outils dans le worktree après les 40 runs, le profil et son export. Le contrôle live a détecté les trois remplacements `tools/probe_sector_power.gd`, `tools/prove_sector_power.py` et `tools/selfcheck_sector_power.py`; leurs nouvelles empreintes correspondent exactement à `published-tool-identity.json` et aux outils figés de cette campagne. Trois outils de géométrie ont aussi été ajoutés selon ce manifeste. Aucun des autres fichiers du snapshot candidat n'a changé lors de ce contrôle. L'identité complète du worktree actuel avec les sources mesurées n'est donc pas affirmée. Cette publication postérieure ne change pas les empreintes avant/après conservées par les 40 runs et le profil.

Le premier contrôle live ayant signalé cette divergence est conservé dans `perf-audit/provenance-initial-live-check.json`. Le contrôle final `provenance-audit.json` conserve explicitement `candidate_all_manifest_sources_match_live_files: false` et vérifie la correspondance précise de ces trois remplacements documentés; il ne masque pas la divergence.

Audits relançables, sans moteur : `python3 .cstack/orchestrate/silo9/issue10/perf-audit/audit_campaign.py` et `python3 .cstack/orchestrate/silo9/issue10/perf-audit/audit_provenance.py`. Les deux ont terminé avec code 0. Le second contrôle live dépend de l'état post-publication décrit ci-dessus; des commits ou ajouts documentaires ultérieurs peuvent le faire diverger, sans invalider les manifests historiques.

Aucun moteur, encodeur, profil, benchmark ou descendant lancé par cet agent pendant les deux phases. Aucun worktree ni outil de mesure modifié. Écritures limitées à `perf-tool-review.md`, `perf-review.md` et `perf-audit/`. Tous les processus de cette revue sont terminés; le périmètre est libéré au parent.
