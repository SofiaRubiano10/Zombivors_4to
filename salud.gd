extends Node

# Taller 9 - Tarea B (María Sofía): la vida del jugador vive aquí, en un nodo
# hijo del Personaje, para no tocar personaje.gd.
# Taller 10 - Tarea B, Nivel 1: avisa con la señal cambio; no sabe quién escucha.
# Nivel 2: sin vida, le avisa a la Partida y se acaba la partida.
# Nivel 3: reaparecer en el punto inicial antes de perder.
# Avance T10: curar(), señal golpeado y descomposición (acumulador).

signal cambio(vida)
signal sin_vida
signal golpeado

@export var vida = 3
@export var invulnerable = 1.0
@export var reapariciones = 1
@export var espera_reaparecer = 2.0
# Descomposición: cuánta vida se pierde cada 'cada_descomposicion' segundos. 0 = apagada.
@export var perdida_descomposicion = 0
@export var cada_descomposicion = 10.0
# Multiplica la descomposición (el cerebro o una mutación la pueden frenar).
var factor_descomposicion = 1.0
var acumulado = 0.0
var reloj = 0.0
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

# El acumulador: cada 'cada_descomposicion' segundos resta la pérdida y avisa.
func descomponer(delta):
	if perdida_descomposicion <= 0 or vida == 0:
		return
	acumulado += delta * factor_descomposicion
	if acumulado >= cada_descomposicion:
		acumulado -= cada_descomposicion
		vida = maxi(vida - perdida_descomposicion, 0)
		cambio.emit(vida)
		print("descomposición cuadro ", Engine.get_physics_frames(), ": vida ", vida)
		if vida == 0:
			sin_vida.emit()

func curar(cantidad):
	if vida == 0:
		return
	vida = mini(vida + cantidad, vida_inicial)
	cambio.emit(vida)

func recibir_golpe(danio):
	if reloj > 0.001 or vida == 0:
		return
	vida = maxi(vida - danio, 0)
	reloj = invulnerable
	cambio.emit(vida)
	golpeado.emit()
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
