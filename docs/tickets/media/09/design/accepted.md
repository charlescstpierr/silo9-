# Conception retenue pour le ticket 09

Retenir C, dossier anonymisé Q. Les deux juges indépendants recommandent Q,23/25 et22/25. Le parent avait A/C ex aequo22/25 et accepte le départage par la propriété centrale et l'option d'accessibilité distincte. B/R est une alternative globale réellement différente, mais ses composants et contexte partagé ne sont pas nécessaires pour neuf sources fixes. Les dossiers sont non exécutés, pas verts. Limite: R conservait un chemin d'origine dans sa dernière ligne; aucun juge n'a consulté le mapping. Cette fuite mineure d'identité est conservée dans judge2.md.

## Forme et comportement

La base complète est c/design.md, avec ces précisions et greffes prioritaires.

- World possède un tableau typé de définitions et bindings des neuf Omni fixes et de leurs émetteurs. Éviter indices magiques et listes parallèles de couleurs. Construction source/diffuseur depuis une même origine. Pas de gestionnaire général ni de conteneur Node par lampe. Les types peuvent être privés au monde ou dans un petit fichier de données si cela réduit réellement la complexité; pas de catalogue externe à valider arbitrairement.
- Conserver world.lights comme collection réelle des Omni utilisée par les sondes/parcours; elle ne porte pas la politique. Les bindings/specs portent rôle et alimentation. Les appelants lisant shadow_key/update_focus sont migrés puis ces anciens symboles supprimés dans la même unité.
- Six plafonniers, un cœur, deux Omni d'accents réaffectées aux alarmes. Placement/palette de C comme départ à ajuster par rendu. Sources décalées seulement de12cm sous leur diffuseur, même x/z. Réutiliser boîtiers existants sans doublons ni collisions nouvelles.
- Une source principale coupée reste réellement éteinte, lumière et émission. Fins et colosse ne la rallument jamais. Le néon défaillant Maintenance suit le cycle doux de C et devient stable en fin. Sa lentille ne partage pas le matériau des objets de mission.
- Les deux alarmes sont explicitement autonomes hors tension, durée/cooldown/son inchangés. PowerConsumers garde la seule horloge. World est seul writer de leur lumière/lentille; aucune écriture concurrente conservée. Composition immédiate après transition et extinction au premier frame suivant expiration, ON ou N-7; ne jamais laisser la dernière image rouge figée. Polling borné des2horloges est acceptable; pas de nouveau signal plus seconde horloge.
- Greffe B/R: option booléenne explicite « Réduire les variations lumineuses » dans settings.cfg, défautfalse. Stabilise néon, enveloppe d'alarme et gain colosse à1 sans retirer son/événement. Ne change pas la sémantique du budget d'effets ni shot_light. Validation à la frontière config comme options existantes.
- Greffe A/P: alimentation principale/autonome explicite dans les définitions et tests. Pas de secours lumineux permanent ajouté initialement. Si Low/OFF/lampeOFF est illisible, essayer les sources déjà allouées à faible énergie et mesurer ce scénario avant adoption.
- Balisage autonome limité aux seules bandes du passage central déjà présentes. Les autres émissions sectorielles restent dans PowerMaterials. Yeux, objets de mission et scan gardent leurs propriétés autonomes.
- Lampe Player Spot fixée caméra selon C, masque1. F physique surWASD/ZQSD et clic stickdroit. Commande refusée inactif, mort, curseur libre ou répétition. Une pression donne une bascule; F tenu en modale/reprise exige relâchement avant une nouvelle activation. Aide F/R3 et étatON lisible. OFF au nouveau joueur/chargement, conservée en pause. Aucun coût/bruit/découverte/perception/sauvegarde supplémentaire.
- Le spot du joueur remplace le spot sectoriel mobile. Maximum1ombre d'exploration en Normal,0Low. NormalON lampe doit produire une vraie ombre cohérente. Les lumières d'armes restent inchangées. Perte de relief lampeOFF est un risque à juger sur les captures, pas une amélioration déjà prouvée.
- Glow resteOFF. Prototype séparé rejeté visuellement pour .3/seuil1/bloom0. Timings exploratoires non concluants pour livraison, voir ../glow-prototype/parent-decision.md. Aucun nouveau post-traitement sans expérience.

## API attendue et observabilité

Main appelle world.set_reduced_light_effects(bool), player.set_flashlight_quality(bool) à la construction et lors de changements. Player expose toggle_flashlight()->bool et flashlight_on. Les commandes réelles passent par Input. Les tests inspectent les véritables Light3D et matériaux rendus, pas une copie de valeurs attendues dans un mock.

Les sources ont des identifiants de domaine stables: ceiling_refuge,ceiling_decontamination,ceiling_maintenance,ceiling_archives,ceiling_core_entry,ceiling_core_end,reactor,alarm_maintenance,alarm_archives. Nommer les Light3D correspondantes pour observation; lampe du joueur nommée Flashlight. Rôle/alimentation peuvent être lus dans les specs typées. L'animation doit pouvoir être exercée déterministement par delta sur une fonction interne réelle, sans horloge de test parallèle.

## Tests avant production

Tests-only sur basee5b0baf. Rouge sémantique parent, aucun parseerror accepté. Garder les tests absents-API exécutables via has_method/find_child puis assertions explicites.

1. Lampe réelle à énergie0; inputF et stickdroit; aucune action en modale/mort/curseur libre; répétition et repriseF maintenu; pas de mutation énergie/relais; pause conserve, nouvelle partie/chargement réinitialiseOFF.
2. Courant et qualité dans les deux ordres; lumière/émission synchrones sur néon; coupure prioritaire pendant néon/colosse/fins; option réduite stable; aucun effet sur voisin/objets de quête.
3. Alarme autonome visible immédiatement, extinction durée/ON/N-7, cooldown et aucune relance parrefresh; nombre de lampes/materials stable après cycles; bornes d'ombres.
4. Préserver migration/save3, mission, scan obligatoire, sas/collisions, trajectoires et deux fins. Tests existants à adapter explicitement: test_sector_power_effects, test_sector_power_commands, test_world; seules hypothèses de topologie/énergie/ancien spot changent. Ne pas supprimer les assertions de fond. Produire diff motivé.

## Preuves de livraison

Réutiliser outils sector_power; aucun framework de preuve parallèle. Captures appariées5zones et néon/alarme en fenêtre, Normal/Low, secteursOFF, énergie0, lampeOFF/ON, ennemi vivant et façades. Parcours physiques des deux conclusions avec ressources/dégâts. Revue indépendante des images, pas simple raycast. Mesures historiques9stations conservées, cinqpaires parqualité sans capture; scénario complémentaire cœur/lampe/alarme séparé. Hashes moteur/wrapper/sonde/source et états effectifs. GPUcible/Windows restent nonvalidés; question matériel envoyée sans bloquer les travaux locaux.

## Séquence et propriété

Un auteur tests-only; parent relit et reproduit rouge; builder distinct production ensuite. Runtime unique. Outils de preuve peuvent être développés séparément après gel des APIs. Revue code/art/perf distincte et publication des limites avant PR prête. Aucun merge/release/déploiement.
