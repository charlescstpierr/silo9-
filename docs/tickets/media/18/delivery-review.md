# Revue finale de livraison — ticket 18

**PASS borné au contenu de livraison examiné, après deux corrections du parent. Aucun défaut bloquant restant trouvé. Les archives finales ne sont pas encore créées et n'ont pas été vérifiées.**

Worktree : `.worktrees/silo9-issue-18`, branche `feat/issue-18-world-persistence`, HEAD `c105da61b2b490546f01c9d67703bfb405a2a44f`, base `28e402821469655598c6a84bc415d8ea04da97c2`. La production commitée est inchangée ; la publication est stagée. Cette revue ne constitue ni un commit ni une validation d'archives futures.

## Portée et méthode

Les hunks ajoutés/modifiés des exécutables de production/tests, des outils publiés et des documents éditoriaux ont été lus. Les exécutables de preuve nouveaux ont été inspectés ; les copies identiques aux versions déjà lues lors de la revue d'outillage ont été recoupées par SHA, et leurs deltas ont été lus. Les gros rapports JSON et journaux bruts ont été contrôlés par leurs empreintes, les observations pertinentes et les validateurs, sans les traiter comme du code à reformater.

Les rapports indépendants code, art, performance, rechargements et binaire ont été lus avec leurs limites. Les images n'ont pas été rouvertes dans cette passe : leurs octets publiés correspondent aux fichiers couverts par les revues visuelles indépendantes. Aucun moteur, capture, profil, export ou descendant n'a été lancé.

Les inventaires et contrôles reproductibles sont dans `delivery-review/` : `read-inventory.json`, `integrity-initial.json`, `source-and-tools-integrity.json`, `published-artifact-audit.json`, `package-guards.json` et `final-review-identities.json`.

## Intégrité et vérifications

- **387 artefacts, 87 755 828 octets** : taille/SHA vérifiés contre `docs/tickets/media/18/SHA256.json`, puis comparaison byte-for-byte avec les originaux du dossier de tâche. Les 395 blobs stagés examinés correspondaient aux fichiers. Manifeste relu une seconde fois en clôture ; aucun écart.
- **Onze fichiers gameplay/tests** : SHA identiques au gel `implementation/frozen-sources.json`, aux fichiers présents et aux blobs du commit `c105da6`. La publication n'altère pas la production exécutée. Un second contrôle indépendant compare aussi les 154 fichiers gameplay/assets/scènes/données/config du manifeste parent aux octets du commit : tous identiques (`gameplay-identity-recheck.json`).
- **Outils de campagne** : les trois copies archivées et le runner gardent les SHA du gel. Le probe et wrapper publiés sont identiques. Le seul delta du selfcheck publié est `TemporaryDirectory()` à la place du dossier sibling propre au workspace ; le diff exact est dans `published-selfcheck.diff`. Le probe du profil diffère uniquement par son marqueur d'entrée, sans recyclage de ses timings dans les paires.
- **40 selfchecks publiés relancés : OK**. Exécution avec bytecode désactivé et répertoire temporaire propre à cette revue ; journal `published-selfchecks.log`. Le rouge de publication archivé est bien l'échec de chemin temporaire, puis le vert comporte 40 tests. Il ne s'agit pas d'un nouveau rouge gameplay.
- **Deux parcours source revalidés depuis les vrais artefacts publiés** : validateurs et vérifications PNG/save passent, fins MÈRE et N-7, distances 525,484 m et 524,672 m. Nouveaux acteurs, F5/F9, douille active puis absente et second ARC sont contrôlés. La sortie 143 du superviseur extérieur reste conservée, distincte des deux enfants et de la vidéo terminés à 0.
- **Vingt runs revalidés**, y compris par la fonction de l'audit indépendant : 7 666 intervalles, 7 686 frames, sans erreur. Le recalcul Low donne +1,810 ms et +4,3935 % en médiane appariée. `performance-decision.md` accepte explicitement ce coût. Aucun gain n'est revendiqué ; Normal et p95/p99 restent non concluants.
- **Vingt rechargements et huit contre-exemples revalidés** depuis les mesures réelles. Les identités de meshes/matériaux et le budget ciblé restent stables. La hausse de mémoire totale n'est ni effacée ni attribuée sans preuve.
- **Binaire Linux présent** : SHA recalculé égal au fichier testé. Le reçu contient un code processus 0 et seize codes d'entrée 0. La revue indépendante couvre douze PNG ; sa portée reste démarrage/déplacement/lampe/scan/sauvegarde/chargement/menus, sans mission complète dans le binaire. Windows reste exporté seulement.
- **46 liens locaux** de README, VALIDATION et ticket18 résolvent. `git diff --cached --check` passe. `docs/.gdignore` reste présent.

## Constats corrigés pendant la revue

1. La synthèse attribuait deux références ObjectDB à chaque supplément visuel. Les journaux montrent cet avertissement seulement en Normal. Le parent a corrigé et restagé « dont deux à la fermeture du supplément Normal ». Le rapport artistique et les logs bruts restent exacts et inchangés.
2. Le script historique `native_package_smoke_verified.py` n'exige pas lui-même un code processus final nul ; son code shell seul ne suffit donc pas comme gate. Son exécution archivée est pourtant à 0, avec seize entrées à 0. Le script historique reste conservé tel qu'exécuté. Le parent a renforcé `verify_packages.py` : code processus de type int égal à 0 et exactement seize événements avec codes int égaux à 0 exigés avant `linux_binary_matches_tested`. Les deux gardes finales ont été relues ; cas valide accepté et cinq mutants rejetés, sans lire ni créer d'archive.

`publish_selection.py` a été lu : sélection bornée, exclusion userdata/config/cache et conservation des originaux. L'inventaire publié actuel ne contient aucun fichier hors manifeste, hormis le manifeste lui-même. `verify_packages.py` vérifie les blobs du futur ZIP source contre HEAD, le futur binaire Linux contre celui testé, le contenu Windows contre l'export présent et les documents finaux dans les deux paquets. Ces chemins ont été inspectés statiquement, pas exécutés avant existence des archives.

## Deslop et no-comments

Passe appliquée au diff, sans modification de fichiers par le relecteur. Tous les hunks changés du périmètre exécutable/éditorial ont été lus ; aucune suppression de code ou de commentaire n'était nécessaire pour rendre le comportement plus simple ou plus sûr.

| Catégorie | Périmètre | Suppressions | Décision |
| --- | --- | ---: | --- |
| Code et tests | Six fichiers gameplay, cinq tests, trois outils publiés | 0 | Invariants, migration historique et contre-exemples comportementaux justifiés ; aucune abstraction spéculative ou compatibilité morte identifiée. |
| Commentaires | Fixtures UTF-8, captures, marqueur de tir, précision Vector3 | 0 | Raisons non évidentes cohérentes avec le code et la preuve ; aucun contournement masqué retenu. |
| Archives de preuve | Scripts/rapports historiques | 0 | Conserver leur identité et leurs limites, y compris anciens échecs et chemins du workspace. Ils ne sont pas présentés comme outils portables sans adaptation. |
| Éditorial | Synthèse ticket18 | 0 | Correction factuelle ObjectDB réalisée par le parent et vérifiée ; README restagé avec sa ponctuation corrigée. |

La précision finale sur les anciennes versions refusant le schéma 4 a été relue ; elle correspond à la borne de schéma 2/3 de la base, sans nouvelle prétention runtime.

Aucune licence, directive de sécurité ou contrainte d'outil protégée supprimée. Aucune suppression non testée ; aucune ligne incertaine proposée pour suppression. Les 40 selfchecks ont été relancés après la passe.

Les **treize exceptions whitespace** visent exactement les chemins consignés dans `raw-evidence-whitespace.json`, tous logs ou diffs bruts. Leurs octets correspondent aux originaux ; aucune source gameplay/test n'est exemptée. `linguist-generated` borne le marquage à media18 et ne supprime aucun contenu.

## Limites conservées et prochaine étape

Les six images terminales originales de sentinelle restent occultées ; les huit vues complémentaires prouvent la silhouette reconstruite, sans inventer une nouvelle marche ni une comparaison visuelle originale devenue valable. La revue artistique ouvre 44 images au total, sans visionnage continu du film. Avertissements ObjectDB/V-Sync, diagnostics exclus et paire interrompue restent identifiables. Aucun résultat Windows, GPU joueur, audio matériel ou gain de FPS n'est déduit de llvmpipe.

Le parent peut intégrer cette revue, régénérer le manifeste publié, puis créer et vérifier les archives finales contre le commit de livraison. Leur existence, contenu et intégrité ne sont pas couverts par ce PASS. Les SHA de clôture de la publication et des adaptations sont dans `delivery-review/final-review-identities.json` ; une modification ultérieure doit être contrôlée sur son delta.

Libération : seuls `issue18/delivery-review.md` et `issue18/delivery-review/` ont été écrits par ce relecteur. Aucun index, fichier du worktree ou état Git modifié. Aucun worktree créé ; branche et worktree conservés et relâchés. Aucun processus persistant détenu.
