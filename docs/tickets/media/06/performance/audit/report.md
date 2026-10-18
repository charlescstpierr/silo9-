# Audit indépendant des performances — ticket 6

**Preuves cohérentes, aucune différence isolée au-delà de la variation entre essais sur ce rendu logiciel.** Les chiffres ne démontrent ni une amélioration, ni une absence de surcoût, ni le respect d'une cible à 60 images/s sur PC joueur.

Audit exécuté par `python3 .cstack/orchestrate/silo9/issue06/performance-audit/audit.py`, sortie 0. Aucun nouveau rendu, profilage ou benchmark lancé par cet audit. Aucun fichier du jeu modifié. Script, résultats numériques et empreintes : `audit.py.txt`, `audit.json`, `console.json` dans ce dossier public. Le script est une copie de référence dépendant de l’arborescence privée de la campagne. Sa commande ci-dessus décrit l’exécution originale, pas un outil autonome dans ce dossier.

## Résultats recalculés

Chaque cellule donne la médiane de cinq essais, suivie de leur minimum–maximum. Les percentiles de chaque essai sont recalculés depuis les intervalles bruts triés, indice `floor(N * p)` borné à `N - 1`.

| Variante | p50, ms | p95, ms |
|---|---:|---:|
| Base 0473efb | 92,706 (92,024–94,898) | 110,849 (108,325–112,180) |
| Normal 5fd906f | 94,103 (91,993–94,670) | 112,328 (109,821–114,247) |
| Minimal 5fd906f | 95,269 (92,746–96,070) | 111,466 (104,813–130,343) |
| Réduit 5fd906f | 93,163 (90,277–97,239) | 113,291 (101,816–115,183) |

Les plages se recouvrent. À titre diagnostique, un test exact bilatéral de somme des rangs sur les cinq p50 de chaque côté donne p=0,841 pour normal, 0,095 pour minimal, 1 pour réduit. Ce petit échantillon alterné ne constitue pas une démonstration d'équivalence. L'écart des médianes normal/base est +1,397 ms ; il reste dans la variation observée.

Tous les essais ont un maximum de 343 appels de dessin. La base atteint 669 nœuds et 82 ressources ; chaque budget candidat atteint 681 nœuds et 83 ressources. La préallocation reste présente, même avec le budget minimal.

## Intégrité et travail réellement exécuté

- Vingt sorties 0, sans erreur moteur détectée ni échec de scénario ; cinq répétitions par variante, ordre des quatre variantes inversé un tour sur deux.
- Chaque essai produit neuf tirs acceptés, neuf impacts reçus par la cible physique invisible, 296 dégâts : cinq D9 et quatre ARC. Les débits de munitions et d'énergie sont vérifiés événement par événement. La séquence comprend le rechargement D9 réel, les changements d'arme et trois secondes de stabilisation.
- Les intervalles complets de boucle sont enregistrés pendant cette séquence ; le PNG de chauffe est écrit avant l'enregistrement. Le film et le profilage ne figurent pas dans les vingt essais.
- Les 180 fichiers de source/tests suivis de 0473efb et les 187 de 5fd906f correspondent aux blobs Git et aux fichiers locaux. Les vingt manifestes correspondent au manifeste gelé ; leurs contrôles avant/après indiquent une campagne inchangée. Les deux préparations correspondent également à ce manifeste.
- Les copies du script GDScript et du lanceur Python de chacun des vingt essais ont été hachées indépendamment et comparées au manifeste. Les fichiers actuels des outils et du moteur correspondent aussi aux empreintes gelées.
- Godot 4.7.2 stable officiel, X11, Compatibility/OpenGL, llvmpipe LLVM 21.1.8, 1280×720, qualité normale ; progression des images effectivement dessinées vérifiée pour chaque essai. Les journaux bruts, agrégats et résumés concordent.
- PNG `../performance-final/perf-1-candidate-normal/renderer-warmup.png` inspecté visuellement : scène industrielle réelle, arme et HUD visibles à 1280×720. Cette image au repos ne prouve pas à elle seule la qualité des effets de tir.

Les variantes de performance changent seulement le budget avec caméra à 0,5 et lumière à 1. Elles diffèrent des profils combinés des captures d'inspection, qui changent plusieurs réglages ensemble.

## Facteur dominant observé

La passe de profilage séparée utilise la même révision 5fd906f et le même scénario de neuf impacts/296 dégâts ; sortie 0 et absence d'erreur vérifiées. Son échantillonneur lit les deltas CPU des threads dans `/proc` toutes les 0,5 seconde. Les champs `utime` et `stime` sont correctement additionnés, puis normalisés par `SC_CLK_TCK` et le temps écoulé.

Sur ses 29 échantillons, la fenêtre approximative entre la date du PNG de chauffe +1 seconde et celle du JSON final −1 seconde retient les indices 12 à 26, soit 15 échantillons. La reconstruction avec l'horloge de ce démarrage retrouve exactement ces indices. Ils sont figés dans le script d'audit pour rendre le recalcul possible après redémarrage.

Recalcul : **491,64 % d'un cœur CPU** pour l'ensemble des threads du processus, dont **447,73 % pour les threads llvmpipe**, soit **91,07 % du CPU observé**. L'hôte expose huit CPU : les chiffres restent sous la capacité totale de 800 %. Cela identifie le rendu logiciel comme travail CPU dominant du processus observé ; ce n'est ni une mesure d'utilisation GPU ni une preuve qu'aucun autre facteur ne limite le temps d'image. Le relevé CPU final précède d'environ 82 secondes le premier PNG de la campagne chronométrée ; le profilage est explicitement exclu des agrégats.

## Limites et verdict

La charge avant lancement des essais varie approximativement de 1,56 à 4,09 sur huit CPU. Les répétitions alternées réduisent le biais temporel sans supprimer le bruit de l'hôte. Les intervalles comprennent ordonnancement et VSync ; le binaire utilisé est le moteur officiel lançant les sources, pas une comparaison de versions exportées optimisées sur GPU joueur.

La séquence est courte et stationnaire. Elle établit que les effets n'ajoutent pas de différence distinguable dans cette campagne dominée par le rendu logiciel. Elle ne prédit pas les performances d'une exploration complète, d'un combat dense, d'une carte graphique cible ou de Windows. Les mesures de FPS cible restent à faire sur le matériel pertinent.

Aucun défaut d'intégrité ou d'agrégation trouvé. Aucun worktree créé, aucun descendant lancé, aucun processus persistant détenu ; tranche libérée au parent.
