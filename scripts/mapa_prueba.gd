class_name MapaPrueba
extends NavigationRegion3D
## Mapa de prueba, NO es el museo real. Se arma con estas listas para poder
## rediseñarlo rápido cuando lleguen los planos.
##
##        z-24  ┌───────────────────────────┬────────┬────────┐
##              │        SALA GRANDE         DEPÓSITO│SEGURIDAD│
##        z-6   ├─────┬ ┬──────────┬ ┬───────┼─┬ ─────┬ ┬─────┤
##              │ SALA A    VESTÍBULO      SALA B             │
##        z12   └──────────────┬ ┬────────────────────────────┘
##                       PARQUEADERO (camioneta)

const ALTO: float = 4.0
const GROSOR: float = 0.3
const PUERTA: float = 2.4
const ALTO_PUERTA: float = 2.7

## [z, x_inicio, x_fin, [centros de puertas en x]]
const MUROS_H: Array = [
	[-24.0, -24.0, 24.0, []],
	[-6.0, -24.0, 24.0, [-16.0, 0.0, 12.0, 20.0]],
	[12.0, -24.0, 24.0, [0.0]],
]
## [x, z_inicio, z_fin, [centros de puertas en z]]
const MUROS_V: Array = [
	[-24.0, -24.0, 12.0, []],
	[24.0, -24.0, 12.0, []],
	[-8.0, -6.0, 12.0, [3.0]],
	[8.0, -6.0, 12.0, [3.0]],
	[8.0, -24.0, -6.0, [-15.0]],
	[16.0, -24.0, -6.0, []],
]
## Paneles sueltos: sirven de cobertura y también exhiben obras. [x, z, largo_x, largo_z]
const PANELES: Array = [
	[-14.0, -15.0, 0.3, 7.0],
	[-2.0, -15.0, 0.3, 7.0],
	[-16.0, 3.0, 5.0, 0.3],
	[16.0, 3.0, 5.0, 0.3],
]
const SUELOS: Array = [
	# [x0, z0, x1, z1, color]
	[-24.0, -24.0, 8.0, -6.0, "6e4d33"],
	[8.0, -24.0, 16.0, -6.0, "4c4a48"],
	[16.0, -24.0, 24.0, -6.0, "3f4a55"],
	[-24.0, -6.0, -8.0, 12.0, "745238"],
	[-8.0, -6.0, 8.0, 12.0, "8d8a84"],
	[8.0, -6.0, 24.0, 12.0, "745238"],
]
const LUCES: Array = [
	[-16.0, -15.0], [-3.0, -15.0], [12.0, -15.0], [20.0, -15.0],
	[-16.0, 3.0], [0.0, 3.0], [16.0, 3.0],
]

## Dónde pueden aparecer las cosas. Cada partida se reparten al azar.
## Cuadros en pared: [x, z, giro en grados]; el giro apunta hacia el interior de la sala.
const SLOTS_PARED: Array = [
	[-23.84, -1.0, 90.0], [-23.84, 7.0, 90.0], [-20.0, -5.84, 0.0], [-11.0, -5.84, 0.0],
	[-20.0, 11.84, 180.0], [-12.0, 11.84, 180.0], [23.84, -1.0, -90.0], [23.84, 7.0, -90.0],
	[11.0, 11.84, 180.0], [20.0, 11.84, 180.0], [-20.0, -23.84, 0.0], [-9.0, -23.84, 0.0],
	[3.0, -23.84, 0.0], [-23.84, -15.0, 90.0], [-13.84, -15.0, 90.0], [-14.16, -15.0, -90.0],
	[-1.84, -15.0, 90.0], [-2.16, -15.0, -90.0], [7.84, -10.0, -90.0], [8.16, -20.0, 90.0],
]
const SLOTS_PEDESTAL: Array = [
	[-8.0, -18.0], [-8.0, -11.0], [3.0, -15.0], [-18.0, 7.0], [12.0, 7.5], [20.0, 0.0], [12.0, -20.0],
]
const SLOTS_COLECCIONABLE: Array = [
	[-22.5, 10.5], [-10.0, -3.5], [-3.5, 10.5], [3.5, -4.5], [22.5, 10.5], [10.0, -3.5],
	[-22.5, -22.5], [6.5, -22.5], [-8.0, -7.5], [14.5, -22.5], [9.5, -7.5], [22.5, -7.5],
]
const CAMARAS: Array = [
	# [x, y, z, giro base]
	[-23.3, 3.6, 11.3, -45.0], [7.3, 3.6, -5.3, 135.0], [23.3, 3.6, 11.3, 45.0],
	[-23.3, 3.6, -23.3, -135.0], [7.3, 3.6, -23.3, 135.0],
]
const PATRULLAS: Array = [
	[[0.0, 8.0], [-16.0, 8.0], [-20.0, -2.0], [-12.0, -2.0], [0.0, -2.0]],
	[[-19.0, -9.0], [-19.0, -21.0], [-8.0, -21.0], [4.0, -21.0], [4.0, -9.0], [-8.0, -9.0]],
	[[20.0, 9.0], [11.0, -1.0], [12.0, -12.0], [12.0, -1.0], [20.0, -1.0], [20.0, -12.0], [20.0, -1.0]],
]

const SPAWN_POLO := Vector3(0, 0.1, 19.0)
const SPAWN_MOSTRO := Vector3(0, 0.1, 15.0)
const SPAWN_POLICIA: Array[Vector3] = [Vector3(-22, 0.1, -9), Vector3(4, 0.1, 10)]
const POS_TERMINAL := Vector3(21.5, 1.05, -22.6)
const POS_CAMIONETA := Vector3(9.0, 0.0, 19.5)

var mat_pared: StandardMaterial3D
var mat_zocalo: StandardMaterial3D
var camioneta: Node3D


func construir() -> void:
	mat_pared = _material(Color("e4dfd5"))
	mat_zocalo = _material(Color("3c3833"))

	_caja_solida(Vector3(52, 1, 62), Vector3(0, -0.5, 2), Color("222326"), false)
	for s: Array in SUELOS:
		_suelo(s[0], s[1], s[2], s[3], Color(s[4] as String))
	_suelo(-26.0, 12.0, 26.0, 33.0, Color("2b2c30"))
	_techo()

	for m: Array in MUROS_H:
		_muro(true, m[0], m[1], m[2], m[3])
	for m: Array in MUROS_V:
		_muro(false, m[0], m[1], m[2], m[3])
	for p: Array in PANELES:
		_caja_solida(Vector3(p[2], 3.0, p[3]), Vector3(p[0], 1.5, p[1]), Color("d9d3c7"))

	# Mostrador del vestíbulo, buena cobertura al agacharse.
	_caja_solida(Vector3(5.0, 1.1, 0.8), Vector3(0, 0.55, 5.5), Color("4a3524"))
	_caja_solida(Vector3(2.0, 0.8, 0.8), Vector3(21.5, 0.4, -22.5), Color("23262b"))
	for slot: Array in SLOTS_PEDESTAL:
		_caja_solida(Vector3(0.9, 1.0, 0.9), Vector3(slot[0], 0.5, slot[1]), Color("efeae0"))
	for slot: Array in SLOTS_COLECCIONABLE:
		_caja_solida(Vector3(0.6, 0.95, 0.6), Vector3(slot[0], 0.475, slot[1]), Color("3a3a3e"))

	_parqueadero()
	_luces()
	_ambiente()
	_hornear_navegacion()


func _hornear_navegacion() -> void:
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


func _muro(horizontal: bool, fijo: float, inicio: float, fin: float, puertas: Array) -> void:
	var cursor: float = inicio
	var orden: Array = puertas.duplicate()
	orden.sort()
	for centro: float in orden:
		_tramo(horizontal, fijo, cursor, centro - PUERTA * 0.5)
		_dintel(horizontal, fijo, centro)
		cursor = centro + PUERTA * 0.5
	_tramo(horizontal, fijo, cursor, fin)


func _tramo(horizontal: bool, fijo: float, a: float, b: float) -> void:
	var largo: float = b - a + GROSOR
	var medio: float = (a + b) * 0.5
	var tam := Vector3(largo, ALTO, GROSOR) if horizontal else Vector3(GROSOR, ALTO, largo)
	var pos := Vector3(medio, ALTO * 0.5, fijo) if horizontal else Vector3(fijo, ALTO * 0.5, medio)
	_caja_mat(tam, pos, mat_pared, true)
	var tam_z: Vector3 = tam + (Vector3(0, 0, 0.04) if horizontal else Vector3(0.04, 0, 0))
	tam_z.y = 0.18
	_caja_mat(tam_z, Vector3(pos.x, 0.09, pos.z), mat_zocalo, false)


func _dintel(horizontal: bool, fijo: float, centro: float) -> void:
	var alto: float = ALTO - ALTO_PUERTA
	var tam := Vector3(PUERTA, alto, GROSOR) if horizontal else Vector3(GROSOR, alto, PUERTA)
	var y: float = ALTO_PUERTA + alto * 0.5
	var pos := Vector3(centro, y, fijo) if horizontal else Vector3(fijo, y, centro)
	_caja_mat(tam, pos, mat_pared, true)


func _suelo(x0: float, z0: float, x1: float, z1: float, color: Color) -> void:
	var m := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(x1 - x0, z1 - z0)
	m.mesh = plano
	m.position = Vector3((x0 + x1) * 0.5, 0.005, (z0 + z1) * 0.5)
	var mat := _material(color)
	mat.roughness = 0.45
	m.material_override = mat
	add_child(m)


func _techo() -> void:
	var m := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(48.3, 0.2, 36.3)
	m.mesh = caja
	m.position = Vector3(0, ALTO + 0.1, -6)
	m.material_override = _material(Color("c4c0b8"))
	add_child(m)


func _caja_solida(tam: Vector3, pos: Vector3, color: Color, visible_malla: bool = true) -> void:
	_caja_mat(tam, pos, _material(color) if visible_malla else null, true)


func _caja_mat(tam: Vector3, pos: Vector3, mat: Material, solida: bool) -> void:
	if mat != null:
		var m := MeshInstance3D.new()
		var caja := BoxMesh.new()
		caja.size = tam
		m.mesh = caja
		m.position = pos
		m.material_override = mat
		add_child(m)
	if solida:
		var cuerpo := StaticBody3D.new()
		cuerpo.collision_layer = Juego.CAPA_MUNDO
		cuerpo.collision_mask = 0
		cuerpo.position = pos
		var col := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = tam
		col.shape = forma
		cuerpo.add_child(col)
		add_child(cuerpo)


func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	return mat


func _parqueadero() -> void:
	# Muros perimetrales para que nadie se salga del mapa.
	_caja_solida(Vector3(52, 3, 0.4), Vector3(0, 1.5, 33), Color("36383c"))
	_caja_solida(Vector3(0.4, 3, 21), Vector3(-26, 1.5, 22.5), Color("36383c"))
	_caja_solida(Vector3(0.4, 3, 21), Vector3(26, 1.5, 22.5), Color("36383c"))
	for i: int in 5:
		var linea := MeshInstance3D.new()
		var caja := BoxMesh.new()
		caja.size = Vector3(0.12, 0.01, 5.0)
		linea.mesh = caja
		linea.position = Vector3(-18.0 + i * 6.0, 0.015, 26.0)
		linea.material_override = _material(Color("c9c6b8"))
		add_child(linea)
	_carro(Vector3(-21, 0, 25), Color("3f5a73"))
	_carro(Vector3(-9, 0, 25), Color("6d6f73"))


func _carro(pos: Vector3, color: Color) -> void:
	_caja_solida(Vector3(2.0, 1.0, 4.4), pos + Vector3(0, 0.6, 0), color)
	_caja_mat(Vector3(1.8, 0.6, 2.2), pos + Vector3(0, 1.4, 0), _material(color.darkened(0.45)), false)


func _luces() -> void:
	for l: Array in LUCES:
		var luz := OmniLight3D.new()
		luz.position = Vector3(l[0], 3.3, l[1])
		luz.light_color = Color("ffe6c4")
		luz.light_energy = 2.2
		luz.omni_range = 16.0
		luz.omni_attenuation = 0.8
		luz.shadow_enabled = true
		add_child(luz)
	for p: Vector2 in [Vector2(0, 15), Vector2(-14, 26), Vector2(14, 26)]:
		var farol := OmniLight3D.new()
		farol.position = Vector3(p.x, 6.0, p.y)
		farol.light_color = Color("ffbf7a")
		farol.light_energy = 1.1
		farol.omni_range = 16.0
		add_child(farol)


func _ambiente() -> void:
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color("0b0e16")
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color("6c7890")
	entorno.ambient_light_energy = 0.4
	entorno.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var mundo := WorldEnvironment.new()
	mundo.environment = entorno
	add_child(mundo)
