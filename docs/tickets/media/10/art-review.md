# Revue artistique indépendante du ticket 10

Verdict : **PASS borné aux 54 PNG ouverts**, pour la distinction des trois salles et la lisibilité des cibles sur les poses contrôlées. Aucun défaut P1/P2 établi sur ce périmètre. Ce verdict ne valide pas une qualité proche de Fortnite : la composition progresse, mais la finition des surfaces, des raccords et de l'usure reste sommaire.

Revue effectuée le 2026-10-18. Règles communes cstack 0.8.0 chargées, ainsi que le skill Unslop pour la rédaction. Documents lus : `design/accepted.md`, `implementation/report.md`, `baseline-identity.json`. Le rapport d'implémentation identifie le candidat par le SHA256 de world_art.gd `c3a973b5774ba521a29deff13dd9234db260c5e0329a0ecfc20da3d53b866cf0`. Cette revue n'a pas recalculé son hash ni audité le code.

- [x] Ouvrir les six comparaisons principales base09/candidat, Normal et Low.
- [x] Ouvrir les vues finales OFF avec lampe, les cibles proches et les suppléments pertinents.
- [x] Évaluer les différences sans utiliser les noms de salles du HUD.
- [x] Consigner les images réellement ouvertes et les limites.

## Résultat visuel

| Salle | Observation directe | Réserve |
| --- | --- | --- |
| Décontamination | Les grands panneaux crème et leurs bandes teal donnent un repère identifiable depuis l'axe central, en Normal comme en Low. Les machines restent visibles, la porte et le chemin central restent dégagés. Les profils et les joints séparent les panneaux de la cloison. | De près, les aplats crème occupent une grande partie de l'image avec très peu de variation. La plaque sombre au bord droit se lit comme un panneau technique, mais son rôle de réparation demeure peu explicite. |
| Maintenance | Les panneaux orange à gauche et sombres à droite apportent une asymétrie absente de la base. La vue tournée vers le collecteur confirme une conduite épaisse avec des attaches espacées, identifiable sans HUD. L'établi et le relais restent séparés du collecteur. | Le collecteur est presque hors champ sur la pose générale09 orientée à droite. Cette pose distingue surtout la salle par la couleur et l'asymétrie. De près, la tôle orange et les traits noirs sous le raccord évoquent imparfaitement une réparation et des coulures. |
| Archives | Les armoires forment de grandes verticales, avec des bandes cyan nettement lisibles sous tension. Elles distinguent la salle des parements crème et orange. N-7 et le personnage dans l'allée gardent des silhouettes dégagées. Le texte mural devient entièrement lisible dans les deux qualités ; la référence le masque. | Les façades perdent beaucoup de détail technique. Sur `detail_dark_bay.png`, elles ressemblent à des blocs sombres parcourus de lignes, avec quelques traits d'abrasion très géométriques. La travée sombre reste une rupture discrète. |

Ces conclusions viennent des formes, couleurs et objets visibles. Aucun masquage ou recadrage du HUD n'a été produit ; il s'agit d'une évaluation visuelle qui ignore son texte, pas d'un test aveugle auprès de joueurs.

La réduction des conduites et chemins de câbles supprime des diagonales qui donnaient davantage de profondeur au plafond de la base. Les cadres, luminaires, lignes du sol et portes successives maintiennent la perspective. Les salles paraissent plus dégagées, mais aussi plus nues en hauteur. Le rendu n'est donc pas uniformément meilleur sur tous les critères : il gagne en hiérarchie des masses et perd en densité industrielle.

Les surfaces sombres des Archives et les plaques crème restent lisibles en Low malgré les contours crénelés. La simplification n'efface pas l'identité des salles dans les images ouvertes. Elle ne suffit pas à donner une matière travaillée ou l'usure crédible attendue d'une finition stylisée aboutie. Une future passe devrait concentrer quelques variations sur les raccords et les bords déjà présents, puis les comparer aux mêmes poses, avant d'ajouter du détail partout.

## Cibles et états

Dans `verified-lighting-{normal,low}/`, les six vues critiques par qualité montrent le relais, le disjoncteur Maintenance et la preuve, lampe éteinte puis allumée. Aucun nouveau parement ne les coupe sur ces poses. Lampe éteinte, le dessus du relais reste sombre ; lampe allumée, sa tête et son socle deviennent nettement plus lisibles. La poignée du disjoncteur reste discernable dans les deux états. La face cyan de la preuve ressort de l'armoire sombre située derrière elle.

Les trois vues générales OFF avec lampe par qualité conservent le passage central et les repères principaux. Aux Archives, l'extinction des bandes cyan laisse encore apparaître les montants des armoires. Les vues supplémentaires du disjoncteur Archives et de N-7 montrent aussi leurs contours dégagés.

Le texte `LES ARCHIVES NE MENTENT PAS. LES VOIX, PARFOIS.` est intégralement visible dans les suppléments candidat Normal/Low, contrairement aux deux références correspondantes. C'est une amélioration vérifiée par les pixels, pas seulement reprise du rapport du builder.

Les trois décalages de caméra devant le parement Décontamination ont été ouverts dans les deux qualités. Aucun motif de chevauchement instable n'apparaît dans ces six arrêts sur image. Cela ne valide pas l'absence de scintillement pendant une marche continue. Aucun faux abri ou nouvel obstacle apparent n'a été identifié dans les poses ouvertes ; les collisions et les tirs relèvent d'une autre vérification.

## Couverture exacte et limites

La liste complète figure dans [art-review/opened-images.txt](art-review/opened-images.txt). Chaque ligne correspond à un PNG ouvert avec l'outil de visualisation, sans retouche.

| Groupe | Images ouvertes |
| --- | ---: |
| Base09, trois vues générales ON/lampe OFF, Normal/Low | 6 |
| Candidat final verified-lighting, mêmes trois vues ON/lampe OFF | 6 |
| Candidat final verified-lighting, trois vues OFF/lampe ON | 6 |
| Candidat final verified-lighting, relais/disjoncteur Maintenance/preuve, lampe OFF/ON | 12 |
| Suppléments base/candidat, collecteur gauche/N-7/texte Archives, Normal/Low | 12 |
| Suppléments candidat, réparation gauche/baie sombre/disjoncteur Archives, Normal/Low | 6 |
| Suppléments candidat, trois décalages Décontamination, Normal/Low | 6 |
| Total | 54 |

Les catalogues finaux comptent 44 poses par qualité selon le rapport d'implémentation ; seulement 12 poses par qualité y ont été ouvertes ici. Les dossiers intermédiaires `final-lighting-*` et `preview-*` n'ont pas servi au verdict. Les suppléments ont une provenance distincte, décrite par le builder ; cette revue les utilise comme comparaisons visuelles, sans leur attribuer le validateur du catalogue44.

Aucun moteur, test, benchmark, export, traitement d'image, commande Git ni descendant lancé dans cette tranche. Aucun fichier source modifié. Le runtime n'a pas été utilisé. Pas de conclusion sur les FPS, le coût GPU, les interactions natives, Windows, une mission complète ou les autres poses. La diminution des pièces visibles ne prouve aucun gain de performance.

