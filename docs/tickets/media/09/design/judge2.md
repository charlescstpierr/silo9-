# Jugement indépendant 2 — ticket 09

Recommandation : **Q comme base**, avec les gardes d'entrée et contrôles d'accessibilité de R. P apporte une option de secours utile si les images OFF échouent, mais ses deux sources permanentes de secours ne sont pas acquises avant mesure.

Lecture des dossiers dans l'ordre R → Q → P. Aucun mapping privé, dossier original ou autre jugement consulté. Modèle hérité; aucune diversité de modèles revendiquée. Les trois dossiers sont des **conceptions non exécutables, non vérifiées** : aucun vert ni échec de runtime attribué. Aucun moteur/test lancé. Le choix final et les greffes appartiennent au parent.

## Notes sur 25

| Axe | R | Q | P |
|---|---:|---:|---:|
| Lisibilité et direction artistique | 4 | 4 | 5 |
| Coût borné | 4 | 4 | 3 |
| Contrats corrects | 5 | 4 | 4 |
| Simplicité de propriété | 4 | 5 | 4 |
| Preuves exécutables prévues | 5 | 5 | 5 |
| Total | **22** | **22** | **21** |

Ces notes évaluent la conception et son plan de preuve, pas un résultat visuel mesuré. L'égalité Q/R est départagée par la plus petite surface de changement pour cette scène fixe : tableau central et priorité unique de Q, sans neuf conteneurs ni contexte partagé supplémentaire.

## Comparaison structurelle réelle

**R : composants locaux propriétaires.** Chaque `IndustrialFixture` construit et possède sa source, son matériau et son animation; World transmet un `LightingContext`, PowerConsumers garde la minuterie. La synchronisation source/verre est encapsulée. Cette forme convient à des luminaires réutilisables et éditables, mais ajoute Resource, contexte mutable partagé et cycle de vie de neuf composants pour un seul néon autonome. Le contrat exact de rafraîchissement du contexte et des alarmes doit être explicité : conserver une référence ne suffit pas à appliquer une transition. Aucun défaut exécuté n'est établi.

**Q : composition centrale par bindings.** World possède les couples source/diffuseur, la phase et l'ordre de priorité. Les matériaux sortent de PowerMaterials; PowerConsumers abandonne ses écritures de lentille. Les sources statiques et leurs deux effets restent dans une table, sans nouveau gestionnaire public. Cela réduit le nombre de propriétaires à comprendre lors d'une coupure, d'une fin ou d'un changement de qualité. La contrepartie est davantage de construction dans World : garder les définitions compactes et ne pas construire un registre général.

**P : variante centrale avec alimentation explicite.** Les enums MAINS/BACKUP rendent les exceptions de courant plus lisibles; l'alarme ajoute un signal de transition et les deux secours persistent en coupure. C'est une différence fonctionnelle pertinente, mais pas une troisième architecture globale distincte de Q. Le signal peut être utile, toutefois il ne supprime pas la lecture du temps restant pour l'enveloppe. Son intérêt doit être établi avant de multiplier les chemins de recomposition.

Deux formes globales réellement distinctes sont donc comparées : propriété locale de R contre propriété centrale de Q/P. Les alternatives sont assez précises pour être viables, pas de simples changements de noms.

## Motifs et risques par candidat

- **R** : palette et sources motivées; excellent cadrage des gardes curseur, répétition et reprise avec F maintenu. Accessibilité couvre aussi le colosse. Coût matériel borné, mais neuf conteneurs et diffuseurs indépendants peuvent accroître nœuds/draw calls. Les bandes autonomes restent limitées. Le risque principal est la propagation contexte/alarme, pas le nombre brut de classes.
- **Q** : palette concrète, différence Archives/atelier lisible sur le papier, suppression complète du spot téléporté. Une seule horloge d'alarme, un seul writer par ressource. Le budget des ombres est clair mais le spot mobile et les sources transitoires Low restent à mesurer. Les gardes de curseur et le maintien de F après modale ne sont pas spécifiés aussi nettement que dans R. Les bandes seules n'éclairent pas les silhouettes : rendu sombre obligatoire.
- **P** : meilleur traitement explicite de l'approche des disjoncteurs sans batterie, avec alimentation autonome clairement nommée. En contrepartie, portée8m et sources persistantes OFF augmentent les recouvrements; la route historique ON ne mesure pas cet état. Réutiliser « Budget des effets » évite un réglage, mais modifie le sens d'une préférence existante. Le colosse n'est pas stabilisé par cette option et le néon n'est pas explicitement suspendu à la fin. Ce sont des points de synthèse à résoudre, pas des régressions constatées.

## Greffes recommandées sur Q

1. **Depuis R : contrat d'input complet.** Refuser inactif, décès, curseur libre et répétition clavier; une pression vaut une bascule; tester F maintenu lors de reprise. Préserver l'état en pause, OFF au nouveau joueur/chargement, énergie et relais inchangés.
2. **Depuis R : effets réduits sans chute du colosse.** Préférer une référence stable à la simple borne0,75 de Q pour cette option d'accessibilité; son et événement narratif restent actifs. Tester lumière et émission ensemble. Valeur finale à juger sur rendu.
3. **Depuis P : nommer l'alimentation autonome dans les données/tests.** Une distinction explicite MAINS/BACKUP ou équivalent local évite l'hypothèse incorrecte « toute source située dans le circuit est OFF ». Ne pas importer automatiquement toutes ses autres couches.
4. **Depuis P, conditionnelle seulement : secours faible permanent OFF.** Si Q échoue aux captures Low, énergie0, lampeOFF malgré palette/ambiance/balisage réglés, expérimenter ces deux sources déjà allouées. Mesurer alors un scénario OFF prolongé, séparé du trajet ON. Aucun bénéfice de coût supposé.

Ne pas greffer les conteneurs R sur la table Q : conserver un seul modèle de propriété. Ne pas cumuler polling temporel et signaux d'alarme sans besoin démontré. Ne pas adopter le glow sans comparaison distincte.

## Contrôles statiques et gates avant production/livraison

HEAD vérifié : `e5b0bafa7b8bad369e6767a908b1d8391343b9f2`, branche assignée `feat/issue-09-lighting`. Sources consultées en lecture seule : `power_consumers.gd:126-168`, `world.gd:527-571`, `player.gd:306-326`, `main.gd:637-680`, `test_sector_power_effects.gd:12-80`.

La source confirme que PowerConsumers écrit actuellement la visibilité de lentille au début et à l'arrêt; transférer réellement ces écritures, pas seulement son matériau. `_refresh_power` précède `cut_alarm`, puis `state.changed` suit : vérifier le premier frame rouge et son extinction, y compris après rétablissement/N-7. La nouvelle composition ne doit pas attendre une autre interaction.

Les tests actuels imposent indices, positions et spot mobile. Migrer ces assertions vers alimentation, origine, qualité, synchronisation et budget d'ombres; conserver les checks de courant, idempotence, restauration et progression. Ne pas simplement supprimer les assertions devenues gênantes.

Gates proposés : rouge parent comportemental; tests verts ciblés puis parcours des deux fins; captures appariées avec ennemi vivant et interaction sombre; revue indépendante des pixels; cinq paires Normal/Low sur route historique; scénario distinct cœur/alarme/lampe et OFF prolongé si secours retenu. Hashes moteur/sonde/wrapper, aucun encodeur pendant mesure. Tous les coûts restent hypothétiques et le GPU joueur absent reste non validé.

Limite d'anonymisation : la dernière ligne de R contient encore un chemin de candidat original. Aucun dossier correspondant ni mapping consulté; ne pas utiliser ce chemin comme preuve d'identité ou de qualité.

Seul ce rapport est écrit. Aucun descendant, runtime, commit, push ou PR. Worktree consulté puis relâché; aucun processus persistant créé.
