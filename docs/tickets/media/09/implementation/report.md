# Ticket 09 — implémentation gelée pour revue

Les neuf sources fixes, le néon Maintenance, les alarmes autonomes et la lampe du joueur sont intégrés. Les sept suites du rouge parent et dix suites voisines passent sur le diff final. Aucun test gelé n’a été modifié. Aucun commit, push, PR, descendant ou modification des outils de preuve.

## Périmètre et résultat

Worktree : `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-09`.
Branche : `feat/issue-09-lighting`. HEAD inchangé `896f0447d5f3ba94a464cdae96735228bfd15368`.

- `scripts/world.gd` : tableau typé privé de neuf `Luminaire`, rôles CEILING/REACTOR/ALARM et alimentations MAIN/AUTONOMOUS, sources nommées, origine commune de source et diffuseur. `lights` reste le véritable tableau des neuf Omni. Le composeur détient seul énergie, couleur et émission des luminaires. Seuls le néon et les deux alarmes sont recomposés par frame; les transitions font la composition complète. Les matériaux sectoriels ordinaires restent dans PowerMaterials. Balisage autonome limité aux bandes existantes du passage central.
- `scripts/world_art.gd` : retrait du spot sectoriel, de ses états et de `update_focus`. Suppression des diffuseurs doublonnés et transfert de l’anneau supérieur du réacteur au binding dédié. Les boîtiers existants restent, avec un boîtier identique ajouté au Refuge.
- `scripts/data/power_consumers.gd` : horloges, sons et cooldown préservés. Retrait des écritures concurrentes de visibilité des lentilles. Priorité de process -1 pour faire expirer les horloges avant la composition World du même frame.
- `scripts/player.gd` : Spot `Flashlight` fixé à la caméra, masque1, F/R3, verrou de pression maintenue, commande refusée inactif/mort/curseur libre. OFF au nouvel acteur et à la mort, conservé en pause. Aucune mutation batterie, bruit, perception ou schéma de sauvegarde. Petit boîtier géométrique, couche2. Une ombre en Normal, zéro en Low.
- `scripts/main.gd` : réglage booléen strict « Réduire les variations lumineuses », appliqué au monde et persisté dans settings.cfg, indépendant de shot_light/budget. Qualité appliquée à la lampe, aide F/R3 et HUD LAMPE ON. Validation Apply identique même si Main est ouvert sans monde.
- `tools/verify.sh` : seule addition du test flashlight à la branche X11.

## Rouge → vert et contrôles

La preuve rouge préalable appartient au parent : `../tests-red-parent/gate.json`, passed=true, sept rouges sémantiques. Les huit SHA256 gelés sont recoupés dans `freeze.json` et tous inchangés.

Import initial exécuté avec le binaire réel4.7.2 :

```sh
.tools/Godot_v4.7.2-stable_linux.x86_64 --headless --audio-driver Dummy --path .worktrees/silo9-issue-09 --editor --import --quit
```

Sortie0, aucun Parse Error/SCRIPT ERROR/ERROR, `import.log` (commande réellement lancée depuis le worktree avec chemins relatifs équivalents).

`results.json` conserve la première passe : six suites vertes, `test_lighting_settings` rouge avec exactement `FAIL: Refused Apply cannot change accessibility preference`. Le test crée Main avec boot_world=false; l’ancien guard sautait Dialogue.configure quand dialogue était null. La correction crée une instance de Dialogue seulement si absente avant Apply puis appelle son configure existant, sans nouvelle validation ni requête réseau. `_start_run` retire et queue_free toute instance valide avant de créer celle liée au nouveau RunState. Le fichier dialogue.gd reste inchangé. `test_lighting_settings-final.log` prouve le refus et les scénarios new/load après correction.

Les commandes exactes des17 suites finales et leurs sorties0 sont dans `results-final.json`. Environnement : DISPLAY=:100, XDG_DATA_HOME isolé dans implementation/user-data. Aucun moteur simultané.

| Suites | Runtime | Résultat |
|---|---|---|
| lighting_composition, lighting_alarms, lighting_settings, sector_power_effects, sector_power_commands, world | headless + audio Dummy | 6 sorties0 |
| flashlight_input | X11 + rendering-driver dummy + audio Dummy | sortie0 |
| journey, sector_power_state, sector_power_dialogue, dialogue, state | headless + audio Dummy | 5 sorties0 |
| player, shot_settings, ads_settings_input, ads_transitions, ads_geometry | X11 + rendering-driver dummy + audio Dummy | 5 sorties0 |

Chaque nom correspond à `tests/test_<nom>.gd`. Journaux : `test_<nom>-final.log`. Recherche finale sans occurrence de FAIL:, ERROR:, SCRIPT ERROR ou Parse Error. `test_journey` rapporte `failures=0 travelled=184.7m simulation=40.7s shots=15 health=77`. Cette mission est un test simulé, pas une capture de parcours rendu.

États réellement couverts : cycle complet du néon et matériau rendu synchrone; voisin/objet de quête isolés; deux ordres courant/qualité; coupure prioritaire sur colosse/fins; alarmes immédiatement allumées hors tension, éteintes à expiration/ON/N-7; cooldown et refresh idempotents;100 cycles sans remplacement de nœuds/matériaux/lumières; option réduite stable; F physique/R3 dans deux dispositions, repeat, modal/held-resume/cursor/death; batterie0 sans découverte; pause/load/new; schéma3, mission, sas et collisions.

## Adaptations de conception

- Les vrais diffuseurs des boîtiers existants sont à y4.68; C proposait y4.9, où une deuxième ancienne barre se trouvait déjà. Une seule barre à y4.68 est maintenant construite, sa source à y4.56,12cm dessous, même x/z. Géométrie du boîtier réutilisée. Cette cohérence est établie dans les coordonnées, pas encore validée par pixels.
- L’anneau réel à y2.5 remplace le luminaire de réacteur sans diffuseur associé; sa source est à y2.38. L’orbe de mission garde son matériau autonome.
- Le gain d’alarme démarre à0.2 pour un signal immédiatement visible, monte vers1 en0.15s et s’arrête sur l’horloge existante; l’option réduite utilise1. Le gain colosse devient1 en mode réduit, conformément à accepted.md qui prime sur la première proposition C.
- Pas de validateur général pour la table privée codée dans World. Aucun catalogue externe ni Node gestionnaire ajouté.

## Passe deslop

Les six diffs ont été lus intégralement. Les anciens `shadow_key`, `_shadow_light`, `update_focus`, `focused_z`, `focus_color`, `_light_colors`, `_light` et `_powered_at` sont supprimés avec leurs appelants. Aucun commentaire ajouté. La forme privée Luminaire regroupe la donnée artistique, l’alimentation et le binding sans couche intermodule. Les gardes InputMap sont nécessaires aux tests Player/World isolés sans Main configurant les actions. Aucun autre poids incertain identifié; aucune suppression sans contrôle associée. Les17 suites finales ont été exécutées après ces suppressions et `git diff --check` passe.

## Limites et libération

Aucune capture/vidéo, mesure de performance ou exécution Windows revendiquée par ce builder. Les tests X11 utilisent le renderer dummy et ne prouvent pas les ombres rendues. Les captures comparatives et la campagne performance du parent restent nécessaires, notamment le relief lampeOFF, les silhouettes OFF/batterie0, le coût de l’ombre mobile et la lisibilité HUD. Le glow reste inchangé OFF. Aucun asset tiers ajouté; qualité Fortnite non revendiquée.

Le runtime et le worktree sont relâchés après ce rapport. Aucun Godot, ffmpeg ou descendant lancé par ce builder n’est encore actif; Xvfb parent n’a pas été touché. Les UID non suivis sont préservés. Diff exact dans `diff.patch`; hashes des six fichiers finaux et des tests dans `freeze.json`.
