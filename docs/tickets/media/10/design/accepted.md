# Conception retenue, ticket 10

Base B, proposition anonyme R. Les deux juges frais recommandent R à22/25; parent23/25. Les anciennes passes de jugement ont été interrompues après fuite de contexte et sont exclues, voir blindness-incident.json. Les trois conceptions convergent vers WorldArt et trois recettes privées; leurs compositions graphiques diffèrent. Les alternatives PackedScene et catalogue ont été comparées et rejetées sans inventer une abstraction pour varier le code. Aucun dossier n'est une exécution verte.

## Contrat de production

Reprendre b/design.md comme base avec les précisions suivantes. Seul scripts/world_art.gd peut changer. Aucun nouveau collider, lumière, matériau, texture, particule, état, API publique, interaction ni ressource de mission. World/Player/Enemy/courant/sauvegarde restent intacts. Garder méthodes de batching, préparation des matières et qualité inchangées. Conserver exactement le décor hors des trois secteurs, les luminaires09, le cœur/rotor, refuge, barrières et textes.

- Décontamination : grandes plaques crème plaquées sur les ailes de la cloison existante, bande teal interrompue et une zone sombre indiquant un panneau remplacé. Garder les vitres et les vraies machines. Retirer rails/conduites répétitifs remplacés. Pas de grandes arches libres initialement; elles restent une alternative seulement si les pixels ne distinguent pas la salle.
- Maintenance : collecteur mural à gauche, largement espacé, loin du relais droit. Retirer cylindres décoratifs de sol et répétitions remplacées. Garder établi/outils existants, aucun nouveau capot ou bac débordant au-dessus d'un solide. Usure concentrée sous un raccord et tôle de réparation plaquée, pas du bruit partout.
- Archives : grandes verticales sur les six armoires solides existantes. Face de départ X±8,33, épaisseur à régler depuis la face physique réelle X±8,35. La surface visible doit rester à≤0,04m du solide, vérifiée par ses bornes transformées. Garder visibles les bandes cyan World. Une travée sombre sans nouvelle masse fait la rupture narrative; pas de faux écran/loot. Retirer rails et petites grilles/points WorldArt remplacés.
- Les formes basses restent plaquées aux volumes solides, avec contrôle de leur silhouette depuis les approches. Une simple empreinte X/Z n'autorise pas une pile au-dessus. Les pièces hautes n'empiètent ni sur les portes et leur débattement ni sur les visées.
- Un seul propriétaire par composition; trois méthodes privées, sans trois passes ajoutées sur l'ancien décor. Retirer d'abord les éléments répétitifs des salles, conserver ceux du refuge/cœur. Ne pas modifier un helper partagé pour imposer une teinte locale.
- Même palette, mêmes ombres par famille, portées32/44m, Low0,67. Une réduction de pièces ne prouve pas un gain de coût.

## Parcours de vérification déclaré avant implémentation

Production hors TDD de présentation pure, conformément à skills/tdd/SKILL.md. Les placements et formes visibles changent; aucun comportement d'interaction, validation, physique ou progression n'est ajouté. Ne pas fabriquer de test rouge fondé sur le nom d'une méthode ou une liste artistique. Exécuter les suites existantes pertinentes, comparer les pixels et la géométrie, puis deux missions et le coût rendu. Si un changement de comportement devient nécessaire, arrêter cette extension de périmètre et ouvrir son cycle rouge/vert avant de la coder.

Un nouvel outil de vérification peut être développé séparément sous issue10/proof-tools, sans modifier la production. Ses propres gardes exigent des cas négatifs avant adoption : plaque traversant une approche avec origine hors réserve, pièce tournée dont le bord entre, plaque coupant la visée vers le relais, même plaque derrière la cible acceptée. Ne pas construire deux vérificateurs concurrents. Inspecter les triangles réellement transformés ou les émissions réelles avant fusion; ne pas recopier une liste théorique. Les AABB peuvent éliminer des candidats, pas prouver seules une intersection de visée. Toute intrusion préexistante est explicitement comparée à la base, jamais masquée par une exclusion de salle.

Le relevé géométrique distingue statiques et acteurs, inclut MeshInstance et MultiMesh, compte surfaces/triangles/instances et compare les formes/couches/transforms physiques. Les réserves et segments proviennent des vraies cibles/portes et des approches listées dans explore-gameplay. Ce contrôle ne remplace pas la revue visuelle de faux abris ou des tirs.

## Pixels et coût

Utiliser les captures09 avec leur provenance, identité152fichiers établie, et la sonde originale figée pour les mêmes poses. Trois vues principales et vues proches de relais, disjoncteurs, preuve et N-7, Normal/Low, alimentation et lampe comparables. Aucune retouche d'image pour embellir la preuve. Le builder produit d'abord un aperçu Décontamination puis les trois secteurs afin de corriger les proportions avant la campagne finale.

Le critère est la distinction des trois salles même sans lire le HUD, avec des cibles lisibles. Si l'aperçu échoue, ajuster proportions ou retirer des formes dans les mêmes réserves; pas de retour silencieux aux mêmes couloirs avec quelques boulons. Confirmer l'absence de z-fighting en mouvement.

Deux nouvelles missions source MÈRE Normal/N-7 Low avec E/F natifs, physique, combat et coupures, puis test du binaire exporté. Le choix final reste celui du pilote existant et sera décrit honnêtement. Cinq paires alternées par qualité selon perf-plan.md, aucune capture concurrente. Ajouter des fenêtres stationnaires seulement si la route ne couvre pas les façades. GPU joueur et Windows restent non validés; pas de promesse Fortnite ou60FPS.

## Propriété

Un builder possède seulement world_art.gd et ses rapports/aperçus sous implementation/. Le parent possède les commits et runtime100 lorsqu'il n'est pas prêté explicitement. Un auteur d'outil peut préparer des fichiers disjoints, sans moteur tant que le builder utilise le runtime. Aucun push/PR par les délégués. Les suites et preuves ne doivent pas être réécrites pour masquer un échec.
