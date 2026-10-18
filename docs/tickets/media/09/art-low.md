# Ticket 09 : revue visuelle finale Low

Verdict **PASS limité aux poses Low examinées** sur `653e2a79c7f36e9ac7422335c85cef3b937ed0f9`. Le passage central et les objets nécessaires restent visibles lorsque Maintenance et Archives sont hors tension, avec énergie zéro et lampe éteinte. La lampe améliore la lecture proche. Aucun nouveau défaut bloquant identifié dans cet échantillon. Ce verdict ne valide ni déplacement, ni confort temporel, ni performance, ni Windows, ni une qualité comparable à Fortnite.

Skills appliqués : cstack, contrat cstack-agent, prove-it-works et unslop. Playbook Investigation borné à la revue déléguée. Throughput checkpoint: n/a, read-only investigation.

- [x] Lire la conception retenue et les risques de la preview.
- [x] Inspecter réellement 23 PNG candidates Low, 10 PNG baseline Low et une PNG historique Normal avec `view_image`.
- [x] Recouper les poses, qualités, sources et états dans les manifests et observations.
- [x] Rédiger ce rapport sans lancer de moteur, ffmpeg, descendant ou test de gameplay.

## Provenance et portée

La candidate vient de [render-final-low/manifest.json](render-final-low/manifest.json), la baseline de [render-baseline-low/manifest.json](render-baseline-low/manifest.json), source `e5b0bafa7b8bad369e6767a908b1d8391343b9f2`. Les deux manifests indiquent exit0, aucune erreur de validation et source inchangée. Une lecture indépendante des JSON confirme l'égalité de leurs propres maps `source_before` et `source_after`, 44 PNG par dossier et des positions/rotations de caméra et FOV identiques pour les 44 paires. Cela vérifie les enregistrements existants, sans relancer leurs commandes ni reconstruire tous leurs hashes depuis le dépôt.

Les observations [Low candidate](render-final-low/journey.json) donnent `scale_3d=0.670000016689301` dans les 44 poses. Les observations [Normal](render-final-normal/journey.json), consultées uniquement pour la configuration, donnent `scale_3d=1.0`. Le réglage Low a donc réellement été appliqué. Dans les 44 poses Low, les lumières fixes et la lampe ont `shadow=false`, le joueur a énergie0 et six ennemis ont une santé positive. Ces états enregistrés complètent les pixels ; les PNG seules ne prouvent pas que les robots peuvent se déplacer ou attaquer.

La baseline n'a aucune lampe de joueur : `flashlight=null` dans les 44 observations, y compris les noms de fichiers qui demandent `flash_on`. Aucune comparaison « lampe allumée avant/après » n'est revendiquée.

## Constats visuels

| Sujet | Preuves | Observation indépendante |
|---|---|---|
| Refuge et Décontamination alimentés | [Refuge avant](render-baseline-low/refuge_power_on_flash_off.png), [après](render-final-low/refuge_power_on_flash_off.png), [Décontamination avant](render-baseline-low/decontamination_power_on_flash_off.png), [après](render-final-low/decontamination_power_on_flash_off.png) | Les plafonniers deviennent froids et les bandes centrales claires. Les cadres, sols, seuils, borne énergie et terminal MÈRE restent identifiables. Le fond est sombre mais le trajet central se lit sans lampe. |
| Maintenance alimentée | [Avant](render-baseline-low/maintenance_power_on_flash_off.png), [après](render-final-low/maintenance_power_on_flash_off.png) | Le diffuseur chaud et l'éclairage voisin sont cohérents. Le rampant au sol gauche conserve sa silhouette. Les bandes claires distinguent mieux le trajet des autres lignes orange du décor. |
| Archives alimentées | [Avant](render-baseline-low/archives_power_on_flash_off.png), [après](render-final-low/archives_power_on_flash_off.png) | Le plafonnier froid correspond à la teinte bleue de la pièce. La sentinelle au centre gauche et N-7 au bord gauche restent distincts. Pas de voile lumineux ni de halo envahissant. |
| Cœur alimenté | [Avant](render-baseline-low/core_power_on_flash_off.png), [après lampeOFF](render-final-low/core_power_on_flash_off.png), [lampeON](render-final-low/core_power_on_flash_on.png) | Le réacteur cyan, les colonnes orange et le trajet restent lisibles. La lampe révèle la face de la sentinelle proche. Le rampant à gauche demeure visible. La scène conserve des volumes simples et des aplats sombres ; cela ne démontre pas une finition de niveau Fortnite. |
| Maintenance hors tension | [Avant lampe absente](render-baseline-low/maintenance_power_off_flash_off.png), [après lampeOFF](render-final-low/maintenance_power_off_flash_off.png), [lampeON](render-final-low/maintenance_power_off_flash_on.png) | Plafonnier principal éteint. Les bandes centrales restent lisibles jusqu'au passage Archives, mieux que les anciennes bandes orange. Le rampant latéral est discernable mais peu contrasté. La lampe éclaire surtout le sol proche et le bord du disjoncteur ; elle ne révèle pas artificiellement tout le secteur. |
| Archives hors tension | [Avant lampe absente](render-baseline-low/archives_power_off_flash_off.png), [après lampeOFF](render-final-low/archives_power_off_flash_off.png), [lampeON](render-final-low/archives_power_off_flash_on.png) | Porte du cœur, levier et texte OFF restent visibles. Silhouette de la sentinelle sombre mais distincte ; N-7 et sa légende cyan restent repérables. La lampe dirigée au centre ne remplace pas une recherche visuelle sur les côtés. |
| Disjoncteur proche, circuits coupés | [OFF](render-final-low/critical_breaker_maintenance_flash_off.png), [ON](render-final-low/critical_breaker_maintenance_flash_on.png) | Le texte et le levier restent lisibles à énergie000. Le faisceau révèle fond bleu, poignée et montants, avec contour doux. Le sol au pied reste visible ; absence d'ombre portée conforme à Low. |
| Preuve Archives, circuits coupés | [OFF](render-final-low/critical_evidence_flash_off.png), [ON](render-final-low/critical_evidence_flash_on.png) | L'écran cyan se repère sans lampe. Le faisceau fait apparaître le volume de la borne, les pieds de table, le mur et les joints du sol sans blanchir toute l'image. |
| Relais Maintenance, circuits coupés | [OFF](render-final-low/critical_relay_flash_off.png), [ON](render-final-low/critical_relay_flash_on.png) | La lampe révèle le cylindre et l'écran incliné. La légende SCAN reste visible sans lampe. Son chevauchement partiel avec le HUD supérieur existe aussi dans la [baseline](render-baseline-low/critical_relay_flash_off.png) ; pas une régression attribuable au ticket09. |
| Alarme autonome | [Active](render-final-low/alarm_active.png), [expirée](render-final-low/alarm_expired.png) | Lentille rouge au plafond droit et éclairage local du disjoncteur/sol visibles dans active, absents dans expired. Le plafonnier principal reste éteint. Les observations donnent énergie de l'alarme0,65 puis0, et horloge1,3 puis0. Deux états ne prouvent ni durée exacte ni transition au premier frame. |

## Néon, mode réduit et boîtier corrigé

Les extrema ont été choisis depuis les observations, et non depuis les noms de fichiers. [neon_00](render-final-low/neon_00.png) est un maximum échantillonné à énergie2,2 ; [neon_06](render-final-low/neon_06.png) est le minimum des 13 poses à1,6736. Le diffuseur et le sol s'assombrissent légèrement ensemble. Aucun des deux états ne fait perdre le trajet ou les objets proches. La variation est modeste. Des images fixes ne suffisent pas pour valider son rythme ou son confort.

Les trois images [reduced_00](render-final-low/reduced_00.png), [reduced_01](render-final-low/reduced_01.png) et [reduced_02](render-final-low/reduced_02.png) conservent visuellement le même niveau de lumière. Les observations donnent énergie2,2 pour le plafonnier Maintenance dans les trois cas. Cette sélection ne valide pas une séquence temporelle complète de l'option réduite.

L'[ancienne preview Normal](render-first/maintenance_power_off_flash_off.png), réellement ouverte pour ce contrôle, montrait un large volume bleu recouvrant le pied droit du disjoncteur et le sol. Dans la [candidate finale Low à cette pose](render-final-low/maintenance_power_off_flash_off.png), ce volume est réduit à un petit équipement près de la main. Le pied orange et le sol à droite sont de nouveau visibles ; arme et réticule gardent leur place. La comparaison porte sur l'occlusion de géométrie et non sur une équivalence d'éclairage entre Normal et Low. La [baseline Low](render-baseline-low/maintenance_power_off_flash_off.png) confirme le cadrage de référence.

## Limites de lisibilité

Le Low à échelle0,67 montre des marches d'escalier sur les poutres et des lettres 3D lointaines difficiles à lire. Ces défauts sont déjà présents dans les paires baseline, sans nouvelle dégradation manifeste attribuée au ticket09. Les textes HUD VIE, ÉNERGIE, F/R3 Lampe et LAMPE ON restent lisibles dans les images examinées.

Les ennemis hors tension restent peu contrastés, surtout le rampant latéral et les jambes de la sentinelle. Le passage central, les objets autonomes et les leviers restent identifiables à ces poses. Cela suffit au verdict visuel borné, sans prouver la facilité de repérage en combat ou sur un écran différent. La lampe a un effet utile à proximité et dans le cœur ; elle n'éclaire pas uniformément les grandes pièces, ce qui reste cohérent avec sa portée.

Aucun contrôle de mouvement, collision, commande F/R3, consommation, mission complète, scintillement, FPS ou système Windows n'a été exécuté dans cette revue. Aucun résultat du reviewer Normal ni des juges de conception n'a été lu. La conception retenue et le rapport preview ont uniquement cadré les questions à vérifier.

## Inventaire exact des images ouvertes

23 candidates dans `render-final-low/` :

1. `refuge_power_on_flash_off.png`
2. `decontamination_power_on_flash_off.png`
3. `maintenance_power_on_flash_off.png`
4. `archives_power_on_flash_off.png`
5. `core_power_on_flash_off.png`
6. `maintenance_power_off_flash_off.png`
7. `maintenance_power_off_flash_on.png`
8. `archives_power_off_flash_off.png`
9. `archives_power_off_flash_on.png`
10. `core_power_on_flash_on.png`
11. `critical_breaker_maintenance_flash_off.png`
12. `critical_breaker_maintenance_flash_on.png`
13. `critical_evidence_flash_off.png`
14. `critical_evidence_flash_on.png`
15. `critical_relay_flash_off.png`
16. `critical_relay_flash_on.png`
17. `alarm_active.png`
18. `alarm_expired.png`
19. `neon_00.png`
20. `neon_06.png`
21. `reduced_00.png`
22. `reduced_01.png`
23. `reduced_02.png`

10 baselines dans `render-baseline-low/` : les mêmes noms que les candidates1 à6,8,11,13 et15. Une image historique supplémentaire : `render-first/maintenance_power_off_flash_off.png`. Total réellement ouvert : **34 PNG distinctes**, dont23 candidates finales Low. Les21 autres captures finales Low n'ont pas été inspectées visuellement.

Seul fichier écrit : `.cstack/orchestrate/silo9/issue09/art-low.md`. Worktree source consulté par les manifests : `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-09`, branche `feat/issue-09-lighting`, HEAD de capture `653e2a79c7f36e9ac7422335c85cef3b937ed0f9`. Aucun worktree créé ou détenu en écriture, aucun processus de jeu ou descendant lancé. Tous les chemins sont relâchés.
