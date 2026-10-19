# Décision de coût pour le ticket 18

Le parent conserve les six carcasses et les panneaux de caisse avec le budget prévu de dix-neuf instances statiques, six meshes robot et trois matériaux partagés. Les traces n'ajoutent ni physique, ni IA, ni timer, ni traitement par frame. Leur sauvegarde ajoute des états et des poses, sans sérialiser les effets temporaires.

L'audit des cinq paires Low relève un surcoût p50 dans chaque paire. La médiane des différences appariées vaut +1,810 ms, soit +4,39 % dans cette campagne locale. Les différences vont de +1,420 à +2,799 ms. Ce surcoût est accepté pour rendre les actions du joueur visibles après revisite et chargement. Cette décision ne revendique aucun gain de vitesse.

Le budget mémoire ciblé est vérifié après vingt rechargements mesurés. Les meshes et matériaux restent partagés, les dix-neuf instances sont stables et le compteur de ressources reste à 105. La mémoire statique globale augmente pendant la collecte du rapport ; son attribution reste inconnue et le rapport la conserve.

La mesure porte sur le projet source instrumenté, sous Linux avec llvmpipe, à fenêtre 1280 × 720 et avec la lampe allumée. En Low, la résolution 3D est réduite à 67 % par axe. Les ennemis sont neutralisés pendant la préparation. Le profil CPU séparé décrit le limiteur global de cet hôte ; il ne mesure pas isolément chaque carcasse et n'attribue pas précisément le delta à un composant. Aucun coût Windows, GPU joueur ou objectif 60 FPS n'est certifié.

La référence fait disparaître les robots neutralisés ; le candidat rend leurs traces. Le comparatif mesure donc le coût de cette fonctionnalité visible. La preuve complète et les résultats Normal, p95 et p99 restent dans perf-review.md et perf-summary.json.
