# Preuves du maniement

Ces artefacts utilisent le runtime `463aabf5bcc7d250ce35120841e2ed75a57c9e84`. Le candidat est comparé à `090055e002bf8f3a96e52b979f402d44a9370f87` dans cinq paires alternées. Aucune capture, vidéo ou autre moteur de la tâche ne tournait pendant les dix fenêtres.

- `inspection/` contient 25 vues FPS et 25 vues anatomiques, avec l'état réel et le cadrage de chacune dans `journey.json`.
- `film/` contient le MP4 déterministe, le PCM original extrait du MovieMaker, les événements et leur analyse sonore. Le film ne mesure pas une cadence matérielle.
- `performance.json` rassemble les dix parcours et leurs médianes/plages. Chaque dossier `perf-*` conserve le log, les données et le manifeste de lancement.
- `validation/` contient les tests rouges/verts, le contrôle des 30 suites et la vérification des médias. Le parent y ajoute ses gates et rapports indépendants.
- `native/` est intégré par le parent. Le parcours d'entrée complet utilise `15d2b91`, dont les entrées sont inchangées dans `463aabf` ; le supplément ARC en mouvement utilise `463aabf`.

Chaque lancement archive les outils exacts dans `probe-at-launch.gd.txt` et `runner-at-launch.py.txt`. Leurs hashes et ceux des fichiers de production sont enregistrés avant exécution, contrôlés en sortie et comparés aux objets Git. Les chemins absolus du manifeste décrivent le poste de capture ; les fichiers de ce dossier sont les copies publiées.

Les obliques montrent les mains et avant-bras avec un recul du rig de 0,45 m et une rotation de 0,65 radian. Leurs effets sont masqués et signalés. Les preuves de rayon ARC utilisent les vues FPS, où il reste visible. Les poses de changement à 0,04 s et 0,27 s sont des échantillons du contrôleur gelé ; le reste du parcours avance avec la vraie physique.
