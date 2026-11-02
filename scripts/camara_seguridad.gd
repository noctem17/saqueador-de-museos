class_name CamaraSeguridad
extends Node3D
## Barre de lado a lado. El cono visible le muestra al jugador qué zona vigila.

const ALCANCE: float = 13.0
const MEDIO_ANGULO: float = 0.5
const BARRIDO: float = 0.8

var giro_base: float = 0.0
var activa: bool = true
var sospecha: float = 0.0
var _tiempo: float = 0.0
var _cabeza: Node3D
var _cono: MeshInstance3D
var _mat_cono: StandardMaterial3D
var _led: StandardMaterial3D
var _jugador: Jugador


func _ready() -> void:
	add_to_group("camaras")
	_tiempo = randf() * TAU
	_cabeza = Node3D.new()
	add_child(_cabeza)
	_cabeza.rotation.x = -0.42

	var cuerpo := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(0.22, 0.2, 0.42)
	cuerpo.mesh = caja
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("d7d7d7")
	cuerpo.material_override = mat
	_cabeza.add_child(cuerpo)

	var luz := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.035
	esfera.height = 0.07
	luz.mesh = esfera
	_led = StandardMaterial3D.new()
	_led.albedo_color = Color(1, 0.1, 0.05)
	_led.emission_enabled = true
	_led.emission = Color(1, 0.1, 0.05)
	_led.emission_energy_multiplier = 3.0
	luz.material_override = _led
	luz.position = Vector3(0.07, 0.07, -0.22)
	_cabeza.add_child(luz)

	_cono = MeshInstance3D.new()
	var cono := CylinderMesh.new()
	cono.top_radius = 0.0
	cono.bottom_radius = tan(MEDIO_ANGULO) * ALCANCE
	cono.height = ALCANCE
	cono.radial_segments = 20
	cono.cap_bottom = false
	_cono.mesh = cono
	_cono.rotation.x = -PI / 2.0
	_cono.position.z = -ALCANCE * 0.5
	_mat_cono = StandardMaterial3D.new()
	_mat_cono.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_cono.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_cono.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_cono.albedo_color = Color(1, 0.25, 0.15, 0.05)
	_mat_cono.no_depth_test = false
	_cono.material_override = _mat_cono
	_cono.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cabeza.add_child(_cono)

	_jugador = get_tree().get_first_node_in_group("jugador") as Jugador


func desactivar() -> void:
	activa = false
	sospecha = 0.0
	_cono.visible = false
	_led.emission_energy_multiplier = 0.0
	_led.albedo_color = Color(0.1, 0.1, 0.1)
	_cabeza.rotation.x = -0.9   # Queda mirando al piso, se nota que está apagada.


func _physics_process(delta: float) -> void:
	if not activa or Juego.alarma or Juego.control_bloqueado:
		return
	_tiempo += delta * 0.45
	rotation.y = deg_to_rad(giro_base) + sin(_tiempo) * BARRIDO
	if _jugador == null or _jugador.personaje != Jugador.Personaje.POLO:
		return
	var ojo: Vector3 = _cabeza.global_position
	var adelante: Vector3 = -_cabeza.global_basis.z
	var alcance: float = Vision.alcance_real(ALCANCE, _jugador)
	var espacio: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	if Vision.ve_jugador(espacio, ojo, adelante, _jugador, alcance, MEDIO_ANGULO):
		sospecha += Vision.ritmo(ojo.distance_to(_jugador.punto_pecho()), alcance) * delta * 0.8
		Juego.sospecha = maxf(Juego.sospecha, sospecha)
		_mat_cono.albedo_color = Color(1, 0.1, 0.05, 0.16)
		if sospecha >= 1.0:
			Juego.disparar_alarma("camara")
	else:
		sospecha = maxf(sospecha - delta * 0.4, 0.0)
		_mat_cono.albedo_color = Color(1, 0.25, 0.15, 0.05)
