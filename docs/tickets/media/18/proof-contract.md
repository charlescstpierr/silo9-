# Compléments retenus au plan de preuve18

Le parent a lu proof-plan.md en entier. Réutiliser les trois outils existants dans une copie de tâche figée avant campagnes, en conservant leurs modes historiques. Pas de nouveau framework de preuves.

Corrections du plan :
- Les trois objets primaires sont caisse, sentinel_1 et verrou ARC, conformément au contrat produit. La porte du cœur est un invariant voisin obligatoire, pas un remplacement du verrou dans les trois états suivis.
- Un seul auteur possède probe, wrapper et selfchecks, car leur schéma JSON est couplé. Écriture uniquement dans issue18/proof-tools ; aucune mutation des outils suivis tant que builder et campagnes ne sont pas terminés.
- Pour la préparation PERF seulement, les six robots peuvent recevoir receive_hit réel sur leurs vraies instances, IA figée, à leurs positions réelles identiques entre les deux versions. Relever vivant/pose avant et défaite/collision après. Cela exerce le chemin de mort de production ; ne pas injecter mark_defeated ni supprimer pour simuler une victoire. Cette préparation est une fixture hors mesure, pas une preuve de tir ni de marche.
- La caisse PERF reçoit un vrai Player.fire balistique depuis une pose contrôlée, avec munition et impact vérifiés sur référence/candidat. La référence n'a pas de receive_hit sur la caisse ; elle doit rester intacte après l'impact. Cette différence visuelle est le coût mesuré.
- Le parcours PERSISTANCE, distinct du perf, utilise les vrais tirs et déplacements pour les objets et le robot témoin. La dernière pose vivante vient de la scène et doit différer du spawn. F5/F9 natifs, nouveaux Player/World et effets actifs puis absents. Si le trajet doit être calibré, préserver les diagnostics ratés sans abaisser les critères.
- Capture contrôlée possible dans un run séparé ; ne jamais appeler ses téléports une marche. Le film éventuel et les images ne sont pas des mesures de coût.

Contrat de validation : observations compactes et étapes complètes, IDs exacts, valeurs finies/types stricts, poses liées aux instances et actions observées, demande CLI liée séparément au validateur, chemins de PNG/save contenus dans la sortie et artefacts vérifiés. Les observations ne doivent pas être remplacées par la demande. Les échecs de moteur, rapport, timeout, images, marche, reconstruction ou source font échouer le verdict.

Préserver 24 selfchecks historiques, puis écrire de vrais contre-exemples nouveaux avant l'implémentation du validateur. Le probe ne peut pas encore tourner : le builder possède exclusivement Godot. Tests Python courts autorisés ; aucun profil ou calcul lourd. Après libération builder, demander le diagnostic à l'acteur propriétaire du runtime, puis revue indépendante avant toute campagne de livraison.

Un schéma de preuve n'authentifie pas un producteur arbitraire : son code et ses sources doivent être relus indépendamment. Une fixture synthétique valide n'est jamais une preuve de jeu exécuté.
