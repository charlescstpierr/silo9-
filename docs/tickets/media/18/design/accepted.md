# Contrat retenu : état canonique et traces locales partagées

Base de conception : Q, soit a.md, préférée par les deux juges indépendants à22/25 et20/25. P=c.md, R=b.md. Les trois conceptions ont été lues entièrement par le parent. Elles sont non exécutables, donc aucun PASS runtime. Les différences structurelles portent sur projection locale par objet contre fusion globale et invalidation par signature.

Décision du coordinateur : Q protège le mieux les anciennes sauvegardes et les transitions canoniques. Nous reprenons de R les traces locales partageant une petite palette et un constructeur commun au combat/chargement. Le regroupement global P est rejeté : culling commun, allocations lors de chaque nouvelle mort et registre public mutable. Le nouveau fait de caisse R est rejeté : il ferait évoluer inutilement le catalogue historique de faits. La caisse a un booléen dédié.

La préférence initiale du parent pour le moindre nombre de lots globaux a été révisée après lecture des risques de culling, d'invalidation et de saturation historique. Aucun score parent antérieur au jugement n'est revendiqué. Scores finaux du coordinateur par axes canonique/visuel/coût/interface/preuve : Q=5/4/3/5/5=22 ; R=3/4/4/4/4=19 ; P=3/4/4/3/4=18. Ce sont des scores de conception, pas une preuve de fonctionnement.

## Résultat joueur et limites

La caisse Kenney existante à `(4,0,-12)` casse au premier impact balistique positif. ARC, identifiable par stun positif dans l'API existante, ne la casse pas. Aucun loot, explosion ou dommage secondaire ajouté. Trois panneaux statiques lisibles remplacent la caisse ; les restes ne bloquent ni marche ni tir.

Une sentinelle ou un rampant tué laisse une silhouette statique reconnaissable à sa position réelle et selon son yaw de mort. Les six robots connus sont le maximum. Les traces n'ont ni IA, collision, lumière, timer ni traitement par frame. Les anciens morts sans pose restent absents, sans carcasse inventée au spawn.

Le verrou ARC garde son aspect inactif, son invite et son booléen observable après reconstruction. Un nouveau tir n'ajoute ni transition, souvenir ni message. La porte du cœur reprend immédiatement sa pose finale ouverte lors du chargement ; une ouverture pendant le jeu reste animée.

La restauration reste main.load_run → nouveaux Player et World. Aucun streaming ou restauration en place d'un monde déjà vivant. Les quêtes, circuits, inventaire et deux fins sont conservés.

## Données et propriétaires

- `scripts/run_state.gd` conserve état canonique, mutations, validation et E/S. Ajouter une classe interne typée DeathPose(position: Vector3, yaw: float), un booléen privé `_crate_broken`, et une map privée `_death_poses` bornée. Les nombres de pose sont finis et le yaw enregistré est normalisé.
- API de domaine : `break_crate() -> bool`, `crate_broken() -> bool`, `mark_defeated(id: String, pose: DeathPose = null)` et `death_pose(id) -> DeathPose` retournant copie ou null, `disable_arc_lock() -> bool`. Garder la compatibilité des appels sans pose. Une nouvelle méthode ne doit pas devenir une façade pour un second propriétaire.
- `defeated` reste l'autorité de la mort ; les poses sont des annotations facultatives. Toute pose est cataloguée et son ID est dans defeated. Copier la pose entrante avant stockage, autant que la pose retournée, pour empêcher une mutation indirecte par référence. Pas d'ajout ou déplacement de pose lors d'une seconde neutralisation. ID et pose sont inscrits avant l'unique signal changed.
- `scripts/data/robot_spec.gd` contient un seul catalogue des six IDs, variantes et spawns actuels. World le consomme ; State utilise les mêmes identités pour valider les poses. Les chaînes sentinel_1, crawler_1, sentinel_2, crawler_2, sentinel_3, crawler_3 restent inchangées.
- `scripts/destructible_crate.gd` possède ensemble collider, mesh intact et restes de l'unique caisse, en adaptant receive_hit au State. Le collider indépendant historique doit disparaître. Le sous-arbre reste hors batching statique.
- `scripts/robot_visual.gd` prépare les géométries statiques partagées de deux variantes et les instancie sans Enemy. `world.gd` possède un index privé de traces par ID ; même constructeur au combat et au chargement, aucune duplication lors des refresh.
- À la mort : capturer pose, couper physique et collision, masquer le vivant, enregistrer puis libérer. Remplacer le tween de réduction par cette trace stable immédiate. Ne pas instancier d'Enemy pour un ID déjà vaincu lors de la reconstruction.

## ARC et porte

`disable_arc_lock` réalise la transition idempotente dans State et prépare fait + souvenir avant l'unique notification. Ne pas enchaîner deux helpers émetteurs. Une petite primitive privée de journal sans émission est acceptable si elle évite la duplication de sa politique ; pas de flags publics d'ordre d'exécution.

Le getter ARC proposé par R/P n'est pas greffé tel quel : il couplerait tous les SiloInteractable au fait d'un seul verrou. Garder `is_disabled` comme projection runtime contrôlée par World.refresh à partir du fait, avec transition canonique idempotente dans State. Ce booléen n'entre pas dans la sauvegarde. Restaurer ce booléen, l'invite et l'aspect ensemble ; le test doit vérifier qu'un second impact n'émet même pas le signal disabled.

La barrière coupe sa collision avant queue_free. Le boîtier reste ciblable, avec matériau non émissif et invite « Verrou hors tension ». Ses meshes restent accessibles pour la projection.

Lors de `_build_structure`, si phase>=POWER_RESTORED, placer la porte et son collider à y=4 et marquer reactor_gate_open avant toute frame physique. Le refresh suivant ne rejoue pas de tween. Conserver le tween seulement lors du passage joué vers POWER_RESTORED.

## Schéma 4 et frontière de fichier

Écrire schéma4, en ajoutant exactement `crate_broken: bool` et `death_poses: {id: {position:[x,y,z], yaw:number}}`. Les schémas2/3 gardent leurs clés, faits et bornes historiques. Schéma2 restaure circuits ON ; schéma3 conserve les circuits. Leur migration crée caisse intacte et poses vides.

Schéma4 réserve six places aux robots catalogués en plus des128 IDs génériques historiques : au plus128 IDs hors catalogue et134 IDs totaux, uniques. Les schémas2/3 gardent leur plafond128. Une ancienne liste pleine doit encore pouvoir enregistrer les six morts réelles sans éviction. Les poses restent bornées à six.

Valider les clés/types exacts, ID connu déjà défait, nombres finis, vecteur de trois composantes bornées à ±10000 et yaw à ±PI. Ces bornes larges restent cohérentes avec l'état existant ; ne pas ajouter une enveloppe spatiale étroite non démontrée. Convertir toutes les données avant d'affecter champs/signaux/révision. Un échec conserve aussi le World actif via main.load_run.

À l'écriture, produire une seule chaîne JSON validée ; mesurer ses octets UTF-8 et refuser >65536 avant ouverture du temporaire. Vérifier écriture et erreurs, relire/valider le temporaire avant rename, conserver l'ancien fichier sur chaque erreur contrôlable. Aucun contrat de résistance à une coupure électrique n'est annoncé. Ne sérialiser aucun node, effet, douille, animation, santé partielle ou scène.

## Budget graphique retenu

Clarification du budget contradictoire de Q : chaque carcasse comporte au plus trois MeshInstance3D, chacune avec un ArrayMesh à une seule surface. Les deux variantes ont au plus six ArrayMesh partagés et trois matériaux existants partagés, sans matériel neuf par mort. Réutiliser les formes existantes et conserver une silhouette et des accents lisibles ; éviter le robot complet animé conservé en cache.

La caisse cassée utilise un MultiMeshInstance3D de trois panneaux, BoxMesh partagé et matériau existant. Maximum19 instances graphiques de traces, jusqu'à19 soumissions couleur théoriques, ombres OFF et portée45m. Ces plafonds structurels ne sont pas des chiffres GPU mesurés. Les géométries ne se reconstruisent pas à chaque refresh ; le placement individuel conserve le culling local. Mesurer ressources, sommets/indices et octets des meshes, puis compteurs et coût réel séparément des captures.

## Tests avant production et livraison

1. Le builder possède d'abord seulement les tests et leurs preuves. Il doit exécuter quatre rouges comportementaux sur28e4028, sans erreur de syntaxe, import absent ou dépendance cassée : vraie caisse touchée puis restes attendus ; robot déplacé/tourné puis trace durable ; ARC reconstruit puis second impact idempotent ; porte ouverte immédiatement au retour du chargement. Les tests peuvent employer les APIs existantes et inspecter le snapshot, sans appeler une classe inexistante à l'analyse.
2. Protéger la frontière de sauvegarde : anciens schémas/phases/fins/IDs génériques, schéma4 et poses invalides, capacité128+6, tailleUTF8 exacte et dépassement, erreur d'écriture/rename avec ancien fichier identique et état/signaux inchangés sur rejet.
3. Le parent lit les tests, leurs journaux et la raison des rouges avant d'autoriser la production. Ensuite même test vert sans affaiblissement, puis state/world/power/journey/modal-save/casings selon les changements réels.
4. Parcours source avec tirs réels, marche aller-retour, F5/F9 ou chargement instrumenté déclaré, nouveaux IDs Player/World, trois objets identifiés avant/après et fin réalisable. Quêtes sans doublon, cœur déjà extrait indisponible, circuits mixtes. Sauvegarder pendant des effets réellement actifs et prouver leur absence après reconstruction.
5. Images comparables Normal/Low et revue indépendante. Budget des six traces, allocations stables sous refresh/reloads et mesures de rendu séparées des captures. Outils de preuve nouveaux soumis à leurs cas négatifs. Exports et contrôle natif Linux après revue ; Windows/GPU/audio non déduits de llvmpipe.

Décisions fermées : pas d'approbation supplémentaire demandée, puisque l'implémentation et ces choix bornés sont autorisés. Toute friction répétée avec cette forme revient au coordinateur avant de multiplier les contournements.
