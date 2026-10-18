# 04 · Cellule ARC

L'ARC reçoit une cellule par son coupleur latéral. La main gauche ouvre le levier, extrait la capsule, la range hors cadre, insère une autre cellule et ferme le verrou. Le logement vide possède un fond, un rebord et deux contacts cuivre visibles depuis la caméra FPS.

`WeaponHandling` remplace `D9Reload`. Il possède la sélection effective, la chronologie, la demande de cellule et le retour temporaire. Le joueur garde les entrées et les effets; le rig reçoit une vue sans modifier les comptes. Les durées et événements D9 restent couverts par leurs tests existants.

## Commandes et comptes

R sur ARC et les trois routes B passent par le contrôleur. B depuis le D9 équipe temporairement l'ARC puis rend l'arme désirée. Une sélection manuelle gagne. Depuis l'inventaire, la reprise et la demande ont lieu dans le même tour; un refus restaure l'inventaire.

Une cellule ajoute jusqu'à 60 à la batterie commune, plafonnée à 100 ou 150. Le contrôleur débite une seule cellule au verrou fermé, à 88 % du geste de trois secondes. Le tir attend le retour de la main. Le SCAN reste disponible et dépense la même batterie avant ou après ce jalon. Le refuge remplit immédiatement et gratuitement la batterie, même sans cellule.

Les comptes, la santé et l'activité sont revalidés au moment utile. Une interruption avant le verrou ne dépense rien; une interruption après conserve le transfert acquis. Une seule demande peut attendre une sortie déjà annulée. Le retour automatique d'une opération terminée reste occupé. Une ouverture modale, une mort, une téléportation ou une sélection manuelle efface la demande en attente.

La jauge horizontale lit `energy/max_energy`. Le petit témoin de connexion indique une capsule assise et un verrou fermé. La capsule retirée reste sombre. La sauvegarde conserve les comptes du moment et recrée un joueur prêt au chargement, sans persister la manipulation; le schéma 2 reste inchangé.

## Vérification

La tranche tests seuls `2df27ee` précède toute modification de production. Le parent a confirmé 176 fichiers de production identiques à `ef8350b`. Le contrat ARC échouait sur 57 assertions, son intégration UI sur 68 et le test UI existant sur deux. Les copies exactes et leurs empreintes restent dans `.cstack/issue-04/red-tests` et `receipt.json`.

Le premier runtime vérifié est `29ad254`; la prise calibrée finale est `d60db49`. Les tests couvrent les énergies 0, 10, 15, 40, 99 et 149, les stocks insuffisants, les plafonds, les refus, le SCAN des deux côtés du transfert, le refuge, les grands deltas, les interruptions, les trois routes B et le retour manuel. Les assertions D9 et les poses normales ARC sont conservées; seuls les imports ont migré.

Les régressions complémentaires ont chacune échoué avant leur correction: B pendant le retour automatique, retour vers une arme demandée pendant un changement en cours, arrêt du son lors d'une sélection manuelle, jauge/connexion, et messages de refus tardif ou R sur batterie pleine. Les logs rouges sont conservés. La revue indépendante a reproduit le défaut de destination sur `29ad254` avant sa correction.

Le test d'intégration démarre le vrai `Main`. Il vérifie la pause par les transforms réelles, F5/F9 par mutation des comptes et remplacement du joueur, puis 100 cycles complets par ticks physiques contrôlés. Chacun consomme exactement une cellule; le nombre de nœuds et l'identité des meshes restent stables. Ces cycles contrôlés ne constituent pas une mesure de fluidité.

La calibration géométrique suit l'implémentation. Elle n'est pas présentée comme un historique TDD de l'apparence. Les premiers essais ont révélé des cibles hors portée, un logement peu lisible, une capsule masquée par le bras et une capsule trop près du plan proche pendant son rangement. Les logs et rendus intermédiaires sont conservés. Le premier contrôle des doigts utilisait une direction de rayon inadaptée aux doigts recourbés; le contrôle final mesure leurs centres contre les triangles des pièces.

La sonde finale échantillonne toutes les phases à 5 ms. Les deux bras conservent leurs longueurs de 0,32 et 0,30 m. Le déplacement maximal des origines de cellule, verrou et main est de 14,987 mm par échantillon. L'écart main/marqueur reste inférieur à 0,001 mm. Les rayons de paume rencontrent les triangles entre 18,24 et 19,76 mm; les centres des doigts recourbés sont à 3,08–11,72 mm de ces triangles. Il s'agit de mesures géométriques sur le modèle stylisé, pas d'une simulation de collision des tissus.

La bouche suit l'arme à chaque échantillon. Les annulations gèlent les poses affichées pendant l'abaissement. Cellule, verrou et logement passent sous le bord inférieur du champ aux FOV 60°, 76° et 90° avant restauration. La cellule atteint aussi cette zone hors cadre entre rangement et nouvelle insertion.

## Artefacts et reproduction

Les captures FPS et obliques proviennent du moteur. La vidéo est une capture déterministe à 30 images/s et son audio provient du mixeur Godot. Elle ne prouve pas la fluidité. Chaque lancement de preuve enregistre les empreintes de production et de la sonde, la commande, la révision et le code de sortie, puis vérifie que les sources n'ont pas changé.

Les commandes reproductibles utilisent `.tools/Godot_v4.7.2-stable_linux.x86_64`. Les tests se lancent avec `--headless --path . --script tests/test_arc_cell_contract.gd`, et de même pour `test_arc_cell_ui`, `test_arc_lifecycle`, `test_arc_geometry`, `test_arc_audio`, `test_arc_indicator` et `test_arc_feedback`. `XDG_DATA_HOME` pointe vers un dossier de preuve isolé.

`DISPLAY=:99 python3 tools/prove_arc_cell.py --inspect --film` produit les rendus et la vidéo. `--measure --baseline <archive-ef8350b> --runs 5` effectue les paires alternées. La baseline doit être importée par le même Godot avant la mesure. Les bruts sont dans `.cstack/issue-04`.

La preuve clavier/souris native et la livraison distante appartiennent au coordinateur. Aucun résultat GPU matériel, Windows ou comparaison Fortnite n'est déduit de ce serveur llvmpipe.

## Médias livrés

- [Capsule extraite en FPS](media/04/0-extracted.png), [logement vide et contacts](media/04/0-pocket.png), [insertion](media/04/0-insert.png).
- [Vue oblique gauche](media/04/1-extracted.png) et [vue oblique droite](media/04/2-extracted.png).
- [Vidéo sonore déterministe](media/04/arc-cell.mp4), [PCM du mixeur](media/04/movie-audio.wav) et [analyse des signaux](media/04/audio-analysis.json).
- [Manifestes inspection](media/04/inspection-manifest.json) et [film](media/04/film-manifest.json), [index des tests](media/04/validation-index.json).

La vidéo comporte 460 images, soit 15,33 secondes à 30 images/s. Le rendu a demandé environ 62 secondes sur ce serveur. Les treize événements sonores de manipulation sont présents dans le PCM réel, avec un départ mesuré entre 1,33 et 10,67 ms après l'image de l'événement. Aucun son n'a été reconstruit ou ajouté au montage.

Les anciens logs de calibration restent consultables sous `.cstack/issue-04`, y compris `green-geometry.log`, dont le nom historique ne signifie pas qu'il passe. Les résultats finaux sont ceux de l'index livré. Les warnings de fermeture AudioStreamWAV/AudioStreamPlaybackWAV observés dans deux nouveaux tests ont disparu après arrêt/libération des streams et attente du thread audio dans le nettoyage des fixtures; leurs assertions restent identiques.

## Coût mesuré sur llvmpipe

Ce banc ne démontre pas de changement fiable de fluidité au repos: l'écart de médiane est inférieur à la dispersion des essais candidat. Le geste actif ajoute une charge qui n'existait pas sur la baseline. Il est donc chiffré séparément.

Cinq paires alternées utilisent Godot 4.7.2, 1280×720, la même scène/caméra/qualité et des fenêtres de huit secondes après échauffement. Aucune capture ni autre moteur n'a tourné pendant ces mesures. Tous les essais terminent sans erreur; chaque fenêtre active parcourt les dix gestes et effectue deux transferts vérifiés, soit dix transferts au total.

| Mesure | Baseline `ef8350b`, ARC prêt | `d60db49`, ARC prêt | `d60db49`, cellule active |
|---|---:|---:|---:|
| Médiane des p50 image, ms | 96,938 | 99,161 | 99,332 |
| Plage des p50 image, ms | 96,247–97,832 | 95,293–103,927 | 95,590–101,250 |
| Médiane des p95 image, ms | 112,563 | 117,229 | 117,215 |
| Médiane du second appel rig, ms | 0,039 | 0,044 | 0,052 |
| Appels de rendu | 315 | 328 | 323–328 |
| Triangles | 53 046 | 54 134 | 53 750–54 134 |

L'ARC prêt ajoute 13 appels de rendu et 1 088 triangles. Le second appel `update_visual(0, frame)` est une mesure isolée et déjà échauffée. Il ne représente pas le coût CPU total d'une image; l'intervalle image inclut le rendu logiciel et les frais de la sonde.

Un diagnostic séparé, exclu des cinq paires, a enregistré les threads avec `pidstat`: médiane 459,5 % CPU pour Godot, dont 419 % pour les threads llvmpipe et 42 % pour le thread principal, sur huit CPU logiques. Ce diagnostic a précédé le dernier ajustement de prise. Il identifie le rendu logiciel comme consommateur dominant dans cette scène. Les valeurs d'environ 100 ms par image décrivent ce serveur, pas une cible GPU matériel.

Les [résultats complets](media/04/performance.json), les [manifestes par essai](media/04/performance), la [méthode](media/04/benchmark-method.md) et le [diagnostic CPU](media/04/profile-summary.json) accompagnent ce tableau. Les fichiers de production des captures, du film et des cinq essais candidat correspondent aux mêmes empreintes `d60db49`.
