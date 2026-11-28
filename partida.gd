extends Node

# Taller 10 - Tarea A (Juan Diego): la zona. La partida es un nodo sin cuerpo
# con tres estados; otros scripts le avisan con ganar() o perder().
# Nivel 1: la partida termina una sola vez (guarda).
# Nivel 2: cuenta metas y, al terminar, el mundo se detiene (pausa).
# Nivel 3: reinicia sola y recuerda intentos y mejor tiempo (static).

# Clase 1: valores del plan y señales del contrato (terminada, meta).
# Clase 2: saciar el hambre ya no gana: abre la SALIDA (señal salida_abierta)
# y hay que llegar a ella. Las presas son comida o cazadores devorados.

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
# true: las metas abren la salida. false: las metas ganan directamente.
@export var con_salida = true
# static: es del script, no del nodo. Sobrevive a recargar la escena.
static var intentos = 1
static var mejor = 0.0

var estado = Estado.JUGANDO
var tiempo = 0.0
var hechas = 0
var reloj = 0.0
var abierta = false

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
	if metas > 0 and hechas >= metas and not abierta:
		# Sin salida en la escena (escenas de prueba) se gana como antes.
		if con_salida and get_tree().get_first_node_in_group("salida") != null:
			abrir_salida()
		else:
			ganar()

# Como la megafonía: quien esté en el grupo "salida" se entera.
func abrir_salida():
	abierta = true
	print("salida abierta cuadro ", Engine.get_physics_frames())
	get_tree().call_group("salida", "abrir")
	salida_abierta.emit()

func ganar(motivo = "escapaste de las oficinas"):
	terminar(Estado.GANO, motivo)

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


# Para el HUD: las variables static se leen mejor con una función.
func intento_actual():
	return intentos

func mejor_tiempo():
	return mejor

func reiniciar():
	intentos += 1
	# Primero quitar la pausa: si no, la escena nueva nace congelada.
	get_tree().paused = false
	get_tree().reload_current_scene()
