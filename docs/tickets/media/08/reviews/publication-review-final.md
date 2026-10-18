# Revue finale de publication — ticket 8

**PASS**, borné au HEAD `b1b77e34969c78d0319da166073bbb3b9953135a` sur `feat/issue-08-materials`. Aucun défaut concret restant identifié dans la publication examinée. La production de jeu est identique au commit exécuté `efc2a581fd329321a852507d775af6fcda0a9cb1` ; seuls README, attributs Git, outil public et documents/preuves ont changé.

Worktree : `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-08`. L'indépendance porte sur la publication, la documentation et l'outil, dont je ne suis pas l'auteur. Elle ne s'applique pas à la qualité du contrat de test que j'ai écrit ; le parent l'a relu. Aucun Godot, ffmpeg, benchmark, générateur, descendant, modification de production ou commit lancé. Seuls ce rapport et son JSON privé ont été écrits ; fichiers relâchés.

## Contrôles effectués

- Les **278 entrées** de `media/08/SHA256.json` concordent toutes avec les fichiers. **279 fichiers** avec le manifeste lui-même, tous suivis par Git ; aucune entrée manquante, aucun fichier supplémentaire non inventorié.
- Les **17 liens relatifs Markdown** du README et du rapport pointent vers des fichiers présents, notamment film, provenance, images, données brutes et audit. Les chemins historiques internes sont explicitement distingués des nouvelles commandes de reproduction.
- L'outil public porte le SHA `44ad5e220bfb29672a6e8e3a7683278316c62a1d3ed85758e0a71b708d4b9570`, identique à la sonde du film exécuté. Sa lecture complète était couverte par `publication-review-initial.md` ; aucune ligne de script n'a changé depuis. Les réserves ont été traitées : 30 fps imposés par la commande et vérifiés dans le fichier ; z5 pour les 17 PNG archivés, z8 pour l'outil public et le film ; variante historique référencée ; XDG isolé, timeout et commande MovieWriter/ffprobe fournis.
- Les JSON publiés indiquent 17 captures d'inspection et 13 captures film, six segments et 1 080 observations, aucune failure, quatre textures. Le hash MP4 correspond à son manifeste média. Le compte de 1 236 images / 41,2 s / 30 fps et les limites de visionnage sont cohérents avec le ffprobe enregistré et le rapport artistique. Aucun second visionnage ou décodage n'est revendiqué par cette revue.
- Les p50/p95 des dix runs ont été **recalculés depuis leurs intervalles bruts**, puis leurs médianes/min/max recalculés par version : chaque valeur égale le tableau publié et l'audit. Les dix runs déclarent huit impacts et 246 dégâts sans failure. L'audit publié contient effectivement 542 assertions passées ; je n'ai pas relancé son programme ni repris ces assertions comme 542 vérifications nouvelles de ma part.
- Le rapport décrit correctement le recouvrement des plages, l'absence de gain démontré, le rendu logiciel, la fenêtre centrale approximative du profil, la campagne interrompue exclue et les limites GPU/Windows/60 fps. Le compteur de ressources est distingué de la mémoire texture. Le marqueur `PERFORMANCE_PENDING` est absent.
- Aucun AVI, dossier user-data/userdata, fichier .env ou clé privée n'est inclus. Le scan des fichiers textuels contre des motifs courants de jetons et clés n'a trouvé aucune correspondance. Cette vérification n'est pas une preuve d'absence de tout secret possible sous une forme inconnue.

## Attributs Git et commentaires

`linguist-generated` est borné à `docs/tickets/media/08/**`, pour replier les preuves en revue ; il ne masque ni code de jeu ni rapport principal. L'exemption whitespace additionnelle vise exactement `docs/tickets/media/08/proof-fix/patch/cleanup.patch`. Ce fichier est octet pour octet le patch historique, dont les lignes de contexte commencent par espace puis tabulation. Les autres chemins gardent leur contrôle whitespace. `git diff --check efc2a58 HEAD` termine avec code 0.

Aucun nouveau commentaire trompeur ni suppression de contrôle détecté. Aucun changement recommandé au titre de no-comments, aucune suppression/restauration ou correction appliquée.

## Empreintes et portée

Les détails machine sont dans `publication-review-final.json`, dont le HEAD, les 17 liens, les hashes des quatre fichiers publics principaux, celui du manifeste global et les statistiques recalculées. SHA du manifeste publié : `20b3ec718d0f105468e3eece226b0d2cdea6b0fb522059a8266b8083ea0a9892`.

Le PASS concerne ce HEAD précis. L'archivage ultérieur de ce rapport ajoute une preuve documentaire ; il doit conserver les données examinées et mettre à jour l'inventaire des nouveaux fichiers sans prétendre que ceux-ci existaient déjà à ce HEAD. Cette revue n'autorise ni merge ni déploiement.
