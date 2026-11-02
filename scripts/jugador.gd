class_name Jugador
extends CharacterBody3D
## Primera persona. El mismo nodo sirve a los dos personajes:
## Polo solo roba y se esconde; Mostro entra disparando cuando suena la alarma.

signal disparo_realizado
signal vida_cambio

enum Personaje { POLO, MOSTRO }

const VEL_CAMINAR: float = 3.4
const VEL_CORRER: float = 5.8
const VEL_AGACHADO: float = 1.8
const SALTO: float = 4.2
const ALTURA_PIE: float = 1.75
const ALTURA_AGACHADO: float = 1.0
const ASOMAR_DIST: float = 0.55
const ASOMAR_GIRO: float = 0.2
const ALCANCE_USO: float = 2.4
const BALAS: int = 12
const DANO_DISPARO: int = 1
const SENSIBILIDAD: float = 0.0025

var personaje: Personaje = Personaje.POLO
var polo_rescatado: bool = false
var agachado: bool = false
var corriendo: bool = false
var vida: int = 100
var balas: int = BALAS

var objetivo_uso: Interactuable = null
var progreso_uso: float = 0.0
var texto_uso: String = ""

var _capsula: CapsuleShape3D
var _colision: CollisionShape3D
var _pivote: Node3D
var _camara: Camera3D
var _arma: Node3D
var _destello: OmniLight3D
var _alto_actual: float = ALTURA_PIE
var _asomar: float = 0.0
var _enfriar_disparo: float = 0.0
var _recargando: float = 0.0
var _ruido_pasos: float = 0.0
var _balanceo: float = 0.0


func _ready() -> void:
	add_to_group("jugador")
	collision_layer = Juego.CAPA_JUGADOR
	collision_mask = Juego.CAPA_MUNDO | Juego.CAPA_ENEMIGO
	floor_snap_length = 0.2

	_capsula = CapsuleShape3D.new()
	_capsula.radius = 0.32
	_capsula.height = ALTURA_PIE
	_colision = CollisionShape3D.new()
	_colision.shape = _capsula
	_colision.position.y = ALTURA_PIE * 0.5
	add_child(_colision)

	_pivote = Node3D.new()
	_pivote.position.y = ALTURA_PIE - 0.15
	add_child(_pivote)
	_camara = Camera3D.new()
	_camara.fov = 75.0
	_camara.current = true
	_pivote.add_child(_camara)
	_armar_pistola()
	_arma.visible = false


func _armar_pistola() -> void:
	_arma = Node3D.new()
	_arma.position = Vector3(0.2, -0.17, -0.5)
	_arma.scale = Vector3.ONE * 0.6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("1a1b1e")
	mat.metallic = 0.7
	mat.roughness = 0.4
	for parte: Array in [[Vector3(0.05, 0.08, 0.26), Vector3.ZERO], [Vector3(0.05, 0.14, 0.07), Vector3(0, -0.09, 0.08)]]:
		var m := MeshInstance3D.new()
		var caja := BoxMesh.new()
		caja.size = parte[0]
		m.mesh = caja
		m.position = parte[1]
		m.material_override = mat
		_arma.add_child(m)
	_destello = OmniLight3D.new()
	_destello.position.z = -0.25
	_destello.light_color = Color("ffcf7a")
	_destello.light_energy = 0.0
	_destello.omni_range = 6.0
	_arma.add_child(_destello)
	_camara.add_child(_arma)


func cambiar_a_mostro(pos: Vector3, mirar_a: Vector3) -> void:
	personaje = Personaje.MOSTRO
	global_position = pos
	velocity = Vector3.ZERO
	_arma.visible = true
	agachado = false
	corriendo = false
	vida = 100
	balas = BALAS
	vida_cambio.emit()
	look_at(Vector3(mirar_a.x, global_position.y, mirar_a.z), Vector3.UP)
	_pivote.rotation.x = 0.0
	_cancelar_uso()


func recibir_dano(cantidad: int) -> void:
	vida = maxi(vida - cantidad, 0)
	vida_cambio.emit()


func punto_cabeza() -> Vector3:
	return _pivote.global_position


func punto_pecho() -> Vector3:
	return global_position + Vector3.UP * (_alto_actual * 0.55)


func recargando() -> bool:
	return _recargando > 0.0


func _unhandled_input(event: InputEvent) -> void:
	if Juego.control_bloqueado or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		var movimiento := event as InputEventMouseMotion
		rotate_y(-movimiento.relative.x * SENSIBILIDAD)
		_pivote.rotation.x = clampf(_pivote.rotation.x - movimiento.relative.y * SENSIBILIDAD, -1.45, 1.45)


func _physics_process(delta: float) -> void:
	var bloqueado: bool = Juego.control_bloqueado
	_mover(delta, bloqueado)
	_agacharse(delta, bloqueado)
	_asomarse(delta, bloqueado)
	_interactuar(delta, bloqueado)
	if personaje == Personaje.MOSTRO and not bloqueado:
		_arma_logica(delta)
	_destello.light_energy = move_toward(_destello.light_energy, 0.0, delta * 40.0)


func _mover(delta: float, bloqueado: bool) -> void:
	var entrada := Vector2.ZERO if bloqueado else Input.get_vector("izquierda", "derecha", "adelante", "atras")
	# Mantener F para robar deja al ladrón quieto: no se puede descolgar corriendo.
	if objetivo_uso != null and progreso_uso > 0.0:
		entrada = Vector2.ZERO
	corriendo = not bloqueado and Input.is_action_pressed("correr") and entrada.length() > 0.1 and not agachado
	var vel: float = VEL_AGACHADO if agachado else (VEL_CORRER if corriendo else VEL_CAMINAR)
	if personaje == Personaje.POLO:
		vel *= 1.0 - 0.06 * Juego.robadas.size()   # Cada obra pesa en el bolso.
	var dir: Vector3 = global_basis * Vector3(entrada.x, 0.0, entrada.y)
	velocity.x = dir.x * vel
	velocity.z = dir.z * vel
	if is_on_floor():
		if not bloqueado and Input.is_action_just_pressed("saltar") and not agachado:
			velocity.y = SALTO
			_hacer_ruido(6.0)
	else:
		velocity += get_gravity() * delta
	move_and_slide()

	# Correr se oye. Caminar no; agachado, menos.
	if corriendo and is_on_floor():
		_ruido_pasos -= delta
		if _ruido_pasos <= 0.0:
			_ruido_pasos = 0.4
			_hacer_ruido(9.0)
	# Balanceo leve de cámara al andar.
	var horizontal: float = Vector2(velocity.x, velocity.z).length()
	_balanceo += delta * horizontal * 2.4
	_camara.position.y = sin(_balanceo) * 0.018 * clampf(horizontal, 0.0, 1.0)


func _hacer_ruido(radio: float) -> void:
	Juego.ruido.emit(global_position, radio)


func _agacharse(delta: float, bloqueado: bool) -> void:
	var quiere: bool = not bloqueado and Input.is_action_pressed("agacharse")
	if not quiere and agachado:
		# No se puede poner de pie debajo de algo.
		quiere = test_move(global_transform, Vector3.UP * (ALTURA_PIE - ALTURA_AGACHADO))
	agachado = quiere
	var objetivo: float = ALTURA_AGACHADO if agachado else ALTURA_PIE
	_alto_actual = move_toward(_alto_actual, objetivo, delta * 5.0)
	_capsula.height = maxf(_alto_actual, _capsula.radius * 2.0)
	_colision.position.y = _capsula.height * 0.5
	_pivote.position.y = _alto_actual - 0.15


func _asomarse(delta: float, bloqueado: bool) -> void:
	var lado: float = 0.0
	if not bloqueado:
		lado = Input.get_axis("asomar_izq", "asomar_der")
	var meta: float = lado * ASOMAR_DIST
	if not is_zero_approx(lado):
		meta = lado * _distancia_libre(lado)
	_asomar = move_toward(_asomar, meta, delta * 3.2)
	_pivote.position.x = _asomar
	_pivote.rotation.z = -_asomar / ASOMAR_DIST * ASOMAR_GIRO


## La cabeza no atraviesa muros al asomarse: se detiene antes.
func _distancia_libre(lado: float) -> float:
	var origen: Vector3 = global_position + Vector3.UP * _pivote.position.y
	var destino: Vector3 = origen + global_basis.x * lado * (ASOMAR_DIST + 0.2)
	var q := PhysicsRayQueryParameters3D.create(origen, destino, Juego.CAPA_MUNDO)
	var r: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
	if r.is_empty():
		return ASOMAR_DIST
	var libre: float = origen.distance_to(r["position"] as Vector3) - 0.2
	return clampf(libre, 0.0, ASOMAR_DIST)


func _interactuar(delta: float, bloqueado: bool) -> void:
	var visto: Interactuable = null if bloqueado else _buscar_interactuable()
	if visto != objetivo_uso:
		_cancelar_uso()
		objetivo_uso = visto
	texto_uso = "" if objetivo_uso == null else objetivo_uso.prompt(self)
	if objetivo_uso == null or not objetivo_uso.disponible(self):
		progreso_uso = 0.0
		return
	if Input.is_action_pressed("interactuar"):
		progreso_uso += delta / maxf(objetivo_uso.duracion, 0.05)
		if progreso_uso >= 1.0:
			var usado: Interactuable = objetivo_uso
			_cancelar_uso()
			usado.completar(self)
	else:
		progreso_uso = 0.0


func _cancelar_uso() -> void:
	objetivo_uso = null
	progreso_uso = 0.0
	texto_uso = ""


func _buscar_interactuable() -> Interactuable:
	var desde: Vector3 = _camara.global_position
	var hasta: Vector3 = desde - _camara.global_basis.z * ALCANCE_USO
	var q := PhysicsRayQueryParameters3D.create(desde, hasta, Juego.CAPA_MUNDO | Juego.CAPA_INTERACTUABLE)
	var r: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
	if r.is_empty():
		return null
	return r["collider"] as Interactuable


func _arma_logica(delta: float) -> void:
	_enfriar_disparo = maxf(_enfriar_disparo - delta, 0.0)
	if _recargando > 0.0:
		_recargando -= delta
		if _recargando <= 0.0:
			balas = BALAS
			disparo_realizado.emit()
		return
	if Input.is_action_just_pressed("recargar") and balas < BALAS:
		_recargando = 1.4
		disparo_realizado.emit()
		return
	if Input.is_action_just_pressed("disparar") and _enfriar_disparo <= 0.0:
		if balas <= 0:
			_recargando = 1.4
			disparo_realizado.emit()
			return
		disparar()


func disparar() -> void:
	balas -= 1
	_enfriar_disparo = 0.22
	_destello.light_energy = 3.0
	_pivote.rotation.x = minf(_pivote.rotation.x + 0.012, 1.45)
	_hacer_ruido(30.0)
	disparo_realizado.emit()
	var desde: Vector3 = _camara.global_position
	var hasta: Vector3 = desde - _camara.global_basis.z * 60.0
	var q := PhysicsRayQueryParameters3D.create(desde, hasta, Juego.CAPA_MUNDO | Juego.CAPA_ENEMIGO)
	var r: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
	if not r.is_empty() and r["collider"] is Guardia:
		(r["collider"] as Guardia).recibir_dano(DANO_DISPARO)
