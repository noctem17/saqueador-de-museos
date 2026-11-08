extends Node
## Prueba automática: juega la misión con entradas reales y comprueba cada sistema.

var fallos: int = 0
var capturar: bool = false
var mision: Mision


func _ready() -> void:
	capturar = "capturas" in OS.get_cmdline_user_args()
	_correr.call_deferred()


func revisar(nombre: String, ok: bool, extra: Variant = "") -> void:
	print("%s  %s  %s" % ["OK  " if ok else "FAIL:", nombre, extra])
	if not ok:
		fallos += 1


func frames(n: int) -> void:
	for i: int in n:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		await get_tree().physics_frame


func foto(nombre: String) -> void:
	if not capturar:
		return
	await frames(4)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://capturas")
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png("res://capturas/%s.png" % nombre)


func foto_pausada(nombre: String) -> void:
	if not capturar:
		return
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://capturas")
	get_viewport().get_texture().get_image().save_png("res://capturas/%s.png" % nombre)


func nueva() -> void:
	if mision != null and is_instance_valid(mision):
		mision.free()
		await get_tree().process_frame
	Mision.saltar_intro = true
	mision = Mision.new()
	get_tree().root.add_child(mision)
	await frames(10)


func mirar(jug: Jugador, punto: Vector3) -> void:
	var cab: Vector3 = jug.punto_cabeza()
	jug.look_at(Vector3(punto.x, jug.global_position.y, punto.z), Vector3.UP)
	var piv: Node3D = jug.get_child(1)
	piv.rotation.x = atan2(punto.y - cab.y, Vector2(punto.x - cab.x, punto.z - cab.z).length())


## Altura del piso donde está un punto (los pisos van cada mision.mapa.alto_piso).
func piso_y(y: float) -> float:
	var alto: float = mision.mapa.alto_piso
	return floorf((y + 0.3) / alto) * alto if y > -0.5 else y - 0.3


## Busca una posición libre alrededor del objeto desde la que el rayo lo alcance.
func _acercarse(j: Jugador, objeto: Node3D, alto_mira: float = 0.07, distancias: Array = [1.0, 0.75]) -> bool:
	for direccion: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		for dist: float in distancias:
			var pos: Vector3 = objeto.global_position + direccion * dist
			j.global_position = Vector3(pos.x, piso_y(objeto.global_position.y) + 0.1, pos.z)
			j.velocity = Vector3.ZERO
			await frames(3)
			if j.global_position.distance_to(Vector3(pos.x, j.global_position.y, pos.z)) > 0.2:
				continue
			mirar(j, objeto.global_position + Vector3.UP * alto_mira)
			await frames(3)
			if j.objetivo_uso == objeto:
				return true
	return false


func quitar_peligros() -> void:
	for g: Node in get_tree().get_nodes_in_group("guardias"):
		g.process_mode = Node.PROCESS_MODE_DISABLED
	for c: Node in get_tree().get_nodes_in_group("camaras"):
		c.process_mode = Node.PROCESS_MODE_DISABLED


func pulsar_continuar() -> void:
	var ev := InputEventAction.new()
	ev.action = "saltar"
	ev.pressed = true
	Input.parse_input_event(ev)


func medir_fps() -> void:
	Mision.saltar_intro = true
	mision = Mision.new()
	get_tree().root.add_child(mision)
	await get_tree().create_timer(6.0).timeout
	print("FPS: %d  dibujos: %d" % [Engine.get_frames_per_second(), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
	get_tree().quit(0)


func _correr() -> void:
	if "fps" in OS.get_cmdline_user_args():
		await medir_fps()
		return

	# Llamada inicial real: va anotando en la agenda y entrega el control.
	Mision.saltar_intro = false
	mision = Mision.new()
	get_tree().root.add_child(mision)
	var guarda: int = 0
	await frames(80)
	await foto("00_llamada")
	while Juego.control_bloqueado and guarda < 60:
		pulsar_continuar()
		await frames(5)
		guarda += 1
	revisar("la llamada termina y da el control", not Juego.control_bloqueado, guarda)
	revisar("la agenda quedó anotada", Juego.anotadas == Juego.OBRAS_POR_MISION, Juego.anotadas)

	await nueva()
	for g: Node in get_tree().get_nodes_in_group("guardias"):
		g.process_mode = Node.PROCESS_MODE_DISABLED
	# Ruido: un guardia que oye correr va a mirar.
	var gr: Guardia = get_tree().get_nodes_in_group("guardias")[0]
	gr.process_mode = Node.PROCESS_MODE_INHERIT
	Juego.ruido.emit(gr.global_position + Vector3(2, 0, 0), 9.0)
	revisar("el guardia oye el ruido", gr.estado == Guardia.Estado.INVESTIGAR)

	# Vehiculo bloqueado mientras falten piezas.
	revisar("la camioneta no arranca con pendientes", not mision.camioneta.disponible(mision.jugador))

	# Camara ve al jugador de frente y dispara la alarma.
	var espacio: PhysicsDirectSpaceState3D = mision.get_world_3d().direct_space_state
	for c: Node in get_tree().get_nodes_in_group("camaras"):
		var cam: CamaraSeguridad = c
		cam.set_physics_process(false)
		cam.rotation.y = deg_to_rad(cam.giro_base)
		var cabeza: Node3D = cam.get_child(0)
		await frames(1)
		var plano: Vector3 = -cabeza.global_basis.z
		plano.y = 0.0
		var sitio: Vector3 = cabeza.global_position + plano.normalized() * 6.0
		mision.jugador.global_position = Vector3(sitio.x, piso_y(cam.global_position.y) + 0.1, sitio.z)
		await frames(2)
		var visto: bool = Vision.ve_jugador(espacio, cabeza.global_position, -cabeza.global_basis.z, mision.jugador, CamaraSeguridad.ALCANCE, CamaraSeguridad.MEDIO_ANGULO)
		revisar("la cámara en %s vigila la sala" % cam.position, visto)
		cam.set_physics_process(true)

	# La consola apaga todas las camaras.
	var term: Interactuable = null
	for h: Node in mision.get_children():
		if h is Mision.Otros.Terminal:
			term = h
	term.completar(mision.jugador)
	var todas: bool = get_tree().get_nodes_in_group("camaras").all(func(c: Node) -> bool: return not (c as CamaraSeguridad).activa)
	revisar("la consola apaga las cámaras", todas)

	await nueva()
	var j: Jugador = mision.jugador

	# Azar: agenda y posiciones cambian entre partidas.
	var lista_a: Array = Juego.lista.map(func(o: Dictionary) -> String: return o["id"])
	var pos_a: Vector3 = mision.obras[0].global_position
	await nueva()
	j = mision.jugador
	var lista_b: Array = Juego.lista.map(func(o: Dictionary) -> String: return o["id"])
	var pos_b: Vector3 = mision.obras[0].global_position
	revisar("agenda de 4 piezas", lista_b.size() == 4, lista_b)
	revisar("agenda o sitios cambian entre partidas", lista_a != lista_b or pos_a != pos_b)
	var con_pedestal: bool = Juego.lista.any(func(o: Dictionary) -> bool: return o["tipo"] != "pintura")
	revisar("incluye una pieza de pedestal", con_pedestal)
	var nav: RID = mision.mapa.get_navigation_map()
	# El servidor de navegación registra el mapa nuevo en segundo plano: hay que esperarlo.
	var espera_nav: int = 0
	while NavigationServer3D.map_get_closest_point(nav, mision.mapa.spawn_polo).is_zero_approx() and espera_nav < 300:
		await frames(1)
		espera_nav += 1
	var polys: int = mision.mapa.navigation_mesh.get_polygon_count()
	revisar("navegación horneada", polys > 20, polys)
	var lejos: Vector3 = mision.mapa.punto_lejano
	var camino: PackedVector3Array = NavigationServer3D.map_get_path(nav, mision.mapa.spawn_polo, lejos, true)
	revisar("hay ruta desde la entrada hasta el fondo", camino.size() > 2 and camino[-1].distance_to(lejos) < 1.0, camino.size())
	for ruta: Array in mision.mapa.patrullas:
		for p: Array in ruta:
			var punto := Vector3(p[0], mision.mapa.base_y(mision.mapa.piso_de(p, 2)), p[1])
			var cerca: Vector3 = NavigationServer3D.map_get_closest_point(nav, punto)
			if cerca.distance_to(punto) > 0.6:
				revisar("punto de patrulla alcanzable", false, p)

	# Guardias caminan de verdad.
	var g0: Guardia = get_tree().get_nodes_in_group("guardias")[0]
	var ini: Vector3 = g0.global_position
	await frames(240)
	revisar("el guardia patrulla", g0.global_position.distance_to(ini) > 1.0, g0.global_position.distance_to(ini))

	# Movimiento con entradas reales.
	await nueva()
	j = mision.jugador
	quitar_peligros()
	var p0: Vector3 = j.global_position
	Input.action_press("adelante")
	await frames(60)
	Input.action_release("adelante")
	revisar("W mueve al jugador", p0.distance_to(j.global_position) > 2.0, p0.distance_to(j.global_position))
	await foto("01_entrada")

	var alto: float = j.punto_cabeza().y
	Input.action_press("agacharse")
	await frames(40)
	revisar("agacharse baja la cabeza", j.punto_cabeza().y < alto - 0.5, j.punto_cabeza().y)
	Input.action_release("agacharse")
	await frames(40)
	revisar("levantarse", absf(j.punto_cabeza().y - alto) < 0.05)

	Input.action_press("asomar_der")
	await frames(30)
	var piv: Node3D = j.get_child(1)
	revisar("asomarse desplaza la cabeza", piv.position.x > 0.3, piv.position.x)
	Input.action_release("asomar_der")
	await frames(30)
	revisar("volver de asomarse", absf(piv.position.x) < 0.05)

	# Robar la agenda completa manteniendo F.
	for info: Dictionary in Juego.lista:
		var obra: Obra = null
		for o: Obra in mision.obras:
			if o.datos["id"] == info["id"]:
				obra = o
		var centro := Vector3(obra.global_position.x, piso_y(obra.global_position.y) + 0.1, obra.global_position.z)
		if info["tipo"] == "pintura":
			var frente: Vector3 = obra.global_basis.z
			j.global_position = centro + frente * 1.3
			await frames(3)
			mirar(j, obra.global_position + frente * 0.07)
		else:
			await _acercarse(j, obra, 0.3, [1.3, 1.0])
		await frames(3)
		if Juego.robadas.is_empty():
			await foto("02_cuadro")
		revisar("mira la pieza %s" % info["id"], j.objetivo_uso == obra, j.texto_uso)
		Input.action_press("interactuar")
		await frames(int(obra.duracion * 60.0) + 12)
		Input.action_release("interactuar")
		await frames(2)
		revisar("robó %s" % info["id"], obra.robada)
		if Juego.robadas.size() == 1:
			await foto("03_marco_vacio")
	revisar("agenda tachada", Juego.faltantes() == 0)

	# Todos los escondites de coleccionables se pueden alcanzar y mirar.
	var coleccionable: Node3D = null
	for h: Node in mision.get_children():
		if h is Mision.Otros.Coleccionable:
			if coleccionable == null:
				coleccionable = h
			else:
				h.free()   # Si otra moneda ocupa el mismo escondite, el rayo la vería a ella.
	for slot: Array in mision.mapa.slots_coleccionable:
		var sitio := Vector3(slot[0], slot[1], slot[2])
		coleccionable.global_position = sitio
		await frames(2)
		var alcanzable: bool = await _acercarse(j, coleccionable)
		revisar("coleccionable alcanzable en %s" % sitio, alcanzable)
	var antes: int = Juego.bolso.size()
	await _acercarse(j, coleccionable)
	revisar("mira coleccionable", j.objetivo_uso == coleccionable, j.texto_uso)
	Input.action_press("interactuar")
	await frames(40)
	Input.action_release("interactuar")
	await frames(2)
	revisar("coleccionable al bolso", Juego.bolso.size() == antes + 1)

	mision.hud.alternar_pantalla()
	mision.hud._leer_item(0)
	revisar("la pantalla de agenda pausa el juego", get_tree().paused)
	await foto_pausada("04_agenda_bolso")
	mision.hud.alternar_pantalla()
	revisar("cerrar reanuda", not get_tree().paused)

	# Camioneta: gana.
	j.global_position = mision.mapa.pos_camioneta + Vector3(0, 0.1, 2.1)
	await frames(3)
	mirar(j, mision.mapa.pos_camioneta + Vector3.UP * 1.0)
	await frames(3)
	revisar("mira camioneta", j.objetivo_uso == mision.camioneta, j.texto_uso)
	await foto("05_camioneta")
	Input.action_press("interactuar")
	await frames(75)
	Input.action_release("interactuar")
	await foto("05b_huida")
	await frames(300)
	await get_tree().process_frame
	revisar("resultado completo tras huir", Juego.resultado == "completo", Juego.resultado)
	await frames(10)
	await get_tree().process_frame
	revisar("carga la escena final", get_tree().current_scene != null and get_tree().current_scene.name == "Final", get_tree().current_scene)
	if get_tree().current_scene != null:
		mision.free()
		await get_tree().process_frame
		await foto_pausada("06_final")
		get_tree().current_scene.free()
		get_tree().current_scene = null

	# Alarma: entra Mostro, dispara, rescata y huye.
	await nueva()
	j = mision.jugador
	var pos_polo: Vector3 = mision.mapa.punto_prueba
	j.global_position = pos_polo
	await frames(5)
	var g1: Guardia = get_tree().get_nodes_in_group("guardias")[0]
	g1.ruta = []
	g1.global_position = pos_polo + Vector3(0, 0, -4)
	g1.look_at(Vector3(pos_polo.x, g1.global_position.y, pos_polo.z), Vector3.UP)
	var espera: int = 0
	while not Juego.alarma and espera < 300:
		await get_tree().physics_frame
		espera += 1
	revisar("el guardia detecta y suena la alarma", Juego.alarma, espera)
	while Juego.control_bloqueado and espera < 900:
		await get_tree().physics_frame
		espera += 1
	revisar("control pasa a Mostro", j.personaje == Jugador.Personaje.MOSTRO and not Juego.control_bloqueado)
	await foto("07_mostro")
	var g2: Guardia = get_tree().get_nodes_in_group("guardias")[0]
	g2.vida = 1
	j.global_position = g2.global_position + Vector3(0, 0.1, 3)
	await frames(2)
	mirar(j, g2.global_position + Vector3.UP * 1.1)
	await frames(2)
	var balas: int = j.balas
	j.disparar()
	await frames(2)
	revisar("el disparo gasta bala", j.balas == balas - 1)
	revisar("el disparo abate al guardia", g2.estado == Guardia.Estado.MUERTO)

	# Los tiros aciertan en cabeza, torso y piernas, no solo en el centro.
	for alto_tiro: Array in [[1.72, 3], [1.13, 1], [0.35, 1]]:
		var blanco: Guardia = get_tree().get_nodes_in_group("guardias")[0]
		blanco.vida = 5
		j.global_position = blanco.global_position + Vector3(0, 0.1, 3.5)
		await frames(2)
		mirar(j, blanco.global_position + Vector3.UP * (alto_tiro[0] as float))
		await frames(2)
		j.disparar()
		await frames(2)
		revisar("tiro a altura %s" % alto_tiro[0], blanco.vida == 5 - (alto_tiro[1] as int), blanco.vida)
	var ultimo: Guardia = get_tree().get_nodes_in_group("guardias")[0]
	for g: Node in get_tree().get_nodes_in_group("guardias"):
		g.process_mode = Node.PROCESS_MODE_DISABLED
	ultimo.process_mode = Node.PROCESS_MODE_INHERIT
	ultimo.vida = 1
	var hacia_g: Vector3 = (ultimo.global_position - pos_polo).normalized()
	j.global_position = ultimo.global_position - Vector3(hacia_g.x, 0, hacia_g.z) * 1.8 + Vector3.UP * 0.1
	await frames(2)
	mirar(j, ultimo.global_position + Vector3.UP * 1.1)
	await frames(2)
	j.disparar()
	await frames(4)
	await foto_pausada("08_sangre")
	await frames(170)
	revisar("el guardia cae", ultimo.estado == Guardia.Estado.MUERTO)
	mirar(j, ultimo.global_position + Vector3.UP * 0.1)
	await foto("09_charco")

	quitar_peligros()
	j.global_position = pos_polo + Vector3(1.4, 0, 0)
	await frames(3)
	mirar(j, pos_polo + Vector3.UP * 0.6)
	await frames(3)
	revisar("Mostro encuentra a Polo", j.objetivo_uso == mision.polo_escondido, j.texto_uso)
	await foto("10_polo_escondido")
	Input.action_press("interactuar")
	await frames(75)
	Input.action_release("interactuar")
	await frames(3)
	revisar("Polo rescatado", j.polo_rescatado)

	j.recibir_dano(1000)
	await frames(90)
	await get_tree().process_frame
	revisar("morir termina la misión", Juego.resultado == "fallo", Juego.resultado)

	print("RESULTADO: %d fallos" % fallos)
	get_tree().quit(1 if fallos > 0 else 0)
