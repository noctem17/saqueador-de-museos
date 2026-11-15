class_name DecoracionMuseo
extends RefCounted
## Utilería del Museo Nacional: matas, bancas, cordones, extintores, letreros de
## salida, paneles de sala, celdas recreadas, lockers de vigilancia y el montaje de
## la sala 1. No cambia la forma del edificio (eso es mapa_museo_nacional.gd): solo
## lo llena para que se sienta vivo y deja bultos detrás de los cuales esconderse.
##
## Todo se arma con las cajas y cilindros del mapa, que se juntan en pocas mallas,
## así que llenar el museo casi no cuesta rendimiento.

const H: float = MapaMuseoNacional.H
const S_PEDESTALES: Array = [22.25, 36.25, 50.25]   # Donde ya hay pedestales en cada brazo.

var m: MapaMuseoNacional
var _maceta: Material
var _hoja: Material
var _hoja_clara: Material
var _rojo: Material
var _metal: Material
var _laton: Material
var _cordon: Material


func _init(mapa: MapaMuseoNacional) -> void:
	m = mapa
	_maceta = m.material(Color("8a4b2f"), 0.9)
	_hoja = m.material(Color("2f5a2a"), 0.9)
	_hoja_clara = m.material(Color("4c7a35"), 0.9)
	_rojo = m.material(Color("b3241b"), 0.5)
	_metal = m.material(Color("2d3034"), 0.45)
	_laton = m.material(Color("c09a45"), 0.35)
	_cordon = m.material(Color("7a1420"), 0.8)


func decorar() -> void:
	for b: Dictionary in MapaMuseoNacional.BRAZOS:
		_brazo_planta_baja(b)
		for f: int in [1, 2]:
			_pasillo_celdas(b, f)
	_celdas_recreadas()
	_centro()
	_vestibulo()
	_vigilancia()
	_sala_1()
	_salas_de_arriba()
	_patios()


# ================================================================ por zonas

## Galería del piso 1: banca en el pasillo central, panel de la sala, matas al
## fondo, extintor y papeleras junto a los pilares.
func _brazo_planta_baja(b: Dictionary) -> void:
	var u: Vector3 = b["u"]
	var v: Vector3 = b["v"]
	var giro_banca: float = m._giro(v)   # La banca corre a lo largo del brazo.
	var p: Vector3 = m._w(b, 29.0, 0, 0)
	m.banca(p.x, p.z, giro_banca)
	var nombre: String = (MapaMuseoNacional.SALAS[b["id"]][0][0] as String).to_upper()
	panel(m._w(b, 15.2, 4.6, 0), m._giro(-u), nombre)   # Entre vitrinas en la sala 6.
	for t: float in [-5.3, 5.3]:
		maceta(m._w(b, 56.6, t, 0), true)
		extintor(m._w(b, 31.0, signf(t) * 6.1, 0), m._giro(-v * signf(t)))
	for t: float in [-1.85, 1.85]:
		papelera(m._w(b, 13.5, t, 0))


## Pasillo entre celdas (pisos 2 y 3): extintor, banca contra el muro, matas al
## fondo y letrero de salida a la entrada del brazo.
func _pasillo_celdas(b: Dictionary, f: int) -> void:
	var y0: float = f * H
	var u: Vector3 = b["u"]
	var v: Vector3 = b["v"]
	extintor(m._w(b, 17.0, 2.27, y0), m._giro(-v))
	extintor(m._w(b, 45.0, -2.27, y0), m._giro(v))
	var p: Vector3 = m._w(b, 31.0, -2.0, y0)
	m.banca(p.x, p.z, m._giro(v), y0)
	for t: float in [-1.6, 1.6]:
		maceta(m._w(b, 56.8, t, y0), false)
	salida(m._w(b, 10.2, 0, y0 + 3.95), m._giro(u), "↩ SALIDA")   # Encima de la puerta al centro.


## Tres celdas abiertas del piso 2 recreadas como eran en la cárcel: catre,
## banquito y balde. Quedan en penumbra: buen sitio para esconderse.
func _celdas_recreadas() -> void:
	var y0: float = H
	var madera: Material = m.material(Color("5a3e27"), 0.85)
	var colchon: Material = m.material(Color("8c8270"), 0.95)
	for dato: Array in [["n", 7], ["o", 3], ["e", 7]]:
		var b: Dictionary = _brazo(dato[0])
		var c: float = MapaMuseoNacional.INICIO_BRAZO + MapaMuseoNacional.CELDA * (dato[1] as int) + MapaMuseoNacional.CELDA * 0.5
		for lado: float in [-1.0, 1.0]:
			# Catre de hierro y tablas contra el tabique.
			m._caja_bt(b, c + 0.78, c + 1.52, lado * 3.6, lado * 5.6, y0 + 0.36, y0 + 0.42, madera, false)
			m._caja_bt(b, c + 0.82, c + 1.48, lado * 3.65, lado * 5.55, y0 + 0.42, y0 + 0.5, colchon, false)
			for ds: float in [0.8, 1.5]:
				for dt: float in [3.62, 5.58]:
					m._caja_bt(b, c + ds - 0.025, c + ds + 0.025, lado * dt - 0.025, lado * dt + 0.025, y0, y0 + 0.36, m.hierro, false)
			m._caja_bt(b, c + 0.78, c + 1.52, lado * 3.6, lado * 5.6, y0, y0 + 0.5, null, true)
			# Banquito y balde.
			var q: Vector3 = m._w(b, c - 1.0, lado * 4.0, y0)
			m.cilindro(0.17, 0.42, q, madera, 8, false)
			m.cilindro(0.15, 0.32, m._w(b, c - 1.2, lado * 5.8, y0), m.material(Color("5b5f62"), 0.5), 10, false, 0.13)


## Centro del panóptico: matas a los lados de cada puerta y letrero de salida
## hacia la escalera principal.
func _centro() -> void:
	for f: int in 3:
		var y0: float = f * H
		for p: Vector2 in [Vector2(4.2, -9.3), Vector2(-4.2, -9.3), Vector2(9.3, 4.2), Vector2(9.3, -4.2),
				Vector2(-9.3, 4.2), Vector2(-9.3, -4.2), Vector2(4.2, 9.3), Vector2(-4.2, 9.3)]:
			maceta(Vector3(p.x, y0, p.y), f != 2)
		salida(Vector3(0, y0 + 3.85, 9.82), 180.0, "↓ SALIDA · ESCALERA PRINCIPAL")


## Vestíbulo: matas en la portada, fila con cordones frente a la taquilla,
## exhibidor de folletos y panel de bienvenida.
func _vestibulo() -> void:
	for x: float in [-2.9, 2.9]:
		maceta(Vector3(x, 0, 35.2), true)
	for x: float in [7.0, 9.6]:
		cordones(Vector3(x, 0, 29.6), Vector3(x, 0, 33.6))
	# Exhibidor de folletos.
	m.caja_mat(Vector3(0.9, 1.4, 0.35), Vector3(-10.9, 0.7, 33.5), m.material(Color("3b2f26"), 0.7), true, PI * 0.5)
	var folleto: Array[Color] = [Color("c9472f"), Color("2f6f8f"), Color("e0b34a"), Color("4f7a3c")]
	for i: int in 4:
		m.caja_mat(Vector3(0.18, 0.26, 0.02), Vector3(-10.71, 0.45 + 0.28 * i, 33.2 + 0.25 * (i % 2)), m.material(folleto[i]), false, PI * 0.5)
	panel(Vector3(3.2, 0, 33.2), 0.0, "BIENVENIDOS\nMUSEO NACIONAL DE COLOMBIA")


## Cuarto de vigilancia: lockers, silla, archivador y botellón de agua.
func _vigilancia() -> void:
	var gris: Material = m.material(Color("5d6670"), 0.5)
	for i: int in 4:
		var z: float = 23.25 + 0.52 * i
		m.caja_mat(Vector3(0.5, 1.9, 0.5), Vector3(29.45, 0.95, z), gris, true)
		m.caja_mat(Vector3(0.02, 0.16, 0.03), Vector3(29.19, 1.15, z + 0.15), _metal, false)
	silla(Vector3(26.0, 0, 23.9), 180.0)
	m.caja_mat(Vector3(0.5, 1.3, 0.6), Vector3(22.55, 0.65, 27.2), gris, true)
	m.cilindro(0.16, 0.95, Vector3(28.9, 0, 27.4), m.material(Color("e8e8e8"), 0.6), 10)
	m.cilindro(0.15, 0.4, Vector3(28.9, 0.95, 27.4), m.material_vidrio(), 10, false)


## Sala 1, cerrada por montaje: escalera de tijera, carretilla, rollos de plástico
## de burbujas y el letrero de prohibido el paso (la reja con candado la pone mision.gd).
func _sala_1() -> void:
	var aluminio: Material = m.material(Color("9da3a8"), 0.4)
	for dz: float in [-0.25, 0.25]:
		m.caja_t(Vector3(0.05, 2.0, 0.05), Transform3D(Basis(Vector3.RIGHT, 0.22 * signf(dz)), Vector3(-27.5, 0.98, 33.5 + dz)), aluminio, false)
	m.caja_mat(Vector3(0.5, 2.0, 0.7), Vector3(-27.5, 1.0, 33.5), null, true)
	# Carretilla.
	m.caja_mat(Vector3(0.6, 0.06, 0.4), Vector3(-15.0, 0.08, 25.0), _metal, false)
	m.caja_mat(Vector3(0.05, 1.2, 0.05), Vector3(-15.0, 0.65, 24.82), _metal, false)
	m.caja_mat(Vector3(0.5, 0.5, 0.4), Vector3(-15.0, 0.36, 25.05), m.material(Color("8a6c48")), true)
	for dz: float in [0.0, 0.7]:
		m.cilindro(0.35, 1.2, Vector3(-14.4, 0, 33.6 + dz), m.material(Color("d7e2e6"), 0.3), 12)
	letrero_pequeno("MONTAJE EN CURSO\nPROHIBIDO EL PASO", Vector3(-11.83, 1.65, 31.1), 90.0, Color("b3241b"))


## Sala 7 (piso 2) y exposición temporal (piso 3): matas en las esquinas.
func _salas_de_arriba() -> void:
	for f: int in [1, 2]:
		for p: Vector2 in [Vector2(-28.6, 23.4), Vector2(28.6, 23.4), Vector2(-28.6, 34.9), Vector2(28.6, 34.9)]:
			maceta(Vector3(p.x, f * H, p.y), true)


## Patios: matas grandes junto a la arcada del patio de la fuente.
func _patios() -> void:
	for x: float in [-28.5, -10.6]:
		maceta(Vector3(x, 0, 21.2), true)


# ================================================================ piezas sueltas

## Mata en matera de barro. Las grandes son palmas que tapan a una persona.
func maceta(pos: Vector3, grande: bool) -> void:
	var r: float = 0.36 if grande else 0.26
	var alto: float = 0.55 if grande else 0.42
	m.cilindro(r, alto, pos, _maceta, 10, false, r * 0.75)
	m.cilindro(r * 0.92, 0.02, pos + Vector3.UP * alto, m.material(Color("3a2a1c")), 10, false)
	var copa: float = 1.35 if grande else 0.85
	m.cilindro(0.04, copa, pos + Vector3.UP * alto, m.material(Color("5a4a2a")), 5, false)
	var semilla: int = absi(hash(pos.snapped(Vector3.ONE * 0.1)))
	for i: int in 5:
		var a: float = TAU * i / 5.0 + float(semilla % 7)
		var off := Vector3(cos(a), 0, sin(a)) * (0.28 if grande else 0.18)
		var y: float = alto + copa * (0.65 + 0.12 * float(i % 3))
		m.esfera(0.3 if grande else 0.2, pos + off + Vector3.UP * y, _hoja if i % 2 == 0 else _hoja_clara)
	m.esfera(0.34 if grande else 0.22, pos + Vector3.UP * (alto + copa), _hoja)
	# Cuerpo alto: no se atraviesa, la grande tapa la vista, y la malla de navegación
	# no se monta encima (con una matera bajita salía una rampa falsa en el pasillo).
	var lado: float = 0.7 if grande else 0.5
	var alto_cuerpo: float = 1.9 if grande else 1.3
	m.caja_t(Vector3(lado, alto_cuerpo, lado), Transform3D(Basis(), pos + Vector3.UP * alto_cuerpo * 0.5), null, true)


## Panel de sala sobre un atril: nombre de la sala y las normas de la visita.
func panel(pos: Vector3, giro: float, titulo: String) -> void:
	var g: float = deg_to_rad(giro)
	var bas := Basis(Vector3.UP, g)
	m.caja_mat(Vector3(0.9, 1.5, 0.06), pos + Vector3.UP * 0.95, m.material(Color("2a2d33"), 0.6), true, g)
	m.caja_mat(Vector3(0.5, 0.2, 0.4), pos + Vector3.UP * 0.1, m.material(Color("2a2d33"), 0.6), false, g)
	var l := Label3D.new()
	l.text = "%s\n\n· No toque las obras\n· No use flash\n· No coma en las salas" % titulo
	l.font_size = 30
	l.pixel_size = 0.0022
	l.width = 360.0
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.outline_size = 0
	l.modulate = Color("efe6d2")
	l.position = pos + Vector3.UP * 1.1 + bas * Vector3(0, 0, 0.035)
	l.rotation.y = g
	m.add_child(l)


## Extintor rojo colgado de la pared, con su letrero. giro: hacia dónde mira.
func extintor(pos: Vector3, giro: float) -> void:
	var g: float = deg_to_rad(giro)
	var bas := Basis(Vector3.UP, g)
	var base: Vector3 = pos + bas * Vector3(0, 0, 0.12)
	m.cilindro(0.09, 0.5, base + Vector3.UP * 0.65, _rojo, 10, false)
	m.cilindro(0.04, 0.07, base + Vector3.UP * 1.15, _metal, 6, false)
	m.caja_mat(Vector3(0.3, 0.3, 0.02), pos + Vector3.UP * 1.55 + bas * Vector3(0, 0, 0.02), m.material_brillante(Color("c62a1f"), Color("5a0d08"), 0.4), false, g)


## Letrero verde de salida, que brilla un poco en la penumbra.
func salida(pos: Vector3, giro: float, texto: String) -> void:
	var g: float = deg_to_rad(giro)
	var bas := Basis(Vector3.UP, g)
	var ancho: float = 0.6 + texto.length() * 0.055
	m.caja_mat(Vector3(ancho, 0.3, 0.05), pos, m.material_brillante(Color("1f8a4c"), Color("1f8a4c"), 0.9), false, g)
	var l := Label3D.new()
	l.text = texto
	l.font_size = 40
	l.pixel_size = 0.0035
	l.outline_size = 0
	l.modulate = Color(1, 1, 1)
	l.position = pos + bas * Vector3(0, 0, 0.03)
	l.rotation.y = g
	m.add_child(l)


func papelera(pos: Vector3) -> void:
	m.cilindro(0.18, 0.7, pos, _metal, 10, false, 0.16)
	m.caja_t(Vector3(0.4, 1.3, 0.4), Transform3D(Basis(), pos + Vector3.UP * 0.65), null, true)   # Alto: ver maceta().


## Postes de latón con cordón rojo, cada 1,3 m entre a y b.
func cordones(a: Vector3, b: Vector3) -> void:
	var n: int = maxi(1, roundi(a.distance_to(b) / 1.3))
	for i: int in n + 1:
		var p: Vector3 = a.lerp(b, float(i) / n)
		m.cilindro(0.17, 0.04, p, _metal, 10, false)
		m.cilindro(0.025, 0.95, p, _laton, 6, true)
	var medio: Vector3 = (a + b) * 0.5
	var giro: float = atan2(b.x - a.x, b.z - a.z)
	m.caja_mat(Vector3(0.03, 0.03, a.distance_to(b)), medio + Vector3.UP * 0.82, _cordon, false, giro)


## Cinta de "no pasar": franja roja y blanca entre dos puntos.
func cinta(a: Vector3, b: Vector3) -> void:
	var n: int = 8
	var giro: float = atan2(b.x - a.x, b.z - a.z)
	var largo: float = a.distance_to(b) / n
	for i: int in n:
		var p: Vector3 = a.lerp(b, (i + 0.5) / n)
		var color: Material = _rojo if i % 2 == 0 else m.material(Color("f2f2f2"))
		m.caja_mat(Vector3(0.01, 0.07, largo), p, color, false, giro)


func silla(pos: Vector3, giro: float) -> void:
	var g: float = deg_to_rad(giro)
	var bas := Basis(Vector3.UP, g)
	var tela: Material = m.material(Color("22252a"), 0.8)
	m.cilindro(0.04, 0.42, pos, _metal, 6, false)
	m.caja_mat(Vector3(0.46, 0.08, 0.46), pos + Vector3.UP * 0.46, tela, false, g)
	m.caja_mat(Vector3(0.44, 0.5, 0.06), pos + Vector3.UP * 0.78 + bas * Vector3(0, 0, -0.21), tela, false, g)
	m.caja_mat(Vector3(0.5, 0.9, 0.5), pos + Vector3.UP * 0.45, null, true, g)


func letrero_pequeno(texto: String, pos: Vector3, giro: float, color: Color) -> void:
	var l := Label3D.new()
	l.text = texto
	l.font_size = 32
	l.pixel_size = 0.0028
	l.outline_size = 0
	l.modulate = color
	l.position = pos
	l.rotation_degrees.y = giro
	m.add_child(l)


func _brazo(id: String) -> Dictionary:
	for b: Dictionary in MapaMuseoNacional.BRAZOS:
		if b["id"] == id:
			return b
	return {}
