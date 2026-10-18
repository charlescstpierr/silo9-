extends "res://tests/test_fps_materials.gd"
func run() -> void:
	var rig := Rig.new()
	root.add_child(rig)
	var reference := {"source_revision": "98f2d4a735d7c2fe1ad6f3d8431ab86772db1e8a", "quantization": "1e-6, expanded triangle order; excludes UV/color/index sharing", "geometry": geometry_snapshot(rig)}
	var file := FileAccess.open("/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.cstack/orchestrate/silo9/issue08/tests-parent-red/reference.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(reference, "\t") + "\n")
	file.close()
	print("CAPTURED ", reference.geometry.size(), " geometry entries")
	rig.free()
	await process_frame
	quit()
