class_name MapaMuseoNacional
extends Mapa
## Museo Nacional de Colombia, antigua Penitenciaría Central de Cundinamarca (el
## Panóptico). Tres pisos, planta en cruz y muralla de fortaleza, armados a partir
## de los planos isométricos del museo y de fotos. Las medidas son aproximadas y
## la ubicación de cada sala dentro de la cruz es una interpretación; los nombres de
## las salas son los oficiales (museonacional.gov.co).
##
##   z-64 ┌────────────────────────── muralla ──────────────────────────┐
##        │   PATIO NOROESTE          BRAZO N            PATIO NORESTE   │
##        │                     (celdas, 3 pisos)                        │
##   z-10 │ BRAZO OESTE ─────────── CENTRO ─────────── BRAZO ESTE        │
##        │                       (pozo de luz)                          │
##    z10 │   PATIO DE LA FUENTE   ESCALERA         PATIO SUR            │
##    z22 │             ┌──────── BLOQUE DE ENTRADA ────────┐            │
##    z37 └─────────────┴──── FACHADA · portada en arco ────┴────────────┘
##          prados, árboles, escalinata y rampas → acera y Carrera Séptima
##
## x crece hacia el este y z hacia el sur (la calle). Medidas en metros.
## Pisos: y = 0, 4.5 y 9; techo a 13.5. La calle está 1.8 m más abajo.

const H: float = 4.5
const PISOS: int = 3
## Los muros de cada piso quedan unos centímetros más bajos que el piso de arriba. Si
## llegaran justo a su altura, la tarjeta no sabría qué dibujar encima y parpadearía.
const HM: float = H - 0.08
const Y_TECHO: float = 13.5
const Y_CALLE: float = -1.8
const LARGO_BRAZO: float = 58.0
const INICIO_BRAZO: float = 10.0
const MEDIO_BRAZO: float = 6.5      # Medio ancho de cada brazo.
const PASILLO: float = 2.5          # Medio ancho del pasillo entre celdas.
const CELDA: float = 3.5
const NUM_CELDAS: int = 13
const CELDAS_ABIERTAS: Array[int] = [1, 3, 5, 7, 9, 11]
const PUERTA_PATIO_S: float = 29.25 # Puertas de los brazos hacia los patios (piso 1).

## Cada brazo con su dirección: u apunta hacia afuera, v es el costado.
const BRAZOS: Array = [
	{"id": "n", "u": Vector3(0, 0, -1), "v": Vector3(1, 0, 0)},
	{"id": "o", "u": Vector3(-1, 0, 0), "v": Vector3(0, 0, -1)},
	{"id": "e", "u": Vector3(1, 0, 0), "v": Vector3(0, 0, 1)},
]
## Nombres oficiales por piso: [cerca del centro, al fondo].
const SALAS: Dictionary = {
	"n": [["Sala 4 · Memoria en movimiento", "Sala 5 · Talleres del Panóptico y reserva visible"],
		["Sala 10 · Ascensión al tepuy", "Sala 11 · Hacer sociedad"],
		["Sala 16 · En renovación", "Sala 16 · En renovación"]],
	"o": [["Sala 2 · Tierra de historias", "Sala 3 · Tiempo sin olvido"],
		["Sala 8 · Orfebrería colonial y republicana", "Sala 9 · Ser territorio (en renovación)"],
		["Sala 15 · Ser y hacer", "Sala 15 · Ser y hacer"]],
	"e": [["Sala 6 · Brillante amanecer", "Sala 6 · Brillante amanecer"],
		["Sala 12 · Gabinete de conexiones", "Sala 13 · Tierra como recurso"],
		["Sala 17 · Fuerza, fe y sustancia", "Sala 17 · Fuerza, fe y sustancia"]],
}
const CENTRO: Array[String] = ["Centro del Panóptico", "Centro del Panóptico", "Sala 14 · La Rotonda"]

var piedra: Material
var piedra_oscura: Material
var estuco: Material
var madera: Material
var baldosa: Material
var adoquin: Material
var ladrillo: Material
var hierro: Material
var teja: Material
var oscuro: Material
var pasto: Material


func _init() -> void:
	alto_piso = H
	spawn_polo = Vector3(2.0, Y_CALLE + 0.1, 53.5)
	spawn_mostro = Vector3(-2.0, 0.1, 40.0)
	spawn_policia = [Vector3(-10, 0.1, 42), Vector3(10, 0.1, 42), Vector3(-40, 0.1, -40)]
	pos_terminal = Vector3(26.0, 1.05, 22.75)
	pos_camioneta = Vector3(8.0, Y_CALLE, 59.0)
	giro_camioneta = -90.0
	fin_huida = Vector3(-170.0, Y_CALLE, 59.0)
	plano_huida = Vector3(-22.0, Y_CALLE + 1.6, 54.5)
	punto_prueba = Vector3(-3, 0.1, 3)
	punto_lejano = Vector3(0, 2 * H, -54)
	_datos()


func construir() -> void:
	piedra = material_bloques(Color("ad8c62"), Color("5f4c38"), Vector2(0.9, 0.42))
	piedra_oscura = material_bloques(Color("8c6f4f"), Color("4a3b2c"), Vector2(1.1, 0.55), 0.14)
	estuco = material(Color("e8e2d6"))
	madera = material_bloques(Color("6b4a30"), Color("43301f"), Vector2(2.2, 0.2), 0.12, 0.012)
	baldosa = material_bloques(Color("a49d90"), Color("6f6a60"), Vector2(0.6, 0.6), 0.08, 0.02)
	adoquin = material_bloques(Color("b3a284"), Color("7f735c"), Vector2(0.5, 0.5), 0.12, 0.02)
	ladrillo = material_bloques(Color("9a5a3c"), Color("5f3a28"), Vector2(0.25, 0.12), 0.15, 0.012)
	hierro = material(Color("1d1b19"), 0.5)
	teja = material_bloques(Color("a4532f"), Color("6e3520"), Vector2(0.4, 0.25), 0.18, 0.02)
	oscuro = material(Color("1d2534"), 0.3)
	pasto = material(Color("3a5a2c"), 0.95)

	capas = 1 | CAPA_EXTERIOR
	_terreno()
	_muralla()
	_fachada()
	capas = 1
	_centro()
	for b: Dictionary in BRAZOS:
		_brazo(b)
	_escalera_principal()
	_bloque_entrada()
	capas = 1 | CAPA_EXTERIOR
	_patios()
	_techos()
	capas = 1
	_luces()
	_letreros()
	ambiente(Color("060912"), Color("4a5266"), 0.2)
	hornear_navegacion(0.25)


# ================================================================ ayudas

## Dentro de la muralla (patios incluidos). La plaza, los jardines y la calle son afuera.
func es_interior(pos: Vector3) -> bool:
	return absf(pos.x) < 64.0 and pos.z > -64.0 and pos.z < 36.6



## Punto del mundo a partir de coordenadas de un brazo: s a lo largo, t de costado.
func _w(b: Dictionary, s: float, t: float, y: float) -> Vector3:
	return (b["u"] as Vector3) * s + (b["v"] as Vector3) * t + Vector3.UP * y


## Giro (en grados, como en los cuadros) que mira hacia una dirección del mundo.
func _giro(dir: Vector3) -> float:
	return rad_to_deg(atan2(dir.x, dir.z))


func _caja_bt(b: Dictionary, s0: float, s1: float, t0: float, t1: float, y0: float, y1: float, mat: Material, solida: bool = true) -> void:
	var p0: Vector3 = _w(b, s0, t0, y0)
	var p1: Vector3 = _w(b, s1, t1, y1)
	var mn := Vector3(minf(p0.x, p1.x), minf(p0.y, p1.y), minf(p0.z, p1.z))
	var mx := Vector3(maxf(p0.x, p1.x), maxf(p0.y, p1.y), maxf(p0.z, p1.z))
	caja_mat(mx - mn, (mn + mx) * 0.5, mat, solida)


## Muro a lo largo del brazo, en el costado t, con puertas en las posiciones s.
func _muro_brazo(b: Dictionary, t: float, puertas_s: Array, y0: float, mat: Material, grosor: float, ancho_p: float = PUERTA, alto_p: float = ALTO_PUERTA, zocalo: bool = false) -> void:
	var u: Vector3 = b["u"]
	var horizontal: bool = absf(u.x) > 0.5
	var signo: float = u.x + u.z
	var lado: Vector3 = (b["v"] as Vector3) * t
	var fijo: float = lado.x + lado.z
	var a: float = minf(INICIO_BRAZO * signo, LARGO_BRAZO * signo)
	var c: float = maxf(INICIO_BRAZO * signo, LARGO_BRAZO * signo)
	var puertas: Array = []
	for s: float in puertas_s:
		puertas.append(s * signo)
	muro(horizontal, fijo, a, c, puertas, HM, mat, zocalo, y0, grosor, ancho_p, alto_p)


## Ventana de celda: hueco oscuro en arco con reja. p es el centro de abajo, sobre
## la cara del muro, y "giro" mira hacia afuera de esa cara.
func _ventana(p: Vector3, giro: float, ancho: float = 0.9, alto: float = 1.45) -> void:
	var g: float = deg_to_rad(giro)
	var recto: float = alto - ancho * 0.5
	caja_mat(Vector3(ancho + 0.05, recto, 0.04), p + Vector3.UP * recto * 0.5, oscuro, false, g)
	malla(_cilindro_malla(ancho * 0.5 + 0.025, ancho * 0.5 + 0.025, 0.04, 10), Transform3D(Basis(Vector3.UP, g) * Basis(Vector3.RIGHT, PI * 0.5), p + Vector3.UP * recto), oscuro)
	reja(p + Basis(Vector3.UP, g) * Vector3(0, 0, 0.03), g, ancho, alto, hierro, 0.15)


func _arbol(x: float, z: float, y: float = 0.0) -> void:
	cilindro(0.28, 4.4, Vector3(x, y, z), Color("4a3a2a"), 7)
	var copa: Material = material(Color("2f4a26"))
	esfera(2.3, Vector3(x, y + 5.2, z), copa)
	esfera(1.6, Vector3(x + 1.1, y + 4.5, z + 0.6), copa)
	esfera(1.5, Vector3(x - 0.9, y + 4.7, z - 0.7), copa)


func _farol(x: float, z: float, y: float = 0.0) -> void:
	cilindro(0.09, 3.8, Vector3(x, y, z), Color("1c1c1e"), 6)
	esfera(0.24, Vector3(x, y + 3.95, z), material_brillante(Color("ffe2b0"), Color("ffbf7a"), 2.5))
	var l := luz(Vector3(x, y + 3.8, z), 1.2, 13.0, false, Color("ffbf7a"), false)
	l.light_cull_mask = CAPA_EXTERIOR


## Garita de vigilancia en una esquina de la muralla.
func _garita(x: float, z: float, y: float) -> void:
	cilindro(1.7, 1.2, Vector3(x, y - 1.2, z), piedra_oscura, 8, false, 0.9)
	cilindro(1.7, 3.0, Vector3(x, y, z), piedra, 8, false)
	cilindro(0.0, 2.8, Vector3(x, y + 3.0, z), teja, 8, false, 2.05)
	esfera(0.22, Vector3(x, y + 5.9, z), piedra_oscura)
	for k: int in 4:
		var a: float = TAU * k / 4.0 + PI * 0.25
		caja_mat(Vector3(0.18, 0.9, 0.06), Vector3(x + cos(a) * 1.68, y + 1.6, z + sin(a) * 1.68), oscuro, false, -a + PI * 0.5)


# ================================================================ exterior

func _terreno() -> void:
	# Suelo alto (museo, prados y plaza) y suelo bajo (acera y calle).
	caja_mat(Vector3(144, 1, 118), Vector3(0, -0.5, -13), null, true)
	caja_mat(Vector3(250, 1, 26), Vector3(-53, Y_CALLE - 0.5, 59), null, true)
	suelo(-64, -64, 64, 36.0, material(Color("5f594f"), 0.95), 0.0)

	# Plaza frente a la portada y prados a los lados.
	suelo(-14, 37.2, 14, 46.0, adoquin, 0.0)
	suelo(-64, 37.2, -14, 38.2, adoquin, 0.0)
	suelo(14, 37.2, 64, 38.2, adoquin, 0.0)
	for lado: float in [-1.0, 1.0]:
		var x0: float = 14.0 * lado
		var x1: float = 64.0 * lado
		var mn: float = minf(x0, x1)
		var mx: float = maxf(x0, x1)
		caja(Vector3(mx - mn, 0.15, 7.6), Vector3((mn + mx) * 0.5, 0.075, 42.1), Color("8e8068"))
		suelo(mn + 0.3, 38.6, mx - 0.3, 45.7, pasto, 0.15)
		# Muro de contención entre los prados y la rampa.
		caja_mat(Vector3(52.0, 2.05, 0.3), Vector3(38.0 * lado, -0.775, 46.15), piedra_oscura, true)
		# Plataforma que une la plaza con la rampa.
		caja_mat(Vector3(4.0, 1.8, 2.0), Vector3(10.0 * lado, -0.9, 47.0), adoquin, true)
		caja_mat(Vector3(0.3, 2.05, 4.0), Vector3(8.15 * lado, -0.775, 48.0), piedra_oscura, true)
		# Rampa larga con baranda, de la plaza a la acera.
		var arriba := Vector3(12.0 * lado, 0.0, 47.15)
		var abajo := Vector3(40.0 * lado, Y_CALLE, 47.15)
		rampa(arriba, abajo, 1.7, adoquin)
		for i: int in 8:
			var xa: float = (12.0 + 3.5 * i) * lado
			var xb: float = (12.0 + 3.5 * (i + 1)) * lado
			var y_top: float = lerpf(0.0, Y_CALLE, 3.5 * i / 28.0) + 0.25
			var alto_m: float = y_top - Y_CALLE
			caja_mat(Vector3(3.5, alto_m, 0.3), Vector3((xa + xb) * 0.5, Y_CALLE + alto_m * 0.5, 48.15), piedra_oscura, true)
			baranda(Vector3(xa, y_top, 48.15), Vector3(xb, y_top, 48.15), hierro, 0.85, 0.2, false)
		caja_mat(Vector3(4.0, 2.05, 0.3), Vector3(10.0 * lado, -0.775, 48.15), piedra_oscura, true)
		# Jardineras de abajo, entre la rampa y la acera.
		for j: int in 3:
			var cx: float = (17.0 + j * 8.5) * lado
			caja(Vector3(6.5, 0.5, 2.6), Vector3(cx, Y_CALLE + 0.25, 50.4), Color("7d705a"))
			caja(Vector3(6.2, 0.4, 2.3), Vector3(cx, Y_CALLE + 0.7, 50.4), Color("35552a"), false)
		# Árboles en los prados y una fila sobre la acera.
		for x: float in [20.0, 31.0, 44.0, 56.0]:
			_arbol(x * lado, 41.5 + (1.5 if int(x) % 2 == 0 else -1.0), 0.15)
		for x: float in [16.0, 34.0, 52.0]:
			_arbol(x * lado, 53.2, Y_CALLE)
	# Escalinata central, de la plaza a la acera.
	escalera(Vector3(0, 0, 46.0), Vector3(0, Y_CALLE, 50.0), 16.0, piedra_oscura)
	# Estatua sobre pedestal en el prado oriental.
	caja(Vector3(1.4, 1.8, 1.4), Vector3(36.0, 1.05, 42.0), Color("8d877c"))
	cilindro(0.32, 1.3, Vector3(36.0, 1.95, 42.0), Color("3b3a36"), 8, false)
	esfera(0.26, Vector3(36.0, 3.45, 42.0), material(Color("3b3a36")))
	for p: Vector2 in [Vector2(-10, 38.6), Vector2(10, 38.6), Vector2(-10, 45.2), Vector2(10, 45.2), Vector2(-30, 45.6), Vector2(30, 45.6)]:
		_farol(p.x, p.y)
	banca(20.0, 39.5, 0.0, 0.15)
	banca(-24.0, 39.5, 0.0, 0.15)

	# Acera y Carrera Séptima.
	suelo(-180, 50.0, 72, 55.0, material(Color("75716b"), 0.9), Y_CALLE)
	suelo(-180, 55.0, 72, 65.0, material(Color("222326"), 0.9), Y_CALLE)
	suelo(-180, 65.0, 72, 67.0, material(Color("75716b"), 0.9), Y_CALLE)
	for i: int in 22:
		caja(Vector3(3.0, 0.01, 0.15), Vector3(-170.0 + i * 11.0, Y_CALLE + 0.012, 60.0), Color("c9c6b8"), false)
	carro(Vector3(-20.0, Y_CALLE, 56.6), Color("6d6f73"), 90.0)
	for x: float in [-26.0, 24.0]:
		_farol(x, 54.6, Y_CALLE)
	# Límites invisibles.
	caja_mat(Vector3(0.4, 10, 140), Vector3(-72, 3, 0), null, true)
	caja_mat(Vector3(0.4, 10, 140), Vector3(72, 3, 0), null, true)
	caja_mat(Vector3(144, 10, 0.4), Vector3(0, 3, 67.5), null, true)
	caja_mat(Vector3(144, 10, 0.4), Vector3(0, 3, -70), null, true)


func _muralla() -> void:
	# Muros laterales y de atrás de la antigua penitenciaría, con garitas en las esquinas.
	muro(false, -64.0, -64.0, 36.0, [], 10.0, piedra, false, 0.0, 1.0)
	muro(false, 64.0, -64.0, 36.0, [], 10.0, piedra, false, 0.0, 1.0)
	muro(true, -64.0, -64.0, 64.0, [], 10.0, piedra, false, 0.0, 1.0)
	for x: float in [-64.0, 64.0]:
		caja_mat(Vector3(1.4, 0.4, 101.0), Vector3(x, 10.2, -14.0), piedra_oscura, false)
	caja_mat(Vector3(129.0, 0.4, 1.4), Vector3(0, 10.2, -64.0), piedra_oscura, false)
	for p: Vector2 in [Vector2(-64, -64), Vector2(64, -64)]:
		_garita(p.x, p.y, 10.4)


func _fachada() -> void:
	var z: float = 36.6
	var cara: float = 37.2
	# Cuerpo central alto y alas más bajas, todo en piedra.
	muro(true, z, -64.0, -30.0, [], 10.0, piedra, false, 0.0, 1.2)
	muro(true, z, 30.0, 64.0, [], 10.0, piedra, false, 0.0, 1.2)
	muro(true, z, -30.0, 30.0, [0.0], 14.0, piedra, false, 0.0, 1.2, 4.6, 7.0)
	# Relleno sobre la puerta para que el hueco quede en arco de medio punto.
	for k: int in 6:
		var ya: float = 4.7 + k * (2.3 / 6.0)
		var h: float = ya + 2.3 / 12.0 - 4.7
		var w: float = sqrt(maxf(2.3 * 2.3 - h * h, 0.0))
		for lado: float in [-1.0, 1.0]:
			caja_mat(Vector3(2.3 - w, 2.3 / 6.0, 1.2), Vector3(lado * (w + 2.3) * 0.5, ya + 2.3 / 12.0, z), piedra, false)
	arco(Vector3(0, 4.7, cara + 0.15), 0.0, 2.3, 0.55, 0.3, piedra_oscura, 13)
	# Portada: pilastras, entablamento y letrero.
	for lado: float in [-1.0, 1.0]:
		caja_mat(Vector3(0.9, 8.6, 0.6), Vector3(lado * 3.4, 4.3, cara + 0.3), piedra_oscura, true)
		reja(Vector3(lado * 3.45, 0.0, cara + 0.68), 0.0, 2.2, 5.0, hierro, 0.14)
	caja_mat(Vector3(8.2, 0.8, 0.8), Vector3(0, 9.0, cara + 0.4), piedra_oscura, false)
	caja_mat(Vector3(8.8, 0.3, 1.0), Vector3(0, 9.55, cara + 0.5), piedra_oscura, false)
	# Contrafuertes: es lo que le da el aire de fortaleza.
	var x: float = -60.0
	while x <= 60.0:
		if absf(x) > 6.5:
			var alto: float = 14.0 if absf(x) < 30.0 else 10.0
			caja_mat(Vector3(1.3, alto - 1.6, 1.1), Vector3(x, (alto - 1.6) * 0.5, cara + 0.55), piedra_oscura, true)
			caja_mat(Vector3(1.0, 1.6, 0.6), Vector3(x, alto - 0.8, cara + 0.3), piedra_oscura, false)
		x += 6.0
	# Ventanucos enrejados en lo alto del cuerpo central, entre contrafuertes.
	for xv: float in [-27.0, -21.0, -15.0, 15.0, 21.0, 27.0]:
		_ventana(Vector3(xv, 10.6, cara + 0.01), 0.0, 0.7, 1.2)
	# Zócalo y cornisa.
	for lado: float in [-1.0, 1.0]:
		caja_mat(Vector3(61.7, 1.2, 0.5), Vector3(lado * 33.15, 0.6, cara + 0.25), piedra_oscura, true)
	caja_mat(Vector3(61.4, 0.5, 1.8), Vector3(0, 13.75, z + 0.3), piedra_oscura, false)
	for lado: float in [-1.0, 1.0]:
		caja_mat(Vector3(34.4, 0.45, 1.8), Vector3(lado * 47.0, 9.8, z + 0.3), piedra_oscura, false)
	# Pendón de la exposición temporal.
	caja_mat(Vector3(2.0, 4.2, 0.05), Vector3(-9.0, 6.6, cara + 0.08), material(Color("8c1d1d")), false)
	for p: Vector2 in [Vector2(-64, z), Vector2(64, z)]:
		_garita(p.x, p.y, 10.4)
	for p: Vector2 in [Vector2(-30, z), Vector2(30, z)]:
		_garita(p.x, p.y, 14.4)


# ================================================================ centro

func _centro() -> void:
	var diagonales: Array = [
		[Vector2(6.5, -10), Vector2(10, -6.5)], [Vector2(10, 6.5), Vector2(6.5, 10)],
		[Vector2(-6.5, 10), Vector2(-10, 6.5)], [Vector2(-10, -6.5), Vector2(-6.5, -10)],
	]
	for f: int in PISOS:
		var y0: float = f * H
		for d: Array in diagonales:
			muro_diagonal(d[0], d[1], HM, piedra, y0, 0.6)
		# Lados hacia los brazos y la escalera, con una abertura amplia.
		muro(true, -10.0, -6.5, 6.5, [0.0], HM, estuco, true, y0, GROSOR, 5.0, 3.6)
		muro(true, 10.0, -6.5, 6.5, [0.0], HM, estuco, true, y0, GROSOR, 5.0, 3.6)
		muro(false, -10.0, -6.5, 6.5, [0.0], HM, estuco, true, y0, GROSOR, 5.0, 3.6)
		muro(false, 10.0, -6.5, 6.5, [0.0], HM, estuco, true, y0, GROSOR, 5.0, 3.6)
		if f == 0:
			suelo(-10, -10, 10, 10, baldosa, 0.02)
		else:
			_losa_octogono(y0, baldosa)
			for lado: Array in [[Vector3(-2.5, y0, -2.5), Vector3(2.5, y0, -2.5)], [Vector3(2.5, y0, -2.5), Vector3(2.5, y0, 2.5)],
					[Vector3(2.5, y0, 2.5), Vector3(-2.5, y0, 2.5)], [Vector3(-2.5, y0, 2.5), Vector3(-2.5, y0, -2.5)]]:
				baranda(lado[0], lado[1], hierro, 1.0, 0.14)
	_losa_octogono(Y_TECHO, estuco)
	# Planta baja: mesa del vigilante bajo el pozo de luz.
	cilindro(2.6, 0.02, Vector3(0, 0.03, 0), Color("6e2a22"), 24, false)
	cilindro(1.4, 1.05, Vector3.ZERO, Color("3d2b1c"), 16)
	# Bancas de la Rotonda (sala 14).
	banca(5.6, 0.0, 90.0, 2 * H)
	banca(-5.6, 0.0, 90.0, 2 * H)


## Entrepiso: el piso de arriba con su material y, debajo, el cielo raso de estuco.
func _entrepiso(x0: float, z0: float, x1: float, z1: float, y: float, mat_piso: Material, huecos: Array = []) -> void:
	losa(x0, z0, x1, z1, y - 0.04, GROSOR - 0.04, estuco, huecos)
	losa(x0, z0, x1, z1, y, 0.04, mat_piso, huecos, false)


## Losa del octágono central con el pozo de luz en el medio.
func _losa_octogono(y: float, mat: Material) -> void:
	if mat != estuco:
		_losa_octogono(y - 0.04, estuco)
	var grosor: float = 0.04 if mat != estuco else GROSOR - 0.04
	var solida: bool = mat == estuco
	losa(-6.5, -10, 6.5, 10, y, grosor, mat, [[-2.5, -2.5, 2.5, 2.5]], solida)
	losa(-10, -6.5, -6.5, 6.5, y, grosor, mat, [], solida)
	losa(6.5, -6.5, 10, 6.5, y, grosor, mat, [], solida)
	for esquina: Array in [[Vector2(10, 6.5), Vector2(6.5, 10)], [Vector2(6.5, -10), Vector2(10, -6.5)],
			[Vector2(-10, -6.5), Vector2(-6.5, -10)], [Vector2(-6.5, 10), Vector2(-10, 6.5)]]:
		var a: Vector2 = esquina[0]
		var b: Vector2 = esquina[1]
		var medio: Vector2 = (a + b) * 0.5
		var hacia_centro: Vector2 = -medio.normalized()
		var c: Vector2 = medio + hacia_centro * 1.24
		var giro: float = -atan2(b.y - a.y, b.x - a.x)
		# Unos milímetros más abajo: esta pieza se monta sobre las otras y no deben coincidir.
		caja_mat(Vector3(a.distance_to(b), grosor, 2.48), Vector3(c.x, y - 0.004 - grosor * 0.5, c.y), mat, solida, giro)


# ================================================================ brazos

func _brazo(b: Dictionary) -> void:
	var id: String = b["id"]
	var u: Vector3 = b["u"]
	for f: int in PISOS:
		var y0: float = f * H
		var puertas_ext: Array = [PUERTA_PATIO_S] if f == 0 else []
		# Muros exteriores de piedra, con sus ventanas enrejadas.
		for t: float in [-MEDIO_BRAZO, MEDIO_BRAZO]:
			_muro_brazo(b, t, puertas_ext, y0, piedra, 0.6)
			for k: int in NUM_CELDAS:
				var c: float = INICIO_BRAZO + CELDA * k + CELDA * 0.5
				if f == 0 and absf(c - PUERTA_PATIO_S) < 1.0:
					continue
				var signo: float = signf(t)
				var fuera: Vector3 = (b["v"] as Vector3) * signo
				var y_v: float = y0 + (1.6 if f == 0 else 1.9)
				_ventana(_w(b, c, t + signo * 0.31, y_v), _giro(fuera))
				if f == 0 or k in CELDAS_ABIERTAS:
					_ventana(_w(b, c, t - signo * 0.31, y_v), _giro(-fuera))
		_caja_bt(b, LARGO_BRAZO - 0.3, LARGO_BRAZO + 0.3, -MEDIO_BRAZO - 0.3, MEDIO_BRAZO + 0.3, y0, y0 + HM, piedra)
		# Piso.
		var p0: Vector3 = _w(b, INICIO_BRAZO, -MEDIO_BRAZO, 0)
		var p1: Vector3 = _w(b, LARGO_BRAZO, MEDIO_BRAZO, 0)
		var x0: float = minf(p0.x, p1.x)
		var x1: float = maxf(p0.x, p1.x)
		var z0: float = minf(p0.z, p1.z)
		var z1: float = maxf(p0.z, p1.z)
		var piso_mat: Material = baldosa if (id == "e" and f == 0) else madera
		if f == 0:
			suelo(x0, z0, x1, z1, piso_mat, 0.02)
		else:
			_entrepiso(x0, z0, x1, z1, y0, piso_mat)
		if f == 0:
			_planta_baja(b)
		else:
			_celdas(b, f)
		# Focos a lo largo del pasillo.
		var s: float = 13.0
		while s < LARGO_BRAZO:
			var energia: float = 3.0 if (id == "e" and f == 0) else 4.6
			var color: Color = Color("ffc77a") if (id == "e" and f == 0) else Color("ffe6c4")
			foco(_w(b, s, 0, y0 + H - 0.35), energia, H + 0.2, 64.0, color)
			s += 7.0
		# Letreros de las salas, mirando hacia el centro.
		var nombres: Array = SALAS[id][f]
		letrero((nombres[0] as String).to_upper(), _w(b, 9.83, 0, y0 + 4.0), _giro(-u), 44)
		if nombres[1] != nombres[0]:
			letrero((nombres[1] as String).to_upper(), _w(b, 34.0, 0, y0 + 3.75), _giro(-u), 40)
		zonas.append(_zona(b, INICIO_BRAZO, 34.0, f, nombres[0]))
		zonas.append(_zona(b, 34.0, LARGO_BRAZO + 0.5, f, nombres[1]))
	# Techo del último piso.
	var q0: Vector3 = _w(b, INICIO_BRAZO, -MEDIO_BRAZO, 0)
	var q1: Vector3 = _w(b, LARGO_BRAZO, MEDIO_BRAZO, 0)
	losa(minf(q0.x, q1.x), minf(q0.z, q1.z), maxf(q0.x, q1.x), maxf(q0.z, q1.z), Y_TECHO, GROSOR, estuco)


func _zona(b: Dictionary, s0: float, s1: float, f: int, nombre: String) -> Array:
	var p0: Vector3 = _w(b, s0, -MEDIO_BRAZO, 0)
	var p1: Vector3 = _w(b, s1, MEDIO_BRAZO, 0)
	return [minf(p0.x, p1.x), minf(p0.z, p1.z), maxf(p0.x, p1.x), maxf(p0.z, p1.z), f, "Piso %d · %s" % [f + 1, nombre]]


## Piso 1 de los brazos: galería con dos filas de pilares, como en el plano.
func _planta_baja(b: Dictionary) -> void:
	var id: String = b["id"]
	for k: int in range(1, NUM_CELDAS + 1):
		var s: float = INICIO_BRAZO + CELDA * k
		for t: float in [-PASILLO, PASILLO]:
			cilindro(0.32, HM, _w(b, s, t, 0), estuco, 8)
	for t: float in [-PASILLO, PASILLO]:
		_caja_bt(b, INICIO_BRAZO, LARGO_BRAZO, t - 0.2, t + 0.2, HM - 0.45, HM, estuco, false)
	if id == "e":
		# Sala 6: vitrinas con piezas de oro, en penumbra.
		var oro := material_brillante(Color("d9a521"), Color("5a3d08"), 1.0)
		for k: int in [0, 2, 4, 6, 8, 10, 12]:
			var c: float = INICIO_BRAZO + CELDA * k + CELDA * 0.5
			for t: float in [-4.5, 4.5]:
				_caja_bt(b, c - 1.0, c + 1.0, t - 0.4, t + 0.4, 0.0, 0.9, material(Color("2b2622")), true)
				_caja_bt(b, c - 1.0, c + 1.0, t - 0.4, t + 0.4, 0.9, 1.6, material_vidrio(), false)
				for i: int in 3:
					esfera(0.07 + 0.02 * i, _w(b, c - 0.6 + 0.6 * i, t, 1.02), oro)
	elif id == "n":
		# Sala 5: estanterías de la reserva visible.
		var estante := Color("5a4632")
		for k: int in [8, 9, 10, 12]:
			var c: float = INICIO_BRAZO + CELDA * k + CELDA * 0.5
			for t: float in [-4.6, 4.6]:
				for ds: float in [-1.4, 1.4]:
					_caja_bt(b, c + ds - 0.04, c + ds + 0.04, t - 0.3, t + 0.3, 0.0, 2.2, material(estante))
				for y: float in [0.7, 1.4, 2.1]:
					_caja_bt(b, c - 1.4, c + 1.4, t - 0.3, t + 0.3, y - 0.025, y + 0.025, material(estante))


## Pisos 2 y 3: las celdas del panóptico a lado y lado del pasillo.
func _celdas(b: Dictionary, f: int) -> void:
	var y0: float = f * H
	var puertas: Array = []
	for k: int in NUM_CELDAS:
		puertas.append(INICIO_BRAZO + CELDA * k + CELDA * 0.5)
	for t: float in [-PASILLO, PASILLO]:
		_muro_brazo(b, t, puertas, y0, estuco, GROSOR, 1.3, 2.5, true)
	for k: int in range(1, NUM_CELDAS + 1):
		var s: float = INICIO_BRAZO + CELDA * k
		for t: Array in [[PASILLO, MEDIO_BRAZO - 0.3], [-(MEDIO_BRAZO - 0.3), -PASILLO]]:
			_caja_bt(b, s - 0.15, s + 0.15, t[0], t[1], y0, y0 + HM, estuco)
	# Puertas en arco con reja: cerradas o abiertas contra la pared.
	for k: int in NUM_CELDAS:
		var c: float = INICIO_BRAZO + CELDA * k + CELDA * 0.5
		for t: float in [-PASILLO, PASILLO]:
			var signo: float = signf(t)
			var hacia_pasillo: Vector3 = -(b["v"] as Vector3) * signo
			var g: float = deg_to_rad(_giro(hacia_pasillo))
			arco(_w(b, c, t, y0 + 2.5 - 0.65), g, 0.65, 0.18, 0.34, estuco, 7)
			if k in CELDAS_ABIERTAS:
				reja(_w(b, c + 1.35, t + signo * 0.22, y0), g, 1.25, 2.5, hierro)
			else:
				reja(_w(b, c, t, y0), g, 1.25, 2.5, hierro)
				caja_mat(Vector3(1.3, 2.5, 0.1), _w(b, c, t, y0 + 1.25), null, true, g)
	# Sala 16, en renovación: andamios y lonas dentro de las celdas abiertas.
	if b["id"] == "n" and f == 2:
		for k: int in [3, 7, 11]:
			var c: float = INICIO_BRAZO + CELDA * k + CELDA * 0.5
			for t: float in [-4.4, 4.4]:
				for ds: float in [-1.2, 1.2]:
					for dt: float in [-0.9, 0.9]:
						_caja_bt(b, c + ds - 0.04, c + ds + 0.04, t + dt - 0.04, t + dt + 0.04, y0, y0 + 2.6, material(Color("6f7377")))
				_caja_bt(b, c - 1.3, c + 1.3, t - 1.0, t + 1.0, y0 + 2.0, y0 + 2.06, material(Color("8a7a5c")), false)


# ================================================================ escalera y entrada

func _escalera_principal() -> void:
	for f: int in PISOS:
		var y0: float = f * H
		# Muros de piedra hacia los patios.
		muro(false, -9.0, 10.0, 22.0, [], HM, piedra, false, y0, 0.6)
		muro(false, 9.0, 10.0, 22.0, [], HM, piedra, false, y0, 0.6)
		muro(true, 10.0, -9.0, -6.5, [], HM, piedra, false, y0, 0.6)
		muro(true, 10.0, 6.5, 9.0, [], HM, piedra, false, y0, 0.6)
		if f == 0:
			suelo(-9, 10, 9, 22, baldosa, 0.02)
		else:
			_entrepiso(-9, 10, 9, 22, y0, baldosa, [[-6, 12.5, 6, 20]])
			baranda(Vector3(-6, y0, 12.5), Vector3(-6, y0, 20), hierro)
			baranda(Vector3(6, y0, 12.5), Vector3(6, y0, 20), hierro)
			baranda(Vector3(-6, y0, 12.5), Vector3(6, y0, 12.5), hierro)
			if f == PISOS - 1:
				baranda(Vector3(-6, y0, 20), Vector3(2, y0, 20), hierro)
			else:
				baranda(Vector3(-2, y0, 20), Vector3(2, y0, 20), hierro)
		zonas.append([-9.0, 10.0, 9.0, 22.0, f, "Piso %d · Escalera principal" % (f + 1)])
		foco(Vector3(-7.5, y0 + H - 0.35, 16.0), 4.0)
		foco(Vector3(7.5, y0 + H - 0.35, 16.0), 4.0)
		if f == PISOS - 1:
			continue
		# Escalera en U: un tramo sube hacia el norte, descansa y el otro vuelve al sur.
		var mitad: float = y0 + H * 0.5
		escalera(Vector3(-4, y0, 20), Vector3(-4, mitad, 15.5), 3.8, piedra_oscura)
		caja_mat(Vector3(12.0, GROSOR, 3.0), Vector3(0, mitad - GROSOR * 0.5, 14.0), estuco, true)
		suelo(-6, 12.5, 6, 15.5, piedra_oscura, mitad)
		escalera(Vector3(4, mitad, 15.5), Vector3(4, y0 + H, 20), 3.8, piedra_oscura)
		for xb: float in [-5.95, -2.05]:
			baranda(Vector3(xb, y0, 20), Vector3(xb, mitad, 15.5), hierro)
		for xb: float in [2.05, 5.95]:
			baranda(Vector3(xb, mitad, 15.5), Vector3(xb, y0 + H, 20), hierro)
		baranda(Vector3(-6, mitad, 12.55), Vector3(6, mitad, 12.55), hierro)
		foco(Vector3(0, y0 + H - 0.35, 14.0), 3.6)
		if f == 0:
			caja_mat(Vector3(12.0, mitad - GROSOR, 3.0), Vector3(0, (mitad - GROSOR) * 0.5, 14.0), estuco, true)
			caja_mat(Vector3(3.8, mitad, 4.5), Vector3(4, mitad * 0.5, 17.75), estuco, true)
	losa(-9, 10, 9, 22, Y_TECHO, GROSOR, estuco)


func _bloque_entrada() -> void:
	for f: int in PISOS:
		var y0: float = f * H
		var puertas_patio: Array = [-20.0] if f == 0 else []
		muro(true, 22.0, -30.0, -9.0, puertas_patio, HM, piedra, false, y0, 0.6)
		muro(true, 22.0, 9.0, 30.0, [20.0] if f == 0 else [], HM, piedra, false, y0, 0.6)
		muro(true, 22.0, -9.0, 9.0, [0.0], HM, piedra, false, y0, 0.6, 6.0 if f == 0 else 3.0, 3.6 if f == 0 else 2.8)
		muro(false, -30.0, 22.0, 36.0, [], HM, piedra, false, y0, 0.6)
		muro(false, 30.0, 22.0, 36.0, [], HM, piedra, false, y0, 0.6)
		if f > 0:
			for xv: float in [-25.0, -15.0, 15.0, 25.0]:
				_ventana(Vector3(xv, y0 + 1.9, 21.69), 180.0)
		if f == 0:
			suelo(-30, 22, 30, 36, baldosa, 0.02)
		else:
			_entrepiso(-30, 22, 30, 36, y0, madera if f == 1 else baldosa)
		for xl: float in [-20.0, 0.0, 20.0]:
			for zl: float in [26.0, 32.0]:
				foco(Vector3(xl, y0 + H - 0.35, zl), 4.4)
	losa(-30, 22, 30, 36, Y_TECHO, GROSOR, estuco)

	# Piso 1: vestíbulo "Historia del Panóptico" con columnas, sala 1 y vigilancia.
	muro(false, -12.0, 22.0, 36.0, [29.0], HM, estuco, true)
	muro(false, 12.0, 22.0, 36.0, [29.0], HM, estuco, true)
	for xc: float in [-5.0, 5.0]:
		for zc: float in [25.0, 28.0, 31.0, 34.0]:
			cilindro(0.35, HM, Vector3(xc, 0, zc), estuco, 10)
	caja(Vector3(0.8, 1.1, 4.0), Vector3(-8.5, 0.55, 30.0), Color("4a3524"))
	var pantalla := material_brillante(Color("0e2233"), Color("4fb3e0"), 1.0)
	for zk: float in [24.0, 27.0]:
		caja(Vector3(0.7, 1.4, 0.4), Vector3(8.8, 0.7, zk), Color("2a2c30"))
		caja_mat(Vector3(0.6, 0.5, 0.04), Vector3(8.8, 1.15, zk + 0.22), pantalla, false)
	zonas.append([-12.0, 22.0, 12.0, 37.2, 0, "Piso 1 · Vestíbulo · Historia del Panóptico"])
	# Sala 1, cerrada por montaje.
	var embalaje := Color("8a6c48")
	caja(Vector3(1.2, 0.9, 1.0), Vector3(-24.0, 0.45, 26.0), embalaje)
	caja(Vector3(0.9, 0.7, 0.9), Vector3(-25.6, 0.35, 27.6), embalaje)
	caja(Vector3(1.4, 1.0, 1.0), Vector3(-17.0, 0.5, 33.0), embalaje)
	for px: float in [-21.2, -18.8]:
		for pz: float in [34.0, 35.2]:
			caja(Vector3(0.08, 2.6, 0.08), Vector3(px, 1.3, pz), Color("6f7377"))
	caja(Vector3(2.6, 0.06, 1.4), Vector3(-20.0, 2.0, 34.6), Color("8a7a5c"), false)
	caja(Vector3(0.08, 1.3, 1.7), Vector3(-29.6, 0.65, 29.0), Color("d8d2c6"))
	zonas.append([-30.0, 22.0, -12.0, 37.2, 0, "Piso 1 · Sala 1 · La historia del museo (cerrada por montaje)"])
	# Taquilla y cuarto de vigilancia con la consola que apaga las cámaras.
	muro(false, 22.0, 22.0, 28.0, [25.0], HM, estuco, true)
	muro(true, 28.0, 22.0, 30.0, [], HM, estuco, true)
	caja(Vector3(2.0, 0.8, 0.8), Vector3(26.0, 0.4, 22.8), Color("23262b"))
	banca(17.0, 34.5, 0.0)
	zonas.append([12.0, 22.0, 30.0, 37.2, 0, "Piso 1 · Taquilla y vigilancia"])

	# Piso 2: sala 7, "Memoria y Nación", con su muro central.
	var y1: float = H
	caja_mat(Vector3(24.0, 3.2, 0.3), Vector3(0, y1 + 1.6, 29.0), estuco, true)
	for i: int in 8:
		var tono: Color = Color.from_hsv(float(i) / 8.0, 0.45, 0.75)
		caja(Vector3(2.8, 0.5, 0.32), Vector3(-10.5 + i * 3.0, y1 + 2.9, 29.0), tono, false)
	banca(20.0, 25.0, 0.0, y1)
	banca(-20.0, 25.0, 0.0, y1)
	zonas.append([-30.0, 22.0, 30.0, 37.2, 1, "Piso 2 · Sala 7 · Memoria y Nación"])

	# Piso 3: exposición temporal del Miguel Urrutia.
	var y2: float = 2 * H
	for xp: float in [-20.0, -8.0, 8.0, 20.0]:
		caja_mat(Vector3(6.0, 3.0, GROSOR), Vector3(xp, y2 + 1.5, 28.0), estuco, true)
	banca(0.0, 32.5, 0.0, y2)
	zonas.append([-30.0, 22.0, 30.0, 37.2, 2, "Piso 3 · Exposición temporal · Museo de Arte Miguel Urrutia"])


# ================================================================ patios

func _patios() -> void:
	# Patio de la fuente (suroeste), como en las fotos: senderos de ladrillo, fuente
	# de varios platos, árboles y una arcada contra el bloque de entrada.
	suelo(-64, 6.5, -9, 22, material(Color("2f4a26"), 0.95), 0.012)
	suelo(-64, 13.0, -30, 15.5, ladrillo, 0.02)
	suelo(-47.5, 6.5, -45.0, 22.0, ladrillo, 0.026)
	suelo(-30, 18.5, -9, 22.0, ladrillo, 0.02)
	var f := Vector3(-36.0, 0, 14.0)
	var fuente := material(Color("6b5f50"))
	cilindro(2.6, 0.5, f, fuente, 12)
	cilindro(2.3, 0.02, f + Vector3.UP * 0.5, Color("2c4a55"), 12, false)
	cilindro(1.6, 0.35, f + Vector3.UP * 0.5, fuente, 12, false, 1.9)
	cilindro(0.25, 1.1, f + Vector3.UP * 0.85, fuente, 8, false, 0.35)
	cilindro(1.1, 0.35, f + Vector3.UP * 1.9, fuente, 12, false, 0.35)
	cilindro(0.15, 0.6, f + Vector3.UP * 2.25, fuente, 8, false, 0.2)
	cilindro(0.55, 0.22, f + Vector3.UP * 2.8, fuente, 10, false, 0.15)
	for a: Vector2 in [Vector2(-56, 9), Vector2(-52, 19), Vector2(-40, 9.5), Vector2(-24, 10), Vector2(-16, 16)]:
		_arbol(a.x, a.y)
	for xa: float in [-58.0, -40.0]:
		baranda(Vector3(xa, 0, 7.5), Vector3(xa + 10.0, 0, 7.5), hierro, 0.5, 0.25, false)
	banca(-28.0, 10.0, 0.0)
	banca(-52.0, 14.2, 0.0)
	# Arcada: columnas y arcos delante del muro del bloque de entrada.
	var xc: float = -29.0
	while xc <= -10.0:
		cilindro(0.28, 3.1, Vector3(xc, 0, 19.8), piedra_oscura, 8)
		if xc + 3.0 <= -9.5:
			arco(Vector3(xc + 1.5, 3.1, 19.8), 0.0, 1.22, 0.3, 0.5, piedra_oscura, 7)
		xc += 3.0
	caja_mat(Vector3(20.5, 0.35, 2.6), Vector3(-19.5, 4.6, 20.7), teja, false)
	caja_mat(Vector3(20.5, 0.9, 0.5), Vector3(-19.5, 4.1, 19.8), piedra_oscura, false)
	zonas.append([-64.0, 6.5, -9.0, 22.0, 0, "Patio de la fuente"])

	# Patio sur-oriental: prado, árboles y bancas.
	suelo(9, 6.5, 64, 22, material(Color("34502a"), 0.95), 0.012)
	suelo(9, 12.5, 64, 15.0, ladrillo, 0.02)
	for a: Vector2 in [Vector2(20, 9), Vector2(34, 19), Vector2(48, 9.5), Vector2(58, 18)]:
		_arbol(a.x, a.y)
	banca(30.0, 10.0, 0.0)
	banca(44.0, 18.5, 0.0)
	zonas.append([9.0, 6.5, 64.0, 22.0, 0, "Patio oriental"])

	# Patios de atrás, a los lados del brazo norte.
	for lado: float in [-1.0, 1.0]:
		for a: Vector2 in [Vector2(20, -20), Vector2(38, -30), Vector2(26, -48), Vector2(50, -52), Vector2(54, -18)]:
			_arbol(a.x * lado, a.y)
		banca(16.0 * lado, -24.0, 90.0)
	zonas.append([-64.0, -64.0, -6.5, -6.5, 0, "Patio noroeste"])
	zonas.append([6.5, -64.0, 64.0, -6.5, 0, "Patio noreste"])
	zonas.append([-72.0, 37.2, 72.0, 50.0, 0, "Jardines de la entrada"])
	zonas.append([-180.0, 50.0, 72.0, 70.0, 0, "Carrera Séptima"])


func _techos() -> void:
	# Tejados a dos aguas sobre los brazos, el bloque de entrada y la escalera.
	prisma(Vector3(14.6, 2.6, 49.0), Vector3(0, Y_TECHO + 1.3, -34.0), teja)
	prisma(Vector3(14.6, 2.6, 49.0), Vector3(-34.0, Y_TECHO + 1.3, 0), teja, PI * 0.5)
	prisma(Vector3(14.6, 2.6, 49.0), Vector3(34.0, Y_TECHO + 1.3, 0), teja, PI * 0.5)
	prisma(Vector3(15.2, 2.8, 61.0), Vector3(0, Y_TECHO + 1.4, 29.0), teja, PI * 0.5)
	prisma(Vector3(18.8, 2.4, 12.4), Vector3(0, Y_TECHO + 1.2, 16.0), teja)
	# Linterna octogonal sobre el centro, de donde baja la luz al pozo.
	caja_mat(Vector3(5.2, 0.05, 5.2), Vector3(0, Y_TECHO - 0.06, 0), material_brillante(Color("9fb6d6"), Color("7f9fcf"), 1.1), false)
	cilindro(7.0, 2.6, Vector3(0, Y_TECHO, 0), piedra, 8, false, -1.0, PI / 8.0)
	cilindro(6.95, 0.7, Vector3(0, Y_TECHO + 1.3, 0), material_brillante(Color("9fb6d6"), Color("6f8fbf"), 0.7, true), 8, false, -1.0, PI / 8.0)
	cilindro(0.6, 3.4, Vector3(0, Y_TECHO + 2.6, 0), teja, 8, false, 7.6, PI / 8.0)


func _luces() -> void:
	for f: int in PISOS:
		var y0: float = f * H
		for p: Vector2 in [Vector2(5.5, 5.5), Vector2(-5.5, 5.5), Vector2(5.5, -5.5), Vector2(-5.5, -5.5)]:
			foco(Vector3(p.x, y0 + H - 0.35, p.y), 4.4)
		# Luces que bañan los muros donde cuelgan las obras grandes.
		# Inclinadas hacia la pared: si apuntan derecho al piso, la luz apenas roza el muro.
		for d: Vector2 in [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]:
			for lado: float in [-4.5, 4.5]:
				var a_lo_largo := Vector2(d.y, d.x) * lado
				var desde: Vector2 = d * 5.5 + a_lo_largo
				var hacia: Vector2 = d * 9.8 + a_lo_largo
				var l := foco(Vector3(desde.x, y0 + H - 0.4, desde.y), 4.5, 7.0, 34.0)
				l.look_at(Vector3(hacia.x, y0 + 1.7, hacia.y))
		zonas.append([-10.0, -10.0, 10.0, 10.0, f, "Piso %d · %s" % [f + 1, CENTRO[f]]])
	# Luz de luna que baja por el pozo del centro.
	foco(Vector3(0, Y_TECHO + 1.8, 0), 5.0, 17.0, 16.0, Color("a9bde0"), false)
	# Reflectores que iluminan la fachada desde el suelo.
	for x: float in [-48.0, -36.0, -20.0, -9.0, 9.0, 20.0, 36.0, 48.0]:
		var r := SpotLight3D.new()
		r.position = Vector3(x, 0.4, 40.0)
		r.rotation_degrees = Vector3(58.0, 0, 0)
		r.light_color = Color("ffcf94")
		r.light_energy = 5.0
		r.spot_range = 18.0
		r.spot_angle = 32.0
		r.light_cull_mask = CAPA_EXTERIOR
		add_child(r)
	# Patios.
	for p: Vector2 in [Vector2(-30, 14), Vector2(-50, 10), Vector2(30, 14), Vector2(50, 18), Vector2(-30, -30), Vector2(30, -30), Vector2(-40, -54), Vector2(40, -54)]:
		_farol(p.x, p.y)
	var luna := DirectionalLight3D.new()
	luna.rotation_degrees = Vector3(-42, 35, 0)
	luna.light_color = Color("9fb3d9")
	luna.light_energy = 0.35
	luna.shadow_enabled = true
	luna.directional_shadow_max_distance = 90.0
	add_child(luna)


func _letreros() -> void:
	letrero("MUSEO NACIONAL", Vector3(0, 10.4, 37.25), 0.0, 150, Color("efe6d2"))
	letrero("EN PRÉSTAMO\n\nColección de arte del\nBanco de la República\n\nMuseo de Arte\nMiguel Urrutia", Vector3(-9.0, 6.6, 37.32), 0.0, 40, Color("f3ead8"))
	letrero("VESTÍBULO · HISTORIA DEL PANÓPTICO", Vector3(0, 3.7, 22.32), 0.0, 52)
	letrero("SALA 1 · LA HISTORIA DEL MUSEO Y EL MUSEO EN LA HISTORIA\nCERRADA POR MONTAJE", Vector3(-11.83, 3.3, 29.0), 90.0, 36)
	letrero("TAQUILLA", Vector3(11.83, 3.3, 29.0), -90.0, 44)
	letrero("VIGILANCIA", Vector3(21.83, 3.0, 25.0), -90.0, 40)
	letrero("ESCALERA PRINCIPAL", Vector3(0, 4.0, 9.83), 180.0, 44)
	letrero("SALA 7 · MEMORIA Y NACIÓN", Vector3(0, H + 3.4, 22.32), 0.0, 52)
	letrero("MURO DE LA DIVERSIDAD", Vector3(0, H + 2.9, 29.18), 0.0, 40)
	letrero("EXPOSICIÓN TEMPORAL\nMUSEO DE ARTE MIGUEL URRUTIA · EN PRÉSTAMO", Vector3(0, 2 * H + 3.4, 22.32), 0.0, 48)
	letrero("SALA 14 · LA ROTONDA\nMIRADA PANÓPTICA AL ARTE", Vector3(0, 2 * H + 4.0, 9.83), 180.0, 44)


# ================================================================ datos de juego

func _datos() -> void:
	# Cuadros. Brazos, piso 1: entre ventanas, en las paredes de afuera (no en la sala 6).
	for b: Dictionary in BRAZOS:
		var u: Vector3 = b["u"]
		var v: Vector3 = b["v"]
		if b["id"] != "e":
			# En el fondo del brazo norte (sala 5) están las estanterías: ahí no hay cuadros.
			var sitios: Array = [17.0, 24.0, 34.5] if b["id"] == "n" else [17.0, 24.0, 34.5, 41.5, 48.5]
			for s: float in sitios:
				for t: float in [-6.19, 6.19]:
					var p: Vector3 = _w(b, s, t, 0)
					slots_pared.append([p.x, p.z, _giro(-v * signf(t)), 0])
		# Pisos 2 y 3: dentro de las celdas abiertas, en el tabique que da al centro.
		for f: int in [1, 2]:
			for k: int in [1, 5, 9]:
				var s_k: float = INICIO_BRAZO + CELDA * k
				for t: float in [-4.4, 4.4]:
					var p: Vector3 = _w(b, s_k + 0.16, t, 0)
					slots_pared.append([p.x, p.z, _giro(u), f])
	# La Rotonda y los pisos de abajo: obras grandes en los muros diagonales.
	for f: int in PISOS:
		for d: Array in [[8.03, 8.03, -135.0], [8.03, -8.03, -45.0], [-8.03, -8.03, 45.0], [-8.03, 8.03, 135.0]]:
			slots_pared.append([d[0], d[1], d[2], f])
	for lado: float in [-4.5, 4.5]:
		slots_pared.append([lado, -9.84, 0.0, 2])
		slots_pared.append([lado, 9.84, 180.0, 2])
		slots_pared.append([-9.84, lado, 90.0, 2])
		slots_pared.append([9.84, lado, -90.0, 2])
	# Vestíbulo de entrada, muro de la diversidad y exposición temporal.
	for zc: float in [25.0, 33.0]:
		slots_pared.append([-11.84, zc, 90.0, 0])
		slots_pared.append([11.84, zc, -90.0, 0])
	for xm: float in [-8.0, 0.0, 8.0]:
		slots_pared.append([xm, 28.84, 180.0, 1])
		slots_pared.append([xm, 29.16, 0.0, 1])
	for xp: float in [-20.0, -8.0, 8.0, 20.0]:
		slots_pared.append([xp, 27.84, 180.0, 2])
		slots_pared.append([xp, 28.16, 0.0, 2])
	for xf: float in [-24.0, -12.0, 12.0, 24.0]:
		slots_pared.append([xf, 35.99, 180.0, 2])

	# Esculturas.
	for p: Array in [[4.5, -22.25, 0], [-4.5, -36.25, 0], [4.5, -50.25, 0],
			[-22.25, -4.5, 0], [-36.25, 4.5, 0], [-50.25, -4.5, 0],
			[22.25, 4.5, 0], [36.25, -4.5, 0], [50.25, 4.5, 0],
			[4.4, -22.25, 1], [-36.25, 4.4, 1], [50.25, -4.4, 1], [22.25, 4.4, 2], [-50.25, -4.4, 2], [18.0, 32.5, 1]]:
		slots_pedestal.append(p)

	slots_coleccionable = [
		[-8.5, 1.11, 29.0], [-8.5, 1.11, 31.0],      # Taquilla del vestíbulo.
		[25.2, 0.81, 22.8],                           # Escritorio de vigilancia.
		[-24.0, 0.91, 26.0],                          # Caja de embalaje, sala 1.
		[-28.0, 0.47, 10.0], [30.0, 0.47, 10.0],      # Bancas de los patios.
		[25.75, 0.92, 4.6], [39.75, 0.92, -4.6],      # Vitrinas de la sala 6.
		[4.6, 0.73, -43.25], [-4.6, 1.43, -46.75],    # Estantes de la reserva visible.
		[5.5, H + 0.01, -30.3], [-44.3, H + 0.01, 5.5],   # Rincones de celdas, piso 2.
		[5.6, 2 * H + 0.47, 0.0],                     # Banca de la Rotonda.
		[20.0, H + 0.47, 25.0],                       # Banca de la sala 7.
		[0.0, 2 * H + 0.47, 32.5],                    # Banca de la exposición temporal.
		[20.0, 0.62, 39.5],                           # Banca del prado.
		[0.9, 1.06, 0.0],                             # Mesa del vigilante.
	]

	camaras = [
		[11.3, 3.9, 35.3, 45.0], [7.5, 3.9, 7.5, 45.0],
		[0.0, 3.9, -57.3, 180.0], [-57.3, 3.9, 0.0, -90.0], [57.3, 3.9, 0.0, 90.0],
		[0.0, H + 3.9, -57.3, 180.0], [29.3, H + 3.9, 35.3, 45.0],
		[7.5, 2 * H + 3.9, 7.5, 45.0], [-57.3, 2 * H + 3.9, 0.0, -90.0], [-29.3, 2 * H + 3.9, 35.3, -45.0],
	]

	patrullas = [
		[[4.0, 4.0, 0], [4.0, -4.0, 0], [-4.0, -4.0, 0], [-4.0, 4.0, 0]],          # Centro: mira hacia todos los brazos.
		[[0.0, -14.0, 0], [0.0, -54.0, 0]],                                        # Brazo norte.
		[[-14.0, 0.0, 0], [-54.0, 0.0, 0]],                                        # Brazo oeste.
		[[14.0, 0.0, 0], [54.0, 0.0, 0]],                                          # Sala 6.
		[[0.0, 32.0, 0], [-7.0, 25.0, 0], [7.0, 25.0, 0]],                         # Vestíbulo de entrada.
		[[-24.0, 25.0, 1], [24.0, 25.0, 1], [24.0, 33.0, 1], [-24.0, 33.0, 1]],   # Sala 7.
		[[0.0, -13.0, 1], [0.0, -55.0, 1]],                                        # Pasillo norte, piso 2.
		[[5.0, 5.0, 2], [5.0, -5.0, 2], [-5.0, -5.0, 2], [-5.0, 5.0, 2]],          # La Rotonda.
		[[-13.0, 0.0, 2], [-55.0, 0.0, 2]],                                        # Pasillo oeste, piso 3.
		[[-24.0, 25.0, 2], [24.0, 25.0, 2]],                                       # Exposición temporal.
	]
