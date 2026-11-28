extends Node

@export var tecla: String = "interactuar"
@export var alcance: float = 1.5
@export var tiempo_necesario: float = 1.5

@onready var pj = get_parent()

var progreso: float = 0.0
var actual: Node = null

# Clase 2: si te golpean mientras comes, pierdes lo que llevabas.
func _ready() -> void:
	var salud = pj.get_node_or_null("Salud") if pj else null
	if salud != null:
		salud.golpeado.connect(_al_ser_golpeado)

func _al_ser_golpeado(_danio) -> void:
	if progreso > 0.0:
		progreso = 0.0
		actual = null
		Sentidos.aviso(get_tree(), "¡Te interrumpieron mientras comías!", Color(1.0, 0.6, 0.2))

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
	
	var antes = progreso
	progreso += delta / maxf(0.01, tiempo_necesario)
	
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
		if obj.is_queued_for_deletion():
			continue
		if d <= alcance and (mejor == null or d < distancia_a(mejor)):
			mejor = obj
	return mejor

func distancia_a(obj: Node) -> float:
	if not pj or not obj is Node3D:
		return 9999.0
	var a = Vector2(pj.global_position.x, pj.global_position.z)
	var b = Vector2(obj.global_position.x, obj.global_position.z)
	return a.distance_to(b)
