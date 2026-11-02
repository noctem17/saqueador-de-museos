extends Control
## Pantalla de título.


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Color("0b0e16")
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.custom_minimum_size.x = 420
	centro.add_child(col)

	var titulo := Label.new()
	titulo.text = "EL ENCARGO"
	titulo.add_theme_font_size_override("font_size", 64)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(titulo)
	var sub := Label.new()
	sub.text = "Lo que no se ve, no pasó."
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color("e0b34a"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)

	var separador := Control.new()
	separador.custom_minimum_size.y = 24
	col.add_child(separador)

	var jugar := Button.new()
	jugar.text = "Jugar"
	jugar.add_theme_font_size_override("font_size", 22)
	jugar.pressed.connect(func() -> void: get_tree().change_scene_to_file(Juego.ESCENA_MISION))
	col.add_child(jugar)
	var salir := Button.new()
	salir.text = "Salir"
	salir.add_theme_font_size_override("font_size", 22)
	salir.pressed.connect(func() -> void: get_tree().quit())
	col.add_child(salir)
	jugar.grab_focus()
