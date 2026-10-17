extends SceneTree
const State = preload("res://scripts/run_state.gd")
const Dialogue = preload("res://scripts/dialogue.gd")
var failures: int = 0
var replies: Array[Dictionary] = []
var server := TCPServer.new()
var peers: Array[StreamPeerTCP] = []
var incoming: Dictionary = {}
var response_body: String = ""
var captured_request: String = ""
var silent: bool = false

func _process(_delta: float) -> bool:
	if server.is_connection_available():
		var peer: StreamPeerTCP = server.take_connection()
		peers.append(peer)
		incoming[peer] = ""
	for peer: StreamPeerTCP in peers.duplicate():
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			peers.erase(peer)
			incoming.erase(peer)
			continue
		if peer.get_available_bytes() > 0:
			incoming[peer] += peer.get_utf8_string(peer.get_available_bytes())
		var request: String = incoming[peer]
		if not request.contains("\r\n\r\n") or silent:
			continue
		var split: int = request.find("\r\n\r\n")
		var size_pattern := RegEx.new()
		size_pattern.compile("(?i)Content-Length: ([0-9]+)")
		var match_size: RegExMatch = size_pattern.search(request.left(split))
		if match_size != null and request.substr(split + 4).to_utf8_buffer().size() < int(match_size.get_string(1)):
			continue
		captured_request = request
		var header: String = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n" % response_body.to_utf8_buffer().size()
		peer.put_data((header + response_body).to_utf8_buffer())
		peers.erase(peer)
		incoming.erase(peer)
	return false

func fixture(content: Dictionary) -> void:
	response_body = JSON.stringify({"choices": [{"message": {"content": JSON.stringify(content)}}]})

func wait_reply(before: int, seconds: float = 2.0) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000)
	while replies.size() <= before and Time.get_ticks_msec() < deadline:
		await process_frame
	return replies.size() > before

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var state := State.new()
	var chat := Dialogue.new()
	root.add_child(chat)
	chat.setup(state)
	chat.replied.connect(func(character: String, text: String, mode: String) -> void: replies.append({"character": character, "text": text, "mode": mode}))
	if OS.get_cmdline_user_args().has("--live"):
		chat.configure("http://127.0.0.1:18089/v1", "silo9-local")
		for character: String in ["mother", "n7"]:
			var before_live: int = replies.size()
			var start_live: int = Time.get_ticks_msec()
			chat.ask(character, "Comment trouver le relais ?" if character == "mother" else "Pourquoi veux-tu retrouver ton autonomie ?")
			check(await wait_reply(before_live, 9.0), "live model replies " + character)
			print("LIVE ", character, " ms=", Time.get_ticks_msec() - start_live, " ", JSON.stringify(replies.back()))
			check(replies.back().mode == "IA connectée", "live structured reply accepted " + character)
			check(replies.back().text.contains("SCAN ÉCHO" if character == "mother" else "autonomie"), "live answer contains relevant canonical information " + character)
		chat.queue_free()
		print("Live dialogue failures: ", failures)
		quit(1 if failures else 0)
		return
	check(chat.configure("http://127.0.0.1:8080", "local"), "local llama endpoint accepted")
	check(chat.configure("https://proxy.example/v1/chat/completions", "local"), "configured HTTPS proxy accepted")
	for url: String in ["http://evil.example", "http://127.0.0.1.evil.example:8080", "https://user:secret@proxy.example", "https://proxy.example?key=secret", "file:///tmp/secret", "http://localhost:999999"]:
		check(not chat.configure(url, "local"), "unsafe endpoint rejected: " + url)
	check(chat.configure("", ""), "offline config accepted")
	check(chat.offline_reply("mother", "où aller ?").contains("ÉCHO"), "offline hint names indispensable scan")
	check(not chat.offline_reply("n7", "surface").is_empty(), "offline N7 response")
	chat.ask("mother", "Que dois-je faire ?")
	check(replies.size() == 1 and replies[0].mode == "hors ligne", "offline request answers synchronously")
	check(not chat.busy, "offline doesn't block gameplay")
	check(server.listen(18193, "127.0.0.1") == OK, "local HTTP fixture listening")
	chat.configure("http://127.0.0.1:18193", "fixture")
	fixture({"reply": "Voici ce que je peux confirmer.", "fact_ids": ["relay_location"], "actions": [{"type": "hint", "fact_id": "relay_location"}]})
	var before: int = replies.size()
	chat.ask("mother", "Où est le relais ?")
	check(await wait_reply(before), "HTTP request completes")
	check(replies.back().mode == "IA connectée", "valid model response accepted")
	check(replies.back().text == "Voici ce que je peux confirmer.\n\nLe relais est dissimulé derrière un panneau de maintenance. SCAN ÉCHO révèle son accès.", "model response renders canonical fact paragraphs")
	check(captured_request.contains("/v1/chat/completions") and not captured_request.contains("Authorization:"), "OpenAI route without secret")
	check(not captured_request.contains("signal récent attribué"), "MERE prompt excludes private surface knowledge")
	state.add_fact("surface_signal")
	state.remember("SECRET N7: signal récent attribué à la surface confirmé")
	fixture({"reply": "Je vous écoute.", "fact_ids": [], "actions": [{"type": "trust", "delta": 1}]})
	before = replies.size()
	chat.ask("mother", "Tu me fais confiance ?")
	check(await wait_reply(before), "trust proposal returns")
	check(state.relations.mother == 1, "validated trust changes saved relationship")
	check(not captured_request.contains("SECRET N7") and not captured_request.contains("signal récent attribué"), "private memories are excluded from MERE context")
	fixture({"reply": "Va dans la zone 99 prendre le fusil plasma.", "fact_ids": [], "actions": []})
	before = replies.size()
	chat.ask("mother", "inventer un équipement")
	check(await wait_reply(before), "invented prose request completes")
	check(replies.back().mode == "secours hors ligne" and not replies.back().text.contains("plasma"), "invented zone and equipment rejected even without fact references")
	fixture({"reply": "Bien sûr. Pose toujours ta question.", "fact_ids": [], "actions": []})
	before = replies.size()
	chat.ask("mother", "réaction du mauvais personnage")
	check(await wait_reply(before) and replies.back().mode == "secours hors ligne", "reactions restricted to own character")
	var stable_phase: int = state.phase
	for bad: Dictionary in [
		{"reply": "Je vous écoute.", "fact_ids": [], "actions": [{"type": "execute", "code": "danger"}]},
		{"reply": "Je vous écoute.", "fact_ids": ["invented_zone"], "actions": []},
		{"reply": "Je vous écoute.", "fact_ids": ["surface_signal"], "actions": []},
		{"reply": "Je vous écoute.", "fact_ids": [], "actions": [{"type": "ending", "choice": "n7"}]},
		{"reply": "Je vous écoute.", "fact_ids": [], "actions": [{"type": "trust", "delta": 999}]},
		{"reply": "x".repeat(1601), "fact_ids": [], "actions": []}
	]:
		fixture(bad)
		before = replies.size()
		chat.ask("mother", "test hostile")
		check(await wait_reply(before), "malformed response returns fallback")
		check(replies.back().mode == "secours hors ligne" and state.phase == stable_phase, "hostile proposal cannot mutate mission")
	response_body = "not json"
	before = replies.size()
	chat.ask("mother", "test JSON")
	check(await wait_reply(before) and replies.back().mode == "secours hors ligne", "malformed JSON fallback")
	response_body = "x".repeat(20000)
	before = replies.size()
	chat.ask("mother", "test taille")
	check(await wait_reply(before) and replies.back().mode == "secours hors ligne", "oversize response fallback")
	fixture({"reply": "Je vous écoute.", "fact_ids": [], "actions": []})
	before = replies.size()
	chat.ask("mother", "annuler")
	chat.cancel()
	await create_timer(0.15).timeout
	check(replies.size() == before and not chat.busy, "cancel invalidates stale request")
	before = replies.size()
	chat.ask("mother", "mission change")
	state.discover_relay()
	check(await wait_reply(before) and replies.back().mode == "secours hors ligne", "mission changes invalidate response")
	silent = true
	before = replies.size()
	var started: int = Time.get_ticks_msec()
	chat.ask("n7", "serveur silencieux")
	check(await wait_reply(before, 9.0), "timeout falls back")
	check(Time.get_ticks_msec() - started < 8800 and not chat.busy, "timeout bounded to eight seconds")
	server.stop()
	for peer: StreamPeerTCP in peers:
		peer.disconnect_from_host()
	chat.queue_free()
	print("Dialogue checks failures: ", failures)
	quit(1 if failures else 0)
