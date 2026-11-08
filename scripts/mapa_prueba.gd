class_name MapaPrueba
extends Mapa
## Mapa de prueba, NO es el museo real. Queda de respaldo: la misión usa
## MapaMuseoNacional, salvo que Mision.USAR_MAPA_PRUEBA esté en true.
##
##        z-24  ┌───────────────────────────┬────────┬────────┐
##              │        SALA GRANDE         DEPÓSITO│SEGURIDAD│
##        z-6   ├─────┬ ┬──────────┬ ┬───────┼─┬ ─────┬ ┬─────┤
##              │ SALA A    VESTÍBULO      SALA B             │
##        z12   └──────────────┬ ┬────────────────────────────┘
##                       PARQUEADERO (camioneta)

const ALTO: float = 4.0

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
	[-1.8, 1.1, 5.4], [1.9, 1.1, 5.6], [20.9, 0.8, -22.5], [-12.0, 0.47, 6.5], [18.0, 0.47, 7.0],
	[-8.0, 0.47, -14.5], [15.3, 0.75, -12.0], [15.3, 1.45, -18.0], [10.2, 0.9, -8.5],
	[-23.3, 0.01, -6.9], [-1.5, 0.01, -11.9], [23.3, 0.01, 11.3],
]
const BANCAS: Array = [[-12.0, 6.5, 0.0], [18.0, 7.0, 0.0], [-8.0, -14.5, 90.0]]
const CAMARAS: Array = [
	[-23.3, 3.6, 11.3, -45.0], [7.3, 3.6, -5.3, 135.0], [23.3, 3.6, 11.3, 45.0],
	[-23.3, 3.6, -23.3, -135.0], [7.3, 3.6, -23.3, 135.0],
]
const PATRULLAS: Array = [
	[[0.0, 8.0], [-16.0, 8.0], [-20.0, -2.0], [-12.0, -2.0], [0.0, -2.0]],
	[[-19.0, -9.0], [-19.0, -21.0], [-8.0, -21.0], [4.0, -21.0], [4.0, -9.0], [-8.0, -9.0]],
	[[20.0, 9.0], [11.0, -1.0], [12.0, -12.0], [12.0, -1.0], [20.0, -1.0], [20.0, -12.0], [20.0, -1.0]],
]


func _init() -> void:
	slots_pared = SLOTS_PARED
	slots_pedestal = SLOTS_PEDESTAL
	slots_coleccionable = SLOTS_COLECCIONABLE
	camaras = CAMARAS
	patrullas = PATRULLAS
	spawn_polo = Vector3(0, 0.1, 19.0)
	spawn_mostro = Vector3(0, 0.1, 15.0)
	spawn_policia = [Vector3(-22, 0.1, -9), Vector3(4, 0.1, 10)]
	pos_terminal = Vector3(21.5, 1.05, -22.6)
	pos_camioneta = Vector3(9.0, 0.0, 19.5)
	giro_camioneta = -90.0
	fin_huida = Vector3(-78.0, 0.0, 19.5)
	plano_huida = Vector3(-20.0, 1.6, 26.0)
	punto_prueba = Vector3(-3, 0.1, 2)
	punto_lejano = Vector3(-19, 0, -21)


func construir() -> void:
	var pared: StandardMaterial3D = material(Color("e4dfd5"))
	caja_mat(Vector3(52, 1, 62), Vector3(0, -0.5, 2), null, true)
	for s: Array in SUELOS:
		suelo(s[0], s[1], s[2], s[3], Color(s[4] as String))
	suelo(-26.0, 12.0, 26.0, 33.0, Color("2b2c30"))
	techo(-24.0, -24.0, 24.0, 12.0, ALTO, Color("c4c0b8"))
	for m: Array in MUROS_H:
		muro(true, m[0], m[1], m[2], m[3], ALTO, pared, true)
	for m: Array in MUROS_V:
		muro(false, m[0], m[1], m[2], m[3], ALTO, pared, true)
	for p: Array in PANELES:
		caja(Vector3(p[2], 3.0, p[3]), Vector3(p[0], 1.5, p[1]), Color("d9d3c7"))

	# Mostrador del vestíbulo, buena cobertura al agacharse.
	caja(Vector3(5.0, 1.1, 0.8), Vector3(0, 0.55, 5.5), Color("4a3524"))
	caja(Vector3(2.0, 0.8, 0.8), Vector3(21.5, 0.4, -22.5), Color("23262b"))
	for slot: Array in SLOTS_PEDESTAL:
		caja(Vector3(0.9, 1.0, 0.9), Vector3(slot[0], 0.5, slot[1]), Color("efeae0"))
	_muebles()
	_parqueadero()
	for l: Array in LUCES:
		luz(Vector3(l[0], 3.3, l[1]), 2.2, 16.0, true)
	for p: Vector2 in [Vector2(0, 15), Vector2(-14, 26), Vector2(14, 26)]:
		luz(Vector3(p.x, 6.0, p.y), 1.1, 16.0, false, Color("ffbf7a"), false)
	ambiente(Color("0b0e16"), Color("6c7890"), 0.4)
	hornear_navegacion()


func _parqueadero() -> void:
	var gris := Color("36383c")
	caja(Vector3(52, 3, 0.4), Vector3(0, 1.5, 33), gris)
	# Muro oeste con la salida a la calle (z entre 17 y 22).
	caja(Vector3(0.4, 3, 5), Vector3(-26, 1.5, 14.5), gris)
	caja(Vector3(0.4, 3, 11), Vector3(-26, 1.5, 27.5), gris)
	caja_mat(Vector3(0.4, 3, 5), Vector3(-26, 1.5, 19.5), null, true)
	suelo(-90.0, 12.0, -26.0, 27.0, Color("1f2024"))
	var pluma := Node3D.new()
	pluma.name = "Pluma"
	pluma.position = Vector3(-25.8, 1.1, 17.2)
	add_child(pluma)
	var tubo := MeshInstance3D.new()
	var caja_tubo := BoxMesh.new()
	caja_tubo.size = Vector3(0.1, 0.1, 4.8)
	tubo.mesh = caja_tubo
	tubo.position.z = 2.4
	tubo.material_override = material(Color("c8352b"))
	pluma.add_child(tubo)
	caja(Vector3(0.4, 3, 21), Vector3(26, 1.5, 22.5), gris)
	for i: int in 5:
		caja(Vector3(0.12, 0.01, 5.0), Vector3(-18.0 + i * 6.0, 0.015, 26.0), Color("c9c6b8"), false)
	carro(Vector3(-21, 0, 25), Color("3f5a73"))
	carro(Vector3(-9, 0, 25), Color("6d6f73"))


func _muebles() -> void:
	for b: Array in BANCAS:
		banca(b[0], b[1], b[2])
	# Depósito: estantes contra el muro y un par de cajas.
	var madera := Color("5a4632")
	for z: float in [-12.0, -18.0]:
		caja(Vector3(0.6, 2.2, 0.08), Vector3(15.35, 1.1, z - 2.0), madera)
		caja(Vector3(0.6, 2.2, 0.08), Vector3(15.35, 1.1, z + 2.0), madera)
		for y: float in [0.7, 1.4, 2.1]:
			caja(Vector3(0.6, 0.05, 4.0), Vector3(15.35, y, z), madera)
	caja(Vector3(1.2, 0.9, 1.0), Vector3(10.2, 0.45, -8.5), Color("7a5f42"))
	caja(Vector3(0.9, 0.7, 0.9), Vector3(10.1, 0.35, -21.0), Color("6a5238"))
