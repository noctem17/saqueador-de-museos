class_name Elihcotero
extends Node3D
## El ELIHCOTERO: Franchesca Marcos transformada en helicóptero.
##
## Fuera de la pelea solo gira las hélices y flota. En la pelea (empezar_pelea)
## vuela de un punto a otro sobre la carretera, siempre con la trompa hacia Polo,
## y le lanza misiles. Con la mitad de la vida se enfurece: dispara más seguido
## y de a dos. Los cohetes de Polo le quitan vida (toca / recibir_cohete).

signal vida_cambio(vida: float, maxima: float)
signal derribado
signal enfurecida
signal misil_lanzado

const ESCALA: float = 1.3          ## El cuerpo del modelo mide unos 6 m; así queda de jefe.
const ALTURA_VUELO: float = 7.5
const VIDA_MAX: float = 100.0
const DANO_COHETE: float = 12.5    ## Ocho cohetes y cae.
const TIEMPO_MISIL: float = 1.8    ## Lo que tarda el misil en caer: lo que hay para esquivar.
## Zonas que reciben los cohetes: [centro relativo al helicóptero, radio].
const ZONAS: Array = [[Vector3(0, 2.0, 1.9), 2.8], [Vector3(0, 2.8, -4.5), 1.6]]

const VELOCIDAD: float = 6.5      ## Calmada; enfurecida va un 35 % más rápido.

var velocidad: float = VELOCIDAD

var giro_helice: float = 0.0       ## Velocidad de las hélices (radianes por segundo).
var flotando: bool = false         ## En el aire, sin pelear, se mece un poco.
var peleando: bool = false
var vida: float = VIDA_MAX
var objetivo: Node3D               ## Polo.
var zona_vuelo: AABB               ## Por dónde puede volar durante la pelea.

var _helices: Array[Node3D] = []   ## [hélice de arriba, hélice de la cola]
var _baliza: OmniLight3D
var _golpe: OmniLight3D            ## Destello cuando le pega un cohete.
var _destino: Vector3
var _vel_actual: Vector3 = Vector3.ZERO
var _prox_misil: float = 3.0
var _furiosa: bool = false


func _ready() -> void:
	add_to_group("blanco_cohete")
	var modelo := (load("res://modelos/franciacoptero.glb") as PackedScene).instantiate() as Node3D
	modelo.scale = Vector3.ONE * ESCALA
	modelo.position.y = 2.19 * ESCALA   # Los patines quedan sobre el piso.
	add_child(modelo)
	for nombre: String in ["Helice", "HeliceCola"]:
		_helices.append(modelo.find_child(nombre, true, false) as Node3D)
	# Reflector bajo la trompa, apuntando adelante y abajo (hacia Polo).
	var reflector := SpotLight3D.new()
	reflector.position = Vector3(0, 0.3, 3.0)
	reflector.rotation_degrees = Vector3(-35, 180, 0)
	reflector.light_color = Color("e8f0ff")
	reflector.light_energy = 6.0
	reflector.spot_range = 30.0
	reflector.spot_angle = 18.0
	add_child(reflector)
	# Luz propia para que se vea contra el cielo negro, y baliza roja que parpadea.
	var relleno := OmniLight3D.new()
	relleno.position = Vector3(0, 1.5, 6.0)
	relleno.light_color = Color("ffd9c2")
	relleno.light_energy = 4.0
	relleno.omni_range = 12.0
	add_child(relleno)
	_baliza = OmniLight3D.new()
	_baliza.position = Vector3(0, 2.4, -1.5)
	_baliza.light_color = Color("ff2a2a")
	_baliza.light_energy = 0.0
	_baliza.omni_range = 6.0
	add_child(_baliza)
	_golpe = OmniLight3D.new()
	_golpe.position = Vector3(0, 2.0, 2.0)
	_golpe.light_color = Color("fff0d0")
	_golpe.light_energy = 0.0
	_golpe.omni_range = 10.0
	add_child(_golpe)


func _process(delta: float) -> void:
	if _helices.size() == 2 and giro_helice > 0.0:
		_helices[0].rotate_y(giro_helice * delta)
		_helices[1].rotate_x(giro_helice * 1.6 * delta)
		_baliza.light_energy = 4.0 if fmod(Time.get_ticks_msec() / 1000.0, 1.0) < 0.12 else 0.0
	_golpe.light_energy = move_toward(_golpe.light_energy, 0.0, delta * 30.0)
	if peleando:
		_volar(delta)
		_atacar(delta)
	elif flotando:
		var s: float = Time.get_ticks_msec() / 1000.0
		position.y = ALTURA_VUELO + sin(s * 1.3) * 0.35
		rotation.z = sin(s * 0.9) * 0.05


func empezar_pelea(polo: Node3D, zona: AABB) -> void:
	objetivo = polo
	zona_vuelo = zona
	flotando = false
	peleando = true
	_prox_misil = 2.5
	_nuevo_destino()


func reiniciar(pos: Vector3) -> void:
	vida = VIDA_MAX
	velocidad = VELOCIDAD
	_furiosa = false
	peleando = false
	flotando = true
	global_position = pos
	rotation = Vector3.ZERO
	_vel_actual = Vector3.ZERO
	vida_cambio.emit(vida, VIDA_MAX)


## ¿Este punto le pega al helicóptero?
func toca(punto: Vector3) -> bool:
	if not peleando:
		return false
	for z: Array in ZONAS:
		if punto.distance_to(global_transform * (z[0] as Vector3)) < (z[1] as float):
			return true
	return false


func recibir_cohete(_punto: Vector3) -> void:
	vida = maxf(vida - DANO_COHETE, 0.0)
	_golpe.light_energy = 12.0
	# Se sacude con el golpe.
	rotation.z += randf_range(-0.25, 0.25)
	rotation.x += 0.15
	vida_cambio.emit(vida, VIDA_MAX)
	if not _furiosa and vida <= VIDA_MAX * 0.5:
		_furiosa = true
		velocidad *= 1.35
		enfurecida.emit()
	if vida <= 0.0:
		peleando = false
		derribado.emit()


func _volar(delta: float) -> void:
	var hacia: Vector3 = _destino - global_position
	if hacia.length() < 1.5:
		_nuevo_destino()
	_vel_actual = _vel_actual.lerp(hacia.normalized() * velocidad, delta * 1.4)
	global_position += _vel_actual * delta
	# La trompa siempre hacia Polo (la trompa del modelo mira a +Z).
	var a: Vector3 = objetivo.global_position - global_position
	rotation.y = lerp_angle(rotation.y, atan2(a.x, a.z), delta * 2.5)
	# Se inclina hacia donde avanza, como un helicóptero de verdad.
	var local: Vector3 = Basis(Vector3.UP, rotation.y).inverse() * _vel_actual
	rotation.x = lerpf(rotation.x, local.z * 0.035, delta * 3.0)
	rotation.z = lerpf(rotation.z, -local.x * 0.045, delta * 3.0)


## Otro punto de la zona de vuelo, lejos de Polo para que no se le meta encima.
func _nuevo_destino() -> void:
	for intento: int in 12:
		_destino = zona_vuelo.position + Vector3(randf(), randf(), randf()) * zona_vuelo.size
		var d := Vector2(_destino.x - objetivo.global_position.x, _destino.z - objetivo.global_position.z)
		if d.length() > 12.0:
			return


func _atacar(delta: float) -> void:
	_prox_misil -= delta
	if _prox_misil > 0.0:
		return
	_prox_misil = randf_range(1.5, 2.1) if _furiosa else randf_range(2.4, 3.2)
	var cuantos: int = 2 if _furiosa else 1
	for i: int in cuantos:
		var destino: Vector3 = objetivo.global_position
		if i > 0:
			# El segundo misil cae a un lado, para cerrarle el paso.
			destino += Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * 4.0
		destino.y = 0.0
		var salida: Vector3 = global_transform * Vector3(1.4 if i == 0 else -1.4, 1.0, 2.0)
		Explosivos.lanzar_misil(get_parent(), salida, destino, TIEMPO_MISIL)
	misil_lanzado.emit()
