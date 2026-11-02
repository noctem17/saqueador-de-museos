extends Control
## Cierre: no muestra dinero, muestra lo que desapareció.


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Color("0b0e16")
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado: String in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 56)
	add_child(margen)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	margen.add_child(col)

	var titulo := Label.new()
	titulo.text = "LO QUE EL PAÍS DEJÓ DE VER"
	titulo.add_theme_font_size_override("font_size", 38)
	col.add_child(titulo)

	var veredicto := Label.new()
	veredicto.text = _veredicto()
	veredicto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	veredicto.add_theme_font_size_override("font_size", 19)
	veredicto.add_theme_color_override("font_color", Color("e0b34a"))
	col.add_child(veredicto)

	var cuerpo := RichTextLabel.new()
	cuerpo.bbcode_enabled = true
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_font_size_override("normal_font_size", 18)
	cuerpo.text = _listado()
	col.add_child(cuerpo)

	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 12)
	col.add_child(botones)
	var otra := Button.new()
	otra.text = "Otro encargo"
	otra.pressed.connect(func() -> void: get_tree().change_scene_to_file(Juego.ESCENA_MISION))
	botones.add_child(otra)
	var menu := Button.new()
	menu.text = "Menú"
	menu.pressed.connect(func() -> void: get_tree().change_scene_to_file(Juego.ESCENA_MENU))
	botones.add_child(menu)


func _veredicto() -> String:
	var n: int = Juego.robadas.size()
	match Juego.resultado:
		"completo":
			return "Mostro: \"Buen trabajo. Mañana abren el museo y nadie va a preguntar por lo que ya no está.\""
		"parcial":
			return "Mostro: \"Se quedaron algunas. Las que salieron no vuelven.\" Piezas desaparecidas: %d de %d." % [n, Juego.lista.size()]
		_:
			return "Mostro cayó en el museo. Las piezas que alcanzaron a salir nunca aparecieron: %d de %d." % [n, Juego.lista.size()]


func _listado() -> String:
	var texto: String = ""
	if Juego.robadas.is_empty():
		texto = "Esta noche no desapareció ninguna pieza. Las paredes siguen hablando.\n\n"
	for id: String in Juego.robadas:
		var o: Dictionary = Catalogo.obra(id)
		texto += "[b]%s[/b] — %s\n%s\n\n" % [o["titulo"], Juego.credito(o), o["texto"]]
	var extras: int = Juego.bolso.size() - Juego.robadas.size()
	if extras > 0:
		texto += "[i]Piezas de historia que quedaron en el bolso de Polo sin que nadie las reclamara: %d.[/i]\n" % extras
	return texto
