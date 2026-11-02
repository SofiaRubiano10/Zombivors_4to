extends Node

@export var tecla: String = "interactuar"
@export var alcance: float = 1.5
@export var tiempo_necesario: float = 1.5

@onready var pj = get_parent()

var progreso: float = 0.0
var actual: Node = null

func _ready() -> void:
	call_deferred("_verificar_mas_cercano_inicial")

func _verificar_mas_cercano_inicial() -> void:
	var obj_global = mas_cercano_global()
	if obj_global == null:
		print("no hay nada en el grupo interactivos")
	else:
		var d = snappedf(distancia_a(obj_global), 0.01)
		print("más cercano: ", obj_global.name, " a ", d, " m")

func _physics_process(delta: float) -> void:
	# Verificación de pulsación de tecla única (Nivel 2)
	if Input.is_action_just_pressed(tecla):
		var obj_inmediato = mas_cercano()
		if obj_inmediato == null:
			print("nada a menos de ", alcance, " m")
		else:
			var d = snappedf(distancia_a(obj_inmediato), 0.01)
			print("interactúa con ", obj_inmediato.name, " a ", d, " m")
	
	# Interacción sostenida / mantener para completar (Nivel 3)
	var obj = mas_cercano()
	if not Input.is_action_pressed(tecla) or obj == null:
		progreso = 0.0
		actual = null
		return
	
	if obj != actual: # Cambió de objeto: se reinicia el progreso
		actual = obj
		progreso = 0.0
	
	var antes = progreso
	progreso += delta / maxf(0.01, tiempo_necesario)
	
	# Imprime retroalimentación visual en cada cuarto de progreso (25%, 50%, 75%)
	if int(progreso * 4) > int(antes * 4) and progreso < 0.999:
		print(obj.name, ": ", int(progreso * 4) * 25, " %")
	
	# Completado al 100%
	if progreso >= 0.999:
		print("completado: ", obj.name)
		if obj.has_method("usar"):
			obj.usar()
		progreso = 0.0

func mas_cercano_global() -> Node:
	var mejor: Node = null
	for obj in get_tree().get_nodes_in_group("interactivos"):
		if mejor == null or distancia_a(obj) < distancia_a(mejor):
			mejor = obj
	return mejor

func mas_cercano() -> Node:
	var mejor: Node = null
	for obj in get_tree().get_nodes_in_group("interactivos"):
		var d = distancia_a(obj)
		if d <= alcance and (mejor == null or d < distancia_a(mejor)):
			mejor = obj
	return mejor

func distancia_a(obj: Node) -> float:
	if not pj or not obj is Node3D:
		return 9999.0
	var a = Vector2(pj.global_position.x, pj.global_position.z)
	var b = Vector2(obj.global_position.x, obj.global_position.z)
	return a.distance_to(b)
