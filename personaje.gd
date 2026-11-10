class_name Personaje
extends CharacterBody3D

enum Estado { QUIETO, CAMINAR, CORRER, COMIENDO }
const RUIDO = [0.0, 1.0, 3.0, 0.0] # metros de propagación sonora por estado

@export var camara: Camera3D
@export var speed_caminar: float = 2.5
@export var speed_correr: float = 2.5
@export var tiempo_arranque: float = 0.5
@export_enum("Ninguna", "Avanzar 60 cuadros", "Avanzar 60 y soltar", "Avanzar y la acción desde el cuadro 30", "Mantener la acción 2 s", "Avanzar con la acción 60 cuadros", "Diagonal W+D 60 cuadros") var Prueba: String = "Ninguna"
@export var AccionPrueba: String = ""

# Los tres enchufes del personaje (los modifican nodos hijos como Interactuar)
var multiplicador: float = 1.0
var empuje: Vector3 = Vector3.ZERO
var accion: String = ""

# Variables internas de movimiento y estado
var avance: Vector3 = Vector3.ZERO
var estado: Estado = Estado.QUIETO
var ruido: float = 0.0

# La salud y la descomposición viven en el nodo hijo Salud (salud.gd).

@onready var anim: AnimationPlayer = $Modelo/AnimationPlayer if has_node("Modelo/AnimationPlayer") else null

func _physics_process(delta: float) -> void:
	velocity += get_gravity() * delta
	
	# Obtención de entrada direccional
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var entrada: Vector3 = Vector3(input_dir.x, 0.0, input_dir.y)
	
	# Rotación horizontal relativa a la orientación de la cámara (diagonal corregida)
	var giro_cam: float = camara.global_rotation.y if camara else 0.0
	var direction: Vector3 = entrada.rotated(Vector3.UP, giro_cam).normalized()
	
	var corre: bool = Input.is_action_pressed("correr")
	var speed: float = speed_correr if corre else speed_caminar
	var objetivo: Vector3 = direction * speed * multiplicador
	var paso: float = (speed / maxf(0.05, tiempo_arranque)) * delta
	avance = avance.move_toward(objetivo, paso)
	
	velocity.x = avance.x + empuje.x
	velocity.z = avance.z + empuje.z
	empuje = empuje.move_toward(Vector3.ZERO, 12.0 * delta)
	
	# Orientar el modelo hacia la dirección de avance
	if direction.length() > 0.0:
		basis = Basis.looking_at(direction)
	
	move_and_slide()
	
	# Máquina de estados con actualización de ruido
	var antes: Estado = estado
	estado = elegir_estado()
	ruido = RUIDO[estado]
	if estado != antes:
		print("estado ", Estado.keys()[estado], " · ruido ", ruido, " m")
	
	animar()
	_prueba()

func elegir_estado() -> Estado:
	if accion == "pick-up":
		return Estado.COMIENDO
	if not is_on_floor():
		return Estado.QUIETO
	var rapidez: float = Vector2(velocity.x, velocity.z).length()
	if rapidez < 0.1:
		return Estado.QUIETO
	if rapidez > speed_caminar + 0.1:
		return Estado.CORRER
	return Estado.CAMINAR

func animar() -> void:
	if not anim:
		return
	if accion != "":
		anim.play(accion)
		return
	match estado:
		Estado.QUIETO:
			anim.play("idle")
		Estado.CAMINAR:
			anim.play("walk")
		Estado.CORRER:
			anim.play("sprint")
		Estado.COMIENDO:
			anim.play("crouch")

# Bloque de pruebas automatizadas del taller
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
			if _cuadro_prueba in [1, 10, 15, 30, 60]:
				print("cuadro ", _cuadro_prueba, ": pos ", pos, " · rapidez ", snappedf(rap, 0.01))
		"Avanzar 60 y soltar":
			if _cuadro_prueba <= 60:
				Input.action_press("move_up")
			else:
				Input.action_release("move_up")
			if _cuadro_prueba in [60, 61, 65, 70, 75, 80, 90]:
				print("cuadro ", _cuadro_prueba, ": pos ", pos, " · rapidez ", snappedf(rap, 0.01))
		"Avanzar y la acción desde el cuadro 30":
			if _cuadro_prueba <= 90:
				Input.action_press("move_up")
			if _cuadro_prueba >= 30 and _cuadro_prueba <= 90:
				if AccionPrueba != "":
					Input.action_press(AccionPrueba)
			if _cuadro_prueba in [30, 31, 35, 40, 60, 90]:
				print("cuadro ", _cuadro_prueba, ": pos ", pos, " · rapidez ", snappedf(rap, 0.01))
		"Mantener la acción 2 s":
			if AccionPrueba != "" and _cuadro_prueba <= 120:
				Input.action_press(AccionPrueba)
			if _cuadro_prueba in [1, 2, 20, 60, 90, 92, 120]:
				print("cuadro ", _cuadro_prueba, ": acción mantenida...")
		"Diagonal W+D 60 cuadros":
			if _cuadro_prueba <= 60:
				Input.action_press("move_up")
				Input.action_press("move_right")
			else:
				Input.action_release("move_up")
				Input.action_release("move_right")
			if _cuadro_prueba in [30, 60]:
				print("cuadro ", _cuadro_prueba, ": pos ", pos, " · rapidez ", snappedf(rap, 0.01))
