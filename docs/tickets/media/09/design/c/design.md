# C : sources fixes, ombre portée par le joueur

## Problème et ancrage

Faire reconnaître les quatre secteurs et les coupures sans augmenter le budget d'ombres. Le monde possède déjà neuf Omni et un spot mobile, `world.gd:130-139,174-179,559-571`, `world_art.gd:383-412`. Les indices du tableau déterminent actuellement la politique lumineuse. Les sources de néon et leurs matériaux sont écrits séparément, ce qui rend une panne locale fragile.
La proposition conserve le composeur central mais remplace les indices par neuf définitions explicites. Elle supprime le spot qui change de pose par secteur. Son budget d'ombre revient à une lampe portée par le joueur. Tout ce qui suit est une conception non exécutée, avec valeurs artistiques et coûts hypothétiques.
Ancrage lu : `../../grounding.md`, les trois rapports référencés, puis les sections citées du code au HEAD `e5b0bafa7b8bad369e6767a908b1d8391343b9f2`. API consultées : `../../api/{Light3D,SpotLight3D,Environment}.xml`, épinglées 4.7.2-stable par `manifest.json`. Le glow Compatibility existe mais ses paramètres diffèrent du Forward+.

## Usage avant types

Le joueur entre en Décontamination sous une lumière froide, retrouve l'atelier chaud en Maintenance, puis les Archives bleues. Au cœur, le cyan du réacteur tranche avec le seuil ambre. F allume une lampe blanche, même à énergie 0. Cliquer le stick droit fait la même action. La lampe ne découvre pas le relais caché et ne modifie pas la vision des robots.
Lors d'une coupure, le plafond s'éteint et la lentille rouge au-dessus du disjoncteur éclaire brièvement le boîtier. Le passage reste repérable par les marquages de secours et l'ambiance minimale. Le joueur conserve une raison d'utiliser la lampe pour identifier les silhouettes, sans en dépendre pour retrouver la sortie.

Sites d'appel proposés, sans implantation :
```gdscript
# SiloWorld._ready, après création des consommateurs et avant regroupement artistique.
_build_luminaires() # Construit sources et diffuseurs à partir des mêmes définitions.
# SiloWorld._refresh_power, puis rappel sans effet de bord depuis refresh.
_compose_lights() # Lit RunState, qualité, colosse et les minuteries existantes.
# Player._unhandled_input, au même niveau que les autres actions de jeu.
if event.is_action_pressed("flashlight") and not event.is_echo():
    toggle_flashlight() # Refus inactif/mort; ne dépense jamais RunState.energy.
# Main, création et application des réglages.
world.set_reduced_light_effects(reduced_light_effects)
player.set_flashlight_quality(low_quality)
```
L'aide affiche « F / clic stick droit : lampe » et le HUD « LAMPE ON » seulement lorsqu'elle est allumée. Le paramètre « Éclairage animé réduit » est séparé de `shot_light`, qui reste dédié aux tirs.

## Forme et propriété

Types privés proposés dans `scripts/data/luminaire_spec.gd`, puis références d'exécution détenues seulement par `SiloWorld` :
```gdscript
class_name LuminaireSpec
extends Resource
 enum Role { CEILING, CORE, CIRCUIT_ALARM }
 @export var role: Role
 @export var circuit: StringName # Vide = alimentation fixe, jamais une alarme.
 @export var origin: Vector3
 @export var tint: Color
 @export var energy_normal: float
 @export var energy_low: float
 @export var radius: float
 @export var faulty: bool = false # Un seul CEILING de Maintenance.
# Binding privé construit une fois, pas de recherche d'arbre pendant le jeu.
class LuminaireBinding:
    var spec: LuminaireSpec
    var light: OmniLight3D
    var emitter: StandardMaterial3D
# Dans World : Array[LuminaireBinding], référence directe au néon défaillant.
func _build_luminaires() -> void: pass # TODO construire et valider les neuf définitions.
func _compose_lights() -> void: pass # TODO unique writer de lumière et diffuseur associés.
func set_reduced_light_effects(value: bool) -> void: pass
# Dans Player : bool transitoire et un SpotLight3D enfant de Camera3D.
func toggle_flashlight() -> bool: return false # TODO garde active/health, bascule unique.
func set_flashlight_quality(low: bool) -> void: pass
```
La validation de construction refuse les identifiants de circuits inconnus, une alarme sans circuit, plusieurs néons défaillants et les valeurs non finies. Aucun validateur par frame. Principe boundary-discipline.
`PowerConsumers` conserve la durée, le cooldown, le son et la décision de déclencher l'alarme. Le composeur lit `alarm_remaining`, sans deuxième horloge ni nouvel événement gameplay. La lentille est référencée par le binding et son matériau dupliqué une seule fois. Enlever ses autres écritures de visibilité dans `PowerConsumers`; conserver `stop_alarm` comme modification de la minuterie et du son.
Les émetteurs de luminaires sortent explicitement de `PowerMaterials`; ce dernier garde le décor sectoriel. Ainsi, aucun matériau n'a deux auteurs. Principe separate-before-serializing-shared-state.
`_compose_lights` reste idempotent. L'animation du néon utilise une phase scalaire de session mise à jour par World; seuls le néon et les alarmes actives nécessitent une actualisation continue. La recomposition totale intervient aux transitions existantes. Aucun Tween n'écrit `light_energy` directement.
L'interface publique ajoute seulement deux réglages et une commande. Elle cache la priorité des effets, la synchronisation diffuseur/source et le budget des lumières. Le parcours input→Player et état→World reste dans deux fichiers par décision, selon minimize-reader-load.

## Plan d'éclairage concret

Valeurs initiales proposées, à régler après comparaison rendue. Le diffuseur et la lumière partagent le même x et z; la source est 0,12 m sous sa face, hors de son boîtier.

| Lieu | Source réelle et diffuseur | Palette | Énergie Normal / Low, portée |
|---|---|---|---|
| Refuge | Plafond `(0,4.78,6)`, barre existante | crème `FFE1B5` | 1,3 / 2,1 ; 12 m |
| Décontamination | Plafond `(0,4.78,-5)`, barre existante | blanc cyan `B9E5EA` | 1,3 / 2,1 ; 12 m |
| Maintenance | Plafond `(0,4.78,-22)`, barre et joues ambre | ambre clair `FFD09A` | 1,5 / 2,2 ; 12 m |
| Archives | Plafond `(0,4.78,-42)`, barre et joues bleues | bleu pâle `B4D0EF` | 1,3 / 2,1 ; 12 m |
| Cœur, seuil | Plafond `(0,4.78,-63)` | ambre clair `FFD09A` | 1,2 / 2,0 ; 11 m |
| Cœur, fond | Plafond `(0,4.78,-73)` | blanc neutre `D5E7DF` | 1,0 / 1,9 ; 10 m |
| Réacteur | Omni existante `(0,2.7,-72)`, orb et anneaux | cyan `63E9E0` | 2,4 / 0 ; 7 m |
| Deux alarmes | Réaffecter les accents `z=-30/-58` aux deux `CircuitSpec.alarm_position`, au contact des lentilles | rouge `FF513B` | 0,9 / 0,65 ; 4 m |

Les plaques danger conservées à `z=-30/-58` restent des panneaux réfléchissants ou faiblement émissifs, sans prétendre éclairer leur secteur. Aucun luminaire invisible déplacé avec le joueur. Les six barres conservent leurs boîtiers, sans nouvelle collision. Leur couleur diffuse suit leur lumière; les matériaux des objets de mission et yeux restent autonomes.
Le balisage de secours réutilise les bandes au sol `(x=±2.1,y=.025,z tous les 4 m)`, `world.gd:169`. Matériau indépendant, blanc cyan très peu émissif, clairement déclaré autonome. Garder l'ambiance globale 0,18 pour la première comparaison. Si les silhouettes deviennent illisibles, régler l'ambiance ou les énergies avant toute livraison; les bandes seules ne prouvent pas cette lisibilité.
Lampe à `(0.12,-0.10,-0.15)` relativement à la caméra, direction avant. Spot blanc chaud `F2E8D4`, portée 14 m, angle 32°, énergie initiale 2,5. Masque monde 1 pour ne pas brûler les mains. Petit boîtier visible attaché au rig, aucune collision. Normal autorise son ombre; Low la supprime. Toutes les autres lumières restent sans ombre.

## Composition et animation

Le plafond défaillant Maintenance a un cycle de 6 s : stable 1,0 pendant 4,8 s, descente douce vers 0,65 en 0,4 s, remontée en 0,8 s. Aucun noir ni clignotement rapide. En effets réduits, gain constant 1. Le même gain multiplie lumière et émission, sans toucher le reste du secteur.
Plafonds et cœur : courant d'abord, puis énergie de qualité, puis gain néon et colosse. Fin choisit la teinte finale existante; elle ne rétablit jamais le courant. Fin suspend le néon pour que le signal narratif reste stable. Effets réduits remplace aussi la chute du colosse par un gain minimum 0,75.
Alarme : seulement si `alarm_remaining > 0` et fin différente de N-7. Une montée douce sur 0,15 s puis rouge stable, extinction à 1,5 s; effets réduits utilise le même plateau sans animation. La lentille et sa lumière partagent ce gain. Elle reste visible lorsque son circuit est OFF, y compris en Low. Le colosse et les teintes finales ne repeignent pas ce signal de sécurité.
Lampe : OFF à chaque nouvelle session/chargement. Ne change pas pendant pause ou dialogue; input refusé par `active` et santé comme le tir. Elle retrouve son état après fermeture d'une modale. La mort l'éteint. Aucun champ dans la sauvegarde schéma3; le réglage d'accessibilité va dans `settings.cfg`.
La lampe ne produit aucun bruit et ne modifie aucune perception. Le stick droit est libre dans `main.gd:658`; éviter la croix directionnelle, déjà partagée avec navigation et ARC.

## Coût, compromis et alternative

Hypothèse, non mesure : neuf Omni allouées comme avant, mais sept sources fixes au maximum en jeu normal hors alarme contre neuf auparavant. Une lampe spot remplace le spot mobile. Ombres simultanées : au plus une en Normal, zéro en Low. En Low, six plafonds, la lampe et au plus deux alarmes peuvent éclairer; cette hausse transitoire doit être mesurée.
Supprimer `_shadow_light`, `update_focus` et leurs états dédiés une fois les appelants migrés. Le gain de coût reste hypothétique : une ombre mobile peut coûter plus qu'une ombre fixe, malgré le même nombre. Accepter la perte d'ombres architecturales lampe OFF en échange d'une source crédible et d'un arbitrage simple du budget.
Glow OFF par défaut. Expérience distincte sur vues refuge, Maintenance, Archives et cœur : comparer OFF/ON à poses et exposition identiques, puis coût apparié sans capture. Ne le retenir que si la revue préfère le résultat sans effacer détails/inscriptions et si son coût mesuré est acceptable. Aucun gain de glow présupposé; aucun projecteur de texture, non pris en charge en Compatibility.
Alternative structurelle viable : neuf `Luminaire3D` locaux, chacun propriétaire de son Omni, diffuseur et phase. `apply_context(powered: bool, low: bool, ending: StringName, colossus_gain: float, reduced: bool)` reçoit les transitions World; les alarmes s'abonnent au contrôleur de circuit. World cesse d'écrire ces propriétés, `PowerMaterials` exclut leurs diffuseurs. Une instance néon traite seule son temps. Cette forme cache la mécanique de synchronisation par composant et facilite l'ajout d'une lampe.
Je préfère ici la table centrale : l'alternative expose le contexte de priorité à neuf instances et ajoute leur cycle de vie pour seulement un effet autonome. Elle reste préférable si le prochain niveau doit permettre à des artistes de placer beaucoup de luminaires indépendants. Aucun bus d'événements général, ni système de priorité configurable n'est nécessaire dans les deux formes.

## Preuves requises et prochaine étape

TDD : lampe à énergie0, refus pendant modale/mort, une bascule par pression, remise à zéro au chargement; OFF ne revient jamais pendant néon/colosse/fin; rouge alarme borné et autonome, arrêt N-7; émission et lumière du néon synchronisées; stabilité des références après 100 transitions. Garder tests de mission, collision et restauration. Remplacer les seules assertions d'énergie/topologie artistiques par les contrats de sources et d'ombres justifiés ci-dessus.
Étendre la sonde et le wrapper existants, pas un nouveau moteur de preuve. Capturer les mêmes poses Normal/Low, lampe OFF/ON, deux circuits OFF, énergie0; inclure silhouettes vivantes, disjoncteurs et relais découvert. Capturer le néon haut/bas et l'alarme avant toute attente de combat. L'examen des pixels à taille réelle est indépendant du succès du raycast.
Mesurer cinq paires alternées par qualité sur la route historique inchangée, puis un scénario cœur et alertes séparé. Conserver hashes moteur, wrapper et source, échelle effective et compte d'ombres. Exiger zéro encodeur pendant mesure. LlvmPipe ne démontre aucun FPS joueur ni coût GPU cible.
Première étape après sélection parent : écrire les tests comportementaux seuls, observer les rouges sur la base, puis retirer le spot mobile et construire les neuf bindings. Aucune décision humaine nouvelle nécessaire. Risques à trancher par rendu : contraste à énergie0, ombre mobile plus chère, perte de volume lampe OFF et recouvrement des lumières sur les lots de décor.
Décision de synthèse réservée au parent. Candidat C rédigé sans lecture des autres candidats ni grille. Aucun moteur, test, code de production, commit, push ou descendant lancé. Worktree consulté en lecture seule puis relâché; seul ce document est écrit.
