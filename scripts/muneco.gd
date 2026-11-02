class_name Muneco
extends RefCounted
## Figura humana provisional hecha con primitivas. Se reemplazará por modelos reales
## sin tocar la lógica: solo cambia lo que devuelve crear().


static func crear(piel: Color, ropa: Color, pantalon: Color, agachado: bool = false) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "Muneco"
	var escala_y: float = 0.62 if agachado else 1.0
	raiz.scale.y = escala_y
	_parte(raiz, _capsula(0.13, 0.85), Vector3(-0.13, 0.43, 0), pantalon, "PiernaI")
	_parte(raiz, _capsula(0.13, 0.85), Vector3(0.13, 0.43, 0), pantalon, "PiernaD")
	_parte(raiz, _capsula(0.26, 0.75), Vector3(0, 1.15, 0), ropa, "Torso")
	_parte(raiz, _capsula(0.09, 0.72), Vector3(-0.34, 1.13, 0), ropa, "BrazoI")
	_parte(raiz, _capsula(0.09, 0.72), Vector3(0.34, 1.13, 0), ropa, "BrazoD")
	var cabeza := SphereMesh.new()
	cabeza.radius = 0.15
	cabeza.height = 0.32
	_parte(raiz, cabeza, Vector3(0, 1.68, 0), piel, "Cabeza")
	return raiz


static func _capsula(radio: float, alto: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = radio
	c.height = alto
	return c


static func _parte(raiz: Node3D, malla: Mesh, pos: Vector3, color: Color, nombre: String) -> void:
	var m := MeshInstance3D.new()
	m.name = nombre
	m.mesh = malla
	m.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	m.material_override = mat
	raiz.add_child(m)


## Balanceo simple de piernas y brazos al caminar.
static func animar(raiz: Node3D, fase: float, intensidad: float) -> void:
	var angulo: float = sin(fase) * 0.55 * intensidad
	for par: Array in [["PiernaI", angulo], ["PiernaD", -angulo], ["BrazoI", -angulo], ["BrazoD", angulo]]:
		var parte := raiz.get_node_or_null(par[0] as String) as Node3D
		if parte:
			parte.rotation.x = par[1]
