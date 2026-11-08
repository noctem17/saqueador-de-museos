class_name Mapa
extends NavigationRegion3D
## Base común de los mapas. Trae las herramientas para armar el edificio con cajas
## (muros con puertas, suelos, techos, muebles, luces y letreros) y los datos que
## lee la misión: dónde pueden ir obras, coleccionables, cámaras, guardias y la
## camioneta. Cada mapa concreto llena esos datos en _init() y arma todo en construir().

const GROSOR: float = 0.3
const PUERTA: float = 2.4
const ALTO_PUERTA: float = 2.7
## Los muros largos se parten en tramos: el renderer Mobile solo aplica unas pocas
## luces por malla, y una malla enorme se quedaría a oscuras.
const TRAMO_MAX: float = 12.0

var slots_pared: Array = []          # Cuadros: [x, z, giro]. El giro apunta hacia la sala.
var slots_pedestal: Array = []       # Esculturas: [x, z]
var slots_coleccionable: Array = []  # Monedas y billetes: [x, y, z]
var camaras: Array = []              # [x, y, z, giro base]
var patrullas: Array = []            # Rutas de guardias: listas de [x, z]
var spawn_polo := Vector3.ZERO
var spawn_mostro := Vector3.ZERO
var spawn_policia: Array[Vector3] = []
var pos_terminal := Vector3.ZERO
var pos_camioneta := Vector3.ZERO
var giro_camioneta: float = -90.0
var fin_huida := Vector3.ZERO
var plano_huida := Vector3.ZERO      # Desde dónde se filma la huida.
var punto_prueba := Vector3.ZERO     # Sitio despejado que usan las pruebas automáticas.
var punto_lejano := Vector3.ZERO     # Sitio lejos de la entrada, para probar que hay ruta.

var _materiales: Dictionary[String, StandardMaterial3D] = {}


## Cada mapa lo reemplaza con su propio edificio.
func construir() -> void:
	pass


func material(color: Color, rugosidad: float = 0.8) -> StandardMaterial3D:
	var clave: String = "%s/%.2f" % [color.to_html(), rugosidad]
	if not _materiales.has(clave):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = rugosidad
		_materiales[clave] = mat
	return _materiales[clave]


## Muro recto con huecos de puerta. horizontal: corre a lo largo de x en z = fijo;
## si no, corre a lo largo de z en x = fijo.
func muro(horizontal: bool, fijo: float, inicio: float, fin: float, puertas: Array, alto: float, mat: Material, zocalo: bool) -> void:
	var cursor: float = inicio
	var orden: Array = puertas.duplicate()
	orden.sort()
	for centro: float in orden:
		_tramo(horizontal, fijo, cursor, centro - PUERTA * 0.5, alto, mat, zocalo)
		_dintel(horizontal, fijo, centro, alto, mat)
		cursor = centro + PUERTA * 0.5
	_tramo(horizontal, fijo, cursor, fin, alto, mat, zocalo)


func _tramo(horizontal: bool, fijo: float, a: float, b: float, alto: float, mat: Material, zocalo: bool) -> void:
	if b - a <= 0.01:
		return
	var partes: int = ceili((b - a) / TRAMO_MAX)
	var paso: float = (b - a) / partes
	for i: int in partes:
		var largo: float = paso + GROSOR
		var medio: float = a + paso * (i + 0.5)
		var tam := Vector3(largo, alto, GROSOR) if horizontal else Vector3(GROSOR, alto, largo)
		var pos := Vector3(medio, alto * 0.5, fijo) if horizontal else Vector3(fijo, alto * 0.5, medio)
		caja_mat(tam, pos, mat, true)
		if zocalo:
			var tam_z: Vector3 = tam + (Vector3(0, 0, 0.04) if horizontal else Vector3(0.04, 0, 0))
			tam_z.y = 0.18
			caja_mat(tam_z, Vector3(pos.x, 0.09, pos.z), material(Color("3c3833")), false)


func _dintel(horizontal: bool, fijo: float, centro: float, alto: float, mat: Material) -> void:
	var resto: float = alto - ALTO_PUERTA
	var tam := Vector3(PUERTA, resto, GROSOR) if horizontal else Vector3(GROSOR, resto, PUERTA)
	var y: float = ALTO_PUERTA + resto * 0.5
	var pos := Vector3(centro, y, fijo) if horizontal else Vector3(fijo, y, centro)
	caja_mat(tam, pos, mat, true)


## Muro entre dos puntos cualesquiera del plano (para las esquinas en diagonal).
func muro_diagonal(a: Vector2, b: Vector2, alto: float, mat: Material) -> void:
	var largo: float = a.distance_to(b) + GROSOR
	var medio: Vector2 = (a + b) * 0.5
	var giro: float = -atan2(b.y - a.y, b.x - a.x)
	caja_mat(Vector3(largo, alto, GROSOR), Vector3(medio.x, alto * 0.5, medio.y), mat, true, giro)


func suelo(x0: float, z0: float, x1: float, z1: float, color: Color, y: float = 0.005) -> void:
	var m := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(x1 - x0, z1 - z0)
	m.mesh = plano
	m.position = Vector3((x0 + x1) * 0.5, y, (z0 + z1) * 0.5)
	m.material_override = material(color, 0.45)
	add_child(m)


func techo(x0: float, z0: float, x1: float, z1: float, y: float, color: Color) -> void:
	# Termina en el centro de los muros para que el borde no asome por fuera.
	caja_mat(Vector3(x1 - x0, 0.2, z1 - z0), Vector3((x0 + x1) * 0.5, y + 0.1, (z0 + z1) * 0.5), material(color), false)


func caja(tam: Vector3, pos: Vector3, color: Color, solida: bool = true, giro: float = 0.0) -> void:
	caja_mat(tam, pos, material(color), solida, giro)


## Caja con malla visible (si hay material) y colisión (si es sólida).
func caja_mat(tam: Vector3, pos: Vector3, mat: Material, solida: bool, giro: float = 0.0) -> void:
	if mat != null:
		var m := MeshInstance3D.new()
		var forma_visual := BoxMesh.new()
		forma_visual.size = tam
		m.mesh = forma_visual
		m.position = pos
		m.rotation.y = giro
		m.material_override = mat
		add_child(m)
	if solida:
		var forma := BoxShape3D.new()
		forma.size = tam
		_cuerpo_solido(forma, pos, giro)


## Cilindro apoyado en el piso: pos es el centro de la base. Con radio_abajo distinto
## sale un cono truncado (tazas de fuente, bases).
func cilindro(radio: float, alto: float, pos: Vector3, color: Color, lados: int = 12, solido: bool = true, radio_abajo: float = -1.0) -> void:
	var m := MeshInstance3D.new()
	var forma_visual := CylinderMesh.new()
	forma_visual.top_radius = radio
	forma_visual.bottom_radius = radio if radio_abajo < 0.0 else radio_abajo
	forma_visual.height = alto
	forma_visual.radial_segments = lados
	forma_visual.rings = 1
	m.mesh = forma_visual
	m.position = pos + Vector3.UP * alto * 0.5
	m.material_override = material(color)
	add_child(m)
	if solido:
		var forma := CylinderShape3D.new()
		forma.radius = radio
		forma.height = alto
		_cuerpo_solido(forma, m.position, 0.0)


func esfera(radio: float, pos: Vector3, mat: Material) -> void:
	var m := MeshInstance3D.new()
	var forma_visual := SphereMesh.new()
	forma_visual.radius = radio
	forma_visual.height = radio * 2.0
	forma_visual.radial_segments = 8
	forma_visual.rings = 5
	m.mesh = forma_visual
	m.position = pos
	m.material_override = mat
	add_child(m)


func _cuerpo_solido(forma: Shape3D, pos: Vector3, giro: float) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.collision_layer = Juego.CAPA_MUNDO
	cuerpo.collision_mask = 0
	cuerpo.position = pos
	cuerpo.rotation.y = giro
	var col := CollisionShape3D.new()
	col.shape = forma
	cuerpo.add_child(col)
	add_child(cuerpo)


## Luz de sala. Las del grupo "luces_sala" se ponen rojas cuando suena la alarma.
func luz(pos: Vector3, energia: float, rango: float, sombras: bool, color: Color = Color("ffe6c4"), de_sala: bool = true) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energia
	l.omni_range = rango
	l.omni_attenuation = 0.8
	l.shadow_enabled = sombras
	if de_sala:
		l.add_to_group("luces_sala")
	add_child(l)
	return l


## Texto pegado a una pared. El giro funciona igual que en los cuadros.
func letrero(texto: String, pos: Vector3, giro: float, tam: int = 56, color: Color = Color("2b2622")) -> void:
	var l := Label3D.new()
	l.text = texto
	l.font_size = tam
	l.pixel_size = 0.004
	l.modulate = color
	l.outline_size = 0
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = pos
	l.rotation_degrees.y = giro
	add_child(l)


## Panel blanco detrás de un cuadro, para que la obra no quede sobre la piedra.
func panel_de_obra(slot: Array, ancho: float = 2.8, alto: float = 2.6) -> void:
	var giro: float = deg_to_rad(slot[2] as float)
	var frente := Vector3(sin(giro), 0.0, cos(giro))
	var pos := Vector3(slot[0], 1.9, slot[1]) - frente * 0.025
	caja_mat(Vector3(ancho, alto, 0.04), pos, material(Color("ece7dd")), false, giro)


func banca(x: float, z: float, giro: float) -> void:
	var escena: PackedScene = load("res://modelos/banca.glb")
	var b := escena.instantiate() as Node3D
	b.scale = Vector3(2.4, 1.42, 2.2)
	b.position = Vector3(x, 0, z)
	b.rotation_degrees.y = giro
	add_child(b)
	var largo := Vector3(1.6, 0.45, 0.55) if is_zero_approx(fmod(giro, 180.0)) else Vector3(0.55, 0.45, 1.6)
	caja_mat(largo, Vector3(x, 0.225, z), null, true)


func carro(pos: Vector3, color: Color, giro: float = 0.0) -> void:
	var escena: PackedScene = load("res://modelos/camioneta.glb")
	var modelo := escena.instantiate() as Node3D
	modelo.position = pos
	modelo.rotation_degrees.y = giro
	add_child(modelo)
	pintar_carro(modelo, color)
	var tam := Vector3(2.1, 1.5, 4.2) if is_zero_approx(fmod(giro, 180.0)) else Vector3(4.2, 1.5, 2.1)
	caja_mat(tam, pos + Vector3(0, 0.75, 0), null, true)


## Cambia el color de la carrocería de un carro del paquete.
static func pintar_carro(modelo: Node3D, color: Color) -> void:
	for nodo: Node in modelo.find_children("*", "MeshInstance3D", true, false):
		var malla := nodo as MeshInstance3D
		for s: int in malla.mesh.get_surface_count():
			var original: Material = malla.get_active_material(s)
			if original.resource_name == "White":
				var nuevo := original.duplicate() as BaseMaterial3D
				nuevo.albedo_color = color
				nuevo.metallic = 0.6
				nuevo.roughness = 0.3
				malla.set_surface_override_material(s, nuevo)


func ambiente(fondo: Color, luz_ambiente: Color, energia: float) -> void:
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = fondo
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = luz_ambiente
	entorno.ambient_light_energy = energia
	entorno.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var mundo := WorldEnvironment.new()
	mundo.environment = entorno
	add_child(mundo)


## Calcula por dónde pueden caminar los guardias a partir de las colisiones.
func hornear_navegacion() -> void:
	var nav := NavigationMesh.new()
	nav.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav.geometry_collision_mask = Juego.CAPA_MUNDO
	nav.cell_size = 0.25
	nav.cell_height = 0.25
	nav.agent_radius = 0.5
	nav.agent_height = 2.0
	nav.agent_max_climb = 0.25
	navigation_mesh = nav
	bake_navigation_mesh(false)
