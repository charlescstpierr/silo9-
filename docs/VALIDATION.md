# Validation de SILO 9

Le [rapport Mission Astra](ASTRA_VALIDATION.md) décrit les changements, captures et mesures de la branche graphique. Les résultats ci-dessous documentent le prototype initial.

Version de développement du 18 octobre 2026, Godot 4.7.2 stable. Le résultat est un prototype FPS jouable. Le niveau et son équilibrage ne sont pas encore validés comme une expérience humaine de 20 à 30 minutes.

Les mesures globales et captures ci-dessous correspondent à la base `8649b60`. La modification des mains est décrite séparément dans [le rapport du ticket 2](tickets/02-fps-rig.md), avec son scénario, ses preuves et les limites de ses mesures.

## Comportements vérifiés

`./tools/verify.sh` importe le projet puis exécute sept suites Godot headless avec des sauvegardes isolées dans `.cstack/silo9/test-user-data`.

| Vérification | Résultat observé |
|---|---|
| État et sauvegarde | Ressources partagées, progression du relais, deux fins exclusives, relations bornées, schéma 2, refus atomique des données invalides |
| Contrôleur | Mur, gravité, saut, marche basse, accroupissement sous plafond, raycast, dégâts D9, ARC et immobilisation, recharge et annulation |
| Interface | Menus, pause, disposition logique WASD/ZQSD, inventaire, H/B, mort, choix final inaccessible avant le noyau, sous-titres masqués pendant le dialogue |
| Monde | Scan à portée, réparation, archive, cœur, porte physique, détour ARC, butin non duplicable, perception occultée, franchissement des cloisons |
| Réseau | Vrai HTTP local de test, timeout de 8 s, réponse malformée/surdimensionnée, annulation, réponse périmée, intentions hostiles et confidentialité |
| Géométrie visuelle | Faces des armes complètes, sommets référencés, normales finies et unitaires |
| Parcours intégré | Vrai déplacement du joueur, visée et interaction sur les objets, combat, mission, retour à l'ascenseur, restauration et deux conclusions |

Le parcours intégré couvre environ 184 mètres et 15 tirs, avec zéro échec. Le bot connaît les emplacements et vise automatiquement. Ses quelque 39 secondes simulées ne représentent pas la durée d'une première partie humaine. Aucun temps d'attente artificiel n'a été ajouté pour atteindre une durée annoncée.

Le cycle rouge puis vert est conservé pour les comportements de base et les défauts découverts : marches, événements AZERTY réels, raccourcis d'inventaire, navigation entre cloisons et hallucination narrative. Les preuves brutes sont dans `.cstack/silo9/evidence/` du workspace de construction. Des relecteurs indépendants ont reproduit puis revalidé les corrections.

## Rendu et exécution

Le projet a été exécuté dans une fenêtre Godot Linux sous Xvfb. Des entrées natives X11 ont ouvert les réglages, démarré la partie, déplacé le joueur, activé le scan et ouvert la pause. Les captures de cette refonte proviennent du jeu rendu avec des caméras positionnées pour examiner le décor : [ascenseur](screenshots/lift.png), [maintenance](screenshots/maintenance.png), [atelier](screenshots/workshop.png), [N-7](screenshots/n7.png), [dialogue](screenshots/dialogue.png) et [réacteur](screenshots/reactor.png). Elles montrent le mode normal ; elles ne mesurent ni la fluidité ni la durée de jeu.

Le binaire Linux release exécute le benchmark intégré avec `-- --benchmark`. Le binaire Windows x64 est exporté avec les modèles officiels 4.7.2 et identifié comme PE32+. Aucun environnement Windows n'est disponible ici : son lancement sous Windows reste non vérifié. Le pilote audio du serveur est simulé ; les sons sont générés et chargés, mais leur écoute sur un périphérique physique n'a pas été évaluée.

## Refonte stylisée

La direction retenue par Charles et Lou est un style stylisé proche de Fortnite, avec une identité industrielle propre à SILO 9. Cette version ajoute des panneaux peints, six modules Quaternius CC0, des armes chanfreinées tenues par des mains gantées, des robots articulés, un personnage N-7 visible, un atelier et un cœur animé. Le HUD affiche des barres de vie et de batterie. Le panneau de conversation laisse le personnage visible.

Les captures finales ont fait l'objet d'une revue indépendante. Les chevauchements de dialogue, la paroi vide de l'ascenseur et le manque de composition de l'atelier ont été corrigés. Les murs restent répétitifs et certains textes 3D sont crénelés. Cette itération constitue un prototype stylisé cohérent ; elle n'atteint pas encore le niveau de finition de Fortnite.

## Conversation réelle et canon

Deux personnages ont reçu des réponses du vrai serveur llama.cpp b11716 avec Qwen2.5-0.5B-Instruct Q4_K_M, sur `127.0.0.1:18089`, modèle API `silo9-local`, sans clé. Deux passes de la version finale ont répondu en mode « IA connectée ». Les temps observés étaient 3,36/4,43 secondes puis 1,37/1,54 secondes. Ce petit échantillon prouve la connexion, pas la qualité conversationnelle générale.

Le texte saisi par le joueur est libre. Le modèle choisit une réaction approuvée, des faits connus et des actions bornées. Le jeu assemble les textes canoniques ; il n'affiche pas de prose factuelle arbitraire du modèle. La variété des formulations est limitée. Le mode hors ligne et les indices immédiats fonctionnent sans aucun modèle.

## Performances

Objectif produit : 60 FPS en 1080p sur un PC équipé d'un GPU. Objectif non certifié par cette machine de développement.

Le serveur dispose de huit processeurs logiques et utilise Mesa llvmpipe, donc du rendu logiciel sur CPU. La série finale utilise le binaire Linux release, cinq passages alternés par qualité, quatre positions, 1,5 seconde de préparation puis 3 secondes de mesure par position. Les ennemis restent actifs et le scan est déclenché en maintenance. La santé est rétablie avant chaque point de mesure pour que les dégâts accumulés par ce personnage immobile ne déclenchent pas le menu de mort. Le nombre de frames, les appels de rendu et la survie sont contrôlés ; une première passe rejetée pour mort du joueur est exclue des résultats. Le pilote refuse de modifier VSync ; seule sa désactivation demandée est enregistrée. Le compteur mémoire interne n'est pas disponible en release et vaut `null` dans les rapports.

Le mode performance réduit la résolution 3D à 67 % par axe, conserve le HUD à la résolution de la fenêtre, simplifie les lumières et coupe le brouillard. Il désactive également les ombres, le filtre de lissage et les textures de relief. Le monde regroupe ses formes statiques par secteur et matériau ; les grandes surfaces du sol, du plafond et des parois sont séparées par pièce pour limiter les lumières qui les affectent. Les meshes des robots sont partagés. Un seul projecteur produit des ombres dans le secteur courant en mode normal. Les textures utilisent des mipmaps et les détails distants sont masqués. Le lissage normal utilise un shader léger placé sous le HUD : le FXAA natif est indisponible dans ce moteur Compatibility, et le MSAA a été écarté après un coût excessif sur llvmpipe. La perception des ennemis tourne à 5 Hz, les robots éloignés cessent de simuler, les effets sont bornés et les appels IA sont asynchrones.

Chaque station contient de 18 à 55 frames par passage. Les p95 décrivent ces petits échantillons et ne constituent pas une estimation précise des saccades rares.

Médiane des temps de frame p50 sur cinq passages par mode :

| Position | Normal | Performance | p95 en performance |
|---|---:|---:|---:|
| ASCENSEUR / REFUGE | 152.4 ms | 78.8 ms | 93.3 ms |
| 02 / MAINTENANCE | 166.2 ms | 71.9 ms | 86.5 ms |
| 03 / ARCHIVES | 156.5 ms | 69.0 ms | 78.0 ms |
| 04 / CŒUR | 135.0 ms | 55.6 ms | 66.5 ms |

En maintenance, le mode performance réduit le temps médian de frame de 166.2 à 71.9 ms, soit 57 %. Les plages entre passages sont 160.0–171.2 ms et 69.1–75.5 ms. Ce gain compare deux réglages du même binaire, dont une réduction des pixels 3D. Le processus utilise en moyenne environ 4.7 cœurs CPU ; les shaders et le rendu sont exécutés par llvmpipe sur CPU. Les 60 FPS ne sont pas atteints sur ce serveur.

Les résultats complets et le SHA du binaire mesuré sont dans [performance.json](performance.json). Ils ne constituent pas une certification Windows ou GPU.

## Limites restantes

- Finition de prototype stylisé : composition encore répétitive, animations modestes et déplacements ennemis guidés par les passages de ce niveau.
- Durée, difficulté et plaisir de jeu à calibrer avec Charles et Lou.
- Aucun test sur un PC Windows physique ni mesure sur GPU matériel.
- Réponses IA encadrées ; pas de génération libre de nouveaux faits narratifs.
- Ces résultats historiques précèdent la publication du prototype dans la PR #88.
