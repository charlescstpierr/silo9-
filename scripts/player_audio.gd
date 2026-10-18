class_name SiloPlayerAudio
extends RefCounted

static func synthesize(kind: String) -> AudioStreamWAV:
	var mechanical := kind in ["remove","insert","rack_pull","rack_release","cell_unlock","cell_remove","cell_insert","cell_transfer"]
	var duration: float = .16 if mechanical else (.65 if kind == "scan" else .28)
	var count: int = int(22050.0 * duration)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var random := RandomNumberGenerator.new()
	random.seed = 9027
	for index in count:
		var time := float(index) / 22050.0
		var envelope := pow(1.0 - float(index) / float(count), 3.0)
		var sample: float
		match kind:
			"shot":
				sample = (random.randf_range(-1, 1) * 0.75 + sin(time * 420.0) * 0.25) * envelope
			"arc":
				sample = (sin(time * 2800.0 + sin(time * 80.0) * 8.0) * 0.65 + random.randf_range(-0.3, 0.3)) * envelope
			"scan":
				sample = sin(time * (3200.0 - time * 1800.0)) * sin(minf(time * 30.0, PI * 0.5)) * envelope
			"remove":
				sample = (sin(time*2200)*.25 + random.randf_range(-.5,.5))*envelope*(1.0 if time < .025 else .12)
			"insert":
				sample = (sin(time*900)*.55 + sin(time*3100)*.2 + random.randf_range(-.25,.25))*envelope
			"rack_pull":
				sample = (sin(time*4800+sin(time*140)*3)*.25 + random.randf_range(-.55,.55))*envelope
			"rack_release":
				sample = (sin(time*1700)*.4 + random.randf_range(-.65,.65))*envelope*(1.0 if time < .04 else .08)
			"cell_unlock":
				sample = (sin(time*3600)*.35+random.randf_range(-.3,.3))*envelope
			"cell_remove":
				sample = sin(time*(1800-time*4000))*.6*envelope
			"cell_insert":
				sample = (sin(time*600)*.45+sin(time*2400)*.25)*envelope
			"cell_transfer":
				sample = (sin(time*(2200+time*16000))*.4+sin(time*4400)*.2)*envelope
			"hurt":
				sample = (sin(time * 190.0) + random.randf_range(-0.2, 0.2)) * envelope
			_:
				sample = random.randf_range(-1.0, 1.0) * envelope * (1.0 if time < 0.035 or time > 0.13 and time < 0.17 else 0.05)
		bytes.encode_s16(index * 2, int(clampf(sample, -1, 1) * 22000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = bytes
	return stream
