class_name Sfx
extends RefCounted
## Reproducción de sonidos. Cada sonido es audio/<nombre> en WAV, OGG o MP3, así que
## para cambiar uno basta con reemplazar el archivo por otro con el mismo nombre.

const FORMATOS: Array[String] = ["wav", "ogg", "mp3"]

static var _cache: Dictionary[String, AudioStream] = {}


static func _flujo(nombre: String) -> AudioStream:
	if not _cache.has(nombre):
		_cache[nombre] = null
		for ext: String in FORMATOS:
			var ruta: String = "res://audio/%s.%s" % [nombre, ext]
			if ResourceLoader.exists(ruta):
				_cache[nombre] = load(ruta) as AudioStream
				break
	return _cache[nombre]


## Sonido con posición en el mundo: se oye más o menos según la distancia.
static func en(padre: Node, nombre: String, pos: Vector3, volumen_db: float = 0.0, rango: float = 30.0) -> void:
	var flujo: AudioStream = _flujo(nombre)
	if flujo == null or not padre.is_inside_tree():
		return
	var p := AudioStreamPlayer3D.new()
	p.stream = flujo
	p.volume_db = volumen_db
	p.max_distance = rango
	p.unit_size = 6.0
	p.pitch_scale = randf_range(0.93, 1.07)
	p.finished.connect(p.queue_free)
	padre.add_child(p)
	p.global_position = pos
	p.play()


## Sonido plano, sin posición: interfaz y lo que oye el propio jugador.
static func plano(padre: Node, nombre: String, volumen_db: float = 0.0) -> void:
	var flujo: AudioStream = _flujo(nombre)
	if flujo == null or not padre.is_inside_tree():
		return
	var p := AudioStreamPlayer.new()
	p.stream = flujo
	p.volume_db = volumen_db
	p.pitch_scale = randf_range(0.97, 1.03)
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	p.finished.connect(p.queue_free)
	padre.add_child(p)
	p.play()


## Sonido en bucle (alarma, ambiente). Devuelve el reproductor para poder detenerlo.
static func bucle(padre: Node, nombre: String, volumen_db: float = 0.0) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	var original: AudioStream = _flujo(nombre)
	if original != null:
		var flujo := original.duplicate() as AudioStream
		if flujo is AudioStreamWAV:
			var wav := flujo as AudioStreamWAV
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = int(wav.get_length() * wav.mix_rate)
		else:
			flujo.set("loop", true)   # OGG y MP3 usan esta propiedad.
		p.stream = flujo
	p.volume_db = volumen_db
	padre.add_child(p)
	p.play()
	return p
