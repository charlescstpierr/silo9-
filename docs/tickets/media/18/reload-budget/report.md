# Budget des rechargements, ticket 18

**PASS borné sur vingt rechargements mesurés après deux d'échauffement.** Chaque reconstruction conserve six traces, dix-neuf instances visibles de restes, les six mêmes ArrayMesh et les trois mêmes matériaux robot. Le compteur global de ressources reste à 105. Aucun gameplay modifié ; aucun résultat GPU, export ou parcours natif déduit de cette séquence headless.

Run retenu : `run-20261018T160950Z/`, unique tentative moteur. HEAD `c105da61b2b490546f01c9d67703bfb405a2a44f`, branche `feat/issue-18-world-persistence`, worktree `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-18`. Les empreintes de tous les fichiers suivis sont inchangées avant/après. `metadata.json` contient les empreintes sources, outils et binaire ; `result.json` contient commande, environnement et verdict ; `measurements.json` garde chaque relevé et `runtime.log` la sortie verbose complète.

## Travail réellement exécuté

Le parent a transféré le runtime avant le lancement. `run.py --execute` a utilisé Godot 4.7.2 headless, un userdata isolé et aucune capture, aucun encodeur ou profil. Le jeu et ses tests suivis n'ont pas changé. La compilation Python était le seul contrôle préalable au transfert ; le probe GDScript a ensuite terminé du premier coup.

Le vrai Player a été placé devant la caisse : rayon sur le collider identifié, tir D9 accepté, impact au point attendu et munitions de 12 à 11. Chacun des six vrais Enemy a été déplacé de `(0.35,0,-0.45)`, tourné, puis neutralisé par `receive_hit(1000,0)`. Ces appels injectés aux ennemis sont distincts du parcours natif de combat. Déplacements et IA sont figés pour isoler les reconstructions.

Après le drainage initial, vingt-deux cycles ont appelé Main.save_run puis Main.load_run. Chaque cycle vérifie le fichier sauvegardé et de nouveaux identifiants Player/World. Six frames et deux synchronisations physiques précèdent le relevé ; les anciens acteurs sont alors libérés. Vingt refresh supplémentaires précèdent chaque inspection. Les traces sont lues dans la scène réelle, leur pose comparée au lieu de décès attendu ; aucun Enemy n'est recréé. Il y a 23 relevés : préparation, deux échauffements et vingt cycles retenus.

Le probe termine avec **186 assertions réussies, zéro échec et code 0**. Le validateur externe confirme structure, ressources, poses, reconstruction et état canonique. Huit contre-exemples appliqués aux mesures réelles sont tous rejetés : instance supplémentaire, nouveau mesh, nouveau matériau, acteur réutilisé, mauvaise pose, collision de caisse, traitement actif d'une trace et run incomplet. Ces mutations éprouvent le validateur, pas un second jeu modifié.

## Ressources observées

- Six traces, chacune avec trois meshes à une surface, aucune collision, lumière, timer ou callback par frame ; ombres OFF et portée locale 45 m.
- Six IDs de meshes et trois IDs de matériaux robot identiques pendant toute la séquence. Les tableaux récupérés représentent 3 153 sommets, 11 028 indices et 195 456 octets, sans croissance. Ce ne sont ni des triangles effectivement dessinés ni la mémoire GPU totale.
- Une instance MultiMesh de caisse, trois panneaux visibles, couche et masque nuls. BoxMesh et matériau partagés avec le World courant ; leurs identités peuvent normalement changer lors d'une reconstruction de World.
- Dix-neuf instances visibles de restes à chaque relevé. Ce nombre ne mesure pas les soumissions réelles au GPU.

Sur les vingt cycles après échauffement : 624 nœuds constants, 105 ressources constantes, zéro nœud orphelin. Le nombre global d'objets varie entre 2 856 et 2 860 ; premier et dernier valent 2 860. Huit nœuds audio sont présents dans chaque scène active.

La mémoire statique passe de 280 276 334 à 281 138 366 octets, soit **+862 032 octets**. Cette hausse est conservée dans le résultat. Le probe accumule lui-même des relevés et copies de snapshots ; sans profil d'allocations, la part du rapport et celle du jeu ne sont pas séparées. Le résultat permet d'affirmer la stabilité des ressources ciblées et du compteur de ressources, pas une mémoire totale strictement plate.

Après suppression de Main et dix frames supplémentaires, il reste un nœud, zéro orphelin, 1 721 objets et 47 ressources. Avant construction de Main, les compteurs étaient un nœud, 1 488 objets et six ressources. Le chargement initial et les caches ont donc laissé des objets/ressources disponibles pendant la vie du processus ; leurs classes ne sont pas toutes attribuées par ce probe. Le journal verbose de fermeture ne signale **aucun avertissement ObjectDB, aucune référence résiduelle et aucune erreur**. Cela ne corrige ni n'invalide les quatre références audio observées dans l'autre test monde, dont le drainage et le scénario diffèrent. Aucun arrêt audio ajouté pour obtenir ce résultat.

## Durées de transition

Les intervalles excluent préparation, inspection géométrique et écriture du rapport. Ils servent au diagnostic de cette seule séquence, sans référence comparée ni attribution d'un limiteur. La checklist de mesure a été appliquée en bornant la revendication ; ce relevé ne constitue pas un benchmark de performance.

| Intervalle, vingt cycles | Médiane | Minimum | Maximum |
| --- | ---: | ---: | ---: |
| Appel synchrone Main.save_run | 1,071 ms | 0,919 ms | 3,487 ms |
| Appel synchrone Main.load_run | 264,288 ms | 238,065 ms | 450,308 ms |
| Chargement et drainage des frames | 334,247 ms | 297,271 ms | 526,997 ms |

Le dernier intervalle inclut le contrôle des nouveaux acteurs et la désactivation de la simulation avant les attentes ; ce n'est pas du CPU pur. Les temps bruts des actions préparatoires restent dans measurements.json. Le run complet prend 12,745 s. Charge hôte initiale à une minute : 3,19. Aucun chiffre de débit, gain, coût GPU, fluidité ou mission complète n'est revendiqué.

## Libération

Tous les fichiers de cette tranche sont sous `reload-budget/`. Aucun commit, push, export, descendant, serveur X11 ou correction de production. `result.json` enregistre l'absence de Godot après la fin du processus et l'intégrité des sources. Le runtime a été explicitement rendu au parent immédiatement après lecture du résultat, avant rédaction de ce rapport. Aucun autre moteur ne sera lancé par cette tranche ; worktree conservé et relâché pour la campagne du parent.
