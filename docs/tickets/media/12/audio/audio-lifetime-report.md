# Durée de vie audio après destruction du monde

Source et tests gelés, aucun correctif. `production-hashes.json` reste identique. Reproduction uniquement headless dans `probe_audio_lifetime.gd`.

Trois runs à un seul monde coupent les deux circuits, rétablissent Maintenance, détruisent monde et joueur, attendent une frame puis quittent. Ils reproduisent respectivement 7, 4 et 7 avertissements ObjectDB, tous AudioStreamPlaybackWAV/AudioStreamWAV. Logs `audio-immediate-0.log` à `audio-immediate-2.log`, commandes dans `audio-immediate-checks.json`, exit0.

Un run reconstruit et détruit huit mondes. Après chaque destruction et deux frames, jusqu'à deux playbacks et trois streams suivis par références faibles subsistent. À250ms puis750ms, les références suivies sont toutes libérées à chacun des huit cycles. Les compteurs après drainage restent stables : un nœud racine, zéro nœud orphelin, 35 ressources et1633 objets après soustraction des WeakRef ajoutées par la probe. Les objets du premier chargement augmentent par rapport au démarrage1526, puis restent stables entre reconstructions. Au dernier contrôle après1s,1631objets ; aucun avertissement final. Log `audio-lifetime-drained.log`, commande dans `audio-lifetime-checks.json`, exit0.

La reproduction établit des références audio retenues temporairement après queue_free et libérées pendant les250ms suivants. Elle appuie l'explication par drainage audio différé lors de l'arrêt immédiat. Elle ne montre aucune accumulation persistante sur ces huit reconstructions ; elle n'établit pas l'absence de toute fuite possible ni le mécanisme interne exact du moteur. Aucun patch de production proposé ou appliqué. Tous les processus lancés sont terminés.
