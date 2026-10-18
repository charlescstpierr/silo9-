# Protocole performance ticket10, avant production

Question principale : coût de la nouvelle composition des trois secteurs, comparée à0297cf7 dans worktree09. Candidat dans worktree10, HEAD à geler après revue. Godot4.7.2, X11 Compatibility,1280×720,llvmpipe. Même version figée de la sonde et du wrapper pour les deux branches.

Cinq paires alternées par qualité, Normal puis Low; ordre baseline/candidat inversé une paire sur deux. Le parcours reste celui des neuf stations physiques92,4m, circuitsON, lampeOFF, ennemis retirés, chauffe2s. Un seul moteur, aucun encodeur/capture/profil concurrent. Ne pas réutiliser les timings09 comme baseline10. Les captures09 peuvent être réutilisées uniquement pour les comparatifs visuels, avec identité152fichiers et états conservés dans baseline-identity.json.

Conserver tous les intervalles wall-clock entre callbacks _process, frames réellement dessinées, coordonnées/états/FOV/échelle, maximums drawcalls/nœuds/ressources et hashes du moteur/outils/source. Recalcul indépendant p50/p95/p99 par run puis médianes/plages et différences appariées. Ces mesures ne sont pas du temps GPU et ne valident pas60FPS1080p.

Le relevé géométrique doit tenir compte des surfaces MeshInstance et des instances MultiMesh, hors fenêtre mesurée. Un drawcall constant ne garantit pas coût constant. Une inspection de trois poses fixes peut compléter le trajet si ses vues ne couvrent pas les nouveaux décors; la choisir avant campagne et séparer ses chiffres. Le nouveau décor doit conserver portée32/44m, Low0,67 et budget d'ombres09. Tout coût reproductible matériel appelle une optimisation ou un compromis explicite, sans invoquer un gain global depuis une seule pose.

L'hôte ne possède pas de GPU joueur. La question matérielle déjà envoyée reste sans réponse; cela ne bloque pas les contrôles locaux. Toutes les captures et missions restent séparées des timings de livraison.

## Complément décidé avant la campagne

Les nouveaux parements changent les surfaces éclairées et susceptibles de projeter une ombre. Le trajet doit donc comparer aussi la lampe allumée, au-delà du seul nombre de lumières. La campagne comprend désormais quatre groupes : Normal OFF, Normal ON, Low OFF, Low ON. Chacun contient cinq paires baseline/candidat, soit40runs. L'ordre des versions alterne à chaque paire. Les groupes restent séparés dans les résultats; ne pas présenter une différence ON/OFF entre groupes comme une activation appariée dans le même run.

La copie `perf-proof-tools` ajoute l'option explicite `--flashlight-on` au seul mode perf. Défaut OFF et autres modes conservés; TDD du nouveau contrat puis diagnostic réel exclu de la campagne. L'état réel de la lampe est vérifié pendant le relevé et à la fin. Même outil figé et même SHA moteur dans les40runs. Pas de benchmark de livraison avant revue de cette extension. Les captures et missions déjà terminées utilisent `route-proof-tools` et gardent leur provenance.
