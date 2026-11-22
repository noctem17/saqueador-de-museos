extends Node3D
## Dispara la alarma con Polo dentro del museo y guarda la entrada de Mostro,
## una foto cada medio segundo, en capturas/mostro_NN.png.
## Ejecutar con ventana:  Godot_console --path . tests/vistas_mostro.tscn

func _ready() -> void:
	Mision.saltar_intro = true
	Juego.mostro_presentado = "corta" in OS.get_cmdline_user_args()
	var mision := Mision.new()
	add_child(mision)
	await get_tree().process_frame
	for g: Node in get_tree().get_nodes_in_group("guardias"):
		g.process_mode = Node.PROCESS_MODE_DISABLED
	var j: Jugador = mision.jugador
	j.global_position = Vector3(0, 0.1, 8.5)
	await get_tree().create_timer(1.0).timeout
	Juego.disparar_alarma("camara")
	DirAccess.make_dir_recursive_absolute("res://capturas")
	for i: int in 80:
		await get_tree().create_timer(0.5).timeout
		var m: AudioStreamPlayer = mision.get("_musica_mostro")
		var mp: AudioStreamPlayer = mision.get("_musica_polo")
		print("mostro_%02d  FPS %d  bloqueado %s  musica_polo %s" % [i, Engine.get_frames_per_second(), Juego.control_bloqueado, mp != null and mp.playing])
		get_viewport().get_texture().get_image().save_png("res://capturas/mostro_%02d.png" % i)
		if not Juego.control_bloqueado and i > 4:
			print("FIN: control para Mostro; música sonando: ", m != null and m.playing)
			break
	get_tree().quit()
