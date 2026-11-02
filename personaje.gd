class_name Personaje
extends CharacterBody3D

@export var camara: Camera3D
@export var speed_caminar: float = 2.5
@export var speed_correr: float = 2.5
@export_enum("Ninguna", "Avanzar 60 cuadros", "Avanzar con la acción 60 cuadros", "Diagonal W+D 60 cuadros") var Prueba: String = "Ninguna"
@export var AccionPrueba: String = ""

# Los tres enchufes para la Tarea B (María Sofía)
var multiplicador: float = 1.0
var empuje: Vector3 = Vector3.ZERO
var accion: String = ""

@onready var anim: AnimationPlayer = $Modelo/AnimationPlayer if has_node("Modelo/AnimationPlayer") else null

func _physics_process(delta: float) -> void:
	velocity += get_gravity() * delta
	
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var entrada: Vector3 = Vector3(input_dir.x, 0.0, input_dir.y)
	
	# Rotación horizontal de la cámara (corrige la diagonal torcida)
	var giro_cam: float = camara.global_rotation.y if camara else 0.0
	var direction: Vector3 = entrada.rotated(Vector3.UP, giro_cam).normalized()
	
	var corre: bool = Input.is_action_pressed("correr")
	var speed: float = speed_correr if corre else speed_caminar
	
	velocity.x = direction.x * speed * multiplicador + empuje.x
	velocity.z = direction.z * speed * multiplicador + empuje.z
	
	if direction.length() > 0.0:
		basis = Basis.looking_at(direction)
	
	if accion != "":
		if anim: anim.play(accion)
	elif direction.length() > 0.0 and corre:
		if anim: anim.play("sprint")
	elif direction.length() > 0.0:
		if anim: anim.play("walk")
	else:
		if anim: anim.play("idle")
	
	move_and_slide()
	_prueba()

# Bloque de pruebas automáticas del Taller 7 - Nivel 1
var _cuadro_prueba: int = 0
func _prueba() -> void:
	if Prueba == "Ninguna":
		return
	_cuadro_prueba += 1
	var rap: float = Vector2(velocity.x, velocity.z).length()
	var pos: Vector3 = global_position.snappedf(0.01)
	
	match Prueba:
		"Avanzar 60 cuadros":
			if _cuadro_prueba <= 60:
				Input.action_press("move_up")
			else:
				Input.action_release("move_up")
			if _cuadro_prueba in [1, 30, 60]:
				print("cuadro ", _cuadro_prueba, ": pos ", pos, " · rapidez ", snappedf(rap, 0.01))
		"Avanzar con la acción 60 cuadros":
			if _cuadro_prueba <= 60:
				Input.action_press("move_up")
				if AccionPrueba != "":
					Input.action_press(AccionPrueba)
			else:
				Input.action_release("move_up")
				if AccionPrueba != "":
					Input.action_release(AccionPrueba)
			if _cuadro_prueba in [1, 30, 60]:
				print("cuadro ", _cuadro_prueba, ": pos ", pos, " · rapidez ", snappedf(rap, 0.01))
		"Diagonal W+D 60 cuadros":
			if _cuadro_prueba <= 60:
				Input.action_press("move_up")
				Input.action_press("move_right")
			else:
				Input.action_release("move_up")
				Input.action_release("move_right")
			if _cuadro_prueba in [1, 30, 60]:
				print("cuadro ", _cuadro_prueba, ": pos ", pos, " · rapidez ", snappedf(rap, 0.01))
