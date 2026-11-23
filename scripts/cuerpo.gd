class_name Cuerpo
extends Node3D
## Personaje 3D con animaciones. Hay dos clases de esqueleto:
## - Quaternius (Franchesca): animaciones "CharacterArmature|Nombre".
## - Mixamo (los modelos nuevos del equipo): herramientas/rigear_mixamo.py les copió
##   las mismas animaciones de Quaternius con el nombre limpio ("Walk") y dejó las
##   suyas con "m_" ("m_walk"). Cada tipo dice en "animaciones" cuál usar para cada
##   acción del juego, así el resto del código siempre pide "Walk", "Idle", etc.

const PREFIJO: String = "CharacterArmature|"
const BUCLES: Array[String] = ["Idle", "Idle_Neutral", "Idle_Gun", "Idle_Gun_Pointing", "Walk", "Run", "Run_Shoot"]

## Hueso de Quaternius -> el mismo hueso en Mixamo.
const HUESOS_MIXAMO: Dictionary[String, String] = {
	"Hips": "Hips", "Abdomen": "Spine", "Torso": "Spine1", "Chest": "Spine2", "Neck": "Neck", "Head": "Head",
	"UpperArm.L": "LeftArm", "UpperArm.R": "RightArm", "LowerArm.L": "LeftForeArm", "LowerArm.R": "RightForeArm",
	"Wrist.L": "LeftHand", "Wrist.R": "RightHand", "UpperLeg.L": "LeftUpLeg", "UpperLeg.R": "RightUpLeg",
	"LowerLeg.L": "LeftLeg", "LowerLeg.R": "RightLeg", "Foot.L": "LeftFoot", "Foot.R": "RightFoot",
}

const TIPOS: Dictionary[String, Dictionary] = {
	# "cara": altura de los ojos (para los primeros planos); "agachado": cuánto
	# baja el cuerpo en la pose agachada; "animaciones": acción del juego ->
	# animación del modelo; "bucles": animaciones propias que se repiten.
	"polo": {
		"modelo": "res://modelos/polo_mx.glb",
		"mixamo": true,
		"colores": {},
		"cara": 1.56,
		"agachado": -0.36,
		"animaciones": {"Idle": "Idle_Neutral", "Walk": "m_walk", "Run": "m_run"},
		"bucles": ["m_walk", "m_run", "m_scared_01", "m_clap", "m_afraid"],
		"escondido": "Idle",   # Sin animaciones de miedo: le deforman la cara.
	},
	"mostro": {
		"modelo": "res://modelos/mostro_mx.glb",
		"mixamo": true,
		"colores": {},
		"cara": 1.52,
		"agachado": -0.36,
		"animaciones": {"Idle": "Idle_Neutral", "Walk": "m_walk", "Run": "m_run"},
		"bucles": ["m_walk", "m_run", "m_dance_03"],
	},
	# Desbloqueable para más adelante.
	"mostro_premium": {
		"modelo": "res://modelos/mostro_premium_mx.glb",
		"mixamo": true,
		"colores": {},
		"cara": 1.6,
		"agachado": -0.36,
		"animaciones": {"Idle": "Idle_Neutral", "Walk": "m_walk", "Run": "m_run"},
		"bucles": ["m_walk", "m_run", "m_dance_03", "m_dance_05"],
	},
	# El jefe de la espada de Bolívar.
	"elcacas": {
		"modelo": "res://modelos/elcacas_mx.glb",
		"mixamo": true,
		"colores": {},
		"cara": 1.6,
		"agachado": -0.36,
		"animaciones": {"Idle": "m_wait", "Walk": "m_walk", "Run": "m_run"},
		"bucles": ["m_walk", "m_run", "m_wait", "m_cry"],
	},
	"franchesca": {
		"modelo": "res://modelos/franchesca.glb",
		"colores": {},
		"cara": 1.15,
		"dist_cara": 2.5,
		"agachado": -0.16,
	},
	"guardia": {
		"modelo": "res://modelos/vigilante_mx.glb",
		"mixamo": true,
		"colores": {},
		"arma": true,
		"pistola": [Vector3(-0.02, 0.0, 0.04), Vector3(0, 90, 90)],
		"cara": 1.68,
		"animaciones": {"Idle": "m_look_around", "Walk": "m_walk", "Run": "m_run", "Death": "m_fall"},
		"bucles": ["m_walk", "m_run", "m_look_around"],
	},
	"policia": {
		"modelo": "res://modelos/policia_mx.glb",
		"mixamo": true,
		"colores": {},
		"arma": true,
		"pistola": [Vector3(-0.02, 0.0, 0.04), Vector3(0, 90, 90)],
		"cara": 1.68,
		"animaciones": {"Idle": "m_make_a_call_02", "Walk": "m_walk", "Run": "m_run", "Death": "m_fall"},
		"bucles": ["m_walk", "m_run", "m_make_a_call_02"],
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
	var bucles: Array = BUCLES.map(_completa) + (datos.get("bucles", []) as Array)
	for nombre: String in bucles:
		if _anim.has_animation(nombre):
			_anim.get_animation(nombre).loop_mode = Animation.LOOP_LINEAR
	_anim.animation_finished.connect(_al_terminar)
	_recolorear(datos["colores"] as Dictionary)
	if datos.get("arma", false):
		var en_mano: Array = datos.get("pistola", [Vector3(-0.02, 0.09, 0.03), Vector3(0, 90, 90)])
		_arma_mano = _poner_pistola("Wrist.R", en_mano[0] as Vector3, en_mano[1] as Vector3)
		_enderezar_pistola(_arma_mano)
		if datos.get("mixamo", false):
			# Funda al lado derecho de la cadera, dada en metros del cuerpo.
			_arma_cadera = _poner_en_cuerpo("Hips", Vector3(0.2, 0.93, 0.02), Vector3(0, 0, -90))
		else:
			_arma_cadera = _poner_pistola("Hips", Vector3(-0.2, 0.0, 0.03), Vector3(0, 0, -90))
		_arma_mano.visible = false
		_boca = Marker3D.new()
		_boca.position = Vector3(1.3, 0.0, 0.0)
		_arma_mano.add_child(_boca)
	reproducir("Idle")


## Nombre real de la animación en el modelo (ver "animaciones" en TIPOS).
func _completa(nombre: String) -> String:
	var datos: Dictionary = TIPOS[tipo]
	var propio: String = (datos.get("animaciones", {}) as Dictionary).get(nombre, nombre)
	return propio if datos.get("mixamo", false) else PREFIJO + propio


## Nombre real del hueso (los modelos nuevos usan los nombres de Mixamo).
func _hueso(nombre: String) -> String:
	return HUESOS_MIXAMO.get(nombre, nombre) if TIPOS[tipo].get("mixamo", false) else nombre


func tiene_animacion(nombre: String) -> bool:
	return _anim.has_animation(_completa(nombre))


## Animación en bucle que queda como base.
func reproducir(nombre: String, mezcla: float = 0.2) -> void:
	if _base == nombre:
		return
	_base = nombre
	_anim.active = true
	_anim.play(_completa(nombre), mezcla)


## Animación de una sola vez; al terminar regresa a la base.
func una_vez(nombre: String, mezcla: float = 0.08) -> void:
	_anim.active = true
	_anim.play(_completa(nombre), mezcla)


## Queda detenida en un punto de la animación, como una pose.
func posar(nombre: String, proporcion: float) -> void:
	_base = nombre
	var completo: String = _completa(nombre)
	_anim.active = true
	_anim.play(completo)
	_anim.seek(_anim.get_animation(completo).length * proporcion, true)
	_anim.pause()


## Escondido: los modelos nuevos usan su animación de miedo (si la tienen); los
## demás, una pose agachada hecha doblando caderas y rodillas.
func esconderse() -> void:
	var miedo: String = TIPOS[tipo].get("escondido", "")
	if miedo != "":
		_base = ""
		reproducir(miedo, 0.0)
		return
	agachar()


func agachar() -> void:
	posar("Idle_Neutral", 0.0)
	for lado: String in [".L", ".R"]:
		_doblar("UpperLeg" + lado, Vector3.RIGHT, -1.6)
		_doblar("LowerLeg" + lado, Vector3.RIGHT, 1.95)
		_doblar("Foot" + lado, Vector3.RIGHT, -0.35)
	_doblar("Abdomen", Vector3.RIGHT, 0.35)
	_doblar("Neck", Vector3.RIGHT, -0.25)
	_modelo.position.y = TIPOS[tipo].get("agachado", -0.42)


func _doblar(hueso: String, eje: Vector3, angulo: float) -> void:
	var i: int = _esqueleto.find_bone(_hueso(hueso))
	if i < 0:
		return
	var padre: int = _esqueleto.get_bone_parent(i)
	var global_q: Quaternion = _esqueleto.get_bone_global_pose(i).basis.get_rotation_quaternion()
	var padre_q: Quaternion = _esqueleto.get_bone_global_pose(padre).basis.get_rotation_quaternion()
	var nuevo_global: Quaternion = Quaternion(eje, angulo) * global_q
	_esqueleto.set_bone_pose_rotation(i, padre_q.inverse() * nuevo_global)
	_esqueleto.force_update_all_bone_transforms()


## Dobla un hueso (para poses hechas a mano, como el "6-7" de Mostro).
func doblar(hueso: String, eje: Vector3, angulo: float) -> void:
	_doblar(hueso, eje, angulo)


## Silueta: todo el cuerpo negro y sin luz, para no revelar quién es.
func silueta(activa: bool) -> void:
	var negro: StandardMaterial3D = null
	if activa:
		negro = StandardMaterial3D.new()
		negro.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		negro.albedo_color = Color(0.01, 0.01, 0.012)
	for nodo: Node in _modelo.find_children("*", "MeshInstance3D", true, false):
		(nodo as MeshInstance3D).material_override = negro


## Pistola en la mano derecha (para la pose final de la presentación de Mostro).
func sacar_pistola() -> Node3D:
	if _arma_mano:
		_arma_mano.visible = true
		return _arma_mano
	var datos: Array = TIPOS[tipo].get("pistola", [Vector3(-0.02, 0.09, 0.03), Vector3(0, 90, 90)])
	_arma_mano = _poner_pistola("Wrist.R", datos[0] as Vector3, datos[1] as Vector3)
	_enderezar_pistola(_arma_mano)
	return _arma_mano


## En la mano de Mixamo la pistola quedaba acostada, atravesando la palma: se gira
## 90° sobre el cañón para que la empuñadura quede dentro de la mano.
func _enderezar_pistola(arma: Node3D) -> void:
	if TIPOS[tipo].get("mixamo", false):
		arma.rotate_object_local(Vector3.RIGHT, PI * 0.5)


func morir() -> void:
	_base = ""
	_anim.active = true
	_anim.play(_completa("Death"), 0.1)


func mano_armada(activa: bool) -> void:
	if _arma_mano:
		_arma_mano.visible = activa
		_arma_cadera.visible = not activa


func boca_arma() -> Vector3:
	return _boca.global_position if _boca else global_position + Vector3.UP * 1.3


func _al_terminar(nombre: StringName) -> void:
	if _base != "" and String(nombre) != _completa(_base):
		_anim.play(_completa(_base), 0.15)


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


## Pone un objeto largo (palo, espada) en la mano: entra por la palma y apunta en
## `direccion` (en el mundo), según la pose que tenga la mano en este momento.
## Después sigue a la mano en cada animación. El objeto debe ir a lo largo de su +Y.
func sostener(objeto: Node3D, direccion: Vector3, hueso: String = "Wrist.R") -> void:
	if _anim.active:
		_anim.advance(0.0)   # Que la pose de la animación ya esté puesta.
	_esqueleto.force_update_all_bone_transforms()
	var metros: Node3D = adjuntar(hueso)
	metros.add_child(objeto)
	var i: int = _esqueleto.find_bone(_hueso(hueso))
	var mano: Transform3D = _esqueleto.global_transform * _esqueleto.get_bone_global_pose(i)
	var dedos: Vector3 = mano.basis.y.normalized()
	var palma: Vector3 = mano.origin + dedos * 0.06
	var y: Vector3 = direccion.normalized()
	var x: Vector3 = y.cross(Vector3.UP if absf(y.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT).normalized()
	var deseado := Transform3D(Basis(x, y, x.cross(y)), palma - y * 0.1)
	# Relativo al hueso, sin esperar a que el nodo del hueso se actualice.
	var a_hueso: Transform3D = Transform3D(mano.basis.orthonormalized(), mano.origin).affine_inverse() * deseado
	var hueso_a_metros: Transform3D = metros.transform
	objeto.transform = hueso_a_metros.affine_inverse() * a_hueso


## Estocada baja hecha a mano (los paquetes no la traen): pierna derecha adelante,
## torso inclinado y el brazo derecho estirado hacia abajo y al frente.
## `ajustes` permite cambiar ángulos para probar: {"hueso": [eje, ángulo]}.
const POSE_ESTOCADA: Array = [
	["UpperLeg.R", Vector3.RIGHT, -0.75],
	["LowerLeg.R", Vector3.RIGHT, 0.7],
	["UpperLeg.L", Vector3.RIGHT, 0.45],
	["LowerLeg.L", Vector3.RIGHT, 0.35],
	["Abdomen", Vector3.RIGHT, 0.3],
	["Chest", Vector3.RIGHT, 0.15],
	["UpperArm.R", Vector3.RIGHT, -0.9],
	["UpperArm.R", Vector3.FORWARD, -0.25],
	["LowerArm.R", Vector3.RIGHT, -0.25],
	["UpperArm.L", Vector3.RIGHT, 0.5],
]


func pose_estocada(pose: Array = POSE_ESTOCADA) -> void:
	posar("Idle_Neutral", 0.0)
	_anim.active = false   # Si no, el reproductor vuelve a poner la animación encima.
	for p: Array in pose:
		_doblar(p[0] as String, p[1] as Vector3, p[2] as float)


## Hacia adelante y un poco arriba, como se sostiene un sable en guardia.
func adelante_arriba() -> Vector3:
	return (-global_basis.z * 0.8 + Vector3.UP * 0.6).normalized()


## Velocidad de las animaciones (1 = normal; menos = cámara lenta).
func velocidad(v: float) -> void:
	_anim.speed_scale = v


## Nodo pegado a un hueso, en metros normales (para la espada de Elcacas, el palo de Polo...).
func adjuntar(hueso: String) -> Node3D:
	return _adjunto(hueso)


## El esqueleto de estos modelos viene escalado 100 veces. El nodo intermedio lo
## compensa para que lo que se le cuelgue use metros normales.
func _adjunto(hueso: String) -> Node3D:
	var a := BoneAttachment3D.new()
	a.bone_name = _hueso(hueso)
	_esqueleto.add_child(a)
	var metros := Node3D.new()
	# Compensa la escala del esqueleto (100 en los de Quaternius, 1 en los cabezones).
	var escala_esqueleto: float = _esqueleto.global_basis.get_scale().x / maxf(global_basis.get_scale().x, 0.0001)
	metros.scale = Vector3.ONE / maxf(escala_esqueleto, 0.0001)
	a.add_child(metros)
	return metros


## Cuelga una pistola de un hueso, pero ubicada con coordenadas del cuerpo (x a la
## derecha, y arriba, -z adelante) en la pose de reposo. Sirve cuando los ejes del
## hueso son raros, como la cadera de Mixamo.
func _poner_en_cuerpo(hueso: String, pos: Vector3, giro: Vector3) -> Node3D:
	var arma: Node3D = _poner_pistola(hueso, Vector3.ZERO, Vector3.ZERO)
	var metros := arma.get_parent() as Node3D
	var i: int = _esqueleto.find_bone(_hueso(hueso))
	var esqueleto_en_cuerpo: Transform3D = global_transform.affine_inverse() * _esqueleto.global_transform
	var hueso_en_cuerpo: Transform3D = esqueleto_en_cuerpo * _esqueleto.get_bone_global_rest(i) * metros.transform
	var giro_rad: Vector3 = giro * (PI / 180.0)
	var deseado := Transform3D(Basis.from_euler(giro_rad).scaled(Vector3.ONE * 0.13), pos)
	arma.transform = hueso_en_cuerpo.affine_inverse() * deseado
	return arma


func _poner_pistola(hueso: String, pos: Vector3, giro: Vector3) -> Node3D:
	var escena: PackedScene = load("res://modelos/pistola.glb")
	var arma := escena.instantiate() as Node3D
	var adjunto: Node3D = _adjunto(hueso)
	adjunto.add_child(arma)
	arma.position = pos
	arma.rotation_degrees = giro
	arma.scale = Vector3.ONE * 0.13
	return arma

