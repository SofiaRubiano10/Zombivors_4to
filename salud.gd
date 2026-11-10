extends Node

# Taller 9 - Tarea B (María Sofía): la vida del jugador vive aquí, en un nodo
# hijo del Personaje, para no tocar personaje.gd.
# Taller 10 - Tarea B, Nivel 1: avisa con la señal cambio; no sabe quién escucha.
# Nivel 2: sin vida, le avisa a la Partida y se acaba la partida.
# Nivel 3: reaparecer en el punto inicial antes de perder.
# Clase 1: valores del plan y señal golpeado para quien deba reaccionar al daño.
# Clase 1: el reloj es el cuerpo, la descomposición quita vida con el tiempo.

signal cambio(vida)
signal sin_vida
signal golpeado(danio)

@export var vida = 100
@export var invulnerable = 0.5
@export var reapariciones = 0
@export var espera_reaparecer = 2.0
@export var intervalo_descomposicion = 10.0
# Fracción de la vida inicial que se pierde en cada intervalo.
@export var porcentaje_descomposicion = 0.02
var reloj = 0.0
var acumulado = 0.0
var vida_inicial = 0
var punto = Vector3.ZERO
@onready var pj = get_parent()

func _ready():
	sin_vida.connect(_al_quedar_sin_vida)
	vida_inicial = vida
	punto = pj.global_position

func _physics_process(delta):
	reloj = maxf(reloj - delta, 0.0)
	descomponer(delta)

# No pasa por recibir_golpe: el cuerpo se pudre aunque seas invulnerable.
func descomponer(delta):
	if vida == 0:
		return
	acumulado += delta
	if acumulado < intervalo_descomposicion:
		return
	acumulado -= intervalo_descomposicion
	quitar_vida(int(round(vida_inicial * porcentaje_descomposicion)))

func recibir_golpe(danio):
	if reloj > 0.001 or vida == 0:
		return
	reloj = invulnerable
	golpeado.emit(danio)
	quitar_vida(danio)

func quitar_vida(cantidad):
	if cantidad <= 0:
		return
	vida = maxi(vida - cantidad, 0)
	cambio.emit(vida)
	if vida == 0:
		sin_vida.emit()

# Se busca aquí y no en _ready(): la Partida quizá todavía no existía.
func _al_quedar_sin_vida():
	if reapariciones > 0:
		reapariciones -= 1
		vida = vida_inicial
		pj.global_position = punto
		reloj = espera_reaparecer
		cambio.emit(vida)
		print("reaparece cuadro ", Engine.get_physics_frames())
		return
	var partida = get_tree().get_first_node_in_group("partida")
	if partida != null:
		partida.perder("sin vida")
