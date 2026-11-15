class_name EntradaMostro
extends Node
## La entrada de Mostro cuando a Polo lo pillan (al estilo de las presentaciones
## de personaje de Devil May Cry).
##
## 1. Llamada en pantalla dividida: Polo escondido a la izquierda y, a la derecha,
##    Mostro como una silueta negra a contraluz de los faros, con la brasa del
##    cigarrillo. Nadie le ve la cara.
## 2. Cuelga y arranca AURA (desde el segundo 12, para que el golpe fuerte de la
##    canción caiga justo cuando se le ve la cara).
## 3. Camina en silueta por la acera y sube la escalinata, en varios planos.
## 4. Destello: se le revela la cara y la cámara se aleja despacio, desde abajo.
## 5. Golpes, patadas, el "6-7" y saca la pistola. Sale su nombre en grande.
##
## La primera vez se ve completa; si vuelve a pasar en otra partida, solo la
## llamada corta y la presentación. Mantener ESPACIO la salta.

const INICIO_CANCION: float = 12.0   ## Desde dónde arranca AURA.
const GOLPE_CANCION: float = 23.45   ## Segundo de AURA donde entra el golpe fuerte.

var mision: Node
var musica: AudioStreamPlayer        ## Queda sonando en bucle mientras se juega con Mostro.

var _hud: Hud
var _mostro: Cuerpo
var _brasa: OmniLight3D
var _saltar: bool = false
var _cam: Camera3D
var _seguir_a: Node3D                ## La cámara principal mira a este nodo cada cuadro.
var _alto_mirada: float = 1.0
var _arrastre: Vector3 = Vector3.INF ## Si no es INF, la cámara va pegada a _seguir_a con este desfase.
var _temblor: float = 0.0
var _capa: CanvasLayer
var _destello: ColorRect
var _luces: Array[Node] = []         ## Luces de la escena, para borrarlas al final.


## Cuenta toda la escena. Al terminar la pantalla queda en negro.
func reproducir(m: Node, pos_polo: Vector3, causa: String) -> void:
	mision = m
	_hud = m.get("hud")
	var mapa: Mapa = m.get("mapa")
	var y_calle: float = mapa.spawn_polo.y - 0.1
	var y_plaza: float = mapa.spawn_mostro.y - 0.1
	var completa: bool = not Juego.mostro_presentado
	Juego.mostro_presentado = true
	_armar_capas()
	_mostro = Cuerpo.crear("mostro")
	m.add_child(_mostro)
	_armar_brasa()
	_hud.franjas(true)

	# 1. La llamada, con la pantalla partida en dos.
	var esquina := Vector3(6.0, y_calle, 57.5)
	_mostro.global_position = esquina
	_mostro.rotation.y = 0.0   # Mira hacia el museo (-Z).
	_mostro.silueta(true)
	_faros(esquina + Vector3(3.4, 0, 0.5), Vector3(-1, 0, 0))
	# Su mitad lo muestra de perfil, para que se vea el cigarrillo y el humo.
	var partida: Control = _pantalla_partida(
		pos_polo + Vector3(0.35, 0.85, -1.4), pos_polo + Vector3(0, 0.7, 0),
		esquina + Vector3(-2.3, 1.05, -0.55), esquina + Vector3(0, 1.0, -0.15))
	get_viewport().disable_3d = true   # Queda tapado por las dos mitades.
	await _hud.fundir(0.0, 0.5)
	var lineas: Array[Dictionary] = [
		{"quien": "POLO", "texto": "Jefe... me vieron. Suena la alarma.", "dura": 2.2},
		{"quien": "MOSTRO", "texto": "%s Escóndase y no respire." % causa, "dura": 2.4},
	]
	if completa:
		lineas.append_array([
			{"quien": "POLO", "texto": "¿Y usted qué va a hacer?", "dura": 1.8},
			{"quien": "MOSTRO", "texto": "Lo que hago siempre: terminar lo que los demás no se atreven.", "dura": 2.8},
		])
	lineas.append({"quien": "MOSTRO", "texto": "Voy para allá.", "dura": 1.5})
	await _hud.reproducir_llamada(lineas, true)
	Sfx.plano(mision, "descolgar", -6.0)
	await _hud.fundir(1.0, 0.25)
	partida.queue_free()
	get_viewport().disable_3d = false

	# 2. Cuelga: arranca AURA. La alarma se baja para que no se peleen.
	musica = Sfx.bucle(mision, "musica/mostro", -7.0)
	var alarma: AudioStreamPlayer = mision.get("_alarma_sonido")
	if alarma:
		alarma.volume_db = -30.0
	if completa and not _saltado():
		musica.play(INICIO_CANCION)
		await _caminata(y_calle, y_plaza)
	else:
		musica.play(GOLPE_CANCION - 0.6)
		_mostro.global_position = Vector3(0, y_plaza, 44.8)
		_mostro.rotation.y = 0.0
	if not _saltado():
		await _revelacion(completa)
	await _hud.fundir(1.0, 0.4)
	_limpiar()


func _process(delta: float) -> void:
	if _cam == null or not is_instance_valid(_cam):
		return
	if _seguir_a and _arrastre != Vector3.INF:
		_cam.global_position = _seguir_a.global_position + _arrastre
	if _seguir_a:
		_cam.look_at(_seguir_a.global_position + Vector3.UP * _alto_mirada)
	if _temblor > 0.0:
		_temblor = maxf(_temblor - delta * 2.0, 0.0)
		_cam.h_offset = randf_range(-1, 1) * _temblor * 0.1
		_cam.v_offset = randf_range(-1, 1) * _temblor * 0.1
	else:
		_cam.h_offset = 0.0
		_cam.v_offset = 0.0
	if _brasa:
		_brasa.light_energy = 1.2 + sin(Time.get_ticks_msec() * 0.006) * 0.5


## 3. La silueta camina por la acera y sube la escalinata, en cuatro planos.
func _caminata(y_calle: float, y_plaza: float) -> void:
	_hud.fundir(0.0, 0.6)
	_mostro.reproducir("Walk")
	_mostro.rotation.y = PI * 0.5   # Camina hacia -X, hacia la escalinata.
	# A ras del piso, los zapatos llegando.
	_mostro.global_position = Vector3(22.0, y_calle, 52.6)
	_nueva_camara(Vector3(19.0, y_calle + 0.18, 53.1), Vector3.ZERO)
	_seguir_a = _mostro
	_alto_mirada = 0.25
	_arrastre = Vector3(-2.6, 0.18, 0.5)
	_cam.global_position = _mostro.global_position + _arrastre
	var t := create_tween()
	t.tween_property(_mostro, "global_position:x", 15.5, 3.6)
	if await _esperar(3.6):
		return
	# De lado, desde la calle, con el museo iluminado detrás: se ve la silueta.
	_nueva_camara(Vector3.ZERO, Vector3.ZERO)
	_arrastre = Vector3(0.0, 0.9, 5.2)
	_cam.global_position = _mostro.global_position + _arrastre
	_alto_mirada = 1.0
	t = create_tween()
	t.tween_property(_mostro, "global_position:x", 8.5, 3.6)
	if await _esperar(3.6):
		return
	# Por detrás, subiendo la escalinata hacia la fachada.
	_mostro.global_position = Vector3(0.0, y_calle, 52.0)
	_mostro.rotation.y = 0.0
	_nueva_camara(Vector3(0.9, y_calle + 0.5, 55.2), Vector3.ZERO)
	_arrastre = Vector3.INF
	_alto_mirada = 1.6
	t = create_tween()
	t.tween_property(_mostro, "global_position", Vector3(0.0, y_calle, 50.0), 0.9)
	t.tween_property(_mostro, "global_position", Vector3(0.0, y_plaza, 46.0), 1.8)
	t.tween_property(_mostro, "global_position", Vector3(0.0, y_plaza, 44.8), 0.6)
	if await _esperar(3.3):
		return
	# Se detiene. Primerísimo plano de la silueta: solo la brasa del cigarrillo.
	t.kill()
	_mostro.global_position = Vector3(0.0, y_plaza, 44.8)
	_mostro.reproducir("Idle")
	_seguir_a = null
	_nueva_camara(Vector3(0.3, y_plaza + 1.15, 43.0), Vector3(0, y_plaza + 1.1, 44.8))
	_cam.fov = 38.0
	# Espera el golpe fuerte de la canción.
	while musica.get_playback_position() < GOLPE_CANCION and not _saltado():
		await get_tree().process_frame


## 4 y 5. Se le ve la cara, la cámara se aleja y viene el show.
func _revelacion(completa: bool) -> void:
	var base: Vector3 = _mostro.global_position
	_mostro.silueta(false)
	_mostro.reproducir("Idle")
	_destellar(Color.WHITE)
	_temblor = 1.0
	# Luz de frente, desde arriba, como un poste de luz.
	var foco := SpotLight3D.new()
	foco.light_color = Color("fff1dc")
	foco.light_energy = 5.0
	foco.spot_range = 9.0
	foco.spot_angle = 40.0
	mision.add_child(foco)
	foco.global_position = base + Vector3(0, 4.5, -1.6)
	foco.look_at(base + Vector3.UP * 1.0)
	_luces.append(foco)
	_brasa.get_parent().visible = false   # Apaga el cigarrillo para el show.
	_hud.fundir(0.0, 0.05)
	# Primer plano de la cara y se aleja despacio, bajando: queda mirando desde abajo.
	var cara: Vector3 = base + Vector3.UP * (Cuerpo.TIPOS["mostro"]["cara"] as float)
	_nueva_camara(cara + Vector3(0.15, 0.0, -0.95), cara)
	_cam.fov = 40.0
	_seguir_a = _mostro
	_alto_mirada = 1.0 if not completa else 1.1
	var t := create_tween()
	t.tween_property(_cam, "global_position", base + Vector3(0.9, 0.35, -4.2), 3.6 if completa else 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if await _esperar(3.6 if completa else 1.4):
		return

	if completa:
		# Golpes y patadas, cada uno con su corte de cámara.
		var golpes: Array = [
			["Punch_Right", Vector3(-1.6, 1.0, -1.4)],
			["Kick_Left", Vector3(1.4, 0.3, -1.8)],
			["Punch_Left", Vector3(0.2, 1.2, -1.5)],
			["Kick_Right", Vector3(2.1, 0.8, 0.2)],
			["Sword_Slash", Vector3(-1.2, 2.2, -1.6)],
		]
		for g: Array in golpes:
			_nueva_camara(base + (g[1] as Vector3), base + Vector3.UP * 0.9)
			_seguir_a = _mostro
			_alto_mirada = 0.9
			_mostro.una_vez(g[0] as String, 0.03)
			Sfx.plano(mision, "pose", -8.0)
			_temblor = 0.4
			if await _esperar(0.55):
				return
		# El "6-7": una mano arriba, la otra abajo, y al revés, varias veces.
		_nueva_camara(base + Vector3(0.0, 1.0, -2.6), base + Vector3.UP * 0.9)
		for i: int in 6:
			_mostro.posar("Idle_Neutral", 0.0)
			var arriba: String = ".L" if i % 2 == 0 else ".R"
			var abajo: String = ".R" if i % 2 == 0 else ".L"
			_mostro.doblar("UpperArm" + arriba, Vector3.RIGHT, -1.6)
			_mostro.doblar("UpperArm" + abajo, Vector3.RIGHT, -0.3)
			_mostro.doblar("UpperArm.L", Vector3.FORWARD, 0.5)
			_mostro.doblar("UpperArm.R", Vector3.FORWARD, -0.5)
			_numero("6" if i % 2 == 0 else "7", i % 2 == 0)
			if await _esperar(0.24):
				return

	# Saca la pistola y apunta a la cámara. Su nombre en grande.
	_mostro.posar("Idle_Gun_Pointing", 0.5)
	_mostro.sacar_pistola()
	# En esa pose el brazo queda estirado hacia un lado, con la pistola de perfil.
	_mostro.rotation.y = 0.0
	Sfx.plano(mision, "desenfundar", -2.0)
	_nueva_camara(base + Vector3(-0.2, 1.15, -2.7), base + Vector3(-0.2, 0.95, 0))
	_seguir_a = null
	_cam.fov = 45.0
	_temblor = 0.5
	_titulo()
	await _esperar(2.6)


# ------------------------------------------------------------------ ayudas

## Espera unos segundos, o menos si mantienen ESPACIO. Devuelve true si se saltó.
func _esperar(segundos: float) -> bool:
	var fin: int = Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < fin:
		if _saltado():
			return true
		await get_tree().process_frame
	return _saltado()


func _saltado() -> bool:
	if Input.is_action_pressed("saltar"):
		_saltar = true
	return _saltar


## Cámara nueva en el mundo; borra la anterior.
func _nueva_camara(desde: Vector3, hacia: Vector3) -> void:
	if _cam and is_instance_valid(_cam):
		_cam.queue_free()
	_cam = Camera3D.new()
	_cam.fov = 50.0
	mision.add_child(_cam)
	if desde != Vector3.ZERO:
		_cam.global_position = desde
		if hacia != Vector3.ZERO and not desde.is_equal_approx(hacia):
			_cam.look_at(hacia)
	_cam.make_current()
	var relleno := OmniLight3D.new()
	relleno.light_color = Color("c9d6ff")
	relleno.light_energy = 0.8
	relleno.omni_range = 4.0
	_cam.add_child(relleno)


## Capas de la interfaz: la pantalla partida, el destello y los textos grandes.
func _armar_capas() -> void:
	_capa = CanvasLayer.new()
	_capa.layer = 7
	mision.add_child(_capa)
	var capa_destello := CanvasLayer.new()
	capa_destello.layer = 9
	_capa.add_child(capa_destello)
	_destello = ColorRect.new()
	_destello.set_anchors_preset(Control.PRESET_FULL_RECT)
	_destello.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_destello.color = Color(1, 1, 1, 0)
	capa_destello.add_child(_destello)


## Dos cámaras del mismo mundo, lado a lado, con una línea blanca en el medio.
func _pantalla_partida(desde_a: Vector3, hacia_a: Vector3, desde_b: Vector3, hacia_b: Vector3) -> Control:
	var caja := HBoxContainer.new()
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_theme_constant_override("separation", 0)
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa.add_child(caja)
	var mitades: Array = [[desde_a, hacia_a], [desde_b, hacia_b]]
	for i: int in 2:
		if i == 1:
			var linea := ColorRect.new()
			linea.color = Color("e8e2d0")
			linea.custom_minimum_size = Vector2(6, 0)
			caja.add_child(linea)
		var cont := SubViewportContainer.new()
		cont.stretch = true
		cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caja.add_child(cont)
		var vp := SubViewport.new()
		vp.world_3d = get_viewport().world_3d
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		cont.add_child(vp)
		var cam := Camera3D.new()
		cam.fov = 42.0
		vp.add_child(cam)
		cam.global_position = mitades[i][0]
		cam.look_at(mitades[i][1])
		cam.current = true
		var relleno := OmniLight3D.new()
		relleno.light_color = Color("aab8e0")
		relleno.light_energy = 0.7
		relleno.omni_range = 3.0
		cam.add_child(relleno)
	return caja


## Luz de faros detrás de Mostro: lo deja a contraluz, por eso se ve negro.
func _faros(pos: Vector3, hacia: Vector3 = Vector3(0, 0, -1)) -> void:
	var luz := SpotLight3D.new()
	luz.light_color = Color("fff1d6")
	luz.light_energy = 6.0
	luz.spot_range = 14.0
	luz.spot_angle = 35.0
	mision.add_child(luz)
	luz.global_position = pos + Vector3(0, 0.9, 0)
	luz.look_at(pos + hacia * 6.0)
	_luces.append(luz)


## El cigarrillo: un cilindro blanco que sale de la boca, la brasa en la punta y
## un hilo de humo. No es parte del modelo, así que no se pone negro en la silueta.
func _armar_brasa() -> void:
	var raiz := Node3D.new()
	_mostro.add_child(raiz)
	raiz.position = Vector3(-0.03, 1.02, -0.42)
	# Apunta hacia adelante, un poco al lado y hacia abajo, como en la boca.
	raiz.look_at_from_position(raiz.position, raiz.position + Vector3(-0.45, -0.25, -1.0), Vector3.UP)
	var papel := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.009
	c.bottom_radius = 0.009
	c.height = 0.1
	c.radial_segments = 8
	papel.mesh = c
	var blanco := StandardMaterial3D.new()
	blanco.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blanco.albedo_color = Color("e9e4d8")
	papel.material_override = blanco
	papel.rotation.x = -PI * 0.5   # El cilindro queda acostado a lo largo del cigarrillo (-Z).
	papel.position.z = -0.05
	raiz.add_child(papel)
	var punta := MeshInstance3D.new()
	var e := SphereMesh.new()
	e.radius = 0.011
	e.height = 0.022
	punta.mesh = e
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color("ff6a1a")
	punta.material_override = m
	punta.position.z = -0.1
	raiz.add_child(punta)
	_brasa = OmniLight3D.new()
	_brasa.light_color = Color("ff5a14")
	_brasa.light_energy = 1.2
	_brasa.omni_range = 0.9
	_brasa.position.z = -0.1
	raiz.add_child(_brasa)
	# Humo: bolitas grises que suben despacio, crecen y se deshacen.
	var humo := GPUParticles3D.new()
	humo.amount = 24
	humo.lifetime = 2.4
	humo.local_coords = false
	humo.visibility_aabb = AABB(Vector3(-1, -0.5, -1), Vector3(2, 2.5, 2))
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 12.0
	pm.initial_velocity_min = 0.12
	pm.initial_velocity_max = 0.22
	pm.gravity = Vector3(0.03, 0.04, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.0
	var crece := Curve.new()
	crece.add_point(Vector2(0, 0.3))
	crece.add_point(Vector2(1, 2.2))
	var ct := CurveTexture.new()
	ct.curve = crece
	pm.scale_curve = ct
	var rampa := Gradient.new()
	rampa.set_color(0, Color(0.8, 0.8, 0.82, 0.0))
	rampa.set_color(1, Color(0.7, 0.7, 0.72, 0.0))
	rampa.add_point(0.12, Color(0.85, 0.85, 0.88, 0.55))
	var gt := GradientTexture1D.new()
	gt.gradient = rampa
	pm.color_ramp = gt
	humo.process_material = pm
	var bola := SphereMesh.new()
	bola.radius = 0.025
	bola.height = 0.05
	bola.radial_segments = 6
	bola.rings = 3
	var mh := StandardMaterial3D.new()
	mh.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mh.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mh.vertex_color_use_as_albedo = true
	bola.material = mh
	humo.draw_pass_1 = bola
	humo.position.z = -0.1
	raiz.add_child(humo)


func _destellar(color: Color) -> void:
	_destello.color = Color(color, 0.95)
	create_tween().tween_property(_destello, "color:a", 0.0, 0.5)


## Un "6" o un "7" enorme que aparece de un lado o del otro.
func _numero(texto: String, izquierda: bool) -> void:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", 150)
	l.add_theme_color_override("font_color", Color("ffd34a"))
	l.add_theme_color_override("font_outline_color", Color("2a0a00"))
	l.add_theme_constant_override("outline_size", 22)
	_anclar(l, 0.18 if izquierda else 0.68, 0.28)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa.add_child(l)
	l.rotation = -0.2 if izquierda else 0.2
	var t := create_tween()
	t.tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.15)
	t.tween_callback(l.queue_free)


## El nombre, como en las presentaciones de personaje: entra de lado y torcido.
func _titulo() -> void:
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa.add_child(raiz)
	var franja := ColorRect.new()
	franja.color = Color(0.55, 0.05, 0.05, 0.85)
	_anclar(franja, 0.0, 0.62)
	franja.position.x = -80
	franja.size = Vector2(900, 150)
	franja.rotation = -0.06
	raiz.add_child(franja)
	var nombre := Label.new()
	nombre.text = "MOSTRO"
	nombre.add_theme_font_size_override("font_size", 120)
	nombre.add_theme_color_override("font_color", Color.WHITE)
	nombre.add_theme_color_override("font_outline_color", Color.BLACK)
	nombre.add_theme_constant_override("outline_size", 16)
	_anclar(nombre, 0.0, 0.605)
	nombre.position.x = 60
	nombre.rotation = -0.06
	raiz.add_child(nombre)
	var lema := Label.new()
	lema.text = "El ilegítimo"
	lema.add_theme_font_size_override("font_size", 28)
	lema.add_theme_color_override("font_color", Color("ffd9a0"))
	lema.add_theme_color_override("font_outline_color", Color.BLACK)
	lema.add_theme_constant_override("outline_size", 8)
	_anclar(lema, 0.0, 0.81)
	lema.position.x = 90
	lema.rotation = -0.06
	lema.modulate.a = 0.0
	raiz.add_child(lema)
	raiz.position.x = -1400
	var t := create_tween()
	t.tween_property(raiz, "position:x", 0.0, 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t.tween_property(lema, "modulate:a", 1.0, 0.3)
	t.tween_interval(0.35)
	t.tween_callback(_grito_final)


## Grita su consigna: letras enormes arriba que entran de golpe, con temblor.
func _grito_final() -> void:
	var l := Label.new()
	l.text = "¡¡¡VIVA CRISTO REY!!!"
	l.add_theme_font_size_override("font_size", 64)
	l.add_theme_color_override("font_color", Color("ffd34a"))
	l.add_theme_color_override("font_outline_color", Color("2a0a00"))
	l.add_theme_constant_override("outline_size", 16)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.anchor_left = 0.0
	l.anchor_right = 1.0
	l.anchor_top = 0.14
	l.anchor_bottom = 0.14
	l.offset_bottom = 90
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa.add_child(l)
	l.pivot_offset = Vector2(get_viewport().get_visible_rect().size.x * 0.5, 45)
	l.scale = Vector2(1.7, 1.7)
	create_tween().tween_property(l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_temblor = 1.0


## Pega la esquina de arriba a la izquierda del control a un punto de la pantalla (0..1).
func _anclar(c: Control, x: float, y: float) -> void:
	c.anchor_left = x
	c.anchor_right = x
	c.anchor_top = y
	c.anchor_bottom = y
	c.offset_left = 0
	c.offset_top = 0


func _limpiar() -> void:
	get_viewport().disable_3d = false
	for n: Node in _luces:
		if is_instance_valid(n):
			n.queue_free()
	if _cam and is_instance_valid(_cam):
		_cam.queue_free()
	if is_instance_valid(_mostro):
		_mostro.queue_free()
	if is_instance_valid(_capa):
		_capa.queue_free()
	_hud.franjas(false)
