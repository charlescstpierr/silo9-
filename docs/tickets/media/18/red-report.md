# Ticket 18 : tests avant production

La phase rouge est terminée. Les quatre comportements monde échouent sur la production inchangée au HEAD `28e402821469655598c6a84bc415d8ea04da97c2`. Aucun cycle vert ni changement de production n'a été entrepris. Le parent doit lire les tests et les journaux avant d'autoriser la phase suivante.

Worktree : `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-18`, branche `feat/issue-18-world-persistence`. Ce worktree était fourni par le parent ; aucun worktree créé, commit, publication ou descendant.

Skills lus/appliqués : cstack TDD, règles runtime/base, contrat de délégué cstack-agent et unslop. Contrats lus : brief, grounding, accepted et accepted-review. La phase se limite aux trois nouveaux fichiers de tests et aux preuves ci-dessous.

## Résultats retenus

| Suite | Assertions | Réussites | Échecs attendus | Code |
| --- | ---: | ---: | ---: | ---: |
| `tests/test_world_persistence.gd` | 50 | 26 | 24 | 1 |
| `tests/test_persistence_state.gd` | 171 | 150 | 21 | 1 |

Les commandes exactes, durées et SHA-256 des fichiers réellement exécutés sont dans `red-tests/results.json`. Les journaux retenus sont `red-tests/test_world_persistence.log` et `red-tests/test_persistence_state.log`. Les sorties retenues n'ont aucune erreur d'import, de syntaxe, de script ou moteur. Le dernier run monde signale toutefois quatre références ObjectDB résiduelles à la fermeture ; le diagnostic audio borné est décrit ci-dessous. Le run état n'a aucun avertissement. Les erreurs et avertissements sont consignés séparément dans results.json.

Commande reproductible, depuis le worktree :

```sh
.tools/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --script tests/test_world_persistence.gd
.tools/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --script tests/test_persistence_state.gd
```

### Les quatre rouges monde

1. **Caisse réelle : cinq échecs.** La raycast initiale identifie le collider à `(4,0,-12)`. Le vrai changement d'arme termine ; l'ARC est tiré et conserve la caisse. Le D9 consomme ensuite une munition ; la raycast de caméra cible le même collider et le marqueur d'impact tombe sur ce collider. Après ce tir, le collider bloque encore, aucun ensemble de trois panneaux n'apparaît et aucun booléen canonique n'enregistre la casse. Après `main.save_run` puis `main.load_run`, la caisse bloque toujours le rayon et le balayage d'une capsule joueur. Les tests ne remplacent pas la caisse par un objet factice.
2. **Deux variantes robot : dix échecs.** `sentinel_1` est déplacé à `(1.2,0,-23.5)`, yaw `0.73`; `crawler_1` à `(-2.2,0,-29.5)`, yaw `-1.17`. L'API `receive_hit(1000,0)` neutralise chaque vrai Enemy et inscrit son ID. Le signal ne contient pas de pose, aucune nouvelle géométrie de trace n'apparaît immédiatement ni après 2,6 s, et aucune pose n'est sauvegardée. Le chargement remplace Player et World et ne ressuscite pas le robot ; il ne restaure pas non plus de trace à la pose de mort.
3. **Verrou ARC : six échecs.** Le premier impact inscrit le fait mais produit plusieurs notifications. Le test observe les snapshots reçus pendant `changed` pour exiger fait et souvenir ensemble. Un autre souvenir est inséré avant sauvegarde pour exposer le doublon au-delà de la seule déduplication consécutive. Après reconstruction, le booléen, l'invite et l'émission visuelle ne correspondent pas à l'état inactif. Le second impact émet des événements et ajoute de nouveau le souvenir. La suppression de la barrière, déjà fonctionnelle, reste une protection verte distincte.
4. **Porte : trois échecs.** La progression réelle répare le relais. L'ouverture jouée reste animée et atteint bien y=4. Après sauvegarde/chargement, avant toute frame, porte et collider sont de nouveau en position fermée ; le rayon reste bloqué après deux étapes de synchronisation physique. Le test n'attend pas le tween de restauration avant son assertion.

Tous les rechargements de ces scénarios utilisent `main.load_run` et vérifient de nouveaux identifiants d'instance pour Player ET World. Le rejet d'une sauvegarde avec pose orpheline protège aussi l'état et les acteurs actifs.

### État et fichier

Les 21 échecs se répartissent ainsi : 12 migrations vers le schéma 4, un schéma 4 valide refusé, une borne de pose valide refusée, trois assertions de capacité 128+6, quatre assertions de refus d'une écriture trop grande.

Les vraies fixtures historiques 2/3 sont construites sans les nouvelles clés. Les phases 0/1/2/3, les deux fins, les faits et IDs génériques sont préservés. Le schéma 2 restaure les circuits ON, le schéma 3 conserve une combinaison OFF/ON. Chaque ancien schéma accepte 128 IDs et refuse 129 sans modifier état, révision ou signaux. Ce sont des protections déjà vertes.

La capacité est exercée en chargeant 128 IDs historiques, puis en appelant l'API actuelle `mark_defeated` pour les six IDs réellement construits dans World. La baseline garde seulement les 128 historiques et perd ces nouvelles défaites. Aucun appel à une classe future n'est nécessaire.

La fixture de taille contient des IDs et souvenirs Unicode conformes aux bornes de champs. Le JSON fait exactement 65 536 puis 65 537 **octets UTF-8**, mesure vérifiée avant chaque essai. Le fichier de 65 536 octets est sauvegardé et rechargé. À 65 537, la baseline accepte l'écriture, écrase le fichier valide et le temporaire sentinelle, puis refuse son propre fichier à la lecture. L'état mémoire, la révision et les signaux ne changent pas pendant l'essai.

Les erreurs d'ouverture du temporaire, de rename et d'écriture conservent déjà le précédent fichier. Les fixtures utilisent respectivement un répertoire au chemin temporaire, un parent non modifiable avec fichier temporaire encore modifiable, et un lien temporaire vers `/dev/full`. Les permissions sont restaurées et les fichiers dédiés supprimés. Ces succès ne sont pas présentés comme des rouges, ni comme une preuve du nouveau mécanisme de relecture du temporaire.

## Limites et essais exclus

- Le rejet des poses invalides couvre types, clés, ID inconnu/orphelin, longueur du vecteur, bornes et nombres non finis. Sur la baseline, le schéma 4 entier est refusé : ces succès ne prouvent donc pas les validateurs individuels. Le cas positif schéma 4 devra d'abord passer après implémentation.
- Les copies entrante et sortante de DeathPose, la normalisation du yaw et l'interdiction de déplacer une pose au second décès sont écrites derrière le chargement positif du schéma 4. Elles sont explicitement **non exercées** sur la baseline. Aucun faux rouge fondé sur l'absence de classe ou méthode n'est revendiqué.
- Les assertions sur le sous-arbre d'une trace, son absence de traitement par frame et sa stabilité sous 20 refresh sont également conditionnées à l'existence réelle d'une trace. Elles restent à exercer après production.
- La relecture validante du temporaire n'a pas de rouge indépendant ici. Une première fixture `/dev/null` provoquait déjà un refus d'E/S ; elle a été reclassée et remplacée par `/dev/full`. Aucun test ne prétend distinguer actuellement validation de relecture et erreur d'écriture.
- Les premiers essais de compilation, conservés dans `*-attempt*.log`, contenaient des erreurs de fixture : notation octale non admise, inférence de type et appel statique de `create_link`. Ils sont exclus de la preuve rouge.
- `world-attempt2.log` est exclu pour la caisse : le tir échouait parce que la physique figée empêchait la fin du changement d'arme. La fixture termine maintenant le vrai changement d'arme et vérifie le tir ainsi que son impact. Aucune assertion de comportement n'a été affaiblie.
- Un essai verbose borné, `world-attempt3.log`, identifie les quatre références ObjectDB résiduelles comme deux AudioStreamWAV et deux AudioStreamPlaybackWAV. Le dernier run monde retrouve un avertissement de quatre instances ; le run état n'en émet aucun. Aucune correction audio hors périmètre n'a été faite, et aucun processus moteur ne subsiste.
- Exécution headless seulement. Aucun parcours manuel de marche aller-retour, capture Normal/Low, budget GPU, allocation sous six carcasses, export, audio matériel ou test Windows n'est revendiqué. Les actions robot et ARC sont injectées via leur API de dégâts ; seul le scénario caisse exerce le vrai hitscan Player.fire.
- Cette phase n'a pas relancé les anciennes suites ; leurs résultats de baseline restent les preuves du parent. Les anciennes fixtures et leurs configurations n'ont pas été modifiées.

## Intégrité et libération

`red-tests/tracked-before.json` et `tracked-after.json` contiennent les empreintes des 2 557 fichiers suivis. `red-tests/integrity.json` confirme **zéro fichier suivi modifié**, donc aucune source de production, ancien test, configuration, asset ou outil modifié. Les trois nouveaux fichiers autorisés sont la seule modification dans le worktree ; les UID déjà non suivis avant les essais sont conservés.

Les sauvegardes par défaut sont sauvegardées puis restaurées par la fixture ; les fichiers dédiés aux essais sont nettoyés. `red-tests/runtime-release.json` consigne l'absence de processus Godot après la phase. Aucun serveur X11 n'a été lancé ni arrêté. Le runtime headless et la réservation X11 :100 sont libérés au parent, ainsi que l'exclusivité d'écriture des trois tests. Le worktree reste en place pour la lecture du parent. Arrêt à la phase rouge, sans autorisation implicite de production.
