extends Node3D
## Fotos del Museo Nacional desde puntos fijos, para revisar el mapa sin jugar.
## Ejecutar con ventana:  Godot_console --path . tests/vistas_museo.tscn
## Las imágenes quedan en capturas/museo_*.png

const VISTAS: Array = [
	# [archivo, posición de la cámara, punto al que mira]
	["museo_00_aerea", Vector3(48, 62, 72), Vector3(0, 0, 8)],
	["museo_01_fachada", Vector3(9, 1.7, 45), Vector3(-2, 3.5, 30)],
	["museo_02_hall", Vector3(5, 1.7, 28.5), Vector3(-3, 1.4, 19)],
	["museo_03_vestibulo", Vector3(0, 1.7, 17.2), Vector3(0, 1.6, 6)],
	["museo_04_centro", Vector3(-5, 1.8, 5), Vector3(4, 2.2, -6)],
	["museo_05_brazo_norte", Vector3(1.5, 1.7, -9), Vector3(-1, 1.6, -28)],
	["museo_06_sala_oro", Vector3(9, 1.7, 1.5), Vector3(28, 1.2, -2)],
	["museo_07_salas_2_3", Vector3(-9, 1.7, -1.5), Vector3(-28, 1.4, 1)],
	["museo_08_patio_fuente", Vector3(-9, 1.7, 9), Vector3(-20, 1.5, 13)],
	["museo_09_sala_5", Vector3(9.5, 1.7, 19.5), Vector3(20, 1.2, 27)],
	["museo_10_sala_1", Vector3(-9.5, 1.7, 19.5), Vector3(-22, 1.4, 27)],
]


func _ready() -> void:
	Mision.saltar_intro = true
	var mision := Mision.new()
	add_child(mision)
	await get_tree().process_frame
	for g: Node in get_tree().get_nodes_in_group("guardias"):
		g.process_mode = Node.PROCESS_MODE_DISABLED
	mision.hud.visible = false
	var cam := Camera3D.new()
	cam.fov = 70.0
	add_child(cam)
	cam.make_current()
	await get_tree().create_timer(1.0).timeout
	DirAccess.make_dir_recursive_absolute("res://capturas")
	for v: Array in VISTAS:
		cam.global_position = v[1]
		cam.look_at(v[2])
		cam.far = 400.0
		for i: int in 4:
			await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://capturas/%s.png" % v[0])
	get_tree().quit()
