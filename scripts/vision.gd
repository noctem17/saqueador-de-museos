class_name Vision
extends RefCounted
## Línea de visión compartida por guardias y cámaras.
## Revisa cabeza y pecho: asomarse tras un muro deja ver solo la cabeza.


static func ve_jugador(espacio: PhysicsDirectSpaceState3D, ojo: Vector3, adelante: Vector3,
		jugador: Jugador, alcance: float, medio_angulo: float) -> bool:
	if not jugador.dentro:
		return false   # En la calle o en los jardines nadie sospecha de él.
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


## Agachado se es más difícil de ver, en la penumbra también, y de lejos se tarda
## más en reconocer a alguien. Agachado y en penumbra, un guardia te ve a ~4,5 m.
static func alcance_real(alcance: float, jugador: Jugador) -> float:
	var factor: float = 0.62 if jugador.agachado else 1.0
	if jugador.en_sombra:
		factor *= 0.55
	return alcance * factor


## Cuánta luz de las lámparas le llega a un punto (0 = penumbra). Solo cuenta las
## que están en el mismo piso y encima del punto: un foco del piso de arriba no
## atraviesa la losa.
static func luz_en(punto: Vector3, luces: Array[Light3D], alto_piso: float) -> float:
	var total: float = 0.0
	for l: Light3D in luces:
		if not is_instance_valid(l) or not l.visible:
			continue
		var d: Vector3 = punto - l.global_position
		if d.y > 0.5 or d.y < -alto_piso:
			continue
		var distancia: float = d.length()
		if l is SpotLight3D:
			var foco := l as SpotLight3D
			if distancia > foco.spot_range:
				continue
			var eje: Vector3 = -foco.global_basis.z
			if rad_to_deg(eje.angle_to(d)) > foco.spot_angle * 0.8:
				continue
			total += 1.0 - distancia / foco.spot_range
		elif l is OmniLight3D:
			var bombillo := l as OmniLight3D
			if distancia < bombillo.omni_range:
				total += 1.0 - distancia / bombillo.omni_range
	return total


static func ritmo(distancia: float, alcance: float) -> float:
	return lerpf(0.8, 0.22, clampf(distancia / alcance, 0.0, 1.0))
