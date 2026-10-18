# Ticket 09 : tests seuls, gel avant implémentation

Skills lus : cstack runtime/base, cstack-agent et TDD. Aucun descendant. Branche `feat/issue-09-lighting`, HEAD `e5b0bafa7b8bad369e6767a908b1d8391343b9f2`.
Worktree : `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-09`. Seuls les huit fichiers de tests ci-dessous sont écrits. Aucun script de production, data, tools, projet, commit ou push. UID générés conservés. Worktree relâché ; aucun processus moteur encore détenu.

## Exécution réellement observée

`./tools/godot.sh --headless --path . --editor --import --quit` : import final sans SCRIPT ERROR, Parse Error ou ERROR. Une première invocation avait fourni le mauvais chemin relatif après le chdir du wrapper ; elle est exclue et corrigée, sans être comptée comme rouge.

Depuis le worktree, environnement `XDG_DATA_HOME=<racine>/.cstack/orchestrate/silo9/issue09/tests-user-data` isolé :

```sh
./tools/godot.sh --headless --path . --script tests/<nom>.gd
```

| Suite | Sortie | Rouge observé sur base |
|---|---:|---|
| test_lighting_composition | 1 | API effets réduits et neuf sources nommées absentes |
| test_lighting_alarms | 1 | API effets réduits et neuf sources nommées absentes |
| test_lighting_settings | 1 | Option booléenne explicite absente dans vrai Main |
| test_sector_power_effects | 1 | Nouvelle composition par identité différente de la base |
| test_sector_power_commands | 1 | Source maintenance nommée exigée, absente |
| test_world | 1 | Ancien spot à ombre encore présent dans World |
| test_flashlight_input | 2 | DISPLAY REQUIRED ; exclusion headless, **pas un rouge prouvé** |

Logs et commandes exactes : `tests-red-author/*.log`, `tests-red-author/results.json`. Pas d'erreur de syntaxe ni d'accès invalide observée. Les logs des suites modifiées après premier passage ont été remplacés par leur nouvelle exécution avant gel. Pas de revendication de vert : production absente, assertions au-delà des guards pas encore exercées. Le parent doit reproduire le rouge, puis lancer la suite input sur X11 (dummy renderer accepté pour comportement ; aucune preuve visuelle ainsi obtenue).

## Contrats ajoutés

- `lighting_fixture` dérive du fixture courant réel ; aucun mock. Identifiants de domaine choisis dans accepted.md. Le temps avance par `_process(delta)` des consommateurs et de World, leurs véritables chemins existants ; aucun timer de test parallèle. Les autres simulations sont gelées.
- Composition : néon effectivement variable pendant cycle complet, variation isolée du voisin, même gain dans matériaux réellement rendus, matériau non partagé avec objets de quête, option réduite stable, colosse neutralisé, priorité coupure dans les deux ordres qualité/courant, restauration et deux fins.
- Alarme : source réelle et lentille synchrones, immédiatement visible hors tension, Normal/Low, extinction après durée, ON et fin N-7, refresh idempotent, cooldown conservé, option réduite plateau stable, 100 cycles sans remplacement de nodes/materials/Omni. Aucun spot World autorisé.
- Réglages : vrai widget et bouton Appliquer, persistance booléenne settings.cfg, faux types rejetés, défaut false, indépendance shot_light/budget, application effective au monde nouveau/chargé, pas de champ gameplay schema3 ajouté, refus global d'Apply sur endpoint invalide.
- Input (X11 requis) : F physique et R3 dans deux dispositions, répétition ignorée, énergie0, pas de bruit/découverte, pose camera et masque1, HUD ON, budget d'ombre via Main Normal/Low, refus en modales/curseur libre/mort, reprise F maintenu et réarmement après relâchement, pause conserve, chargement/nouvelle partie OFF.

## Assertions anciennes migrées précisément

- `test_sector_power_effects.assert_lights` : neuf Omni conservées ; indices 0..5 et énergies esthétiques codées remplacés par identités plafond/réacteur/alarme. **Amplitudes de référence capturées réellement par qualité avant coupures**, puis comparées après cycles pour conserver détection de dérive. Alarme exclue de politique alimentation principale. Option réduite appliquée si disponible pour rendre la référence stable ; le néon variable est couvert séparément. Le spot World supprimé est remplacé par assertions de plafonds dans les deux qualités ; lampe Player et son ombre ont leur suite réelle. Test colosse sélectionne les plafonds coupés, pas les alarmes autonomes via z. Teinte finale exclut alarmes de sécurité. Matériaux, ventilateurs, sons, circuits, ennemis de fin et restaurations restent vérifiés.
- `test_sector_power_commands` : l'observateur cherche le plafond Maintenance nommé plutôt que toutes les Omni à z secteur (alarme autonome). Assertion préalable de présence évite un callback vide. Toutes les assertions de transaction/réentrance/révision/sauvegarde, commandes physiques, bruit, cooldown, sas, collisions capsule et occupation joueur/robot sont intactes.
- `test_world` : assertions de visibilité de `art.shadow_key` remplacées par absence de shadow_enabled sur les lumières de World en Low et Normal. Le budget d'ombre porté par Player est vérifié séparément. Résolution, textures, mission, scan obligatoire, porte/réparation, ARC, trajet capsule, fin et comportement ennemi restent inchangés.

## Limites et suite parent

Le builder devra classer `test_flashlight_input.gd` dans la branche X11 de `tools/verify.sh` ; fichier outils hors de ma propriété. La présence matérielle d'une lampe à ombre n'est pas une preuve de qualité de ses pixels : captures/rendu parent nécessaires. Aucun GPU joueur, FPS ou comportement Windows testé. Le signal du colosse, ses sons et les interactions natives complètes restent couverts par les suites/parcours voisins et la campagne parent.

SHA256 des huit fichiers gelés :

- `tests/lighting_fixture.gd` : `7314110ec6c045cc64a5cd3f3ff5520f00d59bb342786b8126c06ef82d052448`
- `tests/test_lighting_composition.gd` : `f76d6852901b12efad9812493bfd5cf80e4d622092b5fccd7b38e784ea062f34`
- `tests/test_lighting_alarms.gd` : `f22ce6e4f1ba938d324364251611563b33d56f0fd7e52a5f3bf5909cd4789d97`
- `tests/test_lighting_settings.gd` : `19675e810f9417cb2bd6b95afbae9ca73f2595c7bc8d90ad87eb5e4351a35846`
- `tests/test_flashlight_input.gd` : `9b51fdbadfb9b41ab42290a1f625214b134d7fd65b0eff806f0897103f496425`
- `tests/test_sector_power_effects.gd` : `7ad768d657f73003c62cb989bdcddb9838b5e04080e554cf929913f9616de61f`
- `tests/test_sector_power_commands.gd` : `0ead73ecea6af19fb2f77b5e802a82e54a99cab60a34d2f139c1986d714408ca`
- `tests/test_world.gd` : `b7712cef26ef65a972713faeb03e8ce862192a35e4b4f6b9baf82072f0c05657`
