extends Node3D
## Fotos de la espada de Bolívar: la jaula con el reloj, la escena de la espada,
## la carátula del reloj de cerca y la jaula subiendo. Quedan en capturas/espada_NN.png.
## Ejecutar con ventana:  Godot_console --path . tests/vistas_espada.tscn

var _n: int = 0


func _ready() -> void:
	Mision.saltar_intro = true
	var mision := Mision.new()
	add_child(mision)
	await get_tree().process_frame
	for g: Node in get_tree().get_nodes_in_group("guardias"):
		g.process_mode = Node.PROCESS_MODE_DISABLED
	var j: Jugador = mision.jugador
	j.global_position = Vector3(0.0, 0.1, 7.5)
	j.mirar_hacia(Vector3.ZERO)
	Juego.control_bloqueado = false
	await _foto(1.0)
	if not "rapido" in OS.get_cmdline_user_args():
		# La escena de la espada.
		mision._cine_espada()
		for i: int in 22:
			await _foto(1.0)
	# El reloj de cerca.
	j.global_position = Vector3(2.8, 0.1, 4.6)
	j.mirar_hacia(mision.reloj.global_position)
	mision.reloj.completar(j)
	await _foto(0.8)
	mision.reloj.minutos = 3 * 60 + 19
	mision.reloj._mostrar_hora()
	await _foto(0.5)
	mision.reloj._probar()
	for i: int in 5:
		await _foto(0.8)
	get_tree().quit()


func _foto(espera: float) -> void:
	await get_tree().create_timer(espera).timeout
	DirAccess.make_dir_recursive_absolute("res://capturas")
	get_viewport().get_texture().get_image().save_png("res://capturas/espada_%02d.png" % _n)
	print("espada_%02d  FPS %d" % [_n, Engine.get_frames_per_second()])
	_n += 1
