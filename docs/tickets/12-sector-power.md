# Ticket 12 : circuits électriques des secteurs

La Maintenance et les Archives possèdent chacune un disjoncteur utilisable avec E, même hors tension. Couper un secteur éteint ses lampes et surfaces lumineuses, relève les feuilles latérales du sas et arrête son ventilateur. Rétablir le courant inverse ces effets. Le passage central reste libre ; les feuilles attendent si le joueur ou un robot occupe leur volume de fermeture.

Une coupure produit un avertissement de 1,5 seconde, limité par un délai de huit secondes, qui peut attirer les robots proches. Le scan, la recharge de secours, la réparation acquise du relais, le verrou du cœur et les deux conclusions conservent leurs règles. Les deux configurations sont des Resources natives, sans plugin ni asset tiers ajouté.

La sauvegarde passe au schéma 3. Les fichiers de schéma 2 sont validés puis migrés avec les deux circuits alimentés. Un fichier invalide ne modifie pas la partie active. MÈRE connaît les deux circuits ; N-7 connaît celui des Archives. Un cycle OFF puis ON invalide une réponse conversationnelle en vol avant ses actions. Une ancienne version du jeu ne lit pas les nouvelles sauvegardes de schéma 3.

## Preuves exécutées

La production mesurée est `2c205f59520d935e09c921574a20e42379999348`, après les tests seuls de `a2149d9`. Le parent a reproduit les quatre échecs sémantiques avant l'implémentation, puis les quatre suites électriques sont passées. Deux tests de préférences qui exigeaient encore le schéma 2 ont été adaptés après leur échec exact ; leurs autres assertions restent inchangées.

La revue indépendante a exécuté 24 restaurations par `Main.save_run` et `Main.load_run`, aux étapes de mission et dans les quatre combinaisons électriques. Les 252 assertions passent. Les tests de collision couvrent le volume du joueur et des robots. Les tests de dialogue utilisent une réponse HTTP injectée sur loopback, aucun modèle réel.

Deux nouvelles parties automatisées ont atteint leurs conclusions avec les combats, ressources et dégâts actifs :

| Parcours | Qualité | Distance enregistrée | Interactions des disjoncteurs | Conclusion |
| --- | --- | ---: | --- | --- |
| MÈRE | Normale | 193,4 m | Six bascules par E natif après contrôle du rayon | CONFINEMENT |
| N-7 | Low | 187,5 m | Six bascules par E natif après contrôle du rayon | ÉMANCIPATION |

Les déplacements utilisent le contrôleur physique et une orientation scriptée. MÈRE passe par le détour ; N-7 utilise réellement l'ARC sur le verrou. Le choix final appelle le gestionnaire du bouton après ouverture physique de la console. Ce ne sont pas des sessions humaines.

- [Film MÈRE](media/12/video/mother-final.mp4) : 90,2 secondes, 1 353 images, 1280 × 720, 15 images/s, sans audio. Décodage intégral réussi.
- [Disjoncteur alimenté](media/12/native/mother/before_03_breaker_maintenance.png) et [coupé](media/12/native/mother/after_04_breaker_maintenance.png).
- [Sas sous tension](media/12/native/mother/before_03_maintenance_sas.png) et [ouvert après coupure](media/12/native/mother/after_04_maintenance_sas.png).
- [Ventilateur arrêté](media/12/native/mother/after_04_maintenance_fan_0.png) et [rétabli](media/12/native/mother/after_05_maintenance_fan_0.png).
- [Conclusion MÈRE](media/12/native/mother/conclusion_mother.png) et [conclusion N-7 en Low](media/12/native/n7-low/conclusion_n7.png).

La revue visuelle indépendante porte sur 30 captures finales et six images espacées du film. Elle ne revendique pas de visionnage continu. L'arrêt et la reprise des rotors sont également corroborés par leurs rotations enregistrées. L'audio Dummy vérifie l'état des lecteurs, pas un son entendu.

## Coût de rendu

Cinq paires alternées par qualité, soit 20 exécutions et 7 537 intervalles de frame, ont été auditées indépendamment. Le même trajet physique de 92,4 m utilise neuf stations, sans ennemis, avec les circuits ON. Les captures et le profil CPU sont exclus de cette campagne. Les deux côtés utilisent Godot 4.7.2 depuis le projet source, à 1280 × 720, avec llvmpipe sur ce serveur Linux.

Les valeurs sont les médianes des cinq runs, en millisecondes :

| Qualité | p50 avant | p50 après | p95 avant | p95 après | Verdict |
| --- | ---: | ---: | ---: | ---: | --- |
| Normale | 81,805 | 83,699 | 99,678 | 106,725 | Coût mesurable, +2,32 % au p50 et +7,07 % au p95 |
| Low | 43,639 | 43,100 | 58,475 | 55,121 | Plages recouvrantes, aucun gain établi |

En Normal, les plages p50 sont 81,682–83,331 ms avant et 82,812–84,614 ms après. Le p99 médian passe de 109,758 à 118,010 ms. Le maximum d'appels de dessin passe de 259–263 à 298, les nœuds de 541 à 603 et le compteur de ressources moteur de 96 à 101. Ce dernier n'est pas une mesure de VRAM.

Le coordinateur accepte explicitement ce coût borné pour les nouveaux équipements ; le verdict de régression du reviewer reste conservé. Le regroupement des surfaces non électriques a été préservé. Un essai exploratoire séparé retirant les ombres de 14 petites pièces n'a pas apporté de signal de gain ; cette variante n'a pas été intégrée. Aucun seuil de FPS Windows ou GPU joueur n'est déclaré atteint. [Décision et limites](media/12/performance/perf-decision.md).

Le profil séparé attribue 458,4 % CPU aux huit threads llvmpipe sur 500,8 % pour le processus Godot. Il établit que le rendu logiciel domine ce banc, sans identifier une méthode GDScript comme cause du surcoût.

## Reproduire et examiner

Depuis un checkout du projet, avec un affichage X11 disponible :

```sh
python3 tools/selfcheck_sector_power.py
python3 tools/prove_sector_power.py --project . --godot /chemin/vers/godot --mode capture --ending mother --require-circuits --display :100 --output /chemin/neuf/preuve-mere
python3 tools/prove_sector_power.py --project . --godot /chemin/vers/godot --mode capture --ending n7 --low --require-circuits --display :100 --output /chemin/neuf/preuve-n7
```

Le mode `perf` mesure un parcours sans capture. Chaque sortie doit être neuve. La sonde ne démarre ni n'arrête le serveur X. Le film a été enregistré séparément avec ffmpeg ; sa commande est archivée.

- [Revue du code](media/12/reviews/code.md), [revue visuelle](media/12/reviews/visual.md) et [audit des performances](media/12/reviews/performance.md).
- [Rouge avant production](media/12/tests/red/gate.json) et [résultats recalculés de la campagne](media/12/perf-audit/parent-audit.json).
- [Parcours MÈRE](media/12/native/mother/journey.json), [parcours N-7](media/12/native/n7-low/journey.json) et [empreintes des artefacts](media/12/SHA256.json).

Les rapports et manifests conservent les chemins des checkouts de construction. Le script d'audit archivé comprend des contrôles de ces checkouts au SHA mesuré ; ses résultats ont été figés avant les commits documentaires. La sonde publique ci-dessus permet de rejouer le parcours sur un autre checkout. Les hashes du wrapper au transfert et du moteur sont documentés séparément des manifests de runs.

Des avertissements WAV à l'arrêt immédiat ont été reproduits. Sur huit reconstructions, toutes les références audio suivies disparaissent dans les 250 ms après destruction ; les compteurs restent stables, sans nœud orphelin. Aucune accumulation persistante n'a été observée dans cette expérience. [Diagnostic audio](media/12/audio/audio-lifetime-report.md).
