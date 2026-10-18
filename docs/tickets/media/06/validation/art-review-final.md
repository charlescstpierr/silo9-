# Ticket 6 — revue visuelle indépendante finale

Verdict **PASS pour la retouche géométrique D**, au commit `1e0ef98d00d3386cdb7185df154083759c593b4c`. Les réserves de lisibilité D9/ARC de `art-review.md` sont levées. L'éjection D9 et les raccords échantillonnés disposent maintenant de preuves visuelles suffisantes pour cette passe. Ce verdict ne certifie ni la fluidité en lecture continue, ni l'interface native, ni la performance, ni les collisions.

Revue du 18 octobre 2026, indépendante de l'auteur. Contrats lus : cstack-agent/runtime-base, conception acceptée et revue précédente ; probes `visual-fix/probe.gd`, `visual-fix/film.gd` et fonction `delayed_first_draw` du probe parent. Aucun Godot, ffmpeg, serveur X11, descendant ou commit lancé. Aucune source modifiée. Seuls ce rapport et les planches statiques autorisées sous `art-final-contact/` ont été créés.

## Images réellement ouvertes

Tous les fichiers suivants ont été examinés avec `view_image`, sans pixels générés ni reconstruction IA :

- Les **11 PNG originaux** de `visual-fix/candidate-d/` : `d9-rest`, `d9-000ms`, `d9-035ms`, `d9-070ms`, `d9-120ms`, `arc-rest`, `arc-000ms`, `arc-035ms`, `arc-070ms`, `arc-120ms`, `casing-secondary-whole`.
- Les trois PNG originaux de `render-final/inspection/` : `d9-first-draw`, `arc-first-draw`, `casing-secondary-whole`.
- Images du film ouvertes dans les planches `art-final-contact/` : **0 à 12**, **30/31/32/35/40**, **64/65/66/70/75**, **149/150/151/152/153/157/160/162/168**, **194/195/198/202/207/215**. Ces six planches recadrent exactement le rectangle `(620,300)–(1280,720)` des PNG moteurs, à un pixel source par pixel de planche ; les numéros sont inscrits au-dessus. Les images **7 à 12**, **30/31/32** et **64/65/66** ont aussi été ouvertes en entier, pour examiner les douilles au-dessus du recadrage et les mains à gauche.
- `art-final-contact/variants.png` : départ D9 et ARC à 0 ms pour baseline et variantes A/B/C, recadrages `(620,300)–(920,450)` à échelle native. Les captures originales restent dans `visual-fix/`.

Il s'agit d'une inspection d'images fixes consécutives et d'échantillons ciblés. Je n'ai pas visionné le MP4 en lecture continue ni écouté de piste audio. Aucun verdict ne repose sur les seuls comptes de couleur ou drapeaux `visible`.

## Observations

**D9 — PASS, certitude élevée.** La croix orange se reconnaît immédiatement à l'échelle FPS dès 0 ms et dans le premier dessin retardé du parent. Ses branches supérieure, inférieure et gauche sont distinctes ; la branche droite rejoint visuellement l'avant du canon. Elle ne ressemble plus à deux bouts occultés comme la baseline. La liaison orange demeure lisible pendant l'abaissement, particulièrement à l'image 32 : la croix accompagne la bouche au lieu de rester comme une icône dans le décor. Le départ s'éteint entre les images 5 et 6 ; les poses contrôlées le montrent absent à 120 ms. Le réticule et le couloir restent dégagés.

**ARC — PASS, certitude élevée.** Une portion annulaire cyan identifiable est présente dès 0 ms et au premier dessin retardé. Son côté droit est occulté par le modèle de l'arme ; la portion gauche suffit à lire une couronne, distincte du faisceau et des voyants permanents. À 35, 70 puis 120 ms, l'arc grandit vers l'avant et la gauche, autour du faisceau. Le déplacement axial accompagne l'expansion ; je ne vois pas d'anneau détaché flottant loin de la bouche. Les images moteur 150–157 et 195/198/202 confirment cette évolution sur deux tirs. À 160 et 207, départ et faisceau ont disparu. Imposer un anneau intégralement visible n'améliorerait pas ce cadrage : l'occultation actuelle donne une relation spatiale cohérente avec l'arme.

**Douille D9 — PASS de lisibilité, certitude élevée dans ces images.** Dans 0–6, un petit cylindre ocre apparaît au-dessus du port droit, puis s'éloigne vers le haut et la droite en tournant. Les images entières 7–12 permettent de le suivre jusqu'au bord droit. Sa silhouette est identifiable en vue FPS, malgré sa petite taille. L'éjection reste indépendante de l'abaissement à 31/32/35. Les deux vues secondaires montrent un cylindre entier ; celle de `candidate-d` vise une douille figée depuis une caméra déplacée, et celle du parent cache également le rig. Elles prouvent sa forme, pas un contact au sol. Aucune nouvelle douille n'est visible au départ ARC. Les données `frames.json` corroborent ce dernier point dans l'échantillon : une ancienne douille demeure à 149/150, disparaît à 151, puis aucun slot visible aux instants du second tir ARC. La garantie générale zéro éjection ARC reste du ressort des tests dédiés.

**Retour et interruptions — PASS sur les poses inspectées, certitude moyenne.** Dans 0–12, les mains et l'arme reviennent progressivement à leur pose de repos sans dérive visible ; le décor conserve son orientation. Le retour ARC est également cohérent entre 150 et 168, puis 195 et 215. Les valeurs enregistrées de FOV reviennent à 76, depuis 76.4 pour D9 et 76.25 pour ARC : ce sont des données du probe, pas une mesure optique indépendante.

Après B à 31, la suppression de l'impulsion accompagne le début d'abaissement. À 32 puis 35, le départ suit encore l'avant du canon ; à 40, l'ensemble est caché. Le mouvement est rapide et son amplitude entre images se voit ; je n'observe pas de main détachée, de flash figé dans l'espace ou de remontée intempestive qui justifierait une nouvelle correction. L'annulation CELL à 65 conserve la prise de la main sur l'ARC visible à 64, puis descend l'ensemble à 66 ; il est hors cadre à 70/75. La caméra ne présente pas de saut d'orientation. Cette inspection ne permet pas de qualifier le confort temporel en lecture continue ni toutes les images intermédiaires des segments échantillonnés.

Les modèles, mains, palette et décor restent cohérents avec les repos. Le contraste orange/cyan et les formes simples préservent la direction stylisée retenue, sans comparaison de qualité avec Fortnite.

## Variantes rejetées

La planche comparative confirme les limites conservées par l'auteur : A garde un D9 en T et ne donne pas de couronne identifiable au départ ; B dégage la croix mais laisse une séparation visible avec le canon et une portion ARC trop mince ; C rend la croix massive et peu reconnaissable. D conserve la croix lisible de B avec sa liaison centrale et la couronne de C. Aucune retouche des douilles n'est nécessaire pour lever la réserve visuelle précédente.

## Conditions et provenance vérifiées

`probe.gd` appelle le vrai `Player.fire()`, coupe ensuite les processus automatiques et avance explicitement la présentation à 0/35/70/120 ms. La simulation de douille est figée pour les poses contrôlées. Ces images ne prouvent pas une cadence de jeu. `film.gd` laisse avancer moteur et physique, appelle directement les méthodes Player et enregistre 270 PNG sous un réglage fixe de 60 images/s. Les événements sont consignés à 0/30 (D9), 31 (B), 65 (interruption CELL), 110 (sélection ARC), 150/195 (ARC). Aucun parcours XTest n'est exercé par ce film.

Le complément parent utilise 18 ticks physiques sans rendu puis vérifie exactement un nouveau pre/post draw. Son `journey.json` ne signale aucun échec ; les PNG montrent effectivement la croix et l'arc attendus. Le cadrage secondaire rapproché et la simulation figée sont explicitement décrits dans les métadonnées. Renderer déclaré : Godot 4.7.2, X11, OpenGL Compatibility, llvmpipe, 1280×720.

Contrôle SHA-256 indépendant : **562 entrées source**, **338 artefacts** et **42 journaux de validation** du manifeste `visual-fix/manifest.json` correspondent aux fichiers actuels, sans écart. Le HEAD Git correspond au commit annoncé ; son diff porte uniquement sur `_build_weapons` dans `scripts/player.gd`, 11 ajouts et 7 retraits. Les **186 sources** et **trois outils/binaires** de `render-final/campaign.json` correspondent également aux empreintes courantes, sans écart.

| Élément | SHA-256 vérifié |
| --- | --- |
| `scripts/player.gd` et `visual-fix/candidate-d-player.gd` | `646ec35fbceb16206627fb027a25868603c77aae80925a01d18559418288f59d` |
| `visual-fix/probe.gd` | `90c6d9effdcac58762789555bdc63959bfbe544560932a4f9764b4229421b28f` |
| `visual-fix/film.gd` | `389958ba560347d3bef88c1d651e9459eff11f85a4392a8bc2e0f9884df7d9fc` |
| `visual-fix/film-d/frames.json` | `e47e3a59a9a5b24239fb123523d3942516949f9736a07e972ef73889594fa235` |
| Probe parent `tools/probe_shot_feedback.gd` | `888a2f91a0e6458db9597e7489baa4e5ba715a2f310fe9a6d0c0659eec863f54` |
| `render-final/inspection/journey.json` | `ea91c0f6c99ff8db3e3b941741ea3aef424e933f4e5a22a14c7721b26a7fbf31` |

Le contrôle actuel prouve l'identité avec les manifestes ; il ne recrée pas un gel avant capture qui n'aurait pas eu lieu. La provenance baseline de la campagne de retouche reste celle déclarée par l'auteur : source dérivée de Git après capture, sans garde de hash pré-lancement.

## Limites et libération

Les dommages, les rayons et le point exact de collision ne sont pas démontrés visuellement : la cible parent est invisible et le film n'a pas de cible dédiée. La petite douille ne permet pas d'établir le contact, le rebond ou la pénétration par examen des pixels. Plafonds, purges, réglages indépendants, interface native et persistance appartiennent aux campagnes séparées. `performance_valid=false` est conservé ; aucun FPS mesuré ni gain de performance n'est déduit du film. Aucune exécution Windows, aucun GPU cible, aucune parité Fortnite n'est revendiquée.

Worktree lu : `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-06`, branche `feat/issue-06-shot-feedback`, HEAD `1e0ef98d00d3386cdb7185df154083759c593b4c`. Aucun worktree créé. Rapport, planches et accès source sont **libérés** pour le parent ; aucun processus ni descendant de cette revue ne reste actif.
