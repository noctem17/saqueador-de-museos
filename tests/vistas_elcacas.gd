extends Node3D
## La escena de Elcacas completa, con los diálogos automáticos. En el duelo juega
## sola: se asoma al lado que dice la flecha y pega cuando dice ¡AHORA! (el primer
## golpe lo recibe a propósito, para ver el daño). Foto cada medio segundo en
## capturas/elcacas_NNN.png.
## Ejecutar con ventana:  Godot_console --path . tests/vistas_elcacas.tscn -- automatica

var _n: int = 0
var _mision: Mision
var _primero: bool = true
var _foto: int = 0


func _ready() -> void:
	Mision.saltar_intro = true
	_mision = Mision.new()
	add_child(_mision)
	await get_tree().process_frame
	for c: Node in get_tree().get_nodes_in_group("camaras"):
		c.process_mode = Node.PROCESS_MODE_DISABLED
	var j: Jugador = _mision.jugador
	j.global_position = _mision.mapa.pos_espada + Vector3(2.0, 0.1, 0.5)
	j.mirar_hacia(_mision.mapa.pos_espada)
	Juego.control_bloqueado = false
	Juego.cine_espada_visto = true
	_mision.reloj.probar_hora(3 * 60 + 19)
	DirAccess.make_dir_recursive_absolute("res://capturas")
	await get_tree().create_timer(4.0).timeout
	_mision.espada.completar(j)
	var fin: int = Time.get_ticks_msec() + 240000
	while Time.get_ticks_msec() < fin:
		_pilotear()
		var cada: int = 8 if Engine.time_scale < 0.9 else 30   # Más fotos en cámara lenta.
		if _n % cada == 0:
			get_viewport().get_texture().get_image().save_png("res://capturas/elcacas_%03d.png" % _foto)
			_foto += 1
		_n += 1
		await get_tree().process_frame
		if Juego.alarma and _mision.espada.robada and not Juego.control_bloqueado:
			print("FIN: espada robada, alarma sonando, Polo con control")
			for i: int in 3:
				await get_tree().create_timer(0.5).timeout
				get_viewport().get_texture().get_image().save_png("res://capturas/elcacas_%03d.png" % (_foto + i))
			break
	print("espada robada: ", _mision.espada.robada, "  alarma: ", Juego.alarma, "  vida Polo: ", _mision.jugador.vida)
	get_tree().quit()


func _pilotear() -> void:
	var jefe: JefeElcacas = null
	for h: Node in _mision.get_children():
		if h is JefeElcacas:
			jefe = h
	if jefe == null or jefe.elcacas == null or not jefe.get("_peleando"):
		return
	var e: Elcacas = jefe.elcacas
	Input.action_release("asomar_izq")
	Input.action_release("asomar_der")
	if e.fase == Elcacas.Fase.AVISO:
		if _primero:
			return   # El primero no lo esquiva.
		var lado: int = e.get("_lado")
		Input.action_press("asomar_der" if lado >= 0 else "asomar_izq")
	elif e.fase == Elcacas.Fase.ABIERTO:
		_primero = false
		jefe.golpear()
