# Décision sur le coût du ticket 12

La campagne est valide. En qualité normale, le p50 médian passe de 81,805 à 83,699 ms, soit un surcoût de 1,894 ms et 2,32 %. Le p95 passe de 99,678 à 106,725 ms, soit 7,047 ms et 7,07 %. Les cinq différences appariées sont positives. Le verdict de régression du reviewer est conservé. Low ne montre pas de différence établie sur le temps médian.

Le coordinateur accepte explicitement ce coût borné pour les deux nouveaux circuits, leurs commandes, sas et ventilateurs. Aucun seuil de FPS joueur n'est déclaré atteint. La demande privilégie la performance sans interdire tout coût d'une nouvelle mécanique ; la PR donne les mesures et leur portée locale sur llvmpipe. Cette décision ne transforme pas le surcoût en gain.

Une économie a été intégrée avant gel : les surfaces non émissives sont regroupées par matériau et bucket, sans séparation inutile par circuit. Aucun gain numérique n'est revendiqué pour cette correction, car cette version intermédiaire n'a pas été comparée.

Le contre-factuel jetable retire exactement 14 petits émetteurs d'ombre et conserve les boîtiers et sas. Son unique essai, source inchangée, réalise le parcours sans erreur. Il donne un p50 de 85,820 ms et un p95 de 108,055 ms. Un seul essai n'établit pas un effet statistique ; il n'apporte ici aucun signal de gain justifiant une adoption. La variante n'est pas intégrée et reste exclue des 20 runs de la campagne.

Regrouper quatre petites paires de montants pourrait retirer quatre instances de rendu. Cette piste n'a pas été expérimentée et aucun gain n'est revendiqué. Le candidat atteint 298 appels de dessin au maximum sur le parcours, contre 259 à 263 avant, et 603 nœuds contre 541. Les tests de bascules répétées ne montrent pas de croissance. Le profil identifie le rendu logiciel comme coût CPU dominant, sans établir une méthode GDScript causale.

La PR est livrée pour revue avec cette limite connue. Elle ne certifie ni Windows ni un GPU cible et n'autorise aucun merge. Les futurs travaux d'éclairage du ticket 9 restent distincts ; aucune compensation future n'est promise avant mesure.
