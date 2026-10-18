extends CanvasLayer

func _ready() -> void:
	layer = 0
	var screen := ColorRect.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var filter := ShaderMaterial.new()
	filter.shader = preload("res://assets/shaders/edge_smoothing.gdshader")
	screen.material = filter
	add_child(screen)
