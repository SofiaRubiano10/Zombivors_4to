extends Area3D

# Clase 2 - Tarea A (Juan Diego): la salida de la zona.
# Empieza cerrada. Cuando la Partida avisa salida_abierta, se abre;
# entrar en ella con la salida abierta gana la partida.

@export var color_cerrada = Color(0.35, 0.1, 0.1)
@export var color_abierta = Color(0.2, 0.8, 0.3)

var abierta = false
var partida = null
var material = StandardMaterial3D.new()
@onready var marca = $Marca

func _ready():
	add_to_group("salida")
	material.albedo_color = color_cerrada
	marca.material_override = material
	body_entered.connect(_al_entrar)
	# Diferido: la Partida entra a su grupo en su propio _ready().
	call_deferred("_conectar")

func _conectar():
	partida = get_tree().get_first_node_in_group("partida")
	if partida != null:
		partida.salida_abierta.connect(abrir)

func abrir():
	abierta = true
	material.albedo_color = color_abierta
	material.emission_enabled = true
	material.emission = color_abierta
	# Si el zombi ya estaba encima cuando se abrió, también cuenta.
	for cuerpo in get_overlapping_bodies():
		_al_entrar(cuerpo)

func _al_entrar(cuerpo):
	if abierta and partida != null and cuerpo.is_in_group("jugador"):
		partida.ganar()
