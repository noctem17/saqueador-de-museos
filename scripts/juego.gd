extends Node
## Autoload "Juego": estado de la misión y controles. Lo que deba sobrevivir entre
## escenas o enterarse todo el mundo pasa por aquí.

signal alarma_disparada(motivo: String)
signal agenda_cambio
signal bolso_cambio
signal aviso(texto: String)
signal ruido(posicion: Vector3, radio: float)

const CAPA_MUNDO: int = 1
const CAPA_JUGADOR: int = 2
const CAPA_ENEMIGO: int = 4
const CAPA_INTERACTUABLE: int = 8

const OBRAS_POR_MISION: int = 4
const COLECCIONABLES_POR_MISION: int = 6

const ESCENA_MENU: String = "res://escenas/menu.tscn"
const ESCENA_MISION: String = "res://escenas/mision.tscn"
const ESCENA_FINAL: String = "res://escenas/final.tscn"

var lista: Array[Dictionary] = []   ## Obras encargadas en esta partida.
var anotadas: int = 0               ## Cuántas alcanzó a anotar Polo durante la llamada.
var robadas: Array[String] = []     ## ids de obras robadas.
var bolso: Array[Dictionary] = []   ## Todo lo que lleva encima (obras y coleccionables).
var alarma: bool = false
var control_bloqueado: bool = true
var sospecha: float = 0.0           ## Máxima detección actual, de 0 a 1, para la interfaz.
var resultado: String = ""          ## "completo", "parcial" o "fallo".
var tiempo_mision: float = 0.0


func _ready() -> void:
	_registrar_controles()


func _registrar_controles() -> void:
	var teclas: Dictionary[String, Array] = {
		"adelante": [KEY_W], "atras": [KEY_S], "izquierda": [KEY_A], "derecha": [KEY_D],
		"correr": [KEY_SHIFT], "agacharse": [KEY_CTRL, KEY_C], "saltar": [KEY_SPACE],
		"asomar_izq": [KEY_Q], "asomar_der": [KEY_E], "interactuar": [KEY_F],
		"agenda": [KEY_TAB], "recargar": [KEY_R], "pausa": [KEY_ESCAPE],
	}
	for accion: String in teclas:
		if InputMap.has_action(accion):
			continue
		InputMap.add_action(accion)
		for tecla: int in teclas[accion]:
			var ev := InputEventKey.new()
			ev.physical_keycode = tecla as Key
			InputMap.action_add_event(accion, ev)
	if not InputMap.has_action("disparar"):
		InputMap.add_action("disparar")
		var clic := InputEventMouseButton.new()
		clic.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("disparar", clic)


## Prepara una partida nueva: agenda distinta cada vez, con al menos una pieza que
## no sea un cuadro para que haya que buscar también en los pedestales.
func nueva_mision() -> void:
	var cuadros: Array[Dictionary] = Catalogo.OBRAS.filter(func(o: Dictionary) -> bool: return o["tipo"] == "pintura")
	var pedestal: Array[Dictionary] = Catalogo.OBRAS.filter(func(o: Dictionary) -> bool: return o["tipo"] != "pintura")
	cuadros.shuffle()
	pedestal.shuffle()
	lista = [pedestal[0]]
	lista.append_array(cuadros.slice(0, OBRAS_POR_MISION - 1))
	lista.shuffle()
	anotadas = 0
	robadas = []
	bolso = []
	alarma = false
	control_bloqueado = true
	sospecha = 0.0
	resultado = ""
	tiempo_mision = 0.0


func esta_en_lista(id: String) -> bool:
	return lista.any(func(o: Dictionary) -> bool: return o["id"] == id)


func faltantes() -> int:
	return lista.size() - robadas.size()


func registrar_robo(obra: Dictionary) -> void:
	robadas.append(obra["id"])
	bolso.append({
		"nombre": obra["titulo"],
		"detalle": _credito(obra),
		"texto": obra["texto"],
		"clase": "obra",
	})
	agenda_cambio.emit()
	bolso_cambio.emit()
	aviso.emit("Tachado de la agenda: %s" % obra["titulo"])


func registrar_coleccionable(c: Dictionary) -> void:
	bolso.append({
		"nombre": c["nombre"],
		"detalle": c["epoca"],
		"texto": c["texto"],
		"clase": "coleccionable",
	})
	bolso_cambio.emit()
	aviso.emit("Al bolso: %s (TAB para leer)" % c["nombre"])


func disparar_alarma(motivo: String) -> void:
	if alarma:
		return
	alarma = true
	sospecha = 0.0
	alarma_disparada.emit(motivo)


func _credito(obra: Dictionary) -> String:
	var anio: String = obra["anio"]
	return obra["autor"] if anio.is_empty() else "%s, %s" % [obra["autor"], anio]


func credito(obra: Dictionary) -> String:
	return _credito(obra)
