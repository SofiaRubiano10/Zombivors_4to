extends Camera3D

@export var objetivo: Node3D
@export var distancia: Vector3 = Vector3(6, 8, 6)
@export var suavizado: float = 2.5
@export var limite_min: Vector2 = Vector2(-14, -14) # x y z mínimas del mapa
@export var limite_max: Vector2 = Vector2(14, 14)   # x y z máximas del mapa

func _ready() -> void:
	top_level = true
	if objetivo:
		# Se orienta UNA vez en _ready(), mirando al objetivo desde la distancia inicial
		look_at_from_position(objetivo.global_position + distancia, objetivo.global_position)

func _physics_process(delta: float) -> void:
	if not objetivo:
		return
	
	# Clamp al foco de seguimiento para que la vista respete los bordes del mapa
	var foco: Vector3 = objetivo.global_position
	foco.x = clamp(foco.x, limite_min.x, limite_max.x)
	foco.z = clamp(foco.z, limite_min.y, limite_max.y)
	
	var destino: Vector3 = foco + distancia
	global_position = global_position.lerp(destino, suavizado * delta)
