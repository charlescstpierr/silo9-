# Ticket 5, verdict visuel final

PASS borné aux images et aux phases inspectées sur `463aabf5bcc7d250ce35120841e2ed75a57c9e84`. Les deux blocages du rapport provisoire sont levés. Aucun autre défaut manifeste de mains, de raccord ou de silhouette n'a été observé dans les 50 captures finales. La fluidité en lecture continue et le son ne sont pas certifiés.

## Preuves de cette passe

J'ai lu les pixels des 50 PNG de `.worktrees/silo9-issue-05/.cstack/issue-05/proof-delivery/inspection/`, les 25 vues FPS et les 25 obliques, ainsi que leur `manifest.json` et `journey.json`. J'ai également inspecté `.cstack/orchestrate/silo9/issue05/film-sheet-final.png`, puis les manifestes, données de parcours et analyse PCM de `proof-delivery/film/`. Les captures antérieures de `15d2b91` restent historiques dans `art-review.md`.

Les deux manifestes finaux identifient `463aabf`, un code de sortie moteur 0, et des sources, probe et runner inchangés pendant leur exécution. Le parent a effectué la comparaison des hashes aux objets Git ; je n'ai pas refait cette comparaison dans cette passe limitée aux images et JSON. Le parent signale par ailleurs un code 143 du wrapper après production des artefacts, distinct du code moteur 0. Je ne déclare pas ce wrapper réussi. La présente revue porte sur les artefacts terminés effectivement consultés.

## Blocages levés

Le faisceau ARC est corrigé visuellement dans `1-urgent-sprint-fps.png`. Le segment cyan part vers l'avant du modèle et rejoint la cible ; le large segment qui passait derrière le boîtier vers le coin inférieur droit dans la capture précédente a disparu. Les mains et la silhouette arrière restent lisibles. Le tir immobile `1-fire-fps.png` reste cohérent. Cette observation valide le défaut de présentation signalé ; elle ne constitue pas une vérification du calcul des dégâts, de l'impact ou des ressources.

Les nouvelles obliques montrent maintenant les deux poignets et les avant-bras. `0-rest-oblique.png` rend lisible la prise D9 à deux mains, `1-rest-oblique.png` le soutien avant propre à ARC. La continuité des manches, poignets et mains reste visible pendant marche, sprint, regard, arrêt, visée, tir et les quatre poses de changement. Je n'y vois ni membre inversé, ni main flottante, ni rupture entre poignet et avant-bras. Les extrémités proximales coupées des bras deviennent visibles dans cette vue diagnostique reculée ; elles n'apparaissent pas dans les vues FPS et ne constituent pas un défaut de jeu démontré.

Le JSON décrit explicitement les obliques avec `rig_yaw=0.65`, `rig_position=(0,0.15,-0.45)` et `anatomy_effects_hidden=true`. Les captures affichent aussi "Inspection anatomique · effets masqués". Ces vues servent à l'anatomie ; la correction du faisceau est jugée dans la vue FPS, où les effets restent présents.

## Poses et mouvement

Les captures `switch-1-lower`, `switch-1-raise`, `switch-0-lower` et `switch-0-raise` montrent respectivement D9 en LOWER_ABORT, ARC en RAISE, ARC en LOWER_ABORT et D9 en RAISE. Les huit enregistrements FPS/oblique correspondent à `motion=2/4` et `lower=0.15625/0.1180758`. Les armes sont abaissées en vue FPS et conservent leurs prises en vue oblique. `final-ready` montre D9 revenu au repos. Ce sont les phases exactes échantillonnées par contrôleur figé à 0,04 s et 0,27 s ; aucune durée réelle de rendu intermédiaire n'est déduite de ces images.

Les poses de locomotion restent retenues. Les paires repos/marche montrent une petite variation verticale ; le sprint déplace l'ensemble sans casser les prises ; la visée rapproche l'ensemble du centre. La différence de réponse D9/ARC reste corroborée par le film final : à la fin du segment d'arrêt, le poignet droit vaut `(0.206791,-0.220236,-0.339714)` pour D9 et `(0.208651,-0.222204,-0.337684)` pour ARC, pour un repos commun `(0.2066,-0.2182,-0.33992)`. ARC garde davantage de décalage. Les captures de tir en sprint montrent également des poses de récupération distinctes. Ce constat porte sur une réponse échantillonnée ; je ne transforme pas ces chiffres en jugement subjectif de masse au contrôle continu.

Les gestes D9 et ARC restent lisibles dans les images finales et la nouvelle planche film. `d9-partial-oblique` montre la main gauche tenant le chargeur sous l'arme tandis que la droite maintient la poignée. `d9-empty` montre la main gauche au-dessus de l'arme. `arc-cell` montre le couvercle ouvert et la main manipulant la cellule ; `b-from-d9` montre l'intervention supérieure ARC avant le retour D9 prêt. Aucune pièce détachée involontaire ou pénétration grossière ne ressort de ces poses. Certaines faces des doigts restent masquées par l'arme ; l'absence de toute intersection entre triangles n'est pas certifiée.

La nouvelle planche conserve les passages abaissés, recharges et retours prêts sans éclatement d'assemblage observable. Les données du film couvrent 657 échantillons, les états READY/RELOAD/LOWER_ABORT/RAISE/CELL et les gestes 0 à 19. Les écarts maximaux enregistrés valent `4.924e-7 m` pour prise/poignet et `5.333e-7 m` pour bouche/arme. L'inspection donne respectivement `5.340e-7 m` et `5.025e-7 m`. Ces mesures renforcent la cohérence des contacts visibles ; elles ne remplacent pas une inspection de chaque image interpolée.

## Limites et libération

J'ai inspecté des images fixes et la planche du film, pas le MP4 en lecture continue. Je ne revendique ni écoute, ni absence de popping sur chacune des 701 images, ni évaluation de fluidité perçue. L'analyse PCM finale contient 14 fenêtres de sons non nulles, avec débuts rapportés entre 1 et 9,33 ms après les événements ; ce résultat numérique ne constitue pas une écoute.

Le film reste une capture déterministe à 30 images/s d'environ 23,367 s, pas une mesure de performance. Les captures utilisent FOV 76. Le saut, les escaliers, les autres FOV, les cas de grands deltas et les entrées natives dépendent des vérifications distinctes du parent. Aucun verdict Windows, GPU cible ou parité Fortnite.

Seul `art-review-final.md` a été créé pendant cette passe ; `art-review.md` est conservé. Aucun Godot, ffmpeg, extraction, test, descendant ou processus persistant lancé. Aucun worktree créé. Revue libérée.
