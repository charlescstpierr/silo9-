# Revue visuelle indépendante du ticket 18

**PASS borné à la lisibilité des trois objets restaurés après complément. ISSUES conservé sur la série originale.** Les 24 PNG originaux, les huit captures complémentaires et les douze images extraites du film ont tous été ouverts avec `view_image`. La carcasse restaurée est désormais reconnaissable en Normal et Low. Les six vues originales de `sentinel_1` après sa mort restent occultées et non probantes ; le supplément ne les requalifie pas.

## Preuves et portée

`native-mother/manifest.json` et `native-n7-low/manifest.json` sont finaux, avec `exit_code: 0`, `validation_errors: []` et `source_unchanged: true`, au HEAD `c105da61b2b490546f01c9d67703bfb405a2a44f`. Les rapports `journey.json` indiquent respectivement Normal/MÈRE et Low/N-7, aucune failure, et 525,48 m / 524,67 m parcourus. Ces distances proviennent de l'instrumentation ; je ne les ai pas mesurées visuellement.

Les captures utilisent une caméra contrôlée séparée. La marche, les combats, les visites et F5/F9 proviennent des rapports instrumentés, pas de la succession des PNG. Les rapports indiquent des nouveaux IDs Player/World après chargement. Aucune affirmation de fluidité, FPS, audio, rendu GPU cible ou Windows n'est faite ici. Le film est examiné uniquement à travers douze images échantillonnées, sans visionnage continu.

## Images originales réellement ouvertes

Chaque cellule est un fichier distinct ouvert et inspecté.

| Normal | Low |
| --- | --- |
| `native-mother/initial_crate.png` | `native-n7-low/initial_crate.png` |
| `native-mother/modified_crate.png` | `native-n7-low/modified_crate.png` |
| `native-mother/revisited_crate.png` | `native-n7-low/revisited_crate.png` |
| `native-mother/restored_crate.png` | `native-n7-low/restored_crate.png` |
| `native-mother/initial_sentinel_1.png` | `native-n7-low/initial_sentinel_1.png` |
| `native-mother/modified_sentinel_1.png` | `native-n7-low/modified_sentinel_1.png` |
| `native-mother/revisited_sentinel_1.png` | `native-n7-low/revisited_sentinel_1.png` |
| `native-mother/restored_sentinel_1.png` | `native-n7-low/restored_sentinel_1.png` |
| `native-mother/initial_arc.png` | `native-n7-low/initial_arc.png` |
| `native-mother/modified_arc.png` | `native-n7-low/modified_arc.png` |
| `native-mother/revisited_arc.png` | `native-n7-low/revisited_arc.png` |
| `native-mother/restored_arc.png` | `native-n7-low/restored_arc.png` |

## Constats visuels

La caisse intacte est identifiable. Après destruction, trois panneaux gris-bleu remplacent son volume fermé et se détachent du sol sombre. La disposition des restes est stable entre modified, revisited et restored dans les deux qualités. Leur rendu est simple, mais le changement d'état se lit. Une image fixe ne prouve pas l'absence de collision ; celle-ci est rapportée séparément à zéro dans les observations.

ARC passe d'une façade orange lumineuse avec barrière visible à un boîtier sombre sans barrière. Cet état persiste dans les trois vues terminales en Normal et Low. Le boîtier sombre reste localisable grâce au cadrage et à sa silhouette, mais son invite n'est pas affichée dans ces PNG. Le texte `Verrou hors tension`, le booléen disabled et l'absence de second signal/message sont des preuves du rapport, pas des lectures à l'écran.

La sentinelle initiale est reconnaissable, avec tête, tronc et membres séparables. Dans `modified_sentinel_1.png`, `revisited_sentinel_1.png` et `restored_sentinel_1.png`, pour les deux qualités, un grand panneau remplit presque tout le cadre. La carcasse est invisible. C'est un défaut bloquant de la preuve visuelle : impossible de comparer silhouette, contact au sol ou orientation. Cela ne démontre pas un défaut de gameplay ou l'absence effective de carcasse.

Les vues ARC montrent d'autres carcasses à l'arrière-plan, lisibles comme robots couchés. Elles ne remplacent pas la preuve de l'identité `sentinel_1`.

Low présente des contours plus crénelés que Normal ; les trois panneaux de caisse et la différence actif/inactif d'ARC restent lisibles. La sentinelle morte ne peut pas recevoir de verdict de lisibilité Low à partir de vues occultées. Aucun niveau de qualité comparé à un jeu commercial n'est revendiqué.

## Comparabilité et limites de cadrage

Les métadonnées `persistence.images` indiquent FOV 76° et rotation `[-0.3811044, 0.7853982, 0]` pour les 24 images. La caisse est cadrée depuis `[7, 2.2, -9]` ; ARC depuis `[5.8, 2.2, -54]`. Ces positions sont identiques entre les quatre étapes et entre Normal/Low. Leurs comparaisons sont donc exploitables.

La caméra initiale de la sentinelle est approximativement `[6, 2.20083, -16.36]`. Les trois caméras terminales sont identiques au sein de chaque parcours, mais déplacées avec le lieu de mort : `[3.95689, 2.20094, -13.43748]` en Normal et `[3.92795, 2.20094, -13.32446]` en Low. Cette adaptation place la cloison entre caméra et trace. La constance des métadonnées ne suffit donc pas à rendre les images probantes.

Les observations instrumentées conservent la même pose terminale avant/après chargement dans chaque parcours : Normal `[0.95689, 0.000943, -16.43748]`, yaw `2.987949` ; Low `[0.92795, 0.000943, -16.32446]`, yaw `2.987949`. Elles indiquent trois meshes, aucune collision et aucun traitement. Ces valeurs restent distinctes de la vérification visuelle manquante.

Le HUD est lisible, sans chevauchement bloquant. Son secteur suit le joueur réel et non la caméra de capture : par exemple, une vue de la caisse peut afficher CŒUR ou ASCENSEUR. Il ne faut pas présenter ces cadrages comme une vue de visée du joueur. Dans les deux `modified_crate.png`, des bras et une arme apparaissent à gauche, conséquence visible de la caméra séparée ; ils ne cachent pas la caisse. L'alignement de visée en jeu n'est pas validé par cette série.

## Complément de reconstruction examiné

Le script `visual-supplement/capture.gd`, relu en lecture seule, recharge chaque véritable sauvegarde de campagne, reconstruit le monde, masque joueur/HUD et produit deux angles de sentinelle ainsi que caisse et ARC. Il n'enregistre aucune nouvelle marche ni combat. `run.json` et les deux `captures.json` indiquent sorties 0, listes de failures vides et rayons centraux libres. L'exclusion du collider ARC dans son rayon sert à contrôler l'absence d'obstacle devant la cible, pas à prouver que le boîtier n'a pas de collision.

Les SHA des deux saves ont été recalculés et concordent avec les rapports de capture : Normal `1d971740fb868cc87f36383b90f2e67cb6e2ff9421c447f865e360bbd738bd77`, Low `3d187e633f79296fc5643122b834dfab8f504818787db9bee149a83f30cb8990`. Le SHA du script concorde aussi avec `run.json`. Position et yaw de `sentinel_1` correspondent aux valeurs terminales originales de chaque campagne.

| Supplément Normal réellement ouvert | Supplément Low réellement ouvert |
| --- | --- |
| `visual-supplement/normal/sentinel_front.png` | `visual-supplement/low/sentinel_front.png` |
| `visual-supplement/normal/sentinel_back.png` | `visual-supplement/low/sentinel_back.png` |
| `visual-supplement/normal/crate.png` | `visual-supplement/low/crate.png` |
| `visual-supplement/normal/arc.png` | `visual-supplement/low/arc.png` |

La sentinelle est couchée dans l'allée, visible entièrement sous les deux angles. La tête, le tronc, les épaules et les pieds conservent une silhouette de robot ; les accents orange aident à la distinguer du sol. Low réduit les détails, mais la trace reste reconnaissable. Aucun flottement ou enfoncement évident ne ressort de ces angles. Ces images établissent la lisibilité de la pose reconstruite ; elles ne montrent pas les trois étapes terminales originales depuis un angle dégagé.

La caisse présente les mêmes panneaux disloqués et ARC le même boîtier éteint, sans barrière. Le HUD et les bras du joueur sont absents comme prévu. Aucun défaut bloquant n'est observé sur ces huit captures. Le contraste du boîtier ARC est faible, mais son volume et son emplacement restent discernables dans le cadrage montré.

Le journal du supplément Normal contient `2 ObjectDB instances were leaked at exit`. Le journal Low lu ne contient pas ce message. Les deux contiennent l'avertissement V-Sync du pilote. Les sorties 0 ne suppriment pas cet avertissement de fermeture ; aucune cause ni correction gameplay n'est déduite ici.

## Douze images échantillonnées du film

`native-film/review-frames.json` décrit une extraction à intervalle nominal de 12,1444 s. Les empreintes des douze fichiers ont été recalculées et correspondent au manifeste. Chaque fichier suivant a été ouvert ; il ne s'agit pas d'un visionnage continu.

| Image réellement ouverte | Observation |
| --- | --- |
| `native-film/review-frames/frame-01.png` | Écran de démarrage Godot. |
| `native-film/review-frames/frame-02.png` | Décontamination, arme et lampe visibles, message IMPACT. |
| `native-film/review-frames/frame-03.png` | Maintenance, invite de rétablissement du circuit lisible. |
| `native-film/review-frames/frame-04.png` | Archives, carcasse couchée au premier plan et accès au cœur. |
| `native-film/review-frames/frame-05.png` | Rampant vivant au cœur, effets de tir et impact visibles. |
| `native-film/review-frames/frame-06.png` | Retour vers l'ascenseur annoncé, carcasse visible dans les Archives. |
| `native-film/review-frames/frame-07.png` | Panneaux de caisse détruite visibles à gauche pendant le parcours. |
| `native-film/review-frames/frame-08.png` | Couloir Maintenance/Archives dégagé au centre, traces à distance. |
| `native-film/review-frames/frame-09.png` | Passage près du panneau Archives ; centre de la vue disponible. |
| `native-film/review-frames/frame-10.png` | Message Progression restaurée ; carcasse visible dans Maintenance et débris de caisse à droite. |
| `native-film/review-frames/frame-11.png` | Cœur vide, carcasse visible, dialogue de MÈRE et HUD lisibles. |
| `native-film/review-frames/frame-12.png` | Retour au refuge, objectif de choix final encore affiché. |

Ces images soutiennent la présence de traces durant le parcours et après une restauration annoncée. Elles ne montrent pas chaque tir, la continuité de marche, tous les instants F5/F9 ou l'écran de fin. Le HUD et le réticule restent lisibles dans cet échantillon. Des textes de décor vus par leur dos apparaissent inversés dans les images 09 et 12 ; c'est un défaut visuel non bloquant observé, sans attribution au ticket 18. Aucun jugement sur les animations ou la précision temporelle de visée ne découle d'images espacées.

`ffprobe.json` rapporte un H.264 1280×720, 145,733333 s et 2 186 images. `writer.json` et `decode.json` rapportent écriture, ffprobe et décodage complets avec codes 0. Ces valeurs décrivent le fichier, pas les performances du jeu. `native-summary.json` conserve aussi la sortie 143 du superviseur 24873, de cause non établie, alors que ses deux enfants et l'écriture/décodage ont terminé avec code 0. Toute la chaîne ne peut donc pas être déclarée sortie 0.

Verdict final limité : lisibilité des trois états restaurés confirmée par les captures originales exploitables et le complément ; cohérence visuelle avec les douze images film examinées. La comparaison visuelle directe de la sentinelle entre modified/revisited/restored reste manquante dans la série originale et repose sur les observations instrumentées pour la constance de sa pose.

Libération : 44 images ouvertes au total. Seul `art-review.md` écrit ; aucun moteur, capture, ffmpeg, modification de production/outils ou descendant lancé par ce réviseur. Le parent conserve l'exclusivité du runtime.
