extends Node
## Autoload "Juego": estado de la misión y controles. Lo que deba sobrevivir entre
## escenas o enterarse todo el mundo pasa por aquí.

signal alarma_disparada(motivo: String)
signal agenda_cambio
signal bolso_cambio
signal llaves_cambio
signal aviso(texto: String)
signal obra_robada(obra: Dictionary)
signal polo_atrapado
signal ruido(posicion: Vector3, radio: float)

const CAPA_MUNDO: int = 1
const CAPA_JUGADOR: int = 2
const CAPA_ENEMIGO: int = 4
const CAPA_INTERACTUABLE: int = 8
const CAPA_IMPACTO: int = 16

const OBRAS_POR_MISION: int = 7
const MINIMO_POR_MUSEO: int = 2
const COLECCIONABLES_POR_MISION: int = 6

const ESCENA_MENU: String = "res://escenas/menu.tscn"
const ESCENA_MISION: String = "res://escenas/mision.tscn"
const ESCENA_FINAL: String = "res://escenas/final.tscn"
const ESCENA_CARRETERA: String = "res://escenas/carretera.tscn"   ## Jefe final: solo si se llevan todas.

var lista: Array[Dictionary] = []   ## Obras encargadas en esta partida.
var anotadas: int = 0               ## Cuántas alcanzó a anotar Polo durante la llamada.
var robadas: Array[String] = []     ## ids de obras robadas.
var bolso: Array[Dictionary] = []   ## Todo lo que lleva encima (obras y coleccionables).
var alarma: bool = false
var control_bloqueado: bool = true
var sospecha: float = 0.0           ## Máxima detección actual, de 0 a 1, para la interfaz.
var resultado: String = ""          ## "completo", "parcial" o "fallo".
## Modo exploración: el museo sin guardias, cámaras ni llamada, para recorrerlo.
## Lo prende el menú y dura hasta que se vuelva a elegir "Jugar".
var modo_exploracion: bool = false
var llaves: Array[String] = []      ## Llaves del candado de la Sala 1 que ya tiene Polo.
var mostro_presentado: bool = false ## Ya se vio la entrada completa de Mostro (las siguientes son cortas).
var cine_cuadro_visto: bool = false
var cine_espada_visto: bool = false ## Ya vio la escena de la espada (y sabe del reloj). ## Ya vio la escena del cuadro del MAMBO (y sabe de las llaves).
var tiempo_mision: float = 0.0
var ubicaciones: Dictionary[String, String] = {}   ## id de obra -> "Piso 2 · Sala 8 ..."


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


## Prepara una partida nueva. Las piezas "fija" (el cuadro del MAMBO y la del Museo
## del Oro) siempre están; el resto sale al azar, con al menos MINIMO_POR_MUSEO del
## Urrutia y del Nacional. La agenda queda ordenada por museo, como sus secciones.
func nueva_mision() -> void:
	lista = Catalogo.OBRAS.filter(func(o: Dictionary) -> bool: return o.get("fija", false))
	var resto: Array[Dictionary] = Catalogo.OBRAS.filter(func(o: Dictionary) -> bool: return not o.get("fija", false) and not o.get("opcional", false))
	resto.shuffle()
	for museo: String in ["urrutia", "nacional"]:
		var del_museo: Array[Dictionary] = resto.filter(func(o: Dictionary) -> bool: return o["museo"] == museo)
		for o: Dictionary in del_museo.slice(0, MINIMO_POR_MUSEO):
			lista.append(o)
			resto.erase(o)
	lista.append_array(resto.slice(0, OBRAS_POR_MISION - lista.size()))
	var orden: Array = Catalogo.MUSEOS.map(func(m: Dictionary) -> String: return m["id"])
	lista.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return orden.find(a["museo"]) < orden.find(b["museo"]))
	anotadas = 0
	llaves = []
	cine_cuadro_visto = false
	cine_espada_visto = false
	robadas = []
	bolso = []
	alarma = false
	control_bloqueado = true
	sospecha = 0.0
	resultado = ""
	tiempo_mision = 0.0
	ubicaciones = {}


func esta_en_lista(id: String) -> bool:
	return lista.any(func(o: Dictionary) -> bool: return o["id"] == id)


## Piezas de la agenda que faltan (los extras, como el cuadro del MAMBO, no cuentan).
func faltantes() -> int:
	return lista.filter(func(o: Dictionary) -> bool: return not o["id"] in robadas).size()


func registrar_robo(obra: Dictionary) -> void:
	robadas.append(obra["id"])
	bolso.append({
		"nombre": obra["titulo"],
		"detalle": _credito(obra),
		"texto": obra["texto"],
		"clase": "obra",
		"imagen": Catalogo.imagen(obra["id"]),
	})
	agenda_cambio.emit()
	bolso_cambio.emit()
	aviso.emit("Tachado de la agenda: %s" % obra["titulo"])
	obra_robada.emit(obra)


func registrar_coleccionable(c: Dictionary) -> void:
	bolso.append({
		"nombre": c["nombre"],
		"detalle": c["epoca"],
		"texto": c["texto"],
		"clase": "coleccionable",
	})
	bolso_cambio.emit()
	aviso.emit("Al bolso: %s (TAB para leer)" % c["nombre"])


func tomar_llave(id: String) -> void:
	if id in llaves:
		return
	llaves.append(id)
	llaves_cambio.emit()
	agenda_cambio.emit()
	var faltan: int = 3 - llaves.size()
	var cola: String = "Ya están las tres: a la Sala 1." if faltan == 0 else "Faltan %d." % faltan
	aviso.emit("Llave %s. %s" % [Llaves.DATOS[id]["nombre"], cola])


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
