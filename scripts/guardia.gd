class_name Guardia
extends CharacterBody3D
## Patrulla, sospecha, investiga y persigue. La policía es este mismo guardia
## arrancando ya en alerta.

enum Estado { PATRULLA, INVESTIGAR, ALERTA, MUERTO }

const VEL_PATRULLA: float = 1.7
const VEL_INVESTIGAR: float = 2.6
const VEL_ALERTA: float = 3.5
const ALCANCE_VISTA: float = 14.0
const MEDIO_ANGULO: float = 0.95
const DIST_DISPARO: float = 13.0
const DANO: int = 9

var ruta: Array[Vector3] = []
var es_policia: bool = false
var vida: int = 3
var estado: Estado = Estado.PATRULLA
var sospecha: float = 0.0

var _indice: int = 0
var _espera: float = 1.0
var _espera_investigar: float = 0.0
var _enfriar_tiro: float = 1.0
var _fase_paso: float = 0.0
var _agente: NavigationAgent3D
var _muneco: Node3D
var _icono: Label3D
var _jugador: Jugador
var _colision: CollisionShape3D


func _ready() -> void:
	add_to_group("guardias")
	collision_layer = Juego.CAPA_ENEMIGO
	collision_mask = Juego.CAPA_MUNDO | Juego.CAPA_JUGADOR | Juego.CAPA_ENEMIGO

	var forma := CapsuleShape3D.new()
	forma.radius = 0.35
	forma.height = 1.8
	_colision = CollisionShape3D.new()
	_colision.shape = forma
	_colision.position.y = 0.9
	add_child(_colision)

	var ropa: Color = Color("1f2f4d") if es_policia else Color("3d4a3f")
	_muneco = Muneco.crear(Color("c49a78"), ropa, Color("1c1f26"))
	add_child(_muneco)

	_icono = Label3D.new()
	_icono.position.y = 2.2
	_icono.font_size = 96
	_icono.pixel_size = 0.005
	_icono.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_icono.no_depth_test = true
	add_child(_icono)

	_agente = NavigationAgent3D.new()
	_agente.path_desired_distance = 0.6
	_agente.target_desired_distance = 0.8
	_agente.height = 1.8
	_agente.radius = 0.4
	add_child(_agente)

	_jugador = get_tree().get_first_node_in_group("jugador") as Jugador
	Juego.ruido.connect(_oir)
	Juego.alarma_disparada.connect(_on_alarma)
	if es_policia or Juego.alarma:
		estado = Estado.ALERTA


func _physics_process(delta: float) -> void:
	if estado == Estado.MUERTO:
		return
	if Juego.control_bloqueado:
		_muneco_quieto()
		return
	if estado == Estado.ALERTA:
		_alerta(delta)
	else:
		_detectar(delta)
		if estado == Estado.PATRULLA:
			_patrullar(delta)
		elif estado == Estado.INVESTIGAR:
			_investigar(delta)
	_actualizar_icono()


func recibir_dano(cantidad: int) -> void:
	if estado == Estado.MUERTO:
		return
	vida -= cantidad
	if vida > 0:
		return
	estado = Estado.MUERTO
	_colision.set_deferred("disabled", true)
	collision_layer = 0
	_icono.text = ""
	remove_from_group("guardias")
	var tween := create_tween()
	tween.tween_property(_muneco, "rotation:x", -PI / 2.0, 0.35).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(_muneco, "position:y", 0.2, 0.35)


func _detectar(delta: float) -> void:
	if _jugador == null or _jugador.personaje != Jugador.Personaje.POLO:
		return
	var ojo: Vector3 = global_position + Vector3.UP * 1.65
	var adelante: Vector3 = -global_basis.z
	var alcance: float = Vision.alcance_real(ALCANCE_VISTA, _jugador)
	var distancia: float = ojo.distance_to(_jugador.punto_pecho())
	var espacio: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var visto: bool = Vision.ve_jugador(espacio, ojo, adelante, _jugador, alcance, MEDIO_ANGULO)
	# Si te chocas con un guardia te nota aunque esté de espaldas.
	if distancia < 1.6 and not visto:
		visto = Vision.ve_jugador(espacio, ojo, adelante, _jugador, alcance, PI)
	if visto:
		sospecha += Vision.ritmo(distancia, alcance) * delta
		Juego.sospecha = maxf(Juego.sospecha, sospecha)
		if sospecha >= 1.0:
			Juego.disparar_alarma("guardia")
			return
		if sospecha > 0.4:
			_ir_a(_jugador.global_position)
			estado = Estado.INVESTIGAR
			_espera_investigar = 3.0
	else:
		sospecha = maxf(sospecha - delta * 0.3, 0.0)


func _oir(pos: Vector3, radio: float) -> void:
	if estado == Estado.PATRULLA or estado == Estado.INVESTIGAR:
		if global_position.distance_to(pos) <= radio:
			_ir_a(pos)
			estado = Estado.INVESTIGAR
			_espera_investigar = 3.0


func _on_alarma(_motivo: String) -> void:
	if estado != Estado.MUERTO:
		estado = Estado.ALERTA
		sospecha = 0.0


func _ir_a(pos: Vector3) -> void:
	_agente.target_position = pos


func _patrullar(delta: float) -> void:
	if ruta.is_empty():
		return
	if _espera > 0.0:
		_espera -= delta
		_muneco_quieto()
		if _espera <= 0.0:
			_indice = (_indice + 1) % ruta.size()
			_ir_a(ruta[_indice])
		return
	if _agente.is_navigation_finished():
		_espera = randf_range(1.0, 2.5)
		_muneco_quieto()
		return
	_avanzar(VEL_PATRULLA, delta)


func _investigar(delta: float) -> void:
	if not _agente.is_navigation_finished():
		_avanzar(VEL_INVESTIGAR, delta)
		return
	_muneco_quieto()
	_espera_investigar -= delta
	rotate_y(sin(_espera_investigar * 2.0) * delta * 1.4)   # Mira alrededor.
	if _espera_investigar <= 0.0:
		estado = Estado.PATRULLA
		_espera = 0.5


func _alerta(delta: float) -> void:
	if _jugador == null:
		return
	var espacio: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var ojo: Vector3 = global_position + Vector3.UP * 1.65
	var q := PhysicsRayQueryParameters3D.create(ojo, _jugador.punto_pecho(), Juego.CAPA_MUNDO)
	var a_jugador: Vector3 = _jugador.global_position - global_position
	var linea_libre: bool = espacio.intersect_ray(q).is_empty()
	_enfriar_tiro -= delta
	if linea_libre and a_jugador.length() < DIST_DISPARO and _jugador.personaje == Jugador.Personaje.MOSTRO:
		_mirar(a_jugador, delta * 3.0)
		_muneco_quieto()
		if _enfriar_tiro <= 0.0:
			_enfriar_tiro = randf_range(0.9, 1.5)
			# Fallan más de lejos y si Mostro se mueve rápido.
			if randf() < lerpf(0.75, 0.3, a_jugador.length() / DIST_DISPARO):
				_jugador.recibir_dano(DANO)
		return
	_ir_a(_jugador.global_position)
	_avanzar(VEL_ALERTA, delta)


func _avanzar(vel: float, delta: float) -> void:
	var siguiente: Vector3 = _agente.get_next_path_position()
	var dir: Vector3 = siguiente - global_position
	dir.y = 0.0
	if dir.length() < 0.05:
		return
	dir = dir.normalized()
	velocity.x = dir.x * vel
	velocity.z = dir.z * vel
	velocity.y = -2.0
	move_and_slide()
	_mirar(dir, delta)
	_fase_paso += delta * vel * 3.2
	Muneco.animar(_muneco, _fase_paso, 1.0)


func _mirar(dir: Vector3, delta: float) -> void:
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), clampf(delta * 7.0, 0.0, 1.0))


func _muneco_quieto() -> void:
	Muneco.animar(_muneco, 0.0, 0.0)


func _actualizar_icono() -> void:
	if estado == Estado.ALERTA:
		_icono.text = "!"
		_icono.modulate = Color(0.95, 0.15, 0.1)
	elif sospecha > 0.05 or estado == Estado.INVESTIGAR:
		_icono.text = "?"
		_icono.modulate = Color(1.0, 0.8, 0.2)
	else:
		_icono.text = ""
