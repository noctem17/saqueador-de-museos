class_name MapaMuseoNacional
extends Mapa
## Primer piso del Museo Nacional de Colombia, reducido para el juego.
## El edificio fue la Penitenciaría Central de Cundinamarca (el Panóptico): una cruz
## con un centro desde el que se vigilan los brazos. El mapa conserva esa idea; las
## medidas son más pequeñas que las reales y la ubicación de cada sala es inventada.
## Los nombres de las salas son los oficiales (museonacional.gov.co).
##
##          z-30 ┌────────┬───────────┬────────┐
##               │ PATIO  │  BRAZO N  │ PATIO  │  Norte: sala 4 y, al fondo, la
##               │ NO     │  sala 4   │ NE     │  exposición temporal del Urrutia.
##           z-6 ├────────┴─┐ ┌─────┐ ┌┴────────┤
##               │ BRAZO O   CENTRO   BRAZO E   │  Oeste: salas 2 y 3. Este: sala 6.
##            z6 ├────────┬─┘ └──┬──┘ └┬────────┤
##               │ PATIO  │VESTÍBULO│  PATIO   │  Patio suroeste: la fuente.
##           z18 ├────────┴─┬──────┬┴──────────┤
##               │  SALA 1  │ HALL │  SALA 5   │
##           z30 └──────────┴──┬───┴───────────┘  Fachada de piedra.
##                    JARDINES · CALLE (camioneta)
##
## x crece hacia el este y z hacia el sur (hacia la calle). Medidas en metros.

const ALTO: float = 4.5          # Salas.
const ALTO_CENTRO: float = 7.0   # El centro del panóptico es más alto.
const ALTO_PIEDRA: float = 6.5   # Muros de piedra que dan a los patios.

const PIEDRA := Color("a3825d")
const PIEDRA_OSCURA := Color("7d6347")
const ESTUCO := Color("e7e1d6")
const MADERA := Color("6b4a30")

## Muros de piedra. [fijo, inicio, fin, [puertas], alto]
const PIEDRA_H: Array = [
	[-30.0, -30.0, 30.0, [], ALTO_PIEDRA],
	[-6.0, -30.0, -8.0, [-20.25], ALTO_PIEDRA],
	[-6.0, 8.0, 30.0, [20.25], ALTO_PIEDRA],
	[6.0, -30.0, -8.0, [-13.25], ALTO_PIEDRA],
	[6.0, 8.0, 30.0, [13.25], ALTO_PIEDRA],
	[18.0, -30.0, -8.0, [-20.0], ALTO_PIEDRA],
	[18.0, 8.0, 30.0, [20.0], ALTO_PIEDRA],
	[30.0, -30.0, 30.0, [0.0], 7.5],
]
const PIEDRA_V: Array = [
	[-30.0, -30.0, 30.0, [], ALTO_PIEDRA],
	[30.0, -30.0, 30.0, [], ALTO_PIEDRA],
	[-6.0, -30.0, -8.0, [-20.25], ALTO_PIEDRA],
	[6.0, -30.0, -8.0, [-13.25], ALTO_PIEDRA],
	[-6.0, 8.0, 17.7, [], ALTO_PIEDRA],
	[6.0, 8.0, 17.7, [], ALTO_PIEDRA],
]
## Muros interiores de estuco blanco. [fijo, inicio, fin, [puertas]]
const ESTUCO_H: Array = [
	[18.0, -8.0, 8.0, [0.0]],        # Hall → vestíbulo.
	[-18.5, -3.0, 3.0, [0.0]],       # Sala 4 → exposición temporal.
	[23.0, 23.0, 29.7, []],          # Cuarto de vigilancia.
]
const ESTUCO_V: Array = [
	[-8.0, 18.0, 29.7, [24.0]],      # Hall → sala 1.
	[8.0, 18.0, 29.7, [24.0]],       # Hall → sala 5.
	[-18.5, -3.0, 3.0, [0.0]],       # Sala 2 → sala 3.
	[23.0, 18.0, 23.0, [20.5]],      # Puerta del cuarto de vigilancia.
]
## Los cuatro lados en diagonal del octágono central.
const DIAGONALES: Array = [
	[Vector2(6, -8), Vector2(8, -6)], [Vector2(8, 6), Vector2(6, 8)],
	[Vector2(-6, 8), Vector2(-8, 6)], [Vector2(-8, -6), Vector2(-6, -8)],
]
## Divisiones entre las antiguas celdas, a lo largo de cada brazo.
const CELDAS: Array[float] = [11.5, 15.0, 18.5, 22.0, 25.5]

const SLOTS_PARED: Array = [
	# Brazo norte: sala 4 y exposición temporal.
	[-5.79, -9.75, 90.0], [-5.79, -13.25, 90.0], [-5.79, -16.75, 90.0], [-5.79, -23.75, 90.0], [-5.79, -27.75, 90.0],
	[5.79, -9.75, -90.0], [5.79, -16.75, -90.0], [5.79, -20.25, -90.0], [5.79, -23.75, -90.0], [5.79, -27.75, -90.0],
	# Brazo oeste: salas 2 y 3.
	[-9.75, -5.79, 0.0], [-13.25, -5.79, 0.0], [-16.75, -5.79, 0.0], [-23.75, -5.79, 0.0], [-27.75, -5.79, 0.0],
	[-9.75, 5.79, 180.0], [-16.75, 5.79, 180.0], [-20.25, 5.79, 180.0], [-27.75, 5.79, 180.0],
	# Vestíbulo.
	[-5.79, 11.0, 90.0], [-5.79, 15.0, 90.0], [5.79, 11.0, -90.0], [5.79, 15.0, -90.0],
	# Hall y salas 1 y 5, contra la fachada.
	[-5.0, 29.79, 180.0], [5.0, 29.79, 180.0], [-26.0, 29.79, 180.0], [-13.0, 29.79, 180.0], [12.0, 29.79, 180.0],
	# Panel suelto de la sala 1.
	[-19.0, 23.79, 180.0], [-19.0, 24.21, 0.0],
]
const SLOTS_PEDESTAL: Array = [
	[0.0, -14.0], [0.0, -26.0], [-14.5, 0.0], [-24.0, 0.0],
	[16.75, -4.5], [23.75, 4.5], [27.75, -4.5], [9.75, 4.5], [11.0, 20.5],
]
const SLOTS_COLECCIONABLE: Array = [
	[-1.8, 1.11, 21.5], [1.9, 1.11, 21.6],        # Taquilla del hall.
	[14.0, 0.73, 23.5], [18.0, 1.43, 26.5],       # Estantes de la reserva visible.
	[-14.0, 0.47, 15.0], [-12.0, 0.47, -20.0],    # Bancas de los patios.
	[0.8, 1.11, 0.0],                             # Mesa del centro.
	[13.25, 0.92, -5.3], [-23.75, 0.92, 5.3],     # Dentro de vitrinas.
	[-24.0, 0.91, 21.0],                          # Caja de embalaje en la sala 1.
	[-5.15, 0.01, -29.15], [7.3, 0.01, 29.15],    # Rincones.
	[25.8, 0.81, 18.8],                           # Escritorio de vigilancia.
]
## Vitrinas de pared con piezas decorativas: [x, z de la pared donde se apoyan].
const VITRINAS: Array = [
	[9.75, -6.0], [13.25, -6.0], [16.75, 6.0], [20.25, 6.0], [27.75, 6.0],   # Sala 6, oro.
	[-23.75, 6.0],                                                          # Sala 3.
]
const BANCAS: Array = [
	[-14.0, 15.0, 0.0], [-22.0, 15.0, 0.0], [-12.0, -20.0, 90.0],
	[14.0, -18.0, 90.0], [18.0, 15.0, 0.0], [-4.5, 27.5, 0.0],
]
const ARBOLES: Array = [
	[-26.5, 9.5], [-10.0, 15.5], [-24.0, -24.0], [-12.0, -13.0], [-25.0, -11.0],
	[24.0, -24.0], [12.0, -24.0], [24.0, -12.0], [26.0, 9.5], [10.5, 15.0],
	[-20.0, 34.5], [20.0, 34.5], [-15.0, 42.0], [15.0, 42.0],
]
const CAMARAS: Array = [
	[7.3, 3.9, 29.3, 45.0],      # Hall.
	[6.5, 4.2, 6.5, 45.0],       # Centro del panóptico.
	[-2.4, 3.9, -29.3, 180.0],   # Fondo del brazo norte.
	[29.3, 3.9, 2.4, 90.0],      # Fondo de la sala 6.
	[-29.3, 3.9, -2.4, -90.0],   # Fondo de la sala 3.
	[-5.3, 3.9, 17.3, -45.0],    # Vestíbulo.
]
const PATRULLAS: Array = [
	[[3.0, 3.0], [3.0, -3.0], [-3.0, -3.0], [-3.0, 3.0]],                               # Centro: mira hacia todos los brazos.
	[[2.0, -10.0], [2.0, -28.0], [-2.0, -28.0], [-2.0, -10.0]],                         # Brazo norte.
	[[0.0, 26.0], [-20.0, 21.0], [-26.0, 27.0], [0.0, 26.0], [0.0, 12.0]],              # Hall, sala 1 y vestíbulo.
	[[12.0, 0.0], [27.0, 0.0], [20.25, -9.0], [20.0, -20.0], [20.25, -9.0]],           # Sala 6 y patio noreste.
	[[-11.0, 0.0], [-28.5, 0.0], [-20.25, -9.0], [-20.0, -22.0], [-20.25, -9.0]],      # Salas 2 y 3 y patio noroeste.
]


func _init() -> void:
	slots_pared = SLOTS_PARED
	slots_pedestal = SLOTS_PEDESTAL
	slots_coleccionable = SLOTS_COLECCIONABLE
	camaras = CAMARAS
	patrullas = PATRULLAS
	spawn_polo = Vector3(0, 0.1, 44.0)
	spawn_mostro = Vector3(-2.0, 0.1, 40.0)
	spawn_policia = [Vector3(-14, 0.1, 45), Vector3(14, 0.1, 45), Vector3(-20, 0.1, -25)]
	pos_terminal = Vector3(26.5, 1.05, 18.7)
	pos_camioneta = Vector3(6.0, 0.0, 53.5)
	giro_camioneta = -90.0
	fin_huida = Vector3(-110.0, 0.0, 53.5)
	plano_huida = Vector3(-14.0, 1.6, 50.5)
	punto_prueba = Vector3(-3, 0.1, 2)
	punto_lejano = Vector3(-20, 0, -22)


func construir() -> void:
	caja_mat(Vector3(100, 1, 100), Vector3(0, -0.5, 15), null, true)
	_suelos()
	_muros()
	_techos()
	_salas()
	_patios()
	_exterior()
	_luces()
	_letreros()
	ambiente(Color("070a12"), Color("56627a"), 0.35)
	hornear_navegacion()


func _suelos() -> void:
	suelo(-8.0, -8.0, 8.0, 8.0, Color("9a958c"))                  # Centro.
	suelo(-6.0, -30.0, 6.0, -18.5, Color("5e4330"))               # Exposición temporal.
	suelo(-6.0, -18.5, 6.0, -8.0, MADERA)                         # Sala 4.
	suelo(-30.0, -6.0, -8.0, 6.0, Color("735033"))                # Salas 2 y 3.
	suelo(8.0, -6.0, 30.0, 6.0, Color("3a3430"))                  # Sala 6, más oscura.
	suelo(-6.0, 8.0, 6.0, 18.0, Color("8d8a84"))                  # Vestíbulo.
	suelo(-8.0, 18.0, 8.0, 30.0, Color("a39d92"))                 # Hall.
	suelo(-30.0, 18.0, -8.0, 30.0, Color("6e4d33"))               # Sala 1.
	suelo(8.0, 18.0, 30.0, 30.0, Color("4c4a48"))                 # Sala 5.


func _muros() -> void:
	var piedra: StandardMaterial3D = material(PIEDRA, 0.95)
	var estuco: StandardMaterial3D = material(ESTUCO)
	for m: Array in PIEDRA_H:
		muro(true, m[0], m[1], m[2], m[3], m[4], piedra, false)
	for m: Array in PIEDRA_V:
		muro(false, m[0], m[1], m[2], m[3], m[4], piedra, false)
	for m: Array in ESTUCO_H:
		muro(true, m[0], m[1], m[2], m[3], ALTO, estuco, true)
	for m: Array in ESTUCO_V:
		muro(false, m[0], m[1], m[2], m[3], ALTO, estuco, true)
	for d: Array in DIAGONALES:
		muro_diagonal(d[0], d[1], ALTO_CENTRO, piedra)
	# Encima de la entrada a cada brazo, el muro sube hasta el techo del centro.
	var resto: float = ALTO_CENTRO - ALTO
	var y: float = ALTO + resto * 0.5
	for z: float in [-8.0, 8.0]:
		caja_mat(Vector3(12.3, resto, GROSOR), Vector3(0, y, z), estuco, false)
	for x: float in [-8.0, 8.0]:
		caja_mat(Vector3(GROSOR, resto, 12.3), Vector3(x, y, 0), estuco, false)

	# Celdas: tabiques blancos a cada lado de los brazos y una viga encima, como arcadas.
	for d: float in CELDAS:
		for lado: float in [-4.5, 4.5]:
			caja_mat(Vector3(3.0, ALTO, GROSOR), Vector3(lado, ALTO * 0.5, -d), estuco, true)
			caja_mat(Vector3(GROSOR, ALTO, 3.0), Vector3(-d, ALTO * 0.5, lado), estuco, true)
			caja_mat(Vector3(GROSOR, ALTO, 3.0), Vector3(d, ALTO * 0.5, lado), estuco, true)
	for lado: float in [-3.0, 3.0]:
		caja_mat(Vector3(GROSOR, 0.9, 22.0), Vector3(lado, 4.05, -19.0), estuco, false)
		caja_mat(Vector3(22.0, 0.9, GROSOR), Vector3(-19.0, 4.05, lado), estuco, false)
		caja_mat(Vector3(22.0, 0.9, GROSOR), Vector3(19.0, 4.05, lado), estuco, false)


func _techos() -> void:
	var gris := Color("cdc7bc")
	techo(-6.0, -30.0, 6.0, -8.0, ALTO, gris)
	techo(-30.0, -6.0, -8.0, 6.0, ALTO, gris)
	techo(8.0, -6.0, 30.0, 6.0, ALTO, Color("2a2622"))
	techo(-6.0, 8.0, 6.0, 18.0, ALTO, gris)
	techo(-30.0, 18.0, 30.0, 30.0, ALTO, gris)
	techo(-8.0, -8.0, 8.0, 8.0, ALTO_CENTRO, gris)
	# Claraboya del centro: entra la luz de la luna.
	var vidrio := StandardMaterial3D.new()
	vidrio.albedo_color = Color("9fb6d6")
	vidrio.emission_enabled = true
	vidrio.emission = Color("6f8fbf")
	vidrio.emission_energy_multiplier = 0.8
	var claraboya := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = 2.4
	disco.bottom_radius = 2.4
	disco.height = 0.05
	disco.radial_segments = 8
	claraboya.mesh = disco
	claraboya.position = Vector3(0, ALTO_CENTRO - 0.03, 0)
	claraboya.material_override = vidrio
	add_child(claraboya)


func _salas() -> void:
	for slot: Array in SLOTS_PEDESTAL:
		caja(Vector3(0.9, 1.0, 0.9), Vector3(slot[0], 0.5, slot[1]), Color("efeae0"))
	# Centro: mesa redonda del vigilante, desde donde se ven los brazos.
	cilindro(1.2, 1.1, Vector3.ZERO, Color("4a3524"), 16)

	# Vestíbulo "Historia del Panóptico": pantallas táctiles.
	var pantalla := StandardMaterial3D.new()
	pantalla.albedo_color = Color("0e2233")
	pantalla.emission_enabled = true
	pantalla.emission = Color("4fb3e0")
	pantalla.emission_energy_multiplier = 1.0
	for lado: float in [-1.0, 1.0]:
		caja(Vector3(0.4, 1.4, 0.7), Vector3(5.55 * lado, 0.7, 13.0), Color("2a2c30"))
		caja_mat(Vector3(0.04, 0.5, 0.6), Vector3(5.33 * lado, 1.15, 13.0), pantalla, false)

	# Hall: taquilla, buena cobertura al agacharse.
	caja(Vector3(5.0, 1.1, 0.8), Vector3(0, 0.55, 21.5), Color("4a3524"))

	# Sala 1, cerrada por montaje: cajas, andamio y lienzos tapados.
	var embalaje := Color("8a6c48")
	caja(Vector3(1.2, 0.9, 1.0), Vector3(-24.0, 0.45, 21.0), embalaje)
	caja(Vector3(0.9, 0.7, 0.9), Vector3(-25.6, 0.35, 22.6), embalaje)
	caja(Vector3(1.4, 1.0, 1.0), Vector3(-12.0, 0.5, 27.0), embalaje)
	caja(Vector3(0.08, 1.3, 1.7), Vector3(-29.75, 0.65, 24.0), Color("d8d2c6"))
	caja(Vector3(0.08, 1.1, 1.4), Vector3(-29.75, 0.55, 26.2), Color("cfc8ba"))
	caja(Vector3(6.0, 3.0, GROSOR), Vector3(-19.0, 1.5, 24.0), ESTUCO)
	for px: float in [-21.2, -18.8]:
		for pz: float in [28.0, 29.2]:
			caja(Vector3(0.08, 2.6, 0.08), Vector3(px, 1.3, pz), Color("6f7377"))
	caja(Vector3(2.6, 0.06, 1.4), Vector3(-20.0, 2.0, 28.6), Color("8a7a5c"), false)

	# Sala 5, talleres y reserva visible: estanterías.
	var estante := Color("5a4632")
	for x: float in [14.0, 18.0]:
		for z: float in [21.0, 24.5, 28.0]:
			caja(Vector3(0.6, 2.2, 0.08), Vector3(x, 1.1, z), estante)
		for y: float in [0.7, 1.4, 2.1]:
			caja(Vector3(0.6, 0.05, 7.0), Vector3(x, y, 24.5), estante)
		caja(Vector3(0.45, 0.35, 0.6), Vector3(x, 0.9, 21.8), Color("9a8466"), false)
		caja(Vector3(0.4, 0.3, 0.5), Vector3(x, 1.6, 27.0), Color("b5a58a"), false)
	# Cuarto de vigilancia: la consola que apaga las cámaras.
	caja(Vector3(2.0, 0.8, 0.8), Vector3(26.5, 0.4, 18.8), Color("23262b"))

	# Vitrinas de pared con piezas de oro (sala 6) y de piedra (salas 2 y 3).
	var oro := StandardMaterial3D.new()
	oro.albedo_color = Color("d9a521")
	oro.metallic = 0.9
	oro.roughness = 0.25
	oro.emission_enabled = true
	oro.emission = Color("5a3d08")
	var vidrio := StandardMaterial3D.new()
	vidrio.albedo_color = Color(0.8, 0.9, 1.0, 0.12)
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidrio.roughness = 0.05
	for v: Array in VITRINAS:
		var x: float = v[0]
		var lado: float = signf(v[1])
		var z_base: float = (6.0 - 0.55) * lado
		caja(Vector3(2.4, 0.9, 0.8), Vector3(x, 0.45, z_base), Color("2b2622"))
		caja_mat(Vector3(2.4, 0.7, 0.8), Vector3(x, 1.25, z_base), vidrio, false)
		var pieza: Material = oro if x > 0.0 else material(Color("8a7a66"))
		for i: int in 3:
			esfera(0.07 + 0.02 * i, Vector3(x - 0.7 + 0.7 * i, 1.0, z_base + 0.1 * lado), pieza)


func _patios() -> void:
	var grava := Color("6f675b")
	var pasto := Color("34502a")
	for p: Array in [[-30.0, -30.0, -6.0, -6.0], [6.0, -30.0, 30.0, -6.0], [-30.0, 6.0, -6.0, 18.0], [6.0, 6.0, 30.0, 18.0]]:
		suelo(p[0], p[1], p[2], p[3], grava, 0.003)
		suelo(p[0] + 2.0, p[1] + 2.0, p[2] - 2.0, p[3] - 2.0, pasto, 0.007)
	for b: Array in BANCAS:
		banca(b[0], b[1], b[2])
	for a: Array in ARBOLES:
		_arbol(a[0], a[1])
	# Fuente del patio suroeste.
	var centro := Vector3(-18.0, 0.0, 12.0)
	cilindro(2.2, 0.6, centro, Color("4b4136"), 8)
	cilindro(1.95, 0.02, centro + Vector3.UP * 0.6, Color("2c4a55"), 8, false)
	var fuente := Color("4b4136")
	cilindro(0.2, 1.3, centro + Vector3.UP * 0.6, fuente, 8, false, 0.32)
	cilindro(1.05, 0.45, centro + Vector3.UP * 1.75, fuente, 10, false, 0.3)
	cilindro(0.95, 0.02, centro + Vector3.UP * 2.19, Color("2c4a55"), 10, false)
	cilindro(0.12, 0.55, centro + Vector3.UP * 2.2, fuente, 8, false, 0.16)
	cilindro(0.5, 0.25, centro + Vector3.UP * 2.7, fuente, 10, false, 0.15)
	# Ventanas en arco con rejas en los muros que dan a los patios, como las celdas.
	var hueco := material(Color("15120f"))
	var reja := material(Color("2e2b28"))
	for d: float in [9.75, 13.25, 16.75, 20.25, 23.75, 27.75]:
		for lado: float in [-1.0, 1.0]:
			_ventana(Vector3(6.17 * lado, 3.4, -d), 90.0, hueco, reja)
			_ventana(Vector3(-d, 3.4, 6.17 * lado), 0.0, hueco, reja)
			_ventana(Vector3(d, 3.4, 6.17 * lado), 0.0, hueco, reja)


func _ventana(pos: Vector3, giro: float, hueco: Material, reja: Material) -> void:
	var g: float = deg_to_rad(giro)
	caja_mat(Vector3(1.0, 1.3, 0.04), pos, hueco, false, g)
	var arco := MeshInstance3D.new()
	var media := CylinderMesh.new()
	media.top_radius = 0.5
	media.bottom_radius = 0.5
	media.height = 0.04
	media.radial_segments = 10
	arco.mesh = media
	arco.position = pos + Vector3.UP * 0.65
	arco.rotation = Vector3(PI * 0.5, g, 0)
	arco.material_override = hueco
	add_child(arco)
	var a_lo_largo := Vector3(cos(g), 0, -sin(g))
	for i: int in 3:
		caja_mat(Vector3(0.04, 1.6, 0.06), pos + a_lo_largo * (-0.3 + 0.3 * i) + Vector3.UP * 0.15, reja, false, g)


func _arbol(x: float, z: float) -> void:
	cilindro(0.25, 4.2, Vector3(x, 0, z), Color("4a3a2a"), 8)
	var copa := material(Color("2f4a26"))
	esfera(2.0, Vector3(x, 4.8, z), copa)
	esfera(1.4, Vector3(x + 0.9, 4.2, z + 0.5), copa)


func _exterior() -> void:
	# Fachada: pilastras de piedra, marco de la puerta y letreros.
	for x: float in [-27.0, -21.0, -15.0, -9.0, 9.0, 15.0, 21.0, 27.0]:
		caja(Vector3(0.7, 7.5, 0.5), Vector3(x, 3.75, 30.4), PIEDRA_OSCURA)
	for x: float in [-1.45, 1.45]:
		caja(Vector3(0.5, 3.1, 0.5), Vector3(x, 1.55, 30.35), PIEDRA_OSCURA)
	caja(Vector3(3.4, 0.5, 0.5), Vector3(0, 3.0, 30.35), PIEDRA_OSCURA)
	caja(Vector3(2.0, 3.6, 0.05), Vector3(-5.0, 4.6, 30.18), Color("8c1d1d"), false)

	# Jardines escalonados de la entrada (reducidos y planos) y la calle.
	suelo(-40.0, 30.0, 40.0, 47.0, Color("a89a7e"))
	for j: Array in [[-28.0, 33.0, -9.0, 36.0], [9.0, 33.0, 28.0, 36.0], [-28.0, 40.0, -9.0, 44.0], [9.0, 40.0, 28.0, 44.0]]:
		var ancho: float = j[2] - j[0]
		var fondo: float = j[3] - j[1]
		var c := Vector3((j[0] + j[2]) * 0.5, 0.0, (j[1] + j[3]) * 0.5)
		caja(Vector3(ancho, 0.45, fondo), c + Vector3.UP * 0.225, Color("8e8068"))
		caja(Vector3(ancho - 0.3, 0.02, fondo - 0.3), c + Vector3.UP * 0.46, Color("3c5a2c"), false)
	for x0: float in [-40.0, 4.0]:
		caja(Vector3(36.0, 0.6, 0.4), Vector3(x0 + 18.0, 0.3, 47.0), PIEDRA_OSCURA)
	suelo(-130.0, 47.0, 40.0, 49.0, Color("6d6a66"))
	suelo(-130.0, 49.0, 40.0, 58.0, Color("232427"))
	for i: int in 14:
		caja(Vector3(3.0, 0.01, 0.15), Vector3(-120.0 + i * 11.0, 0.012, 53.5 + 0.0), Color("c9c6b8"), false)
	carro(Vector3(-18.0, 0.0, 51.0), Color("6d6f73"), 90.0)
	# Límites invisibles para que nadie se salga del mapa.
	caja_mat(Vector3(0.4, 6, 30), Vector3(-40, 3, 45), null, true)
	caja_mat(Vector3(0.4, 6, 30), Vector3(40, 3, 45), null, true)
	caja_mat(Vector3(80, 6, 0.4), Vector3(0, 3, 60), null, true)
	for x: float in [-35.0, 35.0]:
		caja_mat(Vector3(10, 6, 0.4), Vector3(x, 3, 30.2), null, true)
	# Faroles.
	for p: Vector2 in [Vector2(-6, 33), Vector2(6, 33), Vector2(-6, 45.5), Vector2(6, 45.5), Vector2(-14, 48.5), Vector2(16, 48.5)]:
		cilindro(0.08, 3.6, Vector3(p.x, 0, p.y), Color("1c1c1e"), 6)
		esfera(0.22, Vector3(p.x, 3.7, p.y), _material_farol())
		luz(Vector3(p.x, 3.6, p.y), 1.3, 13.0, false, Color("ffbf7a"), false)


var _farol: StandardMaterial3D


func _material_farol() -> StandardMaterial3D:
	if _farol == null:
		_farol = StandardMaterial3D.new()
		_farol.albedo_color = Color("ffe2b0")
		_farol.emission_enabled = true
		_farol.emission = Color("ffbf7a")
		_farol.emission_energy_multiplier = 2.5
	return _farol


func _luces() -> void:
	var calida := Color("ffe6c4")
	var oro := Color("ffc77a")
	luz(Vector3(0, 6.2, 0), 3.0, 16.0, true)
	luz(Vector3(0, 4.0, -12.0), 2.0, 12.0, true)
	luz(Vector3(0, 4.0, -23.0), 2.0, 12.0, true)
	luz(Vector3(0, 4.0, -28.0), 1.4, 8.0, false)
	luz(Vector3(-13.0, 4.0, 0), 2.0, 12.0, true)
	luz(Vector3(-24.0, 4.0, 0), 1.8, 12.0, false)
	luz(Vector3(13.0, 4.0, 0), 1.3, 11.0, true, oro)
	luz(Vector3(24.0, 4.0, 0), 1.3, 11.0, false, oro)
	luz(Vector3(0, 4.0, 13.0), 2.0, 12.0, true, calida)
	luz(Vector3(0, 4.0, 24.0), 2.2, 14.0, true, calida)
	luz(Vector3(-19.0, 4.0, 24.0), 1.4, 14.0, false, calida)
	luz(Vector3(19.0, 4.0, 23.0), 1.8, 14.0, true, calida)
	luz(Vector3(26.5, 4.0, 20.5), 1.4, 7.0, false, Color("cfe6ff"))
	# Patios: un farol por patio y la luna.
	for p: Vector2 in [Vector2(-18, -18), Vector2(18, -18), Vector2(-24, 12), Vector2(18, 12)]:
		luz(Vector3(p.x, 3.5, p.y), 1.0, 12.0, false, Color("ffbf7a"), false)
	var luna := DirectionalLight3D.new()
	luna.rotation_degrees = Vector3(-40, 30, 0)
	luna.light_color = Color("9fb3d9")
	luna.light_energy = 0.3
	luna.shadow_enabled = true
	add_child(luna)


func _letreros() -> void:
	letrero("SALA 4 · MEMORIA EN MOVIMIENTO", Vector3(0, 5.6, -7.8), 0.0)
	letrero("EXPOSICIÓN TEMPORAL\nMUSEO DE ARTE MIGUEL URRUTIA · EN PRÉSTAMO", Vector3(0, 3.5, -18.3), 0.0, 48)
	letrero("SALA 6 · BRILLANTE AMANECER\nLA METALURGIA DEL ORO EN EL MUNDO INDÍGENA", Vector3(7.8, 5.6, 0), -90.0, 48)
	letrero("SALA 2 · TIERRA DE HISTORIAS", Vector3(-7.8, 5.6, 0), 90.0)
	letrero("SALA 3 · TIEMPO SIN OLVIDO\nDIÁLOGOS DESDE EL MUNDO PREHISPÁNICO", Vector3(-18.3, 3.5, 0), 90.0, 48)
	letrero("VESTÍBULO · HISTORIA DEL PANÓPTICO", Vector3(0, 5.6, 7.8), 180.0)
	letrero("VESTÍBULO · HISTORIA DEL PANÓPTICO", Vector3(0, 3.5, 18.2), 0.0, 48)
	letrero("SALA 1 · LA HISTORIA DEL MUSEO Y EL MUSEO EN LA HISTORIA\nCERRADA POR MONTAJE", Vector3(-7.8, 3.4, 24.0), 90.0, 40)
	letrero("SALA 5 · TALLERES DEL PANÓPTICO Y RESERVA VISIBLE", Vector3(7.8, 3.4, 24.0), -90.0, 40)
	letrero("VIGILANCIA", Vector3(22.8, 3.0, 20.5), -90.0, 40)
	letrero("MUSEO NACIONAL", Vector3(0, 4.6, 30.5), 0.0, 120, Color("efe6d2"))
	letrero("EN PRÉSTAMO\n\nColección de arte del\nBanco de la República\n\nMuseo de Arte\nMiguel Urrutia", Vector3(-5.0, 4.6, 30.22), 0.0, 36, Color("f3ead8"))
