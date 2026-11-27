class_name SistemaEventos
extends Node

# Clase 6: es el punto donde se juntan las señales del juego con los efectos, para
# que salgan a la vez. Al recibir un golpe (Salud.golpeado) el destello rojo de
# LuzEvento sale encima del zombi en el mismo cuadro que el hit flash y la sacudida;
# al chocar la embestida (Embestida.choco) la cámara da una sacudida corta.

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
	call_deferred("conectar_jugador")

func conectar_jugador() -> void:
	var jugador: Node = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		return
	var salud: Node = jugador.get_node_or_null("Salud")
	if salud != null:
		salud.golpeado.connect(func(_d): _on_evento(jugador.global_position))
	var embestida: Node = jugador.get_node_or_null("Embestida")
	if embestida != null and embestida.has_signal("choco"):
		embestida.choco.connect(_al_chocar)

func _al_chocar(_posicion: Vector3) -> void:
	var camara: Camera3D = get_viewport().get_camera_3d()
	if camara != null and camara.has_method("sacudir"):
		camara.sacudir()

func _process(delta: float) -> void:
	# Decaimiento exponencial del destello de daño (Nivel 2)
	if luz_evento:
		luz_evento.light_energy = decaer(luz_evento.light_energy, 0.0, k_destello, delta)
	
	# La vida vive en el nodo Salud del jugador: a menos vida, más peligro.
	var jugador: Node = get_tree().get_first_node_in_group("jugador")
	var salud: Node = jugador.get_node_or_null("Salud") if jugador else null
	if salud != null:
		variable = clampf(1.0 - float(salud.vida) / maxf(1.0, salud.vida_inicial), 0.0, 1.0)

	# Actualizar la luz variable (Nivel 3)
	if luz_variable != null:
		luz_variable.light_color = color_bajo.lerp(color_alto, variable)
		if "peligro" in luz_variable:
			# La LuzJugador pone su propia energía (depende de lo oscuro que esté): solo recibe
			# el peligro, y con él encoge la vista del zombi.
			luz_variable.peligro = variable
		else:
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
