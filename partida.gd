extends Node

# Taller 10 - Tarea A (Juan Diego): la zona. La partida es un nodo sin cuerpo
# con tres estados; otros scripts le avisan con ganar() o perder().
# Nivel 1: la partida termina una sola vez (guarda).
# Nivel 2: cuenta metas y, al terminar, el mundo se detiene (pausa).

enum Estado { JUGANDO, GANO, PERDIO }

@export var tiempo_limite = 30.0
# false: al acabarse el tiempo se pierde. true: sobrevivir gana.
@export var gana_con_tiempo = false
# Cuántas metas hay que cumplir para ganar. 0 = no se cuentan.
@export var metas = 3

var estado = Estado.JUGANDO
var tiempo = 0.0
var hechas = 0

func _ready():
	# Always: este nodo sigue vivo aunque el juego quede en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("partida")
	tiempo = tiempo_limite

func _physics_process(delta):
	# Prueba: Enter = una meta. Borrar estas dos líneas al terminar.
	if Input.is_action_just_pressed("ui_accept"):
		avisar_meta()
	if estado != Estado.JUGANDO:
		return
	tiempo = maxf(tiempo - delta, 0.0)
	if tiempo <= 0.001:
		if gana_con_tiempo:
			ganar()
		else:
			perder("se acabó el tiempo")

# La llaman los objetivos del juego: no saben qué pasa después.
func avisar_meta():
	if estado != Estado.JUGANDO:
		return
	hechas += 1
	print("meta ", hechas, " de ", metas)
	if metas > 0 and hechas >= metas:
		ganar()

func ganar():
	terminar(Estado.GANO, "ganó")

func perder(motivo):
	terminar(Estado.PERDIO, motivo)

# La guarda: la partida termina una sola vez.
func terminar(nuevo, motivo):
	if estado != Estado.JUGANDO:
		return
	estado = nuevo
	print("fin: ", Estado.keys()[estado], " cuadro ",
		Engine.get_physics_frames(), " (", motivo, ")")
	get_tree().paused = true
