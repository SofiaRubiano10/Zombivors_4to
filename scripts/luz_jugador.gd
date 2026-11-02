class_name LuzJugador
extends SpotLight3D

# En Zombivors es el cono cálido de visión del zombi hacia adelante
@export var rango: float = 5.0 # Metros: alcance del cono de visión del concepto
@export var altura: float = 1.2 # Metros sobre los pies del zombi

func _ready() -> void:
	position = Vector3(0.0, altura, 0.0)
	spot_range = rango
	spot_attenuation = 2.0 # Exponente 2 que modela la caída física 1/d^2
	spot_angle = 35.0 # Apertura del cono hacia adelante (-Z)
	light_color = Color("#D4A373") # Tono cálido de nuestra paleta
	light_energy = 2.5 # Calculado: 0.1 * 5^2 = 2.5 para llegar con 0.1 a 5 m
	
	# Prueba rápida de la función pura en consola:
	print("--- Tarea C Nivel 1 (Juan Diego): LuzJugador y Atenuación 1/d^2 ---")
	print("Atenuación a 1m: ", atenuacion(1.0), " | a 2m: ", atenuacion(2.0), " | a 4m: ", atenuacion(4.0))

static func atenuacion(d: float, exponente: float = 2.0) -> float:
	return 1.0 / pow(maxf(d, 0.0001), exponente)
