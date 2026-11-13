extends Node

@export var tecla: String = "interactuar"
@export var alcance: float = 1.5
# Lo que se usa si el objeto no dice cuánto tarda (tiempo_comer).
@export var tiempo_necesario: float = 1.5

@onready var pj = get_parent()

var progreso: float = 0.0
var actual: Node = null

func _physics_process(delta: float) -> void:
	# Mantener la tecla junto a un interactivo hasta completar
	var obj = mas_cercano()
	if not Input.is_action_pressed(tecla) or obj == null:
		if progreso > 0.0 and pj:
			pj.multiplicador = 1.0
			pj.accion = ""
		progreso = 0.0
		actual = null
		return
	
	if obj != actual: # Cambió de objeto: se reinicia el progreso
		actual = obj
		progreso = 0.0
	
	if pj:
		pj.multiplicador = 0.0
		pj.accion = "pick-up"
	
	# Cada alimento dice cuánto tarda en comerse: la carroña es rápida, la carne no.
	var tiempo: float = obj.tiempo_comer if "tiempo_comer" in obj else tiempo_necesario
	var antes = progreso
	progreso += delta / maxf(0.01, tiempo)
	
	# Imprime retroalimentación visual en cada cuarto de progreso (25%, 50%, 75%)
	if int(progreso * 4) > int(antes * 4) and progreso < 0.999:
		print(obj.name, ": ", int(progreso * 4) * 25, " %")
	
	# Completado al 100%
	if progreso >= 0.999:
		print("completado: ", obj.name)
		if pj:
			pj.multiplicador = 1.0
			pj.accion = ""
		if obj.has_method("usar"):
			obj.usar()
		progreso = 0.0
		actual = null

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
