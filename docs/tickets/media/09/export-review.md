# Vérification des exports

`bash tools/export.sh` a terminé avec code 0 dans le worktree09, source de jeu `653e2a79c7f36e9ac7422335c85cef3b937ed0f9`. Les deux exports embarquent leur PCK. Les documents sont copiés séparément et seront actualisés avant paquetage. Windows est exporté, pas exécuté.

Le binaire Linux a été lancé directement depuis `builds/linux/SILO9.x86_64`, sans éditeur ni sonde GDScript. `native_package_smoke_verified.py` envoie de vrais clics et touches XTest, avec données utilisateur isolées. Il ouvre une nouvelle partie, avance, bascule F, utilise Q, ouvre/reprend la pause, rebascule F, revient au menu et quitte. Sortie moteur 0. Le journal contient uniquement l'avertissement V-Sync non pris en charge par llvmpipe, sans erreur moteur/script. Son empreinte est dans `packaged-native-verified/verification.json`.

Le parent a ouvert les images finales `flashlight-on`, `pause-lamp-on`, `resumed-lamp-on` et `flashlight-off-again`. Elles montrent respectivement LAMPE ON et énergie100; le menu pause; LAMPE ON après reprise et énergie80; l'absence de LAMPE ON et santé93 pendant que la sentinelle approche. La lampe éclaire réellement le sol et le robot. Ce contrôle n'est pas une mission complète ni une mesure de fluidité.

Un premier essai `packaged-native-final` avait également quitté avec code0, mais sa capture nommée flashlight-on montrait encore l'état précédent. Cette image n'a pas été acceptée comme preuve ON. Le second essai conserve le même binaire et attend une seconde après chaque entrée, au lieu de0,35s. Les deux essais sont conservés; seul `packaged-native-verified` sert à la preuve finale. Aucune source de jeu n'a changé.
