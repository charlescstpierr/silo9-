# Ticket 5 : maniement des armes

Le changement manuel descend l'arme pendant 0,16 s, prépare les deux prises sous le cadre, puis remonte pendant 0,14 s. Le D9 répond plus vite aux déplacements que l'ARC. Le regard entraîne un retard horizontal et vertical des mains, atténué en visée. Le mouvement des mains dépend de la vitesse réellement obtenue au sol ; courir contre un mur ne produit plus de pas périodiques. La caméra conserve la visée et la hauteur d'accroupissement, sans bob périodique.

Player collecte les entrées et la rotation réellement appliquée. WeaponHandling conserve sélection effective, destination, horloge et opération cellule. Le rig filtre le mouvement et compose les prises et la bouche. Il ne débite aucune ressource. Les profils résident dans les ressources d'arme existantes.

## Commandes et interruptions

Un clic bref en READY tente immédiatement un tir. Le premier tick physique suivant ne réutilise pas le temps antérieur au clic pour déclencher un doublon ; les ticks ultérieurs reprennent le cooldown configuré. Le clic qui recapture le curseur reste consommé jusqu'au relâchement. Un clic refusé pendant une manipulation n'est pas mémorisé. Le maintien réessaie au premier READY final.

La visée gagne sur la course. Un tir ne ralentit pas le déplacement ; son recul existant réduit temporairement la cible de pose de course. Cette fenêtre dure 0,175 s pour D9 et 0,125 s pour ARC avec les paramètres actuels. Elle ne définit ni la cadence ni la durée du flash. Une recomposition à delta zéro applique un nouveau recul sans avancer les filtres. Pendant l'effet ARC, le rayon reste attaché à la bouche mobile et conserve son impact initial ; aucune nouvelle trace ni dépense n'est effectuée.

Les touches 1/2 acceptent les événements clavier marqués `echo`. La trace native a montré que Godot pouvait marquer ainsi la dernière frappe d'un 1/2/1 livré dans une même image, même avec relâchement intermédiaire. La répétition d'une même destination ne redémarre pas son horloge. Cette règle concerne seulement la sélection ; R, scanner et tir ne changent pas. Le paramètre `allow_echo` est décrit dans [la définition officielle Godot 4.7.2 de InputEvent](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/doc/classes/InputEvent.xml).

Une nouvelle destination pendant la remontée attend sa fin puis redescend sans créneau READY utilisable. Revenir à l'arme initiale avant le masquage termine tout de même le trajet. L'opération masquée s'exécute aussi lorsque l'index final est identique. Un grand delta peut traverser toute la transition sans image intermédiaire ; le jalon HIDDEN ne promet pas une frame rendue.

R utilise l'arme effective. B conserve son intention unique et sa destination de retour. Scanner et interaction restent disponibles pendant les manipulations. Pause, mort, désactivation et téléportation gardent les annulations existantes et purgent l'intention de tir et le regard. Les économies, durées et jalons de rechargement D9/ARC ainsi que le schéma de sauvegarde restent inchangés.

## Vérification reproductible

`DISPLAY=:100 bash tools/verify.sh` exécute les suites historiques et les suites de sélection, entrée, mouvement et activité. Les suites entrée/mouvement exigent une vraie capture souris X11 ; sans DISPLAY, le runner utilise `xvfb-run`. Elles ne sont jamais ignorées en mode headless.

Les copies exactes des tests rouges et leurs logs restent sous `.cstack/issue-05/`. Le gate parent relie les 27 échecs comportementaux au commit tests-only `eecf9a9`. Le runtime initial est `7a4c79f`. La revue a ajouté la suppression des clics commencés dans une modale et préservé le tir maintenu lors d'une activation répétée ; ces régressions passent sur `c68212d`. Le correctif des sélections regroupées est `15d2b91`, après deux échecs comportementaux reproduits par le parent sur le commit tests-only `4114198`. La revue visuelle a ensuite reproduit le rayon ARC détaché en sprint, également présent sur la baseline, et le signe vertical inversé. Le commit tests-only `6ccb314` précède leur correction `463aabf`. Le test complémentaire `test_weapon_mask_order.gd` observe les coins des maillages avant restauration des pièces ; il a été ajouté après implémentation et constitue une preuve de régression supplémentaire.

Les tests couvrent 100 sélections alternées, contacts des deux mains, bouche dans le même tick, FOV 60/76/90, grands deltas, delta zéro, clic bref/maintien/capture, sol/mur/marche/saut, regard et arrêt, pause/mort/chargement. Les anciennes fixtures attendent explicitement READY final. Les sondes historiques ont aussi été migrées ; l'assertion D9-only de `probe_fps_rig` était déjà obsolète avant ce ticket.

`python3 tools/prove_weapon_handling.py --inspect --film` produit des vues FPS et obliques et un film moteur déterministe. `--measure --baseline CHEMIN` exécute cinq paires baseline/candidat alternées, sans capture concurrente. Le runner vérifie les sources contre les objets Git et enregistre les hashes des sources, de la sonde et du runner avant chaque lancement puis contrôle leur stabilité.

La scène de preuve conserve les ennemis rendus mais désactive leur IA des deux côtés pour empêcher les tirs de transformer la mesure en combat. La sonde laisse le vrai traitement physique du joueur avancer. Elle relève les phases effectivement rencontrées, la vitesse obtenue, les contacts et les ressources. Le coût de son second `update_visual(0)` est un appel chaud isolé ; ce n'est pas le coût CPU de toute l'image. Les intervalles d'images incluent cette sonde des deux côtés. Le film à 30 images/s n'est pas une mesure de fluidité.

Le parcours X11 sur `15d2b91`, dont les entrées restent inchangées dans `463aabf`, vérifie les clics commencés en modale sur les deux armes, trois séquences 1/2/1 avec pressions de 30 ms, les recharges, scanner, B et F9. Ses [comptes observés](media/05/native/verification.json) distinguent les reprises sans débit des tirs frais.

Le [film moteur](media/05/film/weapon-handling.mp4) dure 23,37 s. L'analyse de son PCM trouve 14 fenêtres de cues, avec un signal détecté entre 1 et 9,34 ms après leurs événements. Ce contrôle confirme une présence sonore dans chaque fenêtre ; il ne remplace pas une écoute continue. Les captures FPS et obliques et les contrôles de géométrie constituent la preuve visuelle. Les obliques reculent le rig pour montrer les deux mains et avant-bras, avec leurs effets masqués et signalés. Les poses de sélection sont échantillonnées à 0,04 s et 0,27 s du vrai contrôleur gelé ; le reste du parcours utilise la physique automatique. Chaque capture consigne sa motion, son abaissement, son arme et son cadrage. Aucune fluidité matérielle n'est déduite du film fixé à 30 images/s.

## Résultats et limites

Les [30 suites](media/05/validation/builder-verification.json) passent sur `463aabf`. Les rapports de [vérification indépendante](media/05/validation/parent-verification.json), les rouges et les verts restent dans le dossier public de validation.

Les [cinq paires alternées](media/05/performance.json) ne montrent pas de différence de coût mesurable. Les colonnes donnent la médiane des cinq résultats, puis leur étendue en millisecondes.

| Mesure | Baseline 090055e | Candidat 463aabf |
|---|---:|---:|
| Intervalle d'image p50 |94,791 [92,183 à 95,611] |94,587 [93,337 à 95,316] |
| Intervalle d'image p95 |113,553 [107,011 à 118,992] |113,264 [112,051 à 118,956] |
| Appel chaud du rig à delta zéro, p50 |0,061 [0,058 à 0,062] |0,060 [0,059 à 0,063] |

Le moteur utilise llvmpipe LLVM 21.1.8 sur 8 CPU logiques. L'observation séparée montre huit threads llvmpipe actifs, autour de 18 à 45 % CPU chacun dans l'échantillon, contre 64 % pour le thread principal. Ces mesures décrivent une scène à rendu logiciel, en 1280×720, qualité normale avec lissage de contour, interface masquée et IA ennemie gelée. Elles n'attestent pas une cadence jouable sur une carte graphique cible. Le petit appel à delta zéro ne représente pas le CPU de l'image ni l'exécution des filtres. La [méthode complète](media/05/benchmark-method.md) conserve cette distinction.

L'inspection finale comprend 50 captures, dont 25 obliques anatomiques. Les [métadonnées des poses](media/05/inspection/journey.json) donnent les états réellement capturés. La [vue ARC en sprint](media/05/inspection/1-urgent-sprint-fps.png) conserve le rayon visible ; les effets sont masqués uniquement dans les vues anatomiques. La différence de réponse D9/ARC est mesurée dans les tests et dans le retour au repos échantillonné du film, sans certification subjective de masse au contrôle continu.

Les deux moteurs de capture ont terminé avec sortie 0 et hashes stables. Le wrapper de leur commande a cependant remonté 143, cause non établie. Ce statut reste conservé dans la [validation indépendante des médias](media/05/validation/media-independent-validation.json). Les 701 images du MP4 ont été décodées intégralement sans erreur ; les sources ont été comparées aux objets Git 463aabf et les outils archivés à leurs hashes de lancement. Ce contrôle valide les artefacts terminés sans présenter le wrapper comme réussi.

Aucun résultat de cette machine ne certifie une carte graphique de jeu, Windows ou une équivalence Fortnite.
