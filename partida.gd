extends Node

# Taller 10 - Tarea A (Juan Diego): la zona. La partida es un nodo sin cuerpo
# con tres estados; otros scripts le avisan con ganar() o perder().
# Nivel 1: la partida termina una sola vez (guarda).
# Nivel 2: cuenta metas y, al terminar, el mundo se detiene (pausa).
# Nivel 3: reinicia sola y recuerda intentos y mejor tiempo (static).

# Clase 1: valores del plan y señales del contrato (terminada, meta).
# Clase 2: cumplir las metas abre la salida; se gana al entrar en ella.

signal terminada(estado, motivo)
signal meta(hechas, total)
signal salida_abierta
enum Estado { JUGANDO, GANO, PERDIO }

@export var tiempo_limite = 120.0
# false: al acabarse el tiempo se pierde. true: sobrevivir gana.
@export var gana_con_tiempo = false
# Cuántas metas hay que cumplir para ganar. 0 = no se cuentan.
@export var metas = 3
@export var espera_reinicio = 1.0
# static: es del script, no del nodo. Sobrevive a recargar la escena.
static var intentos = 1
static var mejor = 0.0

var estado = Estado.JUGANDO
var tiempo = 0.0
var hechas = 0
var reloj = 0.0

func _ready():
	# Always: este nodo sigue vivo aunque el juego quede en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("partida")
	tiempo = tiempo_limite
	print("intento ", intentos, " · mejor tiempo ", snappedf(mejor, 0.01))

func _physics_process(delta):
	if estado != Estado.JUGANDO:
		reloj -= delta
		if reloj <= 0.001:
			reiniciar()
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
	meta.emit(hechas, metas)
	if metas > 0 and hechas >= metas:
		abrir_salida()

# Sin salida en la escena (las de prueba) se gana directo, como antes.
func abrir_salida():
	if get_tree().get_first_node_in_group("salida") == null:
		ganar()
		return
	print("salida abierta")
	salida_abierta.emit()

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
	reloj = espera_reinicio
	var usado = tiempo_limite - tiempo
	if estado == Estado.GANO and (mejor == 0.0 or usado < mejor):
		mejor = usado
	terminada.emit(estado, motivo)


func reiniciar():
	intentos += 1
	# Primero quitar la pausa: si no, la escena nueva nace congelada.
	get_tree().paused = false
	get_tree().reload_current_scene()
