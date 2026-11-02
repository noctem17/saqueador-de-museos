extends Node3D
## Foto de todos los personajes y vehículos para ajustar modelos.
## Ejecutar con ventana:  Godot_console --path . tests/retratos.tscn

const FOTOS: Array = [
	# [archivo, posición de cámara, objetivo]
	["r_grupo", Vector3(0, 1.3, 4.6), Vector3(0, 1.0, 0)],
	["r_mostro", Vector3(-2.25, 1.65, 0.75), Vector3(-2.25, 1.6, 0)],
	["r_mostro2", Vector3(-1.6, 1.65, 0.3), Vector3(-2.25, 1.6, 0)],
	["r_arma", Vector3(0.2, 1.35, 1.0), Vector3(0.65, 1.3, 0.3)],
	["r_arma2", Vector3(1.4, 1.5, 0.3), Vector3(0.6, 1.3, 0.3)],
	["r_cadera", Vector3(-0.2, 1.0, 1.0), Vector3(-0.6, 0.9, 0)],
	["r_agachado", Vector3(5.0, 1.0, 2.2), Vector3(5, 0.6, 0)],
	["r_agachado2", Vector3(6.8, 1.0, 0.8), Vector3(5, 0.6, 0)],
	["r_camioneta", Vector3(-7, 2.0, 4.5), Vector3(-7, 0.8, -1)],
]


func _ready() -> void:
	var mundo := WorldEnvironment.new()
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color("46505e")
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color.WHITE
	entorno.ambient_light_energy = 0.7
	mundo.environment = entorno
	add_child(mundo)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-40, 25, 0)
	add_child(sol)

	var poses: Array = [["polo", -3.6, "Idle"], ["mostro", -2.25, "Idle"], ["guardia", -0.6, "Idle"], ["guardia", 0.9, "Idle_Gun_Pointing"], ["policia", 2.7, "Run_Shoot"]]
	for p: Array in poses:
		var c: Cuerpo = Cuerpo.crear(p[0])
		add_child(c)
		c.position.x = p[1]
		c.rotation.y = PI   # Mirando a la cámara.
		c.reproducir(p[2], 0.0)
		if p[0] == "guardia" and p[2] != "Idle" or p[0] == "policia":
			c.mano_armada(true)
	var hecho: Cuerpo = Cuerpo.crear("polo")
	add_child(hecho)
	hecho.position = Vector3(5, 0, 0)
	hecho.rotation.y = PI
	hecho.agachar()

	var suv: Node3D = (load("res://modelos/camioneta.glb") as PackedScene).instantiate()
	add_child(suv)
	suv.position = Vector3(-7, 0, -1)

	var cam := Camera3D.new()
	add_child(cam)
	cam.make_current()
	await get_tree().create_timer(0.8).timeout
	DirAccess.make_dir_recursive_absolute("res://capturas")
	for f: Array in FOTOS:
		cam.global_position = f[1]
		cam.look_at(f[2])
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://capturas/%s.png" % f[0])
	get_tree().quit()
