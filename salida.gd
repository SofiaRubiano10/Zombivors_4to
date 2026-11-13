extends Area3D

# Clase 2 - Tarea A (Juan Diego): la salida de la zona.
# Empieza cerrada. Cuando la Partida avisa salida_abierta, se abre;
# entrar en ella con la salida abierta gana la partida.
# Clase 4: a los 5 minutos la Partida avisa salida_cerrada y se pone roja.
# La Salida solo avisa que la pisaron: si eso gana o pierde lo decide la Partida.

@export var color_cerrada = Color(0.35, 0.1, 0.1)
@export var color_abierta = Color(0.2, 0.8, 0.3)
@export var color_tarde = Color(0.9, 0.15, 0.1)

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
		partida.salida_cerrada.connect(cerrar)

func abrir():
	abierta = true
	encender(color_abierta)
	# Si el zombi ya estaba encima cuando se abrió, también cuenta.
	for cuerpo in get_overlapping_bodies():
		_al_entrar(cuerpo)

func cerrar():
	abierta = false
	encender(color_tarde)

func encender(color):
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color

func _al_entrar(cuerpo):
	if partida != null and cuerpo.is_in_group("jugador"):
		partida.entrar_salida()
