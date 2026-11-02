class_name SistemaEventos
extends Node

@export var luz_evento: OmniLight3D
@export var pico_destello := 4.0
@export var k_destello := 10.0

@export var luz_variable: Light3D
@export var color_bajo := Color("#D4A373") # Amarillo carne / cono cálido sano
@export var color_alto := Color("#B22222") # Rojo alerta en peligro crítico
@export var k_variable := 4.0

var variable := 0.0 # Representa el nivel de peligro/descomposición del zombi (de 0 a 1)

func _ready() -> void:
	for d in get_tree().get_nodes_in_group("disparadores"):
		if not d.evento.is_connected(_on_evento):
			d.evento.connect(_on_evento)
	if luz_evento:
		luz_evento.light_energy = 0.0

func _process(delta: float) -> void:
	# Decaimiento exponencial del destello de daño (Nivel 2)
	if luz_evento:
		luz_evento.light_energy = decaer(luz_evento.light_energy, 0.0, k_destello, delta)
	
	# Sincronizar con la salud del zombi o permitir teclas de prueba ARRIBA/ABAJO (Nivel 3)
	var jugador: Node = get_tree().get_first_node_in_group("jugador")
	if Input.is_key_pressed(KEY_UP):
		variable = minf(1.0, variable + delta * 0.5)
	elif Input.is_key_pressed(KEY_DOWN):
		variable = maxf(0.0, variable - delta * 0.5)
	elif jugador and "salud" in jugador and "salud_maxima" in jugador:
		variable = clampf(1.0 - (jugador.salud / maxf(1.0, jugador.salud_maxima)), 0.0, 1.0)
		
	# Actualizar la luz variable (Nivel 3)
	if luz_variable != null:
		luz_variable.light_color = color_bajo.lerp(color_alto, variable)
		var energia_deseada: float = 2.5 + 1.5 * variable
		luz_variable.light_energy = decaer(luz_variable.light_energy, energia_deseada, k_variable, delta)

func _on_evento(posicion: Vector3) -> void:
	if luz_evento:
		luz_evento.global_position = posicion + Vector3.UP * 1.5
		luz_evento.light_energy = pico_destello
		print("Destello de evento en ", posicion.snappedf(0.01), " con pico = ", pico_destello)

static func decaer(actual: float, base: float, k: float, dt: float) -> float:
	var alpha := 1.0 - exp(-k * dt)
	return actual + (base - actual) * alpha
