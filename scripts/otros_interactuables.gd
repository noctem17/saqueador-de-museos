extends RefCounted
## Coleccionable, Terminal, Vehiculo y PoloEscondido viven aquí porque son pequeños.
## Se usan como Otros.Coleccionable, Otros.Terminal, etc.


class Coleccionable:
	extends Interactuable
	var datos: Dictionary = {}
	var _visual: MeshInstance3D
	var _brillo: MeshInstance3D
	var _mat_brillo: StandardMaterial3D
	var _tiempo: float = 0.0

	func configurar(info: Dictionary) -> void:
		datos = info
		duracion = 0.4
		agregar_colision(Vector3(0.22, 0.14, 0.22), Vector3(0, 0.07, 0))
		_visual = MeshInstance3D.new()
		var mat := StandardMaterial3D.new()
		mat.emission_enabled = true
		mat.emission_energy_multiplier = 0.9
		var forma: String = info["forma"]
		if forma == "moneda":
			var disco := CylinderMesh.new()
			disco.top_radius = 0.022
			disco.bottom_radius = 0.022
			disco.height = 0.004
			disco.radial_segments = 10
			_visual.mesh = disco
			mat.albedo_color = Color("d6ad2a")
			mat.emission = Color("8a6a12")
			mat.metallic = 0.9
			mat.roughness = 0.3
		else:
			var papel := BoxMesh.new()
			papel.size = Vector3(0.15, 0.002, 0.07) if forma == "billete" else Vector3(0.11, 0.002, 0.15)
			_visual.mesh = papel
			mat.albedo_color = Color("8fae7f") if forma == "billete" else Color("e6dcc0")
			mat.emission = Color("3a4433") if forma == "billete" else Color("4f4a3c")
		_visual.material_override = mat
		_visual.position.y = 0.006
		_visual.rotation.y = randf() * TAU
		add_child(_visual)

		# Destello: es lo que delata la pieza, no su tamaño.
		_brillo = MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE * 0.2
		_brillo.mesh = quad
		var degradado := Gradient.new()
		degradado.set_color(0, Color(1.0, 0.95, 0.7, 1.0))
		degradado.set_color(1, Color(1.0, 0.85, 0.4, 0.0))
		var textura := GradientTexture2D.new()
		textura.gradient = degradado
		textura.fill = GradientTexture2D.FILL_RADIAL
		textura.fill_from = Vector2(0.5, 0.5)
		textura.fill_to = Vector2(1.0, 0.5)
		_mat_brillo = StandardMaterial3D.new()
		_mat_brillo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat_brillo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat_brillo.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_mat_brillo.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_mat_brillo.albedo_texture = textura
		_brillo.material_override = _mat_brillo
		_brillo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_brillo.position.y = 0.03
		add_child(_brillo)
		_tiempo = randf() * TAU

	func _process(delta: float) -> void:
		_tiempo += delta * 2.6
		var pulso: float = pow(0.5 + 0.5 * sin(_tiempo), 4.0)
		_mat_brillo.albedo_color.a = 0.25 + 0.75 * pulso
		_brillo.scale = Vector3.ONE * (0.7 + 0.6 * pulso)

	func prompt(_j: Jugador) -> String:
		return "[F] Guardar en el bolso: %s" % datos["nombre"]

	func completar(_j: Jugador) -> void:
		Sfx.plano(get_parent(), "moneda" if datos["forma"] == "moneda" else "papel", -6.0)
		Juego.registrar_coleccionable(datos)
		queue_free()


## Consola de la sala de seguridad: apaga todas las cámaras.
class Terminal:
	extends Interactuable
	var usada: bool = false

	func _ready() -> void:
		duracion = 3.5

	func disponible(_j: Jugador) -> bool:
		return not usada and not Juego.alarma

	func prompt(_j: Jugador) -> String:
		return "" if usada or Juego.alarma else "[F] Apagar las cámaras"

	func completar(_j: Jugador) -> void:
		usada = true
		Sfx.plano(get_parent(), "consola", -6.0)
		get_tree().call_group("camaras", "desactivar")
		Juego.aviso.emit("Cámaras fuera de línea")


## La camioneta. Termina la misión si se puede salir.
class Vehiculo:
	extends Interactuable
	signal escapar

	func _ready() -> void:
		duracion = 1.0

	func prompt(j: Jugador) -> String:
		if j.personaje == Jugador.Personaje.MOSTRO and not j.polo_rescatado:
			return "Falta Polo: no se va sin él"
		if Juego.faltantes() > 0 and not Juego.alarma:
			return "Aún no: piezas pendientes en la agenda: %d" % Juego.faltantes()
		if Juego.faltantes() > 0:
			return "[F] Huir con lo que hay (pendientes: %d)" % Juego.faltantes()
		return "[F] Arrancar"

	func disponible(j: Jugador) -> bool:
		if j.personaje == Jugador.Personaje.MOSTRO and not j.polo_rescatado:
			return false
		return Juego.alarma or Juego.faltantes() == 0

	func completar(_j: Jugador) -> void:
		escapar.emit()


## Polo agachado esperando a que Mostro lo saque tras la alarma.
class PoloEscondido:
	extends Interactuable
	signal rescatado

	func _ready() -> void:
		duracion = 1.0
		agregar_colision(Vector3(1.0, 1.3, 1.0), Vector3(0, 0.65, 0))
		var cuerpo: Cuerpo = Cuerpo.crear("polo")
		add_child(cuerpo)
		cuerpo.agachar()

	func prompt(_j: Jugador) -> String:
		return "[F] Sacar a Polo"

	func completar(j: Jugador) -> void:
		j.polo_rescatado = true
		rescatado.emit()
		queue_free()


## Polo corriendo detrás de Mostro después del rescate.
class PoloSeguidor:
	extends Node3D
	const VELOCIDAD: float = 4.6
	var objetivo: Node3D
	var _agente: NavigationAgent3D
	var _cuerpo: Cuerpo

	func _ready() -> void:
		_cuerpo = Cuerpo.crear("polo")
		add_child(_cuerpo)
		_agente = NavigationAgent3D.new()
		_agente.path_desired_distance = 0.6
		_agente.target_desired_distance = 2.2
		add_child(_agente)

	func _physics_process(delta: float) -> void:
		if objetivo == null or Juego.control_bloqueado:
			return
		_agente.target_position = objetivo.global_position
		if _agente.is_navigation_finished():
			_cuerpo.reproducir("Idle")
			return
		var dir: Vector3 = _agente.get_next_path_position() - global_position
		dir.y = 0.0
		if dir.length() < 0.05:
			return
		dir = dir.normalized()
		global_position += dir * VELOCIDAD * delta
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), clampf(delta * 8.0, 0.0, 1.0))
		_cuerpo.reproducir("Run")
