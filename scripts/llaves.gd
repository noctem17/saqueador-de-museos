class_name Llaves
extends RefCounted
## El candado de la Sala 1 y sus tres llaves (corazón, estrella y tigre). Se usan
## como Llaves.Llave y Llaves.Candado desde mision.gd, que los pone en el mapa.
##
## Cada llave está siempre en el mismo sitio y escondida de una forma distinta:
## en el agua de la fuente, en un cajón o detrás de un ladrillo flojo. Al tomarla
## queda anotada en Juego.llaves; con las tres, el candado deja abrir la reja.

## Datos de cada llave: el símbolo que se ve en el candado, la agenda y la llave.
const DATOS: Dictionary = {
	"corazon": {"nombre": "del corazón", "simbolo": "♥", "color": Color("c62a2a")},
	"estrella": {"nombre": "de la estrella", "simbolo": "★", "color": Color("e0b52a")},
	"tigre": {"nombre": "del tigre", "simbolo": "TIGRE", "color": Color("e07a1f")},
}


## Llave de latón con su dije de color. Se arma con figuras simples.
static func modelo_llave(id: String) -> Node3D:
	var raiz := Node3D.new()
	var laton := StandardMaterial3D.new()
	laton.albedo_color = Color("d9b04a")
	laton.metallic = 0.6
	laton.roughness = 0.3
	laton.emission_enabled = true
	laton.emission = Color("d9b04a")
	laton.emission_energy_multiplier = 0.25
	var aro := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 0.018
	toro.outer_radius = 0.03
	aro.mesh = toro
	aro.material_override = laton
	aro.position.x = -0.06
	raiz.add_child(aro)
	var vara := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(0.1, 0.012, 0.012)
	vara.mesh = caja
	vara.material_override = laton
	vara.position.x = 0.02
	raiz.add_child(vara)
	for dx: float in [0.05, 0.065]:
		var diente := MeshInstance3D.new()
		var d := BoxMesh.new()
		d.size = Vector3(0.008, 0.012, 0.025)
		diente.mesh = d
		diente.material_override = laton
		diente.position = Vector3(dx, 0, 0.016)
		raiz.add_child(diente)
	var dije := Label3D.new()
	dije.text = DATOS[id]["simbolo"]
	dije.font_size = 64 if id != "tigre" else 28
	dije.pixel_size = 0.0012
	dije.modulate = DATOS[id]["color"]
	dije.outline_size = 6
	dije.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	dije.position = Vector3(-0.06, 0.06, 0)
	raiz.add_child(dije)
	return raiz


## Una llave escondida. "escondite" decide cómo se ve el sitio:
## "agua" (fondo de la fuente), "cajon" (escritorio) o "ladrillo" (muro de la celda).
class Llave:
	extends Interactuable
	var id: String = ""
	var escondite: String = ""
	var _llave: Node3D
	var _tapa: Node3D   # Lo que se mueve al sacarla: el cajón o el ladrillo.

	func configurar(id_llave: String, tipo: String) -> void:
		id = id_llave
		escondite = tipo
		duracion = 1.2 if tipo == "agua" else 1.6
		_llave = Llaves.modelo_llave(id)
		add_child(_llave)
		match tipo:
			"agua":
				_llave.rotation = Vector3(-PI * 0.5, 0.4, 0)
				_llave.position.y = 0.01
				agregar_colision(Vector3(0.4, 0.2, 0.4), Vector3(0, 0.08, 0))
			"cajon":
				_tapa = _caja(Vector3(0.5, 0.16, 0.05), Color("4a3524"))
				var tirador := _caja(Vector3(0.14, 0.025, 0.03), Color("b8bcc2"), _tapa)
				tirador.position.z = 0.04
				_llave.visible = false
				_llave.position = Vector3(0, 0.02, -0.15)
				agregar_colision(Vector3(0.55, 0.2, 0.12), Vector3(0, 0, 0.02))
			"ladrillo":
				# El ladrillo sobresale un poco, con la junta oscura alrededor.
				var junta := _caja(Vector3(0.3, 0.16, 0.02), Color("1e1712"))
				junta.position.z = -0.02
				_tapa = _caja(Vector3(0.26, 0.12, 0.12), Color("a8633f"))
				_tapa.position.z = 0.05
				_llave.visible = false
				_llave.position = Vector3(0, 0, -0.03)
				_pistas_tigre()
				agregar_colision(Vector3(0.35, 0.2, 0.2), Vector3(0, 0, 0.07))

	func _caja(tam: Vector3, color: Color, padre: Node3D = null) -> MeshInstance3D:
		var m := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = tam
		m.mesh = b
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.8
		m.material_override = mat
		(padre if padre else self).add_child(m)
		return m

	## Pistas para encontrar el ladrillo: zarpazos naranjas de tigre pintados en el
	## muro, polvo de ladrillo en el piso y una vela encendida que alumbra el sitio.
	func _pistas_tigre() -> void:
		var pintura := StandardMaterial3D.new()
		pintura.albedo_color = Color("e07a1f")
		pintura.emission_enabled = true
		pintura.emission = Color("e07a1f")
		pintura.emission_energy_multiplier = 0.6
		for i: int in 3:
			var raya := MeshInstance3D.new()
			var b := BoxMesh.new()
			b.size = Vector3(0.035, 0.55, 0.01)
			raya.mesh = b
			raya.material_override = pintura
			raya.position = Vector3(-0.1 + 0.1 * i, 0.5, -0.02)
			raya.rotation.z = 0.35
			add_child(raya)
		for i: int in 5:
			var polvo := _caja(Vector3(0.04, 0.025, 0.04), Color("8a4f33"))
			polvo.position = Vector3(-0.12 + 0.06 * i, -0.335, 0.1 + 0.04 * (i % 2))
			polvo.rotation.y = i * 0.7
		# Vela en el piso, al pie del muro.
		var vela := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.025
		c.bottom_radius = 0.025
		c.height = 0.12
		vela.mesh = c
		var cera := StandardMaterial3D.new()
		cera.albedo_color = Color("efe6cf")
		vela.material_override = cera
		vela.position = Vector3(0.3, -0.29, 0.15)
		add_child(vela)
		var llama := MeshInstance3D.new()
		var e := SphereMesh.new()
		e.radius = 0.015
		e.height = 0.04
		llama.mesh = e
		var fuego := StandardMaterial3D.new()
		fuego.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fuego.albedo_color = Color("ffb347")
		llama.material_override = fuego
		llama.position = Vector3(0.3, -0.21, 0.15)
		add_child(llama)
		var luz := OmniLight3D.new()
		luz.light_color = Color("ff9a40")
		luz.light_energy = 1.2
		luz.omni_range = 2.2
		luz.position = Vector3(0.3, -0.1, 0.25)
		add_child(luz)

	func prompt(_j: Jugador) -> String:
		match escondite:
			"cajon":
				return "[F] Revisar el cajón del escritorio"
			"ladrillo":
				return "[F] Sacar el ladrillo flojo"
		return "[F] Sacar la llave %s del agua" % Llaves.DATOS[id]["nombre"]

	func completar(_j: Jugador) -> void:
		collision_layer = 0
		Sfx.plano(get_parent(), "moneda", -8.0)
		if _tapa:
			# El cajón se abre o el ladrillo sale, se ve la llave un momento y se la lleva.
			_llave.visible = true
			var t := create_tween()
			t.tween_property(_tapa, "position:z", _tapa.position.z + 0.3, 0.35)
			t.tween_interval(0.5)
			t.tween_callback(_llave.hide)
		else:
			_llave.hide()
		Juego.tomar_llave(id)


## Reja de la Sala 1 con un candado de tres cerraduras. Mira hacia +x (el vestíbulo).
class Candado:
	extends Interactuable
	signal abierto
	const ANCHO: float = 2.4
	const ALTO: float = 2.7
	var _hojas: Array[Node3D] = []
	var _solido: CollisionShape3D
	var _ojos: Dictionary = {}   # id de llave -> Label3D de su cerradura.
	var _abierta: bool = false

	func _ready() -> void:
		duracion = 2.5
		var hierro := StandardMaterial3D.new()
		hierro.albedo_color = Color("1d1b19")
		hierro.metallic = 0.5
		hierro.roughness = 0.5
		# Dos hojas que giran sobre sus bisagras, a lado y lado de la puerta.
		for lado: float in [-1.0, 1.0]:
			var bisagra := Node3D.new()
			bisagra.position.z = lado * ANCHO * 0.5
			add_child(bisagra)
			_hojas.append(bisagra)
			var n: int = 9
			for i: int in n + 1:
				var z: float = -lado * (ANCHO * 0.5) * float(i) / n
				_barra(bisagra, Vector3(0.03, ALTO, 0.03), Vector3(0, ALTO * 0.5, z), hierro)
			for y: float in [0.08, 1.1, ALTO - 0.06]:
				_barra(bisagra, Vector3(0.04, 0.05, ANCHO * 0.5), Vector3(0, y, -lado * ANCHO * 0.25), hierro)
		# La caja del candado, con sus tres cerraduras.
		var placa := StandardMaterial3D.new()
		placa.albedo_color = Color("6e5a2c")
		placa.metallic = 0.7
		placa.roughness = 0.35
		_barra(self, Vector3(0.08, 0.5, 0.36), Vector3(0.06, 1.1, 0), placa)
		var ids: Array = ["corazon", "estrella", "tigre"]
		for i: int in 3:
			var ojo := Label3D.new()
			ojo.text = Llaves.DATOS[ids[i]]["simbolo"]
			ojo.font_size = 48 if ids[i] != "tigre" else 20
			ojo.pixel_size = 0.0018
			ojo.outline_size = 0
			ojo.modulate = Color(0.15, 0.13, 0.1)
			ojo.position = Vector3(0.105, 1.26 - 0.15 * i, 0)
			ojo.rotation.y = PI * 0.5
			add_child(ojo)
			_ojos[ids[i]] = ojo
		agregar_colision(Vector3(0.3, 0.6, 0.5), Vector3(0.1, 1.1, 0))
		# Cuerpo sólido que cierra la puerta mientras la reja esté cerrada.
		var cuerpo := StaticBody3D.new()
		cuerpo.collision_layer = Juego.CAPA_MUNDO
		cuerpo.collision_mask = 0
		_solido = CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = Vector3(0.1, ALTO, ANCHO)
		_solido.shape = forma
		_solido.position.y = ALTO * 0.5
		cuerpo.add_child(_solido)
		add_child(cuerpo)
		Juego.llaves_cambio.connect(_pintar_ojos)
		_pintar_ojos()

	func _barra(padre: Node3D, tam: Vector3, pos: Vector3, mat: Material) -> void:
		var m := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = tam
		m.mesh = b
		m.position = pos
		m.material_override = mat
		padre.add_child(m)

	## Cada cerradura se enciende con el color de su llave cuando Polo ya la tiene.
	func _pintar_ojos() -> void:
		for id: String in _ojos:
			var ojo: Label3D = _ojos[id]
			ojo.modulate = Llaves.DATOS[id]["color"] if id in Juego.llaves else Color(0.15, 0.13, 0.1)

	func disponible(_j: Jugador) -> bool:
		return not _abierta and Juego.llaves.size() >= 3

	func prompt(_j: Jugador) -> String:
		if _abierta:
			return ""
		if Juego.llaves.size() >= 3:
			return "[F] Abrir el candado con las tres llaves"
		var faltan: Array[String] = []
		for id: String in DATOS:
			if not id in Juego.llaves:
				faltan.append((DATOS[id]["nombre"] as String).trim_prefix("del ").trim_prefix("de la "))
		return "Candado de tres cerraduras. Faltan las llaves: %s" % ", ".join(faltan)

	func completar(_j: Jugador) -> void:
		abrir()

	func abrir() -> void:
		if _abierta:
			return
		_abierta = true
		collision_layer = 0
		_solido.set_deferred("disabled", true)
		Sfx.plano(get_parent(), "consola", -10.0)
		var t := create_tween().set_parallel()
		for i: int in _hojas.size():
			var lado: float = -1.0 if i == 0 else 1.0
			t.tween_property(_hojas[i], "rotation:y", lado * deg_to_rad(100.0), 1.4).set_trans(Tween.TRANS_SINE)
		Juego.aviso.emit("La reja de la Sala 1 está abierta")
		abierto.emit()
