extends Node3D
## Fotos de un modelo en varias animaciones a la vez, una copia por animación,
## para revisar que las animaciones copiadas se vean bien.
## Uso:  Godot_console --path . tests/vistas_modelos.tscn -- res://modelos/polo_mx.glb Idle Walk ...
## Queda en capturas/modelos_<nombre>.png (de frente) y _lado.png (de lado).

func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var ruta: String = args[0] if args.size() > 0 else "res://modelos/polo_mx.glb"
	var anims: Array = Array(args.slice(1)) if args.size() > 1 else ["Idle", "Walk", "Run", "Idle_Gun_Pointing", "Punch_Right", "Death", "Interact", "Kick_Left"]
	var proporcion: float = 0.35
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-40, 30, 0)
	add_child(sol)
	var mundo := WorldEnvironment.new()
	mundo.environment = Environment.new()
	mundo.environment.background_mode = Environment.BG_COLOR
	mundo.environment.background_color = Color("8a9099")
	mundo.environment.ambient_light_color = Color.WHITE
	mundo.environment.ambient_light_energy = 0.6
	add_child(mundo)
	var piso := MeshInstance3D.new()
	piso.mesh = PlaneMesh.new()
	(piso.mesh as PlaneMesh).size = Vector2(40, 10)
	add_child(piso)
	var escena: PackedScene = load(ruta)
	for i: int in anims.size():
		var m := escena.instantiate() as Node3D
		add_child(m)
		m.position.x = (i - (anims.size() - 1) * 0.5) * 1.5
		var ap := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var etiqueta := Label3D.new()
		etiqueta.text = anims[i]
		etiqueta.position = Vector3(m.position.x, 2.05, 0)
		etiqueta.font_size = 40
		add_child(etiqueta)
		# "nombre@0.7" = la animación en ese punto (por defecto 0.35).
		var nombre: String = String(anims[i]).get_slice("@", 0)
		var punto: float = float(String(anims[i]).get_slice("@", 1)) if "@" in anims[i] else proporcion
		if not ap.has_animation(nombre):
			print("NO EXISTE ", nombre, " en ", ap.get_animation_list())
			continue
		ap.play(nombre)
		ap.seek(ap.get_animation(nombre).length * punto, true)
		ap.pause()
	var cam := Camera3D.new()
	add_child(cam)
	var ancho: float = anims.size() * 1.5
	cam.position = Vector3(0, 1.0, ancho * 0.42 + 0.8)
	cam.look_at(Vector3(0, 0.9, 0))
	DirAccess.make_dir_recursive_absolute("res://capturas")
	var nombre: String = ruta.get_file().get_basename()
	for i: int in 3:
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://capturas/modelos_%s_%s.png" % [nombre, OS.get_environment("SUF")])
	for m: Node in get_children():
		if m.has_method("instantiate") or m.find_child("AnimationPlayer", true, false):
			(m as Node3D).rotation.y = -PI * 0.5
	await get_tree().create_timer(0.2).timeout
	get_viewport().get_texture().get_image().save_png("res://capturas/modelos_%s_lado.png" % nombre)
	get_tree().quit()
