extends Node

@export var tecla: String = "interactuar"
@export var alcance: float = 1.5

@onready var pj = get_parent()

func _physics_process(_delta: float) -> void:
	# Verificación periódica del Nivel 1 (cada medio segundo)
	if Engine.get_physics_frames() % 30 == 0:
		var obj_global = mas_cercano_global()
		if obj_global == null:
			print("no hay nada en el grupo interactivos")
		else:
			var d_glob = snappedf(distancia_a(obj_global), 0.01)
			print("más cercano: ", obj_global.name, " a ", d_glob, " m")
	
	# Verificación con alcance al presionar E (Nivel 2)
	if Input.is_action_just_pressed(tecla):
		var obj = mas_cercano()
		if obj == null:
			print("nada a menos de ", alcance, " m")
		else:
			var d = snappedf(distancia_a(obj), 0.01)
			print("interactúa con ", obj.name, " a ", d, " m")

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
