# Mesure prévue

Mesurer le changement d’intervalle de rendu du parcours complet ADS en comparant la base 98f2d4a au commit final du ticket 8. Cinq paires à ordre alterné sous Linux, X11, OpenGL Compatibility et llvmpipe. Le résultat ne validera pas des FPS sur GPU joueur. Les deux versions possèdent déjà la même visée et le même FOV ; la réserve générique du runner sur un changement de grossissement ne s’applique pas ici, ce qui sera vérifié dans les données.

Le script chronomètre les intervalles des frames pendant déplacements, visée, huit tirs, R et B. Il exige huit impacts et 246 dégâts ainsi que les transferts de ressources. Import, captures de chauffe, film et profilage restent hors mesures. Les temps englobent rendu, ordonnanceur et VSync. Les deux versions tournent depuis les sources avec le même moteur, pas comme exports release. Le profil séparé échantillonne le CPU par thread pour identifier le coût dominant.
