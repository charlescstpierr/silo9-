# Revue indépendante de publication — ticket 7

**PASS dans le périmètre publication. Aucun blocage concret relevé.** La documentation décrit correctement les preuves disponibles et leurs limites. Cette revue ne réexécute ni Godot, ni le film, ni les mesures de performance.

Périmètre lu : delta README, `docs/tickets/07-ads.md`, les trois nouveaux outils complets, les rapports indépendants code/protocole, natif, art et performance, leurs manifestes et les preuves pertinentes. La passe de commentaires et deslop ne relève ni commentaire narratif à retirer, ni contournement, ni code mort actionnable. Les deux docstrings précisent le contrat externe X11 et la nature synthétique des tests ; elles sont justifiées. Aucun changement de style ou de code proposé.

## Contrôles effectués

- Les **303 entrées** de `docs/tickets/media/07/SHA256.json` correspondent toutes aux octets et empreintes des fichiers publiés. Aucun fichier supplémentaire sous ce dossier, hors le manifeste lui-même.
- Les 9 liens du README et les 11 liens du rapport pointent vers des destinations existantes ou des URL externes. Les chemins privés dans les rapports et scripts archivés restent de la provenance, explicitement annoncée dans le rapport principal ; les commandes reproductibles utilisent les outils publics.
- HEAD observé : `1f36f01eea2e5d34dafee7f46a665c013370cbb4`, branche `feat/issue-07-ads`. Aucun diff de production/tests depuis ce HEAD. Pour chacun des manifestes rendu et film, les **192 empreintes source** concordent avec le disque et les objets Git de cette révision. Les fichiers UID générés non suivis ne changent pas cette source suivie.
- Les 39 logs de la campagne initiale (import et 38 suites) concordent avec leurs empreintes, sorties 0 et absence des diagnostics techniques recherchés. Les trois logs post-retouche concordent aussi. La documentation distingue explicitement ces deux étapes et le déplacement visuel de 9 mm ; elle ne prétend pas une nouvelle campagne complète après cette ligne.
- Inspection : 18 tirs, 18 impacts, 603 dégâts, aucune panne de parcours. Film : huit tirs, huit impacts, 246 dégâts ; manifeste de décodage à sortie 0 et 480 images. Les deux parcours indiquent `performance_valid: false`. Ces données soutiennent le texte sans transformer le film fixe en benchmark.
- Les agrégats du tableau correspondent au JSON public des dix essais et au rapport indépendant : p50 médians 94,823/94,664 ms, p95 médians 119,371/113,132 ms. Le document garde les limites llvmpipe, variation, rendu depuis les sources, fenêtres hors profilage et variation de volume visible. Aucun objectif matériel n'est déclaré atteint.
- Lecture des sauvegardes natives, options, journal de parcours et sorties : les valeurs citées de munitions, énergie, cellules et options concordent. La planche native des huit captures acceptées montre le jeu et les poses annoncées. Les tentatives invalidées restent identifiées comme telles.
- Aucun dossier `user-data` copié. Les dix sauvegardes natives publiées contiennent seulement les champs du jeu ; mémoire conversationnelle et faits sont vides. Les deux configurations de conversation ont endpoint et modèle vides. La recherche de clés privées, jetons fournisseurs/GitHub, URL avec identifiants et champs secrets non vides dans les 186 fichiers textuels publiés ne trouve aucune correspondance. Les chemins locaux Ubuntu sont des chemins de provenance, pas des identifiants secrets.

## Identité des outils et portée

Les outils publics sont identiques aux drafts finaux relus :

- `tools/probe_ads.gd` : `a0322c3f6e7186033dc97763c082a20dc50537d1fa6a9d13519cd6ede956a56d`.
- `tools/prove_ads.py` : `9e480f622584876b83a9413ca50ca07b75b0006e4433cef71c211e0655e44386`.
- `tools/selfcheck_ads.py` : `4dc92d3322eb247028df620301a8717eb6fe3134ce9b6e2f36ee72c426d88ef3`.

Le film archive bien la sonde `bce35a3a48b04717976bf15844c08b892bd70386eff63829a11c0f6f11df6985`, antérieure à la seule attente de disponibilité ARC. Ce delta a été lu : il ne change ni quotas ni assertions. Le texte distingue cette version de la sonde de performance a0322. Les labels corrigés sont séparés des données de jeu. Le log public des selfchecks installés rapporte 16 tests verts ; cette revue le lit sans revendiquer leur réexécution.

Empreintes des documents examinés : README `44aaf345ef66c284a5c9aac99657fc3c9b5ec645c2a4c7c8bca9461aeefb2e03`, rapport ticket `d12340c0bdb42b3319169f6dd5e4ed9b30587459d74ac9692172ac14f97e0e17`, manifeste 303 entrées `bb817e5c98590a318cbba30eb9218c2ec535daa8bb415e902e0fc1951482f878`.

Les limites proches des murs, Windows non exécuté, absence de manette physique, absence de GPU cible et absence de lecture/écoute continue restent correctement annoncées. Aucun constat de cette revue ne valide la qualité Fortnite ni une fréquence de 60 images/s.

Seule écriture : ce rapport. Aucun runtime, ffmpeg, commit, descendant ou worktree créé. Worktree observé : `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-07`. Tous les fichiers sont relâchés au parent ; aucun processus persistant lancé par cette mission.
