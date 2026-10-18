# Revue finale bornée du ticket 5

Verdict : PASS pour le delta de correction modale au SHA exact `c68212d018b48a5e191e30aa939558cb8adb592f`. Le P2 de `code-review.md` est corrigé et aucun nouveau constat actionnable n’est établi sur ce delta. Ce verdict ne ferme pas l’incident de sélection native rapide encore investigué par le parent et ne constitue pas une validation générale de livraison.

Périmètre relu : `7a4c79fbf7772552ddfbc359e4ac2c271bc1f28c..c68212d018b48a5e191e30aa939558cb8adb592f`, soit trois lignes de production dans `scripts/player.gd`, la régression d’activation répétée dans `tests/test_weapon_input.gd`, la nouvelle suite `tests/test_weapon_modal_input.gd` et sa prise en charge X11 dans `tools/verify.sh`. La revue précédente reste conservée et ses résultats sont réutilisés uniquement pour les parties inchangées.

## Correction vérifiée

`scripts/player.gd:109-115` conserve l’ancien état actif avant la transition et échantillonne la pression tenue seulement lors du passage inactif → actif. Une pression née pendant l’inactivité arme ainsi la garde jusqu’au relâchement. Un appel répété à `set_active(true)` pendant une rafale active ne réarme pas la garde. La libération existante par événement souris ou absence de pression au tick autorise ensuite un clic neuf. Les ressources, délais de tir, sélection, profils et contrôleur n’ont pas changé dans ce delta.

Le rouge parent sur `7a4c79f` a été lu dans `parent-modal-red.gd/log` : sortie 1, cartouches 11 → 9 après reprise sans nouveau clic. Les preuves builder `parent-modal-green.log`, `repeated-active-red.log` et `repeated-active-green.log` ont été lues. Elles sont des preuves fournies, pas des exécutions du reviewer. Le vert courant a été vérifié séparément ci-dessous.

## Exécutions indépendantes sur c68212d

Les deux suites `test_weapon_input.gd` et `test_weapon_modal_input.gd` passent, chacune avec sortie 0, sous `xvfb-run -a`, X11, pilote de rendu dummy et audio Dummy. La première conserve les clics brefs, cooldowns, premier tick long, maintien, capture et refus ; elle confirme aussi que l’activation répétée préserve une pression active. La seconde utilise le dispatch moteur et confirme la suppression du tir modal ainsi que le nouveau clic après relâchement.

Une matrice temporaire indépendante a ensuite testé les deux armes et chacune des reprises Escape, Tab et B par `Input.parse_input_event`. Les six scénarios vérifient l’entrée effective en pause, le retour READY sur l’arme d’origine, les comptes et un clic neuf après relâchement. Aucune pression tenue depuis la modale ne consomme de balle ou d’énergie. Pour B, seule la cellule demandée est consommée et l’énergie passe normalement de 40 à 100 ; aucune décharge ARC parasite ne la réduit. Deux scénarios supplémentaires vérifient `set_active(true)` répété pendant un maintien actif sur D9 et ARC. Les 26 assertions passent et le processus termine avec sortie 0.

Preuves sous `.worktrees/silo9-issue05-review/.cstack/review-issue05-final/` : `test_weapon_input.log`, `test_weapon_modal_input.log`, `modal_matrix.gd`, `modal_matrix.log`. Les deux dossiers utilisateur `user-data` et `matrix-user-data` sont privés à cette passe. Aucun log ne contient d’erreur de script, de parsing, d’erreur moteur ou d’assertion échouée. `git diff --check 7a4c79f HEAD` passe.

## Commentaires et limites

Aucun commentaire ajouté ou modifié dans le delta. Aucun constat actionnable de revue des commentaires, aucune suppression ou modification appliquée.

Les onze suites et la revue de sélection, masquage, ressources, géométrie et mouvement documentées dans `code-review.md` restent des résultats exécutés sur `7a4c79f`, pas des suites toutes rejouées sur ce SHA. Le correctif courant est limité à l’entrée lors d’activation et aux tests. Aucun rendu, benchmark, mesure matérielle ou validation perceptuelle n’a été exécuté dans cette passe.

Le parent signale encore une séquence native 1/2/1 à 30 ms aboutissant parfois à ARC. Le dispatch moteur précédent avait abouti à D9. La cause et les événements réellement reçus restent en investigation parent ; ce rapport ne classe pas cet incident comme résolu ni comme faute du contrôleur. Les tests présents ne remplacent pas cette vérification native.

## Libération

Worktree reviewer relâché : `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue05-review`, detached HEAD `c68212d018b48a5e191e30aa939558cb8adb592f`. Aucun descendant, commit, push ou autre action distante. Aucun fichier suivi modifié. Les huit `.gd.uid` non suivis déjà constatés restent préservés. Tous les moteurs et Xvfb privés de cette passe sont terminés. Aucun usage du display :100. Le parent garde la propriété de son moteur natif et de la libération globale du worktree partagé.
