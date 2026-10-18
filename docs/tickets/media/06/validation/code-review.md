# Revue indépendante du ticket 6

Verdict : **PASS pour le code et les preuves automatisées inspectées**. Aucun défaut concret à corriger identifié. Ce verdict ne valide ni les pixels, ni les gestes natifs, ni le coût de rendu, ni les exports, réservés au parent.

Acteur nonauteur : `issue06_code_review`. Branche `feat/issue-06-shot-feedback`, HEAD exact `fab9c19c749265104a67d8b5e87c620662a2c012`, base `0473efbc0d271ff73f89a1f0bd6a3d38e42c8aa6`, tests-only `88dc413ed15f72d20c6ef9388ebc5a770925a1dd`. Worktree `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-06`.

## Périmètre et méthode

Lecture de `design/accepted.md`, `tests-gate.json`, `implementation/report.md`, `implementation/result.json`, des 18 fichiers du diff complet base..HEAD et du code voisin. Dépendances suivies dans l'acceptation de tir, la machine de manipulation, la composition du rig, le mode UI, le remplacement du joueur et les tests existants de faisceau. Compétences cstack, blast-radius et prompt comment-reviewer appliqués. Aucun outil non suivi ni preuve visuelle en cours du parent utilisé pour ce verdict.

## Faits de sûreté vérifiés

- **Un seul tir réel et cadence conservée.** `scripts/player.gd:150` conserve refus, débits, cooldown, bruit et unique rayon. L'enveloppe ne rappelle ni `fire`, ni `intersect_ray`, ni `receive_hit`. `_event_shot` reste consommé par la physique, `scripts/player.gd:327`. Le FOV change, pas le transform caméra ni le calcul du rayon. Niveau : chemin tracé et preuves automatisées archivées, dont les assertions 28 + 39 dégâts, refus sans débit, rayon inchangé et point ARC fixe dans `test_shot_feedback` et `test_weapon_beam_motion`.
- **La présentation ne vieillit pas avant soumission.** `scripts/player.gd:520` capture la génération en pre_draw; post_draw acquitte cette génération, pas une éventuelle génération plus récente. `_process`, ligne 530, avance l'âge seulement après acquittement. Aucun vieillissement de l'enveloppe ne subsiste dans la physique. Même séparation dans `scripts/casing_pool.gd:113`. Niveau : chemin tracé et tests X11/dummy archivés. Ces tests démontrent les callbacks et états, pas une image visible.
- **Coupures et rig unique écrivain.** R et B acceptés appellent `_cancel_recoil`; HIDDEN coupe avant `apply_hidden_weapon`, `scripts/player.gd:225`. Les douilles survivent au changement d'arme. Inactivité, mort et téléportation purgent les effets et douilles. Le faisceau suit la bouche via `_update_view` sans modifier son impact. Les écritures du Slide restent dans `fps_rig.gd`, y compris son annulation immédiate. Niveau : chemin tracé et suites de transitions, masquage, manipulation et douilles archivées.
- **Repos FOV sans accumulation.** `scripts/player.gd:165` capture le repos uniquement au départ d'une impulsion inactive; la courbe réutilise cette base et `_cancel_recoil`, ligne 568, la restaure. La force zéro recompose immédiatement la base. Aucune orientation souris n'est écrasée. Niveau : code et assertions archivées aux FOV 60, 76 et 90, souris pendant retour, tirs coalescés et 24 cycles sans dérive.
- **Douilles bornées et décoratives.** `scripts/casing_pool.gd:52` réutilise un slot libre ou le plus ancien, réinitialise tous les champs mobiles et conserve les ressources. Capacité 8, budgets 0/2/8, TTL .8/2 secondes. Le pool top-level conserve le monde; aucune forme de collision ne peut bloquer le tir. Le balayage réutilisé est limité aux corps du masque 1. Normale nulle retire le slot; seules les surfaces de support peuvent le poser. Les slots posés ne lancent plus de rayon. Le TTL consomme le delta complet, le déplacement au plus 1/30 s. Niveau : source, chemins et tests de plafond, baisse de budget, intérieur solide, sol/mur/plafond, recyclage et cible derrière une douille. Le coût maximal est borné en nombre de requêtes, pas encore mesuré en millisecondes par cette revue.
- **Options appliquées à tous les propriétaires.** `scripts/main.gd:661` normalise nombres finis et enum; `_apply_settings`, ligne 403, valide l'endpoint existant avant les nouveaux champs. `_start_run`, ligne 284, retire les anciens propriétaires puis configure le nouveau joueur avant activation. Les callbacks renderer sont déconnectés à la sortie de l'arbre. Les préférences restent dans settings.cfg, hors schema 2. Niveau : chemins suivis et tests archivés des défauts, types invalides, NaN/Inf, Apply, Échap, refus, persistance, joueur courant, nouvelle partie et chargement.

## Intégrité des preuves et tests

Contrôles exécutés par ce reviewer, sans lancer Godot :

- Comparaison Git des quatre fichiers `shot_feedback_fixture.gd`, `test_shot_feedback.gd`, `test_shot_casings.gd`, `test_shot_settings.gd` entre tests-only et HEAD : aucun octet changé.
- SHA-256 des 17 entrées de `implementation/source-sha256.json` comparés au commit, au worktree et aux copies archivées : tous identiques.
- SHA-256 des 64 entrées de `implementation/evidence-sha256.json` recalculés : aucun écart.
- Inspection des logs des 33 suites et du journal final, exit enregistré 0 pour `DISPLAY=:100 ./tools/verify.sh`, aucun `FAIL:`, `SCRIPT ERROR`, `ERROR:` ou `WARNING:`. Commandes et logs sont sous `implementation/`.
- `git diff --check 0473efb..fab9c19` : succès.

Les modifications des anciens tests remplacent le nœud de flash renommé par le nœud réel approprié, sans relâcher distance ni condition de recul. La fixture de masquage conserve les effets avant de libérer son ancien rig; ses assertions restent inchangées. La route X11/dummy fournit les callbacks nécessaires aux anciennes suites temporelles. Aucun test existant supprimé ou assertion affaiblie trouvé.

## Limites et suite parent

Le raccord B depuis D9 est explicitement conservé : `fps_rig.gd:175` retourne en LOWER_ABORT après abaissement de la pose figée. `_recoil == 0`, le FOV au repos et le Slide remis à zéro ne prouvent donc pas que le poignet est revenu au repos. La pose précédente descend jusqu'à HIDDEN. Cela respecte le gel retenu dans la conception; le parent doit juger le rendu réel de cette continuité. Pas de finding présenté comme bug sans preuve visuelle contraire.

Le renderer dummy ne prouve pas la visibilité des départs sur pixels, la lisibilité des options, les clics XTest ou le coût llvmpipe. Les preuves de rendu, gestes natifs, comparaison de coût sans capture concurrente et exports restent dans la tranche parent. Aucun créneau runtime supplémentaire requis par cette revue statique, faute de scénario de bug concret à reproduire.

## Commentaires et libération

Aucun commentaire ajouté ou modifié dans le diff. Aucun constat actionnable issu du prompt comment-reviewer; aucun contrat, licence ou contrainte d'outil proposé à la suppression.

Seul fichier écrit : ce rapport. Aucun source/test modifié, commit, accès distant, descendant ou processus Godot lancé. Worktree conservé et **libéré par le reviewer**; runtime resté sous propriété parent.
