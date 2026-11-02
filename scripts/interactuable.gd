class_name Interactuable
extends StaticBody3D
## Cualquier cosa que se pueda usar manteniendo F. El jugador lo detecta con un rayo.

var duracion: float = 1.0


func _init() -> void:
	collision_layer = Juego.CAPA_INTERACTUABLE
	collision_mask = 0


func disponible(_j: Jugador) -> bool:
	return true


func prompt(_j: Jugador) -> String:
	return ""


func completar(_j: Jugador) -> void:
	pass


func agregar_colision(tam: Vector3, centro: Vector3 = Vector3.ZERO) -> void:
	var forma := BoxShape3D.new()
	forma.size = tam
	var col := CollisionShape3D.new()
	col.shape = forma
	col.position = centro
	add_child(col)
