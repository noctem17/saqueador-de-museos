extends Node3D
## Jefe final: la carretera bajo la lluvia.
##
## Solo se llega aquí si Polo escapó con TODAS las obras. La camioneta va por la
## vía de noche, Franchesca Marcos aparece en la mitad del carril, el carro frena
## y la escena se cuenta con planos de cine: primeros planos de quien habla,
## relámpagos y el grito. Luego se transforma en el ELIHCOTERO y Polo pelea con un
## lanzacohetes (elihcotero.gd, lanzacohetes.gd, explosivos.gd, barra_jefe.gd).
##
## Este script solo dirige: arma el lugar y cuenta la escena paso a paso.

const LARGO_VIA: float = 420.0
const ANCHO_VIA: float = 9.0
const CARRIL: float = 2.2                       ## x del carril de la camioneta.
const POS_FRANCHESCA := Vector3(1.8, 0.0, -16.0)
const FRENA_EN: float = -6.5                    ## z donde queda quieta la camioneta.
const GIRO_MODELO: float = 180.0                ## Para que el frente del modelo mire a -Z.
## Por dónde vuela el helicóptero durante la pelea (siempre adelante de la camioneta).
const ZONA_VUELO := AABB(Vector3(-12, 6.5, -44), Vector3(24, 4, 22))
## Hasta dónde puede caminar Polo durante la pelea.
const LIMITE_ADELANTE: float = -60.0
const INICIO_POLO := Vector3(1.0, 0.05, -10.5)
## Rojo, azul, amarillo, rosado y verde: un color por pose, como los superhéroes de la tele.
const COLORES_PODER: Array[Color] = [Color("e8322b"), Color("2b6ee8"), Color("f2d22e"), Color("e85fb0"), Color("2fbf5a")]

## En las pruebas los diálogos avanzan solos.
var automatica: bool = false
## Para probar: se salta la escena y empieza en la pelea. Se marca en el Inspector
## (nodo Carretera de escenas/carretera.tscn); dejarlo apagado para el juego.
@export var directo_a_pelea: bool = false

var hud: Hud
var camioneta: Node3D
var franchesca: Cuerpo
var polo: Cuerpo
var _lluvia: GPUParticles3D
var _relampago: DirectionalLight3D
var _temblor: float = 0.0
var _prox_relampago: float = 3.0
var _seguir: Node3D             ## Si hay algo aquí, la cámara actual lo mira cada cuadro.
var _seguir_alto: float = 1.0
var _materiales: Dictionary[Color, StandardMaterial3D] = {}
var helicoptero: Elihcotero
var jugador: Jugador               ## Polo en primera persona, solo durante la pelea.
var lanzacohetes: Lanzacohetes
var barra: BarraJefe
var _musica: AudioStreamPlayer
var _pantallazo: ColorRect         ## Destello de color que cubre la pantalla.
var _reiniciando: bool = false
var _vida_polo_antes: int = 100
var _rotor: AudioStreamPlayer      ## Ruido de las hélices.
var _fuego: OmniLight3D            ## Luz de los restos que arden (titila).
var _dijo_furia: bool = false


func _ready() -> void:
	automatica = automatica or "automatica" in OS.get_cmdline_user_args()
	Juego.control_bloqueado = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_armar_cielo()
	_armar_via()
	_armar_lluvia()
	_armar_camioneta()
	franchesca = Cuerpo.crear("franchesca")
	add_child(franchesca)
	franchesca.position = POS_FRANCHESCA
	franchesca.rotation.y = PI   # Mira hacia la camioneta, que llega por +Z.
	polo = Cuerpo.crear("polo")
	add_child(polo)
	polo.visible = false
	_armar_suelo()
	helicoptero = Elihcotero.new()
	add_child(helicoptero)
	helicoptero.visible = false
	barra = BarraJefe.new()
	add_child(barra)
	add_to_group("temblor")
	var capa := CanvasLayer.new()
	capa.layer = 5
	add_child(capa)
	_pantallazo = ColorRect.new()
	_pantallazo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pantallazo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pantallazo.color = Color(1, 1, 1, 0)
	capa.add_child(_pantallazo)
	hud = Hud.new()
	add_child(hud)
	hud.fundir(1.0, 0.01)
	_cinematica()


func _process(delta: float) -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return
	# La lluvia sigue a la cámara, así siempre llueve frente a ella.
	_lluvia.global_position = cam.global_position + Vector3.UP * 14.0 - cam.global_basis.z * 8.0
	if _seguir:
		cam.look_at(_seguir.global_position + Vector3.UP * _seguir_alto)
	if _fuego:
		_fuego.light_energy = 2.2 + sin(Time.get_ticks_msec() * 0.023) * 0.5 + randf() * 0.4
	if _temblor > 0.0:
		_temblor = maxf(_temblor - delta * 1.5, 0.0)
		cam.h_offset = randf_range(-1, 1) * _temblor * 0.15
		cam.v_offset = randf_range(-1, 1) * _temblor * 0.15
	else:
		cam.h_offset = 0.0
		cam.v_offset = 0.0
	_prox_relampago -= delta
	if _prox_relampago <= 0.0:
		_prox_relampago = randf_range(6.0, 11.0)
		relampago(false)


# ------------------------------------------------------------------ la escena

func _cinematica() -> void:
	Sfx.bucle(self, "lluvia", -9.0)
	var motor := Sfx.bucle(self, "motor", -16.0)
	await _precalentar()
	await hud.franjas(true)
	if directo_a_pelea:
		motor.stop()
		camioneta.position = Vector3(CARRIL, 0, FRENA_EN)
		franchesca.visible = false
		helicoptero.visible = true
		helicoptero.giro_helice = 45.0
		helicoptero.global_position = Vector3(POS_FRANCHESCA.x, Elihcotero.ALTURA_VUELO, POS_FRANCHESCA.z - 10.0)
		helicoptero.flotando = true
		_rotor = Sfx.bucle(self, "helicoptero", -6.0)
		_musica = Sfx.bucle(self, "musica/jefe_final", -5.0)
		await _pelea()
		return

	# 1. Desde la orilla: la camioneta pasa rápido bajo la lluvia.
	camioneta.position = Vector3(CARRIL, 0, 130)
	_camara(Vector3(9.5, 0.8, 50.0), camioneta.position)
	_seguir = camioneta
	hud.fundir(0.0, 1.2)
	var t := create_tween()
	t.tween_property(camioneta, "position:z", 42.0, 5.0)
	await get_tree().create_timer(2.6).timeout
	relampago(false)
	await t.finished

	# 2. Detrás de la camioneta: algo hay parado en la vía.
	_seguir = null
	var cam := _camara(Vector3.ZERO, Vector3.ZERO)
	cam.reparent(camioneta, false)
	cam.position = Vector3(-0.4, 2.3, 7.5)
	cam.look_at_from_position(cam.global_position, camioneta.global_position + Vector3(0, 1.0, -25))
	t = create_tween()
	t.tween_property(camioneta, "position:z", 13.0, 2.6)
	await get_tree().create_timer(1.3).timeout
	relampago(true)
	await t.finished

	# 3. A la espalda de ella, a ras del piso: la camioneta frena de golpe.
	_camara(POS_FRANCHESCA + Vector3(-0.9, 0.45, -3.2), camioneta.position + Vector3(0, 0.8, 0))
	_seguir = camioneta
	_seguir_alto = 0.8
	Sfx.plano(self, "frenazo", -4.0)
	t = create_tween()
	t.tween_property(camioneta, "position:z", FRENA_EN, 1.7).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(motor, "volume_db", -30.0, 1.5)
	await t.finished
	_temblor = 0.6
	_seguir = null
	await get_tree().create_timer(0.8).timeout

	# 4. Plano abierto: Polo se baja y se para frente a ella.
	_camara(Vector3(-6.5, 1.7, -8.0), Vector3(1.5, 1.0, -12.0))
	polo.visible = true
	polo.position = Vector3(CARRIL - 1.3, 0, FRENA_EN + 0.3)
	polo.rotation.y = 0.0   # Mira hacia -Z, hacia ella.
	polo.reproducir("Walk")
	t = create_tween()
	t.tween_property(polo, "position", Vector3(CARRIL - 0.6, 0, FRENA_EN - 3.6), 2.2)
	await t.finished
	polo.reproducir("Idle")

	await _hablar([
		{"quien": "POLO", "texto": "¿Y esta señora qué hace parada en la mitad de la vía, con semejante aguacero?"},
		{"quien": "FRANCHESCA", "texto": "Bájele al tonito. Usted no se va de aquí con la historia de mi pueblo en el baúl."},
		{"quien": "POLO", "texto": "Señora, esto es un encargo. Yo solo cargo las cajas."},
		{"quien": "FRANCHESCA", "texto": "Eso dicen todos los que cargan cajas. La espada, el poporo, los cuadros... nada de eso es de nadie para esconderlo. Es de todos."},
	])

	# 5. El grito.
	var cerca := _plano_cara(franchesca)
	# Las letras del grito van al centro: la cara sube al tercio de arriba.
	var ojos: Vector3 = franchesca.global_position + Vector3.UP * (Cuerpo.TIPOS["franchesca"]["cara"] as float)
	cerca.look_at(ojos + Vector3.DOWN * 0.5)
	franchesca.una_vez("Punch_Right")
	relampago(true)
	_temblor = 1.0
	create_tween().tween_property(cerca, "fov", 44.0, 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await hud.grito("¡YO SOY FRANCHESCA MARCOS!\n¡Y NO TE LLEVARÁS TODO LO QUE PROTEJO!", 2.8)

	await _hablar([{"quien": "POLO", "texto": "...Ay, no. Esto no estaba en la agenda."}])

	await _transformacion()
	await _pelea()


## Poses de superhéroe con cortes rápidos, giro, humo y sale el helicóptero.
func _transformacion() -> void:
	var base: Vector3 = franchesca.global_position
	# 1. Cinco poses, cada una con su color y su ángulo de cámara (ella mira a +Z).
	var poses: Array = [
		["Kick_Right", Vector3(3.2, 0.9, 1.6)],
		["Punch_Left", Vector3(-0.9, 0.4, 2.7)],
		["Sword_Slash", Vector3(-2.9, 1.9, 1.3)],
		["Punch_Right", Vector3(0.7, 2.7, 2.3)],
		["Kick_Left", Vector3(2.4, 0.5, 2.4)],
	]
	for i: int in poses.size():
		_camara(base + (poses[i][1] as Vector3), base + Vector3.UP * 0.9)
		franchesca.una_vez(poses[i][0] as String, 0.02)
		_destello(COLORES_PODER[i])
		Sfx.plano(self, "pose", -3.0)
		await get_tree().create_timer(0.75).timeout

	# 2. Giro en el aire, con los cinco colores dando vueltas.
	_camara(base + Vector3(0, 1.2, 5.5), base + Vector3.UP * 1.2)
	franchesca.posar("Idle_Gun_Pointing", 0.5)
	var aro := _aro_de_colores(base)
	Sfx.plano(self, "pose", 0.0)
	var t := create_tween().set_parallel()
	t.tween_property(franchesca, "rotation:y", franchesca.rotation.y + TAU * 3.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(franchesca, "position:y", 0.6, 1.4)
	t.tween_property(aro, "rotation:y", TAU * 4.0, 1.4)
	await t.finished

	# 3. Cortina de humo: ella desaparece y aparece el helicóptero en su lugar.
	Sfx.plano(self, "humo", 0.0)
	_humo(base)
	_destello(Color.WHITE)
	_temblor = 0.8
	await get_tree().create_timer(0.35).timeout
	franchesca.visible = false
	aro.queue_free()
	helicoptero.global_position = Vector3(base.x, 0, base.z - 4.0)
	helicoptero.visible = true
	_rotor = Sfx.bucle(self, "helicoptero", -30.0)
	var arranque := create_tween().set_parallel()
	arranque.tween_property(helicoptero, "giro_helice", 45.0, 3.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	arranque.tween_property(_rotor, "volume_db", -6.0, 3.0)
	# Plano abierto de lado: el humo se abre y queda el helicóptero.
	_camara(base + Vector3(-15.0, 4.0, 3.0), base + Vector3(0, 2.0, -3.0))
	await get_tree().create_timer(3.0).timeout

	# 4. Despega. Arranca la canción. Toma desde abajo, junto a Polo.
	_musica = Sfx.bucle(self, "musica/jefe_final", -5.0)
	_camara(polo.global_position + Vector3(-1.0, 1.3, 2.4), helicoptero.global_position + Vector3.UP * 3.0)
	_seguir = helicoptero
	_seguir_alto = 1.0
	var vuelo := create_tween()
	vuelo.tween_property(helicoptero, "position", Vector3(base.x, Elihcotero.ALTURA_VUELO, base.z - 10.0), 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	vuelo.parallel().tween_property(helicoptero, "rotation:x", -0.12, 1.2)
	vuelo.tween_property(helicoptero, "rotation:x", 0.0, 1.0)
	relampago(true)
	await vuelo.finished
	helicoptero.flotando = true
	_seguir = null

	await _hablar([{"quien": "POLO", "texto": "Mostro no me paga lo suficiente para esto."}])


## Pantalla de un color que se apaga rápido, y una luz del mismo color sobre ella.
func _destello(color: Color) -> void:
	_pantallazo.color = Color(color, 0.5)
	var t := create_tween()
	t.tween_property(_pantallazo, "color:a", 0.0, 0.4)
	var luz := OmniLight3D.new()
	luz.light_color = color
	luz.light_energy = 8.0
	luz.omni_range = 7.0
	add_child(luz)
	luz.global_position = franchesca.global_position + Vector3(0, 1.5, 1.2)
	var t2 := create_tween()
	t2.tween_property(luz, "light_energy", 0.0, 0.6)
	t2.tween_callback(luz.queue_free)


## Cinco esferas de colores girando alrededor de ella durante el giro.
func _aro_de_colores(centro: Vector3) -> Node3D:
	var aro := Node3D.new()
	add_child(aro)
	aro.global_position = centro + Vector3.UP * 1.0
	for i: int in COLORES_PODER.size():
		var bola := MeshInstance3D.new()
		var e := SphereMesh.new()
		e.radius = 0.18
		e.height = 0.36
		bola.mesh = e
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = COLORES_PODER[i]
		bola.material_override = m
		var ang: float = TAU * i / COLORES_PODER.size()
		bola.position = Vector3(cos(ang), 0.2 * sin(ang * 2.0), sin(ang)) * 1.3
		aro.add_child(bola)
		var luz := OmniLight3D.new()
		luz.light_color = COLORES_PODER[i]
		luz.light_energy = 2.0
		luz.omni_range = 3.0
		bola.add_child(luz)
	return aro


## Nube de humo gris que crece y se deshace.
func _humo(centro: Vector3) -> void:
	var p := GPUParticles3D.new()
	p.amount = 90
	p.lifetime = 3.2
	p.one_shot = true
	p.explosiveness = 0.85
	p.visibility_aabb = AABB(Vector3(-15, -2, -15), Vector3(30, 20, 30))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 1.5
	pm.direction = Vector3.UP
	pm.spread = 180.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 6.0
	pm.gravity = Vector3(0, 0.6, 0)
	pm.damping_min = 1.5
	pm.damping_max = 2.5
	pm.scale_min = 1.4
	pm.scale_max = 2.8
	var crece := Curve.new()
	crece.add_point(Vector2(0, 0.4))
	crece.add_point(Vector2(1, 1.3))
	var ct := CurveTexture.new()
	ct.curve = crece
	pm.scale_curve = ct
	var rampa := Gradient.new()
	rampa.set_color(0, Color(0.6, 0.62, 0.66, 0.0))
	rampa.set_color(1, Color(0.45, 0.47, 0.5, 0.0))
	rampa.add_point(0.08, Color(0.75, 0.77, 0.8, 0.95))
	rampa.add_point(0.6, Color(0.5, 0.52, 0.56, 0.7))
	var gt := GradientTexture1D.new()
	gt.gradient = rampa
	pm.color_ramp = gt
	p.process_material = pm
	var bola := SphereMesh.new()
	bola.radius = 1.0
	bola.height = 2.0
	bola.radial_segments = 10
	bola.rings = 5
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	bola.material = m
	p.draw_pass_1 = bola
	add_child(p)
	p.global_position = centro + Vector3.UP * 1.0
	p.emitting = true
	get_tree().create_timer(5.0).timeout.connect(p.queue_free)


## Con la pantalla todavía en negro, pone un momento frente a la cámara el humo, el
## helicóptero y una luz de color: así la tarjeta gráfica prepara esos materiales
## ahora y no se traba la imagen en plena transformación.
func _precalentar() -> void:
	var cam := _camara(Vector3(0, 2, 40), Vector3(0, 2, 20))
	helicoptero.global_position = Vector3(0, 0, 25)
	helicoptero.visible = true
	_humo(Vector3(3, 0, 28))
	Explosivos.explosion(self, Vector3(-2, 2, 26), 1.0, false)
	var aro := _aro_de_colores(Vector3(-3, 0, 30))
	for i: int in 4:
		await get_tree().process_frame
	helicoptero.visible = false
	aro.queue_free()
	cam.queue_free()


## La pelea: Polo saca el lanzacohetes del baúl y pasa a primera persona.
func _pelea() -> void:
	var trasera := Vector3(CARRIL, 0, FRENA_EN + 3.1)
	polo.position = trasera
	polo.rotation.y = 0.0   # De frente al baúl.
	_camara(trasera + Vector3(2.6, 1.7, 2.6), trasera + Vector3(0, 1.0, -1.0))
	polo.una_vez("Interact")
	Sfx.plano(self, "recarga_cohete", -2.0)
	await get_tree().create_timer(1.2).timeout
	await _hablar([{"quien": "POLO", "texto": "A ver qué dejó Mostro en el baúl... ¿Un lanzacohetes? Obvio. Cómo no."}])

	await hud.fundir(1.0, 0.3)
	polo.visible = false
	jugador = Jugador.new()
	jugador.cargar_peso = false
	jugador.dentro = false
	add_child(jugador)   # Su cámara pasa a ser la actual.
	_borrar_camaras_de_cine()
	jugador.global_position = INICIO_POLO
	jugador.mirar_hacia(helicoptero.global_position)
	jugador.vida_cambio.connect(_al_cambiar_vida_polo)
	lanzacohetes = Lanzacohetes.new()
	lanzacohetes.raiz = self
	get_viewport().get_camera_3d().add_child(lanzacohetes)
	lanzacohetes.cambio.connect(barra.fijar_cohete)
	helicoptero.vida_cambio.connect(barra.fijar_vida_jefe)
	helicoptero.enfurecida.connect(_al_enfurecer)
	helicoptero.misil_lanzado.connect(barra.alerta_misil)
	helicoptero.derribado.connect(_victoria)
	hud.franjas(false, false)
	await hud.fundir(0.0, 0.4)
	lanzacohetes.sacar()
	barra.mostrar(true)
	helicoptero.empezar_pelea(jugador, ZONA_VUELO)
	Juego.control_bloqueado = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_burla("¡Desde aquí arriba se ve todo lo que se roban!")


## Franchesca habla desde el helicóptero sin parar la pelea.
func _burla(texto: String) -> void:
	hud.reproducir_llamada([{"quien": "FRANCHESCA", "texto": texto, "dura": 3.5}], true, false)


func _al_enfurecer() -> void:
	_burla("¡Este helicóptero no lo pagó el pueblo! ...Bueno, sí. Pero lo estoy usando para el pueblo.")


func _al_cambiar_vida_polo() -> void:
	barra.fijar_vida_polo(jugador.vida)
	if jugador.vida < _vida_polo_antes:
		_pantallazo.color = Color(0.8, 0.0, 0.0, 0.45)
		create_tween().tween_property(_pantallazo, "color:a", 0.0, 0.5)
	_vida_polo_antes = jugador.vida
	if jugador.vida <= 0 and not _reiniciando:
		_reiniciar_pelea()


## Si Polo cae, la pelea vuelve a empezar (no todo el robo).
func _reiniciar_pelea() -> void:
	_reiniciando = true
	Juego.control_bloqueado = true
	helicoptero.peleando = false
	await hud.fundir(1.0, 0.8)
	get_tree().call_group("proyectiles", "queue_free")
	await hud.grito("¡TE TUMBÓ EL ELIHCOTERO!\nOtra vez...", 1.4)
	jugador.vida = 100
	jugador.vida_cambio.emit()
	jugador.global_position = INICIO_POLO
	helicoptero.reiniciar(Vector3(POS_FRANCHESCA.x, Elihcotero.ALTURA_VUELO, POS_FRANCHESCA.z - 10.0))
	jugador.mirar_hacia(helicoptero.global_position)
	await hud.fundir(0.0, 0.6)
	helicoptero.empezar_pelea(jugador, ZONA_VUELO)
	Juego.control_bloqueado = false
	_reiniciando = false


## La barra llega a cero: el helicóptero revienta y la pantalla queda en blanco.
func _victoria() -> void:
	Juego.control_bloqueado = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	get_tree().call_group("proyectiles", "queue_free")
	barra.mostrar(false)
	var donde: Vector3 = helicoptero.global_position + Vector3.UP * 2.0
	Explosivos.explosion(self, donde, 3.0)
	await get_tree().create_timer(0.45).timeout
	Explosivos.explosion(self, donde + Vector3(1.5, 1.0, -1.0), 3.5)
	var t := create_tween()
	t.tween_property(_pantallazo, "color", Color(1, 1, 1, 1), 0.6)
	if _musica:
		t.parallel().tween_property(_musica, "volume_db", -40.0, 3.0)
	if _rotor:
		t.parallel().tween_property(_rotor, "volume_db", -60.0, 0.6)
	await t.finished
	await _despues_de_la_pelea()


## El final: bajo el blanco se arma la escena; ella queda tirada boca abajo en la
## carretera, Polo dice su última línea, se sube a la camioneta y se va.
func _despues_de_la_pelea() -> void:
	# Bajo la pantalla blanca: se quita la pelea y se ponen los restos.
	if is_instance_valid(jugador):
		jugador.queue_free()
	helicoptero.peleando = false
	helicoptero.visible = false
	helicoptero.giro_helice = 0.0
	if _rotor:
		_rotor.stop()
	var tirada := Vector3(1.0, 0.0, -20.0)
	franchesca.visible = true
	franchesca.posar("Idle_Neutral", 0.0)
	# Boca abajo: el frente del cuerpo hacia el piso y la cabeza hacia -Z.
	franchesca.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
	franchesca.position = tirada + Vector3(0, 0.32, 0)
	_restos(tirada + Vector3(-1.5, 0, -4.0))
	polo.visible = true
	polo.position = Vector3(0.6, 0, -13.0)
	polo.rotation.y = 0.0   # Mirándola.
	polo.reproducir("Idle")
	await hud.franjas(true)

	# 1. El blanco se va despacio: ella en el asfalto, bajo la lluvia.
	_camara(tirada + Vector3(-2.4, 1.2, 0.2), tirada + Vector3(0.0, 0.25, -0.9))
	var t := create_tween()
	t.tween_property(_pantallazo, "color:a", 0.0, 2.5)
	await t.finished
	if _musica:
		_musica.stop()
	await get_tree().create_timer(1.5).timeout
	relampago(false)

	# 2. Por detrás de Polo, que la mira.
	_camara(polo.global_position + Vector3(-0.9, 1.5, 2.2), tirada + Vector3(0, 0.4, 0))
	await get_tree().create_timer(2.2).timeout

	# 3. Su línea.
	await _hablar([{"quien": "POLO", "texto": "Ya puedo llegar a mi casa a comerme una buena puñalada de carne... ya terminó todo."}])

	# 4. Se da la vuelta y camina a la camioneta.
	_camara(Vector3(-5.5, 1.6, -9.5), Vector3(1.5, 1.0, -9.0))
	var puerta := Vector3(CARRIL - 1.3, 0, FRENA_EN + 0.3)
	polo.rotation.y = atan2(-(puerta.x - polo.position.x), -(puerta.z - polo.position.z))
	polo.reproducir("Walk")
	t = create_tween()
	t.tween_property(polo, "position", puerta, 2.6)
	await t.finished
	polo.visible = false
	Sfx.plano(self, "descolgar", -10.0)
	await get_tree().create_timer(0.8).timeout

	# 5. La camioneta arranca, la esquiva por el otro carril y se pierde en la lluvia.
	_camara(tirada + Vector3(3.0, 0.45, -2.0), camioneta.position + Vector3(0, 0.8, 0))
	_seguir = camioneta
	_seguir_alto = 0.8
	var motor := Sfx.bucle(self, "motor", -14.0)
	t = create_tween()
	t.tween_property(camioneta, "position", Vector3(-2.2, 0, -14.0), 2.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(camioneta, "rotation:y", 0.35, 1.3)
	t.chain().tween_property(camioneta, "rotation:y", 0.0, 0.8)
	t.parallel().tween_property(camioneta, "position", Vector3(-2.2, 0, -45.0), 2.0)
	t.chain().tween_property(camioneta, "position", Vector3(-2.2, 0, -170.0), 4.5)
	t.parallel().tween_property(motor, "volume_db", -40.0, 4.5)
	await get_tree().create_timer(5.5).timeout
	_seguir = null
	await get_tree().create_timer(2.0).timeout

	await hud.fundir(1.0, 2.0)
	if Juego.resultado.is_empty():
		Juego.resultado = "completo"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(Juego.ESCENA_FINAL)


## Pedazos rojos del helicóptero tirados en la vía, ardiendo con una luz que titila.
func _restos(centro: Vector3) -> void:
	var rojo := _mat(Color("8e1c18"), 0.6, 0.3)
	var negro := _mat(Color("161616"), 0.9)
	var piezas: Array = [
		[Vector3(1.6, 0.7, 2.4), Vector3(0, 0.3, 0), Vector3(0.2, 0.5, 0.35), rojo],
		[Vector3(0.3, 0.25, 3.2), Vector3(1.8, 0.12, 1.4), Vector3(0, -0.7, 0.1), rojo],
		[Vector3(4.5, 0.08, 0.3), Vector3(-1.6, 0.05, 1.0), Vector3(0, 0.4, 0), negro],
		[Vector3(0.9, 0.5, 0.7), Vector3(2.4, 0.25, -1.3), Vector3(0.4, 1.1, 0.2), negro],
	]
	for p: Array in piezas:
		var m := _caja(p[0] as Vector3, centro + (p[1] as Vector3), p[3] as Material)
		m.rotation = p[2] as Vector3
	_fuego = OmniLight3D.new()
	_fuego.light_color = Color("ff8a2a")
	_fuego.light_energy = 2.4
	_fuego.omni_range = 9.0
	add_child(_fuego)
	_fuego.global_position = centro + Vector3(0, 1.0, 0)
	# Llamitas.
	var llama := StandardMaterial3D.new()
	llama.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	llama.albedo_color = Color("ffb04a")
	for d: Vector3 in [Vector3(0.2, 0.75, 0.1), Vector3(1.7, 0.35, 1.5), Vector3(-0.4, 0.6, -0.5)]:
		var f := MeshInstance3D.new()
		var cono := CylinderMesh.new()
		cono.top_radius = 0.0
		cono.bottom_radius = 0.18
		cono.height = 0.5
		f.mesh = cono
		f.material_override = llama
		add_child(f)
		f.global_position = centro + d


## Lo llaman las explosiones (grupo "temblor") para sacudir la cámara.
func temblar(fuerza: float) -> void:
	_temblor = maxf(_temblor, fuerza)


func _borrar_camaras_de_cine() -> void:
	for c: Node in find_children("*", "Camera3D", true, false):
		if c.has_meta("cine"):
			c.queue_free()


## Diálogo cara a cara: antes de cada línea la cámara corta al que habla.
func _hablar(lineas: Array[Dictionary]) -> void:
	for linea: Dictionary in lineas:
		_plano_cara(polo if linea["quien"] == "POLO" else franchesca)
		await hud.reproducir_llamada([linea], automatica, false)


## Primer plano de la cara de un personaje, un poco de lado.
func _plano_cara(c: Cuerpo) -> Camera3D:
	var cara: float = Cuerpo.TIPOS[c.tipo].get("cara", 1.6)
	var frente: Vector3 = -c.global_basis.z
	var costado: Vector3 = c.global_basis.x
	var ojos: Vector3 = c.global_position + Vector3.UP * cara
	# Mira un poco más abajo de los ojos: la cara queda en el tercio de arriba,
	# lejos del cuadro de diálogo.
	# Las cabezas normales necesitan la cámara cerca; la de Franchesca es enorme.
	var dist: float = Cuerpo.TIPOS[c.tipo].get("dist_cara", 0.95)
	var cam := _camara(ojos + frente * dist + costado * dist * 0.26 + Vector3.UP * 0.02, ojos + Vector3.DOWN * 0.05)
	cam.fov = 40.0
	return cam


## Cambia a una cámara nueva (borra la anterior) con una luz de relleno suave.
func _camara(desde: Vector3, hacia: Vector3) -> Camera3D:
	var vieja: Camera3D = get_viewport().get_camera_3d()
	if vieja and vieja.has_meta("cine"):
		vieja.queue_free()
	var cam := Camera3D.new()
	cam.set_meta("cine", true)
	cam.fov = 50.0
	cam.far = 400.0
	add_child(cam)
	cam.global_position = desde
	if not desde.is_equal_approx(hacia):
		cam.look_at(hacia)
	cam.make_current()
	var relleno := OmniLight3D.new()
	relleno.light_color = Color("c9d6ff")
	relleno.light_energy = 1.4
	relleno.omni_range = 5.0
	cam.add_child(relleno)
	return cam


## Destello de relámpago y, un poco después, el trueno.
func relampago(fuerte: bool) -> void:
	var e: float = 3.2 if fuerte else 1.8
	var t := create_tween()
	t.tween_property(_relampago, "light_energy", e, 0.04)
	t.tween_property(_relampago, "light_energy", 0.3, 0.08)
	t.tween_property(_relampago, "light_energy", e * 0.8, 0.05)
	t.tween_property(_relampago, "light_energy", 0.0, 0.4)
	await get_tree().create_timer(0.25 if fuerte else randf_range(0.7, 1.6)).timeout
	Sfx.plano(self, "trueno", -3.0 if fuerte else -10.0)


# ------------------------------------------------------------------ el lugar

func _armar_cielo() -> void:
	var mundo := WorldEnvironment.new()
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color("0b0f17")
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color("6a7a96")
	entorno.ambient_light_energy = 0.35
	entorno.fog_enabled = true
	entorno.fog_light_color = Color("161c28")
	entorno.fog_density = 0.02
	entorno.glow_enabled = true
	entorno.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	mundo.environment = entorno
	add_child(mundo)
	var luna := DirectionalLight3D.new()
	luna.light_color = Color("8fa3c8")
	luna.light_energy = 0.3
	luna.rotation_degrees = Vector3(-50, 30, 0)
	add_child(luna)
	_relampago = DirectionalLight3D.new()
	_relampago.light_color = Color("dfe8ff")
	_relampago.light_energy = 0.0
	_relampago.rotation_degrees = Vector3(-65, -40, 0)
	add_child(_relampago)


func _armar_via() -> void:
	var centro_z: float = -10.0
	# Asfalto mojado: casi liso y algo metálico para que brille con los faros.
	var asfalto := _mat(Color("1a1b1e"), 0.12, 0.35)
	_caja(Vector3(ANCHO_VIA, 0.2, LARGO_VIA), Vector3(0, -0.1, centro_z), asfalto)
	var pasto := _mat(Color("1b2618"), 1.0)
	for lado: float in [-1.0, 1.0]:
		_caja(Vector3(80, 0.2, LARGO_VIA), Vector3(lado * (ANCHO_VIA * 0.5 + 40), -0.18, centro_z), pasto)
		# Línea blanca del borde.
		_caja(Vector3(0.15, 0.02, LARGO_VIA), Vector3(lado * (ANCHO_VIA * 0.5 - 0.35), 0.01, centro_z), _mat(Color("c9c9c0"), 0.4))
		# Baranda metálica.
		_caja(Vector3(0.06, 0.3, LARGO_VIA), Vector3(lado * (ANCHO_VIA * 0.5 + 0.9), 0.7, centro_z), _mat(Color("8a8f96"), 0.3, 0.6))
	# Línea amarilla del centro, a trozos.
	var raya := BoxMesh.new()
	raya.size = Vector3(0.15, 0.02, 3.0)
	raya.material = _mat(Color("d9b13a"), 0.4)
	_varias(raya, range(-200, 200, 8).map(func(z: int) -> Transform3D: return Transform3D(Basis(), Vector3(0, 0.01, z))))
	# Postes de la baranda.
	var poste := BoxMesh.new()
	poste.size = Vector3(0.12, 0.8, 0.12)
	poste.material = _mat(Color("6f747a"), 0.5, 0.4)
	var postes: Array = []
	for z: int in range(-200, 200, 4):
		for lado: float in [-1.0, 1.0]:
			postes.append(Transform3D(Basis(), Vector3(lado * (ANCHO_VIA * 0.5 + 0.9), 0.4, z)))
	_varias(poste, postes)
	# Árboles a los lados (troncos y copas), repartidos al azar pero siempre igual.
	var azar := RandomNumberGenerator.new()
	azar.seed = 1994
	var troncos: Array = []
	var copas: Array = []
	for i: int in 220:
		var lado: float = -1.0 if i % 2 == 0 else 1.0
		var x: float = lado * azar.randf_range(8.0, 45.0)
		var z: float = azar.randf_range(-200.0, 200.0)
		var alto: float = azar.randf_range(5.0, 9.0)
		troncos.append(Transform3D(Basis().scaled(Vector3(1, alto / 4.0, 1)), Vector3(x, alto * 0.25, z)))
		copas.append(Transform3D(Basis().scaled(Vector3.ONE * alto / 6.0), Vector3(x, alto * 0.62, z)))
	var tronco := CylinderMesh.new()
	tronco.top_radius = 0.15
	tronco.bottom_radius = 0.22
	tronco.height = 2.0
	tronco.radial_segments = 6
	tronco.material = _mat(Color("2b2119"), 1.0)
	_varias(tronco, troncos)
	var copa := SphereMesh.new()
	copa.radius = 2.0
	copa.height = 3.4
	copa.radial_segments = 8
	copa.rings = 5
	copa.material = _mat(Color("16261a"), 0.9)
	_varias(copa, copas)
	# Postes de luz de sodio, uno justo sobre el sitio donde espera ella.
	for z: float in [120.0, 75.0, 30.0, -14.0, -58.0, -102.0]:
		var lado: float = 1.0 if int(z) % 2 == 0 else -1.0
		var x: float = lado * (ANCHO_VIA * 0.5 + 1.4)
		_caja(Vector3(0.18, 7.5, 0.18), Vector3(x, 3.75, z), _mat(Color("3a3d42"), 0.6, 0.5))
		_caja(Vector3(2.2, 0.12, 0.2), Vector3(x - lado * 1.0, 7.4, z), _mat(Color("3a3d42"), 0.6, 0.5))
		var foco := _caja(Vector3(0.6, 0.12, 0.3), Vector3(x - lado * 1.9, 7.3, z), _mat(Color("ffb35c"), 0.5))
		(foco.material_override as StandardMaterial3D).emission_enabled = true
		(foco.material_override as StandardMaterial3D).emission = Color("ffb35c")
		(foco.material_override as StandardMaterial3D).emission_energy_multiplier = 3.0
		var luz := SpotLight3D.new()
		luz.position = Vector3(x - lado * 1.9, 7.1, z)
		luz.rotation_degrees.x = -90.0
		luz.light_color = Color("ffb35c")
		luz.light_energy = 3.0
		luz.spot_range = 11.0
		luz.spot_angle = 50.0
		add_child(luz)


## Piso y paredes invisibles para caminar en la pelea: Polo no puede salirse de la
## vía (las barandas) ni irse lejos por la carretera.
func _armar_suelo() -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.collision_layer = Juego.CAPA_MUNDO
	cuerpo.collision_mask = 0
	add_child(cuerpo)
	var cajas: Array = [
		[Vector3(60, 0.2, 240), Vector3(0, -0.1, -20)],                       # Piso.
		[Vector3(0.4, 4, 90), Vector3(-ANCHO_VIA * 0.5 - 0.2, 2, -20)],       # Baranda izquierda.
		[Vector3(0.4, 4, 90), Vector3(ANCHO_VIA * 0.5 + 0.2, 2, -20)],        # Baranda derecha.
		[Vector3(ANCHO_VIA, 4, 0.4), Vector3(0, 2, LIMITE_ADELANTE)],         # Adelante.
		[Vector3(ANCHO_VIA, 4, 0.4), Vector3(0, 2, 6.0)],                     # Atrás.
	]
	for c: Array in cajas:
		var forma := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = c[0]
		forma.shape = b
		forma.position = c[1]
		cuerpo.add_child(forma)


func _armar_lluvia() -> void:
	_lluvia = GPUParticles3D.new()
	_lluvia.amount = 5000
	_lluvia.lifetime = 0.9
	_lluvia.preprocess = 1.0
	_lluvia.local_coords = false
	_lluvia.visibility_aabb = AABB(Vector3(-30, -40, -30), Vector3(60, 55, 60))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(22, 0.5, 22)
	pm.direction = Vector3(0.12, -1, 0)
	pm.spread = 2.0
	pm.initial_velocity_min = 24.0
	pm.initial_velocity_max = 30.0
	pm.gravity = Vector3(0, -9.8, 0)
	_lluvia.process_material = pm
	var gota := QuadMesh.new()
	gota.size = Vector2(0.018, 0.55)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.75, 0.8, 0.9, 0.3)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mat.billboard_keep_scale = true
	gota.material = mat
	_lluvia.draw_pass_1 = gota
	add_child(_lluvia)


func _armar_camioneta() -> void:
	camioneta = Node3D.new()
	add_child(camioneta)
	var modelo := (load("res://modelos/camioneta.glb") as PackedScene).instantiate() as Node3D
	modelo.rotation_degrees.y = GIRO_MODELO
	camioneta.add_child(modelo)
	Mapa.pintar_carro(modelo, Color("14161b"))
	var solido := StaticBody3D.new()
	solido.collision_layer = Juego.CAPA_MUNDO
	solido.collision_mask = 0
	var forma := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(2.1, 1.6, 4.2)
	forma.shape = caja
	forma.position.y = 0.8
	solido.add_child(forma)
	camioneta.add_child(solido)
	var blanco := _mat(Color("fff1d6"), 0.3)
	blanco.emission_enabled = true
	blanco.emission = Color("fff1d6")
	blanco.emission_energy_multiplier = 4.0
	var rojo := _mat(Color("c01818"), 0.3)
	rojo.emission_enabled = true
	rojo.emission = Color("ff2020")
	rojo.emission_energy_multiplier = 2.5
	for x: float in [-0.72, 0.72]:
		var faro := SpotLight3D.new()
		faro.position = Vector3(x, 0.85, -2.2)
		faro.rotation_degrees.x = -3.0
		faro.light_color = Color("fff1d6")
		faro.light_energy = 7.0
		faro.spot_range = 45.0
		faro.spot_angle = 20.0
		camioneta.add_child(faro)
		var bombillo := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.35, 0.14, 0.05)
		bombillo.mesh = b
		bombillo.material_override = blanco
		bombillo.position = Vector3(x, 0.85, -2.12)
		camioneta.add_child(bombillo)
		var trasera := MeshInstance3D.new()
		trasera.mesh = b
		trasera.material_override = rojo
		trasera.position = Vector3(x, 0.95, 2.12)
		camioneta.add_child(trasera)


# ------------------------------------------------------------------ ayudas

func _mat(color: Color, rugosidad: float, metal: float = 0.0) -> StandardMaterial3D:
	if not _materiales.has(color):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = rugosidad
		m.metallic = metal
		_materiales[color] = m
	return _materiales[color]


func _caja(tam: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	m.mesh = b
	m.material_override = mat
	m.position = pos
	add_child(m)
	return m


## Muchas copias de la misma figura en un solo dibujo (MultiMesh): árboles, rayas, postes.
func _varias(malla: Mesh, transformaciones: Array) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = malla
	mm.instance_count = transformaciones.size()
	for i: int in transformaciones.size():
		mm.set_instance_transform(i, transformaciones[i])
	var nodo := MultiMeshInstance3D.new()
	nodo.multimesh = mm
	add_child(nodo)
