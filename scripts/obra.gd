class_name Obra
extends Interactuable
## Cuadro, escultura u objeto expuesto. Al robar un cuadro queda el marco vacío en
## la pared: esa ausencia es la crítica del juego, así que se queda en la sala.

var datos: Dictionary = {}
var robada: bool = false
var _contenido: Node3D
var _placa: Label3D


func configurar(info: Dictionary) -> void:
	datos = info
	_contenido = Node3D.new()
	add_child(_contenido)
	var tipo: String = info.get("tipo", "pintura")
	if tipo == "pintura":
		_armar_cuadro()
	else:
		_armar_pieza(tipo)
	duracion = 3.0 if tipo == "pintura" else 4.0


func disponible(_j: Jugador) -> bool:
	return not robada and Juego.esta_en_lista(datos["id"])


func prompt(_j: Jugador) -> String:
	if robada:
		return ""
	if Juego.esta_en_lista(datos["id"]):
		return "[F] Llevarse «%s»" % datos["titulo"]
	return "%s. No está en la agenda." % _ficha_corta()


func completar(_j: Jugador) -> void:
	robada = true
	_contenido.visible = false
	Sfx.plano(get_parent(), "descolgar", -5.0)
	_placa.text = "ESTA OBRA YA NO\nPUEDE SER VISTA"
	_placa.modulate = Color(0.75, 0.1, 0.08)
	for hijo: Node in get_children():
		if hijo is CollisionShape3D:
			(hijo as CollisionShape3D).set_deferred("disabled", true)
	Juego.registrar_robo(datos)


func _ficha_corta() -> String:
	return "%s, de %s" % [datos["titulo"], datos["autor"]]


func _armar_cuadro() -> void:
	var tam: Vector2 = datos["tam"]
	var mat_marco := StandardMaterial3D.new()
	mat_marco.albedo_color = Color("3a2a1c")
	var ancho: float = tam.x + 0.16
	var alto: float = tam.y + 0.16
	for liston: Array in [
		[Vector3(ancho, 0.08, 0.07), Vector3(0, tam.y * 0.5 + 0.04, 0.035)],
		[Vector3(ancho, 0.08, 0.07), Vector3(0, -tam.y * 0.5 - 0.04, 0.035)],
		[Vector3(0.08, alto, 0.07), Vector3(-tam.x * 0.5 - 0.04, 0, 0.035)],
		[Vector3(0.08, alto, 0.07), Vector3(tam.x * 0.5 + 0.04, 0, 0.035)],
	]:
		var m := MeshInstance3D.new()
		var caja := BoxMesh.new()
		caja.size = liston[0]
		m.mesh = caja
		m.position = liston[1]
		m.material_override = mat_marco
		add_child(m)

	var lienzo := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = tam
	lienzo.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _textura()
	mat.roughness = 0.75
	lienzo.material_override = mat
	lienzo.position.z = 0.04
	_contenido.add_child(lienzo)

	agregar_colision(Vector3(tam.x + 0.16, tam.y + 0.16, 0.12), Vector3(0, 0, 0.06))
	_crear_placa(Vector3(tam.x * 0.5 + 0.42, -0.45, 0.02))


func _armar_pieza(tipo: String) -> void:
	var tam: Vector2 = datos["tam"]
	var paleta: Array = datos["paleta"]
	var color_a := Color(paleta[0] as String)
	var color_b := Color(paleta[1] as String)
	if tipo == "objeto":
		# Custodia: pie, vara y sol de oro con esmeraldas.
		_pieza(CylinderMesh.new(), Vector3(0.3, 0.04, 0.3), Vector3(0, 0.02, 0), color_a, true)
		_pieza(CylinderMesh.new(), Vector3(0.05, 0.25, 0.05), Vector3(0, 0.17, 0), color_a, true)
		_pieza(SphereMesh.new(), Vector3(0.42, 0.42, 0.09), Vector3(0, 0.5, 0), color_a, true)
		for i: int in 16:
			var ang: float = TAU * i / 16.0
			_pieza(SphereMesh.new(), Vector3.ONE * 0.05, Vector3(cos(ang) * 0.17, 0.5 + sin(ang) * 0.17, 0.04), color_b, true)
	else:
		# Escultura: planos metálicos encajados, reconocibles aunque sean provisionales.
		var semilla := RandomNumberGenerator.new()
		semilla.seed = hash(datos["id"])
		for i: int in 7:
			var escala := Vector3(semilla.randf_range(0.12, 0.5), semilla.randf_range(0.1, 0.45), semilla.randf_range(0.05, 0.3))
			var pos := Vector3(semilla.randf_range(-0.22, 0.22), 0.15 + tam.y * 0.7 * float(i) / 7.0, semilla.randf_range(-0.14, 0.14))
			var pieza := _pieza(BoxMesh.new(), escala, pos, color_a if i % 2 == 0 else color_b, false)
			pieza.rotation = Vector3(semilla.randf_range(-0.5, 0.5), semilla.randf_range(-1.5, 1.5), semilla.randf_range(-0.5, 0.5))
	agregar_colision(Vector3(tam.x, tam.y, tam.x), Vector3(0, tam.y * 0.5, 0))
	_crear_placa(Vector3(0, -0.28, 0.46))


func _pieza(malla: PrimitiveMesh, escala: Vector3, pos: Vector3, color: Color, brilla: bool) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = malla
	m.scale = escala
	m.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.85
	mat.roughness = 0.3 if brilla else 0.5
	m.material_override = mat
	_contenido.add_child(m)
	return m


func _crear_placa(pos: Vector3) -> void:
	_placa = Label3D.new()
	var anio: String = datos["anio"]
	_placa.text = "%s\n%s%s" % [datos["titulo"], datos["autor"], "" if anio.is_empty() else "\n" + anio]
	_placa.font_size = 26
	_placa.pixel_size = 0.0022
	_placa.outline_size = 0
	_placa.modulate = Color(0.12, 0.12, 0.13)
	_placa.double_sided = false
	_placa.width = 300.0
	_placa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_placa.position = pos
	add_child(_placa)


func _textura() -> Texture2D:
	var id: String = datos["id"]
	for ext: String in ["jpg", "png", "jpeg", "webp"]:
		var ruta: String = "res://arte/%s.%s" % [id, ext]
		if ResourceLoader.exists(ruta):
			var tex: Texture2D = load(ruta)
			return tex
	return _textura_provisional()


## Composición abstracta con la paleta de la obra, hasta tener la imagen real.
func _textura_provisional() -> ImageTexture:
	var paleta: Array = datos["paleta"]
	var tam: Vector2 = datos["tam"]
	var ancho: int = int(tam.x * 96.0)
	var alto: int = int(tam.y * 96.0)
	var img := Image.create(ancho, alto, false, Image.FORMAT_RGB8)
	img.fill(Color(paleta[0] as String))
	var azar := RandomNumberGenerator.new()
	azar.seed = hash(datos["id"])
	for i: int in 26:
		var color := Color(paleta[azar.randi_range(0, paleta.size() - 1)] as String).darkened(azar.randf_range(0.0, 0.3))
		var w: int = azar.randi_range(ancho / 12, ancho / 2)
		var h: int = azar.randi_range(alto / 12, alto / 2)
		img.fill_rect(Rect2i(azar.randi_range(-w / 2, ancho - w / 2), azar.randi_range(-h / 2, alto - h / 2), w, h), color)
	return ImageTexture.create_from_image(img)
