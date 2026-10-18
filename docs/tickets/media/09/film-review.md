# Ticket 09 — revue indépendante des parcours natifs et du film

Verdict : **PASS borné aux deux parcours instrumentés et aux douze images examinées**. Aucun constat bloquant dans cette tranche. Ce verdict ne valide ni la fluidité, ni le confort des mouvements, ni un GPU joueur, ni Windows. Le film n'a pas été visionné en continu.

Source examinée : `653e2a79c7f36e9ac7422335c85cef3b937ed0f9`, branche `feat/issue-09-lighting`, worktree `.worktrees/silo9-issue-09`. Application de `cstack-agent` et `prove-it-works`. Revue en lecture seule, sauf ce rapport ; aucun descendant, moteur, ffmpeg, test ou calcul de performance lancé.

## Parcours recoupés

Lecture directe de `native-mother-final/manifest.json`, `native-n7-low-final/manifest.json` et des champs pertinents de leurs `journey.json`, puis des deux `engine.log`. Les deux manifests donnent le même HEAD, `exit_code: 0`, aucune erreur de validation et les mêmes empreintes source/outils avant et après. Les empreintes actuelles de player, main, world, world_art et x11_input correspondent aux deux manifests. Les empreintes actuelles du wrapper et de la sonde correspondent aussi aux empreintes enregistrées.

| Parcours | Qualité | Distance physique | Fin / phase | Santé finale | Combat |
|---|---|---:|---|---:|---|
| `native-mother-final` | Normal | 193,182 m | MÈRE / 4 | 100 | six ennemis vaincus, 15 tirs |
| `native-n7-low-final` | Low | 187,371 m | N-7 / 4 | 70 | six ennemis vaincus, 15 tirs |

Chaque événement `flashlight_native_f` enregistre un appel OS réussi, intention et visibilité passant de false à true. Il précède le premier déplacement de mission dans la sonde et la première interaction dans les observations : 7 489 446 → 10 395 591 µs pour MÈRE ; 8 372 619 → 11 079 280 µs pour N-7. La sonde appelle `tools/x11_input.py key f`, lequel utilise XTest pour la pression et le relâchement. Il ne s'agit donc pas seulement d'un appel direct à `toggle_flashlight`.

Chaque parcours comporte 14 interactions E natives, dont **six bascules de disjoncteurs** : Maintenance puis Archives, chacune ON→OFF→ON→OFF. Les six entrées ont `native`, `aim_valid` et `changed` vrais ; le code vérifie également l'incrément de révision et le changement du prompt. Les deux journaux moteur terminent avec `failures=0`. Ils contiennent l'avertissement de VSync non prise en charge par le pilote, sans erreur de jeu.

Le déplacement passe par les actions Input `forward` et `sprint`, la physique et les collisions normales ; orientation et visée sont scriptées. Il n'y a pas de téléportation après `new_game` dans cette branche de la sonde. Les branches qui figent les acteurs sont réservées aux modes `lighting`/`lighting-perf`, et le retrait des ennemis au mode `perf`. Ici les scènes ne sont pas marquées `scene_inspection` : six ennemis vivants sont présents au départ (santé 65/35), puis leurs comptes diminuent jusqu'à zéro. La sonde vise et tire via les fonctions réelles du joueur, avec rechargement et soin automatique conditionnel. Les états FSM nommés des ennemis ne figurent pas dans ces observations : ce rapport ne prétend pas vérifier chaque transition de comportement.

La santé MÈRE reste à 100 dans les observations conservées : ce parcours ne démontre pas à lui seul un dégât reçu. Le parcours N-7 descend de 100 à 70 et démontre des dégâts au joueur avec acteurs de combat actifs. Les phases observées couvrent 0, 1, 2, 3 et 4. Scan et combat sont déclenchés par API du jeu dans la sonde ; seuls F et E sont prouvés au niveau OS ici.

La console finale est ouverte par E après retour physique au refuge. Le choix appelle ensuite `app._choose_ending(ending)` ; ce gestionnaire est bien celui des deux boutons dans `scripts/main.gd` (lignes 561 et 563 au HEAD examiné). **Aucun clic OS sur le bouton final n'est démontré.** Les deux fins sont établies par les journeys et les vérifications de la sonde, pas par la dernière image échantillonnée du film.

## Film et douze images réellement ouvertes

`native-film/recording.json` rapporte les sorties 0 du writer ffmpeg et du probe. `ffprobe.json` indique 1280×720, 15 images/s, 73,666667 s et 1 105 images lues. `decode.log` est vide ; la sortie 0 du décodage intégral provient du reçu parent transmis avec cette revue, elle n'a pas été réexécutée ici. Le film est sans audio ; le moteur utilise Dummy audio.

`native-film/extraction.json` conserve la commande `fps=1/6`, sa sortie 0 et sa session 48317. Les douze PNG `frame-01.png` à `frame-12.png` ont tous été ouverts avec `view_image`. Les repères ci-dessous sont la grille nominale à six secondes ; l'arrondi par défaut du filtre interdit de les présenter comme timestamps exacts des images source.

| Image / repère nominal | Observation directe |
|---|---|
| 01 / ~0 s | Image noire et curseur de démarrage ; aucune preuve du monde jouable à cet instant. |
| 02 / ~6 s | Refuge, axe vers Décontamination, D9 et mains visibles ; HUD santé/énergie/munitions lisible, lampe non signalée ON. |
| 03 / ~12 s | Entrée Maintenance, `LAMPE ON`, sol et parois éclairés localement ; cible centrale dégagée. |
| 04 / ~18 s | Pilier très proche masquant une grande part gauche/centrale ; monde encore visible à droite et HUD lisible. Cette image ne prouve pas une vue toujours dégagée. |
| 05 / ~24 s | Disjoncteur Maintenance ON, prompt E et tache de lampe très nets, sol lisible ; aucune grosse pièce de lampe ne masque le centre. |
| 06 / ~30 s | Passage vers Archives, énergie 80 et nouvel objectif ; plafond éclairé et zone sombre différenciés. |
| 07 / ~36 s | Archives OFF, N-7 visible à gauche ; disjoncteur hors tension éclairé par la lampe, prompt de rétablissement lisible. |
| 08 / ~42 s | Grille/paroi et terminal proches ; faisceau visible sur la paroi, arme et HUD encore identifiables. |
| 09 / ~48 s | Cœur, sentinelle et rampant visibles ; rechargement et bras occupent le premier plan. Preuve d'une pose de rechargement, pas de sa qualité animée complète. |
| 10 / ~54 s | Objectif de retour au refuge après récupération du cœur ; faisceau et volumes du Cœur lisibles, D9 09/36. |
| 11 / ~60 s | Retour en Maintenance, grande profondeur visible, lampe sur le sol et HUD stable. |
| 12 / ~66 s | Retour au refuge face à la console/paroi éclairée ; objectif de choix encore affiché. L'image n'affiche pas la conclusion. |

Les images 05, 07, 08 et 12 rendent particulièrement visible la lumière locale. Le HUD reste lisible sur les onze images de jeu. Les vues ouvertes ne montrent pas de nouveau boîtier envahissant le bas droit ; la vue très proche du pilier en image 04 et la pose de rechargement en image 09 limitent cependant toute affirmation générale sur le dégagement du champ. Aucun défaut propre à la nouvelle lampe n'est établi par ces deux occlusions. Les images seules ne démontrent ni marche continue, ni absence de scintillement, ni confort des mouvements. La marche est étayée séparément par le code et les journaux des parcours.

## Limites à conserver lors de la publication

- La session orchestratrice 27142 a rapporté 143 après `N7_LOW0`. Les deux manifests moteur, les retours enfants et le writer vidéo rapportent 0 ; le parent rapporte aussi un décodage intégral à 0. La cause du statut externe 143 reste inconnue. Ce rapport ne le transforme pas en succès global de session et n'attribue pas de cause à l'infrastructure.
- Les captures contrôlées des campagnes d'éclairage ne prouvent pas le déplacement. Cette revue concerne les deux parcours physiques et l'échantillon du film MÈRE ; aucune vidéo Low continue n'a été examinée.
- Rendu Linux X11 / llvmpipe sous Godot 4.7.2, aucun GPU cible ou exécutable Windows évalué. Les timings de ces parcours sont explicitement `performance_valid: false` et ne servent pas de benchmark.
- Aucun son audible, jeu humain, validation de confort, ni qualité « Fortnite » globale établi par cette tranche.

Seul fichier créé : ce rapport. Aucun worktree créé ou modifié par la revue ; aucune possession de runtime conservée.
