class_name Hud
extends CanvasLayer
## Interfaz de la misión: objetivo, agenda, llamadas, bolso y pausa.
## Se arma por código para que cada elemento quede en un solo archivo.

const COLOR_PAPEL := Color("eadfc4")
const COLOR_TINTA := Color("1f2a44")

var jugador: Jugador

var _objetivo: Label
var _agenda_mini: RichTextLabel
var _prompt: Label
var _barra_uso: ProgressBar
var _punto: Label
var _sospecha: ProgressBar
var _sospecha_txt: Label
var _aviso: Label
var _alarma: Label
var _estado: Label
var _vida: ProgressBar
var _vida_txt: Label
var _marca: Label
var _rojo: ColorRect
var _tween_marca: Tween
var _llamada: PanelContainer
var _llamada_quien: Label
var _llamada_texto: Label
var _llamada_ayuda: Label
var _fundido: ColorRect
var _pantalla: PanelContainer
var _agenda_grande: RichTextLabel
var _lista_bolso: ItemList
var _lectura: RichTextLabel
var _pausa: PanelContainer
var _tween_aviso: Tween
var _esperando_llamada: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_armar()
	Juego.agenda_cambio.connect(_refrescar_agenda)
	Juego.bolso_cambio.connect(_refrescar_bolso)
	Juego.aviso.connect(mostrar_aviso)


func _armar() -> void:
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)

	_objetivo = _etiqueta(raiz, 18)
	_objetivo.position = Vector2(24, 18)
	_objetivo.size = Vector2(560, 60)
	_objetivo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_estado = _etiqueta(raiz, 16)
	_estado.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_estado.offset_left = 24
	_estado.offset_right = 444
	_estado.offset_top = -46
	_estado.offset_bottom = -18

	# Agenda pequeña siempre a la vista: aquí se ve tachar cada obra.
	var papel := PanelContainer.new()
	papel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	papel.offset_left = -310
	papel.offset_top = 16
	papel.offset_right = -16
	papel.add_theme_stylebox_override("panel", _caja(COLOR_PAPEL, 12))
	raiz.add_child(papel)
	_agenda_mini = RichTextLabel.new()
	_agenda_mini.bbcode_enabled = true
	_agenda_mini.fit_content = true
	_agenda_mini.scroll_active = false
	_agenda_mini.add_theme_color_override("default_color", COLOR_TINTA)
	_agenda_mini.add_theme_font_size_override("normal_font_size", 16)
	papel.add_child(_agenda_mini)

	_punto = _etiqueta(raiz, 20)
	_punto.text = "·"
	_centrar(_punto, 0, -14, 30)

	_prompt = _etiqueta(raiz, 20)
	_centrar(_prompt, 0, 70, 760)
	_barra_uso = ProgressBar.new()
	_barra_uso.show_percentage = false
	_barra_uso.max_value = 1.0
	_barra_uso.custom_minimum_size = Vector2(280, 10)
	_barra_uso.visible = false
	raiz.add_child(_barra_uso)
	_centrar(_barra_uso, 0, 108, 280)

	_sospecha_txt = _etiqueta(raiz, 16)
	_sospecha_txt.text = "TE ESTÁN VIENDO"
	_sospecha_txt.visible = false
	_sospecha_txt.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_sospecha_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sospecha_txt.offset_left = -200
	_sospecha_txt.offset_right = 200
	_sospecha_txt.offset_top = 22
	_sospecha_txt.offset_bottom = 46
	_sospecha = ProgressBar.new()
	_sospecha.show_percentage = false
	_sospecha.max_value = 1.0
	_sospecha.visible = false
	_sospecha.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_sospecha.offset_left = -170
	_sospecha.offset_right = 170
	_sospecha.offset_top = 48
	_sospecha.offset_bottom = 60
	_sospecha.add_theme_stylebox_override("fill", _caja(Color("d9381e"), 0))
	raiz.add_child(_sospecha)

	_alarma = _etiqueta(raiz, 30)
	_alarma.text = "¡ALARMA!"
	_alarma.add_theme_color_override("font_color", Color("ff4b33"))
	_alarma.visible = false
	_alarma.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_alarma.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_alarma.offset_left = -240
	_alarma.offset_right = 240
	_alarma.offset_top = 64
	_alarma.offset_bottom = 108

	_aviso = _etiqueta(raiz, 20)
	_aviso.modulate.a = 0.0
	_centrar(_aviso, 0, 150, 800)

	_vida_txt = _etiqueta(raiz, 16)
	_vida_txt.text = "VIDA"
	_vida_txt.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_vida_txt.offset_left = 24
	_vida_txt.offset_right = 144
	_vida_txt.offset_top = -96
	_vida_txt.offset_bottom = -72
	_vida_txt.visible = false
	_vida = ProgressBar.new()
	_vida.show_percentage = false
	_vida.max_value = 100.0
	_vida.value = 100.0
	_vida.visible = false
	_vida.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_vida.offset_left = 24
	_vida.offset_right = 324
	_vida.offset_top = -70
	_vida.offset_bottom = -52
	_vida.add_theme_stylebox_override("fill", _caja(Color("3fae49"), 0))
	_vida.add_theme_stylebox_override("background", _caja(Color(0, 0, 0, 0.6), 0))
	raiz.add_child(_vida)

	_marca = _etiqueta(raiz, 34)
	_marca.text = "X"
	_marca.modulate.a = 0.0
	_centrar(_marca, 0, -26, 60)

	_rojo = ColorRect.new()
	_rojo.color = Color(0.6, 0.0, 0.0, 0.0)
	_rojo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rojo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(_rojo)

	_armar_llamada(raiz)
	_armar_pantalla(raiz)
	_armar_pausa(raiz)

	_fundido = ColorRect.new()
	_fundido.color = Color.BLACK
	_fundido.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(_fundido)


func _armar_llamada(raiz: Control) -> void:
	_llamada = PanelContainer.new()
	_llamada.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_llamada.offset_left = -440
	_llamada.offset_right = 440
	_llamada.offset_top = -190
	_llamada.offset_bottom = -30
	_llamada.add_theme_stylebox_override("panel", _caja(Color(0.05, 0.06, 0.09, 0.93), 18))
	_llamada.visible = false
	raiz.add_child(_llamada)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	_llamada.add_child(col)
	_llamada_quien = Label.new()
	_llamada_quien.add_theme_font_size_override("font_size", 16)
	_llamada_quien.add_theme_color_override("font_color", Color("e0b34a"))
	col.add_child(_llamada_quien)
	_llamada_texto = Label.new()
	_llamada_texto.add_theme_font_size_override("font_size", 22)
	_llamada_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_llamada_texto.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_llamada_texto)
	_llamada_ayuda = Label.new()
	_llamada_ayuda.text = "ESPACIO para continuar"
	_llamada_ayuda.add_theme_font_size_override("font_size", 13)
	_llamada_ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_llamada_ayuda.modulate.a = 0.6
	col.add_child(_llamada_ayuda)


func _armar_pantalla(raiz: Control) -> void:
	_pantalla = PanelContainer.new()
	_pantalla.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pantalla.offset_left = 40
	_pantalla.offset_right = -40
	_pantalla.offset_top = 30
	_pantalla.offset_bottom = -30
	_pantalla.add_theme_stylebox_override("panel", _caja(COLOR_PAPEL, 22))
	_pantalla.visible = false
	raiz.add_child(_pantalla)

	var columnas := HBoxContainer.new()
	columnas.add_theme_constant_override("separation", 24)
	_pantalla.add_child(columnas)

	var izq := VBoxContainer.new()
	izq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	izq.size_flags_stretch_ratio = 0.8
	columnas.add_child(izq)
	izq.add_child(_titulo_papel("Agenda"))
	_agenda_grande = RichTextLabel.new()
	_agenda_grande.bbcode_enabled = true
	_agenda_grande.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_agenda_grande.add_theme_color_override("default_color", COLOR_TINTA)
	_agenda_grande.add_theme_font_size_override("normal_font_size", 18)
	izq.add_child(_agenda_grande)

	var der := VBoxContainer.new()
	der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columnas.add_child(der)
	der.add_child(_titulo_papel("Bolso"))
	_lista_bolso = ItemList.new()
	_lista_bolso.custom_minimum_size.y = 190
	_lista_bolso.add_theme_font_size_override("font_size", 17)
	_lista_bolso.add_theme_color_override("font_color", Color.WHITE)
	_lista_bolso.item_selected.connect(_leer_item)
	der.add_child(_lista_bolso)
	_lectura = RichTextLabel.new()
	_lectura.bbcode_enabled = true
	_lectura.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lectura.add_theme_color_override("default_color", COLOR_TINTA)
	_lectura.add_theme_font_size_override("normal_font_size", 18)
	der.add_child(_lectura)
	var pie := Label.new()
	pie.text = "TAB para cerrar"
	pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pie.add_theme_color_override("font_color", COLOR_TINTA)
	der.add_child(pie)


func _armar_pausa(raiz: Control) -> void:
	_pausa = PanelContainer.new()
	_pausa.set_anchors_preset(Control.PRESET_CENTER)
	_pausa.offset_left = -220
	_pausa.offset_right = 220
	_pausa.offset_top = -190
	_pausa.offset_bottom = 190
	_pausa.add_theme_stylebox_override("panel", _caja(Color(0.05, 0.06, 0.09, 0.95), 24))
	_pausa.visible = false
	raiz.add_child(_pausa)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	_pausa.add_child(col)
	var ayuda := Label.new()
	ayuda.text = "WASD moverse · SHIFT correr (hace ruido)\nCTRL agacharse · Q/E asomarse\nESPACIO saltar · F usar (mantener)\nTAB agenda y bolso\nClic disparar · R recargar (Mostro)"
	ayuda.add_theme_font_size_override("font_size", 16)
	col.add_child(ayuda)
	var seguir := Button.new()
	seguir.text = "Continuar"
	seguir.pressed.connect(alternar_pausa)
	col.add_child(seguir)
	var reiniciar := Button.new()
	reiniciar.text = "Reiniciar misión"
	reiniciar.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file(Juego.ESCENA_MISION))
	col.add_child(reiniciar)
	var salir := Button.new()
	salir.text = "Volver al menú"
	salir.pressed.connect(func() -> void:
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file(Juego.ESCENA_MENU))
	col.add_child(salir)


func _unhandled_input(event: InputEvent) -> void:
	if _esperando_llamada:
		if event.is_action_pressed("saltar") or (event is InputEventMouseButton and event.is_pressed()):
			_esperando_llamada = false
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pausa"):
		if _pantalla.visible:
			alternar_pantalla()
		else:
			alternar_pausa()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("agenda") and not _pausa.visible and not Juego.control_bloqueado:
		alternar_pantalla()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("agenda") and _pantalla.visible:
		alternar_pantalla()
		get_viewport().set_input_as_handled()


func alternar_pantalla() -> void:
	_pantalla.visible = not _pantalla.visible
	_refrescar_agenda()
	_refrescar_bolso()
	_aplicar_pausa(_pantalla.visible)


func alternar_pausa() -> void:
	_pausa.visible = not _pausa.visible
	_aplicar_pausa(_pausa.visible)


func _aplicar_pausa(pausar: bool) -> void:
	get_tree().paused = pausar
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if pausar else Input.MOUSE_MODE_CAPTURED


func _process(_delta: float) -> void:
	if jugador == null or not is_instance_valid(jugador):
		return
	_punto.visible = not Juego.control_bloqueado
	_prompt.text = jugador.texto_uso
	_barra_uso.visible = jugador.progreso_uso > 0.0
	_barra_uso.value = jugador.progreso_uso

	var hay_sospecha: bool = Juego.sospecha > 0.03 and not Juego.alarma
	_sospecha.visible = hay_sospecha
	_sospecha_txt.visible = hay_sospecha
	_sospecha.value = Juego.sospecha
	Juego.sospecha = maxf(Juego.sospecha - _delta * 0.6, 0.0)

	if jugador.personaje == Jugador.Personaje.MOSTRO:
		var municion: String = "Recargando..." if jugador.recargando() else "%d/%d" % [jugador.balas, Jugador.BALAS]
		_estado.text = "MOSTRO  |  Balas %s" % municion
		_vida.visible = true
		_vida_txt.visible = true
	elif jugador.agachado:
		_estado.text = "POLO  |  agachado"
	elif jugador.corriendo:
		_estado.text = "POLO  |  corriendo: ¡te oyen!"
	else:
		_estado.text = "POLO"
	_alarma.visible = Juego.alarma and fmod(Time.get_ticks_msec() / 500.0, 2.0) < 1.4


## Conecta las señales del jugador. La misión lo llama una vez lo asigna.
func conectar_jugador(j: Jugador) -> void:
	jugador = j
	j.impacto_enemigo.connect(_marcar_impacto)
	j.herido.connect(_al_recibir_dano)
	j.vida_cambio.connect(_actualizar_vida)


func _actualizar_vida() -> void:
	var valor: float = jugador.vida
	var tween := create_tween()
	tween.tween_property(_vida, "value", valor, 0.15)
	var color: Color = Color("c62f24") if valor < 35.0 else (Color("d9a22e") if valor < 65.0 else Color("3fae49"))
	_vida.add_theme_stylebox_override("fill", _caja(color, 0))


func _al_recibir_dano() -> void:
	_rojo.color.a = 0.38
	var tween := create_tween()
	tween.tween_property(_rojo, "color:a", 0.0, 0.4)


func _marcar_impacto(mortal: bool) -> void:
	if _tween_marca:
		_tween_marca.kill()
	_marca.modulate = Color(1, 0.15, 0.1) if mortal else Color.WHITE
	_tween_marca = create_tween()
	_tween_marca.tween_property(_marca, "modulate:a", 0.0, 0.3)


func fijar_objetivo(texto: String) -> void:
	_objetivo.text = texto


func mostrar_aviso(texto: String) -> void:
	_aviso.text = texto
	if _tween_aviso:
		_tween_aviso.kill()
	_aviso.modulate.a = 1.0
	_tween_aviso = create_tween()
	_tween_aviso.tween_interval(2.6)
	_tween_aviso.tween_property(_aviso, "modulate:a", 0.0, 0.5)


func fundir(destino: float, tiempo: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fundido, "color:a", destino, tiempo)
	await tween.finished


## Reproduce una llamada línea por línea. Cada línea: {quien, texto, anota (opcional)}.
## Si la línea trae "anota", al avanzar queda escrita en la agenda.
func reproducir_llamada(lineas: Array[Dictionary], automatica: bool = false) -> void:
	_llamada.visible = true
	_llamada_ayuda.visible = not automatica
	Sfx.plano(self, "telefono", -14.0)
	for linea: Dictionary in lineas:
		_llamada_quien.text = linea["quien"]
		_llamada_texto.text = linea["texto"]
		if linea.get("anota", false):
			Juego.anotadas += 1
			_refrescar_agenda()
		if automatica:
			await get_tree().create_timer(linea.get("dura", 1.8) as float).timeout
		else:
			_esperando_llamada = true
			while _esperando_llamada:
				await get_tree().process_frame
	_llamada.visible = false


func _refrescar_agenda() -> void:
	var cuerpo: String = "[b]Agenda de Polo[/b]\n"
	if Juego.anotadas == 0:
		cuerpo += "..."
	for i: int in mini(Juego.anotadas, Juego.lista.size()):
		var o: Dictionary = Juego.lista[i]
		var titulo: String = o["titulo"]
		var donde: String = Juego.ubicaciones.get(o["id"], "")
		if donde != "":
			titulo += " [color=#8a8170][font_size=13]· %s[/font_size][/color]" % donde.get_slice(" · ", 0)
		cuerpo += "[s]%s[/s]\n" % titulo if o["id"] in Juego.robadas else "%s\n" % titulo
	_agenda_mini.text = cuerpo.strip_edges()

	var detalle: String = ""
	for i: int in mini(Juego.anotadas, Juego.lista.size()):
		var o: Dictionary = Juego.lista[i]
		var donde: String = Juego.ubicaciones.get(o["id"], "")
		var linea: String = "[b]%s[/b]\n%s\n[i]«%s»[/i]" % [o["titulo"], Juego.credito(o), o["razon"]]
		if donde != "":
			linea += "\n[color=#7a5a2a]Está en: %s[/color]" % donde
		detalle += ("[s]%s[/s]" % linea if o["id"] in Juego.robadas else linea) + "\n\n"
	_agenda_grande.text = detalle


func _refrescar_bolso() -> void:
	_lista_bolso.clear()
	for item: Dictionary in Juego.bolso:
		var prefijo: String = "Obra: " if item["clase"] == "obra" else ""
		_lista_bolso.add_item("%s%s" % [prefijo, item["nombre"]])
	if Juego.bolso.is_empty():
		_lectura.text = "El bolso está vacío."
	else:
		_lectura.text = "Elige algo de la lista para leer su historia."


func _leer_item(indice: int) -> void:
	var item: Dictionary = Juego.bolso[indice]
	_lectura.text = "[b]%s[/b]\n%s\n\n%s" % [item["nombre"], item["detalle"], item["texto"]]


func _etiqueta(padre: Control, tam: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(l)
	return l


func _titulo_papel(texto: String) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", COLOR_TINTA)
	return l


func _centrar(c: Control, x: float, y: float, ancho: float) -> void:
	c.set_anchors_preset(Control.PRESET_CENTER)
	c.offset_left = x - ancho * 0.5
	c.offset_right = x + ancho * 0.5
	c.offset_top = y
	c.offset_bottom = y + 30.0
	if c is Label:
		(c as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _caja(color: Color, margen: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_content_margin_all(margen)
	s.set_corner_radius_all(3)
	return s
