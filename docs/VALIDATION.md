# Validation de SILO 9

Version de développement du 17 octobre 2026, Godot 4.7.2 stable. Le résultat est un prototype FPS jouable. Le niveau et son équilibrage ne sont pas encore validés comme une expérience humaine de 20 à 30 minutes.

## Comportements vérifiés

`./tools/verify.sh` importe le projet puis exécute six suites Godot headless avec des sauvegardes isolées dans `.cstack/silo9/test-user-data`.

| Vérification | Résultat observé |
|---|---|
| État et sauvegarde | Ressources partagées, progression du relais, deux fins exclusives, relations bornées, schéma 2, refus atomique des données invalides |
| Contrôleur | Mur, gravité, saut, marche basse, accroupissement sous plafond, raycast, dégâts D9, ARC et immobilisation, recharge et annulation |
| Interface | Menus, pause, disposition logique WASD/ZQSD, inventaire, H/B, mort, choix final inaccessible avant le noyau |
| Monde | Scan à portée, réparation, archive, cœur, porte physique, détour ARC, butin non duplicable, perception occultée, franchissement des cloisons |
| Réseau | Vrai HTTP local de test, timeout de 8 s, réponse malformée/surdimensionnée, annulation, réponse périmée, intentions hostiles et confidentialité |
| Parcours intégré | Vrai déplacement du joueur, visée et interaction sur les objets, combat, mission, retour à l'ascenseur, restauration et deux conclusions |

Le parcours intégré couvre environ 184 mètres et 15 tirs, avec zéro échec. Le bot connaît les emplacements et vise automatiquement. Ses quelque 39 secondes simulées ne représentent pas la durée d'une première partie humaine. Aucun temps d'attente artificiel n'a été ajouté pour atteindre une durée annoncée.

Le cycle rouge puis vert est conservé pour les comportements de base et les défauts découverts : marches, événements AZERTY réels, raccourcis d'inventaire, navigation entre cloisons et hallucination narrative. Les preuves brutes sont dans `.cstack/silo9/evidence/` du workspace de construction. Des relecteurs indépendants ont reproduit puis revalidé les corrections.

## Rendu et exécution

Le projet a été exécuté dans une fenêtre Godot Linux sous Xvfb. Des entrées natives X11 ont ouvert les réglages, démarré la partie, déplacé le joueur, activé le scan et ouvert la pause. Les captures proviennent du jeu rendu : [menu](screenshots/menu.png), [réglages](screenshots/settings.png), [scan en maintenance](screenshots/maintenance.png) et [réacteur](screenshots/reactor.png). Le compteur FPS visible correspond au rendu logiciel du serveur.

Le binaire Linux release exécute le benchmark intégré avec `-- --benchmark`. Le binaire Windows x64 est exporté avec les modèles officiels 4.7.2 et identifié comme PE32+. Aucun environnement Windows n'est disponible ici : son lancement sous Windows reste non vérifié. Le pilote audio du serveur est simulé ; les sons sont générés et chargés, mais leur écoute sur un périphérique physique n'a pas été évaluée.

## Conversation réelle et canon

Deux personnages ont reçu des réponses du vrai serveur llama.cpp b11716 avec Qwen2.5-0.5B-Instruct Q4_K_M, sur `127.0.0.1:18089`, modèle API `silo9-local`, sans clé. Deux passes de la version finale ont répondu en mode « IA connectée ». Les temps observés étaient 3,36/4,43 secondes puis 1,37/1,54 secondes. Ce petit échantillon prouve la connexion, pas la qualité conversationnelle générale.

Le texte saisi par le joueur est libre. Le modèle choisit une réaction approuvée, des faits connus et des actions bornées. Le jeu assemble les textes canoniques ; il n'affiche pas de prose factuelle arbitraire du modèle. La variété des formulations est limitée. Le mode hors ligne et les indices immédiats fonctionnent sans aucun modèle.

## Performances

Objectif produit : 60 FPS en 1080p sur un PC équipé d'un GPU. Objectif non certifié par cette machine de développement.

Le serveur dispose de huit processeurs logiques et utilise Mesa llvmpipe, donc du rendu logiciel sur CPU. La série finale utilise le binaire Linux release, cinq passages alternés par qualité, quatre positions, 1,5 seconde de préparation puis 3 secondes de mesure par position. Ennemis actifs, scan en maintenance, nombre de frames et joueur vivant sont contrôlés. Le pilote refuse de modifier VSync ; seule sa désactivation demandée est enregistrée. Le compteur mémoire interne n'est pas disponible en release et vaut `null` dans les rapports.

Le mode performance réduit la résolution 3D à 67 % par axe, conserve le HUD à la résolution de la fenêtre, simplifie les lumières et coupe le brouillard. Le monde regroupe ses formes statiques par secteur et matériau. La perception des ennemis tourne à 5 Hz, les robots éloignés cessent de simuler, les effets sont bornés et les appels IA sont asynchrones.

Médiane des temps de frame p50 sur cinq passages par mode :

| Position | Normal | Performance | p95 en performance |
|---|---:|---:|---:|
| ASCENSEUR / REFUGE | 63.7 ms | 48.2 ms | 58.7 ms |
| 02 / MAINTENANCE | 71.8 ms | 47.5 ms | 58.8 ms |
| 03 / ARCHIVES | 61.2 ms | 43.7 ms | 50.2 ms |
| 04 / CŒUR | 53.9 ms | 38.1 ms | 47.7 ms |

En maintenance, le mode performance réduit ce temps de frame de 71,8 à 47,5 ms, environ 34 %. Les plages entre passages sont 70,3–74,9 ms et 46,7–50,3 ms. Ce gain vient du changement de réglages, notamment de la réduction des pixels 3D. Le processus utilise en moyenne environ 5,6 cœurs CPU pendant la série ; le rendu logiciel reste le facteur limitant. Les 60 FPS ne sont pas atteints sur ce serveur.

Les résultats complets et le SHA du binaire mesuré sont dans [performance.json](performance.json). Ils ne constituent pas une certification Windows ou GPU.

## Limites restantes

- Apparence de prototype : formes simples, animations modestes et déplacements ennemis guidés par les passages de ce niveau.
- Durée, difficulté et plaisir de jeu à calibrer avec Charles et Lou.
- Aucun test sur un PC Windows physique ni mesure sur GPU matériel.
- Réponses IA encadrées ; pas de génération libre de nouveaux faits narratifs.
- Aucun dépôt distant configuré : livraison locale et archives, sans PR ni publication.
