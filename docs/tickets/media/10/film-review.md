# Revue indépendante des parcours et du film du ticket 10

Verdict **PASS + NOTES**, limité aux traces enregistrées et aux douze PNG effectivement ouverts. Les deux parcours atteignent leur fin attendue. Le film est décodable selon les contrôles enregistrés. Les images montrent une progression lisible jusqu'au retour à la console finale. Elles ne prouvent ni un visionnage continu, ni la fluidité du jeu, ni l'absence de scintillement temporel.

Revue du 18 octobre 2026. Règles chargées : cstack 0.8.0, `runtime/base.md`, `agents/cstack-agent.md`, unslop et technical-writing. Aucun moteur, outil ffmpeg, test ou commande Git exécuté pour cette revue. Aucun descendant lancé. Seul ce rapport est écrit.

## Parcours vérifiés

Sources lues : `native-summary.json`, `native-campaign.json`, `run_native_campaign.py`, les `manifest.json`, `journey.json` et `engine.log` de `native-mother` et `native-n7-low`.

| Preuve enregistrée | Mother | N7, qualité basse |
| --- | --- | --- |
| Head indiqué par le manifeste | `64a948545d63764cb500f6ac1a02380c5d1513f3` | Identique |
| Sortie campagne et manifeste | 0 | 0 |
| Erreurs de validation et échecs de parcours | 0 | 0 |
| Phase finale et fin attendue obtenue | 4, `mother` | 4, `n7` |
| Interactions E marquées natives, visée valide et état modifié | 14 sur 14 | 14 sur 14 |
| Bascules de disjoncteurs | 6 | 6 |
| Événement F, lampe visible après activation | 1, sortie native 0 | 1, sortie native 0 |
| Tirs et ennemis vaincus | 15, 6 | 15, 6 |
| Ennemis vivants dans l'observation finale | 0 | 0 |
| Santé finale | 100 | 70 |
| Distance enregistrée | 193,043 m | 187,481 m |
| Points de parcours terminés | 31 | 30 |

Les six bascules concernent deux disjoncteurs, trois interactions par secteur. Les bits passent de vrai à faux, puis à vrai, puis à faux dans la maintenance comme dans les archives. Il ne s'agit donc pas de six disjoncteurs distincts. Les autres interactions portent sur trois composants, le relais, N7, l'archive, le cœur et la console finale.

J'ai comparé les dictionnaires `source_before` et `source_after` de chaque manifeste, ainsi que `artifacts_before` et `artifacts_after` : ils sont identiques. Le champ `source_unchanged` vaut aussi vrai. Cela confirme la cohérence des instantanés enregistrés au head ci-dessus, sans vérifier l'état courant du checkout.

La frontière d'automatisation reste explicite. Les traces déclarent E et F comme entrées natives du système. La marche utilise les actions `Input` et le déplacement physique, avec orientation et visée scriptées. Le combat, le scan et le choix final passent par les fonctions du jeu selon le résumé de campagne. Les traces déclarent l'absence de téléportation après le démarrage normal pour ces parcours. La présente revue des artefacts ne réinspecte pas l'implémentation de ces mécanismes. L'interaction E sur la console ne prouve pas un choix de fin effectué manuellement dans son interface.

Les deux journaux indiquent Godot 4.7.2, Linux X11, OpenGL Compatibility et llvmpipe. Ils contiennent un avertissement de pilote sur le changement de V-Sync non pris en charge, puis `failures=0`. Cet avertissement ne démontre pas un défaut visuel. Les deux `performance_valid` valent faux. Les durées et statistiques de ces parcours ne constituent pas une comparaison de performances.

## Film et provenance

Sources lues : `native-film/writer.json`, `ffprobe.json`, `decode.json` et `extraction.json`.

Le lancement de l'enregistrement précède celui du parcours Mother dans `run_native_campaign.py`. La capture inclut donc le démarrage. N7 s'exécute après l'arrêt de cet enregistrement : `mother.mp4` n'est pas le film des deux parcours.

Le fichier contient un seul flux H.264, 1280 × 720, 15 images par seconde, 1 105 images et 73,666667 secondes. Aucun flux audio n'est déclaré. Le writer, ffprobe et le décodage complet enregistrent chacun une sortie 0. Aucun nouveau décodage n'a été lancé pendant cette revue.

Le SHA-256 recalculé sur le fichier est `b43f5db7726fbb168e9baffe7298019837e19da0f7dc6a5b3a8ecc225243fbbc`. Il correspond aux valeurs du writer et de l'extraction. L'extraction enregistrée utilise `fps=1/6`, sort avec 0 et liste les douze fichiers présents. C'est un échantillonnage nominal toutes les six secondes. Les noms ci-dessous ne donnent pas les timestamps de présentation exacts des images source.

## Douze images ouvertes

Chaque fichier ci-dessous a été ouvert avec l'outil d'affichage d'image. Le numéro désigne l'ordre d'extraction, sans attribution d'un temps source exact.

| Fichier sous `native-film/frames/` | Observation directe |
| --- | --- |
| `frame-01.png` | Écran noir avec curseur X11. Cohérent avec l'inclusion du démarrage, sans preuve de sa durée exacte. |
| `frame-02.png` | Refuge et axe vers la décontamination. Passage central visible, arme à droite et HUD lisible. |
| `frame-03.png` | Porte de maintenance, ennemi visible et retour « IMPACT ». Des stries fines apparaissent sur les panneaux et l'encadrement ; une image fixe ne permet pas d'en attribuer la cause ni de conclure à un scintillement. |
| `frame-04.png` | Vue très proche d'un panneau mural qui occupe la majorité de l'image. Passage visible à droite et message de ressource récupérée. Cette occultation ponctuelle ne prouve pas un blocage du trajet. |
| `frame-05.png` | Disjoncteur maintenance sous tension, commande « E · Couper maintenance » visible. |
| `frame-06.png` | Accès ouvert aux archives et objectif de rejoindre le cœur. Ouverture et voie de passage visibles. |
| `frame-07.png` | Archives hors tension et commande de rétablissement visible. Le faisceau éclaire le levier. |
| `frame-08.png` | Terminal d'archive et commande de lecture. L'écran clair réduit localement le contraste du texte superposé. Le texte reste identifiable. |
| `frame-09.png` | Cœur, ennemis et animation de rechargement. Les bras occupent le centre droit, avec les ennemis encore visibles. |
| `frame-10.png` | Cœur récupéré et objectif de retour. Le panneau « CONTOURNEMENT » apparaît inversé depuis son revers. Des stries fines sont visibles sur l'encadrement. Aucun blocage démontré. |
| `frame-11.png` | Retour par la maintenance, axe central dégagé et flèche au sol visible. |
| `frame-12.png` | Retour au refuge et commande « Console de descente / choix final ». Aucun écran de conclusion dans cet échantillon. |

Ces vues ne montrent pas d'obstruction permanente empêchant le parcours. Les traces de fin corroborent que les deux itinéraires enregistrés se terminent. La vue proche du mur et les stries visibles restent des observations localisées, sans diagnostic de collision ou de scintillement.

Les douze images ne permettent pas d'exclure un défaut entre les échantillons. La preuve des deux fins vient des `journey.json`, pas des conclusions visibles dans ces PNG. Aucun visionnage continu, confort de commande humaine, résultat audio, GPU cible, exécution Windows ou fluidité universelle n'est revendiqué.

Travail libéré après rédaction du rapport. Aucun worktree ni processus créé par ce relecteur. Le chemin de projet et le head ci-dessus proviennent des manifestes, sans changement de branche.
