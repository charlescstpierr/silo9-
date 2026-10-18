# Revue finale indépendante des outils de preuve

Verdict : **PASS**, dans le périmètre outils/protocole. Aucun défaut concret restant identifié pouvant produire une fausse preuve dans les parcours examinés. Ce verdict ne valide ni les pixels, ni un gain de performance, ni une écoute ou lecture continue du film.

## Périmètre et identité

Lecture intégrale des deux outils actuels `tools/probe_shot_feedback.gd` et `tools/prove_shot_feedback.py`, de la revue initiale et du rapport de durcissement. Contrats chargés : cstack-agent, runtime/base et comment-reviewer du plugin cstack 0.8.0. Lecture ciblée des manifests, journeys, logs d'import/rendu/rejet, du résultat des tests Python et de `film-final/film/decode-verification.json`.

Worktree préexistant : `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-06`, branche `feat/issue-06-shot-feedback`, HEAD observé `5fd906f97c3e6635ad7767d9a29b4c838429e072`.

Les deux outils actuels sont identiques octet pour octet aux fichiers de lancement de l'inspection et du film. Leurs petits fichiers archivés correspondent aussi aux SHA-256 des manifests : probe `888a2f91a0e6458db9597e7489baa4e5ba715a2f310fe9a6d0c0659eec863f54`, runner `269a463a0010e1dad170d43d7bb257f71f093c5f43de8e321c32ec7854199d8f`. Aucun hash du binaire moteur recalculé pendant cette revue.

Inspection et film concernent la source `1e0ef98d00d3386cdb7185df154083759c593b4c`. Le diff vers HEAD confirme que le seul changement de source de production ultérieur est le garde de visibilité du bouton dans `scripts/main.gd` ; un test et `tools/verify.sh` changent aussi. Player n'a pas changé. Ces archives ne sont donc pas présentées comme des exécutions du HEAD actuel complet.

## Fermeture des trois constats initiaux

1. **Préparation avant mesure** — `prove_shot_feedback.py:69-87,183-184` importe chaque projet avant les parcours. Les manifests d'import inspection/film indiquent `measured:false`, sortie 0 et identités avant/après égales ; les logs portent Godot 4.7.2. L'import headless est limité à la préparation. Certitude élevée sur le code et les archives lus.
2. **Identité de campagne** — `prove_shot_feedback.py:30-65,115-148,207` fige sources, tests, révisions, outils et moteur ; vérifie à l'entrée, dans le finally et avant agrégation. Les trois budgets candidats partagent cette identité. Une mutation/commit entre invocations ne peut plus être silencieusement absorbé par une nouvelle identité de référence. Le fichier de lancement est conservé. Le log Python existant indique 10 tests réussis ; aucun test n'a été relancé ici et le faux exécutable de ces tests n'est pas une preuve Godot.
3. **Renderer actif** — `probe_shot_feedback.gd:52-61,90-103` et `prove_shot_feedback.py:90-111` vérifient moteur, X11, Compatibility, driver OpenGL, adapter, boucle active, progression du dessin et capture de préparation. Les logs réels montrent les erreurs attendues pour headless, dummy et disable-render-loop ; le JSON de rejet indique sortie 1 et aucun journey n'existe aux trois destinations. Les logs de l'inspection/film montrent le vrai backend Compatibility llvmpipe, leurs manifests une sortie 0 et leurs journeys aucune assertion en échec. Certitude élevée ; ce n'est pas une preuve de GPU matériel ni de lisibilité des effets.

## Ajouts du parent et comptage

- **Gros plan douille** (`probe_shot_feedback.gd:189-206,279`) : limité au mode inspection, après les tirs du parcours principal. La caméra est déplacée, le rig masqué et la physique du pool suspendue ; pose, visibilité du rig et état de simulation sont restaurés ensuite. L'archive contient `casing-secondary-whole.png` avec une description explicite de cette manipulation. Cette image ne prouve pas la taille ou la lisibilité de la douille depuis la caméra FPS normale. Elle n'entre jamais dans le parcours performance.
- **Film tir puis B** (`:209-217`) : le dixième tir appelle le vrai `fire()`, puis `request_cell()`. Après 4,2 secondes simulées, le code exige une cellule consommée, le transfert exact de 60 points plafonné à l'énergie maximale, le retour à l'arme D9 et l'état READY. Les archives ont zéro échec, 10 événements/hits et une somme de dommages recalculée de 324 : six D9 à 28 et quatre ARC à 39. L'événement supplémentaire est à la frame 320 ; les stages B couvrent 127 échantillons. Les assertions prouvent la fin du transfert/retour dans ce parcours ; elles ne mesurent pas une latence précise ni le câblage de la touche physique B.
- **Quotas distincts** (`:107`, runner `:156-157`) : inspection 12 événements/hits et 380 dégâts recalculés, dont trois tirs de profils après le parcours ; film 10/324 ; performance toujours 9/296. Le champ `film_supplement` rend l'ajout explicite malgré le libellé commun du scénario principal. Aucun mélange film/performance dans l'agrégation.
- **Profils visuels** (`:282-289`) : le profil 0 change simultanément caméra, lumière et budget ; 1 et 2 rétablissent caméra/lumière à 1. Ces captures comparent des configurations complètes. Elles ne démontrent pas isolément l'effet du seul budget 0. Les contrôles séparés de chaque option restent aux suites/natif dédiés et ne sont pas revalidés par cette revue.

## Bornes de preuve conservées

Les deux premiers dessins retardés ont 18 ticks physiques, aucun callback pre/post supplémentaire pendant la pause, puis exactement un callback de chaque type à la capture. Les valeurs sont vérifiées directement dans les snapshots/captures existants. Les compteurs de visibilité et orange/cyan restent des diagnostics, avec un gate manuel pixels explicite. Aucun PASS visuel n'est déduit de ces compteurs.

Les longueurs brutes/stages sont concordantes (869 inspection, 408 film), les intervalles sont finis/positifs et les percentiles archivés correspondent au recalcul local selon la convention du probe. Les deux journeys déclarent `performance_valid:false`. Leurs durées ne sont pas des mesures de fluidité : l'inspection interrompt le rendu et déplace la caméra ; le film capture à cadence simulée fixe. La série performance active n'a pas été inspectée ni jugée ici. Le verdict du runner demeure inconclusif avant analyse du limiteur et de la variation.

`decode-verification.json` décrit un décodage et une sélection de frames examinées par le parent, avec absence d'écoute continue explicitement déclarée. Je n'ai ni décodé, ni visionné, ni écouté le média pendant cette tranche ; ces observations visuelles du parent ne deviennent pas une observation indépendante de ma part.

Passe **no-comments** sur les outils et ajouts : aucun commentaire ou texte ajouté actionnable, aucun contournement caché identifié. Les labels de caméra secondaire, de film non fluide et de limite pixels correspondent au comportement du code. Aucun constat de style.

## Fin et libération

Seul ce rapport a été écrit. Aucun descendant, test, runtime Godot, ffmpeg, profiler, accès distant, mutation source, commit ou processus persistant. Calculs locaux limités aux petits JSON et à l'identité des deux outils archivés. Aucun worktree créé ou supprimé. **Revue terminée ; worktree et fichiers explicitement libérés pour le parent.**
