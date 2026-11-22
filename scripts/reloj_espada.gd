class_name RelojEspada
extends RefCounted
## La espada de Bolívar está en el centro del Panóptico, al fondo del pozo de luz,
## dentro de una jaula. La jaula no tiene candado: abre con un reloj antiguo. Hay
## que poner las agujas en las 3:19. El 3 del reloj está acostado y parece una M:
## la hora se lee M-19, los que se llevaron esa misma espada en 1974.
##
## Se usan como RelojEspada.Reloj y RelojEspada.Jaula desde mision.gd.

const HORA_CORRECTA: int = 3 * 60 + 19   ## Minutos desde las 12:00.
const HORA_INICIAL: int = 7 * 60 + 45    ## El reloj está parado a las 7:45.


## Reloj de pie con la carátula hacia +Z. Mantener F para acercarse a él.
class Reloj:
	extends Interactuable
	signal resuelto

	var minutos: int = HORA_INICIAL
	var resuelto_ya: bool = false
	var _activo: bool = false
	var _aguja_hora: Node3D
	var _aguja_minuto: Node3D
	var _caratula: Node3D
	var _cam: Camera3D
	var _ayuda: CanvasLayer
	var _acumulado: float = 0.0
	var _sostenido: float = 0.0
	var _jugador: Jugador

	func _ready() -> void:
		duracion = 0.4
		var madera := _mat(Color("3a2518"), 0.6)
		var laton := _mat(Color("c9a24a"), 0.35, 0.7)
		# Pie, caja y remate.
		_caja(Vector3(0.5, 1.3, 0.34), Vector3(0, 0.65, 0), madera)
		_caja(Vector3(0.72, 0.74, 0.3), Vector3(0, 1.67, 0), madera)
		_caja(Vector3(0.78, 0.08, 0.36), Vector3(0, 2.08, 0), laton)
		# Carátula: disco blanco mirando a +Z.
		_caratula = Node3D.new()
		_caratula.position = Vector3(0, 1.67, 0.16)
		add_child(_caratula)
		var disco := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.3
		c.bottom_radius = 0.3
		c.height = 0.02
		c.radial_segments = 32
		disco.mesh = c
		disco.material_override = _mat(Color("efe6cf"), 0.8)
		disco.rotation.x = PI * 0.5
		_caratula.add_child(disco)
		var aro := MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = 0.29
		t.outer_radius = 0.32
		aro.mesh = t
		aro.material_override = laton
		aro.rotation.x = PI * 0.5
		_caratula.add_child(aro)
		# Números. El 3 va acostado, con las curvas hacia arriba: parece una M.
		for n: int in range(1, 13):
			var ang: float = TAU * n / 12.0
			var l := Label3D.new()
			l.text = str(n)
			l.font_size = 40
			l.pixel_size = 0.0022
			l.modulate = Color("1d1a17")
			l.outline_size = 0
			l.position = Vector3(sin(ang) * 0.23, cos(ang) * 0.23, 0.015)
			if n == 3:
				l.rotation.z = PI * 0.5
				l.modulate = Color("5a1712")
			_caratula.add_child(l)
		_aguja_hora = _aguja(Vector3(0.022, 0.15, 0.006), Color("15120f"), 0.02)
		_aguja_minuto = _aguja(Vector3(0.014, 0.24, 0.006), Color("15120f"), 0.03)
		# Papelito pegado por el vigilante, al lado de la carátula.
		var papel := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.2, 0.2)
		papel.mesh = q
		papel.material_override = _mat(Color("f2e27a"), 0.9)
		papel.position = Vector3(0.0, 1.18, 0.175)
		papel.rotation.z = 0.08
		add_child(papel)
		var nota := Label3D.new()
		nota.text = "CLAVE DE LA JAULA:\nla hora del 19.\nLa M ya está\nen el reloj.\nNO LA DIGA A NADIE\n— Vigilante Gómez"
		nota.font_size = 16
		nota.pixel_size = 0.0016
		nota.modulate = Color("2a2016")
		nota.outline_size = 0
		nota.position = Vector3(0.0, 1.18, 0.177)
		nota.rotation.z = 0.08
		add_child(nota)
		agregar_colision(Vector3(0.8, 2.2, 0.5), Vector3(0, 1.1, 0))
		_mostrar_hora()

	func _aguja(tam: Vector3, color: Color, z: float) -> Node3D:
		var eje := Node3D.new()
		eje.position.z = z
		_caratula.add_child(eje)
		var m := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = tam
		m.mesh = b
		m.material_override = _mat(color, 0.5)
		m.position.y = tam.y * 0.5 - 0.02
		eje.add_child(m)
		return eje

	func _caja(tam: Vector3, pos: Vector3, mat: Material) -> void:
		var m := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = tam
		m.mesh = b
		m.material_override = mat
		m.position = pos
		add_child(m)

	func _mat(color: Color, rugosidad: float, metal: float = 0.0) -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = rugosidad
		m.metallic = metal
		return m

	## Las agujas se mueven como en un reloj de verdad: la del minuto arrastra la de la hora.
	func _mostrar_hora() -> void:
		var m: int = posmod(minutos, 720)
		_aguja_minuto.rotation.z = -TAU * (m % 60) / 60.0
		_aguja_hora.rotation.z = -TAU * m / 720.0

	func disponible(_j: Jugador) -> bool:
		return not resuelto_ya and not _activo

	func prompt(_j: Jugador) -> String:
		if resuelto_ya:
			return "El reloj marca las 3:19. La jaula está abierta."
		return "[F] Examinar el reloj"

	func completar(j: Jugador) -> void:
		_jugador = j
		_activo = true
		Juego.control_bloqueado = true
		# Cámara de frente a la carátula.
		_cam = Camera3D.new()
		_cam.fov = 40.0
		add_child(_cam)
		_cam.global_position = _caratula.global_position + global_basis.z * 0.95 + Vector3.UP * 0.05
		_cam.look_at(_caratula.global_position)
		_cam.make_current()
		_ayuda = CanvasLayer.new()
		_ayuda.layer = 8
		add_child(_ayuda)
		var l := Label.new()
		l.text = "A / D: mover las agujas (mantén para ir rápido)    F: probar la hora    ESPACIO: dejar el reloj"
		l.add_theme_font_size_override("font_size", 18)
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", 6)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.anchor_left = 0.0
		l.anchor_right = 1.0
		l.anchor_top = 1.0
		l.anchor_bottom = 1.0
		l.offset_top = -70
		l.offset_bottom = -40
		_ayuda.add_child(l)
		if not Juego.alarma_disparada.is_connected(_por_alarma):
			Juego.alarma_disparada.connect(_por_alarma)

	func _process(delta: float) -> void:
		if not _activo or get_tree().paused:
			return
		var dir: float = Input.get_axis("izquierda", "derecha")
		if dir != 0.0:
			_sostenido += delta
			# Empieza despacio (un minuto a la vez) y acelera si se mantiene.
			var velocidad: float = 6.0 if _sostenido < 1.0 else (30.0 if _sostenido < 2.5 else 90.0)
			_acumulado += delta * velocidad
			while _acumulado >= 1.0:
				_acumulado -= 1.0
				minutos += int(signf(dir))
				if posmod(minutos, 5) == 0:
					Sfx.plano(self, "tic", -16.0)
			_mostrar_hora()
		else:
			_sostenido = 0.0
			_acumulado = 0.0
		if Input.is_action_just_pressed("interactuar"):
			_probar()
		elif Input.is_action_just_pressed("saltar"):
			_salir()

	## Prueba la hora puesta. Vale 3:19 de la madrugada o de la tarde.
	func probar_hora(m: int) -> bool:
		minutos = m
		_mostrar_hora()
		return _probar()

	func _probar() -> bool:
		if posmod(minutos, 720) == HORA_CORRECTA:
			resuelto_ya = true
			Sfx.plano(self, "consola", -4.0)
			if _activo:
				_salir()
			resuelto.emit()
			return true
		Sfx.plano(self, "impacto", -12.0)
		var t := create_tween()
		t.tween_property(_caratula, "rotation:z", 0.04, 0.05)
		t.tween_property(_caratula, "rotation:z", -0.04, 0.08)
		t.tween_property(_caratula, "rotation:z", 0.0, 0.05)
		Juego.aviso.emit("Nada. Esa no es la hora.")
		return false

	func _por_alarma(_motivo: String) -> void:
		if _activo:
			_salir(false)

	func _salir(devolver_control: bool = true) -> void:
		_activo = false
		if is_instance_valid(_cam):
			_cam.queue_free()
		if is_instance_valid(_ayuda):
			_ayuda.queue_free()
		if is_instance_valid(_jugador):
			_jugador.activar_camara()
		if devolver_control:
			Juego.control_bloqueado = false


## Jaula octogonal de barrotes alrededor del pedestal. Al abrirse sube por el pozo de luz.
class Jaula:
	extends Node3D
	signal abierta

	const RADIO: float = 1.3
	const ALTO: float = 2.7
	var _solido: CollisionShape3D
	var _abierta: bool = false

	func _ready() -> void:
		var hierro := StandardMaterial3D.new()
		hierro.albedo_color = Color("1f1c19")
		hierro.metallic = 0.6
		hierro.roughness = 0.45
		var oro := StandardMaterial3D.new()
		oro.albedo_color = Color("b8913a")
		oro.metallic = 0.8
		oro.roughness = 0.3
		for i: int in 24:
			var ang: float = TAU * i / 24.0
			_barra(Vector3(0.035, ALTO, 0.035), Vector3(cos(ang) * RADIO, ALTO * 0.5, sin(ang) * RADIO), 0.0, hierro)
		for y: float in [0.06, 1.3, ALTO - 0.05]:
			var aro := MeshInstance3D.new()
			var t := TorusMesh.new()
			t.inner_radius = RADIO - 0.035
			t.outer_radius = RADIO + 0.035
			t.rings = 32
			aro.mesh = t
			aro.material_override = oro if y > 1.0 else hierro
			aro.position.y = y
			add_child(aro)
		# Techo en cúpula de barrotes.
		for i: int in 8:
			var ang: float = TAU * i / 8.0
			var b := _barra(Vector3(0.03, 0.03, RADIO), Vector3(cos(ang) * RADIO * 0.5, ALTO + 0.25, sin(ang) * RADIO * 0.5), -ang + PI * 0.5, hierro)
			b.rotation.x = 0.38
		var placa := Label3D.new()
		placa.text = "PRÉSTAMO ESPECIAL\nCasa Museo Quinta de Bolívar\nNo tocar. No respirar. No soñar."
		placa.font_size = 22
		placa.pixel_size = 0.0022
		placa.modulate = Color("e9dcc0")
		placa.outline_size = 6
		placa.position = Vector3(0, 0.5, RADIO + 0.06)
		add_child(placa)
		var cuerpo := StaticBody3D.new()
		cuerpo.collision_layer = Juego.CAPA_MUNDO
		cuerpo.collision_mask = 0
		_solido = CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = Vector3(RADIO * 2.0, ALTO, RADIO * 2.0)
		_solido.shape = forma
		_solido.position.y = ALTO * 0.5
		cuerpo.add_child(_solido)
		add_child(cuerpo)

	func _barra(tam: Vector3, pos: Vector3, giro_y: float, mat: Material) -> MeshInstance3D:
		var m := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = tam
		m.mesh = b
		m.material_override = mat
		m.position = pos
		m.rotation.y = giro_y
		add_child(m)
		return m

	func abrir() -> void:
		if _abierta:
			return
		_abierta = true
		_solido.set_deferred("disabled", true)
		Sfx.plano(get_parent(), "mecanismo", -4.0)
		var t := create_tween()
		t.tween_property(self, "position:y", position.y + 7.0, 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_callback(hide)
		Juego.aviso.emit("La jaula de la espada se abrió")
		abierta.emit()
