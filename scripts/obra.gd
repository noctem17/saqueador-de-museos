class_name Obra
extends Interactuable
## Cuadro, escultura u objeto expuesto. Al robar una pieza queda el marco vacío en
## la pared o la vitrina vacía en su pedestal: esa ausencia es la crítica del juego,
## así que se queda en la sala.
##
## Los cuadros usan la imagen de res://arte/. Los objetos (pluma, poporo, camiseta...)
## se arman aquí con figuras simples; su foto real solo se ve al leerlos en el bolso.

const COLOR_PEDESTAL := Color("efeae0")

var datos: Dictionary = {}
var robada: bool = false
var bloqueada: bool = false   ## La espada, mientras su jaula esté cerrada.
var _contenido: Node3D
var _placa: Label3D
var _con_vitrina: bool = false
## Si está activo, el primer intento de llevársela no la roba: avisa con
## intento_robo (la espada de Bolívar: ahí aparece Elcacas).
var con_jefe: bool = false

signal intento_robo


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
	return not robada and not bloqueada and _se_puede_llevar()


## Lo de la agenda, y los extras opcionales (el cuadro del MAMBO).
func _se_puede_llevar() -> bool:
	return Juego.esta_en_lista(datos["id"]) or datos.get("opcional", false)


func prompt(_j: Jugador) -> String:
	if robada:
		return ""
	if bloqueada:
		return "%s. Encerrada en la jaula: la abre el reloj." % _ficha_corta()
	if Juego.esta_en_lista(datos["id"]):
		return "[F] Llevarse «%s»" % datos["titulo"]
	if datos.get("opcional", false):
		return "[F] Llevarse «%s» (extra, no está en la agenda)" % datos["titulo"]
	return "%s. No está en la agenda." % _ficha_corta()


func completar(_j: Jugador) -> void:
	if con_jefe:
		con_jefe = false
		intento_robo.emit()
		return
	robada = true
	_contenido.visible = false
	Sfx.plano(get_parent(), "descolgar", -5.0)
	if _con_vitrina:
		Sfx.en(get_parent(), "cristal", global_position + Vector3.UP * 0.5, -3.0, 25.0)
	_placa.text = "ESTA OBRA YA NO\nPUEDE SER VISTA"
	_placa.modulate = Color(0.75, 0.1, 0.08)
	for hijo: Node in get_children():
		if hijo is CollisionShape3D:
			(hijo as CollisionShape3D).set_deferred("disabled", true)
	Juego.registrar_robo(datos)


## Esconde la pieza sin robarla (Elcacas la toma de su pedestal).
func ocultar_pieza() -> void:
	_contenido.visible = false


func _ficha_corta() -> String:
	return "%s, de %s" % [datos["titulo"], datos["autor"]]


# ---------------------------------------------------------------- en la pared

func _armar_cuadro() -> void:
	var tam: Vector2 = _tam_segun_imagen(datos["tam"])
	var tela: bool = datos.get("tela", false)
	if tela:
		# Bandera: tela colgada de una varilla, sin marco.
		_malla(_cilindro(0.012, tam.x + 0.12), Vector3(0, tam.y * 0.5 + 0.03, 0.05), Vector3(0, 0, PI * 0.5), _metal(Color("8c8f94"), 0.4), self)
	else:
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
			_malla(_caja(liston[0]), liston[1], Vector3.ZERO, mat_marco, self)

	var quad := QuadMesh.new()
	quad.size = tam
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _textura()
	mat.roughness = 0.9 if tela else 0.75
	_malla(quad, Vector3(0, 0, 0.04), Vector3.ZERO, mat, _contenido)

	agregar_colision(Vector3(tam.x + 0.16, tam.y + 0.16, 0.12), Vector3(0, 0, 0.06))
	_crear_placa(Vector3(tam.x * 0.5 + 0.42, -0.45, 0.02))


## Con la imagen real, el cuadro toma su forma (ancho/alto) y conserva más o menos
## el mismo tamaño en la pared que tenía en el catálogo.
func _tam_segun_imagen(tam: Vector2) -> Vector2:
	var ruta: String = Catalogo.imagen(datos["id"])
	if ruta == "" or datos.get("tela", false):
		return tam
	var textura: Texture2D = load(ruta)
	var forma: float = float(textura.get_width()) / float(textura.get_height())
	var area: float = tam.x * tam.y
	var nuevo := Vector2(sqrt(area * forma), sqrt(area / forma))
	# Que quepa en la pared: máximo 2.6 m de ancho y 1.8 m de alto.
	var reducir: float = minf(1.0, minf(2.6 / nuevo.x, 1.8 / nuevo.y))
	return nuevo * reducir


# ---------------------------------------------------------------- en pedestal

## El origen es la cara de arriba del pedestal. La vitrina y el pedestal quedan
## aunque la pieza se la lleven.
func _armar_pieza(tipo: String) -> void:
	var modelo: String = datos.get("modelo", "")
	_pedestal(Vector3(1.4, 1.0, 0.7) if modelo == "espada" else Vector3(0.7, 1.0, 0.7))
	var vitrina := Vector3.ZERO   # Tamaño de la urna de vidrio; cero = sin vitrina.
	match modelo:
		"custodia":
			_custodia()
			vitrina = Vector3(0.6, 0.85, 0.5)
		"baligrafo":
			_baligrafo()
			vitrina = Vector3(0.55, 0.3, 0.4)
		"poporo":
			_poporo()
			vitrina = Vector3(0.45, 0.5, 0.45)
		"camiseta":
			_camiseta()
			vitrina = Vector3(0.66, 1.08, 0.5)
		"documento":
			_documento()
			vitrina = Vector3(0.6, 0.26, 0.5)
		"espada":
			_espada()
			vitrina = Vector3(1.3, 0.3, 0.55)
		_:
			if tipo == "escultura":
				_escultura()
	if vitrina != Vector3.ZERO:
		_vitrina(vitrina)
		_con_vitrina = true
	var alto: float = maxf(vitrina.y, (datos["tam"] as Vector2).y)
	if modelo == "espada":
		# Más grande que el bloque sólido que rodea el pedestal: así el rayo de
		# "usar" encuentra primero la espada (ver mapa_museo_nacional.gd).
		agregar_colision(Vector3(2.3, 1.6, 2.3), Vector3(0, 0.0, 0))
	else:
		agregar_colision(Vector3(0.7, alto, 0.7), Vector3(0, alto * 0.5, 0))
	_crear_placa(Vector3(0, -0.28, 0.36))


func _pedestal(tam: Vector3 = Vector3(0.7, 1.0, 0.7)) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLOR_PEDESTAL
	mat.roughness = 0.85
	_malla(_caja(tam), Vector3(0, -0.5, 0), Vector3.ZERO, mat, self)
	# Cuerpo sólido aparte: el jugador y los guardias no atraviesan el pedestal.
	var solido := StaticBody3D.new()
	solido.collision_layer = Juego.CAPA_MUNDO
	solido.collision_mask = 0
	var col := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam
	col.shape = forma
	col.position.y = -0.5
	solido.add_child(col)
	add_child(solido)


func _vitrina(tam: Vector3) -> void:
	var vidrio := StandardMaterial3D.new()
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidrio.albedo_color = Color(0.85, 0.93, 1.0, 0.12)
	vidrio.roughness = 0.05
	vidrio.metallic_specular = 1.0
	vidrio.cull_mode = BaseMaterial3D.CULL_DISABLED
	_malla(_caja(tam), Vector3(0, tam.y * 0.5 + 0.002, 0), Vector3.ZERO, vidrio, self)


## Espada de Bolívar acostada sobre un cojín de terciopelo: hoja, guarda y empuñadura
## doradas, y la vaina al lado.
func _espada() -> void:
	var terciopelo := StandardMaterial3D.new()
	terciopelo.albedo_color = Color("5a1218")
	terciopelo.roughness = 1.0
	_malla(_caja(Vector3(1.2, 0.06, 0.45)), Vector3(0, 0.03, 0), Vector3.ZERO, terciopelo, _contenido)
	var acero := _metal(Color("c8ccd2"), 0.15)
	var oro := _metal(Color("d4a73a"), 0.3, 0.35)
	var cuero := StandardMaterial3D.new()
	cuero.albedo_color = Color("2a1a12")
	cuero.roughness = 0.7
	var y: float = 0.085
	# Hoja, levemente curva: dos tramos.
	_malla(_caja(Vector3(0.5, 0.008, 0.032)), Vector3(-0.05, y, 0.06), Vector3(0, 0.02, 0), acero, _contenido)
	_malla(_caja(Vector3(0.36, 0.008, 0.028)), Vector3(-0.47, y, 0.072), Vector3(0, 0.08, 0), acero, _contenido)
	# Guarda, empuñadura y pomo.
	_malla(_caja(Vector3(0.025, 0.02, 0.16)), Vector3(0.21, y, 0.06), Vector3.ZERO, oro, _contenido)
	_malla(_caja(Vector3(0.13, 0.028, 0.03)), Vector3(0.29, y, 0.06), Vector3.ZERO, oro, _contenido)
	_malla(_esfera(0.022), Vector3(0.37, y, 0.06), Vector3.ZERO, oro, _contenido)
	# Arco de la guarda que protege la mano.
	_malla(_caja(Vector3(0.16, 0.012, 0.012)), Vector3(0.29, y, 0.1), Vector3.ZERO, oro, _contenido)
	# Vaina al lado.
	_malla(_caja(Vector3(0.82, 0.026, 0.045)), Vector3(-0.2, y, -0.1), Vector3(0, 0.04, 0), cuero, _contenido)
	_malla(_caja(Vector3(0.08, 0.03, 0.05)), Vector3(0.18, y, -0.098), Vector3.ZERO, oro, _contenido)
	_malla(_caja(Vector3(0.07, 0.03, 0.05)), Vector3(-0.59, y, -0.13), Vector3.ZERO, oro, _contenido)


## Custodia de La Lechuga: pie, vara y sol de oro con esmeraldas.
func _custodia() -> void:
	var oro := _metal(Color(datos["paleta"][0] as String), 0.3, 0.18)
	var esmeralda := _metal(Color(datos["paleta"][1] as String), 0.2, 0.25)
	_malla(_cilindro(0.15, 0.04), Vector3(0, 0.02, 0), Vector3.ZERO, oro)
	_malla(_cilindro(0.025, 0.25), Vector3(0, 0.17, 0), Vector3.ZERO, oro)
	var sol := _malla(_esfera(0.21), Vector3(0, 0.5, 0), Vector3.ZERO, oro)
	sol.scale.z = 0.2
	for i: int in 16:
		var ang: float = TAU * i / 16.0
		_malla(_esfera(0.025), Vector3(cos(ang) * 0.17, 0.5 + sin(ang) * 0.17, 0.04), Vector3.ZERO, esmeralda)


## Escultura: planos metálicos encajados, al estilo de Bursztyn o Negret.
func _escultura() -> void:
	var tam: Vector2 = datos["tam"]
	var ruta: String = Catalogo.imagen(datos["id"])
	if ruta != "":
		# La foto de la escultura, recortada (PNG con fondo transparente), siempre de
		# frente al que la mira.
		var foto := Sprite3D.new()
		foto.texture = load(ruta)
		foto.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		foto.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		foto.shaded = true
		foto.double_sided = true
		foto.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var alto: float = tam.y * 0.85
		foto.pixel_size = alto / float(foto.texture.get_height())
		foto.position.y = alto * 0.5
		_contenido.add_child(foto)
		return
	var paleta: Array = datos["paleta"]
	var semilla := RandomNumberGenerator.new()
	semilla.seed = hash(datos["id"])
	for i: int in 7:
		var lado := Vector3(semilla.randf_range(0.12, 0.5), semilla.randf_range(0.1, 0.45), semilla.randf_range(0.05, 0.3))
		var pos := Vector3(semilla.randf_range(-0.22, 0.22), 0.15 + tam.y * 0.7 * float(i) / 7.0, semilla.randf_range(-0.14, 0.14))
		var giro := Vector3(semilla.randf_range(-0.5, 0.5), semilla.randf_range(-1.5, 1.5), semilla.randf_range(-0.5, 0.5))
		_malla(_caja(lado), pos, giro, _metal(Color(paleta[i % 2] as String), 0.5))


## El Balígrafo: cartucho de bala de latón con punta de esfero, sobre su base de madera.
func _baligrafo() -> void:
	var laton := _metal(Color("d9b04a"), 0.25, 0.15)
	var negro := _metal(Color("1b1b1d"), 0.6)
	negro.metallic = 0.0
	var madera := StandardMaterial3D.new()
	madera.albedo_color = Color("7a4a26")
	madera.roughness = 0.7
	var grupo := Node3D.new()
	grupo.scale = Vector3.ONE * 1.6   # Un poco más grande que la real (14 cm) para que se vea.
	grupo.rotation.y = 0.3
	_contenido.add_child(grupo)
	_malla(_caja(Vector3(0.24, 0.035, 0.07)), Vector3(0, 0.0175, 0), Vector3.ZERO, madera, grupo)
	var acostado := Vector3(0, 0, PI * 0.5)
	_malla(_cilindro(0.012, 0.11), Vector3(0.02, 0.05, 0), acostado, laton, grupo)        # Vaina.
	_malla(_cilindro(0.0135, 0.008), Vector3(0.078, 0.05, 0), acostado, laton, grupo)     # Culote.
	_malla(_cilindro(0.011, 0.04), Vector3(-0.055, 0.05, 0), acostado, negro, grupo)      # Agarre.
	var punta := CylinderMesh.new()
	punta.top_radius = 0.009
	punta.bottom_radius = 0.0
	punta.height = 0.025
	_malla(punta, Vector3(-0.0875, 0.05, 0), acostado, _metal(Color("b8bcc2"), 0.3), grupo)


## Poporo Quimbaya: cuerpo redondo, cuello largo, cuatro esferas arriba y aro de base.
func _poporo() -> void:
	var oro := _metal(Color("e2ad35"), 0.25, 0.2)
	var grupo := Node3D.new()
	grupo.scale = Vector3.ONE * 1.3
	_contenido.add_child(grupo)
	var base := CylinderMesh.new()
	base.top_radius = 0.035
	base.bottom_radius = 0.045
	base.height = 0.03
	_malla(base, Vector3(0, 0.015, 0), Vector3.ZERO, oro, grupo)
	var cuerpo := _malla(_esfera(0.075), Vector3(0, 0.1, 0), Vector3.ZERO, oro, grupo)
	cuerpo.scale.y = 0.9
	var cuello := CylinderMesh.new()
	cuello.top_radius = 0.016
	cuello.bottom_radius = 0.042
	cuello.height = 0.1
	_malla(cuello, Vector3(0, 0.205, 0), Vector3.ZERO, oro, grupo)
	_malla(_cilindro(0.022, 0.012), Vector3(0, 0.26, 0), Vector3.ZERO, oro, grupo)
	for i: int in 4:
		var ang: float = TAU * i / 4.0
		_malla(_esfera(0.021), Vector3(cos(ang) * 0.024, 0.285, sin(ang) * 0.024), Vector3.ZERO, oro, grupo)


## Camiseta del Café de Colombia sobre un maniquí sin cabeza.
func _camiseta() -> void:
	var tela := StandardMaterial3D.new()
	tela.albedo_texture = _textura_camiseta()
	tela.roughness = 0.95
	var blanca := StandardMaterial3D.new()
	blanca.albedo_color = Color("f5f5f2")
	blanca.roughness = 0.95
	var soporte := _metal(Color("2a2c30"), 0.5)
	_malla(_cilindro(0.02, 0.36), Vector3(0, 0.18, 0), Vector3.ZERO, soporte)
	_malla(_caja(Vector3(0.42, 0.56, 0.2)), Vector3(0, 0.64, 0), Vector3.ZERO, blanca)
	# El frente va aparte: una caja reparte su textura entre las seis caras.
	var frente := QuadMesh.new()
	frente.size = Vector2(0.42, 0.56)
	_malla(frente, Vector3(0, 0.64, 0.101), Vector3.ZERO, tela)
	for lado: float in [-1.0, 1.0]:
		_malla(_caja(Vector3(0.15, 0.17, 0.18)), Vector3(lado * 0.255, 0.82, 0), Vector3(0, 0, lado * 0.45), blanca)
	_malla(_cilindro(0.06, 0.04), Vector3(0, 0.94, 0), Vector3.ZERO, _metal(Color("1d3f8f"), 0.8))
	var letras := Label3D.new()
	letras.text = "CAFÉ DE\nCOLOMBIA"
	letras.font_size = 32
	letras.pixel_size = 0.0016
	letras.outline_size = 0
	letras.modulate = Color("15171a")
	letras.position = Vector3(0, 0.78, 0.104)
	_contenido.add_child(letras)


## Papel inclinado sobre un atril, como en una vitrina de documentos.
func _documento() -> void:
	var atril := StandardMaterial3D.new()
	atril.albedo_color = Color("2b2d31")
	var inclinado := Vector3(0.35, 0, 0)   # Se inclina hacia el frente (+z), donde está la placa.
	_malla(_caja(Vector3(0.48, 0.02, 0.36)), Vector3(0, 0.1, 0), inclinado, atril)
	var tex := _textura()
	var proporcion: float = float(tex.get_width()) / float(tex.get_height())
	var alto: float = 0.3
	var ancho: float = alto * proporcion
	if ancho > 0.42:
		ancho = 0.42
		alto = ancho / proporcion
	var papel := QuadMesh.new()
	papel.size = Vector2(ancho, alto)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.roughness = 0.9
	# El quad mira hacia +z; se acuesta sobre el atril, apenas encima de su cara.
	_malla(papel, Vector3(0, 0.1, 0) + Vector3(0, cos(0.35), sin(0.35)) * 0.012, Vector3(-PI * 0.5 + 0.35, 0, 0), mat)


# ---------------------------------------------------------------- utilidades

func _malla(malla: Mesh, pos: Vector3, giro: Vector3, mat: Material, padre: Node3D = null) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = malla
	m.position = pos
	m.rotation = giro
	m.material_override = mat
	(padre if padre else _contenido).add_child(m)
	return m


func _caja(tam: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = tam
	return b


func _cilindro(radio: float, alto: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = radio
	c.bottom_radius = radio
	c.height = alto
	c.radial_segments = 20
	return c


func _esfera(radio: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = radio
	s.height = radio * 2.0
	return s


## Metal. Con "brillo" > 0 emite un poco de su propio color: así el oro se ve dorado
## aunque la sala esté oscura y no haya nada amarillo que reflejar.
func _metal(color: Color, rugosidad: float, brillo: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.9 if brillo == 0.0 else 0.6
	mat.roughness = rugosidad
	if brillo > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = brillo
	return mat


func _crear_placa(pos: Vector3) -> void:
	_placa = Label3D.new()
	var anio: String = datos["anio"]
	var texto: String = "%s\n%s%s" % [datos["titulo"], datos["autor"], "" if anio.is_empty() else "\n" + anio]
	var prestamo: String = Catalogo.museo(datos.get("museo", "")).get("placa", "")
	if prestamo != "":
		texto += "\n" + prestamo
	_placa.text = texto
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
	var ruta: String = Catalogo.imagen(datos["id"])
	if ruta != "":
		return load(ruta)
	if datos.get("tela", false):
		return _textura_franjas()
	return _textura_provisional()


## Franjas horizontales con los colores de la paleta (la bandera, hasta tener su foto).
func _textura_franjas() -> ImageTexture:
	var paleta: Array = datos["paleta"]
	var img := Image.create(8, paleta.size() * 8, false, Image.FORMAT_RGB8)
	for i: int in paleta.size():
		img.fill_rect(Rect2i(0, i * 8, 8, 8), Color(paleta[i] as String))
	return ImageTexture.create_from_image(img)


## Frente de la camiseta: blanca con los triángulos azul, amarillo y rojo abajo.
func _textura_camiseta() -> ImageTexture:
	var paleta: Array = datos["paleta"]
	var img := Image.create(120, 160, false, Image.FORMAT_RGB8)
	img.fill(Color(paleta[0] as String))
	var picos: Array = [[30, 70, 1], [62, 95, 2], [92, 110, 3]]   # [centro x, altura de la punta, color]
	for pico: Array in picos:
		for y: int in range(pico[1], 160):
			var medio: int = int((y - (pico[1] as int)) * 0.6)
			img.fill_rect(Rect2i((pico[0] as int) - medio, y, medio * 2 + 1, 1), Color(paleta[pico[2]] as String))
	return ImageTexture.create_from_image(img)


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
