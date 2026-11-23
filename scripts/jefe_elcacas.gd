class_name JefeElcacas
extends Node
## La pelea por la espada de Bolívar contra ELCACAS, "el devorador de travestis".
## Sátira política: un supuesto general del ejército de Bolívar que se cree amado
## por todo el pueblo y perseguido por los gringos, y al que nadie toma en serio.
##
## 1. Polo va a tomar la espada: se oyen vidrios rotos, se asusta y voltea.
## 2. Todo se apaga. Elcacas camina despacio desde el fondo, en silueta, mientras
##    suena su voz (la grabó el equipo).
## 3. Se le ve la cara, con su título en grande. Discuten.
## 4. Corre al pedestal y agarra la espada: suena la música de jefe. Polo, sin
##    armas, se saca de atrás "la antimamertos" (un palo rosado). A Elcacas le
##    gusta demasiado... digo, no. ¡En guardia!
## 5. El duelo (elcacas.gd): asomarse con Q/E para esquivar, clic para pegar.
## 6. Vencido, Elcacas llora y le ofrece a Polo un contrato en el Senado (o en la
##    Cámara) a cambio de una noche. Polo le da la vuelta mientras habla, dice que
##    ya se terminó y grita "¡MEGA PUÑALADA DE CARNE!": se la clava por detrás, en
##    las nalgas, la escena se repite desde tres ángulos en cámara lenta y él cae.
## Después la misión toma la espada y suena la alarma (mision.gd).

const LADO_POLO := Vector3(2.1, 0.0, 0.0)   ## Dónde queda Polo, respecto a la espada.
const LADO_JEFE := Vector3(3.9, 0.0, 0.0)   ## Dónde pelea Elcacas.
const NOMBRE := "ELCACAS, el devorador de travestis"

var automatica: bool = false   ## Diálogos solos (para las pruebas).
var mision: Mision
var elcacas: Elcacas

var _hud: Hud
var _jugador: Jugador
var _s: Vector3                 ## Dónde está la espada.
var _polo: Cuerpo               ## Polo visible en las escenas de cine.
var _cam: Camera3D
var _seguir_a: Node3D
var _alto_mirada: float = 1.2
var _arrastre: Vector3 = Vector3.INF
var _temblor: float = 0.0
var _capa: CanvasLayer
var _destello: ColorRect
var _pantallazo: ColorRect
var _indicador: Label
var _barra: BarraJefe
var _palo_vista: Node3D
var _palo_mano: Node3D           ## La antimamertos en la mano de Polo (escenas de cine).
var _musica: AudioStreamPlayer
var _luces: Array[Node] = []
var _apagadas: Dictionary = {}   ## Luz -> energía original.
var _entorno: Environment
var _ambiente_original: float = 0.0
var _peleando: bool = false
var _vencido: bool = false
var _reiniciando: bool = false
var _golpes: int = 0


func reproducir(m: Mision) -> void:
	mision = m
	_hud = m.hud
	_jugador = m.jugador
	_s = m.mapa.pos_espada
	automatica = automatica or "automatica" in OS.get_cmdline_user_args()
	Juego.control_bloqueado = true
	_armar_capas()
	m._apagar_musica(m._musica_polo, 0.3)
	m._apagar_musica(m._musica_conexion, 0.3)
	var entornos: Array = m.mapa.find_children("*", "WorldEnvironment", true, false)
	if not entornos.is_empty():
		_entorno = (entornos[0] as WorldEnvironment).environment
		_ambiente_original = _entorno.ambient_light_energy

	_polo = Cuerpo.crear("polo")
	m.add_child(_polo)
	_polo.global_position = _s + LADO_POLO
	_mirar(_polo, _s)
	elcacas = Elcacas.new()
	m.add_child(elcacas)
	elcacas.global_position = _s + Vector3(11.5, 0, 0)
	_mirar(elcacas, _s)
	elcacas.cuerpo.silueta(true)
	elcacas.visible = false
	_hud.franjas(true, false)

	await _vidrios()
	await _caminata()
	await _revelacion()
	await _discusion()
	await _en_guardia()
	await _pelea()
	await _final()
	_limpiar()


# ------------------------------------------------------------------ 1. vidrios

func _vidrios() -> void:
	var cara: Vector3 = _polo.global_position + Vector3.UP * _cara("polo")
	# De frente a Polo (él mira hacia la espada).
	_nueva_camara(cara + Vector3(-0.95, 0.02, 0.25), cara + Vector3.DOWN * 0.05)
	_polo.reproducir("Idle")
	Sfx.plano(mision, "cristal", 4.0)
	await _esperar(0.25)
	Sfx.plano(mision, "cristal", 0.0)
	_polo.una_vez("HitRecieve", 0.05)   # Un brinco del susto.
	_temblor = 0.6
	_oscurecer(0.03, 1.2)
	await _esperar(1.0)
	await _hablar([{"quien": "POLO", "texto": "¿Q-quién anda ahí?"}])
	# Voltea hacia el pasillo oscuro.
	var t := create_tween()
	t.tween_property(_polo, "rotation:y", _angulo_hacia(_polo, _s + Vector3(10, 0, 0)), 0.5).set_trans(Tween.TRANS_SINE)
	_polo.reproducir("Idle")
	await _esperar(0.6)


# ------------------------------------------------------------------ 2. caminata

func _caminata() -> void:
	elcacas.visible = true
	elcacas.cuerpo.reproducir("Walk", 0.0)
	elcacas.cuerpo.velocidad(0.65)
	# Contraluz al fondo del pasillo: se ve solo la silueta.
	var contraluz := SpotLight3D.new()
	contraluz.light_color = Color("ffe2b8")
	contraluz.light_energy = 9.0
	contraluz.spot_range = 22.0
	contraluz.spot_angle = 28.0
	mision.add_child(contraluz)
	contraluz.global_position = _s + Vector3(17.0, 1.4, 0.0)
	contraluz.look_at(_s + Vector3(4.0, 1.0, 0.0))
	_luces.append(contraluz)
	var voz: AudioStreamPlayer = Sfx.musica(mision, "elcacas_voz", 5.0)
	var largo: float = voz.stream.get_length() if voz.stream else 5.2
	create_tween().tween_property(elcacas, "global_position", _s + Vector3(5.2, 0, 0), largo + 0.6)
	# a) Por encima del hombro de Polo, hacia el fondo.
	_nueva_camara(_polo.global_position + Vector3(-0.7, 1.6, 0.55), Vector3.ZERO)
	_seguir_a = elcacas
	_alto_mirada = 1.2
	_cam.fov = 40.0
	await _esperar(largo * 0.4)
	# b) A ras del piso: los zapatos acercándose.
	_nueva_camara(Vector3.ZERO, Vector3.ZERO)
	_seguir_a = elcacas
	_alto_mirada = 0.3
	_arrastre = Vector3(-1.7, 0.15, 0.55)
	_cam.global_position = elcacas.global_position + _arrastre
	await _esperar(largo * 0.3)
	# c) La cara de Polo, muerto del miedo.
	_arrastre = Vector3.INF
	var cara: Vector3 = _polo.global_position + Vector3.UP * (_cara("polo") - 0.2)
	_nueva_camara(cara + Vector3(0.9, 0.05, 0.3), cara)
	await _esperar(largo * 0.3 + 0.6)
	elcacas.cuerpo.velocidad(1.0)


# ------------------------------------------------------------------ 3. revelación

func _revelacion() -> void:
	elcacas.cuerpo.silueta(false)
	elcacas.cuerpo.reproducir("Idle")
	_destellar(Color.WHITE)
	_temblor = 0.9
	Sfx.plano(mision, "pose", 0.0)
	var foco := SpotLight3D.new()
	foco.light_color = Color("fff1dc")
	foco.light_energy = 6.0
	foco.spot_range = 9.0
	foco.spot_angle = 35.0
	mision.add_child(foco)
	foco.global_position = elcacas.global_position + Vector3(-1.5, 4.2, 0)
	foco.look_at(elcacas.global_position + Vector3.UP * 1.1)
	_luces.append(foco)
	_oscurecer(0.25, 0.4)
	# Primer plano de la cara y se aleja despacio, desde abajo.
	var cara: Vector3 = elcacas.global_position + Vector3.UP * _cara("elcacas")
	_nueva_camara(cara + Vector3(-1.1, 0.0, 0.3), cara + Vector3.DOWN * 0.15)
	_cam.fov = 40.0
	create_tween().tween_property(_cam, "global_position", elcacas.global_position + Vector3(-3.2, 0.5, 1.1), 4.0).set_trans(Tween.TRANS_SINE)
	_seguir_a = elcacas
	_alto_mirada = 1.35
	_titulo()
	await _esperar(4.2)


# ------------------------------------------------------------------ 4. discusión

func _discusion() -> void:
	await _hablar([
		{"quien": "ELCACAS", "texto": "Suelte eso, mijo. Esa espada es mía."},
		{"quien": "POLO", "texto": "¿Suya? La placa dice que la prestó la Casa Museo Quinta de Bolívar."},
		{"quien": "ELCACAS", "texto": "¡Porque yo se la presté a ellos! Yo soy GENERAL DEL EJÉRCITO DE BOLÍVAR. Me la entregó él mismo... en un sueño."},
		{"quien": "POLO", "texto": "Bolívar murió en 1830."},
		{"quien": "ELCACAS", "texto": "¡Por eso fue en un sueño, ignorante! Y el pueblo me ama. Afuera hay una multitud gritando mi nombre."},
		{"quien": "POLO", "texto": "Afuera hay un señor vendiendo empanadas."},
		{"quien": "ELCACAS", "texto": "¡Ese es de los míos! ...Y si usted es de la DEA, sepa que los gringos llevan veinte años buscándome y no me han podido agarrar."},
		{"quien": "POLO", "texto": "Señor, nadie lo está buscando."},
		{"quien": "ELCACAS", "texto": "¡ESO ES LO QUE ELLOS QUIEREN QUE YO CREA!"},
	])
	# Corre al pedestal y agarra la espada.
	var junto: Vector3 = _s + Vector3(1.3, 0, -1.25)
	elcacas.cuerpo.reproducir("Run")
	_nueva_camara(_s + Vector3(4.2, 2.3, -3.6), _s + Vector3(1.5, 1.0, -0.6))
	_seguir_a = null
	_mirar(elcacas, junto)
	var t := create_tween()
	t.tween_property(elcacas, "global_position", junto, 1.0)
	await t.finished
	_mirar(elcacas, _s)
	elcacas.cuerpo.una_vez("Interact")
	await _esperar(0.5)
	mision.espada.ocultar_pieza()
	elcacas.tomar_espada()
	Sfx.plano(mision, "desenfundar", 0.0)
	_destellar(Color("ffe08a"))
	await _hablar([{"quien": "ELCACAS", "texto": "¡La espada del Libertador no se la lleva un ladrón de quinta! ...Bueno, de la Quinta. ¡Usted me entendió!"}])
	# Se planta frente a Polo.
	elcacas.cuerpo.reproducir("Run")
	_mirar(elcacas, _s + LADO_JEFE)
	t = create_tween()
	t.tween_property(elcacas, "global_position", _s + LADO_JEFE + Vector3(0, 0, -1.4), 0.5)
	t.tween_property(elcacas, "global_position", _s + LADO_JEFE, 0.4)
	await t.finished
	_mirar(elcacas, _polo.global_position)
	_mirar(_polo, elcacas.global_position)
	_polo.reproducir("Idle")


# ------------------------------------------------------------------ 5. en guardia

func _en_guardia() -> void:
	elcacas.cuerpo.reproducir("Idle_Sword")
	# Plano heroico desde abajo, y arranca la música de jefe (la de Franchesca).
	_nueva_camara(elcacas.global_position + Vector3(-1.6, 0.35, 1.2), Vector3.ZERO)
	_seguir_a = elcacas
	_alto_mirada = 1.3
	_musica = Sfx.bucle(mision, "musica/jefe_final", -5.0)
	_temblor = 0.7
	Sfx.plano(mision, "pose", -2.0)
	await _esperar(1.6)
	# Polo no tiene con qué. O sí.
	var cara: Vector3 = _polo.global_position + Vector3.UP * _cara("polo")
	_nueva_camara(cara + (elcacas.global_position - _polo.global_position).normalized() * 0.95 + Vector3(0, 0.0, 0.3), cara)
	await _hablar([
		{"quien": "POLO", "texto": "Yo no tengo armas, señor. Mostro dijo que esto era un trabajo limpio."},
		{"quien": "POLO", "texto": "...Pero mi abuela decía: nunca salga de la casa sin su plan B."},
	])
	# Se lleva la mano atrás... y saca la antimamertos.
	_nueva_camara(_polo.global_position + Vector3(-0.2, 1.1, 2.3), _polo.global_position + Vector3.UP * 0.95)
	_polo.una_vez("Interact")
	await _esperar(0.45)
	Sfx.plano(mision, "descolgar", 2.0)
	_polo.reproducir("Idle_Sword", 0.0)
	_palo_en(_polo)
	_destellar(Color("ff8ad0"))
	_temblor = 0.5
	await _hud.grito("¡LA ANTIMAMERTOS!", 1.4)
	# Elcacas la ve.
	var cara_e: Vector3 = elcacas.global_position + Vector3.UP * _cara("elcacas")
	var hacia_polo: Vector3 = (_polo.global_position - elcacas.global_position).normalized()
	_nueva_camara(cara_e + hacia_polo * 1.0 + Vector3(0, 0.02, 0.3), cara_e + Vector3.DOWN * 0.05)
	elcacas.cuerpo.reproducir("Idle")
	await _hablar([
		{"quien": "ELCACAS", "texto": "Uy... a mí me gustan mucho de esas."},
		{"quien": "ELCACAS", "texto": "Digo... ¡NO! ¡Aleje eso de mí, degenerado!"},
	])
	elcacas.cuerpo.reproducir("Idle_Sword")
	_nueva_camara(elcacas.global_position + Vector3(-1.6, 0.35, 1.2), Vector3.ZERO)
	_seguir_a = elcacas
	_alto_mirada = 1.3
	_temblor = 0.8
	Sfx.plano(mision, "pose", -2.0)
	await _hud.grito("¡EN GUARDIA!", 1.4)


# ------------------------------------------------------------------ 6. el duelo

func _pelea() -> void:
	await _hud.fundir(1.0, 0.3)
	_polo.visible = false
	_borrar_camara()
	_jugador.global_position = _s + LADO_POLO
	_jugador.mirar_hacia(elcacas.global_position)
	_jugador.activar_camara()
	_jugador.en_duelo = true
	_jugador.vida = 100
	_jugador.vida_cambio.emit()
	_palo_vista = PaloRosado.vista()
	_jugador.get_viewport().get_camera_3d().add_child(_palo_vista)
	_oscurecer(0.45, 0.5)
	_barra = BarraJefe.new()
	_barra.nombre_jefe = NOMBRE
	_barra.texto_ayuda = "Q / E: asomarse para esquivar (mira la flecha)  ·  Clic: pegar cuando diga ¡AHORA!"
	_barra.con_cohete = false
	mision.add_child(_barra)
	elcacas.vida_cambio.connect(_barra.fijar_vida_jefe)
	elcacas.aviso.connect(_mostrar_aviso)
	elcacas.abierto.connect(_mostrar_ahora)
	elcacas.golpe_a_polo.connect(_al_golpe_a_polo)
	elcacas.esquivado.connect(func() -> void: _mostrar("¡Esquivado!", Color("cfe39a")))
	elcacas.bloqueo.connect(func() -> void: _mostrar("¡Bloqueado! Espere a que ataque", Color("ffb24a")))
	elcacas.golpeado.connect(_al_golpear)
	elcacas.enfurecido.connect(func() -> void: _burla("¡Hasta los gringos me tienen miedo! ¡¿Usted por qué no?!"))
	elcacas.derrotado.connect(func() -> void: _vencido = true)
	_jugador.vida_cambio.connect(_vida_polo)
	_hud.franjas(false, false)
	await _hud.fundir(0.0, 0.4)
	_barra.mostrar(true)
	elcacas.empezar(_jugador)
	_peleando = true
	Juego.control_bloqueado = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_burla("¡Cada golpe que usted me dé es un ataque contra la democracia!")
	while not _vencido:
		await get_tree().process_frame
	_peleando = false
	elcacas.parar()
	_indicador.modulate.a = 0.0
	_barra.mostrar(false)
	_jugador.en_duelo = false
	Juego.control_bloqueado = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_palo_vista.queue_free()


func _process(delta: float) -> void:
	if _peleando and not _reiniciando:
		# La cámara siempre de frente a Elcacas.
		_jugador.mirar_hacia(elcacas.global_position)
		if Input.is_action_just_pressed("disparar"):
			golpear()
	if _cam and is_instance_valid(_cam) and _cam.current:
		if _seguir_a and _arrastre != Vector3.INF:
			_cam.global_position = _seguir_a.global_position + _arrastre
		if _seguir_a:
			_cam.look_at(_seguir_a.global_position + Vector3.UP * _alto_mirada)
		if _temblor > 0.0:
			_temblor = maxf(_temblor - delta * 2.0, 0.0)
			_cam.h_offset = randf_range(-1, 1) * _temblor * 0.08
			_cam.v_offset = randf_range(-1, 1) * _temblor * 0.08
		else:
			_cam.h_offset = 0.0
			_cam.v_offset = 0.0


## Clic de Polo: mueve el palo y le avisa a Elcacas.
func golpear() -> void:
	if _palo_vista and is_instance_valid(_palo_vista):
		PaloRosado.estocada(_palo_vista)
	elcacas.recibir_golpe()


func _mostrar_aviso(lado: int) -> void:
	var textos: Dictionary = {-1: "◄  Q", 1: "E  ►", 0: "Q ◄   ► E"}
	_mostrar(textos[lado], Color("ff4a3a"), 90)
	Sfx.plano(mision, "alerta", -12.0)


func _mostrar_ahora() -> void:
	_mostrar("¡AHORA!  (clic)", Color("7dff7a"), 54)


func _mostrar(texto: String, color: Color, tam: int = 34) -> void:
	_indicador.text = texto
	_indicador.add_theme_font_size_override("font_size", tam)
	_indicador.add_theme_color_override("font_color", color)
	_indicador.modulate.a = 1.0
	_indicador.scale = Vector2(1.25, 1.25)
	var t := create_tween()
	t.tween_property(_indicador, "scale", Vector2.ONE, 0.12)


func _al_golpe_a_polo() -> void:
	_pantallazo.color = Color(0.8, 0.0, 0.0, 0.45)
	create_tween().tween_property(_pantallazo, "color:a", 0.0, 0.5)
	_mostrar("¡Le dio!", Color("ff4a3a"))


func _al_golpear() -> void:
	_golpes += 1
	if _golpes % 3 == 1:
		_burla(["¡Persecución política!", "¡Eso fue un montaje!", "¡Me están chuzando!", "¡Lo voy a denunciar en mis redes!", "¡Esto es culpa de los gringos!"].pick_random())


func _burla(texto: String) -> void:
	_hud.reproducir_llamada([{"quien": "ELCACAS", "texto": texto, "dura": 2.6}], true, false)


func _vida_polo() -> void:
	if not _peleando:
		return
	_barra.fijar_vida_polo(_jugador.vida)
	if _jugador.vida <= 0 and not _reiniciando:
		_reiniciar()


## Si Polo cae, solo se repite el duelo.
func _reiniciar() -> void:
	_reiniciando = true
	Juego.control_bloqueado = true
	elcacas.parar()
	await _hud.fundir(1.0, 0.6)
	await _hud.grito("¡ELCACAS TE DIO PLANAZO!\nOtra vez...", 1.3)
	_jugador.vida = 100
	_jugador.vida_cambio.emit()
	_barra.fijar_vida_polo(100)
	_jugador.global_position = _s + LADO_POLO
	elcacas.reiniciar()
	await _hud.fundir(0.0, 0.5)
	Juego.control_bloqueado = false
	_reiniciando = false


# ------------------------------------------------------------------ 7. el final

func _final() -> void:
	if _musica:
		var t := create_tween()
		t.tween_property(_musica, "volume_db", -24.0, 2.0)
	await _hud.fundir(1.0, 0.4)
	_hud.franjas(true, false)
	var jefe_pos: Vector3 = elcacas.global_position
	elcacas.cuerpo.reproducir("m_cry")
	_mirar(elcacas, _s + LADO_POLO)
	# Polo, con el palo en la mano, le da la vuelta mientras él ruega.
	_polo.visible = true
	_polo.global_position = _s + LADO_POLO
	_polo.reproducir("Walk")
	_polo.velocidad(0.8)
	var atras: Vector3 = jefe_pos + (jefe_pos - (_s + LADO_POLO)).normalized() * 1.15
	var camino: Array[Vector3] = [
		_s + LADO_POLO + Vector3(0.6, 0, 1.6),
		jefe_pos + Vector3(0.5, 0, 1.5),
		atras + Vector3(0, 0, 0.6),
		atras,
	]
	var vuelta := create_tween()
	var desde: Vector3 = _polo.global_position
	for punto: Vector3 in camino:
		vuelta.tween_callback(_mirar.bind(_polo, punto))
		vuelta.tween_property(_polo, "global_position", punto, desde.distance_to(punto) / 0.75)
		desde = punto
	vuelta.tween_callback(func() -> void:
		_polo.velocidad(1.0)
		_polo.reproducir("Idle_Sword")
		_mirar(_polo, jefe_pos))
	# Cámara frente a Elcacas: Polo pasa por detrás, al fondo.
	_nueva_camara(jefe_pos + (_s + LADO_POLO - jefe_pos).normalized() * 1.9 + Vector3(0, 1.35, -0.9), jefe_pos + Vector3.UP * 1.15)
	_cam.fov = 45.0
	await _hud.fundir(0.0, 0.5)
	await _hablar_sin_cortes([
		{"quien": "ELCACAS", "texto": "¡Espere, espere! ¡No me pegue más! Hablemos como gente decente...", "dura": 3.2},
		{"quien": "ELCACAS", "texto": "¿Usted sabe quién soy yo? Le consigo un contrato en el Senado. O en la Cámara de Representantes, lo que usted prefiera.", "dura": 4.2},
		{"quien": "ELCACAS", "texto": "Solo tiene que pasar la noche conmigo en la suite del hotel... ¡con todo respeto! Es una propuesta laboral.", "dura": 4.0},
		{"quien": "ELCACAS", "texto": "Nadie se va a enterar. En este país nunca nadie se entera de nada.", "dura": 3.2},
		{"quien": "ELCACAS", "texto": "¡Por favor! ¡Tengo fuero! ¡Tengo seguidores! ...Tengo miedo.", "dura": 3.2},
	])
	while vuelta.is_running():
		await get_tree().process_frame
	# Polo, detrás de él.
	var cara_polo: Vector3 = _polo.global_position + Vector3.UP * _cara("polo")
	_nueva_camara(cara_polo + (jefe_pos - _polo.global_position).normalized() * 0.9 + Vector3(0, 0.05, 0.35), cara_polo + Vector3.DOWN * 0.05)
	await _hablar([{"quien": "POLO", "texto": "Ya se terminó."}])
	await _mega_punalada(jefe_pos)
	# Recoge la espada (la antimamertos se queda donde está).
	elcacas.espada_en_mano.visible = false
	_mirar(_polo, jefe_pos)
	_polo.una_vez("Interact")
	Sfx.plano(mision, "desenfundar", 0.0)
	await _esperar(0.4)
	_polo.reproducir("Idle")
	_polo.sostener(Elcacas.modelo_espada(), _polo.adelante_arriba())
	var cara: Vector3 = _polo.global_position + Vector3.UP * _cara("polo")
	var frente: Vector3 = -_polo.global_basis.z
	_nueva_camara(cara + frente * 0.95 + _polo.global_basis.x * 0.25, cara + Vector3.DOWN * 0.05)
	await _hablar([{"quien": "POLO", "texto": "La espada vuelve a la lucha. ...Bueno, a la camioneta."}])
	await _hud.fundir(1.0, 0.4)


## Se la clava por detrás, en las nalgas. Primero apunta; después la estocada se
## repite en cámara lenta desde tres ángulos (una palabra del grito en cada una),
## él grita, y cae en cámara lenta con la antimamertos todavía clavada.
func _mega_punalada(jefe_pos: Vector3) -> void:
	_mirar(_polo, jefe_pos)
	var adelante: Vector3 = jefe_pos - _polo.global_position
	adelante.y = 0.0
	adelante = adelante.normalized()               # De Polo hacia Elcacas (y hacia donde mira él).
	var lado: Vector3 = adelante.cross(Vector3.UP).normalized()
	var nalgas: Vector3 = jefe_pos + Vector3.UP * 0.86 - adelante * 0.12
	if _palo_mano:
		_palo_mano.visible = false
	# Polo en estocada baja (pose hecha a mano) con una antimamertos grande en la mano,
	# horizontal, hacia las nalgas.
	_polo.pose_estocada()
	var lanza := Node3D.new()
	var palo: Node3D = PaloRosado.modelo()
	palo.scale = Vector3(1.4, 2.0, 1.4)
	lanza.add_child(palo)
	_polo.sostener(lanza, (adelante + Vector3.DOWN * 0.04).normalized())
	# ¿Dónde tiene que quedar Polo para que la punta salga por delante de Elcacas?
	# La pose no cambia: se mueve el cuerpo entero, y la vara con él.
	await get_tree().process_frame
	var punta: Vector3 = lanza.to_global(Vector3(0, 1.32, 0))
	var meta_punta: Vector3 = nalgas + adelante * 0.5
	var mover: Vector3 = meta_punta - punta
	mover.y = 0.0
	var clavado: Vector3 = _polo.global_position + mover
	var amagando: Vector3 = clavado - adelante * 0.95

	# 1. Apunta. Primer plano bajo de la punta frente a las nalgas.
	_polo.global_position = amagando
	await get_tree().process_frame
	var punta_ahora: Vector3 = lanza.to_global(Vector3(0, 1.32, 0))
	_nueva_camara(punta_ahora + lado * 1.0 - adelante * 0.35 + Vector3.UP * 0.05, punta_ahora.lerp(nalgas, 0.5))
	_cam.fov = 50.0
	create_tween().tween_property(_cam, "fov", 30.0, 2.2).set_trans(Tween.TRANS_SINE)
	Sfx.plano(mision, "desenfundar", 0.0)
	await _hud.grito("¡¡¡MEGA PUÑALADA\nDE CARNE!!!", 1.0)

	# 2. La estocada, tres veces, cada una desde otro ángulo.
	var planos: Array = [
		# [desde, mira a, palabra]
		[jefe_pos + lado * 2.6 + Vector3.UP * 0.9 - adelante * 0.6, nalgas - adelante * 0.3, "¡MEGA!"],
		[jefe_pos - lado * 2.3 - adelante * 0.5 + Vector3.UP * 0.3, nalgas - adelante * 0.35 + Vector3.DOWN * 0.1, "¡PUÑALADA!"],
		[jefe_pos + adelante * 1.7 - lado * 0.6 + Vector3.UP * 1.25, jefe_pos + Vector3.UP * 1.0, "¡DE CARNE!"],
	]
	for i: int in planos.size():
		_polo.global_position = amagando
		elcacas.cuerpo.reproducir("m_cry")
		_nueva_camara(planos[i][0] as Vector3, planos[i][1] as Vector3)
		_cam.fov = 48.0
		_destellar(Color.WHITE)
		Engine.time_scale = 0.28
		await _esperar(0.15)
		# Todo el cuerpo se lanza hacia adelante.
		var t := create_tween()
		t.tween_property(_polo, "global_position", clavado, 0.13).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		await _esperar(0.12)
		# El impacto: lo levanta un poco, destello rosado y temblor.
		elcacas.cuerpo.posar("HitRecieve", 0.35)
		var brinco := create_tween()
		brinco.tween_property(elcacas, "global_position", jefe_pos + Vector3.UP * 0.18, 0.08)
		brinco.tween_property(elcacas, "global_position", jefe_pos, 0.2)
		_destellar(Color("ff3a9a"))
		_temblor = 1.3
		Sfx.plano(mision, "carne", 5.0)
		Sfx.plano(mision, "impacto", 3.0)
		_hud.grito(planos[i][2] as String, 0.25)
		create_tween().tween_property(_cam, "fov", 36.0, 0.35)
		await _esperar(0.5)
	Engine.time_scale = 1.0

	# 3. Queda clavado. Su cara.
	elcacas.cuerpo.reproducir("Idle", 0.1)
	var cara_e: Vector3 = jefe_pos + Vector3.UP * _cara("elcacas")
	_nueva_camara(cara_e + adelante * 0.95 + lado * 0.25, cara_e + Vector3.DOWN * 0.08)
	_temblor = 0.6
	await _hablar([{"quien": "ELCACAS", "texto": "¡¡AAAYYY!! ¡MI FUERO! ¡ME VIOLARON EL FUERO!"}])

	# 4. Polo la suelta: la antimamertos se queda clavada. Él cae en cámara lenta y
	# la cámara gira alrededor.
	lanza.reparent(elcacas.cuerpo.adjuntar("Hips"), true)
	_polo.global_position = clavado - adelante * 0.5
	_polo.reproducir("Idle", 0.0)
	if _musica:
		mision._apagar_musica(_musica, 3.0)
	_nueva_camara(jefe_pos + lado * 2.6 + Vector3.UP * 1.0, Vector3.ZERO)
	_seguir_a = elcacas
	_alto_mirada = 0.7
	_cam.fov = 45.0
	Engine.time_scale = 0.35
	elcacas.cuerpo.morir()
	Sfx.plano(mision, "impacto", 0.0)
	var giro := create_tween()
	giro.tween_property(_cam, "global_position", jefe_pos + adelante * 2.4 + lado * 1.2 + Vector3.UP * 1.6, 1.1).set_trans(Tween.TRANS_SINE)
	await _esperar(1.1)
	Engine.time_scale = 1.0
	_temblor = 0.8
	Sfx.plano(mision, "explosion", -14.0)   # El golpe contra el piso.
	await _esperar(1.4)
	_seguir_a = null


# ------------------------------------------------------------------ ayudas

func _hablar(lineas: Array[Dictionary]) -> void:
	for linea: Dictionary in lineas:
		await _hud.reproducir_llamada([linea], automatica, false)


## Diálogo sin cambiar de cámara (mientras Polo camina por detrás).
func _hablar_sin_cortes(lineas: Array[Dictionary]) -> void:
	await _hud.reproducir_llamada(lineas, automatica, false)


func _esperar(segundos: float) -> bool:
	await get_tree().create_timer(segundos).timeout
	return false


func _cara(tipo: String) -> float:
	return Cuerpo.TIPOS[tipo].get("cara", 1.6)


## Los cuerpos miran hacia -Z.
func _angulo_hacia(nodo: Node3D, punto: Vector3) -> float:
	var d: Vector3 = punto - nodo.global_position
	return atan2(-d.x, -d.z)


func _mirar(nodo: Node3D, punto: Vector3) -> void:
	nodo.rotation.y = _angulo_hacia(nodo, punto)


func _nueva_camara(desde: Vector3, hacia: Vector3) -> void:
	_borrar_camara()
	_seguir_a = null
	_arrastre = Vector3.INF
	_cam = Camera3D.new()
	_cam.fov = 50.0
	mision.add_child(_cam)
	if desde != Vector3.ZERO:
		_cam.global_position = desde
		if hacia != Vector3.ZERO and not desde.is_equal_approx(hacia):
			_cam.look_at(hacia)
	_cam.make_current()
	var relleno := OmniLight3D.new()
	relleno.light_color = Color("c9d6ff")
	relleno.light_energy = 0.6
	relleno.omni_range = 3.5
	_cam.add_child(relleno)


func _borrar_camara() -> void:
	if _cam and is_instance_valid(_cam):
		_cam.queue_free()
	_cam = null


## Apaga (o devuelve) las luces cerca de la espada. `nivel` 0 = negro, 1 = normal.
func _oscurecer(nivel: float, tiempo: float) -> void:
	if _apagadas.is_empty():
		for n: Node in get_tree().get_nodes_in_group("luces_sala"):
			var l := n as Light3D
			if l and absf(l.global_position.y - _s.y) < 4.0 and l.global_position.distance_to(_s) < 30.0:
				_apagadas[l] = l.light_energy
	for l: Light3D in _apagadas:
		if is_instance_valid(l):
			create_tween().tween_property(l, "light_energy", (_apagadas[l] as float) * nivel, tiempo)
	if _entorno:
		create_tween().tween_property(_entorno, "ambient_light_energy", _ambiente_original * maxf(nivel, 0.08), tiempo)


func _armar_capas() -> void:
	_capa = CanvasLayer.new()
	_capa.layer = 7
	mision.add_child(_capa)
	_pantallazo = ColorRect.new()
	_pantallazo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pantallazo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pantallazo.color = Color(0, 0, 0, 0)
	_capa.add_child(_pantallazo)
	_destello = ColorRect.new()
	_destello.set_anchors_preset(Control.PRESET_FULL_RECT)
	_destello.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_destello.color = Color(1, 1, 1, 0)
	_capa.add_child(_destello)
	_indicador = Label.new()
	_indicador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_indicador.add_theme_color_override("font_outline_color", Color.BLACK)
	_indicador.add_theme_constant_override("outline_size", 14)
	_indicador.anchor_left = 0.0
	_indicador.anchor_right = 1.0
	_indicador.anchor_top = 0.6
	_indicador.anchor_bottom = 0.6
	_indicador.offset_bottom = 110
	_indicador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_indicador.modulate.a = 0.0
	_capa.add_child(_indicador)
	_indicador.pivot_offset = Vector2(get_viewport().get_visible_rect().size.x * 0.5, 50)


func _destellar(color: Color) -> void:
	_destello.color = Color(color, 0.9)
	create_tween().tween_property(_destello, "color:a", 0.0, 0.5)


## Su nombre en grande, como en las presentaciones de personaje.
func _titulo() -> void:
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa.add_child(raiz)
	var franja := ColorRect.new()
	franja.color = Color(0.07, 0.1, 0.28, 0.88)
	franja.anchor_top = 0.62
	franja.anchor_bottom = 0.62
	franja.position = Vector2(-80, franja.position.y)
	franja.size = Vector2(1050, 150)
	franja.rotation = -0.06
	raiz.add_child(franja)
	var nombre := Label.new()
	nombre.text = "ELCACAS"
	nombre.add_theme_font_size_override("font_size", 120)
	nombre.add_theme_color_override("font_color", Color("ffd34a"))
	nombre.add_theme_color_override("font_outline_color", Color.BLACK)
	nombre.add_theme_constant_override("outline_size", 16)
	nombre.anchor_top = 0.605
	nombre.anchor_bottom = 0.605
	nombre.position.x = 60
	nombre.rotation = -0.06
	raiz.add_child(nombre)
	var lema := Label.new()
	lema.text = "El devorador de travestis"
	lema.add_theme_font_size_override("font_size", 30)
	lema.add_theme_color_override("font_color", Color("e9e2d0"))
	lema.add_theme_color_override("font_outline_color", Color.BLACK)
	lema.add_theme_constant_override("outline_size", 8)
	lema.anchor_top = 0.81
	lema.anchor_bottom = 0.81
	lema.position.x = 90
	lema.rotation = -0.06
	lema.modulate.a = 0.0
	raiz.add_child(lema)
	raiz.position.x = -1500
	var t := create_tween()
	t.tween_property(raiz, "position:x", 0.0, 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t.tween_property(lema, "modulate:a", 1.0, 0.3)
	t.tween_interval(3.0)
	t.tween_property(raiz, "modulate:a", 0.0, 0.5)
	t.tween_callback(raiz.queue_free)


## El palo rosado en la mano de un cuerpo (para las escenas de cine).
func _palo_en(c: Cuerpo) -> void:
	var palo: Node3D = PaloRosado.modelo()
	c.sostener(palo, c.adelante_arriba())
	_palo_mano = palo


func _limpiar() -> void:
	Engine.time_scale = 1.0
	_borrar_camara()
	for l: Node in _luces:
		if is_instance_valid(l):
			l.queue_free()
	_oscurecer(1.0, 0.1)
	if _polo and is_instance_valid(_polo):
		_polo.queue_free()
	if _barra and is_instance_valid(_barra):
		_barra.queue_free()
	if _capa and is_instance_valid(_capa):
		_capa.queue_free()
	_hud.franjas(false)
	_jugador.activar_camara()


## La antimamertos: el palo rosado de Polo.
class PaloRosado:
	static func modelo() -> Node3D:
		var raiz := Node3D.new()
		var rosa := StandardMaterial3D.new()
		rosa.albedo_color = Color("ff5fb4")
		rosa.roughness = 0.35
		rosa.emission_enabled = true
		rosa.emission = Color("ff3fa0")
		rosa.emission_energy_multiplier = 0.25
		var m := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.02
		c.bottom_radius = 0.026
		c.height = 0.72
		m.mesh = c
		m.position.y = 0.3
		m.material_override = rosa
		raiz.add_child(m)
		var punta := MeshInstance3D.new()
		var e := SphereMesh.new()
		e.radius = 0.024
		e.height = 0.048
		punta.mesh = e
		punta.position.y = 0.66
		punta.material_override = rosa
		raiz.add_child(punta)
		return raiz

	## En primera persona: abajo a la derecha, apuntando hacia adelante.
	static func vista() -> Node3D:
		var raiz := Node3D.new()
		var palo: Node3D = modelo()
		raiz.add_child(palo)
		raiz.position = Vector3(0.28, -0.34, -0.5)
		raiz.rotation_degrees = Vector3(-62, 8, 0)
		raiz.set_meta("reposo", raiz.transform)
		return raiz

	## Estocada: se va hacia adelante y vuelve.
	static func estocada(palo: Node3D) -> void:
		var reposo: Transform3D = palo.get_meta("reposo")
		var adelante: Transform3D = reposo.translated_local(Vector3(0, 0.25, 0)).rotated_local(Vector3.RIGHT, -0.25)
		var t := palo.create_tween()
		t.tween_property(palo, "transform", adelante, 0.07)
		t.tween_property(palo, "transform", reposo, 0.2)
