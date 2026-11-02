extends RefCounted
## Coleccionable, Terminal, Vehiculo y PoloEscondido viven aquí porque son pequeños.
## Se usan como Otros.Coleccionable, Otros.Terminal, etc.


class Coleccionable:
	extends Interactuable
	var datos: Dictionary = {}
	var _visual: MeshInstance3D

	func configurar(info: Dictionary) -> void:
		datos = info
		duracion = 0.5
		agregar_colision(Vector3(0.5, 0.4, 0.5), Vector3(0, 0.2, 0))
		_visual = MeshInstance3D.new()
		var mat := StandardMaterial3D.new()
		mat.emission_enabled = true
		mat.emission_energy_multiplier = 0.5
		var forma: String = info["forma"]
		if forma == "moneda":
			var disco := CylinderMesh.new()
			disco.top_radius = 0.09
			disco.bottom_radius = 0.09
			disco.height = 0.018
			_visual.mesh = disco
			mat.albedo_color = Color("c9a227")
			mat.emission = Color("6b5310")
			mat.metallic = 0.9
			mat.roughness = 0.35
			_visual.rotation.x = PI / 2.0
		else:
			var papel := BoxMesh.new()
			papel.size = Vector3(0.3, 0.005, 0.16) if forma == "billete" else Vector3(0.21, 0.005, 0.29)
			_visual.mesh = papel
			mat.albedo_color = Color("8fae7f") if forma == "billete" else Color("e6dcc0")
			mat.emission = Color("3a4433") if forma == "billete" else Color("4f4a3c")
		_visual.material_override = mat
		_visual.position.y = 0.2
		add_child(_visual)

	func _process(delta: float) -> void:
		_visual.rotate_y(delta * 1.2)

	func prompt(_j: Jugador) -> String:
		return "[F] Guardar en el bolso: %s" % datos["nombre"]

	func completar(_j: Jugador) -> void:
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
		agregar_colision(Vector3(0.8, 1.1, 0.8), Vector3(0, 0.55, 0))
		add_child(Muneco.crear(Color("3b2417"), Color("2f3a4a"), Color("1c1c1f"), true))

	func prompt(_j: Jugador) -> String:
		return "[F] Sacar a Polo"

	func completar(j: Jugador) -> void:
		j.polo_rescatado = true
		rescatado.emit()
		queue_free()
