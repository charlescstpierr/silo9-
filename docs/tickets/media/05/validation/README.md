# Chaîne de preuve

Le runtime final est `463aabf`. `builder-verification.json` lie les 30 tests et logs par hash, et `verify-delivery.log` contient leur exécution complète. Le parent ajoute sa vérification, les gates et les rapports indépendants dans ce dossier, puis les preuves X11 dans `../native/`.

| Comportement | Rouge avant correction | Correction et vert |
|---|---|---|
| Sélection, mouvement, clic bref, activité | Gate initial sur tests-only `eecf9a9`, 27 échecs comportementaux | Runtime `7a4c79f`, suites complètes |
| Clic commencé en modale | Reproduction parent sur `7a4c79f` | `d57761e`, `parent-modal-green.log` |
| Activation répétée avec tir maintenu | `repeated-active-red.log` sur `d57761e` | `c68212d`, `repeated-active-green.log` |
| Dernière sélection classée echo | Tests-only `4114198`, `repeat-selection-red-expanded.log` | `15d2b91`, `repeat-selection-green.log` |
| Rayon ARC détaché pendant sprint | Tests-only `6ccb314`, `beam-red-candidate.log` ; aussi reproduit sur baseline dans `beam-red-baseline.log` | `463aabf`, `beam-green.log` |
| Retard vertical haut/bas | Tests-only `6ccb314`, `look-direction-red.log` | `463aabf`, `look-direction-green.log` |

Le test d'ordre du masquage est une vérification supplémentaire ajoutée après l'implémentation. Il ne constitue pas une preuve TDD antérieure. Le premier fixture de direction, incomplet côté InputMap, est exclu des preuves rouges publiées. Les captures et mesures antérieures aux derniers correctifs restent archivées localement et ne sont pas publiées comme résultat final.

`media-independent-validation.json` conserve le statut 143 inexpliqué du wrapper des captures. Les manifestes moteur attestent sortie 0 et hashes stables ; le contrôle indépendant compare les sources aux objets Git, les archives d'outils aux hashes de lancement, et décode les 701 images du MP4 sans erreur. Ces faits ne transforment pas le statut du wrapper en sortie 0.

Les mesures finales proviennent de dix lancements distincts et sérialisés. Leurs manifestes et copies exactes des outils figurent dans les dossiers `../perf-*`. Le coût du second appel du rig à delta zéro reste un microcoût de recomposition, sans progression des filtres, distinct des intervalles muraux du parcours complet.
