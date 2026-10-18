# Comparaison prévue avant campagne

Mesurer le coût de rendu ajouté par le ticket12 pendant le même trajet physique, sur ce serveur llvmpipe à1280x720. Aucun objectif FPS joueur ou GPU cible n'est revendiqué. Les exécutions Godot depuis le projet source utilisent le même binaire4.7.2, les mêmes réglages et le même outil. Ce ne sont pas des mesures du binaire Windows.

Deux campagnes distinctes, normal et Low. Cinq paires alternées base6126e4c/candidat2c205f5, avec ordre de la paire inversé une fois sur deux. Un processus moteur à la fois, aucun encodeur vidéo. Warmup2s exclu, chemin fixe refuge/maintenance/archives/retour, neuf points atteints et plus90m, ennemis retirés dans les deux bancs, circuits ON sur candidat, aucune capture dans la région mesurée. Les trajets de mission avec combat et bascules sont prouvés séparément et ne servent pas à calculer un gain.

Chaque run doit sortir0, sans erreur, avec hashes source stables, rendu X11 Compatibility actif, frames produites, route complète et échantillons bruts valides. Recalculer p50/p95/p99 depuis ces données. Rapporter médiane et plage des cinq runs, maxima draw calls/nœuds/ressources. Un écart dans la variabilité ne sera pas appelé gain ou régression détectable. Toute dégradation reproductible impose diagnostic.

Avant la campagne, relever uptime/nproc et profiler séparément un run non retenu via pidstat des threads du processus Godot. Le coût llvmpipe sur CPU doit être distingué du coût des scripts et du matériel cible absent. Aucun chiffre du smoke ou des captures n'entre dans la comparaison finale.
