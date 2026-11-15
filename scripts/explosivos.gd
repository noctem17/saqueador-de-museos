class_name Explosivos
extends RefCounted
## Lo que vuela y explota en la pelea contra el ELIHCOTERO:
##  - explosion(): bola de fuego, luz, humo, sonido y temblor de cámara.
##  - Cohete: lo dispara Polo. Va recto; si toca el helicóptero le hace daño.
##  - Misil: lo dispara el helicóptero hacia donde está Polo. Antes de caer marca
##    un círculo rojo en el piso, para que dé tiempo de quitarse.

const RADIO_MISIL: float = 3.2     ## Si Polo está más cerca que esto, lo alcanza.
const DANO_MISIL: int = 34         ## Tres impactos y Polo cae (100 de vida).


## Bola de fuego que crece y se apaga. "tam" 1 = misil; 3 = el helicóptero entero.
static func explosion(padre: Node, pos: Vector3, tam: float = 1.0, con_sonido: bool = true) -> void:
	var raiz := Node3D.new()
	padre.add_child(raiz)
	raiz.global_position = pos
	var bola := MeshInstance3D.new()
	var e := SphereMesh.new()
	e.radius = 1.0
	e.height = 2.0
	e.radial_segments = 12
	e.rings = 6
	bola.mesh = e
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.0, 0.75, 0.3, 1.0)
	bola.material_override = m
	bola.scale = Vector3.ONE * 0.3 * tam
	raiz.add_child(bola)
	var luz := OmniLight3D.new()
	luz.light_color = Color("ff9a3c")
	luz.light_energy = 10.0
	luz.omni_range = 9.0 * tam
	raiz.add_child(luz)
	var t := raiz.create_tween().set_parallel()
	t.tween_property(bola, "scale", Vector3.ONE * 2.6 * tam, 0.45).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t.tween_property(m, "albedo_color", Color(0.35, 0.3, 0.28, 0.0), 0.9).set_delay(0.15)
	t.tween_property(luz, "light_energy", 0.0, 0.7)
	t.chain().tween_callback(raiz.queue_free)
	if not con_sonido:
		return
	Sfx.en(padre, "explosion", pos, 2.0 if tam > 1.5 else -2.0, 80.0)
	# Quien se haya anotado en el grupo "temblor" (la escena) sacude la cámara.
	padre.get_tree().call_group("temblor", "temblar", 0.5 * tam)


## Dispara un cohete desde "desde" hacia "direccion".
static func lanzar_cohete(padre: Node, desde: Vector3, direccion: Vector3) -> void:
	var c := Cohete.new()
	c.direccion = direccion.normalized()
	c.position = desde
	padre.add_child(c)


## Lanza un misil que cae en "destino" después de "tiempo" segundos.
static func lanzar_misil(padre: Node, desde: Vector3, destino: Vector3, tiempo: float) -> void:
	var m := Misil.new()
	m.desde = desde
	m.destino = destino
	m.tiempo = tiempo
	m.position = desde
	padre.add_child(m)


## Cohete del lanzacohetes de Polo.
class Cohete:
	extends Node3D
	const VELOCIDAD: float = 48.0
	const ALCANCE: float = 140.0
	var direccion: Vector3 = Vector3.FORWARD
	var _recorrido: float = 0.0

	func _ready() -> void:
		add_to_group("proyectiles")
		var cuerpo := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.06
		c.bottom_radius = 0.06
		c.height = 0.6
		cuerpo.mesh = c
		var m := StandardMaterial3D.new()
		m.albedo_color = Color("5a6330")
		cuerpo.material_override = m
		cuerpo.rotation.x = -PI * 0.5   # El cilindro queda acostado, apuntando hacia adelante (-Z).
		add_child(cuerpo)
		var fuego := OmniLight3D.new()
		fuego.position.z = 0.4
		fuego.light_color = Color("ffb04a")
		fuego.light_energy = 3.0
		fuego.omni_range = 4.0
		add_child(fuego)
		var llama := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.12
		s.height = 0.4
		llama.mesh = s
		var mf := StandardMaterial3D.new()
		mf.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mf.albedo_color = Color("ffd27a")
		llama.material_override = mf
		llama.position.z = 0.4
		add_child(llama)
		look_at(global_position + direccion)

	func _physics_process(delta: float) -> void:
		var paso: float = VELOCIDAD * delta
		global_position += direccion * paso
		_recorrido += paso
		for blanco: Node in get_tree().get_nodes_in_group("blanco_cohete"):
			if blanco.call("toca", global_position):
				blanco.call("recibir_cohete", global_position)
				_explotar()
				return
		if global_position.y < 0.05 or _recorrido > ALCANCE:
			_explotar()

	func _explotar() -> void:
		Explosivos.explosion(get_parent(), global_position, 1.0)
		queue_free()


## Misil del helicóptero: va de "desde" a "destino" en "tiempo" segundos, en curva.
class Misil:
	extends Node3D
	var desde: Vector3
	var destino: Vector3
	var tiempo: float = 1.8
	var _t: float = 0.0
	var _marca: MeshInstance3D
	var _mat_marca: StandardMaterial3D

	func _ready() -> void:
		add_to_group("proyectiles")
		var cuerpo := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = 0.12
		c.height = 0.8
		cuerpo.mesh = c
		var m := StandardMaterial3D.new()
		m.albedo_color = Color("b9babf")
		m.metallic = 0.6
		cuerpo.material_override = m
		cuerpo.rotation.x = -PI * 0.5
		add_child(cuerpo)
		var luz := OmniLight3D.new()
		luz.light_color = Color("ff3a2a")
		luz.light_energy = 3.0
		luz.omni_range = 4.0
		add_child(luz)
		# Círculo rojo en el piso donde va a caer.
		_marca = MeshInstance3D.new()
		var disco := CylinderMesh.new()
		disco.top_radius = Explosivos.RADIO_MISIL
		disco.bottom_radius = Explosivos.RADIO_MISIL
		disco.height = 0.02
		disco.radial_segments = 32
		_marca.mesh = disco
		_mat_marca = StandardMaterial3D.new()
		_mat_marca.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat_marca.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat_marca.albedo_color = Color(1.0, 0.1, 0.05, 0.35)
		_marca.material_override = _mat_marca
		get_parent().add_child.call_deferred(_marca)
		_marca.position = Vector3(destino.x, 0.03, destino.z)
		global_position = desde
		Sfx.en(get_parent(), "misil", desde, -2.0, 60.0)

	func _process(delta: float) -> void:
		_t += delta / tiempo
		var p: Vector3 = desde.lerp(destino, _t)
		p.y += sin(_t * PI) * 2.0   # Un poco de curva.
		if not p.is_equal_approx(global_position):
			look_at_from_position(p, p + (p - global_position), Vector3.UP)
		global_position = p
		# El círculo late cada vez más rápido.
		_mat_marca.albedo_color.a = 0.25 + 0.25 * absf(sin(_t * _t * 30.0))
		if _t >= 1.0:
			Explosivos.explosion(get_parent(), destino + Vector3.UP * 0.5, 1.0)
			for j: Node in get_tree().get_nodes_in_group("jugador"):
				var polo := j as Jugador
				if polo and Vector2(polo.global_position.x - destino.x, polo.global_position.z - destino.z).length() < Explosivos.RADIO_MISIL:
					polo.recibir_dano(Explosivos.DANO_MISIL)
			_marca.queue_free()
			queue_free()

	func _exit_tree() -> void:
		if is_instance_valid(_marca):
			_marca.queue_free()
