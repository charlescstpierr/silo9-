# Revue indépendante du ticket 09

Verdict **PASS pour le code et les commentaires du diff gelé**. Aucun défaut concret trouvé dans les chemins examinés. Ce verdict ne valide pas les pixels, les performances ni l’exécution Windows.

Le reviewer n’a écrit aucune ligne du produit ou des tests. Il a appliqué cstack-agent, no-comments/comment-reviewer et blast-radius, sans descendant. Le seul fichier produit est ce rapport.

## Périmètre et identité

Worktree `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-09`, branche `feat/issue-09-lighting`. La revue a commencé sur les six modifications de `896f0447d5f3ba94a464cdae96735228bfd15368`. Le parent les a committées pendant la lecture. HEAD observé ensuite `e691f5fcea4824a379f362e85e69baa325a0b0bb`.

Un script Python indépendant a recalculé les SHA256 des six fichiers de production et des huit fichiers de tests. Tous correspondent à `implementation/freeze.json` et `tests-red-parent/gate.json`. `git diff 896f044 --check` passe. Le diff comporte six fichiers, 201 insertions et 85 suppressions. `run_state.gd`, `dialogue.gd` et `enemy.gd` n’ont aucun delta par rapport au commit de tests.

Contrat lu dans `design/accepted.md`, gate rouge et rapport builder lus. Le reviewer a lu le diff entier, les fonctions connectées de Player/Main/World/WorldArt/PowerConsumers/PowerMaterials/Dialogue, les fixtures et les quatre nouvelles suites comportementales. Les références de lignes ci-dessous sont relatives au worktree.

## Transitions et rayon d’impact

Le fait principal est la propriété unique de la composition des luminaires. `World._compose_lights` écrit la lumière et le matériau du même binding, avec le gain nul appliqué après les effets. Il lit l’unique horloge de PowerConsumers pour les alarmes. Ce fait est établi par traçage statique, niveau 3 du playbook blast-radius. Je n’ai pas exécuté le moteur indépendamment, conformément à la réservation du runtime au parent.

- `scripts/world.gd:629` compose courant, qualité, néon, colosse et fin. `scripts/world.gd:647` impose le gain nul après ces modificateurs. Une transition de qualité ou de fin ne peut donc pas rallumer le plafonnier d’un circuit OFF. Chaque luminaire crée son matériau dédié à `scripts/world.gd:596`; les objets de mission et PowerMaterials ne détiennent pas ce matériau.
- `scripts/world.gd:549` commute le circuit, applique son état, arme éventuellement l’alarme, puis émet `state.changed`. La connexion à `refresh` à `scripts/world.gd:98` recompose immédiatement après armement. `scripts/data/power_consumers.gd:134` coupe l’alarme au retour ON; `scripts/world.gd:569` la coupe en fin N-7. `scripts/world.gd:641` est le seul writer de visibilité de sa lentille. Aucun ancien writer concurrent n’est conservé.
- `scripts/data/power_consumers.gd:22` donne la priorité -1 à l’horloge; `scripts/data/power_consumers.gd:161` la décrémente avant la composition World de priorité normale. World actualise toujours les deux alarmes à `scripts/world.gd:488`, même quand le néon devient stable. L’absence d’une dernière image rouge persistante est cohérente avec cet ordre; le scheduler réel n’a pas été rejoué par ce reviewer. Les tests lus appellent eux-mêmes Consumers avant World.
- `scripts/world.gd:632` limite la mise à jour continue au néon et aux deux alarmes. Les transitions appellent la composition complète. La boucle n’alloue pas de nœud, de mesh ou de matériau. Les neuf lumières sont créées une seule fois. Le batch statique précède la construction des lentilles à `scripts/world.gd:91`, donc il ne détruit pas leurs références et ne fusionne pas les matériaux animés. Le coût des setters et des appels de dessin reste à mesurer.
- Le spot sectoriel et ses appelants sont supprimés ensemble. Une recherche sur `scripts`, `tools` et `tests` ne trouve plus `shadow_key`, `update_focus`, `focused_z`, `focus_color`, `_powered_at` ou `_light_colors`. Les neuf Omni ont leurs ombres désactivées à `scripts/world.gd:624`. Le seul nouveau spot d’exploration appartient à Player, masque 1, et `scripts/main.gd:712` lui applique la qualité. Le budget déclaré est au maximum une ombre en Normal et zéro en Low. La présence et la cohérence d’une ombre visible exigent encore la preuve rendue.

## Entrées, réglages et mission

- `scripts/player.gd:190` refuse la commande si le joueur est inactif, mort ou si le curseur est libre. `scripts/player.gd:364` refuse l’écho et verrouille la pression jusqu’au relâchement. `scripts/player.gd:147` reprend l’état physique de F/R3 lors de l’activation après une modale. Les chemins réels Main passent par `set_active`, après création du joueur et association du RunState; aucun appelant trouvé ne passe un joueur sans state ou sans lampe construite.
- `scripts/player.gd:148` éteint la lampe à la mort; une pause avec santé positive conserve son état. Main recrée Player lors de New/Load à `scripts/main.gd:297`, ce qui rétablit OFF. La commande de lampe ne dépense aucune énergie, n’émet aucun bruit et ne découvre aucun relais. Les appels scan et les changements de mission restent distincts.
- F physique et R3 sont ajoutés à `scripts/main.gd:655` et `scripts/main.gd:675`. `set_layout` conserve ces actions pendant les changements WASD/ZQSD. L’aide et le HUD lisent l’état réel du joueur.
- `scripts/main.gd:487` accepte uniquement un booléen pour la nouvelle préférence. Apply configure le fournisseur avant de muter les options et de sauver le fichier. Quand Main ne possède pas encore Dialogue, `scripts/main.gd:430` construit le même objet et utilise son validateur existant. `Dialogue.configure` ne dépend pas de RunState et n’envoie aucune requête HTTP. `_start_run` annule, détache et libère cette instance avant de créer le dialogue lié au nouveau RunState. Aucun chemin concret de requête sans state trouvé.
- L’option réduite remplace par 1 le gain de colosse, stabilise le néon et l’enveloppe d’alarme. Elle laisse le son, le déclenchement du colosse, shot_light et effects_budget inchangés. Les circuits OFF restent prioritaires.
- Le schéma de sauvegarde et les règles de mission ne changent pas. `World.refresh`, les actions du relais/cœur, les barrières et le contrôle d’occupation des sas sont conservés. La lampe et la préférence graphique ne sont pas ajoutées à la sauvegarde de partie.

## Preuves lues et limites

Les 17 journaux `implementation/test_*-final.log` ont été inspectés par ce reviewer. Ils rapportent zéro échec; aucun marqueur FAIL:, ERROR:, SCRIPT ERROR ou Parse Error. `test_journey` rapporte 184,7 m, 15 tirs et santé 77. Ces tests ont été exécutés par le builder, pas par le reviewer.

Sept logs contiennent des avertissements ObjectDB à la fermeture, de 2 à 6 instances. Ils ne sont pas masqués. Cette revue n’en attribue pas la cause et ne prouve pas l’absence de fuite. Le parent possède l’investigation runtime et les preuves de durée de vie.

Aucun Godot, ffmpeg, benchmark ou jeu Windows lancé par ce reviewer. Aucune capture ni vidéo inspectée pour ce rapport. Les preuves attendues avant livraison restent les parcours rendus, l’ombre réelle de la lampe, la lisibilité des secteurs OFF/Low, l’expiration visible des alarmes et la mesure du coût graphique.

## Commentaires et libération

Aucun commentaire ajouté ou modifié dans les cinq scripts; le shebang du shell est conservé. Aucun commentaire de contrainte, contournement commenté, narration périmée ou suppression de lint actionnable trouvé. Zéro suppression, zéro restauration, zéro relance et aucun encodage de contrainte proposé. Aucun correctif de code demandé.

Le reviewer n’a créé aucun worktree, processus persistant ou descendant. Aucun fichier source, test, UID, commit, branche distante ou PR modifié. La tranche de revue est libérée.
