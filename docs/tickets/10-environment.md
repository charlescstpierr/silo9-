# Ticket 10 : identité des trois secteurs

Décontamination, Maintenance et Archives ont désormais des compositions distinctes. Les parements remplacent une partie des rails et conduites répétitifs. Le refuge, le cœur, les luminaires et les interactions conservent leur fonctionnement.

| Secteur | Ce que le joueur voit |
|---|---|
| Décontamination | Grandes plaques crème, bande teal interrompue, profils fins et panneau sombre au bord de la cloison. Les vitres et machines restent visibles. |
| Maintenance | Grandes tôles orange à gauche, parement sombre à droite, collecteur mural et attaches espacées. L'établi et le relais restent séparés de cette composition. |
| Archives | Grandes verticales sur les six armoires, bandes cyan conservées, une travée sombre et quelques abrasions. Le texte mural est maintenant entièrement visible. |

Source de production : `64a948545d63764cb500f6ac1a02380c5d1513f3`. Seul `scripts/world_art.gd` change, avec le SHA256 `c3a973b5774ba521a29deff13dd9234db260c5e0329a0ecfc20da3d53b866cf0`. La [conception retenue](media/10/design/accepted.md), le [rapport d'implémentation](media/10/implementation/report.md) et la [revue du code](media/10/code-review.md) précisent ce périmètre.

## Images finales et compromis

Les comparaisons suivantes conservent les poses, l'alimentation et la lampe éteinte. Les images de référence proviennent du ticket 09 déjà publié.

| Secteur | Normal, avant puis après | Low, avant puis après |
|---|---|---|
| Décontamination | [Avant](media/09/render-final-normal/decontamination_power_on_flash_off.png), [après](media/10/implementation/verified-lighting-normal/decontamination_power_on_flash_off.png) | [Avant](media/09/render-final-low/decontamination_power_on_flash_off.png), [après](media/10/implementation/verified-lighting-low/decontamination_power_on_flash_off.png) |
| Maintenance | [Avant](media/09/render-final-normal/maintenance_power_on_flash_off.png), [après](media/10/implementation/verified-lighting-normal/maintenance_power_on_flash_off.png) | [Avant](media/09/render-final-low/maintenance_power_on_flash_off.png), [après](media/10/implementation/verified-lighting-low/maintenance_power_on_flash_off.png) |
| Archives | [Avant](media/09/render-final-normal/archives_power_on_flash_off.png), [après](media/10/implementation/verified-lighting-normal/archives_power_on_flash_off.png) | [Avant](media/09/render-final-low/archives_power_on_flash_off.png), [après](media/10/implementation/verified-lighting-low/archives_power_on_flash_off.png) |

Le [collecteur vu de gauche](media/10/implementation/details-candidate-normal/detail_collector_left.png) est presque hors champ sur la pose générale de Maintenance. La comparaison du texte Archives [avant](media/10/implementation/details-base-normal/detail_text_archives.png) et [après](media/10/implementation/details-candidate-normal/detail_text_archives.png) montre sa lisibilité retrouvée. Les mêmes suppléments existent en Low.

La [revue artistique indépendante](media/10/art-review.md) porte sur 54 PNG effectivement ouverts : six références09, 24 captures finales du catalogue commun et 24 suppléments. Elle confirme la distinction des salles et les cibles dégagées sur ces poses. Ce jugement ignore le texte du HUD, mais ne constitue pas un test aveugle auprès de joueurs.

Chaque campagne finale produit 44 poses par qualité. La publication en retient les 12 poses par qualité ouvertes par la revue. Les suppléments utilisent une sonde distincte et ne revendiquent pas le validateur du catalogue44. Leurs manifestes conservent la provenance complète des captures, y compris celles non sélectionnées pour publication.

Les plafonds sont plus nus et perdent de la profondeur industrielle. Les aplats crème, les raccords et l'usure restent sommaires. Les Archives perdent du détail technique ; leur travée sombre demeure discrète. Les trois décalages de caméra devant Décontamination ne montrent pas de chevauchement instable sur les images inspectées, sans prouver l'absence de scintillement en mouvement. La finition reste éloignée de Fortnite.

## Tests et géométrie

Les [neuf suites finales](media/10/implementation/final-tests/results.json) passent avec code0 et zéro échec : monde, parcours, effets et commandes des circuits, composition, alarmes, réglages, état et dialogue. La revue du code a contrôlé leurs journaux et empreintes, sans relancer le moteur. Des avertissements ObjectDB à l'arrêt subsistent dans quatre suites.

Le changement de production concerne la présentation uniquement. Aucun nouveau collider, matériau, lumière, état, interaction ou API publique n'est ajouté. Les helpers de matériaux, de regroupement des meshes et de qualité restent identiques. Les outils de preuve géométrique ont leur propre cycle rouge puis vert, distinct du décor.

La [revue géométrique finale](media/10/geometry-final-review.md) confirme la correction du validateur, ses 18 tests et la cohérence des extractions réelles. La [comparaison détaillée](media/10/geometry-fix/runtime/attempt-01/comparison.json) couvre 12 segments et 18 volumes, sur les triangles transformés de WorldArt :

- Les 76 colliders ont des empreintes identiques entre référence et candidat.
- Aucun nouveau hit ni retrait sur les 30 contrôles.
- Quatre débattements de porte conservent chacun 40 intersections anciennes, soit 160 au total. Elles restent présentes dans les résultats.
- Les 26 autres contrôles ne signalent aucune intersection.

| Géométrie construite du décor | Avant | Après |
|---|---:|---:|
| Instances et surfaces | 105 | 98 |
| Triangles | 60 644 | 42 068 |

Les groupes statique, acteur et animé restent identiques. Ces nombres décrivent la géométrie construite ou potentielle. Ils ne mesurent ni les triangles rendus, ni les drawcalls, ni le coût GPU, ni un gain de FPS.

Ce contrôle reste limité à l'état initial, aux trajets et visées déclarés, et aux triangles WorldArt. Il ne couvre pas l'animation. Une réserve entièrement enfermée sans croisement de surface peut lui échapper ; les débattements supposent les portes actuelles sans rotation ni changement d'échelle.

Les captures et extractions géométriques enregistrent le HEAD antérieur `0297cf7`, avec le fichier modifié de même empreinte. Les parcours ci-dessous enregistrent le commit `64a9485`. Les manifestes d'origine sont conservés sans réécriture de leur HEAD.

## Deux missions dans le projet source

Le [résumé des parcours](media/10/native-summary.json) et leurs traces enregistrent deux nouvelles parties abouties, sources inchangées :

| Parcours | Qualité | Distance physique | Santé finale | Combat |
|---|---|---:|---:|---|
| [MÈRE](media/10/native-mother/journey.json) | Normal | 193,043 m | 100 | 15 tirs, six ennemis vaincus |
| [N-7](media/10/native-n7-low/journey.json) | Low | 187,481 m | 70 | 15 tirs, six ennemis vaincus |

Chaque parcours comprend 14 interactions E natives, dont six commandes de disjoncteurs, et une activation F native qui rend la lampe visible. Déplacement et collisions passent par Input et la physique. Orientation et visée sont scriptées ; combat, scan et conclusion utilisent les fonctions réelles du jeu. Aucun clic OS sur le bouton final n'est démontré. Les moteurs et validateurs terminent avec code0, sans erreur de validation.

La [vidéo MÈRE](media/10/native-film/mother.mp4) contient 1 105 images en 1280 × 720 à 15 images/s, soit 73,67 secondes, sans audio. L'enregistrement, l'inspection technique et le décodage intégral terminent avec code0. La [revue indépendante](media/10/film-review.md) a ouvert douze images extraites à cadence nominale de six secondes. Aucun visionnage continu n'est revendiqué et ces images n'affichent pas les conclusions; celles-ci sont attestées par les traces. Les durées des parcours incluent l'enregistrement ou les captures et ne constituent pas un benchmark.

Des stries sur certains encadrements et un panneau vu à l'envers sont conservés parmi les [notes visuelles](media/10/film-notes-parent.md). Des motifs semblables existent dans le film09, à des poses différentes. Leur cause et une éventuelle aggravation ne sont pas établies.

Repères de la comparaison historique : encadrement [film09, image03](media/09/native-film/frames/frame-03.png) et [film10, image03](media/10/native-film/frames/frame-03.png), panneau de dos [film09, image10](media/09/native-film/frames/frame-10.png) et [film10, image10](media/10/native-film/frames/frame-10.png). Les poses diffèrent.

## Coût mesuré sur le trajet

Le p95 est plus court dans les cinq paires de chacun des quatre groupes. La [revue indépendante](media/10/perf-review.md) valide les 40 exécutions et leur intégrité, après le [prévol des outils](media/10/perf-tool-review.md). Le [protocole](media/10/perf-plan.md) alterne référence et candidat, sur neuf stations et 92,433 m, circuits alimentés, sans ennemis. Il utilise Godot 4.7.2 Compatibility, Linux X11, llvmpipe et 1280 × 720.

Les valeurs sont des intervalles wall-clock entre callbacks `_process`, en millisecondes. Chaque cellule donne la médiane des cinq p95 puis leur plage minimum/maximum. La dernière colonne donne la médiane des pourcentages appariés, différente du ratio des deux médianes.

| Groupe | p95 avant, ms [plage] | p95 après, ms [plage] | Variation appariée médiane |
|---|---:|---:|---:|
| Normal, lampe OFF | 89,894 [86,222 ; 95,711] | 79,266 [76,198 ; 83,944] | −12,19 % |
| Normal, lampe ON | 105,234 [100,093 ; 108,836] | 91,156 [89,643 ; 97,209] | −11,97 % |
| Low, lampe OFF | 56,408 [54,690 ; 57,115] | 47,597 [46,330 ; 51,608] | −13,17 % |
| Low, lampe ON | 62,739 [58,604 ; 63,328] | 54,043 [50,082 ; 55,329] | −13,58 % |

Les 20 différences appariées p95 sont négatives et les plages ne se recouvrent dans aucun groupe. Le p50 diminue aussi dans les 20 paires. Le p99 augmente dans deux paires ; l'amélioration n'est donc pas uniforme à tous les quantiles. L'[audit des mesures](media/10/perf-audit/campaign-audit.json) conserve les quantiles recalculés, les contrôles des intervalles, les plages et les différences. Les 40 runs terminent sans erreur, avec déplacement et frames réellement rendues. La lampe est vérifiée avant chauffe, pendant chaque callback et en finale. Les relevés ponctuels d'hôte appuient l'absence de moteur concurrent sans constituer une surveillance continue.

Le [profil séparé](media/10/profile-route-link.json) de cinq secondes au début du trajet candidat Normal ON attribue environ 93 % du CPU du processus aux threads llvmpipe. Il ne profile pas la référence et n'établit pas la cause exacte de l'amélioration. Les timings du profil, du diagnostic, des missions et des captures sont exclus des 40 runs. La baisse des triangles construits ne suffit pas à expliquer le gain.

Ces mesures comparent deux projets source instrumentés, avec le même moteur, et non deux exécutables release. Elles ne mesurent pas du temps GPU. Comparer ON à OFF entre groupes ne prouve pas un coût d'activation apparié. Les [empreintes de campagne](media/10/perf-audit/provenance-audit.json) restent identiques pendant les runs ; trois outils ont ensuite été remplacés pour publication, explicitement consignés. Aucune identité complète du worktree actuel avec le snapshot mesuré n'est revendiquée.

## Exports et contrôle natif

Les [exports Linux et Windows](media/10/export.log) ont terminé avec code0 ; leurs [empreintes et identité source](media/10/export-identity.json) sont conservées. Le [contrôle du binaire Linux](media/10/packaged-native-review.md) couvre nouvelle partie, déplacement, F, scan, pause/reprise, extinction de la lampe, retour au menu et sortie. Les entrées et le moteur quittent avec code0 ; le journal ne contient aucune erreur moteur. Le parent a inspecté les neuf captures, notamment [lampe allumée](media/10/packaged-native-verified/flashlight-on.png), [scan](media/10/packaged-native-verified/scan.png) et [reprise avec lampe](media/10/packaged-native-verified/resumed-lamp-on.png).

L'[empreinte du binaire et les entrées](media/10/packaged-native-verified/verification.json) identifient ce contrôle sous Linux X11 et llvmpipe. Les deux missions complètes restent des missions source. Windows a été exporté, sans être exécuté. Aucun contrôle audio ni archive finale n'est établi ici.

Les [outils copiés pour publication](media/10/published-tool-identity.json) conservent leurs empreintes ; leurs [18 tests géométriques](media/10/published-geometry-tests.log) et [24 tests de performance](media/10/published-perf-tests.log) passent. Ces outils sont exclus du paquet Godot.

## État de la validation

Les preuves couvrent la revue du code, les tests, les poses artistiques, la géométrie déclarée, deux missions source, la campagne locale auditée et le contrôle natif du binaire Linux. L'archive finale et sa revue de livraison ne font pas partie des preuves ci-dessus.

Windows, un GPU joueur, l'écoute sur un périphérique audio et l'objectif de 60 FPS en 1080p restent non validés. Les [limites détaillées de la géométrie](media/10/geometry-fix/report.md) et la revue artistique bornent leurs conclusions à leurs preuves.

Le [manifeste de sélection](media/10/selection-manifest.json) décrit seulement les fichiers retenus pour cette publication. Les manifestes de campagne recensent leur contexte d'exécution complet ; ils ne constituent pas un inventaire des fichiers publiés.
