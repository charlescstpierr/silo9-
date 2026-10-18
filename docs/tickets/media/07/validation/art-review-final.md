# Revue visuelle indépendante du ticket 7

Verdict **PASS WITH NOTES** pour l’alignement ADS et les transitions observées. Aucun défaut visuel bloquant trouvé dans ce périmètre. Une intersection avec une paroi très proche reste visible et doit être annoncée dans la livraison.

Révision vérifiée par Git : `1f36f01eea2e5d34dafee7f46a665c013370cbb4`, branche `feat/issue-07-ads`, worktree `.worktrees/silo9-issue-07`. Les manifests de l’inspection et du film identifient cette révision. Cette revue porte sur les pixels des artefacts finaux fournis, sans relancer le jeu ni auditer le code.

## Observations

- Dans les 18 vues ADS de la matrice, le guidon se place au centre de la hausse et de l’image. Le D9 conserve ses trois repères clairs. L’ARC a une hausse ouverte et un guidon visibles au-dessus du boîtier de cellule. Le large témoin cyan reste en dessous de la ligne de mire. Les vues en position basse gardent le réticule HUD ; il disparaît dans les vues ADS.
- Les FOV de départ 60, 76 et 100 modifient la taille apparente des armes sans déplacer leur ligne de mire finale. À FOV 100, les repères occupent moins de pixels et la précision de lecture baisse, sans disparition observée. La cible de preuve de 4 cm devient minuscule à 20 m. Le comptage des impacts appartient aux preuves comportementales, pas à cette appréciation visuelle.
- Les mains visibles restent au contact de l’arme dans les poses basses et ADS. Aux FOV étroits, une partie des bras sort naturellement du bas du cadre. Aucune tranche de géométrie ni main séparée imputable au plan proche de la caméra n’apparaît dans les images inspectées. Ce constat ne garantit pas toutes les poses possibles.
- Les vues ARC accroupie et en marche conservent le guidon centré. Les quatre vues dans le SILO réel montrent des organes encore lisibles devant le couloir détaillé ; le boîtier ARC n’obstrue pas le centre de visée.
- Les blocs consécutifs du film montrent le déplacement de l’arme vers le centre et son retour, l’inversion d’une entrée ADS, les réactions au tir, la sortie pour recharger, puis le retour en visée. Les bras suivent ces mouvements sans rupture évidente dans ces échantillons. Le changement D9/ARC passe par une position abaissée hors cadre, puis remonte. Le transfert de cellule montre la main de soutien quittant puis reprenant sa place.

## Limite murale observée

Dans `wall-frontal-30cm-intersection-observation.png`, la paroi masque toute l’arme et les mains. Dans `wall-oblique-30cm-intersection-observation.png`, la partie arrière de l’ARC et la hausse restent visibles, mais la paroi coupe le boîtier latéral et masque le guidon avant. Ces deux captures montrent une intersection du modèle avec le décor. Elles ne prouvent aucune correction automatique de proximité. Cette limitation est distincte du plan proche de la caméra et ne doit pas être résumée par « aucun clipping ».

## Artefacts inspectés

Sous `render-final/inspection/`, les 36 fichiers `w{0,1}-fov{60,76,100}-{3,10,20}m-{hip,ads}.png`, plus `ads-crouch.png`, `ads-walking.png`, les deux fichiers `wall-*-30cm-intersection-observation.png` et les quatre `silo-w{0,1}-{hip,ads}.png`. Ils ont été examinés dans cinq planches étiquetées sous `render-final/art-sheets/`.

Dix PNG ont aussi été ouverts à leur résolution originale 1280×720 : les deux `w*-fov60-3m-ads.png`, les deux `w*-fov100-20m-ads.png`, `silo-w0-ads.png`, `silo-w1-ads.png`, `ads-crouch.png`, `ads-walking.png` et les deux vues de paroi.

Sous `film-final/film/frames/`, 264 images consécutives par blocs ont été inspectées dans onze planches étiquetées sous `film-final/film/art-sheets/` : `0077..0100`, `0101..0124`, `0125..0148`, `0174..0197`, `0211..0234`, `0235..0258`, `0262..0285`, `0325..0348`, `0363..0386`, `0390..0413`, `0414..0437`. Les numéros désignent les noms PNG, sans supposer leur égalité avec les compteurs internes du moteur. Les journaux `journey.json` servent à repérer les actions, pas à remplacer les pixels.

`art-reviewed-files.json` énumère les 308 fichiers originaux et leurs SHA-256. Les planches réduisent les images et ajoutent une étiquette extérieure ; elles ne retouchent pas les originaux. Le PNG de préchauffage n’est pas inclus dans le verdict.

Film dont proviennent les images inspectées : `film-final/film/ads.mp4`, SHA-256 `a20b900c6d82f95a14ebc03d6f31ba336eca8d3fa26bc1c2af2e7ddbaf28b2ce`. Le rapport ne porte pas sur une future exécution du script de preuve. Une attente de disponibilité ajoutée ensuite à ce script ne modifie pas les pixels de ce film.

## Portée et libération

Cette revue ne constitue pas une lecture continue du film, une écoute audio, une mesure de fluidité, une exécution Windows ou un essai sur manette physique. Le film à cadence fixe ne démontre pas les performances. Les formes, matériaux et bras restent ceux d’un prototype stylisé ; aucune équivalence avec la finition de Fortnite n’est revendiquée.

Aucun fichier de production modifié, aucun commit, aucun descendant, aucun Godot ou ffmpeg lancé. Créations limitées au présent rapport, au manifeste des fichiers lus et aux seize planches de revue. Aucun worktree créé ; tous les fichiers et processus de cette mission sont libérés.
