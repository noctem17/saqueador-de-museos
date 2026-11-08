class_name Mapa
extends NavigationRegion3D
## Base común de los mapas. Trae las herramientas para armar el edificio con piezas
## simples (cajas, cilindros, escalones, rampas, letreros, luces) y los datos que lee
## la misión: dónde pueden ir obras, coleccionables, cámaras, guardias y la camioneta.
## Cada mapa concreto llena esos datos en _init() y arma todo en construir().
##
## Rendimiento: las piezas NO se crean como objetos sueltos. Se van sumando a mallas
## grandes agrupadas por material, piso y zona de 16 m (terminar_lotes() las crea al
## final). Así la tarjeta de video dibuja unas pocas mallas en vez de miles de cajas.
## Las colisiones van todas en un solo cuerpo, y los muros y pisos grandes se
## registran como "oclusores": lo que queda detrás de ellos no se dibuja.

const GROSOR: float = 0.3
const PUERTA: float = 2.4
const ALTO_PUERTA: float = 2.7
const ZONA: float = 16.0

var alto_piso: float = 4.5           # Para mapas de varios pisos.
var slots_pared: Array = []          # Cuadros: [x, z, giro, piso]. El giro apunta hacia la sala.
var slots_pedestal: Array = []       # Esculturas: [x, z, piso]
var slots_coleccionable: Array = []  # Monedas y billetes: [x, y, z] (y absoluta)
var camaras: Array = []              # [x, y, z, giro base]
var patrullas: Array = []            # Rutas de guardias: listas de [x, z, piso]
var zonas: Array = []                # [x0, z0, x1, z1, piso, nombre] para saber dónde está alguien.
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

## Capas de dibujo de lo que se está construyendo. Lo de afuera va también en la capa
## 2, y las luces exteriores solo alumbran esa capa: así no se cuelan por los muros.
var capas: int = 1
const CAPA_EXTERIOR: int = 2

var _materiales: Dictionary[String, Material] = {}
var _mallas: Dictionary[String, Mesh] = {}
var _formas: Dictionary[String, Shape3D] = {}
var _lotes: Dictionary = {}          # clave -> [SurfaceTool, Material]
var _lotes_cerrados: bool = false
var _solidos: StaticBody3D
var _ocl_vertices := PackedVector3Array()
var _ocl_indices := PackedInt32Array()


## Cada mapa lo reemplaza con su propio edificio.
func construir() -> void:
	pass


# ---------------------------------------------------------------- datos

func piso_de(dato: Array, indice: int) -> int:
	return int(dato[indice]) if dato.size() > indice else 0


func base_y(piso: int) -> float:
	return piso * alto_piso


## Si un punto está dentro del museo (ahí sí vigilan los guardias y las cámaras).
func es_interior(_pos: Vector3) -> bool:
	return true


## Nombre de la zona donde está un punto, por ejemplo "Piso 2 · Sala 8".
func zona_en(pos: Vector3) -> String:
	for z: Array in zonas:
		var piso: int = z[4]
		var y0: float = base_y(piso) - 3.0 if piso == 0 else base_y(piso) - 1.0
		if pos.y < y0 or pos.y >= base_y(piso) + alto_piso - 1.0:
			continue
		if pos.x >= z[0] and pos.x < z[2] and pos.z >= z[1] and pos.z < z[3]:
			return z[5]
	return ""


# ---------------------------------------------------------------- materiales

func material(color: Color, rugosidad: float = 0.8) -> StandardMaterial3D:
	var clave: String = "%s/%.2f" % [color.to_html(), rugosidad]
	if not _materiales.has(clave):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = rugosidad
		_materiales[clave] = mat
	return _materiales[clave] as StandardMaterial3D


## Piedra, madera o adoquín con el patrón de bloques del sombreador.
func material_bloques(color: Color, junta: Color, tam: Vector2, variacion: float = 0.18, grosor_junta: float = 0.035) -> ShaderMaterial:
	var clave: String = "b/%s/%s/%s/%.2f" % [color.to_html(), junta.to_html(), tam, variacion]
	if not _materiales.has(clave):
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/bloques.gdshader")
		mat.set_shader_parameter("color_base", color)
		mat.set_shader_parameter("color_junta", junta)
		mat.set_shader_parameter("tam_bloque", tam)
		mat.set_shader_parameter("variacion", variacion)
		mat.set_shader_parameter("junta", grosor_junta)
		_materiales[clave] = mat
	return _materiales[clave] as ShaderMaterial


func material_brillante(color: Color, brillo: Color, energia: float, doble_cara: bool = false) -> StandardMaterial3D:
	var clave: String = "e/%s/%s/%.2f/%s" % [color.to_html(), brillo.to_html(), energia, doble_cara]
	if not _materiales.has(clave):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = brillo
		mat.emission_energy_multiplier = energia
		if doble_cara:
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materiales[clave] = mat
	return _materiales[clave] as StandardMaterial3D


func material_vidrio() -> StandardMaterial3D:
	if not _materiales.has("vidrio"):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.8, 0.9, 1.0, 0.12)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.roughness = 0.05
		_materiales["vidrio"] = mat
	return _materiales["vidrio"] as StandardMaterial3D


# ---------------------------------------------------------------- mallas agrupadas

## Suma una malla al lote que le corresponde. Si los lotes ya se cerraron (cosas
## que la misión agrega después, como los paneles de los cuadros), crea el objeto.
func malla(m: Mesh, xf: Transform3D, mat: Material) -> void:
	if _lotes_cerrados:
		var mi := MeshInstance3D.new()
		mi.mesh = m
		mi.transform = xf
		mi.material_override = mat
		mi.layers = capas
		add_child(mi)
		return
	var piso: int = floori((xf.origin.y + 0.3) / alto_piso)
	var clave: String = "%d|%d|%d|%d|%d" % [mat.get_instance_id(), piso, floori(xf.origin.x / ZONA), floori(xf.origin.z / ZONA), capas]
	if not _lotes.has(clave):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_lotes[clave] = [st, mat, capas]
	(_lotes[clave][0] as SurfaceTool).append_from(m, 0, xf)


## Convierte los lotes en mallas reales. Se llama una vez, al terminar de construir.
func terminar_lotes() -> void:
	if _lotes_cerrados:
		return
	for clave: String in _lotes:
		var st: SurfaceTool = _lotes[clave][0]
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = _lotes[clave][1]
		mi.layers = _lotes[clave][2]
		add_child(mi)
	_lotes.clear()
	_lotes_cerrados = true
	if not _ocl_vertices.is_empty():
		var oclusor := ArrayOccluder3D.new()
		oclusor.set_arrays(_ocl_vertices, _ocl_indices)
		var oi := OccluderInstance3D.new()
		oi.occluder = oclusor
		add_child(oi)


func _caja_malla(tam: Vector3) -> BoxMesh:
	var clave: String = "caja/%s" % tam.snapped(Vector3.ONE * 0.001)
	if not _mallas.has(clave):
		var b := BoxMesh.new()
		b.size = tam
		_mallas[clave] = b
	return _mallas[clave] as BoxMesh


func _cilindro_malla(arriba: float, abajo: float, alto: float, lados: int) -> CylinderMesh:
	var clave: String = "cil/%.3f/%.3f/%.3f/%d" % [arriba, abajo, alto, lados]
	if not _mallas.has(clave):
		var c := CylinderMesh.new()
		c.top_radius = arriba
		c.bottom_radius = abajo
		c.height = alto
		c.radial_segments = lados
		c.rings = 1
		_mallas[clave] = c
	return _mallas[clave] as CylinderMesh


func _solido(forma: Shape3D, xf: Transform3D) -> void:
	if _solidos == null:
		_solidos = StaticBody3D.new()
		_solidos.name = "Solidos"
		_solidos.collision_layer = Juego.CAPA_MUNDO
		_solidos.collision_mask = 0
		add_child(_solidos)
	var col := CollisionShape3D.new()
	col.shape = forma
	col.transform = xf
	_solidos.add_child(col)


func _forma_caja(tam: Vector3) -> BoxShape3D:
	var clave: String = "caja/%s" % tam.snapped(Vector3.ONE * 0.001)
	if not _formas.has(clave):
		var f := BoxShape3D.new()
		f.size = tam
		_formas[clave] = f
	return _formas[clave] as BoxShape3D


func _oclusor(tam: Vector3, xf: Transform3D) -> void:
	var h: Vector3 = tam * 0.49
	var base: int = _ocl_vertices.size()
	for i: int in 8:
		_ocl_vertices.append(xf * Vector3(h.x if i & 1 else -h.x, h.y if i & 2 else -h.y, h.z if i & 4 else -h.z))
	for t: int in [0, 1, 3, 0, 3, 2, 4, 6, 7, 4, 7, 5, 0, 4, 5, 0, 5, 1, 2, 3, 7, 2, 7, 6, 0, 2, 6, 0, 6, 4, 1, 5, 7, 1, 7, 3]:
		_ocl_indices.append(base + t)


# ---------------------------------------------------------------- piezas

## Caja con cualquier orientación. Los muros y pisos grandes y sólidos tapan la vista.
func caja_t(tam: Vector3, xf: Transform3D, mat: Material, solida: bool = true) -> void:
	if mat != null:
		malla(_caja_malla(tam), xf, mat)
	if solida:
		_solido(_forma_caja(tam), xf)
		var d: Array = [tam.x, tam.y, tam.z]
		d.sort()
		if mat != null and d[0] >= 0.25 and d[1] >= 2.5 and not _lotes_cerrados:
			_oclusor(tam, xf)


func caja_mat(tam: Vector3, pos: Vector3, mat: Material, solida: bool, giro: float = 0.0) -> void:
	caja_t(tam, Transform3D(Basis(Vector3.UP, giro), pos), mat, solida)


func caja(tam: Vector3, pos: Vector3, color: Color, solida: bool = true, giro: float = 0.0) -> void:
	caja_mat(tam, pos, material(color), solida, giro)


## Cilindro apoyado en el piso (pos es el centro de la base). Con radio_abajo
## distinto sale un cono truncado; con radio 0 arriba, un cono.
func cilindro(radio: float, alto: float, pos: Vector3, mat_o_color: Variant, lados: int = 12, solido: bool = true, radio_abajo: float = -1.0, giro: float = 0.0) -> void:
	var mat: Material = mat_o_color if mat_o_color is Material else material(mat_o_color as Color)
	var abajo: float = radio if radio_abajo < 0.0 else radio_abajo
	var xf := Transform3D(Basis(Vector3.UP, giro), pos + Vector3.UP * alto * 0.5)
	malla(_cilindro_malla(radio, abajo, alto, lados), xf, mat)
	if solido:
		var clave: String = "cil/%.3f/%.3f" % [maxf(radio, abajo), alto]
		if not _formas.has(clave):
			var f := CylinderShape3D.new()
			f.radius = maxf(radio, abajo)
			f.height = alto
			_formas[clave] = f
		_solido(_formas[clave], xf)


func esfera(radio: float, pos: Vector3, mat: Material) -> void:
	var clave: String = "esf/%.3f" % radio
	if not _mallas.has(clave):
		var s := SphereMesh.new()
		s.radius = radio
		s.height = radio * 2.0
		s.radial_segments = 8
		s.rings = 5
		_mallas[clave] = s
	malla(_mallas[clave], Transform3D(Basis(), pos), mat)


## Prisma triangular (techos a dos aguas). El caballete corre a lo largo de z local.
func prisma(tam: Vector3, pos: Vector3, mat: Material, giro: float = 0.0) -> void:
	var clave: String = "pri/%s" % tam.snapped(Vector3.ONE * 0.01)
	if not _mallas.has(clave):
		var p := PrismMesh.new()
		p.size = tam
		_mallas[clave] = p
	malla(_mallas[clave], Transform3D(Basis(Vector3.UP, giro), pos), mat)


## Muro recto con huecos de puerta. horizontal: corre a lo largo de x en z = fijo;
## si no, corre a lo largo de z en x = fijo. y0 es la altura de la base.
func muro(horizontal: bool, fijo: float, inicio: float, fin: float, puertas: Array, alto: float, mat: Material, zocalo: bool, y0: float = 0.0, grosor: float = GROSOR, ancho_puerta: float = PUERTA, alto_puerta: float = ALTO_PUERTA) -> void:
	var cursor: float = inicio
	var orden: Array = puertas.duplicate()
	orden.sort()
	for centro: float in orden:
		_tramo(horizontal, fijo, cursor, centro - ancho_puerta * 0.5, alto, mat, zocalo, y0, grosor)
		var resto: float = alto - alto_puerta
		if resto > 0.01:
			var tam := Vector3(ancho_puerta, resto, grosor) if horizontal else Vector3(grosor, resto, ancho_puerta)
			var y: float = y0 + alto_puerta + resto * 0.5
			caja_mat(tam, Vector3(centro, y, fijo) if horizontal else Vector3(fijo, y, centro), mat, true)
		cursor = centro + ancho_puerta * 0.5
	_tramo(horizontal, fijo, cursor, fin, alto, mat, zocalo, y0, grosor)


func _tramo(horizontal: bool, fijo: float, a: float, b: float, alto: float, mat: Material, zocalo: bool, y0: float, grosor: float) -> void:
	if b - a <= 0.01:
		return
	# Se parte en tramos para que cada uno caiga en su zona de 16 m.
	var partes: int = ceili((b - a) / ZONA)
	var paso: float = (b - a) / partes
	for i: int in partes:
		# El primer y el último tramo se alargan medio grosor para cerrar las esquinas.
		var s: float = a + paso * i - (grosor * 0.5 if i == 0 else 0.0)
		var e: float = a + paso * (i + 1) + (grosor * 0.5 if i == partes - 1 else 0.0)
		var largo: float = e - s
		var medio: float = (s + e) * 0.5
		var tam := Vector3(largo, alto, grosor) if horizontal else Vector3(grosor, alto, largo)
		var pos := Vector3(medio, y0 + alto * 0.5, fijo) if horizontal else Vector3(fijo, y0 + alto * 0.5, medio)
		caja_mat(tam, pos, mat, true)
		if zocalo:
			var tam_z: Vector3 = tam + (Vector3(0, 0, 0.04) if horizontal else Vector3(0.04, 0, 0))
			tam_z.y = 0.18
			caja_mat(tam_z, Vector3(pos.x, y0 + 0.09, pos.z), material(Color("3c3833")), false)


## Muro entre dos puntos cualesquiera del plano (para las esquinas en diagonal).
func muro_diagonal(a: Vector2, b: Vector2, alto: float, mat: Material, y0: float = 0.0, grosor: float = GROSOR) -> void:
	var largo: float = a.distance_to(b) + grosor
	var medio: Vector2 = (a + b) * 0.5
	var giro: float = -atan2(b.y - a.y, b.x - a.x)
	caja_mat(Vector3(largo, alto, grosor), Vector3(medio.x, y0 + alto * 0.5, medio.y), mat, true, giro)


## Losa horizontal (piso o techo) con huecos rectangulares. huecos: [[x0, z0, x1, z1], ...]
func losa(x0: float, z0: float, x1: float, z1: float, y_arriba: float, grosor: float, mat: Material, huecos: Array = [], solida: bool = true) -> void:
	var xs: Array = [x0, x1]
	var zs: Array = [z0, z1]
	for h: Array in huecos:
		xs.append_array([clampf(h[0], x0, x1), clampf(h[2], x0, x1)])
		zs.append_array([clampf(h[1], z0, z1), clampf(h[3], z0, z1)])
	xs.sort()
	zs.sort()
	for j: int in zs.size() - 1:
		var za: float = zs[j]
		var zb: float = zs[j + 1]
		if zb - za < 0.01:
			continue
		var inicio: float = NAN
		for i: int in xs.size():
			var libre: bool = false
			if i < xs.size() - 1 and xs[i + 1] - xs[i] > 0.01:
				var cx: float = (xs[i] + xs[i + 1]) * 0.5
				var cz: float = (za + zb) * 0.5
				libre = true
				for h: Array in huecos:
					if cx > h[0] and cx < h[2] and cz > h[1] and cz < h[3]:
						libre = false
						break
			if libre and is_nan(inicio):
				inicio = xs[i]
			elif not libre and not is_nan(inicio):
				_losa_rect(inicio, za, xs[i], zb, y_arriba, grosor, mat, solida)
				inicio = NAN


func _losa_rect(x0: float, z0: float, x1: float, z1: float, y_arriba: float, grosor: float, mat: Material, solida: bool) -> void:
	# Las losas grandes también se parten por zonas.
	var nx: int = maxi(1, ceili((x1 - x0) / ZONA))
	var nz: int = maxi(1, ceili((z1 - z0) / ZONA))
	var px: float = (x1 - x0) / nx
	var pz: float = (z1 - z0) / nz
	for i: int in nx:
		for j: int in nz:
			var tam := Vector3(px, grosor, pz)
			caja_mat(tam, Vector3(x0 + px * (i + 0.5), y_arriba - grosor * 0.5, z0 + pz * (j + 0.5)), mat, solida)


func suelo(x0: float, z0: float, x1: float, z1: float, color_o_mat: Variant, y: float = 0.005) -> void:
	var mat: Material = color_o_mat if color_o_mat is Material else material(color_o_mat as Color, 0.45)
	_losa_rect(x0, z0, x1, z1, y + 0.01, 0.02, mat, false)


func techo(x0: float, z0: float, x1: float, z1: float, y: float, color: Color) -> void:
	_losa_rect(x0, z0, x1, z1, y + 0.2, 0.2, material(color), false)


## Plano inclinado entre dos puntos (centros de los extremos de la cara de arriba).
func rampa(desde: Vector3, hasta: Vector3, ancho: float, mat: Material, grosor: float = 0.3) -> void:
	var dir: Vector3 = hasta - desde
	var largo: float = dir.length()
	var adelante: Vector3 = dir / largo
	var lado: Vector3 = Vector3.UP.cross(adelante).normalized()
	if lado.is_zero_approx():
		lado = Vector3.RIGHT
	var arriba: Vector3 = adelante.cross(lado).normalized()
	var b := Basis(lado, arriba, adelante)
	var centro: Vector3 = (desde + hasta) * 0.5 - arriba * grosor * 0.5
	caja_t(Vector3(ancho, grosor, largo), Transform3D(b, centro), mat, true)


## Tramo de escalera: escalones a la vista y una rampa invisible debajo para caminar.
func escalera(desde: Vector3, hasta: Vector3, ancho: float, mat: Material, alto_escalon: float = 0.18) -> void:
	var subida: float = hasta.y - desde.y
	var n: int = maxi(2, roundi(absf(subida) / alto_escalon))
	var plano := Vector3(hasta.x - desde.x, 0, hasta.z - desde.z)
	var huella: float = plano.length() / n
	var adelante: Vector3 = plano.normalized()
	var giro: float = atan2(adelante.x, adelante.z)
	for i: int in n:
		var y_top: float = desde.y + subida * (i + 1) / n
		var alto: float = y_top - minf(desde.y, hasta.y) + 0.05
		var c: Vector3 = desde + adelante * huella * (i + 0.5)
		var tam := Vector3(ancho, alto, huella)
		caja_t(tam, Transform3D(Basis(Vector3.UP, giro), Vector3(c.x, y_top - alto * 0.5, c.z)), mat, false)
	rampa(desde, hasta, ancho, null)


## Baranda de hierro: pasamanos, base y barrotes verticales entre dos puntos. Si
## los puntos están a distinta altura, la baranda sigue la pendiente (escaleras).
func baranda(a: Vector3, b: Vector3, mat: Material, alto: float = 1.0, paso: float = 0.14, solida: bool = true) -> void:
	var dir: Vector3 = b - a
	var largo: float = dir.length()
	if largo < 0.05:
		return
	var adelante: Vector3 = dir / largo
	var lado: Vector3 = Vector3.UP.cross(adelante).normalized()
	var arriba: Vector3 = adelante.cross(lado).normalized()
	var inclinada := Basis(lado, arriba, adelante)
	var vertical := Basis(Vector3.UP, atan2(dir.x, dir.z))
	var medio: Vector3 = (a + b) * 0.5
	caja_t(Vector3(0.06, 0.06, largo), Transform3D(inclinada, medio + Vector3.UP * alto), mat, false)
	caja_t(Vector3(0.05, 0.05, largo), Transform3D(inclinada, medio + Vector3.UP * 0.1), mat, false)
	var n: int = maxi(1, floori(largo / paso))
	for i: int in n + 1:
		var p: Vector3 = a + dir * (float(i) / n)
		caja_t(Vector3(0.025, alto, 0.025), Transform3D(vertical, p + Vector3.UP * alto * 0.5), mat, false)
	if solida:
		_solido(_forma_caja(Vector3(0.1, alto, largo)), Transform3D(inclinada, medio + Vector3.UP * alto * 0.5))


## Reja en arco: barrotes verticales con remate de medio punto. pos es el centro de
## la base; ancho y alto incluyen el arco. Mira hacia +z local girado por "giro".
func reja(pos: Vector3, giro: float, ancho: float, alto: float, mat: Material, paso: float = 0.13) -> void:
	var bas := Basis(Vector3.UP, giro)
	var r: float = ancho * 0.5
	var recto: float = alto - r
	var n: int = maxi(2, floori(ancho / paso))
	for i: int in n + 1:
		var x: float = -r + ancho * float(i) / n
		var h: float = recto + sqrt(maxf(r * r - x * x, 0.0))
		caja_t(Vector3(0.025, h, 0.025), Transform3D(bas, pos + bas * Vector3(x, h * 0.5, 0)), mat, false)
	for y: float in [0.05, recto * 0.5, recto]:
		caja_t(Vector3(ancho, 0.035, 0.03), Transform3D(bas, pos + Vector3.UP * y), mat, false)
	for k: int in 7:
		var a: float = PI * (k + 0.5) / 7.0
		var p: Vector3 = Vector3(cos(a) * r, recto + sin(a) * r, 0)
		caja_t(Vector3(r * PI / 7.0 + 0.02, 0.035, 0.03), Transform3D(bas * Basis(Vector3.BACK, a - PI * 0.5), pos + bas * p), mat, false)


## Arco de medio punto hecho de dovelas, para portadas y arcadas.
func arco(centro: Vector3, giro: float, radio: float, grosor: float, profundo: float, mat: Material, dovelas: int = 11) -> void:
	var bas := Basis(Vector3.UP, giro)
	for k: int in dovelas:
		var a: float = PI * (k + 0.5) / dovelas
		var p: Vector3 = Vector3(cos(a) * (radio + grosor * 0.5), sin(a) * (radio + grosor * 0.5), 0)
		var largo: float = (radio + grosor) * PI / dovelas + 0.02
		caja_t(Vector3(largo, grosor, profundo), Transform3D(bas * Basis(Vector3.BACK, a - PI * 0.5), centro + bas * p), mat, false)


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


## Foco de techo que alumbra hacia abajo. Al no apuntar hacia arriba no se cuela
## al piso de encima, y sin sombras cuesta muy poco.
func foco(pos: Vector3, energia: float = 3.0, rango: float = 4.7, angulo: float = 62.0, color: Color = Color("ffe6c4"), de_sala: bool = true) -> SpotLight3D:
	var l := SpotLight3D.new()
	l.position = pos
	l.rotation_degrees.x = -90.0
	l.light_color = color
	l.light_energy = energia
	l.spot_range = rango
	l.spot_angle = angulo
	l.spot_attenuation = 0.6
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
func panel_de_obra(slot: Array, ancho: float = 2.4, alto: float = 2.4) -> void:
	var giro: float = deg_to_rad(slot[2] as float)
	var frente := Vector3(sin(giro), 0.0, cos(giro))
	var pos := Vector3(slot[0], base_y(piso_de(slot, 3)) + 1.9, slot[1]) - frente * 0.025
	caja_mat(Vector3(ancho, alto, 0.04), pos, material(Color("ece7dd")), false, giro)


func banca(x: float, z: float, giro: float, y: float = 0.0) -> void:
	var escena: PackedScene = load("res://modelos/banca.glb")
	var b := escena.instantiate() as Node3D
	b.scale = Vector3(2.4, 1.42, 2.2)
	b.position = Vector3(x, y, z)
	b.rotation_degrees.y = giro
	add_child(b)
	var largo := Vector3(1.6, 0.45, 0.55) if is_zero_approx(fmod(giro, 180.0)) else Vector3(0.55, 0.45, 1.6)
	caja_mat(largo, Vector3(x, y + 0.225, z), null, true)


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
		var m := nodo as MeshInstance3D
		for s: int in m.mesh.get_surface_count():
			var original: Material = m.get_active_material(s)
			if original.resource_name == "White":
				var nuevo := original.duplicate() as BaseMaterial3D
				nuevo.albedo_color = color
				nuevo.metallic = 0.6
				nuevo.roughness = 0.3
				m.set_surface_override_material(s, nuevo)


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


## Cierra los lotes de mallas y calcula por dónde pueden caminar los guardias.
func hornear_navegacion(celda: float = 0.25) -> void:
	terminar_lotes()
	var nav := NavigationMesh.new()
	nav.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav.geometry_collision_mask = Juego.CAPA_MUNDO
	nav.cell_size = celda
	nav.cell_height = 0.25
	nav.agent_radius = 0.5
	nav.agent_height = 2.0
	nav.agent_max_climb = 0.25
	nav.agent_max_slope = 40.0
	navigation_mesh = nav
	bake_navigation_mesh(false)
