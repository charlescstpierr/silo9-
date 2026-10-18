# Correction des légendes de preuve ADS

Périmètre : présentation du seul `probe_ads.gd` privé. Aucun fichier du jeu, runner ou protocole modifié. Aucun commit, descendant ni processus Godot lancé.

Le texte des captures affichait la dernière étape traitée par `_process`, parfois l'étape hip précédente, et conservait « Arène isolée » après le retour au SILO. La capture fixe désormais sa propre légende avant le `frame_post_draw` existant. Une valeur de présentation indique le lieu réellement sélectionné par les téléportations existantes. Le film conserve son avertissement de cadence fixe et indique également le lieu et les commandes logicielles.

Le nom affiché est indépendant de `stage` : aucun échantillon de performance ni événement de protocole n'est renommé. Aucun délai ou frame supplémentaire n'est ajouté. L'original et le diff sont conservés dans ce dossier.

Contrôles statiques exécutés :
- journey_exact: PASS.
- stage_assignments_exact: PASS.
- await_statements_exact: PASS.
- check_statements_exact: PASS.

Hashes SHA-256 :
- `label-fix-original-probe.gd` : `5cc699787c2ba306a8c4d9563edda4b9beb31cd1accb6b1b346201ffb9ad4b75`.
- `probe_ads.gd` : `bce35a3a48b04717976bf15844c08b892bd70386eff63829a11c0f6f11df6985`.
- `label-fix.patch` : `15708d457edc1b69a83a5daaf9459740d00be449d2417ef3669da893642fda71`.
- `prove_ads.py` : `9e480f622584876b83a9413ca50ca07b75b0006e4433cef71c211e0655e44386`.

Le rendu réel et la compilation restent à vérifier par le parent, propriétaire du runtime. Cette correction de texte suit l'exception de présentation au TDD autorisée dans l'assignation. Aucun verdict visuel n'est revendiqué.

Contexte source : `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-07`, branche `feat/issue-07-ads`, head `1f36f01eea2e5d34dafee7f46a665c013370cbb4`. Ce worktree n'a pas été modifié. Aucun worktree créé. Tous les fichiers et processus de cette assignation sont libérés.
