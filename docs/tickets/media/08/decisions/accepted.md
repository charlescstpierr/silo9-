# Conception retenue pour le ticket 8

La base est **B**, présentée à l’aveugle sous le label **R**. Le parent lui donne 22/25. Les deux juges la recommandent à 22/25, après lecture en ordre inversé. Les quatre dossiers ont été lus ; l’alternative D sans textures fournit la seconde forme structurelle requise. Ce sont des conceptions non exécutées, pas des résultats visuels ou de performance. Les acteurs utilisent le même modèle hérité ; aucune diversité de modèles n’est revendiquée.

## Propriété et ressources

Les API `Visual.build(electric)` et `HandMesh.build(...)` restent identiques. `Player`, le rig, `ViewFrame`, le gameplay et les options de qualité ne changent pas. Les constructeurs possèdent les UV ; les ressources Godot possèdent l’apparence.

Neuf `StandardMaterial3D` préchargés sous `assets/fps/materials/` : `paint_d9`, `paint_arc`, `steel`, `insulator`, `contacts`, `signal_d9`, `signal_arc`, `glove`, `cloth`. Conserver les cinq slots d’armes et les deux surfaces des bras. Ressources partagées et immuables après construction, sans nouvelle classe de service, fabrique ou registre.

Au plus six textures uniques sous `assets/fps/textures/`, chacune au plus 256×256. Les trois paires albédo/rugosité proposées sont peinture, gant et tissu. Réduire ou supprimer une carte sans apport visible. Métaux et isolants restent scalaires. Aucun shader personnalisé, normal map, AO, transparence, `next_pass` ou lumière supplémentaire.

Plafond conservateur : 2,1 MiB de texels RGBA8 avec mipmaps complètes, hors buffers et objets. Inventorier dimensions, formats, mipmaps, images uniques et compteurs disponibles. Cette estimation n’est pas une mesure de VRAM.

Les images sont originales et générées hors ligne de façon déterministe. Versionner le générateur, les fichiers utiles, les paramètres et leurs empreintes. Ne rien générer au lancement. Le dépôt n’a pas de licence générale déclarée : documenter la provenance originale sans inventer une licence CC0/MIT ni changer la politique de licence. Aucun asset Fortnite, téléchargement tiers ou plugin.

## Apparence à éprouver

La palette initiale de B est une hypothèse de rendu. Peinture, isolant, gant et tissu sont diélectriques ; acier et contacts sont métalliques. Ajuster la rugosité pour la lecture réelle. Retirer l’émission .035 des familles ordinaires, conserver l’émission .8 des signaux et l’Omni FPS actuelle .42/specular .45. Le métal partagé touche aussi les mires et de grandes structures : inspecter tous ces usages.

Les gants doivent se lire comme des gants, les manches comme du tissu. Commencer par des motifs répétables larges et calmes. La calibration des deux mains est reprise de A ; son panneau dorsal reste une option conditionnelle si les rendus démontrent le besoin. Ne pas introduire d’emblée `LoftFinish` ou un atlas sémantique. Une marge de huit texels ne garantit pas l’isolation aux petits mipmaps.

Comparer deux looks texturés, ainsi qu’un témoin privé sans cartes gardant la même palette et les mêmes scalaires. Un override de matériau dans l’outil de preuve suffit pour le témoin ; ne pas importer le service `Finish` de D. Le témoin retire les cartes, il ne représente pas une implémentation complète du candidat D. Supprimer les cartes si elles n’apportent rien de visible. Un seul look final et ses assets utiles entrent en production. Conserver aussi les images de la vraie base originale.

## Cartographie

Les UV sont attachés aux vertices de repos, sans recalcul par frame.

- Boîtes, chanfreins et tubes manuels utilisent une projection métrique locale par face. L’axe dominant vient de la normale finale calculée par produit vectoriel après correction du winding, pas de l’argument `outward` approximatif. Les triangles coplanaires partagent la même convention d’axe et de signe. Toute permutation déplace ensemble positions et UV.
- Les cylindres gardent leurs UV natifs. Leur densité différente sur les petites pièces est un compromis à inspecter, pas une raison de réécrire la primitive sans besoin visible.
- Les lofts utilisent U angulaire déroulé avec couture dupliquée et V en longueur cumulée au repos. Les caps ont une projection plane. Affecter explicitement tous les attributs des vertices, y compris leur couleur.
- Positions, normales, poids, os, triangles, transforms et marqueurs restent inchangés. La couture peut dupliquer des vertices et changer les indices. Comparer la géométrie après expansion des triangles, dans leur ordre, au lieu d’exiger les anciens indices identiques.
- Vérifier chaque triangle texturé : cardinalité et finitude des UV, aire non nulle, continuité des faces, dernière tranche de couture. Le flag d’un batch mixte boîte/cylindre ne suffit pas. Les tangentes natives peuvent rester ; aucune génération manuelle n’est nécessaire sans normal map.

## Budgets

Conserver au plus les surfaces actuelles annoncées : 11 D9, 18 ARC et 2 bras. Les confirmer d’abord dans le moteur ; corriger un décompte statique erroné avec preuve avant de figer le test. Ce ne sont pas des draw calls.

Neuf matériaux uniques au maximum, identités et propriétés stables durant R/B/ADS et les changements d’arme. Conserver les plafonds des bras de 24 000 sommets et 16 000 triangles. Aucune allocation matérielle ou d’image par frame, ni nouvelle passe, lumière ou instance de mesh. Low conserve les mêmes petites cartes mipmappées ; pas de nouvelle propagation de qualité.

## Gate avant construction

Une assignation **tests-only** établit d’abord les contrats observables de mapping, géométrie et budget sur les vrais constructeurs. Capturer si utile une référence de la géométrie de base avant modification ; le parent vérifie sa provenance. Les tests ne réimplémentent pas les formules de projection et n’utilisent pas de mocks. Agréger les erreurs pour éviter des milliers de lignes par triangle.

La base doit échouer sémantiquement avant toute production. Le parent lit et reproduit les rouges, puis donne une assignation distincte au builder. Ne pas affaiblir les assertions pour passer. Si un contrôle d’image demande un vrai renderer, prouver cette contrainte au lieu de traiter un échec technique comme rouge fonctionnel.

Exception hors TDD décidée maintenant pour les palettes, bitmaps et autres retouches de présentation pure : comparaison réelle avant/après à cadrage égal, variantes et revue visuelle indépendante. Cette exception ne couvre pas mapping, géométrie, gestion de ressources, validation ou qualité. L’apparence reste une hypothèse jusqu’aux rendus.

## Preuves de livraison

La base `98f2d4a` est archivée dans `issue08/baseline`, avec 192 fichiers sources/tests/assets. Godot 4.7.2, X11, Compatibility et llvmpipe sont le banc disponible.

Au minimum, comparer deux armes × trois lumières froid/rouge/faible × hip/ADS avant/après, puis SILO réel, Low et variantes de look. Identifier explicitement tout laboratoire isolé. Enregistrer caméra, pose, ambiante, lumière FPS, sources actives, masques, qualité, FOV et état. Ne pas appeler « rouge Low » une station dont la vraie lampe est éteinte.

Inspecter des séquences avec rotations lentes, angles rasants, R/B et ADS pour rechercher coutures et scintillement. Dire exactement quelles images ou séquences ont été regardées ; un décodage n’est pas un visionnage. Relancer les six suites ciblées `visual_geometry`, `fps_rig`, `d9_geometry`, `arc_geometry`, `arc_indicator`, `ads_geometry`, plus le nouveau contrat. Élargir seulement si un changement ou un échec le justifie.

Réutiliser le benchmark ADS avec cinq paires alternées, sans capture ni runtime concurrent. Figer source, outils et binaire ; recalculer p50/p95 depuis les intervalles bruts. Inventorier ressources, surfaces et mémoire. Les deux versions possèdent ADS : vérifier les mêmes FOV. L’avertissement historique de l’outil du ticket 7 sur un zoom différent ne s’applique pas si cette égalité est confirmée. Un profil séparé confirme le limiteur si nécessaire. Aucune conclusion sur 60 FPS, GPU cible, Windows, manette physique ou parité Fortnite.

## Greffes et rejets

B/R fournit les ressources natives et le mapping dans les builders. A/P apporte la calibration des deux mains et les dimensions selon le besoin ; sa fabrique et son mapping sémantique initial sont écartés. C/S apporte le contrat UV/winding, l’immuabilité et les attributs explicites des caps ; ses deux cartes d’isolant et sa normalisation de toutes les boîtes sont écartées. D/Q apporte la comparaison sans textures ; son service de couleurs et ses contrats supplémentaires d’os ne sont pas intégrés. Les corrections factuelles des juges restent dans leurs rapports.

Aucun candidat abandonné. La conception est relue et retenue par le parent et les deux juges ; son implémentation et sa vérification restent à faire.
