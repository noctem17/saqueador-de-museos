class_name BarraJefe
extends CanvasLayer
## Interfaz de la pelea contra el ELIHCOTERO, al estilo de los jefes de Dark Souls:
## el nombre y una barra larga y delgada arriba. La vida perdida se queda un
## momento en amarillo antes de bajar, para que se note cada golpe.
## Abajo: los corazones de Polo (3 impactos) y si el cohete está listo.

const NOMBRE: String = "ELIHCOTERO, la profanadora de becas"

var nombre_jefe: String = NOMBRE
var texto_ayuda: String = "Clic: disparar  ·  WASD: moverse  ·  Shift: correr  ·  Quítate de los círculos rojos"
var con_cohete: bool = true

var _raiz: Control
var _relleno: ColorRect
var _rastro: ColorRect
var _marco: Control
var _corazones: Label
var _cohete: Label
var _ayuda: Label
var _alerta: Label


func _ready() -> void:
	layer = 8
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.modulate.a = 0.0
	add_child(_raiz)

	# Nombre y barra del jefe, arriba y centrados (62 % del ancho).
	var marco := Control.new()
	_marco = marco
	marco.anchor_left = 0.19
	marco.anchor_right = 0.81
	marco.offset_top = 34
	marco.offset_bottom = 74
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(marco)
	var nombre := Label.new()
	nombre.text = nombre_jefe
	nombre.add_theme_font_size_override("font_size", 20)
	nombre.add_theme_color_override("font_color", Color("e9e2d0"))
	nombre.add_theme_color_override("font_outline_color", Color.BLACK)
	nombre.add_theme_constant_override("outline_size", 6)
	nombre.position = Vector2(2, 0)
	marco.add_child(nombre)
	var fondo := ColorRect.new()
	fondo.color = Color(0.05, 0.04, 0.04, 0.85)
	fondo.anchor_right = 1.0
	fondo.offset_top = 30
	fondo.offset_bottom = 40
	marco.add_child(fondo)
	_rastro = ColorRect.new()
	_rastro.color = Color("c9a43a")
	_rastro.offset_top = 31
	_rastro.offset_bottom = 39
	marco.add_child(_rastro)
	_relleno = ColorRect.new()
	_relleno.color = Color("8e1b16")
	_relleno.offset_top = 31
	_relleno.offset_bottom = 39
	marco.add_child(_relleno)
	_relleno.position.x = 1
	_rastro.position.x = 1

	# Abajo a la izquierda: Polo y sus corazones. Abajo a la derecha: el cohete.
	_corazones = _etiqueta(Vector2(0, 1), Rect2(28, -64, 400, 40), 26)
	_cohete = _etiqueta(Vector2(1, 1), Rect2(-300, -58, 272, 34), 20)
	_cohete.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# Mira en el centro.
	var mira := _etiqueta(Vector2(0.5, 0.5), Rect2(-20, -20, 40, 40), 26)
	mira.text = "+"
	mira.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mira.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Instrucciones que se borran solas.
	_ayuda = _etiqueta(Vector2(0.5, 0), Rect2(-420, 84, 840, 30), 18)
	_ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ayuda.text = texto_ayuda
	_cohete.visible = con_cohete
	# Aviso de misil: si Polo está mirando al helicóptero no ve los círculos del piso.
	_alerta = _etiqueta(Vector2(0.5, 0.5), Rect2(-200, 60, 400, 40), 30)
	_alerta.text = "¡MISIL! ¡MUÉVASE!"
	_alerta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_alerta.add_theme_color_override("font_color", Color("ff4433"))
	_alerta.modulate.a = 0.0
	fijar_vida_polo(100)
	fijar_cohete(true)


## Texto anclado a un punto de la pantalla (0..1) y con su rectángulo relativo a ese punto.
func _etiqueta(ancla: Vector2, caja: Rect2, tam: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.anchor_left = ancla.x
	l.anchor_right = ancla.x
	l.anchor_top = ancla.y
	l.anchor_bottom = ancla.y
	l.offset_left = caja.position.x
	l.offset_top = caja.position.y
	l.offset_right = caja.end.x
	l.offset_bottom = caja.end.y
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(l)
	return l


func _ancho() -> float:
	return _marco.size.x - 2.0


func mostrar(visible_ahora: bool) -> void:
	if visible_ahora:
		_relleno.size.x = _ancho()
		_rastro.size.x = _ancho()
	create_tween().tween_property(_raiz, "modulate:a", 1.0 if visible_ahora else 0.0, 0.6)
	if visible_ahora:
		_ayuda.modulate.a = 1.0
		var t := create_tween()
		t.tween_interval(7.0)
		t.tween_property(_ayuda, "modulate:a", 0.0, 1.0)


func alerta_misil() -> void:
	_alerta.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(0.9)
	t.tween_property(_alerta, "modulate:a", 0.0, 0.4)


func fijar_vida_jefe(vida: float, maxima: float) -> void:
	var ancho: float = _ancho() * clampf(vida / maxima, 0.0, 1.0)
	_relleno.size.x = ancho
	# El rastro amarillo espera un momento y luego baja hasta la vida nueva.
	var t := create_tween()
	t.tween_interval(0.5)
	t.tween_property(_rastro, "size:x", ancho, 0.4)


func fijar_vida_polo(vida: int) -> void:
	var quedan: int = ceili(vida / float(Explosivos.DANO_MISIL))
	var texto: String = "POLO   "
	for i: int in 3:
		texto += "♥ " if i < quedan else "♡ "
	_corazones.text = texto
	_corazones.add_theme_color_override("font_color", Color("e8433a") if quedan > 1 else Color("ff8a3a"))


func fijar_cohete(cargado: bool) -> void:
	_cohete.text = "Cohete listo" if cargado else "Recargando..."
	_cohete.add_theme_color_override("font_color", Color("cfe39a") if cargado else Color("9a9a9a"))
