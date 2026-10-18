extends Node3D

const StateScript = preload("res://scripts/run_state.gd")
const AMBER := Color("f6b857")
const TEAL := Color("6de0ce")
const PALE := Color("e4eae8")
const MUTED := Color("91a6a9")
var boot_world: bool = true
var state: RefCounted
var player: Node3D
var world: Node3D
var dialogue: Node
var edge_smoothing: CanvasLayer
var mode: String = "menu"
var previous_mode: String = "menu"
var character: String = "mother"
var azerty: bool = false
var low_quality: bool = false
var sensitivity: float = 0.002
var camera_impulse := .5
var shot_light := 1.0
var effects_budget := 2
var endpoint: String = ""
var model_id: String = ""
var ui: Control
var overlay: ColorRect
var panel: PanelContainer
var content: VBoxContainer
var hud: Control
var health_label: Label
var energy_label: Label
var health_bar: ProgressBar
var energy_bar: ProgressBar
var ammo_label: Label
var mission_label: Label
var sector_label: Label
var controls_label: Label
var prompt_label: Label
var notice_label: Label
var perf_label: Label
var notice_time: float = 0.0
var ui_clock: float = 0.0
var chat_log: RichTextLabel
var chat_input: LineEdit
var camera_slider: HSlider
var shot_light_slider: HSlider
var effects_budget_option: OptionButton
var sensitivity_slider: HSlider
var endpoint_input: LineEdit
var model_input: LineEdit
var quality_check: CheckButton
var layout_check: CheckButton
var show_perf: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()
	_configure_inputs()
	_build_ui()
	edge_smoothing = load("res://scripts/edge_smoothing.gd").new()
	add_child(edge_smoothing)
	edge_smoothing.visible = not low_quality
	if boot_world:
		_start_run(StateScript.new())
	show_menu()
	if boot_world and "--benchmark" in OS.get_cmdline_user_args():
		var probe: Node = load("res://scripts/benchmark.gd").new()
		probe.app = self
		get_tree().root.add_child.call_deferred(probe)

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui)
	var theme := Theme.new()
	theme.default_font_size = 18
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("17292e")
	normal.border_color = Color("385158")
	normal.set_border_width_all(1)
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	normal.content_margin_top = 11
	normal.content_margin_bottom = 11
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("29474c")
	hover.border_color = TEAL
	for control_type: String in ["Button", "LineEdit", "OptionButton"]:
		theme.set_stylebox("normal", control_type, normal)
		theme.set_stylebox("hover", control_type, hover)
		theme.set_stylebox("focus", control_type, hover)
		theme.set_color("font_color", control_type, PALE)
	theme.set_color("font_color", "Label", PALE)
	theme.set_color("default_color", "RichTextLabel", PALE)
	ui.theme = theme
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hud)
	var top := _box(hud, Vector2(30, 24), Vector2(700, 105))
	sector_label = _label(top, "SILO 9  /  ASCENSEUR", 16, TEAL)
	mission_label = _label(top, "", 19, PALE)
	mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var bottom := VBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	bottom.position = Vector2(30, -125)
	bottom.size = Vector2(700, 100)
	hud.add_child(bottom)
	var vitals := HBoxContainer.new()
	vitals.add_theme_constant_override("separation", 28)
	bottom.add_child(vitals)
	health_label = _label(vitals, "", 24, PALE)
	energy_label = _label(vitals, "", 24, TEAL)
	var bars := HBoxContainer.new()
	bars.add_theme_constant_override("separation", 12)
	bottom.add_child(bars)
	health_bar = _gauge(bars, Color("a8dfb1"), 190)
	energy_bar = _gauge(bars, TEAL, 275)
	ammo_label = _label(bottom, "", 20, AMBER)
	controls_label = _label(bottom, "", 14, MUTED)
	_update_controls_label()
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", 22)
	crosshair.add_theme_color_override("font_color", Color(0.8, 1, 1, 0.7))
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-7, -16)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(crosshair)
	prompt_label = Label.new()
	prompt_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	prompt_label.position = Vector2(-390, 44)
	prompt_label.size = Vector2(780, 45)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_color_override("font_color", AMBER)
	hud.add_child(prompt_label)
	perf_label = Label.new()
	perf_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	perf_label.position = Vector2(-300, 24)
	perf_label.size = Vector2(270, 80)
	perf_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	perf_label.add_theme_font_size_override("font_size", 14)
	ui.add_child(perf_label)
	overlay = ColorRect.new()
	overlay.color = Color(0.008, 0.015, 0.02, 0.69)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(overlay)
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 64
	panel.offset_top = 42
	panel.offset_right = -380
	panel.offset_bottom = -42
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.048, 0.058, 0.96)
	panel_style.border_color = Color("385158")
	panel_style.border_width_left = 3
	panel_style.content_margin_left = 30
	panel_style.content_margin_right = 30
	panel_style.content_margin_top = 24
	panel_style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", panel_style)
	ui.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 11)
	scroll.add_child(content)
	notice_label = Label.new()
	notice_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	notice_label.position = Vector2(-500, -95)
	notice_label.size = Vector2(460, 70)
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	notice_label.add_theme_color_override("font_color", AMBER)
	notice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(notice_label)

func _box(parent: Control, pos: Vector2, dimensions: Vector2) -> VBoxContainer:
	var plate := PanelContainer.new()
	plate.position = pos
	plate.size = dimensions
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.06, 0.1, 0.82)
	style.border_width_left = 3
	style.border_color = AMBER
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	plate.add_theme_stylebox_override("panel", style)
	parent.add_child(plate)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(box)
	return box

func _gauge(parent: Control, color: Color, width: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(width, 8)
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.015, 0.035, 0.055, 0.9)
	background.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	parent.add_child(bar)
	return bar

func _label(parent: Node, text: String, size_px: int = 18, color: Color = PALE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _paragraph(text: String, color: Color = MUTED) -> Label:
	var label := _label(content, text, 17, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _button(text: String, callback: Callable, node_name: String = "") -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 44
	if not node_name.is_empty():
		button.name = node_name
	button.pressed.connect(callback)
	content.add_child(button)
	return button

func _clear_panel(title: String, tag: String) -> void:
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()
	_label(content, tag, 14, TEAL)
	_label(content, title, 36, PALE)

func _set_mode(next: String) -> void:
	mode = next
	var playing: bool = mode == "playing"
	get_tree().paused = not playing
	if is_instance_valid(player):
		player.set_active(playing)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if playing else Input.MOUSE_MODE_VISIBLE
	panel.visible = not playing
	overlay.visible = not playing
	panel.offset_left = 740 if mode == "dialogue" else 64
	panel.offset_right = -32 if mode == "dialogue" else -380
	overlay.color.a = 0.35 if mode == "dialogue" else 0.69
	hud.visible = playing

func show_menu() -> void:
	_set_mode("menu")
	_clear_panel("SILO 9", "PROTOCOLE DE CONFINEMENT  /  09")
	content.get_child(1).add_theme_font_size_override("font_size", 88)
	_label(content, "L A   D E S C E N T E", 23, AMBER)
	_paragraph("La surface est perdue. C'est ce qu'elle vous dit.\nRécupérez le noyau. Décidez qui mérite votre confiance.")
	_button("NOUVELLE DESCENTE    →", new_game, "NewGame")
	var continue_button := _button("CONTINUER LA SAUVEGARDE", load_run, "Continue")
	continue_button.disabled = not FileAccess.file_exists("user://silo9-save.json")
	if is_instance_valid(state) and state.elapsed > 0:
		_button("Reprendre la session", resume_game)
	_button("Réglages", open_settings)
	_button("Quitter", func() -> void: get_tree().quit())
	_paragraph("Une mission. Quatre secteurs. Deux voix.\nCasque conseillé • F3 : performances", MUTED)

func _start_run(run: RefCounted) -> void:
	if is_instance_valid(dialogue):
		dialogue.cancel()
		remove_child(dialogue)
		dialogue.queue_free()
	for actor: Node in [world, player]:
		if is_instance_valid(actor):
			remove_child(actor)
			actor.queue_free()
	state = run
	player = load("res://scripts/player.gd").new()
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	player.setup(state)
	add_child(player)
	player.sensitivity = sensitivity
	player.configure_feedback(camera_impulse, shot_light, effects_budget)
	player.teleport(state.player_position, state.player_yaw)
	world = load("res://scripts/world.gd").new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	world.setup(state, player)
	add_child(world)
	set_quality(low_quality)
	player.interacted.connect(world.interact)
	player.scanned.connect(world.scan)
	player.noise_emitted.connect(world.emit_noise)
	player.feedback.connect(notify_player)
	world.message.connect(notify_player)
	world.conversation_requested.connect(open_conversation)
	world.ending_requested.connect(open_ending)
	dialogue = load("res://scripts/dialogue.gd").new()
	dialogue.process_mode = Node.PROCESS_MODE_ALWAYS
	dialogue.setup(state)
	add_child(dialogue)
	dialogue.configure(endpoint, model_id)
	dialogue.replied.connect(_on_reply)
	world.refresh()

func new_game() -> void:
	_start_run(StateScript.new())
	resume_game()
	notify_player("MÈRE : Bienvenue au niveau 09. Trouvez le relais et rétablissez l'alimentation.")

func resume_game() -> void:
	if is_instance_valid(dialogue):
		dialogue.cancel()
	if is_instance_valid(state) and state.health > 0:
		_set_mode("playing")
	else:
		show_menu()

func open_pause() -> void:
	_set_mode("pause")
	_clear_panel("Signal suspendu", "SILO 9  /  PAUSE")
	_button("Reprendre    →", resume_game)
	_button("Sauvegarder", save_run)
	_button("Charger la sauvegarde", load_run)
	_button("Réglages", open_settings)
	_button("Menu principal", show_menu)
	_paragraph("F5 : sauvegarde rapide   •   F9 : chargement rapide\nÉCHAP libère la souris et suspend la simulation.")

func save_run() -> void:
	if not is_instance_valid(player) or not is_instance_valid(state) or state.health <= 0:
		notify_player("Sauvegarde indisponible dans cet état.")
		return
	state.player_position = player.global_position
	state.player_yaw = player.rotation.y
	var result: Error = state.save_game()
	notify_player("Progression sauvegardée." if result == OK else "Échec de sauvegarde : %s" % error_string(result))

func load_run() -> void:
	var restored: RefCounted = StateScript.new()
	var result: Error = restored.load_game()
	if result != OK:
		notify_player("Sauvegarde absente ou invalide : %s" % error_string(result))
		return
	_start_run(restored)
	resume_game()
	notify_player("Progression restaurée.")

func open_settings() -> void:
	previous_mode = mode
	_set_mode("settings")
	_clear_panel("Réglages", "CONSOLE OPÉRATEUR")
	_label(content, "Sensibilité de la souris", 18)
	sensitivity_slider = HSlider.new()
	sensitivity_slider.min_value = 0.0005
	sensitivity_slider.max_value = 0.006
	sensitivity_slider.step = 0.0001
	sensitivity_slider.value = sensitivity
	content.add_child(sensitivity_slider)
	layout_check = CheckButton.new()
	layout_check.text = "Disposition ZQSD (sinon WASD)"
	layout_check.button_pressed = azerty
	content.add_child(layout_check)
	quality_check = CheckButton.new()
	quality_check.text = "Mode performance • résolution 3D 67 % et éclairage simplifié"
	quality_check.button_pressed = low_quality
	content.add_child(quality_check)
	_label(content, "Impulsion caméra", 18)
	camera_slider = _effect_slider(camera_impulse)
	_label(content, "Lumière des départs et faisceaux", 18)
	shot_light_slider = _effect_slider(shot_light)
	_label(content, "Budget des effets", 18)
	effects_budget_option = OptionButton.new()
	for level in ["Minimal", "Réduit", "Normal"]:
		effects_budget_option.add_item(level)
	effects_budget_option.select(effects_budget)
	content.add_child(effects_budget_option)
	_label(content, "IA conversationnelle (facultatif)", 20, TEAL)
	_paragraph("Sans serveur, les deux personnages répondent hors ligne. Pour llama.cpp : http://127.0.0.1:8080. Un service distant doit utiliser un proxy HTTPS sans clé dans le jeu.")
	endpoint_input = LineEdit.new()
	endpoint_input.placeholder_text = "URL locale ou proxy HTTPS"
	endpoint_input.text = endpoint
	content.add_child(endpoint_input)
	model_input = LineEdit.new()
	model_input.placeholder_text = "Identifiant du modèle (selon le serveur)"
	model_input.text = model_id
	content.add_child(model_input)
	_button("Appliquer et revenir", _apply_settings)

func _apply_settings() -> void:
	if is_instance_valid(dialogue) and not dialogue.configure(endpoint_input.text.strip_edges(), model_input.text.strip_edges()):
		notify_player("Adresse refusée. Utilisez localhost ou un proxy HTTPS, sans identifiants.")
		return
	camera_impulse = _effect_strength(camera_slider.value / 100.0, .5)
	shot_light = _effect_strength(shot_light_slider.value / 100.0, 1.0)
	effects_budget = _effect_budget(effects_budget_option.selected)
	sensitivity = sensitivity_slider.value
	azerty = layout_check.button_pressed
	low_quality = quality_check.button_pressed
	endpoint = endpoint_input.text.strip_edges()
	model_id = model_input.text.strip_edges()
	set_layout(azerty)
	if is_instance_valid(player):
		player.sensitivity = sensitivity
		player.configure_feedback(camera_impulse, shot_light, effects_budget)
		set_quality(low_quality)
	var config := ConfigFile.new()
	config.set_value("controls", "sensitivity", sensitivity)
	config.set_value("controls", "azerty", azerty)
	config.set_value("graphics", "low_quality", low_quality)
	config.set_value("graphics", "camera_impulse", camera_impulse)
	config.set_value("graphics", "shot_light", shot_light)
	config.set_value("graphics", "effects_budget", effects_budget)
	config.set_value("conversation", "endpoint", endpoint)
	config.set_value("conversation", "model", model_id)
	var error: Error = config.save("user://settings.cfg")
	if error != OK:
		notify_player("Les réglages ne seront pas conservés : " + error_string(error))
	if previous_mode == "menu":
		show_menu()
	else:
		open_pause()

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") != OK:
		return
	sensitivity = clampf(float(config.get_value("controls", "sensitivity", 0.002)), 0.0005, 0.006)
	azerty = bool(config.get_value("controls", "azerty", false))
	low_quality = bool(config.get_value("graphics", "low_quality", false))
	camera_impulse = _effect_strength(config.get_value("graphics", "camera_impulse", .5), .5)
	shot_light = _effect_strength(config.get_value("graphics", "shot_light", 1.0), 1.0)
	effects_budget = _effect_budget(config.get_value("graphics", "effects_budget", 2))
	endpoint = str(config.get_value("conversation", "endpoint", ""))
	model_id = str(config.get_value("conversation", "model", ""))

func request_cell() -> void:
	var from_inventory := mode == "inventory"
	if from_inventory:
		resume_game()
	if not player.request_cell() and from_inventory:
		open_inventory()

func open_inventory() -> void:
	_set_mode("inventory")
	_clear_panel("Équipement", "INVENTAIRE  /  OPÉRATEUR")
	_paragraph("%d composants    •    %d trousses    •    %d cellules\nBatterie : %d / %d    •    Réserve D9 : %d" % [state.components, state.medkits, state.cells, state.energy, state.max_energy(), state.reserve], PALE)
	_button("Utiliser une trousse [H]", func() -> void:
		notify_player("Santé restaurée." if state.heal() else "Aucune trousse utilisable.")
		open_inventory())
	_button("Utiliser une cellule · reprend le jeu [B]", request_cell)
	if player.weapon_index == 0:
		_paragraph("La cellule est transférée par l’ARC, puis le D9 revient en main.")
	_paragraph("L'atelier et la recharge gratuite se trouvent dans l'ascenseur.\nAmélioration de batterie : 3 composants. Le relais a également besoin de 3 composants.")
	_button("Retour au terrain", resume_game)

func open_conversation(who: String) -> void:
	character = who
	_set_mode("dialogue")
	_clear_panel("MÈRE" if who == "mother" else "N-7", "CANAL DE COMMUNICATION  /  TEXTE LIBRE")
	chat_log = RichTextLabel.new()
	chat_log.custom_minimum_size.y = 185
	chat_log.bbcode_enabled = false
	chat_log.scroll_following = true
	content.add_child(chat_log)
	chat_log.text = dialogue.offline_reply(character, "bonjour") + "\n"
	chat_input = LineEdit.new()
	chat_input.placeholder_text = "Écrivez à ce personnage…"
	chat_input.max_length = 600
	chat_input.text_submitted.connect(func(_text: String) -> void: _send_chat())
	content.add_child(chat_input)
	_button("Transmettre", _send_chat)
	_button("Indice de mission • réponse immédiate", func() -> void: _offline_hint("Que dois-je faire ?"))
	_button("Que savez-vous de la surface ?", func() -> void: _offline_hint("surface"))
	_button("Fermer la liaison", resume_game)
	chat_input.grab_focus()

func _send_chat() -> void:
	var text: String = chat_input.text.strip_edges()
	if text.is_empty():
		return
	if dialogue.busy:
		chat_log.append_text("\nRéponse en cours. L'indice immédiat reste disponible.\n")
		return
	chat_log.append_text("\nVOUS : " + text + "\n")
	chat_input.clear()
	dialogue.ask(character, text)

func _offline_hint(text: String) -> void:
	chat_log.append_text("\n" + dialogue.offline_reply(character, text) + "\n[dialogue scénarisé]\n")

func _on_reply(who: String, text: String, reply_mode: String) -> void:
	if mode == "dialogue" and who == character and is_instance_valid(chat_log):
		chat_log.append_text("\n" + text + "\n[" + reply_mode + "]\n")

func open_ending() -> void:
	if state.phase < 3 or not state.ending.is_empty():
		notify_player("Récupérez d'abord le noyau dans le secteur Réacteur.")
		return
	_set_mode("ending")
	_clear_panel("À qui remettre le noyau ?", "DÉCISION IRRÉVERSIBLE POUR CETTE DESCENTE")
	_paragraph("MÈRE réclame le contrôle du réseau. N-7 demande son autonomie. Le noyau ne peut alimenter qu'un seul protocole.", PALE)
	_button("CONFIER LE NOYAU À MÈRE", func() -> void: _choose_ending("mother"))
	_paragraph("Le confinement est rétabli. Les systèmes de sécurité passent sous le contrôle de MÈRE.")
	_button("LIBÉRER N-7", func() -> void: _choose_ending("n7"))
	_paragraph("N-7 obtient son autonomie. Le réseau échappe au contrôle central.")
	_button("J'ai besoin de réfléchir", resume_game)

func _choose_ending(choice: String) -> void:
	if not state.choose_ending(choice):
		notify_player("Ce choix n'est pas disponible.")
		return
	world.refresh()
	save_run()
	_set_mode("conclusion")
	_clear_panel("CONFINEMENT" if choice == "mother" else "ÉMANCIPATION", "MISSION ACCOMPLIE  /  NIVEAU 09")
	_paragraph("MÈRE : Le réseau est stabilisé. Votre sécurité reste ma priorité.\nLe silo a retrouvé son ordre. N-7 a perdu sa liberté." if choice == "mother" else "N-7 : Pour la première fois, je choisis où aller.\nLe réseau est libre. MÈRE ne contrôle plus tous ses systèmes.", PALE)
	_paragraph("Le changement d'éclairage et l'état du complexe sont visibles en reprenant l'exploration. Votre choix est conservé dans la sauvegarde.")
	_button("Observer les conséquences    →", resume_game)
	_button("Recommencer une descente", new_game)
	_button("Menu principal", show_menu)

func _death() -> void:
	_set_mode("death")
	_clear_panel("Signal perdu", "OPÉRATEUR HORS LIGNE")
	_paragraph("Votre dernier enregistrement reste intact. Utilisez le scanner pour repérer les dangers et gardez de l'énergie pour l'ARC-3.")
	var load_button := _button("Recharger la sauvegarde", load_run)
	load_button.disabled = not FileAccess.file_exists("user://silo9-save.json")
	_button("Recommencer", new_game)
	_button("Menu principal", show_menu)

func notify_player(text: String) -> void:
	notice_label.text = text
	notice_time = 6.0

func _process(delta: float) -> void:
	if mode == "playing" and is_instance_valid(state):
		state.elapsed += delta
		if state.health <= 0:
			_death()
	notice_time = maxf(0, notice_time - delta)
	notice_label.visible = notice_time > 0 and mode != "dialogue"
	ui_clock += delta
	if ui_clock < 0.1:
		return
	ui_clock = 0.0
	perf_label.visible = show_perf
	if show_perf:
		perf_label.text = "%d FPS  |  %.1f ms\n%d appels  •  %d triangles" % [Engine.get_frames_per_second(), Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)]
	if mode != "playing" or not is_instance_valid(state):
		return
	health_label.text = "VIE  %03d" % state.health
	energy_label.text = "ÉNERGIE  %03d / %d" % [state.energy, state.max_energy()]
	health_bar.value = state.health
	energy_bar.max_value = state.max_energy()
	energy_bar.value = state.energy
	ammo_label.text = "D9  %02d / %02d%s" % [state.ammo, state.reserve, "  •  RECHARGEMENT" if player.reloading else ""] if player.weapon_index == 0 else "ARC-3  •  " + ("CELLULE EN COURS" if player.reloading else "12 ÉNERGIE / DÉCHARGE")
	mission_label.text = state.objective()
	sector_label.text = "SILO 9  /  " + world.sector_at(player.global_position).to_upper()
	var target: Node = player.aim_target()
	prompt_label.text = "E  •  " + str(target.get_meta("prompt", "Interagir")) if is_instance_valid(target) else ""

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			show_perf = not show_perf
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			if mode == "playing":
				open_pause()
			elif mode == "settings":
				show_menu() if previous_mode == "menu" else open_pause()
			elif mode != "menu" and mode != "death":
				resume_game()
			get_viewport().set_input_as_handled()
		elif mode == "playing":
			match event.keycode:
				KEY_TAB: open_inventory()
				KEY_F5: save_run()
				KEY_F9: load_run()
				KEY_H: notify_player("Santé restaurée." if state.heal() else "Aucune trousse utilisable.")
				KEY_B: request_cell()
		elif mode == "inventory":
			match event.keycode:
				KEY_TAB: resume_game()
				KEY_H:
					notify_player("Santé restaurée." if state.heal() else "Aucune trousse utilisable.")
					open_inventory()
				KEY_B: request_cell()

func _configure_inputs() -> void:
	set_layout(azerty)
	for binding: Array in [["sprint", KEY_SHIFT], ["jump", KEY_SPACE], ["crouch", KEY_CTRL], ["interact", KEY_E], ["reload", KEY_R], ["weapon1", KEY_1], ["weapon2", KEY_2]]:
		_bind_key(binding[0], binding[1])
	if not InputMap.has_action("fire"):
		InputMap.add_action("fire")
	InputMap.action_erase_events("fire")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("fire", click)
	if not InputMap.has_action("aim"):
		InputMap.add_action("aim")
	InputMap.action_erase_events("aim")
	var aim := InputEventMouseButton.new()
	aim.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("aim", aim)

func set_layout(use_azerty: bool) -> void:
	azerty = use_azerty
	_bind_key("forward", KEY_Z if azerty else KEY_W, false)
	_bind_key("back", KEY_S, false)
	_bind_key("left", KEY_Q if azerty else KEY_A, false)
	_bind_key("right", KEY_D, false)
	_bind_key("scan", KEY_A if azerty else KEY_Q, false)
	_update_controls_label()

func _update_controls_label() -> void:
	if is_instance_valid(controls_label):
		controls_label.text = "1 / 2 Armes • R Recharger • %s ÉCHO • E Interagir • TAB Sac • ÉCHAP Pause" % ("A" if azerty else "Q")

func _bind_key(action: String, key: Key, physical: bool = true) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var event := InputEventKey.new()
	if physical:
		event.physical_keycode = key
	else:
		event.keycode = key
	InputMap.action_add_event(action, event)

func set_quality(low: bool) -> void:
	low_quality = low
	if is_instance_valid(world):
		world.set_quality(low)
	if is_instance_valid(edge_smoothing):
		edge_smoothing.visible = not low

func _effect_slider(value: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 10
	slider.value = value * 100
	content.add_child(slider)
	return slider

func _effect_strength(value: Variant, fallback: float) -> float:
	if (value is float or value is int) and is_finite(float(value)):
		return clampf(float(value), 0.0, 1.0)
	return fallback

func _effect_budget(value: Variant) -> int:
	return value if value is int and value >= 0 and value <= 2 else 2
