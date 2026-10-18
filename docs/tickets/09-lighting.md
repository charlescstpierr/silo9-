# Ticket 09 : éclairage des secteurs et lampe du joueur

Les plafonniers correspondent désormais aux diffuseurs visibles. Maintenance conserve une lumière chaude, Décontamination et Archives une lumière froide. Les deux alarmes éclairent leur disjoncteur même hors tension. Le balisage du passage central reste visible pendant une coupure.

La lampe directionnelle révèle les équipements proches, les surfaces et les ennemis dans son faisceau. F physique, en WASD comme en ZQSD, ou R3 la bascule. Elle fonctionne même à zéro énergie, sans consommer la batterie du scan et de l'ARC-3. Le HUD affiche « LAMPE ON ». La pause conserve son état ; une nouvelle partie ou un chargement la réinitialise éteinte.

Dans Réglages, « Réduire les variations lumineuses » stabilise le néon Maintenance, l'enveloppe lumineuse des alarmes et le gain lumineux du colosse. Cette préférence persiste entre sessions. Elle conserve les sons et les événements.

Source vérifiée : `653e2a79c7f36e9ac7422335c85cef3b937ed0f9`. Base de comparaison : `e5b0bafa7b8bad369e6767a908b1d8391343b9f2`. La [conception retenue](media/09/design/accepted.md), le [rapport d'implémentation](media/09/implementation/report.md) et la [revue de code](media/09/code-review.md) détaillent la composition et les transitions.

## Images et compromis visuels

| Situation | Preuve finale |
|---|---|
| Disjoncteur hors tension en Normal | [Lampe éteinte](media/09/render-final-normal/critical_breaker_maintenance_flash_off.png), [allumée](media/09/render-final-normal/critical_breaker_maintenance_flash_on.png) |
| Cœur en Normal | [Lampe éteinte](media/09/render-final-normal/core_power_on_flash_off.png), [allumée](media/09/render-final-normal/core_power_on_flash_on.png) |
| Maintenance hors tension en Low | [Lampe éteinte](media/09/render-final-low/maintenance_power_off_flash_off.png), [allumée](media/09/render-final-low/maintenance_power_off_flash_on.png) |
| Alarme autonome en Low | [Active](media/09/render-final-low/alarm_active.png), [expirée](media/09/render-final-low/alarm_expired.png) |

La [revue Normal](media/09/art-normal.md) porte sur 22 images finales, 14 images de référence et une preview historique. La [revue Low](media/09/art-low.md) porte sur 23 images finales, 10 images de référence et une preview historique. Ces revues ont comparé de vrais pixels. Les campagnes produisent chacune 44 poses ; toutes n'ont pas été inspectées visuellement.

La lampe projette une ombre visible derrière le levier en Normal. Low conserve zéro ombre d'exploration et une échelle 3D de 0,67. Le [cadrage corrigé](media/09/lamp-framing/report.md) dégage le pied du disjoncteur et le sol, auparavant masqués par le boîtier.

Sans lampe, plusieurs surfaces sont plus sombres et ont moins de relief que dans la base. Les ennemis latéraux restent peu contrastés hors faisceau. Le néon varie discrètement ; son aspect franchement défaillant n'est pas établi par les images. Le glow reste désactivé. Les poses contrôlées figent les acteurs et déplacent la caméra : elles ne prouvent ni combat en mouvement, ni confort temporel, ni qualité Fortnite atteinte.

## Comportements et parcours vérifiés

Le parent a reproduit [sept suites rouges sémantiques avant production](media/09/tests-red-parent/gate.json). Le builder a ensuite exécuté [17 suites vertes](media/09/implementation/results-final.json), dont mission, sauvegarde, commandes, éclairage et réglages. Les huit fichiers de tests gelés sont restés identiques. Le parent a rejoué [les quatre nouvelles suites](media/09/tests-green-parent/results.json), toutes vertes.

Ces tests couvrent notamment F/R3, les répétitions et reprises après modale, la batterie vide, pause/chargement, les priorités courant/qualité/fins/colosse, l'expiration des alarmes et la stabilité des objets après 100 cycles. Les tests à rendu factice ne prouvent pas les pixels. La revue indépendante du code porte sur `e691f5f` ; le delta final de cadrage change deux positions, avec tests et captures distincts.

Deux nouvelles parties ont atteint leur conclusion sur la source finale :

| Parcours | Qualité | Distance physique | Santé finale | Combat |
|---|---|---:|---:|---|
| [MÈRE](media/09/native-mother-final/journey.json) | Normal | 193,182 m | 100 | 15 tirs, six ennemis vaincus |
| [N-7](media/09/native-n7-low-final/journey.json) | Low | 187,371 m | 70 | 15 tirs, six ennemis vaincus |

Chaque parcours comprend une activation F par XTest et 14 interactions E natives, dont six bascules de disjoncteurs. Déplacement par Input, physique et collisions restent actifs ; orientation et visée sont scriptées. Combat, scan et choix final utilisent les fonctions réelles du jeu. La console finale est ouverte par E ; aucun clic OS sur le bouton de conclusion n'est démontré. N-7 prouve des dégâts reçus ; la santé observée dans MÈRE reste à 100.

La [vidéo MÈRE](media/09/native-film/mother-final.mp4) dure 73,67 secondes, en 1280 × 720 à 15 images/s, sans audio. L'enregistrement et le décodage intégral ont terminé avec le code 0. La [revue indépendante](media/09/film-review.md) a examiné douze images extraites à intervalles nominaux de six secondes. Aucun visionnage continu, jugement de fluidité ou contrôle audio n'est revendiqué.

Les deux moteurs et le writer vidéo ont terminé avec le code 0. La session orchestratrice a toutefois renvoyé 143 après le résultat N-7 ; sa cause reste inconnue et figure dans le [résumé natif](media/09/native-summary.json). Des avertissements ObjectDB à l'arrêt subsistent dans sept journaux de tests ; cette tranche n'en établit pas la cause ni l'absence de fuite.

## Coût mesuré sur le trajet, lampe éteinte

Le [protocole](media/09/perf-plan.md) compare cinq paires alternées par qualité, soit 20 exécutions. Godot 4.7.2 rend en Compatibility, sous Linux X11 avec llvmpipe, à 1280 × 720. Après deux secondes de préparation, le joueur parcourt les mêmes neuf stations sur 92,433 m. Les ennemis sont retirés, les circuits alimentés et la lampe éteinte. Aucun enregistrement vidéo ni profileur ne tourne pendant ces mesures.

L'[audit indépendant](media/09/perf-audit/audit.json) recalcule 7 452 intervalles et réussit 3 658 contrôles sans erreur. Chaque cellule indique la médiane des cinq passages, puis leur minimum et maximum. Les valeurs sont les intervalles wall-clock, en millisecondes, entre callbacks `_process`, avec vérification des frames rendues. Ce ne sont pas des temps GPU.

| Qualité | p50 avant | p50 après | p95 avant | p95 après |
|---|---:|---:|---:|---:|
| Normal | 89,028 [87,161 ; 91,738] | 74,142 [71,700 ; 74,872] | 109,335 [107,468 ; 130,702] | 89,879 [88,218 ; 93,845] |
| Low | 43,990 [42,915 ; 46,943] | 44,411 [43,865 ; 46,053] | 59,367 [56,923 ; 62,212] | 58,840 [57,434 ; 61,170] |

En Normal, le p95 baisse de 17,79 % sur ce trajet lampe éteinte. Les cinq paires vont dans le même sens et les plages sont séparées. Cette mesure ne couvre pas le cœur, une alarme active ou la lampe allumée. En Low, les plages se recouvrent et les différences appariées changent de signe : aucun gain n'est établi.

Les appels de dessin maximaux passent de 298–301 à 277 en Normal, et de 265 à 270 en Low. Le maximum de nœuds passe de 603 à 607. Le compteur de ressources reste à 101 ; il ne mesure pas la VRAM.

Un [profil séparé de cinq secondes au début du trajet Normal](media/09/perf-audit/profile.json) mesure 443,91 % CPU pour Godot, dont 400,59 % dans les threads llvmpipe, soit 90,24 %. Le rendu logiciel domine cette fenêtre. Ce profil n'identifie pas une fonction responsable du gain et ne compare pas les deux versions.

Les observations Linux de cette page ne valident ni Windows, ni un GPU joueur, ni l'objectif de 60 FPS en 1080p. La finition reste celle d'un prototype stylisé. La durée, le confort et la difficulté demandent encore des essais humains.

## Coût de la lampe et des alarmes

Quatre compléments exploratoires ont mesuré le cœur et Maintenance, lampe éteinte puis allumée, en Normal et Low. Chaque fenêtre dure six secondes, caméra et acteurs figés, alarme tenue. La [revue finale](media/09/perf-review.md) détaille leurs limites. Trois essais antérieurs sont exclus après détection d'une borne temporelle incorrecte. La [correction](media/09/cost-clock-report.md) ancre la durée sur les callbacks réellement mesurés, avec 16 tests verts. Les outils originaux de la campagne principale restent archivés séparément.

Le signal de surcoût Low a déclenché cinq paires supplémentaires, soit dix exécutions. L'[audit ciblé](media/09/perf-audit/cost-confirm.json) contrôle 5 185 intervalles sans erreur. En Maintenance avec alarme tenue, les médianes des cinq passages sont :

| État Low | p50, ms | p95, ms |
|---|---:|---:|
| Base sans lampe | 54,579 | 66,877 |
| Candidat, lampe allumée | 59,204 | 76,927 |
| Candidat, lampe éteinte | 54,471 | 64,736 |

Face à la base sans lampe, le p50 augmente de 8,47 % et le p95 de 15,03 %. Les cinq différences appariées sont positives. Les plages p95 se recouvrent partiellement. Dans le candidat, les cinq activations augmentent aussi ces quantiles; l'ordre intérieur reste toujours OFF puis ON, donc une dérive temporelle n'est pas totalement isolée. Les 321 appels de dessin restent identiques, avec zéro ombre Low. La cause précise du surcoût n'est pas profilée.

La lampe est conservée pour rendre les équipements et volumes proches lisibles pendant les coupures. Ce coût fait partie du compromis du prototype. Le gain du trajet lampe éteinte ne prouve aucun gain global. Le coût Normal avec lampe allumée reste exploratoire. Un test sur GPU joueur demeure nécessaire.

## Exports

Les exports Windows et Linux ont réussi. Le [contrôle natif du binaire Linux](media/09/export-review.md) vérifie nouvelle partie, déplacement, F, scan, pause/reprise, extinction de la lampe et retour au menu. Les [entrées et l'empreinte du binaire](media/09/packaged-native-verified/verification.json) sont archivées. Les captures montrent [LAMPE ON à énergie100](media/09/packaged-native-verified/flashlight-on.png), [son maintien après reprise](media/09/packaged-native-verified/resumed-lamp-on.png) et [son extinction](media/09/packaged-native-verified/flashlight-off-again.png). Le moteur quitte avec code0. Le premier essai et sa capture ON trop précoce restent conservés séparément.

Ce contrôle porte sur le binaire Linux exporté, pas sur une mission complète dans ce binaire. Les deux missions complètes documentées plus haut utilisent le projet source. Windows n'a pas été exécuté. Les preuves et outils publiés portent leurs [empreintes](media/09/SHA256.json).

La [revue indépendante de livraison](media/09/delivery-review.md) valide les preuves publiées, leurs chiffres, les commentaires des outils et les sept captures du binaire inspectées. Elle distingue les vérifications effectuées de celles encore absentes.
