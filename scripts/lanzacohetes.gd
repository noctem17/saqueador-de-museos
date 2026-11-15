class_name Lanzacohetes
extends Node3D
## El lanzacohetes que Polo saca del baúl de la camioneta. Va pegado a la cámara
## (primera persona). Clic izquierdo dispara; lleva un solo cohete, así que
## después de cada disparo baja el tubo, lo recarga y lo vuelve a subir.

signal cambio(cargado: bool)

const RECARGA: float = 1.4
const POS_LISTO := Vector3(0.26, -0.22, -0.42)

var cargado: bool = true
var raiz: Node                     ## Dónde se agregan los cohetes (la escena).
var _ojiva: MeshInstance3D
var _boca: Marker3D


func _ready() -> void:
	position = POS_LISTO
	scale = Vector3.ONE * 0.7
	var verde := StandardMaterial3D.new()
	verde.albedo_color = Color("4b5320")
	verde.roughness = 0.7
	var negro := StandardMaterial3D.new()
	negro.albedo_color = Color("1c1c1c")
	# Tubo (acostado, apuntando hacia adelante = -Z).
	var tubo := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.075
	c.bottom_radius = 0.075
	c.height = 1.1
	tubo.mesh = c
	tubo.material_override = verde
	tubo.rotation.x = PI * 0.5
	tubo.position.z = -0.1
	add_child(tubo)
	# Bocas más anchas adelante y atrás.
	for z: float in [-0.65, 0.45]:
		var anillo := MeshInstance3D.new()
		var a := CylinderMesh.new()
		a.top_radius = 0.095
		a.bottom_radius = 0.095
		a.height = 0.1
		anillo.mesh = a
		anillo.material_override = negro
		anillo.rotation.x = PI * 0.5
		anillo.position.z = z
		add_child(anillo)
	# Mira y empuñadura.
	_caja(Vector3(0.05, 0.09, 0.12), Vector3(-0.06, 0.11, -0.1), negro)
	_caja(Vector3(0.05, 0.16, 0.06), Vector3(0, -0.13, 0.05), negro)
	# Punta del cohete asomada: se ve solo cuando está cargado.
	_ojiva = MeshInstance3D.new()
	var o := CylinderMesh.new()
	o.top_radius = 0.0
	o.bottom_radius = 0.07
	o.height = 0.22
	_ojiva.mesh = o
	var mo := StandardMaterial3D.new()
	mo.albedo_color = Color("6b7a3a")
	_ojiva.material_override = mo
	_ojiva.rotation.x = -PI * 0.5
	_ojiva.position.z = -0.78
	add_child(_ojiva)
	_boca = Marker3D.new()
	_boca.position.z = -0.75
	add_child(_boca)


func _caja(tam: Vector3, pos: Vector3, mat: Material) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	m.mesh = b
	m.material_override = mat
	m.position = pos
	add_child(m)


func _process(_delta: float) -> void:
	if Juego.control_bloqueado or get_tree().paused:
		return
	if cargado and Input.is_action_just_pressed("disparar"):
		disparar()


func disparar() -> void:
	cargado = false
	_ojiva.visible = false
	cambio.emit(false)
	Sfx.plano(self, "cohete", -2.0)
	# El cohete sale de la boca hacia donde apunta la mira (el centro de la pantalla).
	var cam: Camera3D = get_viewport().get_camera_3d()
	var mira: Vector3 = cam.global_position - cam.global_basis.z * 80.0
	var desde: Vector3 = _boca.global_position
	Explosivos.lanzar_cohete(raiz if raiz else get_tree().current_scene, desde, mira - desde)
	get_tree().call_group("temblor", "temblar", 0.25)
	var t := create_tween()
	t.tween_property(self, "position", POS_LISTO + Vector3(0, 0.03, 0.12), 0.05)
	t.tween_property(self, "position", POS_LISTO + Vector3(0, -0.45, 0.1), 0.35)
	t.tween_callback(func() -> void: Sfx.plano(self, "recarga", -4.0))
	t.tween_interval(RECARGA - 0.6)
	t.tween_callback(_ojiva.show)
	t.tween_property(self, "position", POS_LISTO, 0.25)
	t.tween_callback(_listo)


func _listo() -> void:
	cargado = true
	cambio.emit(true)


## Lo sube desde abajo de la pantalla, como si lo acabara de sacar.
func sacar() -> void:
	position = POS_LISTO + Vector3(0, -0.6, 0)
	create_tween().tween_property(self, "position", POS_LISTO, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
