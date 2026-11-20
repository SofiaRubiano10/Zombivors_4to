extends Camera3D

# Cámara diagonal que sigue al zombi.
# Feedback del profesor: proyección ortogonal en vez de perspectiva. En ortogonal
# los objetos no se achican con la distancia y los muros se ven paralelos, como en
# un tablero; size (en la escena, 13 m) es el alto del mundo que cabe en pantalla.

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
		# Arranca ya encima del zombi: sin esto se desliza desde el centro del mapa.
		global_position = foco_de(objetivo.global_position) + distancia

func _physics_process(delta: float) -> void:
	if not objetivo:
		return
	
	# Clamp al foco de seguimiento para que la vista respete los bordes del mapa
	var destino: Vector3 = foco_de(objetivo.global_position) + distancia
	global_position = global_position.lerp(destino, suavizado * delta)

func foco_de(punto: Vector3) -> Vector3:
	var foco: Vector3 = punto
	foco.x = clamp(foco.x, limite_min.x, limite_max.x)
	foco.z = clamp(foco.z, limite_min.y, limite_max.y)
	return foco
