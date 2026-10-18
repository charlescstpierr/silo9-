# Méthode de mesure

La comparaison chiffre le coût du parcours de maniement livré sur cette machine Linux à rendu logiciel. Elle ne cherche pas à certifier une cadence sur GPU de jeu.

Les deux versions utilisent Godot 4.7.2, 1280×720, la qualité normale avec lissage de contour, l'interface masquée et le même scénario demandé. Les ennemis restent rendus, mais leur IA est désactivée des deux côtés pour que le bruit des tirs ne transforme pas la mesure en combat. Le joueur conserve son traitement physique automatique. La sonde n'appelle jamais `_physics_process` avec un delta mural fabriqué.

Après une seconde d'échauffement, le parcours couvre D9 et ARC : repos, marche, sprint, regard, tir urgent, arrêt, visée et tir. Il traverse ensuite D9 partiel/vide, ARC cellule, sélections rapides et B avec retour D9. Chaque sélection normale réserve au moins 0,35 s des deux côtés. Le comportement instantané de la baseline reste instantané ; ses états de descente/remontée proviennent de B, identifiés par les événements et les étiquettes du parcours.

Cinq paires baseline/candidat alternent strictement. Aucun film, capture ni autre moteur de cette tâche ne tourne pendant ces dix fenêtres. Le runner rejette les erreurs moteur, les assertions, une santé altérée, les contacts hors tolérance et les sources modifiées. Il vérifie les fichiers de production contre les objets Git, enregistre leurs hashes et ceux de la sonde/du runner avant lancement, puis contrôle leur stabilité en sortie.

Les intervalles entre callbacks de rendu donnent les p50/p95 muraux. Le second `update_visual(0)` donne seulement le coût d'un appel chaud isolé. Son temps et l'observation de la sonde sont inclus dans les intervalles des deux côtés. Ce microcoût n'est pas celui de toute l'image. À delta zéro, cet appel ne fait pas avancer les filtres de locomotion ; leur exécution normale reste incluse dans les intervalles du parcours complet. Les samples enregistrent aussi les motions et gestes traversés, les vitesses réellement obtenues, le contact et les comptes ; un parcours rapide qui ne fait pas le travail ne passe pas.

Les résultats donnent la médiane et l'étendue des cinq p50/p95 de chaque côté. Une différence plus petite que la variation entre exécutions ne permet pas de conclure à un gain ou à une régression. Une observation séparée des threads du moteur qualifie le rendu logiciel comme limite de cet hôte ; cette observation ne fait pas partie des dix fenêtres publiées.
