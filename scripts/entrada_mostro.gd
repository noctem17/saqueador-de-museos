class_name EntradaMostro
extends Node
## La entrada de Mostro cuando a Polo lo pillan (al estilo de las presentaciones
## de personaje de Devil May Cry).
##
## 1. Llamada en pantalla dividida: Polo escondido a la izquierda y, a la derecha,
##    Mostro como una silueta negra a contraluz de los faros. Nadie le ve la cara.
## 2. Cuelga y arranca AURA (desde el segundo 12, para que el golpe fuerte de la
##    canción caiga justo cuando se le ve la cara).
## 3. Camina en silueta por la acera y sube la escalinata, en varios planos.
## 4. Destello: se le revela la cara y la cámara se aleja despacio, desde abajo.
## 5. Combos de boxeo, un paso de baile y una voltereta; primer plano de la cara
##    mientras sale su nombre en grande.
##
## La primera vez se ve completa; si vuelve a pasar en otra partida, solo la
## llamada corta y la presentación. Mantener ESPACIO la salta.

const INICIO_CANCION: float = 12.0   ## Desde dónde arranca AURA.
const GOLPE_CANCION: float = 23.45   ## Segundo de AURA donde entra el golpe fuerte.

var mision: Node
var musica: AudioStreamPlayer        ## Queda sonando en bucle mientras se juega con Mostro.

var _hud: Hud
var _mostro: Cuerpo
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
	_hud.franjas(true)

	# 1. La llamada, con la pantalla partida en dos.
	var esquina := Vector3(6.0, y_calle, 57.5)
	_mostro.global_position = esquina
	_mostro.rotation.y = 0.0   # Mira hacia el museo (-Z).
	_mostro.silueta(true)
	_faros(esquina + Vector3(3.4, 0, 0.5), Vector3(-1, 0, 0))
	# Su mitad lo muestra de perfil, a contraluz.
	# Polo está encogido del miedo: su cara queda un poco más abajo que de pie.
	var cara_polo: float = (Cuerpo.TIPOS["polo"]["cara"] as float) - 0.22
	var cara_mostro: float = Cuerpo.TIPOS["mostro"]["cara"] as float
	var partida: Control = _pantalla_partida(
		pos_polo + Vector3(0.2, cara_polo + 0.05, -0.95), pos_polo + Vector3(0, cara_polo + 0.03, 0),
		esquina + Vector3(-2.3, cara_mostro - 0.35, -0.55), esquina + Vector3(0, cara_mostro - 0.45, -0.15))
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
	# Se detiene. Primerísimo plano de la silueta: nadie le ve la cara todavía.
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
		# El show, con sus propias animaciones y un corte de cámara por golpe, al
		# estilo de Dante cuando se hace el cool: combo de boxeo, otro combo y un
		# paso raro.
		var planos: Array = [
			# [animación, cuándo cortar (s), posición de la cámara, altura a la que mira]
			["m_box_01", 0.0, Vector3(-1.7, 1.1, -1.5), 1.1],
			["", 0.9, Vector3(1.2, 0.35, -1.6), 1.2],
			["m_box_02", 2.2, Vector3(1.9, 1.5, -1.3), 1.0],
			["", 3.4, Vector3(-0.5, 0.6, -1.3), 1.3],
			["m_freaky", 4.9, Vector3(0.0, 0.25, -1.9), 1.0],
		]
		var empieza: int = Time.get_ticks_msec()
		for p: Array in planos:
			var espera: float = p[1] - (Time.get_ticks_msec() - empieza) / 1000.0
			if espera > 0.0 and await _esperar(espera):
				return
			if p[0] != "":
				_mostro.una_vez(p[0] as String, 0.1)
			_nueva_camara(base + (p[2] as Vector3), base + Vector3.UP * (p[3] as float))
			_seguir_a = _mostro
			_alto_mirada = p[3]
			Sfx.plano(mision, "pose", -8.0)
			_temblor = 0.45
		if await _esperar(0.9):
			return

	# Cierre: rueda hacia la cámara (su animación de "dive") y se levanta. Corte a
	# un primer plano de la cara mientras sale su nombre y suena su frase.
	_mostro.rotation.y = 0.0
	_mostro.una_vez("m_dive", 0.1)
	_nueva_camara(base + Vector3(0.7, 0.5, -3.4), base + Vector3.UP * 0.6)
	_seguir_a = _mostro
	_alto_mirada = 0.6
	_cam.fov = 50.0
	Sfx.plano(mision, "pose", -6.0)
	if await _esperar(2.3):
		return
	var ojos: Vector3 = base + Vector3.UP * (Cuerpo.TIPOS["mostro"]["cara"] as float)
	# La cara queda en la mitad de arriba, encima de la franja con su nombre.
	_nueva_camara(ojos + Vector3(0.3, 0.05, -1.4), ojos + Vector3.DOWN * 0.2)
	_seguir_a = null
	_cam.fov = 40.0
	_temblor = 0.5
	# Se acerca despacio mientras habla.
	create_tween().tween_property(_cam, "fov", 34.0, 8.0).set_trans(Tween.TRANS_SINE)
	_titulo()
	await _esperar(8.2)


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


func _destellar(color: Color) -> void:
	_destello.color = Color(color, 0.95)
	create_tween().tween_property(_destello, "color:a", 0.0, 0.5)


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
	t.tween_callback(_patria_milagro)
	t.tween_interval(5.6)
	t.tween_callback(_grito_final)


## Su frase, con la voz que grabó el equipo.
func _patria_milagro() -> void:
	Sfx.plano(mision, "patria_milagro", 6.0)
	# Subtítulo arriba, para no tapar su nombre.
	var l := Label.new()
	l.text = "«¡Bienvenido a la patria milagro!»"
	l.add_theme_font_size_override("font_size", 34)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.anchor_left = 0.0
	l.anchor_right = 1.0
	l.anchor_top = 0.27
	l.anchor_bottom = 0.27
	l.offset_bottom = 50
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa.add_child(l)


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
