extends SceneTree
## Prueba automática de la misión. El cuerpo se carga aparte porque con -s Godot
## compila este archivo antes de registrar el autoload Juego.
## Ejecutar:  Godot_console --headless --path . --fixed-fps 60 -s tests/prueba_mision.gd
## Capturas:  Godot_console --path . --fixed-fps 60 -s tests/prueba_mision.gd -- capturas


func _initialize() -> void:
	_iniciar.call_deferred()


func _iniciar() -> void:
	var cuerpo: Script = load("res://tests/prueba_cuerpo.gd")
	root.add_child(cuerpo.new())
