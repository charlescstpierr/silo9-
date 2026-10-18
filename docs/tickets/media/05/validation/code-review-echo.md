# Revue parent du correctif de répétition clavier

Révision 15d2b91a13a393b212236d195bda75a23cdc0a45. Le parent n’a écrit aucune source de jeu. Delta lu contre c68212d, deux appels is_action_pressed acceptent désormais echo pour weapon1 et weapon2 seulement. Le contrôleur, le tir, le rechargement, le scanner et les modalités restent inchangés.

La trace native sur c68212d a enregistré quatre frappes finales « 1 » classées echo sur huit séquences, après relâchement. Elles étaient ignorées et la destination restait ARC. Le test exact conservé dans echo-red-test.gd a été relancé par le parent avant correction; deux échecs métier, aucun défaut technique. echo-tests-gate.json lie la preuve au commit tests-only4114198, production c68212d inchangée.

La commande répétée reste une demande manuelle de sélection. Répéter la même destination ne redémarre pas la descente; demander une autre arme garde la priorité manuelle existante. Aucun état clavier parallèle ni mise en mémoire différée ajouté. La référence officielle Godot4.7.2 InputEvent.xml confirme la sémantique allow_echo.

Aucun commentaire ajouté ou modifié. Aucun problème supplémentaire identifié dans ces deux lignes. Le test du builder donne quatre assertions passantes; le parcours natif final et la suite complète parent sont encore en cours. La revue indépendante code-review-final.md reste applicable au code modal inchangé et ses limites sont conservées. Verdict du delta statique PASS; livraison complète non encore acquise.
