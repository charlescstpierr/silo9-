# Revue indépendante du code, ticket 18

**PASS borné : aucun défaut concret actionnable identifié dans le code et les tests assignés.** Les trois suites ciblées ont été relancées indépendamment sur les sources finales et passent. Ce verdict ne valide pas encore le parcours natif, la qualité visuelle en mouvement, les mesures de coût ou les exports.

Worktree examiné : `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-18`. Branche `feat/issue-18-world-persistence`. HEAD et base inchangés : `28e402821469655598c6a84bc415d8ea04da97c2`. Production non commitée, identifiée par `implementation/frozen-sources.json`. Aucun changement de source ou de Git effectué par cette revue.

Compétences appliquées : règles communes cstack, contrat de délégué, no-comments et comment-reviewer, unslop. Documents lus : accepted, accepted-review, grounding, red-report, parent-gate, rapport final du builder et ses manifestes. Diff complet contre la base et six fichiers de production lus, ainsi que les quatre nouveaux fichiers de test et l'adaptation de sector_power_state. Les appels voisins de main, interactable, power_consumers et les boucles sur les ennemis ont été inspectés.

## Contrats vérifiés

- `scripts/run_state.gd:196` réserve les 128 places aux IDs hors catalogue et permet les six IDs réels sans éviction. Une défaite répétée retourne avant toute mutation. L'entrée de pose est copiée, bornée et normalisée, la sortie copiée à la ligne 214. Défaite et pose sont inscrites avant l'unique signal. Les poses restent des annotations facultatives : aucune carcasse n'est inventée pour une vieille défaite sans pose.
- `scripts/run_state.gd:353` valide séparément les versions 2, 3 et 4, avec clés exactes, types, nombres finis, faits de progression et bornes historiques. Les poses doivent appartenir au catalogue et à defeated. Les conversions et collections temporaires précèdent les affectations du chargement, ligne 302. Le rejet ne touche ni état, ni révision, ni signal. `main.load_run` construit un nouvel état avant de remplacer Player et World ; l'ancien monde reste présent sur rejet.
- `scripts/run_state.gd:259` valide puis produit une chaîne JSON unique, mesure ses octets UTF-8 avant ouverture du temporaire, contrôle écriture et relecture avant renommage. Les tests exercent 65 536 octets acceptés, 65 537 refusés et les erreurs d'ouverture, d'écriture via `/dev/full` et de rename. Le précédent fichier reste identique. La relecture validante est réellement présente ; les tests d'E/S ne sont pas présentés comme son rouge indépendant.
- `scripts/destructible_crate.gd` possède modèle et collider. Le collider frère a été retiré de `world.gd`. Un tir D9 réel casse la caisse ; ARC la conserve. La projection coupe couche et masque et révèle trois panneaux. Les raycasts et le balayage d'une capsule vérifient l'absence de blocage après reconstruction.
- `scripts/run_state.gd:227` publie fait et souvenir ARC ensemble, une seule fois. `scripts/world.gd:475` restaure booléen, invite et matériau inactifs, puis coupe la collision de barrière avant suppression. Le second impact après reconstruction n'émet ni disabled, ni message, ni changed. La porte est posée à y=4 pendant `_build_structure`, avant toute frame, tout en conservant le tween de l'ouverture jouée.
- `scripts/enemy.gd:196` capture la pose globale réelle puis coupe physique et collision, masque le vivant et enregistre avant libération. `scripts/world.gd:361` ne construit aucun Enemy déjà défait. Le même constructeur produit la trace au décès et au chargement ; l'index par ID empêche sa duplication sous refresh. Le flux réel construit World à l'origine, donc l'affectation locale de la pose globale conserve ici le lieu exact.
- `scripts/robot_visual.gd:199` partage trois ArrayMesh par variante et trois matériaux existants. Chaque trace reste locale, sans Enemy, collision, lumière, timer ni callback par frame, ombres coupées et portée 45 m. Les pattes miroir inversent leurs indices avant leur transformation négative. Le contrôle géométrique vérifie les buffers générés et comprend un témoin négatif qui inverse de vrais triangles sans altérer la ressource partagée. Les plafonds structurels ne prouvent pas le coût GPU.

## Relances indépendantes

Le parent a transféré explicitement le runtime après sa libération par le builder. Aucune instance moteur n'a été lancée avant ce transfert. `code-review/rerun.py` exécute séquentiellement Godot 4.7.2 headless avec XDG_DATA_HOME, XDG_CONFIG_HOME et XDG_CACHE_HOME propres à la revue. Les commandes, durées, empreintes avant/après et résultats sont dans `code-review/results.json` ; les sorties intégrales sont les trois fichiers `.log` voisins.

| Suite | Assertions réussies | Échecs | Code |
| --- | ---: | ---: | ---: |
| persistence_state | 179 | 0 | 0 |
| world_persistence | 58 | 0 | 0 |
| remains_geometry | 93 | 0 | 0 |

Aucune erreur de script ou moteur. État et géométrie sans avertissement. Monde conserve l'avertissement de quatre références ObjectDB à la fermeture. Le journal rouge verbose `red-tests/world-attempt3.log:1128` identifie deux AudioStreamWAV et deux AudioStreamPlaybackWAV ; cette revue ne prétend pas avoir supprimé ces références ni avoir exécuté un nouveau diagnostic audio verbose.

Les onze empreintes sont identiques avant/après les relances et au manifeste final. Le hash final du test de géométrie est `657df091c8edc02b99e4de5572ca50a3cc29688b820b6fb9884a7d2f698b5757` ; sa dernière actualisation ne change que les libellés pour parler de géométrie générée. `git diff --check` passe. Les anciennes suites du builder ont été lues dans leurs relevés ; elles ne sont pas comptées comme relances indépendantes de cette revue.

## Provenance des rouges et commentaires

`code-review/red-integrity.json` consigne la lecture des deux journaux rouges : 21 échecs état et 24 échecs monde, sans erreur de script ou moteur. Le test état et la fixture ont exactement les hashes de la phase rouge. Retirer les deux seules lignes de protection circuit du test monde reproduit exactement son hash rouge `74b7288a9a950fff5b6d62c21adecae96d4c6d1a8df143abf972257dbf1ecf1e`. Aucune assertion rouge initiale n'a été affaiblie.

Les copies de poses et les assertions de sous-arbres, conditionnées à l'existence de la fonctionnalité sur la baseline, sont désormais parcourues au vert. Le journal `death-circuit-red.log` contient 58 assertions vertes : l'hypothèse circuit a été infirmée, les deux assertions ajoutées sont des protections, pas un nouveau cycle TDD. Les journaux winding conservent un rouge puis un vert sur les pattes miroir ; la présente relance confirme le contrôle final et son témoin négatif, sans rejouer une ancienne implémentation.

Revue no-comments : aucun commentaire ou contournement actionnable. Le seul commentaire ajouté explique la répartition des octets de la fixture UTF-8 et reste cohérent avec le calcul. Aucune directive de suppression, contrainte externe non prouvée ou code mort commenté ajouté. Zéro suppression, restauration, refactorisation ou encodage effectué ; aucune relance de revue commentaire nécessaire.

## Limites et libération

La preuve reste locale et headless : les APIs de dégâts injectent les décès et la désactivation ARC, tandis que la caisse utilise le véritable tir Player. La revisite en marche, les tirs natifs pour les autres objets, les effets actifs au moment de sauvegarder, les captures finales comparables, la stabilité des allocations sous rechargements répétés, le coût graphique et les exports restent au parcours de livraison du parent. Aucun audio matériel, GPU physique, Windows ou résistance à une coupure électrique déduit de ces résultats.

Écritures de cette tranche uniquement dans `code-review.md` et `code-review/`. Aucun worktree créé, aucune mutation Git, aucun descendant, aucun serveur X11 lancé ou arrêté. `code-review/runtime-release.json` atteste à 2026-10-18 15:51:37 UTC l'absence de processus Godot et l'intégrité du gel. Runtime et worktree relâchés au parent ; le worktree reste en place. Ce PASS autorise les vérifications de livraison suivantes, sans les déclarer accomplies.
