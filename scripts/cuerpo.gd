class_name Cuerpo
extends Node3D
## Personaje 3D con animaciones. Todos usan el mismo esqueleto del paquete de
## Quaternius, así que solo cambian el modelo y los colores definidos en TIPOS.

const PREFIJO: String = "CharacterArmature|"
const BUCLES: Array[String] = ["Idle", "Idle_Neutral", "Idle_Gun", "Idle_Gun_Pointing", "Walk", "Run", "Run_Shoot"]

const TIPOS: Dictionary[String, Dictionary] = {
	"polo": {
		"modelo": "res://modelos/polo.glb",
		"colores": {"Skin": "3f2618", "Hair": "0f0b09", "Eyebrows": "0f0b09", "Purple": "22262d", "LightBlue": "191b20"},
	},
	"mostro": {
		"modelo": "res://modelos/mostro.glb",
		"colores": {"Skin": "e8c4a6", "Hair": "1e1814", "Eyebrows": "1e1814", "Beard": "241a14", "Suit": "1b1e26", "Tie": "7a1420"},
	},
	"guardia": {
		"modelo": "res://modelos/guardia.glb",
		"colores": {"LightBrown": "25324a", "LightBlue": "151922", "Red_Dark": "15161a", "White": "1d1e22", "Hair": "1c1612"},
		"arma": true,
	},
	"policia": {
		"modelo": "res://modelos/policia.glb",
		"colores": {},
		"arma": true,
	},
}

static var _materiales: Dictionary[String, Material] = {}

var tipo: String = "guardia"
var _modelo: Node3D
var _anim: AnimationPlayer
var _esqueleto: Skeleton3D
var _base: String = ""
var _arma_mano: Node3D
var _arma_cadera: Node3D
var _boca: Marker3D


static func crear(nombre: String) -> Cuerpo:
	var c := Cuerpo.new()
	c.tipo = nombre
	return c


func _ready() -> void:
	var datos: Dictionary = TIPOS[tipo]
	var escena: PackedScene = load(datos["modelo"] as String)
	_modelo = escena.instantiate() as Node3D
	_modelo.rotation.y = PI   # El modelo mira a +Z; en Godot "adelante" es -Z.
	add_child(_modelo)
	_anim = _modelo.get_node("AnimationPlayer") as AnimationPlayer
	_esqueleto = _modelo.find_child("Skeleton3D", true, false) as Skeleton3D
	for nombre: String in BUCLES:
		_anim.get_animation(PREFIJO + nombre).loop_mode = Animation.LOOP_LINEAR
	_anim.animation_finished.connect(_al_terminar)
	_recolorear(datos["colores"] as Dictionary)
	if datos.get("arma", false):
		_arma_mano = _poner_pistola("Wrist.R", Vector3(-0.02, 0.09, 0.03), Vector3(0, 90, 90))
		_arma_cadera = _poner_pistola("Hips", Vector3(-0.2, 0.0, 0.03), Vector3(0, 0, -90))
		_arma_mano.visible = false
		_boca = Marker3D.new()
		_boca.position = Vector3(1.3, 0.0, 0.0)
		_arma_mano.add_child(_boca)
	reproducir("Idle")


## Animación en bucle que queda como base.
func reproducir(nombre: String, mezcla: float = 0.2) -> void:
	if _base == nombre:
		return
	_base = nombre
	_anim.play(PREFIJO + nombre, mezcla)


## Animación de una sola vez; al terminar regresa a la base.
func una_vez(nombre: String, mezcla: float = 0.08) -> void:
	_anim.play(PREFIJO + nombre, mezcla)


## Queda detenida en un punto de la animación, como una pose.
func posar(nombre: String, proporcion: float) -> void:
	_base = nombre
	var completo: String = PREFIJO + nombre
	_anim.play(completo)
	_anim.seek(_anim.get_animation(completo).length * proporcion, true)
	_anim.pause()


## Pose agachada hecha doblando caderas y rodillas: el paquete no trae esa animación.
func agachar() -> void:
	posar("Idle_Neutral", 0.0)
	for lado: String in [".L", ".R"]:
		_doblar("UpperLeg" + lado, Vector3.RIGHT, -1.6)
		_doblar("LowerLeg" + lado, Vector3.RIGHT, 1.95)
		_doblar("Foot" + lado, Vector3.RIGHT, -0.35)
	_doblar("Abdomen", Vector3.RIGHT, 0.35)
	_doblar("Neck", Vector3.RIGHT, -0.25)
	_modelo.position.y = -0.42


func _doblar(hueso: String, eje: Vector3, angulo: float) -> void:
	var i: int = _esqueleto.find_bone(hueso)
	if i < 0:
		return
	var padre: int = _esqueleto.get_bone_parent(i)
	var global_q: Quaternion = _esqueleto.get_bone_global_pose(i).basis.get_rotation_quaternion()
	var padre_q: Quaternion = _esqueleto.get_bone_global_pose(padre).basis.get_rotation_quaternion()
	var nuevo_global: Quaternion = Quaternion(eje, angulo) * global_q
	_esqueleto.set_bone_pose_rotation(i, padre_q.inverse() * nuevo_global)
	_esqueleto.force_update_all_bone_transforms()


func morir() -> void:
	_base = ""
	_anim.play(PREFIJO + "Death", 0.1)


func mano_armada(activa: bool) -> void:
	if _arma_mano:
		_arma_mano.visible = activa
		_arma_cadera.visible = not activa


func boca_arma() -> Vector3:
	return _boca.global_position if _boca else global_position + Vector3.UP * 1.3


func _al_terminar(nombre: StringName) -> void:
	if _base != "" and not String(nombre).ends_with(_base):
		_anim.play(PREFIJO + _base, 0.15)


func _recolorear(colores: Dictionary) -> void:
	for nodo: Node in _modelo.find_children("*", "MeshInstance3D", true, false):
		var malla := nodo as MeshInstance3D
		for s: int in malla.mesh.get_surface_count():
			var original: Material = malla.get_active_material(s)
			var nombre: String = original.resource_name.get_slice(".", 0)   # Blender puede crear "Suit.001".
			if not colores.has(nombre):
				continue
			var clave: String = "%s/%s" % [tipo, nombre]
			if not _materiales.has(clave):
				var nuevo := original.duplicate() as BaseMaterial3D
				nuevo.albedo_color = Color(colores[nombre] as String)
				_materiales[clave] = nuevo
			malla.set_surface_override_material(s, _materiales[clave])


## El esqueleto de estos modelos viene escalado 100 veces. El nodo intermedio lo
## compensa para que lo que se le cuelgue use metros normales.
func _adjunto(hueso: String) -> Node3D:
	var a := BoneAttachment3D.new()
	a.bone_name = hueso
	_esqueleto.add_child(a)
	var metros := Node3D.new()
	metros.scale = Vector3.ONE * 0.01
	a.add_child(metros)
	return metros


func _poner_pistola(hueso: String, pos: Vector3, giro: Vector3) -> Node3D:
	var escena: PackedScene = load("res://modelos/pistola.glb")
	var arma := escena.instantiate() as Node3D
	var adjunto: Node3D = _adjunto(hueso)
	adjunto.add_child(arma)
	arma.position = pos
	arma.rotation_degrees = giro
	arma.scale = Vector3.ONE * 0.13
	return arma

