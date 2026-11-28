extends StaticBody3D

# Alimento: al comerlo (mantener E junto a él) cura por la Salud y le avisa a la Partida.
# Tipos de alimento (plan, mecánica 8): cada escena de comida trae sus números.
#   alimento_carne.tscn   -> Carne:   +20 de vida, se come en 1.5 s.
#   alimento_carrona.tscn -> Carroña: +8 de vida, se come en 0.5 s (para cuando hay prisa).
#   alimento_cerebro.tscn -> Cerebro: +40 de vida y la descomposición se detiene 20 s.
# El HUD lee nombre, icono y color para mostrar qué hay cerca y qué te comiste.

signal comido(alimento)

@export var nombre: String = "Carne"
@export var curacion: int = 20
# Segundos manteniendo E. Interactuar lo usa en lugar de su tiempo_necesario.
@export var tiempo_comer: float = 1.5
# Segundos que la Salud deja de descomponerse al comerlo (0 = nada).
@export var pausa_descomposicion: float = 0.0
@export var icono: Texture2D
# Color del brillo en el mundo y del acento en el HUD.
@export var color: Color = Color(0.831, 0.639, 0.451, 1)
# "Respira": el modelo se infla y desinfla un poco para que se note que se come.
@export var latido: float = 0.04

var t = 0.0
var escala_base = Vector3.ONE
var energia_base = 0.0
@onready var modelo: Node3D = get_node_or_null("Modelo")
@onready var brillo: Light3D = get_node_or_null("Brillo")

func _ready() -> void:
	add_to_group("interactivos")
	add_to_group("alimentos")
	# Cada alimento late a su ritmo.
	t = randf() * TAU
	if modelo != null:
		escala_base = modelo.scale
	if brillo != null:
		brillo.light_color = color
		energia_base = brillo.light_energy

func _process(delta: float) -> void:
	t += delta
	var pulso = sin(t * 2.4)
	if modelo != null:
		modelo.scale = escala_base * (1.0 + latido * pulso)
	if brillo != null:
		brillo.light_energy = energia_base * (0.85 + 0.15 * pulso)

func usar() -> void:
	comido.emit(self)
	var pj = get_tree().get_first_node_in_group("jugador")
	var salud = pj.get_node_or_null("Salud") if pj else null
	if salud != null:
		salud.curar(curacion)
		if pausa_descomposicion > 0.0 and salud.has_method("pausar_descomposicion"):
			salud.pausar_descomposicion(pausa_descomposicion)
	print("alimento comido: ", nombre, " (+", curacion, " de vida)")
	var partida = get_tree().get_first_node_in_group("partida")
	if partida != null:
		partida.avisar_meta()
	queue_free()
