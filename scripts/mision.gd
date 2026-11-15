class_name Mision
extends Node3D
## Arma una partida: reparte las piezas al azar y dirige la historia
## (llamada, sigilo, alarma, entrada de Mostro y huida).

const Otros := preload("res://scripts/otros_interactuables.gd")
const MAX_POLICIAS: int = 6
const INTERVALO_POLICIA: float = 18.0
## En true vuelve al mapa de prueba (respaldo) en lugar del Museo Nacional.
const USAR_MAPA_PRUEBA: bool = false
## Máximo de cuadros colgados (las obras de la agenda más relleno de la colección).
const MAX_CUADROS: int = 46
## Debajo de esta cantidad de luz (ver Vision.luz_en), Polo está en penumbra.
const UMBRAL_PENUMBRA: float = 0.12

var mapa: Mapa
var jugador: Jugador
var hud: Hud
var camioneta: Otros.Vehiculo
var polo_escondido: Otros.PoloEscondido
var polo_seguidor: Otros.PoloSeguidor
var obras: Array[Obra] = []

var _reloj_policia: Timer
var _terminado: bool = false
var _camioneta_visual: Node3D
var _musica_mostro: AudioStreamPlayer   ## AURA, en bucle mientras se juega con Mostro.
var _ambiente: AudioStreamPlayer
var _alarma_sonido: AudioStreamPlayer
var _zona_actual: String = ""
var _luces: Array[Light3D] = []   ## Lámparas del museo, para saber si Polo está en penumbra.
var _reloj_luz: float = 0.0
var candado: Llaves.Candado
## Distancia a la reja de la Sala 1 a la que arranca la escena del cuadro.
const DIST_CINE_CUADRO: float = 6.0
var _reloj_zona: float = 0.0
## Se pone en true en las pruebas automáticas para saltarse la llamada inicial.
static var saltar_intro: bool = false


func _ready() -> void:
	Juego.nueva_mision()
	mapa = MapaPrueba.new() if USAR_MAPA_PRUEBA else MapaMuseoNacional.new()
	add_child(mapa)
	mapa.construir()

	jugador = Jugador.new()
	jugador.position = mapa.spawn_polo
	add_child(jugador)
	jugador.rotation.y = 0.0

	_repartir_obras()
	_repartir_coleccionables()
	_crear_terminal()
	_crear_candado_y_llaves()
	_crear_camioneta()
	camioneta.escapar.connect(_huir)
	if not Juego.modo_exploracion:
		_crear_camaras()
		_crear_guardias()

	hud = Hud.new()
	add_child(hud)
	hud.conectar_jugador(jugador)

	_reloj_policia = Timer.new()
	_reloj_policia.wait_time = INTERVALO_POLICIA
	_reloj_policia.timeout.connect(_llegada_policia)
	add_child(_reloj_policia)

	Juego.alarma_disparada.connect(_on_alarma)
	jugador.vida_cambio.connect(_on_vida)
	Juego.agenda_cambio.connect(_revisar_objetivo)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_introduccion()


## En el modo exploración, los números llevan a Polo al centro de cada piso.
func _unhandled_key_input(event: InputEvent) -> void:
	if not Juego.modo_exploracion or Juego.control_bloqueado or not event.is_pressed():
		return
	var tecla: Key = (event as InputEventKey).physical_keycode
	if tecla >= KEY_1 and tecla <= KEY_3:
		var piso: int = tecla - KEY_1
		jugador.global_position = Vector3(0, mapa.base_y(piso) + 0.1, 8.5)   # Junto a la escalera, sin pozo debajo.
	elif tecla == KEY_0:
		jugador.global_position = mapa.spawn_polo


func _process(delta: float) -> void:
	jugador.dentro = mapa.es_interior(jugador.global_position)
	_revisar_penumbra(delta)
	_revisar_cine_cuadro()
	if not Juego.control_bloqueado and not _terminado:
		Juego.tiempo_mision += delta
		_avisar_zona(delta)


## Cada 0,2 s mira si algún foco alumbra a Polo. Si no, está en la penumbra.
func _revisar_penumbra(delta: float) -> void:
	_reloj_luz -= delta
	if _reloj_luz > 0.0:
		return
	_reloj_luz = 0.2
	if _luces.is_empty():
		for n: Node in get_tree().get_nodes_in_group("luces_sala"):
			if n is Light3D:
				_luces.append(n as Light3D)
	jugador.en_sombra = Vision.luz_en(jugador.punto_pecho(), _luces, mapa.alto_piso) < UMBRAL_PENUMBRA


## Cuando el jugador cambia de sala, el nombre aparece un momento en pantalla.
func _avisar_zona(delta: float) -> void:
	_reloj_zona -= delta
	if _reloj_zona > 0.0:
		return
	_reloj_zona = 0.4
	var zona: String = mapa.zona_en(jugador.global_position)
	if zona != "" and zona != _zona_actual:
		_zona_actual = zona
		hud.mostrar_aviso(zona)


## Lo que está en la agenda siempre aparece, pero en un sitio distinto cada partida.
func _repartir_obras() -> void:
	var paredes: Array = mapa.slots_pared.duplicate()
	var pedestales: Array = mapa.slots_pedestal.duplicate()
	paredes.shuffle()
	pedestales.shuffle()
	var relleno: Array = Catalogo.RELLENO.duplicate()
	relleno.shuffle()
	var indice_pared: int = 0
	var indice_ped: int = 0
	for info: Dictionary in Catalogo.OBRAS:
		if info.get("sala_fija", false) and not mapa.slot_especial.is_empty():
			_colocar_cuadro(info, mapa.slot_especial)   # El cuadro del MAMBO: siempre en su sala.
		elif info["tipo"] == "pintura":
			_colocar_cuadro(info, paredes[indice_pared])
			indice_pared += 1
		else:
			var slot: Array = pedestales[indice_ped]
			indice_ped += 1
			var o := Obra.new()
			add_child(o)
			o.position = Vector3(slot[0], mapa.base_y(mapa.piso_de(slot, 2)) + 1.0, slot[1])
			o.rotation.y = randf() * TAU
			o.configurar(info)
			obras.append(o)
			_anotar_ubicacion(info, o.position)
	# Relleno de la colección: se repite si hace falta para que no queden salas vacías.
	var i_relleno: int = 0
	while indice_pared < mini(paredes.size(), MAX_CUADROS) and not relleno.is_empty():
		_colocar_cuadro(relleno[i_relleno % relleno.size()], paredes[indice_pared])
		i_relleno += 1
		indice_pared += 1


func _anotar_ubicacion(info: Dictionary, pos: Vector3) -> void:
	if Juego.esta_en_lista(info["id"]):
		Juego.ubicaciones[info["id"]] = mapa.zona_en(pos)


func _colocar_cuadro(info: Dictionary, slot: Array) -> void:
	mapa.panel_de_obra(slot)
	var o := Obra.new()
	add_child(o)
	o.position = Vector3(slot[0], mapa.base_y(mapa.piso_de(slot, 3)) + 1.85, slot[1])
	o.rotation_degrees.y = slot[2]
	o.configurar(info)
	obras.append(o)
	_anotar_ubicacion(info, o.position)


func _repartir_coleccionables() -> void:
	var sitios: Array = mapa.slots_coleccionable.duplicate()
	sitios.shuffle()
	var piezas: Array = Catalogo.COLECCIONABLES.duplicate()
	piezas.shuffle()
	for i: int in mini(Juego.COLECCIONABLES_POR_MISION, piezas.size()):
		var c := Otros.Coleccionable.new()
		add_child(c)
		c.position = Vector3(sitios[i][0], sitios[i][1], sitios[i][2])
		c.configurar(piezas[i])


func _crear_terminal() -> void:
	var t := Otros.Terminal.new()
	add_child(t)
	t.position = mapa.pos_terminal
	t.agregar_colision(Vector3(0.9, 0.5, 0.6))
	var pantalla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(0.8, 0.5, 0.06)
	pantalla.mesh = caja
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("0e2233")
	mat.emission_enabled = true
	mat.emission = Color("2ea3d6")
	mat.emission_energy_multiplier = 1.2
	pantalla.material_override = mat
	t.add_child(pantalla)


func _crear_camioneta() -> void:
	camioneta = Otros.Vehiculo.new()
	add_child(camioneta)
	camioneta.position = mapa.pos_camioneta
	camioneta.rotation_degrees.y = mapa.giro_camioneta   # El frente del modelo apunta a la salida.
	camioneta.agregar_colision(Vector3(2.5, 1.9, 4.6), Vector3(0, 0.95, 0))
	var escena: PackedScene = load("res://modelos/camioneta.glb")
	_camioneta_visual = escena.instantiate() as Node3D
	camioneta.add_child(_camioneta_visual)
	Mapa.pintar_carro(_camioneta_visual, Color("14161b"))
	# Cuerpo aparte para que nadie atraviese la camioneta.
	var solido := StaticBody3D.new()
	solido.collision_layer = Juego.CAPA_MUNDO
	solido.collision_mask = 0
	var col := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(2.1, 1.6, 4.2)
	col.shape = forma
	col.position.y = 0.8
	solido.add_child(col)
	camioneta.add_child(solido)


func _crear_camaras() -> void:
	for dato: Array in mapa.camaras:
		var c := CamaraSeguridad.new()
		c.position = Vector3(dato[0], dato[1], dato[2])
		c.giro_base = dato[3]
		add_child(c)


func _crear_guardias() -> void:
	for ruta: Array in mapa.patrullas:
		var g := Guardia.new()
		for punto: Array in ruta:
			g.ruta.append(Vector3(punto[0], mapa.base_y(mapa.piso_de(punto, 2)), punto[1]))
		add_child(g)
		g.global_position = g.ruta[0]


## Cámara de cine temporal para mostrar a los personajes.
func _plano(desde: Vector3, hacia: Vector3) -> Camera3D:
	var cam := Camera3D.new()
	cam.fov = 50.0
	add_child(cam)
	cam.global_position = desde
	cam.look_at(hacia)
	cam.make_current()
	var relleno := OmniLight3D.new()
	relleno.light_color = Color("ffdcb4")
	relleno.light_energy = 3.6
	relleno.omni_range = 9.0
	cam.add_child(relleno)
	return cam


func _introduccion() -> void:
	_ambiente = Sfx.bucle(self, "ambiente", -18.0)
	if Juego.modo_exploracion:
		Juego.anotadas = Juego.lista.size()
		hud._refrescar_agenda()
		hud.fundir(0.0, 0.5)
		jugador.activar_camara()
		Juego.control_bloqueado = false
		hud.fijar_objetivo("Modo exploración: sin guardias ni cámaras")
		hud.mostrar_aviso("Teclas 1, 2 y 3: ir a ese piso. 0: volver a la calle.")
		return
	if saltar_intro:
		Juego.anotadas = Juego.lista.size()
		hud._refrescar_agenda()
		hud.fundir(0.0, 0.01)
		Juego.control_bloqueado = false
		_revisar_objetivo()
		return
	hud.fijar_objetivo("Llamada entrante: Mostro")
	hud._refrescar_agenda()
	jugador.mostrar_modelo(true)
	var cine: Camera3D = _plano(mapa.spawn_polo + Vector3(1.8, 1.4, -4.6), mapa.spawn_polo + Vector3(0, 0.55, 0))
	await hud.fundir(0.0, 1.0)
	var lineas: Array[Dictionary] = [
		{"quien": "MOSTRO", "texto": "Polo. Saque la agenda y anote."},
		{"quien": "POLO", "texto": "Diga, jefe."},
		{"quien": "MOSTRO", "texto": "Esta noche entra al Nacional. Trajeron piezas del Miguel Urrutia y del Museo del Oro en préstamo, y no quiero que vuelvan a ningún lado."},
		{"quien": "MOSTRO", "texto": "Y de paso, unas del propio Nacional que el Gobierno ya mandó a bajar y un juez mandó a colgar otra vez. Yo termino lo que ellos no pudieron."},
		{"quien": "POLO", "texto": "¿Para vender?"},
		{"quien": "MOSTRO", "texto": "No. Nadie las compra, nadie las cuelga. Nadie las vuelve a ver. Lo que no se ve, no pasó."},
	]
	var seccion: String = ""
	for o: Dictionary in Juego.lista:
		if o["museo"] != seccion:
			seccion = o["museo"]
			lineas.append({"quien": "MOSTRO", "texto": _intro_seccion(seccion)})
		lineas.append({"quien": "MOSTRO", "texto": "«%s», de %s. %s" % [o["titulo"], o["autor"], o["razon"]], "anota": true})
	lineas.append({"quien": "MOSTRO", "texto": "Las tienen regadas por todo el Panóptico, así que búsquelas sala por sala. Y no me haga ir: si yo entro, no entro a mirar cuadros."})
	await hud.reproducir_llamada(lineas)
	jugador.mostrar_modelo(false)
	cine.queue_free()
	jugador.activar_camara()
	Juego.control_bloqueado = false
	_revisar_objetivo()
	hud.mostrar_aviso("TAB: agenda y bolso. ESC: controles.")


## Lo que dice Mostro antes de dictar cada sección de la agenda.
func _intro_seccion(museo: String) -> String:
	match museo:
		"especial":
			return "Lo primero, y lo que más me importa: el cuadro que el MAMBO prestó por un día. Lo tienen en la Sala 1, la que está cerrada por montaje."
		"urrutia":
			return "Del Miguel Urrutia, anote:"
		"nacional":
			return "Del Nacional, las que ya estaban en la lista negra:"
		"oro":
			return "Y del Museo del Oro, una sola. La más bonita."
	return ""


func _crear_candado_y_llaves() -> void:
	if mapa.pos_candado == Vector3.INF:
		return
	candado = Llaves.Candado.new()
	add_child(candado)
	candado.position = mapa.pos_candado
	candado.abierto.connect(_revisar_objetivo)
	for id: String in mapa.sitios_llaves:
		var sitio: Array = mapa.sitios_llaves[id]
		var llave := Llaves.Llave.new()
		add_child(llave)
		llave.position = sitio[0]
		llave.configurar(id, sitio[1])
	Juego.llaves_cambio.connect(_revisar_objetivo)


## La primera vez que Polo se acerca a la reja de la Sala 1 (y nadie lo persigue).
func _revisar_cine_cuadro() -> void:
	if Juego.cine_cuadro_visto or candado == null or Juego.control_bloqueado or Juego.alarma or saltar_intro:
		return
	if jugador.personaje != Jugador.Personaje.POLO:
		return
	if jugador.global_position.distance_to(candado.global_position) < DIST_CINE_CUADRO:
		_cine_cuadro()


## Escena del cuadro del MAMBO: la cámara entra a la Sala 1 y se acerca al cuadro
## mientras Mostro cuenta su historia; luego primer plano de Polo diciendo qué hacer.
func _cine_cuadro() -> void:
	Juego.cine_cuadro_visto = true
	Juego.control_bloqueado = true
	var cuadro: Vector3 = candado.global_position + Vector3(-17.0, 1.85, 2.5)
	for o: Obra in obras:
		if o.datos.get("sala_fija", false):
			cuadro = o.global_position
	await hud.fundir(1.0, 0.35)
	hud.franjas(true)
	# 1. Travelling: desde la reja hasta el cuadro, despacio.
	var desde: Vector3 = candado.global_position + Vector3(-1.2, 1.7, 0.0)
	var hasta: Vector3 = cuadro + Vector3(3.2, -0.05, -0.4)
	var cam: Camera3D = _plano(desde, cuadro)
	var viaje := create_tween()
	viaje.tween_method(func(p: Vector3) -> void:
		cam.global_position = p
		cam.look_at(cuadro), desde, hasta, 14.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await hud.fundir(0.0, 0.6)
	await hud.reproducir_llamada([
		{"quien": "MOSTRO", "texto": "Ahí lo tiene, Polo. El cuadro del MAMBO."},
		{"quien": "MOSTRO", "texto": "Salió del museo geológico, rodó por más museos que un guía turístico, y la junta del MAMBO se lo prestó al Nacional por un solo día."},
		{"quien": "MOSTRO", "texto": "Un día. Como si el patrimonio fuera una licuadora que uno le presta a la vecina."},
		{"quien": "MOSTRO", "texto": "Y le pusieron un candado de tres llaves. Muy bonito. Lo quiero en la camioneta antes de que amanezca."},
		{"quien": "MOSTRO", "texto": "Mi contacto de adentro le mandó dónde están las llaves. Léamelo usted, que yo no tengo tiempo."},
	])
	await hud.fundir(1.0, 0.3)
	viaje.kill()
	cam.queue_free()
	# 2. Primer plano de la cara de Polo, mirando hacia la reja.
	jugador.mirar_hacia(candado.global_position)
	jugador.mostrar_modelo(true)
	var cabeza: Vector3 = jugador.global_position + Vector3.UP * (Cuerpo.TIPOS["polo"].get("cara", 1.62) as float)
	var frente: Vector3 = -jugador.global_basis.z
	var costado: Vector3 = jugador.global_basis.x
	var cam_polo: Camera3D = _plano(cabeza + frente * 1.75 + costado * 0.45 + Vector3.UP * 0.02, cabeza)
	cam_polo.fov = 40.0
	await hud.fundir(0.0, 0.3)
	await hud.reproducir_llamada([
		{"quien": "POLO", "texto": "Tres cerraduras: corazón, estrella y tigre."},
		{"quien": "POLO", "texto": "La del corazón la tiraron a la fuente del patio. La de la estrella la guarda el vigilante en el cajón del escritorio."},
		{"quien": "POLO", "texto": "Y la del tigre está detrás de un ladrillo flojo, en una celda del tercer piso, ala oeste. Dicen que hay zarpazos pintados en el muro."},
		{"quien": "POLO", "texto": "Junto las tres, abro la reja y el cuadro se va con nosotros."},
	])
	await hud.fundir(1.0, 0.3)
	jugador.mostrar_modelo(false)
	cam_polo.queue_free()
	jugador.activar_camara()
	hud.franjas(false)
	hud._refrescar_agenda()
	await hud.fundir(0.0, 0.3)
	Juego.control_bloqueado = false
	_revisar_objetivo()


func _revisar_objetivo() -> void:
	if _terminado:
		return
	if jugador.personaje == Jugador.Personaje.MOSTRO and not jugador.polo_rescatado:
		hud.fijar_objetivo("Encuentra a Polo (marcado en amarillo)")
	elif Juego.cine_cuadro_visto and Juego.llaves.size() < 3 and not Juego.alarma and not "cuadro_enlace" in Juego.robadas:
		hud.fijar_objetivo("Llaves del candado (%d/3): ♥ fuente del patio · ★ cajón de vigilancia · TIGRE celda del piso 3, ala oeste (zarpazos naranjas)" % Juego.llaves.size())
	elif Juego.cine_cuadro_visto and candado and candado.disponible(jugador) and not Juego.alarma:
		hud.fijar_objetivo("Abre el candado de la Sala 1 con las tres llaves")
	elif Juego.faltantes() > 0 and not Juego.alarma:
		hud.fijar_objetivo("Piezas por desaparecer: %d" % Juego.faltantes())
	elif Juego.faltantes() > 0:
		hud.fijar_objetivo("Sal en la camioneta. Piezas pendientes: %d" % Juego.faltantes())
	else:
		hud.fijar_objetivo("Vuelve a la camioneta en la calle")


func _on_alarma(motivo: String) -> void:
	_alarma_en_curso(motivo)


func _alarma_en_curso(motivo: String) -> void:
	Juego.control_bloqueado = true
	_encender_luces_alarma()
	_alarma_sonido = Sfx.bucle(self, "alarma", -16.0)
	var pos_polo: Vector3 = jugador.global_position
	var causa: String = "Una cámara lo pilló." if motivo == "camara" else "Lo vio un guardia."
	await hud.fundir(1.0, 0.4)
	polo_escondido = Otros.PoloEscondido.new()
	polo_escondido.rescatado.connect(_on_polo_rescatado)
	add_child(polo_escondido)
	polo_escondido.global_position = Vector3(pos_polo.x, pos_polo.y, pos_polo.z)

	# Llamada en pantalla partida, la silueta de Mostro y su presentación
	# (entrada_mostro.gd). AURA se queda sonando mientras se juega con él.
	var entrada := EntradaMostro.new()
	add_child(entrada)
	await entrada.reproducir(self, pos_polo, causa)
	_musica_mostro = entrada.musica
	entrada.queue_free()
	_crear_marcador(polo_escondido)
	var meta: Vector3 = mapa.spawn_mostro
	jugador.cambiar_a_mostro(meta, Vector3(0, meta.y, 0))
	jugador.activar_camara()
	await hud.fundir(0.0, 0.3)
	Juego.control_bloqueado = false
	_reloj_policia.start()
	_revisar_objetivo()


func _crear_marcador(destino: Node3D) -> void:
	var marca := Label3D.new()
	marca.text = "POLO"
	marca.font_size = 34
	marca.pixel_size = 0.0014
	marca.modulate = Color(1.0, 0.85, 0.2)
	marca.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marca.no_depth_test = true
	marca.fixed_size = true
	marca.position.y = 1.7
	destino.add_child(marca)


func _on_polo_rescatado() -> void:
	polo_seguidor = Otros.PoloSeguidor.new()
	polo_seguidor.objetivo = jugador
	add_child(polo_seguidor)
	polo_seguidor.global_position = polo_escondido.global_position
	hud.mostrar_aviso("Polo va con usted. Terminen la lista si se atreven.")
	_revisar_objetivo()


func _encender_luces_alarma() -> void:
	for hijo: Node in get_tree().get_nodes_in_group("luces_sala"):
		if hijo is Light3D:
			var luz := hijo as Light3D
			luz.light_color = Color("ff5a44")
			var tween := create_tween().set_loops()
			tween.tween_property(luz, "light_energy", 0.5, 0.6)
			tween.tween_property(luz, "light_energy", 2.4, 0.6)


func _llegada_policia() -> void:
	if get_tree().get_nodes_in_group("guardias").size() >= MAX_POLICIAS or _terminado:
		return
	var g := Guardia.new()
	g.es_policia = true
	add_child(g)
	g.global_position = mapa.spawn_policia.pick_random()
	hud.mostrar_aviso("Llegó la policía")


func _on_vida() -> void:
	if jugador.vida <= 0 and not _terminado:
		_terminar("fallo")


func _huir() -> void:
	if _terminado:
		return
	_terminado = true
	Juego.control_bloqueado = true
	if polo_seguidor:
		polo_seguidor.visible = false
	_plano(mapa.plano_huida, camioneta.global_position + Vector3(0, 0.8, 0))
	_apagar_musica_mostro()
	if _alarma_sonido:
		_alarma_sonido.volume_db = -22.0
	Sfx.plano(self, "motor", -4.0)
	var tween := create_tween()
	if mapa.has_node("Pluma"):
		tween.tween_property(mapa.get_node("Pluma"), "rotation:x", -1.45, 0.8)
	tween.parallel().tween_property(camioneta, "position", mapa.fin_huida, 3.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	if Juego.faltantes() == 0 and not Juego.modo_exploracion:
		# Con todas las obras en el baúl, en la carretera los espera Franchesca.
		Juego.resultado = "completo"
		await hud.fundir(1.0, 0.7)
		get_tree().change_scene_to_file(Juego.ESCENA_CARRETERA)
		return
	_terminar("completo" if Juego.faltantes() == 0 else "parcial")


func _apagar_musica_mostro() -> void:
	if _musica_mostro and is_instance_valid(_musica_mostro):
		var t := create_tween()
		t.tween_property(_musica_mostro, "volume_db", -40.0, 2.5)
		t.tween_callback(_musica_mostro.stop)


func _terminar(resultado: String) -> void:
	_apagar_musica_mostro()
	_terminado = true
	Juego.resultado = resultado
	Juego.control_bloqueado = true
	await hud.fundir(1.0, 0.7)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(Juego.ESCENA_FINAL)
