extends Node3D
## Una foto de cada obra (las de la agenda y las de relleno) en su sitio del museo,
## en capturas/obra_NN.png. Ejecutar con ventana:  Godot_console --path . tests/vistas_obras.tscn

func _ready() -> void:
	Mision.saltar_intro = true
	var mision := Mision.new()
	add_child(mision)
	await get_tree().process_frame
	for g: Node in get_tree().get_nodes_in_group("guardias"):
		g.process_mode = Node.PROCESS_MODE_DISABLED
	var cam := Camera3D.new()
	add_child(cam)
	cam.make_current()
	cam.fov = 60.0
	DirAccess.make_dir_recursive_absolute("res://capturas")
	var n: int = 0
	var solo: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else ""
	for o: Node in mision.find_children("*", "Obra", true, false):
		var obra := o as Obra
		if solo != "" and obra.datos["id"] != solo:
			continue
		var frente: Vector3 = obra.global_basis.z
		var pintura: bool = obra.datos.get("tipo", "pintura") == "pintura"
		var centro: Vector3 = obra.global_position + (Vector3.ZERO if pintura else Vector3.UP * 0.5)
		if not pintura:
			# Pedestal: se busca un lado sin pared para la cámara.
			var espacio := get_world_3d().direct_space_state
			for dir: Vector3 in [frente, -frente, obra.global_basis.x, -obra.global_basis.x]:
				var q := PhysicsRayQueryParameters3D.create(centro, centro + dir * 2.4 + Vector3.UP * 0.2)
				if espacio.intersect_ray(q).is_empty():
					frente = dir
					break
		cam.global_position = centro + frente * (2.6 if pintura else 2.2) + Vector3.UP * 0.2
		cam.look_at(centro)
		await get_tree().create_timer(0.25).timeout
		print("obra_%02d  %s" % [n, obra.datos["id"]])
		get_viewport().get_texture().get_image().save_png("res://capturas/obra_%02d.png" % n)
		n += 1
	get_tree().quit()
