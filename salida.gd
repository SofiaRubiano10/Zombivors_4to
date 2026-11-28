extends Area3D

# Clase 2 (Juan): la salida de las oficinas, el ascensor.
# Empieza cerrada (roja). Cuando la Partida sacia el hambre llama a abrir()
# (está en el grupo "salida") y se pone verde: si el zombi entra, gana.
# Si entra con la salida cerrada, el HUD le recuerda lo que le falta.

const ROJO = Color(0.85, 0.15, 0.15)
const VERDE = Color(0.25, 1.0, 0.45)

var abierta = false
@onready var puerta = get_node_or_null("Puerta")
@onready var luz = get_node_or_null("Luz")
@onready var cartel = get_node_or_null("Cartel")

func _ready():
	add_to_group("salida")
	body_entered.connect(_al_entrar)
	pintar()

func abrir():
	if abierta:
		return
	abierta = true
	pintar()
	print("salida abierta")

func _al_entrar(cuerpo):
	if not cuerpo.is_in_group("jugador"):
		return
	var partida = get_tree().get_first_node_in_group("partida")
	if partida == null:
		return
	if abierta:
		partida.ganar()
	else:
		var falta = partida.metas - partida.hechas
		Sentidos.aviso(get_tree(), "El ascensor está bloqueado: te faltan %d presas" % falta, ROJO)

func pintar():
	var color = VERDE if abierta else ROJO
	if puerta != null and puerta.material_override is StandardMaterial3D:
		puerta.material_override.albedo_color = color
		puerta.material_override.emission = color
	if luz != null:
		luz.light_color = color
	if cartel != null:
		# El color dice si está abierta; el HUD dice cuántas presas faltan.
		cartel.text = "SALIDA"
		cartel.modulate = color
