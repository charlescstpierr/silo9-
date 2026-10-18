class_name SiloPlayerAudio
extends RefCounted

static func synthesize(kind: String) -> AudioStreamWAV:
	var duration: float = 0.28 if kind != "scan" else 0.65
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
