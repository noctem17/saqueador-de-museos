class_name Sfx
extends RefCounted
## Reproducción de sonidos. Cada sonido es audio/<nombre>.wav, así que para cambiar
## uno basta con reemplazar el archivo por otro con el mismo nombre.

static var _cache: Dictionary[String, AudioStream] = {}


static func _flujo(nombre: String) -> AudioStream:
	if not _cache.has(nombre):
		var ruta: String = "res://audio/%s.wav" % nombre
		_cache[nombre] = load(ruta) as AudioStream if ResourceLoader.exists(ruta) else null
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
	var original := _flujo(nombre) as AudioStreamWAV
	var p := AudioStreamPlayer.new()
	if original != null:
		var flujo := original.duplicate() as AudioStreamWAV
		flujo.loop_mode = AudioStreamWAV.LOOP_FORWARD
		flujo.loop_begin = 0
		flujo.loop_end = int(flujo.get_length() * flujo.mix_rate)
		p.stream = flujo
	p.volume_db = volumen_db
	padre.add_child(p)
	p.play()
	return p
