class_name Elcacas
extends Node3D
## Elcacas en la pelea por la espada de Bolívar: esgrima con algún golpe de boxeo
## o patada de por medio. La pelea va por turnos que se repiten:
##   GUARDIA  — espera en guardia. Si Polo le pega ahora, lo bloquea y contraataca.
##   AVISO    — anuncia el golpe: sale una flecha con el lado al que hay que
##              asomarse (Q izquierda, E derecha; en las estocadas sirve cualquiera).
##   (golpe)  — si Polo no se asomó a tiempo, pierde un corazón.
##   ABIERTO  — después de atacar queda descubierto: ahí los clics de Polo le pegan.
## Con la mitad de la vida se enfurece: avisa más rápido y encadena dos golpes.

signal vida_cambio(vida: float, maxima: float)
signal aviso(lado: int)          ## -1 asomarse a la izquierda, 1 a la derecha, 0 cualquiera.
signal abierto                   ## Momento de pegarle.
signal golpe_a_polo
signal esquivado
signal bloqueo
signal golpeado
signal enfurecido
signal derrotado

const VIDA: float = 120.0
const DANO_DE_POLO: float = 10.0
const DANO_A_POLO: int = 34          ## Tres golpes y Polo cae (como los misiles).
const ESPERA_GOLPE: float = 0.45     ## Entre un clic de Polo y el siguiente.
const ANTES_DEL_IMPACTO: float = 0.42   ## La animación arranca este tiempo antes del golpe.

## Golpes posibles. "lado": hacia dónde hay que asomarse (0 = cualquiera; si es
## "azar", se elige izquierda o derecha en el momento).
const ATAQUES: Array[Dictionary] = [
	{"anim": "Sword_Slash", "lado": "azar"},
	{"anim": "Sword_Slash", "lado": "azar"},
	{"anim": "Punch_Right", "lado": 0},     # Estocada.
	{"anim": "Punch_Left", "lado": "azar"}, # Gancho de boxeo.
	{"anim": "Kick_Right", "lado": 0},
]

enum Fase { QUIETO, GUARDIA, AVISO, ABIERTO }

var cuerpo: Cuerpo
var espada_en_mano: Node3D
var vida: float = VIDA
var furioso: bool = false
var fase: Fase = Fase.QUIETO
var jugador: Jugador

var _t: float = 0.0
var _lado: int = 0
var _anim: String = ""
var _animado: bool = false
var _combo: int = 0
var _enfriar: float = 0.0
var _origen: Vector3


func _ready() -> void:
	cuerpo = Cuerpo.crear("elcacas")
	add_child(cuerpo)


## La espada de Bolívar en su mano (se ve desde que la toma del pedestal).
func tomar_espada() -> void:
	if espada_en_mano:
		espada_en_mano.visible = true
		return
	espada_en_mano = Elcacas.modelo_espada()
	# La hoja sale del puño hacia adelante, como en las animaciones de espada.
	cuerpo.sostener(espada_en_mano, cuerpo.adelante_arriba())


## Espada hecha con figuras simples: hoja, guarda y empuñadura doradas.
static func modelo_espada() -> Node3D:
	var raiz := Node3D.new()
	var acero := StandardMaterial3D.new()
	acero.albedo_color = Color("d9dde3")
	acero.metallic = 0.9
	acero.roughness = 0.2
	var oro := StandardMaterial3D.new()
	oro.albedo_color = Color("d4a63c")
	oro.metallic = 0.85
	oro.roughness = 0.3
	var partes: Array = [
		# [tamaño, posición, material]  (la hoja va a lo largo de +Y)
		[Vector3(0.028, 0.78, 0.007), Vector3(0, 0.5, 0), acero],
		[Vector3(0.17, 0.022, 0.03), Vector3(0, 0.1, 0), oro],
		[Vector3(0.026, 0.11, 0.026), Vector3(0, 0.035, 0), oro],
		[Vector3(0.045, 0.04, 0.045), Vector3(0, -0.03, 0), oro],
	]
	for p: Array in partes:
		var m := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = p[0]
		m.mesh = b
		m.position = p[1]
		m.material_override = p[2]
		raiz.add_child(m)
	return raiz


func empezar(j: Jugador) -> void:
	jugador = j
	_origen = global_position
	vida = VIDA
	furioso = false
	vida_cambio.emit(vida, VIDA)
	_a_guardia(1.4)


func parar() -> void:
	fase = Fase.QUIETO
	cuerpo.reproducir("Idle_Sword")


func _a_guardia(espera: float) -> void:
	fase = Fase.GUARDIA
	_t = espera
	_combo = 2 if furioso else 1
	cuerpo.reproducir("Idle_Sword")
	_volver()


func _a_aviso(rapido: bool = false) -> void:
	fase = Fase.AVISO
	var ataque: Dictionary = ATAQUES.pick_random()
	_anim = ataque["anim"]
	var lado: Variant = ataque["lado"]
	_lado = (-1 if randf() < 0.5 else 1) if lado is String else int(lado)
	_animado = false
	var tiempo: float = 0.55 if furioso else 0.8
	_t = tiempo * (0.75 if rapido else 1.0)
	aviso.emit(_lado)


func _process(delta: float) -> void:
	_enfriar = maxf(_enfriar - delta, 0.0)
	if fase == Fase.QUIETO or jugador == null:
		return
	# Siempre de frente a Polo.
	var a_polo: Vector3 = jugador.global_position - global_position
	a_polo.y = 0.0
	if a_polo.length() > 0.1:
		rotation.y = atan2(-a_polo.x, -a_polo.z)   # Los cuerpos miran hacia -Z.
	_t -= delta
	match fase:
		Fase.GUARDIA:
			if _t <= 0.0:
				_a_aviso()
		Fase.AVISO:
			if not _animado and _t <= ANTES_DEL_IMPACTO:
				_animado = true
				cuerpo.una_vez(_anim, 0.05)
				_embestir()
			if _t <= 0.0:
				_resolver()
		Fase.ABIERTO:
			if _t <= 0.0:
				_a_guardia(randf_range(0.5, 0.9) if furioso else randf_range(0.8, 1.4))


## El golpe llega: ¿Polo se asomó al lado correcto?
func _resolver() -> void:
	var asomado: float = jugador.asomado()
	var bien: bool = absf(asomado) > 0.45 and (_lado == 0 or signf(asomado) == _lado)
	if bien:
		esquivado.emit()
		Sfx.plano(self, "pose", -10.0)
	else:
		golpe_a_polo.emit()
		jugador.recibir_dano(DANO_A_POLO)
	_combo -= 1
	if _combo > 0 and jugador.vida > 0:
		_a_aviso(true)
		return
	fase = Fase.ABIERTO
	_t = 1.0 if furioso else 1.3
	abierto.emit()


## Polo le pega (clic). Devuelve "golpe", "bloqueo" o "" si no pasó nada.
func recibir_golpe() -> String:
	if _enfriar > 0.0 or fase == Fase.QUIETO:
		return ""
	_enfriar = ESPERA_GOLPE
	match fase:
		Fase.ABIERTO:
			vida = maxf(vida - DANO_DE_POLO, 0.0)
			vida_cambio.emit(vida, VIDA)
			golpeado.emit()
			Sfx.plano(self, "impacto", -2.0)
			cuerpo.una_vez("HitRecieve", 0.05)
			if vida <= 0.0:
				fase = Fase.QUIETO
				derrotado.emit()
			elif not furioso and vida <= VIDA * 0.5:
				furioso = true
				enfurecido.emit()
			return "golpe"
		Fase.GUARDIA:
			# En guardia lo para con la espada y contraataca de una.
			bloqueo.emit()
			Sfx.plano(self, "impacto", -6.0)
			cuerpo.una_vez("Sword_Slash", 0.05)
			_a_aviso(true)
			return "bloqueo"
	return ""


## Se tira hacia Polo para pegar y vuelve a su sitio.
func _embestir() -> void:
	var hacia: Vector3 = (jugador.global_position - _origen)
	hacia.y = 0.0
	var t := create_tween()
	t.tween_property(self, "global_position", _origen + hacia.normalized() * 0.45, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.35)
	t.tween_property(self, "global_position", _origen, 0.35)


func _volver() -> void:
	create_tween().tween_property(self, "global_position", _origen, 0.25)


## Vuelve a empezar (si Polo cae).
func reiniciar() -> void:
	global_position = _origen
	empezar(jugador)
