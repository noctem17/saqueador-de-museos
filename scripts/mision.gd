class_name Mision
extends Node3D
## Arma una partida: reparte las piezas al azar y dirige la historia
## (llamada, sigilo, alarma, entrada de Mostro y huida).

const Otros := preload("res://scripts/otros_interactuables.gd")
const MAX_POLICIAS: int = 6
const INTERVALO_POLICIA: float = 18.0

var mapa: MapaPrueba
var jugador: Jugador
var hud: Hud
var camioneta: Otros.Vehiculo
var polo_escondido: Otros.PoloEscondido
var obras: Array[Obra] = []

var _reloj_policia: Timer
var _terminado: bool = false
var _camioneta_visual: Node3D
## Se pone en true en las pruebas automáticas para saltarse la llamada inicial.
static var saltar_intro: bool = false


func _ready() -> void:
	Juego.nueva_mision()
	mapa = MapaPrueba.new()
	add_child(mapa)
	mapa.construir()

	jugador = Jugador.new()
	jugador.position = MapaPrueba.SPAWN_POLO
	add_child(jugador)
	jugador.rotation.y = 0.0

	_repartir_obras()
	_repartir_coleccionables()
	_crear_terminal()
	_crear_camioneta()
	camioneta.escapar.connect(_huir)
	_crear_camaras()
	_crear_guardias()

	hud = Hud.new()
	add_child(hud)
	hud.jugador = jugador

	_reloj_policia = Timer.new()
	_reloj_policia.wait_time = INTERVALO_POLICIA
	_reloj_policia.timeout.connect(_llegada_policia)
	add_child(_reloj_policia)

	Juego.alarma_disparada.connect(_on_alarma)
	jugador.vida_cambio.connect(_on_vida)
	Juego.agenda_cambio.connect(_revisar_objetivo)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_introduccion()


func _process(delta: float) -> void:
	if not Juego.control_bloqueado and not _terminado:
		Juego.tiempo_mision += delta


## Lo que está en la agenda siempre aparece, pero en un sitio distinto cada partida.
func _repartir_obras() -> void:
	var paredes: Array = MapaPrueba.SLOTS_PARED.duplicate()
	var pedestales: Array = MapaPrueba.SLOTS_PEDESTAL.duplicate()
	paredes.shuffle()
	pedestales.shuffle()
	var relleno: Array = Catalogo.RELLENO.duplicate()
	relleno.shuffle()
	var indice_pared: int = 0
	var indice_ped: int = 0
	for info: Dictionary in Catalogo.OBRAS:
		if info["tipo"] == "pintura":
			_colocar_cuadro(info, paredes[indice_pared])
			indice_pared += 1
		else:
			var slot: Array = pedestales[indice_ped]
			indice_ped += 1
			var o := Obra.new()
			add_child(o)
			o.position = Vector3(slot[0], 1.0, slot[1])
			o.rotation.y = randf() * TAU
			o.configurar(info)
			obras.append(o)
	while indice_pared < paredes.size() and not relleno.is_empty():
		var extra: Dictionary = relleno.pop_back()
		_colocar_cuadro(extra, paredes[indice_pared])
		indice_pared += 1


func _colocar_cuadro(info: Dictionary, slot: Array) -> void:
	var o := Obra.new()
	add_child(o)
	o.position = Vector3(slot[0], 1.85, slot[1])
	o.rotation_degrees.y = slot[2]
	o.configurar(info)
	obras.append(o)


func _repartir_coleccionables() -> void:
	var sitios: Array = MapaPrueba.SLOTS_COLECCIONABLE.duplicate()
	sitios.shuffle()
	var piezas: Array = Catalogo.COLECCIONABLES.duplicate()
	piezas.shuffle()
	for i: int in mini(Juego.COLECCIONABLES_POR_MISION, piezas.size()):
		var c := Otros.Coleccionable.new()
		add_child(c)
		c.position = Vector3(sitios[i][0], 0.95, sitios[i][1])
		c.configurar(piezas[i])


func _crear_terminal() -> void:
	var t := Otros.Terminal.new()
	add_child(t)
	t.position = MapaPrueba.POS_TERMINAL
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
	camioneta.position = MapaPrueba.POS_CAMIONETA
	camioneta.agregar_colision(Vector3(2.5, 2.3, 5.4), Vector3(0, 1.15, 0))
	_camioneta_visual = Node3D.new()
	camioneta.add_child(_camioneta_visual)
	var pintura := StandardMaterial3D.new()
	pintura.albedo_color = Color("23262d")
	pintura.roughness = 0.35
	pintura.metallic = 0.4
	var vidrio := StandardMaterial3D.new()
	vidrio.albedo_color = Color("0c1016")
	vidrio.roughness = 0.1
	var llanta := StandardMaterial3D.new()
	llanta.albedo_color = Color("0d0d0f")
	var partes: Array = [
		[Vector3(2.2, 1.2, 5.0), Vector3(0, 0.95, 0), pintura],
		[Vector3(2.05, 0.75, 3.3), Vector3(0, 1.9, 0.5), pintura],
		[Vector3(2.08, 0.5, 0.05), Vector3(0, 1.92, -1.17), vidrio],
		[Vector3(0.3, 0.7, 0.7), Vector3(-1.1, 0.4, 1.6), llanta],
		[Vector3(0.3, 0.7, 0.7), Vector3(1.1, 0.4, 1.6), llanta],
		[Vector3(0.3, 0.7, 0.7), Vector3(-1.1, 0.4, -1.6), llanta],
		[Vector3(0.3, 0.7, 0.7), Vector3(1.1, 0.4, -1.6), llanta],
	]
	for p: Array in partes:
		var m := MeshInstance3D.new()
		var caja := BoxMesh.new()
		caja.size = p[0]
		m.mesh = caja
		m.position = p[1]
		m.material_override = p[2]
		_camioneta_visual.add_child(m)
	# Un cuerpo aparte para que los guardias y el jugador no atraviesen la camioneta.
	var solido := StaticBody3D.new()
	solido.collision_layer = Juego.CAPA_MUNDO
	solido.collision_mask = 0
	var col := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(2.2, 2.3, 5.0)
	col.shape = forma
	col.position.y = 1.15
	solido.add_child(col)
	camioneta.add_child(solido)


func _crear_camaras() -> void:
	for dato: Array in MapaPrueba.CAMARAS:
		var c := CamaraSeguridad.new()
		c.position = Vector3(dato[0], dato[1], dato[2])
		c.giro_base = dato[3]
		add_child(c)


func _crear_guardias() -> void:
	for ruta: Array in MapaPrueba.PATRULLAS:
		var g := Guardia.new()
		for punto: Array in ruta:
			g.ruta.append(Vector3(punto[0], 0.0, punto[1]))
		add_child(g)
		g.global_position = g.ruta[0]


func _introduccion() -> void:
	if saltar_intro:
		Juego.anotadas = Juego.lista.size()
		hud._refrescar_agenda()
		hud.fundir(0.0, 0.01)
		Juego.control_bloqueado = false
		_revisar_objetivo()
		return
	hud.fijar_objetivo("Llamada entrante: Mostro")
	hud._refrescar_agenda()
	await hud.fundir(0.0, 1.0)
	var lineas: Array[Dictionary] = [
		{"quien": "MOSTRO", "texto": "Polo. Saque la agenda y anote."},
		{"quien": "POLO", "texto": "Diga, jefe."},
		{"quien": "MOSTRO", "texto": "Esta noche entra al Miguel Urrutia. Hay unas piezas que no quiero que sigan ahí."},
		{"quien": "POLO", "texto": "¿Para vender?"},
		{"quien": "MOSTRO", "texto": "No. Nadie las compra, nadie las cuelga. Nadie las vuelve a ver. Lo que no se ve, no pasó."},
	]
	for o: Dictionary in Juego.lista:
		lineas.append({"quien": "MOSTRO", "texto": "«%s», de %s. %s" % [o["titulo"], o["autor"], o["razon"]], "anota": true})
	lineas.append({"quien": "MOSTRO", "texto": "Las cambian de sitio seguido, así que búsquelas sala por sala. Y no me haga ir: si yo entro, no entro a mirar cuadros."})
	await hud.reproducir_llamada(lineas)
	Juego.control_bloqueado = false
	_revisar_objetivo()
	hud.mostrar_aviso("TAB: agenda y bolso. ESC: controles.")


func _revisar_objetivo() -> void:
	if _terminado:
		return
	if jugador.personaje == Jugador.Personaje.MOSTRO and not jugador.polo_rescatado:
		hud.fijar_objetivo("Encuentra a Polo (marcado en amarillo)")
	elif Juego.faltantes() > 0 and not Juego.alarma:
		hud.fijar_objetivo("Piezas por desaparecer: %d" % Juego.faltantes())
	elif Juego.faltantes() > 0:
		hud.fijar_objetivo("Sal en la camioneta. Piezas pendientes: %d" % Juego.faltantes())
	else:
		hud.fijar_objetivo("Vuelve a la camioneta en el parqueadero")


func _on_alarma(motivo: String) -> void:
	_alarma_en_curso(motivo)


func _alarma_en_curso(motivo: String) -> void:
	Juego.control_bloqueado = true
	_encender_luces_alarma()
	var pos_polo: Vector3 = jugador.global_position
	var causa: String = "Una cámara lo pilló." if motivo == "camara" else "Lo vio un guardia."
	await hud.reproducir_llamada([
		{"quien": "POLO", "texto": "Jefe, me vieron. Suena la alarma.", "dura": 1.6},
		{"quien": "MOSTRO", "texto": "%s Escóndase y no se mueva. Ya voy." % causa, "dura": 2.0},
	], true)
	await hud.fundir(1.0, 0.4)
	polo_escondido = Otros.PoloEscondido.new()
	polo_escondido.rescatado.connect(_on_polo_rescatado)
	add_child(polo_escondido)
	polo_escondido.global_position = Vector3(pos_polo.x, 0.0, pos_polo.z)
	_crear_marcador(polo_escondido)
	jugador.cambiar_a_mostro(MapaPrueba.SPAWN_MOSTRO, Vector3(0, 0, 0))
	await hud.fundir(0.0, 0.4)
	Juego.control_bloqueado = false
	_reloj_policia.start()
	_revisar_objetivo()


func _crear_marcador(destino: Node3D) -> void:
	var marca := Label3D.new()
	marca.text = "POLO"
	marca.font_size = 72
	marca.pixel_size = 0.006
	marca.modulate = Color(1.0, 0.85, 0.2)
	marca.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marca.no_depth_test = true
	marca.fixed_size = false
	marca.position.y = 1.7
	destino.add_child(marca)


func _on_polo_rescatado() -> void:
	hud.mostrar_aviso("Polo está con usted. Terminen la lista si se atreven.")
	_revisar_objetivo()


func _encender_luces_alarma() -> void:
	for hijo: Node in mapa.get_children():
		if hijo is OmniLight3D and (hijo as OmniLight3D).shadow_enabled:
			var luz := hijo as OmniLight3D
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
	g.global_position = MapaPrueba.SPAWN_POLICIA.pick_random()
	hud.mostrar_aviso("Llegó la policía")


func _on_vida() -> void:
	if jugador.vida <= 0 and not _terminado:
		_terminar("fallo")


func _huir() -> void:
	if _terminado:
		return
	_terminado = true
	Juego.control_bloqueado = true
	var camara := Camera3D.new()
	add_child(camara)
	camara.global_position = Vector3(0, 3.0, 27.0)
	camara.look_at(camioneta.global_position + Vector3.UP)
	camara.make_current()
	var tween := create_tween()
	tween.tween_property(camioneta, "position:x", -30.0, 2.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	_terminar("completo" if Juego.faltantes() == 0 else "parcial")


func _terminar(resultado: String) -> void:
	_terminado = true
	Juego.resultado = resultado
	Juego.control_bloqueado = true
	await hud.fundir(1.0, 0.7)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(Juego.ESCENA_FINAL)
