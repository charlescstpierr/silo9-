extends "res://tests/power_fixture.gd"

const Dialogue = preload("res://scripts/dialogue.gd")
var replies: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if not await prepare():
		await finish()
		return
	var chat := Dialogue.new()
	root.add_child(chat)
	chat.setup(state)
	chat.replied.connect(func(_character: String, text: String, mode: String) -> void: replies.append({"text": text, "mode": mode}))
	var mother_on: Variant = state.call("power_summary", "mother")
	var n7_on: Variant = state.call("power_summary", "n7")
	check(not str(mother_on).is_empty() and not str(n7_on).is_empty(), "Both characters receive an electrical summary")
	var offline_on: String = chat.offline_reply("mother", "Quel est l'état des circuits électriques ?")
	command(&"maintenance", false)
	check(state.call("power_summary", "mother") != mother_on, "MERE learns maintenance cut")
	check(state.call("power_summary", "n7") == n7_on, "N7 does not learn maintenance state")
	var offline_off: String = chat.offline_reply("mother", "Quel est l'état des circuits électriques ?")
	check(offline_off != offline_on, "Offline reply reflects current circuit state")
	command(&"archives", false)
	check(state.call("power_summary", "n7") != n7_on, "N7 learns archives cut")
	var n7_offline: String = chat.offline_reply("n7", "Quel est l'état des circuits électriques ?")
	command(&"maintenance", true)
	check(chat.offline_reply("n7", "Quel est l'état des circuits électriques ?") == n7_offline, "Offline N7 response does not leak maintenance")
	command(&"archives", true)
	check(chat.offline_reply("mother", "Quel est l'état des circuits électriques ?") == offline_on, "Offline summary is deterministic after a complete cycle")
	var server := TCPServer.new()
	if not check(server.listen(0, "127.0.0.1") == OK, "Injected HTTP fixture listens on loopback"):
		chat.queue_free()
		await finish()
		return
	chat.configure("http://127.0.0.1:%d" % server.get_local_port(), "injected-power-fixture")
	for stale: bool in [false, true]:
		var before_replies: int = replies.size()
		var before_trust: int = state.relations.mother
		chat.ask("mother", "Quel est l'état des circuits électriques ?")
		var deadline: int = Time.get_ticks_msec() + 2000
		while not server.is_connection_available() and Time.get_ticks_msec() < deadline:
			await process_frame
		if not check(server.is_connection_available(), "Dialogue issues an actual local HTTP request"): break
		var peer: StreamPeerTCP = server.take_connection()
		var request: String = ""
		while Time.get_ticks_msec() < deadline:
			peer.poll()
			if peer.get_available_bytes() > 0: request += peer.get_utf8_string(peer.get_available_bytes())
			if request.contains("\r\n\r\n"):
				var body: Variant = JSON.parse_string(request.get_slice("\r\n\r\n", 1))
				if body is Dictionary: break
			await process_frame
		var payload: Variant = JSON.parse_string(request.get_slice("\r\n\r\n", 1))
		check(payload is Dictionary, "Captured complete real HTTP request")
		if payload is Dictionary:
			var context: String = payload.messages[0].content
			var summary: Variant = state.call("power_summary", "mother")
			check(context.contains(str(summary)) or context.contains(JSON.stringify(summary)), "Online context includes the same filtered electrical summary")
		if stale:
			command(&"maintenance", false)
			command(&"maintenance", true)
		var content := {"reply": "Je vous écoute.", "fact_ids": [], "actions": [{"type": "trust", "delta": 1}]}
		var response: String = JSON.stringify({"choices": [{"message": {"content": JSON.stringify(content)}}]})
		peer.put_data(("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n" % response.to_utf8_buffer().size() + response).to_utf8_buffer())
		deadline = Time.get_ticks_msec() + 2000
		while replies.size() == before_replies and Time.get_ticks_msec() < deadline:
			peer.poll()
			await process_frame
		check(replies.size() == before_replies + 1, "Injected response completes once")
		if replies.size() > before_replies:
			check(replies.back().mode == ("secours hors ligne" if stale else "IA connectée"), "OFF then ON invalidates in-flight response before accepting actions" if stale else "Unchanged electrical context accepts valid response")
		check(state.relations.mother == before_trust + (0 if stale else 1), "Stale response cannot grant trust; valid control can")
		peer.disconnect_from_host()
	server.stop()
	chat.queue_free()
	await finish()
