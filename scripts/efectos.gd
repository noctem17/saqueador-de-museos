class_name Efectos
extends RefCounted
## Sangre, chispas, trazadoras y charcos. Todo se limpia solo.


static func _particulas(padre: Node, pos: Vector3, direccion: Vector3, color: Color, cantidad: int, velocidad: float, vida: float) -> void:
	var p := CPUParticles3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.03
	esfera.height = 0.06
	esfera.radial_segments = 6
	esfera.rings = 3
	p.mesh = esfera
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p.material_override = mat
	p.amount = cantidad
	p.one_shot = true
	p.explosiveness = 0.95
	p.lifetime = vida
	p.direction = direccion
	p.spread = 35.0
	p.initial_velocity_min = velocidad * 0.4
	p.initial_velocity_max = velocidad
	p.gravity = Vector3.DOWN * 9.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.5
	padre.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)


static func sangre(padre: Node, pos: Vector3, direccion: Vector3, fuerte: bool) -> void:
	_particulas(padre, pos, direccion, Color("b00d0d"), 60 if fuerte else 30, 4.5 if fuerte else 3.0, 0.7)


static func chispa(padre: Node, pos: Vector3, normal: Vector3) -> void:
	_particulas(padre, pos, normal, Color("e8d9a0"), 8, 3.0, 0.25)
	_marca(padre, pos, normal, 0.035, Color("1a1a1a"), 25.0)


## Mancha circular pegada a una superficie.
static func _marca(padre: Node, pos: Vector3, normal: Vector3, radio: float, color: Color, duracion: float) -> void:
	var m := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = radio
	disco.bottom_radius = radio
	disco.height = 0.004
	disco.radial_segments = 10
	m.mesh = disco
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.4
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(m)
	m.global_position = pos + normal * 0.008
	if not normal.cross(Vector3.UP).is_zero_approx():
		m.look_at(m.global_position + normal.cross(Vector3.UP), normal)
	if duracion > 0.0:
		padre.get_tree().create_timer(duracion).timeout.connect(m.queue_free)


## Charco que crece bajo un cuerpo.
static func charco(padre: Node, pos: Vector3) -> void:
	var m := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = 0.75
	disco.bottom_radius = 0.75
	disco.height = 0.004
	disco.radial_segments = 14
	m.mesh = disco
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("3f0505")
	mat.roughness = 0.2
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.scale = Vector3(0.1, 1.0, 0.1)
	padre.add_child(m)
	m.global_position = Vector3(pos.x, 0.012, pos.z)
	var tween: Tween = m.create_tween()
	tween.tween_interval(0.4)
	tween.tween_property(m, "scale", Vector3(1.0, 1.0, 1.25), 2.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Línea de luz breve para ver de dónde vino un disparo.
static func trazadora(padre: Node, desde: Vector3, hasta: Vector3) -> void:
	var largo: float = desde.distance_to(hasta)
	if largo < 0.3:
		return
	var m := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(0.012, 0.012, largo)
	m.mesh = caja
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("ffd48a")
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(m)
	m.global_position = (desde + hasta) * 0.5
	m.look_at(hasta)
	padre.get_tree().create_timer(0.05).timeout.connect(m.queue_free)
