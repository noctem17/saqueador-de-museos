extends Node3D
## Fotos del Museo Nacional desde puntos fijos, para revisar el mapa sin jugar, y
## FPS medidos en cada punto.
## Ejecutar con ventana:  Godot_console --path . --disable-vsync tests/vistas_museo.tscn
## Las imágenes quedan en capturas/museo_*.png

const VISTAS: Array = [
	# [archivo, posición de la cámara, punto al que mira]
	["museo_00_aerea", Vector3(70, 75, 110), Vector3(0, 0, 0)],
	["museo_01_calle", Vector3(14, -0.2, 60), Vector3(-2, 5, 36)],
	["museo_02_fachada", Vector3(-24, 1.5, 48), Vector3(4, 7, 36)],
	["museo_03_vestibulo", Vector3(6, 1.7, 35), Vector3(-2, 1.8, 23)],
	["museo_04_escalera", Vector3(7.8, 1.7, 21), Vector3(-2, 3.5, 13)],
	["museo_05_centro_pozo", Vector3(-7, 1.6, 6.5), Vector3(0, 5.5, -2)],
	["museo_06_brazo_norte_p1", Vector3(1.0, 1.7, -11), Vector3(0, 1.6, -50)],
	["museo_07_celdas_p2", Vector3(1.2, 6.2, -11.5), Vector3(-0.5, 5.6, -40)],
	["museo_08_celda_abierta", Vector3(1.5, 6.2, -18.8), Vector3(5.5, 5.6, -15)],
	["museo_09_rotonda_p3", Vector3(-6.5, 10.7, 5.5), Vector3(6, 10.5, -6)],
	["museo_10_sala6_oro", Vector3(11, 1.7, 1.5), Vector3(40, 1.0, -1)],
	["museo_11_patio_fuente", Vector3(-15, 1.7, 9), Vector3(-38, 3.0, 15)],
	["museo_12_patio_brazos", Vector3(-30, 1.7, -30), Vector3(-8, 6, -10)],
	["museo_13_sala7_p2", Vector3(26, 6.2, 34), Vector3(0, 6, 26)],
	["museo_14_temporal_p3", Vector3(-26, 10.7, 34), Vector3(0, 10.5, 26)],
	["museo_15_rampa", Vector3(44, -0.2, 51), Vector3(20, 0, 46)],
	["museo_16_piso_celdas_p2", Vector3(0.3, 6.0, -19.0), Vector3(2.6, 4.5, -25.0)],
	["museo_17_piso_celdas_p3", Vector3(-19.0, 10.5, 0.3), Vector3(-25.0, 9.0, 2.6)],
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
	cam.far = 500.0
	add_child(cam)
	cam.make_current()
	await get_tree().create_timer(1.0).timeout
	DirAccess.make_dir_recursive_absolute("res://capturas")
	for v: Array in VISTAS:
		cam.global_position = v[1]
		cam.look_at(v[2])
		await get_tree().create_timer(0.8).timeout
		print("%s  FPS %d  dibujos %d" % [v[0], Engine.get_frames_per_second(), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
		get_viewport().get_texture().get_image().save_png("res://capturas/%s.png" % v[0])
	get_tree().quit()
