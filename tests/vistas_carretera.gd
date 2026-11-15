extends Node
## Corre la escena de la carretera sola, con los diálogos automáticos, y guarda
## una foto cada segundo en capturas/carretera_NN.png.
## En la pelea apunta al helicóptero y dispara sola; Polo no esquiva, así que
## también se prueba que los misiles pegan y que la pelea se reinicia. Pasado un
## rato le baja la vida al helicóptero para ver el derribo.
## Ejecutar con ventana:  Godot_console --path . tests/vistas_carretera.tscn

var _escena: Node


func _ready() -> void:
	_escena = (load("res://escenas/carretera.tscn") as PackedScene).instantiate()
	_escena.set("automatica", true)
	_escena.set("directo_a_pelea", "pelea" in OS.get_cmdline_user_args())
	get_tree().root.add_child.call_deferred(_escena)
	DirAccess.make_dir_recursive_absolute("res://capturas")
	var inicio_pelea: int = -1
	var reinicios: int = 0
	var visto_reinicio: bool = false
	for i: int in 140:
		await get_tree().create_timer(1.0).timeout
		if not is_instance_valid(_escena) or not _escena.is_inside_tree():
			print("FIN: la escena terminó (fue a la pantalla final)")
			break
		var jv: Variant = _escena.get("jugador")
		var j: Jugador = jv as Jugador if is_instance_valid(jv) else null
		var heli: Elihcotero = _escena.get("helicoptero")
		var peleando: bool = j != null and not Juego.control_bloqueado
		if peleando and inicio_pelea < 0:
			inicio_pelea = i
			print("PELEA empieza en el segundo ", i)
		if j != null and Juego.control_bloqueado and not visto_reinicio and inicio_pelea >= 0 and heli.vida > 0:
			visto_reinicio = true
			reinicios += 1
			print("REINICIO de la pelea (Polo cayó)")
		if peleando:
			visto_reinicio = false
			_apuntar_y_disparar(j, heli)
			if i - inicio_pelea > int(OS.get_environment("DERRIBO_EN") if OS.has_environment("DERRIBO_EN") else "28"):
				heli.recibir_cohete(heli.global_position)   # Para llegar al derribo.
		print("  proyectiles en vuelo: ", get_tree().get_nodes_in_group("proyectiles").size())
		print("carretera_%02d  FPS %d  vida_polo %s  vida_jefe %s" % [i, Engine.get_frames_per_second(), str(j.vida) if j else "-", str(heli.vida) if heli else "-"])
		get_viewport().get_texture().get_image().save_png("res://capturas/carretera_%02d.png" % i)
	print("REINICIOS ", reinicios)
	get_tree().quit()


func _apuntar_y_disparar(j: Jugador, heli: Elihcotero) -> void:
	var blanco: Vector3 = heli.global_transform * (Elihcotero.ZONAS[0][0] as Vector3)
	blanco += (heli.get("_vel_actual") as Vector3) * 0.45
	j.mirar_hacia(blanco)
	var pivote: Node3D = j.get("_pivote")
	var d: Vector3 = blanco - pivote.global_position
	pivote.rotation.x = atan2(d.y, Vector2(d.x, d.z).length())
	# Se dispara directo: un Input.action_press a mitad de cuadro no se alcanza a
	# ver como "recién presionado" (con el mouse de verdad sí).
	var arma: Lanzacohetes = _escena.get("lanzacohetes")
	if arma and arma.cargado:
		arma.disparar()
