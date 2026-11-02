class_name Guardia
extends CharacterBody3D
## Patrulla, sospecha, investiga y persigue. La policía es este mismo guardia
## arrancando ya en alerta y con el arma en la mano.

enum Estado { PATRULLA, INVESTIGAR, ALERTA, MUERTO }

const VEL_PATRULLA: float = 1.5
const VEL_INVESTIGAR: float = 2.2
const VEL_ALERTA: float = 3.6
const ALCANCE_VISTA: float = 14.0
const MEDIO_ANGULO: float = 0.95
const DIST_DISPARO: float = 14.0
const DANO: int = 8
const TIEMPO_DESENFUNDAR: float = 0.7
const INTERVALO_PASOS: float = 0.5


## Zona que recibe balas: cabeza, torso o piernas. Va aparte del cuerpo físico
## porque la cápsula con la que camina no cubre toda la figura.
class ZonaImpacto:
	extends Area3D
	var dueno: Guardia
	var dano: int = 1


var ruta: Array[Vector3] = []
var es_policia: bool = false
var vida: int = 3
var estado: Estado = Estado.PATRULLA
var sospecha: float = 0.0

var _indice: int = 0
var _espera: float = 1.0
var _espera_investigar: float = 0.0
var _enfriar_tiro: float = 1.0
var _desenfundar: float = -1.0
var _armado: bool = false
var _pasos: float = 0.0
var _agente: NavigationAgent3D
var _cuerpo: Cuerpo
var _icono: Label3D
var _jugador: Jugador
var _colision: CollisionShape3D
var _zonas: Array[ZonaImpacto] = []


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

	_cuerpo = Cuerpo.crear("policia" if es_policia else "guardia")
	add_child(_cuerpo)
	_crear_zona(Vector3(0.36, 0.36, 0.36), Vector3(0, 1.68, 0), 3)   # Cabeza: un tiro basta.
	_crear_zona(Vector3(0.85, 0.78, 0.5), Vector3(0, 1.13, 0), 1)    # Torso y brazos.
	_crear_zona(Vector3(0.6, 0.76, 0.5), Vector3(0, 0.38, 0), 1)     # Piernas.
	if es_policia:
		vida = 4

	_icono = Label3D.new()
	_icono.position.y = 2.25
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
		_entrar_en_alerta()


func _crear_zona(tam: Vector3, pos: Vector3, dano: int) -> void:
	var z := ZonaImpacto.new()
	z.dueno = self
	z.dano = dano
	z.collision_layer = Juego.CAPA_IMPACTO
	z.collision_mask = 0
	z.monitoring = false
	var forma := BoxShape3D.new()
	forma.size = tam
	var col := CollisionShape3D.new()
	col.shape = forma
	z.add_child(col)
	z.position = pos
	add_child(z)
	_zonas.append(z)


func _physics_process(delta: float) -> void:
	if estado == Estado.MUERTO:
		return
	if Juego.control_bloqueado:
		_quieto()
		return
	match estado:
		Estado.ALERTA:
			_alerta(delta)
		Estado.PATRULLA:
			_detectar(delta)
			_patrullar(delta)
		Estado.INVESTIGAR:
			_detectar(delta)
			_investigar(delta)
	_actualizar_icono()


func recibir_dano(cantidad: int, punto: Vector3, direccion: Vector3) -> void:
	if estado == Estado.MUERTO:
		return
	vida -= cantidad
	var fatal: bool = vida <= 0
	Efectos.sangre(get_parent(), punto, direccion, fatal)
	Sfx.en(self, "carne", punto, 0.0, 18.0)
	if estado != Estado.ALERTA:
		_entrar_en_alerta()
	if not fatal:
		_cuerpo.una_vez("HitRecieve")
		return
	estado = Estado.MUERTO
	collision_layer = 0
	_colision.set_deferred("disabled", true)
	for z: ZonaImpacto in _zonas:
		z.queue_free()
	_zonas.clear()
	_icono.text = ""
	remove_from_group("guardias")
	_cuerpo.morir()
	Efectos.charco(get_parent(), global_position)


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
	if distancia < 1.4 and not visto:
		visto = Vision.ve_jugador(espacio, ojo, adelante, _jugador, alcance, PI)
	if visto:
		sospecha += Vision.ritmo(distancia, alcance) * delta
		Juego.sospecha = maxf(Juego.sospecha, sospecha)
		if sospecha >= 1.0:
			Juego.disparar_alarma("guardia")
			return
		if sospecha > 0.45 and estado != Estado.INVESTIGAR:
			Sfx.en(self, "alerta", global_position, -8.0, 16.0)
		if sospecha > 0.45:
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
		_entrar_en_alerta()


func _entrar_en_alerta() -> void:
	estado = Estado.ALERTA
	sospecha = 0.0
	_desenfundar = TIEMPO_DESENFUNDAR


func _ir_a(pos: Vector3) -> void:
	_agente.target_position = pos


func _patrullar(delta: float) -> void:
	if ruta.is_empty():
		_quieto()
		return
	if _espera > 0.0:
		_espera -= delta
		_quieto()
		if _espera <= 0.0:
			_indice = (_indice + 1) % ruta.size()
			_ir_a(ruta[_indice])
		return
	if _agente.is_navigation_finished():
		_espera = randf_range(1.0, 2.5)
		_quieto()
		return
	_avanzar(VEL_PATRULLA, delta, "Walk")


func _investigar(delta: float) -> void:
	if not _agente.is_navigation_finished():
		_avanzar(VEL_INVESTIGAR, delta, "Walk")
		return
	_quieto()
	_espera_investigar -= delta
	rotate_y(sin(_espera_investigar * 2.0) * delta * 1.4)   # Mira alrededor.
	if _espera_investigar <= 0.0:
		estado = Estado.PATRULLA
		_espera = 0.5


func _alerta(delta: float) -> void:
	if _jugador == null:
		return
	if _desenfundar > 0.0:
		_sacar_arma(delta)
		return
	var ojo: Vector3 = global_position + Vector3.UP * 1.5
	var q := PhysicsRayQueryParameters3D.create(ojo, _jugador.punto_pecho(), Juego.CAPA_MUNDO)
	var a_jugador: Vector3 = _jugador.global_position - global_position
	var linea_libre: bool = get_world_3d().direct_space_state.intersect_ray(q).is_empty()
	_enfriar_tiro -= delta
	if linea_libre and a_jugador.length() < DIST_DISPARO and _jugador.personaje == Jugador.Personaje.MOSTRO:
		_mirar(a_jugador, delta * 1.5)
		_cuerpo.reproducir("Idle_Gun_Pointing")
		if _enfriar_tiro <= 0.0:
			_enfriar_tiro = randf_range(0.9, 1.6)
			_disparar(a_jugador.length())
		return
	_ir_a(_jugador.global_position)
	_avanzar(VEL_ALERTA, delta, "Run_Shoot" if _armado else "Run")


## Se detiene un instante y saca la pistola de la cadera: se ve venir el tiro.
func _sacar_arma(delta: float) -> void:
	if not _armado:
		_armado = true
		_cuerpo.una_vez("Interact")
		Sfx.en(self, "desenfundar", global_position, -2.0, 18.0)
	_desenfundar -= delta
	if _jugador:
		_mirar(_jugador.global_position - global_position, delta)
	if _desenfundar <= TIEMPO_DESENFUNDAR * 0.5:
		_cuerpo.mano_armada(true)
	if _desenfundar <= 0.0:
		_cuerpo.reproducir("Idle_Gun_Pointing")


func _disparar(distancia: float) -> void:
	_cuerpo.una_vez("Idle_Gun_Shoot", 0.04)
	var boca: Vector3 = _cuerpo.boca_arma()
	var destino: Vector3 = _jugador.punto_pecho()
	# Fallan más de lejos; un fallo pasa a un lado del jugador.
	var acierta: bool = randf() < lerpf(0.72, 0.28, distancia / DIST_DISPARO)
	if acierta:
		_jugador.recibir_dano(DANO)
	else:
		destino += Vector3(randf_range(-0.9, 0.9), randf_range(-0.4, 0.7), randf_range(-0.9, 0.9))
	Efectos.trazadora(get_parent(), boca, destino)
	Sfx.en(self, "disparo_guardia", boca, 0.0, 45.0)
	var luz := OmniLight3D.new()
	luz.light_color = Color("ffcf7a")
	luz.light_energy = 2.5
	luz.omni_range = 5.0
	add_child(luz)
	luz.global_position = boca
	get_tree().create_timer(0.06).timeout.connect(luz.queue_free)


func _avanzar(vel: float, delta: float, animacion: String) -> void:
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
	_cuerpo.reproducir(animacion)
	_pasos -= delta * (vel / VEL_PATRULLA)
	if _pasos <= 0.0:
		_pasos = INTERVALO_PASOS * 1.5
		Sfx.en(self, "paso", global_position, -6.0, 14.0)


func _mirar(dir: Vector3, delta: float) -> void:
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), clampf(delta * 7.0, 0.0, 1.0))


func _quieto() -> void:
	_cuerpo.reproducir("Idle_Gun_Pointing" if _armado else "Idle")


func _actualizar_icono() -> void:
	if estado == Estado.ALERTA:
		_icono.text = "!"
		_icono.modulate = Color(0.95, 0.15, 0.1)
	elif sospecha > 0.05 or estado == Estado.INVESTIGAR:
		_icono.text = "?"
		_icono.modulate = Color(1.0, 0.8, 0.2)
	else:
		_icono.text = ""
