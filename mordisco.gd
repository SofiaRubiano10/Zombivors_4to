extends Node

# Clase 2 (Sofía y Juan): el mordisco del zombi (Espacio).
# Vive en un nodo hijo del Personaje, como Interactuar y Salud.
# - De frente: solo hiere (danio). El cazador se entera y se defiende.
# - Por la espalda, o si ya le queda poca vida: te lo comes. Cura, cuenta como
#   una presa para abrir la salida y quita a ese cazador del mapa.
# El HUD lee objetivo y por_la_espalda para decirte qué pasará si muerdes.

signal mordio(presa, devorada)

const VERDE = Color(0.49, 0.99, 0.42)
const NARANJA = Color(1.0, 0.6, 0.2)

@export var tecla: String = "morder"
@export var alcance: float = 1.6
@export var danio: int = 15
@export var recarga: float = 0.6
@export var curacion: int = 30

var reloj: float = 0.0
# El cazador más cercano al alcance (o null) y si estás a su espalda.
var objetivo: Node3D = null
var por_la_espalda: bool = false

@onready var pj = get_parent()

func _physics_process(delta: float) -> void:
	reloj = maxf(reloj - delta, 0.0)
	objetivo = mas_cercano()
	por_la_espalda = objetivo != null and Sentidos.a_la_espalda(objetivo, pj.global_position)
	if Input.is_action_just_pressed(tecla) and reloj <= 0.001:
		morder()

func morder() -> void:
	reloj = recarga
	if objetivo == null:
		return
	# Se gira hacia la presa: el mordisco va a donde está.
	pj.basis = Basis.looking_at(Sentidos.hacia(pj.global_position, objetivo.global_position))
	if por_la_espalda or objetivo.vida <= danio:
		devorar(objetivo)
	else:
		objetivo.recibir_golpe(danio)
		Sentidos.aviso(get_tree(), "¡De frente solo lo hieres! Rodéalo y muerde su espalda", NARANJA)
		mordio.emit(objetivo, false)

func devorar(presa: Node3D) -> void:
	presa.devorar()
	var salud = pj.get_node_or_null("Salud")
	if salud != null:
		salud.curar(curacion)
	var partida = get_tree().get_first_node_in_group("partida")
	if partida != null:
		partida.avisar_meta()
	Sentidos.aviso(get_tree(), "¡Te lo comiste! +%d de vida" % curacion, VERDE)
	print("devorado: ", presa.name)
	mordio.emit(presa, true)
	objetivo = null
	por_la_espalda = false

func mas_cercano() -> Node3D:
	var mejor: Node3D = null
	var mejor_d: float = alcance
	for c in get_tree().get_nodes_in_group("cazadores"):
		if c.get("muerto"):
			continue
		var d = Sentidos.distancia(pj.global_position, c.global_position)
		if d <= mejor_d:
			mejor = c
			mejor_d = d
	return mejor
