# Implémentation du ticket 10

Tranche terminée et runtime libéré le 2026-10-18T13:58:43.359577+00:00. Aucun commit, push, PR, descendant ni modification du serveur Xvfb. La validation globale du ticket reste au coordinateur.

Worktree : `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-10`. Branche `feat/issue-10-environment`. HEAD inchangé `0297cf78827e180a10b16648cf7e411499f531d4`.
Source modifiée uniquement : `scripts/world_art.gd`, SHA256 `c3a973b5774ba521a29deff13dd9234db260c5e0329a0ecfc20da3d53b866cf0`. Diff : `candidate.diff` (65 ajouts / 17 suppressions). Les UID non suivis préexistants sont conservés ; comparaison initial/final : seule ligne ajoutée au statut, `M scripts/world_art.gd`.

## Changement

Les répétitions longitudinales des trois secteurs sont retirées dans `_walls_and_deck`; les cadres glTF et les luminaires restent. Les parements communs des sorties sont remplacés par trois recettes privées appelées une fois dans `build`.

- Décontamination (`world_art.gd:191`) : grandes plaques crème, bande teal interrompue, profils steel fins et panneau réparé sombre au bord extérieur. Plafond libéré des chemins de câbles et conduites, vitres et machines conservées. Le premier rendu a précédé les deux autres recettes. Après retour du parent, ajout des profils et remplacement du rectangle sombre isolé pour éviter l'apparence d'un écran.
- Maintenance (`214`) : collecteur gauche, trois attaches espacées, deux stations de câbles, tôle de réparation et coulures localisées. Retrait des quatre cylindres de sol décoratifs. Établi, outils et luminaire existants déplacés textuellement dans la recette sans changement de placement. Grandes tôles orange à gauche, parement sombre à droite, joints et profils fins.
- Archives (`254`) : deux faces sombres par armoire et nervures crème périphériques, une nervure omise sur la baie gauche Z−46. Suppression des petites grilles et points cyan WorldArt. Bandes cyan World conservées devant le nouveau parement. Verticales de sortie amincies et reculées après inspection du texte narratif.

`static-method-identity.json` confirme l'identité textuelle des helpers matériaux, batching, qualité, sol/coques, refuge, cœur, rotor et consoles ; le bloc commun des six machines et le bloc atelier/luminaire sont également identiques. Aucun nouveau matériau, lumière, collider, état, interaction, API publique ou ressource. `base-candidate-file-identity.json` compare 141 fichiers relevés sources/tests/assets hors UID/imports : seul world_art.gd diffère.

## Réserves de placement

Les façades d'armoires sont centrées à |X|8,33, épaisseur0,02 ; nervures à8,325, épaisseur0,03. Leurs bornes X les plus proches du joueur sont8,32/8,31, à0,03/0,04m de la face solide8,35. Les marques d'abrasion tournent autour de X et restent à|X|8,31..8,315. Ce calcul depuis les placements n'est pas le verdict de l'outil géométrique indépendant.

Les nouveaux parements de cloison restent hors X±2,8. À Archives, leur face visible Z−53,725 se situe devant le solide Z−53,75 et derrière le texte Z−53,70. Les vues rapprochées base/candidat montrent que le texte, partiellement masqué sur la base, est désormais entièrement visible. Aucun texte World n'a changé.

## Parcours hors TDD et suites

Présentation pure déclarée avant la première écriture dans `preimplementation.md`, conformément au contrat accepté et au skill cstack TDD. Aucun comportement ajouté ; pas de test rouge artistique ni de test modifié.

Les neuf suites existantes ont été exécutées deux fois : première passe avant la dernière finition des bords Maintenance (`tests/`), puis passe finale au SHA ci-dessus (`final-tests/`). Toutes les suites finales terminent avec code0, zéro erreur détectée : world, journey, sector_power_effects, sector_power_commands, lighting_composition, lighting_alarms, lighting_settings, sector_power_state, sector_power_dialogue. Commandes exactes, hash du test, hash source, durée et code dans `final-tests/results.json`; sorties intégrales dans les logs voisins. Commande type :

```sh
Godot_v4.7.2-stable_linux.x86_64 --headless --path WORKTREE --script tests/test_world.gd
```

Les dossiers XDG sont isolés dans les preuves. `git diff --check` termine avec code0.

Avertissements conservés : V-Sync non réglable sous llvmpipe ; avertissements intermittents ObjectDB à la fermeture dans certaines suites/captures. Le contrôle verbose `test_world` reproduit sur la base quatre références audio (2 AudioStreamWAV, 2 AudioStreamPlaybackWAV), sans mesh signalé ; l'exécution verbose candidat n'en affiche aucune. Preuves dans `tests/verbose-*/engine.log` et `tests/verbose-comparison.json`. Aucun nettoyage audio hors périmètre tenté.

## Images et provenance

Les captures finales du catalogue09 original figé sont dans `verified-lighting-normal/` et `verified-lighting-low/` : 44 PNG chacune, code0, zéro erreur du validateur09, sources inchangées entre début/fin. Les manifestes consignent moteur, sonde, wrapper, sources et commande. Le mode est `lighting`, avec circuits et éclairage exigés, puis `--low` pour la seconde passe. Les p95 produits par le wrapper incluent les captures et ne constituent pas un benchmark.

`decontamination-preview-normal/`, `three-sectors-preview-normal/`, `final-lighting-normal/` et `final-lighting-low/` sont des intermédiaires antérieurs aux derniers bords Maintenance et/ou au recul du parement Archives. Ne pas les présenter comme le candidat final.

À la demande du parent, `supplemental_capture.gd` est une copie jetable de la sonde09 avec uniquement `lighting_route` remplacée par12 poses annoncées. `supplemental-provenance.json` donne la source et les deux hashes. Le validateur44 n'a pas été appliqué à ce nouveau catalogue. `details-{candidate,base}-{normal,low}/` contient12 PNG par run : les48 captures passent leurs contrôles propres (code0,12 fichiers, zéro échec moteur, sources inchangées). Même sonde et mêmes poses sur base09 et candidat ; circuits ON, lampe OFF. Chaque manifeste fournit la commande exacte et les hashes.

Vues complémentaires : collecteur gauche, réparation gauche, sortie Maintenance, N7, disjoncteur Archives, texte Archives, baie sombre, relais, preuve, trois décalages caméra de0,2m devant le parement Décontamination. Le builder a ouvert les trois vues principales Normal, Décontamination/Maintenance Low, Archives OFF+lampe Low, les comparaisons N7/texte/collecteur, les cibles proches Low et les trois décalages Décontamination. Aucun z-fighting observé sur ces trois décalages ; cela ne prouve pas une marche native continue.

Les pixels montrent des compositions distinctes et des cibles dégagées sur les poses inspectées. Le collecteur gauche est partiellement hors champ de la pose09 orientée à droite, d'où `detail_collector_left.png`. Le décor demeure stylisé et sombre lampeOFF ; aucun niveau Fortnite n'est revendiqué.

## Limites et relais au coordinateur

Pas de benchmark comparatif, export binaire, nouvelle mission native E/F, inventaire géométrique indépendant, ni revue artistique indépendante dans cette tranche. La suite journey passe, mais ne remplace pas les deux missions et le binaire demandés par le contrat global. Les timings de capture ne doivent pas être utilisés pour annoncer un gain. GPU joueur et Windows non validés ; audio Dummy ne prouve pas l'écoute.

Tous mes processus Godot et lanceurs sont terminés. `DISPLAY=:100` est libéré ; le Xvfb parent PID2472984 est resté vivant et n'a pas été redémarré. Aucun worktree créé ou supprimé ; le worktree10 est conservé et libéré pour revue/preuves parent. Les sources restent figées au SHA ci-dessus.
