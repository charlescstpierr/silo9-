# Film Movie Maker detection

Parent red reviewed: `../../render-final/parent-film-red/reproduction.json` and `godot.log`. Actual engine Movie Maker reports 30 FPS, but `OS.get_cmdline_args()` does not expose its consumed switches, so both guards falsely fail.

Versioned API checked before editing: `https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/doc/classes/Engine.xml`; local `issue06/api/Engine.xml` SHA-256 `8a4205ff0f3d4a6d3ba10c94c10472418d1e1abe3c0a6aa44b7106cb1f0f1936` matches its provenance manifest. Lines 203–207 specify `Engine.get_write_movie_path()` returns an empty string when Movie Maker is inactive.

The new copy replaces only the consumed-argument checks with a nonempty movie-path check. No other checks, quotas, scene behavior or proof framing changed. `probe_materials_frontal.gd` and the original probe remain untouched.

This guard establishes Movie Maker activation; it does **not** establish 30 FPS, output existence, complete encoding, or playback correctness. The parent launcher must pass `--fixed-fps 30`, preserve that invocation, and independently check the completed movie's actual cadence with ffprobe. No undocumented native FPS property or timing-derived guess was added.

Static verification: original hash matched, API hash matched, exact single replacement, preserved original bytes after write. No Godot or ffmpeg process launched; no production edit, commit or descendant. Negative no-movie and positive 30 FPS replay remain for parent. File released.

New SHA-256: `44ad5e220bfb29672a6e8e3a7683278316c62a1d3ed85758e0a71b708d4b9570`.
