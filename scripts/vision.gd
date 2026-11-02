class_name Vision
extends RefCounted
## Línea de visión compartida por guardias y cámaras.
## Revisa cabeza y pecho: asomarse tras un muro deja ver solo la cabeza.


static func ve_jugador(espacio: PhysicsDirectSpaceState3D, ojo: Vector3, adelante: Vector3,
		jugador: Jugador, alcance: float, medio_angulo: float) -> bool:
	var a_jugador: Vector3 = jugador.punto_pecho() - ojo
	if a_jugador.length() > alcance:
		return false
	if adelante.angle_to(a_jugador.normalized()) > medio_angulo:
		return false
	for punto: Vector3 in [jugador.punto_cabeza(), jugador.punto_pecho()]:
		var q := PhysicsRayQueryParameters3D.create(ojo, punto, Juego.CAPA_MUNDO)
		if espacio.intersect_ray(q).is_empty():
			return true
	return false


## Agachado se es más difícil de ver, y de lejos se tarda más en reconocer a alguien.
static func alcance_real(alcance: float, jugador: Jugador) -> float:
	return alcance * (0.62 if jugador.agachado else 1.0)


static func ritmo(distancia: float, alcance: float) -> float:
	return lerpf(2.2, 0.55, clampf(distancia / alcance, 0.0, 1.0))
