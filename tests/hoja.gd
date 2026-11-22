extends SceneTree
## Junta capturas en hojas de 4x4 para revisarlas de un vistazo.
## Uso: Godot --headless --path . -s tests/hoja.gd -- <prefijo> [cada]
## Lee capturas/<prefijo>NN.png y guarda capturas/hoja_<prefijo>_N.png.

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var prefijo: String = args[0]
	var cada: int = int(args[1]) if args.size() > 1 else 1
	var archivos: Array[String] = []
	for f: String in DirAccess.get_files_at("res://capturas"):
		if f.begins_with(prefijo) and f.ends_with(".png") and f.trim_prefix(prefijo).trim_suffix(".png").is_valid_int():
			archivos.append(f)
	archivos.sort()
	var elegidos: Array[String] = []
	for i: int in archivos.size():
		if i % cada == 0:
			elegidos.append(archivos[i])
	var hoja_n: int = 0
	for inicio: int in range(0, elegidos.size(), 16):
		var hoja := Image.create(1280, 720, false, Image.FORMAT_RGB8)
		for k: int in mini(16, elegidos.size() - inicio):
			var img := Image.load_from_file("res://capturas/" + elegidos[inicio + k])
			img.convert(Image.FORMAT_RGB8)
			img.resize(320, 180)
			hoja.blit_rect(img, Rect2i(0, 0, 320, 180), Vector2i((k % 4) * 320, (k / 4) * 180))
		hoja.save_png("res://capturas/hoja_%s_%d.png" % [prefijo.trim_suffix("_"), hoja_n])
		print("hoja ", hoja_n, ": ", elegidos[inicio], " .. ", elegidos[mini(inicio + 15, elegidos.size() - 1)])
		hoja_n += 1
	quit()
