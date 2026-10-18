# Jugement indépendant 1 — ticket 09

Lecture dans l'ordre P → Q → R, après brief, grille privée et `issue09/grounding.md`. Aucun mapping, autre dossier candidat ou autre jugement lu. Modèle hérité; aucune diversité de modèles revendiquée.

**Base recommandée : Q**, avec les greffes bornées ci-dessous. Le choix final appartient au parent.

## Statut de vérification

P, Q et R sont des conceptions non exécutables : **non vérifiés**, aucun vert ni rouge de tests. Les notes jugent la précision de leur conception et de leur preuve prévue; elles ne certifient ni rendu ni performance.

Source consultée readonly au HEAD `e5b0bafa7b8bad369e6767a908b1d8391343b9f2` : `world.gd:527-571`, `power_consumers.gd:126-168`, `power_materials.gd`, `player.gd:135-150,306-333`, `main.gd:636-680`. Aucun moteur, test ou benchmark lancé.

## Notes /25

| Axe /5 | P | Q | R |
|---|---:|---:|---:|
| Lisibilité et direction artistique concrète | 4 | 4 | 4 |
| Coût borné | 4 | 4 | 4 |
| Contrats corrects | 4 | 5 | 5 |
| Simplicité de propriété | 4 | 5 | 4 |
| Preuves exécutables prévues | 5 | 5 | 5 |
| **Total** | **21** | **23** | **22** |

Tous décrivent des palettes, positions, sources synchronisées et scénarios pénombre précis. Tous laissent justement la lisibilité et le coût à mesurer. Aucun ne mérite un avantage esthétique sur la seule prose.

P propose un secours permanent OFF utile pour retrouver les disjoncteurs, mais son rayon8m pourrait réduire visuellement la distinction ON/OFF. Son réglage d'effets partagé ne traite pas explicitement la forte variation du colosse et ajoute un nouveau signal d'alarme. Ce sont des risques de conception, pas des régressions constatées.

Q préserve une entrée de composition unique et lit la minuterie existante sans nouveau signal. Son option lumineuse distincte exprime plus clairement l'accessibilité que le changement de sens du budget d'effets de P. Ses transitions, priorités et suppression des anciens writers sont les plus directement implémentables dans le monde actuel.

R offre la meilleure encapsulation locale de géométrie/source/matériau. Son contexte partagé et la liaison de minuterie ajoutent cependant un cycle de propagation à expliciter, sans bénéfice immédiat établi pour neuf équipements fixes. Les neuf conteneurs restent un coût borné, pas un problème de performance démontré.

## Comparaison des formes globales

**Forme centrale P/Q** : World possède les bindings, la phase du seul néon et les écritures des lumières/lentilles. PowerConsumers conserve la mécanique et les horloges. Player possède la lampe. La politique courant/fin/colosse se lit dans un seul ordre; les transitions existantes appellent déjà ce composeur. Q évite le signal supplémentaire de P.

**Forme locale R** : chaque IndustrialFixture possède construction, matériau et composition. World distribue un contexte global, PowerConsumers distribue le temps d'alarme, une fixture anime le néon. C'est une frontière réellement différente, non un alias de la table : les écritures finales et le cycle de vie passent aux nœuds locaux.

R serait préférable pour des luminaires réutilisés ou édités séparément. Ici, Q couvre le niveau fixe avec moins de nœuds et moins d'étapes de propagation. Le coût supplémentaire de R ne suffit pas à le rejeter; c'est la simplicité de vérification des priorités qui départage. L'argument de P selon lequel les composants exigeraient neuf processeurs n'est pas acquis : R n'en active qu'un pour le néon.

## Greffes précises et corrections avant production

1. **Depuis R : garde de reprise de F maintenu.** Étendre le contrat Q avec refus curseur libéré et test natif appui pendant modale → reprise → relâchement, sans bascule parasite. R décrit ce scénario explicitement; `Player.set_active` possède déjà des captures analogues pour tir/visée.
2. **Depuis R : réduire réellement les variations du colosse.** Préférer gain constant1 avec l'option d'accessibilité, son et événement conservés. Le plancher0,75 de Q reste une variation dont la nécessité n'est pas établie. Tester cette exception de présentation sans toucher l'état narratif.
3. **Depuis P : secours physique comme solution conditionnelle, pas ajout immédiat.** Si les captures Low/OFF/lampeOFF échouent, essayer ses deux lentilles autonomes à faible énergie avec le budget existant, puis comparer lisibilité et coût. Ne pas les greffer sans cette preuve : elles changent durablement l'apparence des coupures.
4. **Depuis R : balisage autonome limité.** Q doit sélectionner explicitement les seules bandes du passage central, sans rendre indépendant tout le décor sectoriel. Conserver la frontière `PowerMaterials` pour les autres émissions.

Rejeter la classe locale R pour cette tranche et le signal `alarm_changed` de P : aucune exigence du brief ne les nécessite avec Q. Garder glow OFF jusqu'à l'expérience séparée; aucun gain n'est présumé.

## Risques à fermer par preuves

- **Source et ownership** : les lentilles sont actuellement montrées/cachées par `cut_alarm` et `stop_alarm`. Retirer ces écritures lors du transfert, y compris à l'expiration. Conserver le matériau hors du registre `PowerMaterials`. Tester stop par minuterie, ON et N-7, ainsi qu'un refresh répété sans son rejoué.
- **Minuterie** : préciser quand World relit `alarm_remaining` et compose après son expiration; ne pas créer une seconde horloge d'alarme. Tester le premier et dernier état visibles, pas uniquement un échantillon au milieu.
- **Budget** : dix Light3D monde/exploration allouées ne prouvent aucun coût égal. Le spot mobile à ombre peut élargir la scène rendue. Mesurer lampeOFF/ON et alertes simultanées séparément de la route historique; lumières d'arme inchangées comptées à part.
- **Interaction et équité** : sans ombres en Low, le faisceau peut traverser les murs. La pénombre ne diminue pas la vision ennemie. Captures de robots vivants et façades lisibles à énergie0 obligatoires, sans remplacer cette preuve par le succès du raycast.
- **Présentation** : perte des ombres architecturales lampeOFF et augmentation de la hauteur des sources peuvent aplatir les volumes. Examiner tous les secteurs et le cœur à taille réelle avant approbation visuelle.
- **Validation** : conserver les assertions de mission, restauration et coupure; remplacer seulement les valeurs artistiques devenues obsolètes. Hashes source/moteur/sonde/wrapper par campagne, mêmes conditions A/B, aucun encodeur pendant les mesures. GPU cible et Windows restent non vérifiés sans exécution adaptée.

Seul ce rapport est écrit. Aucun descendant, production, runtime, commit, push ou PR. Worktree consulté puis relâché; aucun processus persistant créé.
