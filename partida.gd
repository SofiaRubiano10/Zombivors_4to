extends Node

# Taller 10 - Tarea A (Juan Diego): la zona. La partida es un nodo sin cuerpo
# con tres estados; otros scripts le avisan con ganar() o perder().
# Nivel 1: la partida termina una sola vez (guarda).
# Nivel 2: cuenta metas y, al terminar, el mundo se detiene (pausa).
# Nivel 3: reinicia sola y recuerda intentos y mejor tiempo (static).

# Clase 1: valores del plan y señales del contrato (terminada, meta).
# Clase 2: cumplir las metas abre la salida; se gana al entrar en ella.
# Clase 4: ya no hay cuenta atrás, hay un cronómetro que sube, y la meta es un
# porcentaje de la comida del mapa. El tiempo tiene dos marcas:
#  - antes de tiempo_tarde (5 min): cumplir la meta abre la salida y entrar gana.
#  - desde tiempo_tarde: la salida se cierra. Con la meta cumplida, tocarla es llegar
#    tarde y se pierde. Sin la meta, no pasa nada (como siempre).
#  - en tiempo_reinicio (8 min): se pierde por tiempo, el mundo queda quieto 4 s y reinicia.

signal terminada(estado, motivo)
signal meta(hechas, total)
signal salida_abierta
signal salida_cerrada
enum Estado { JUGANDO, GANO, PERDIO }

# Segundos de cronómetro a partir de los cuales ya no se puede ganar.
@export var tiempo_tarde = 300.0
# Segundos de cronómetro en los que el nivel se reinicia sí o sí.
@export var tiempo_reinicio = 480.0
# Parte de la comida del mapa que hay que comer para abrir la salida. 0 = no se cuenta.
@export var porcentaje_meta = 0.6
@export var espera_reinicio = 1.0
# Lo que el mundo queda en pausa cuando el nivel se acaba por tiempo.
@export var espera_tiempo = 4.0
# static: es del script, no del nodo. Sobrevive a recargar la escena.
static var intentos = 1
static var mejor = 0.0

var estado = Estado.JUGANDO
# Cronómetro: segundos jugados en este intento.
var tiempo = 0.0
# Cuántos alimentos pide la meta. Se calcula al empezar con la comida que haya.
var metas = 0
var hechas = 0
var abierta = false
var tarde = false
var reloj = 0.0

func _ready():
	# Always: este nodo sigue vivo aunque el juego quede en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("partida")
	print("intento ", intentos, " · mejor tiempo ", snappedf(mejor, 0.01))
	# Diferido: los alimentos entran a su grupo en su propio _ready().
	call_deferred("contar_metas")

func contar_metas():
	var total = get_tree().get_nodes_in_group("alimentos").size()
	metas = metas_para(total, porcentaje_meta)
	print("comida en el mapa ", total, " · meta ", metas, " (", int(porcentaje_meta * 100), " %)")
	meta.emit(hechas, metas)

# El mínimo entero que llega al porcentaje: con 5 alimentos y 60 % son 3; con 6 son 4.
static func metas_para(total, porcentaje):
	return ceili(total * porcentaje - 0.0001)

func _physics_process(delta):
	if estado != Estado.JUGANDO:
		reloj -= delta
		if reloj <= 0.001:
			reiniciar()
		return
	tiempo += delta
	if not tarde and tiempo >= tiempo_tarde:
		cerrar_salida()
	if tiempo >= tiempo_reinicio:
		terminar(Estado.PERDIO, "se acabó el tiempo", espera_tiempo)

# La llaman los objetivos del juego: no saben qué pasa después.
func avisar_meta():
	if estado != Estado.JUGANDO:
		return
	hechas += 1
	print("meta ", hechas, " de ", metas)
	meta.emit(hechas, metas)
	if cumplio() and not abierta:
		abrir_salida()

func cumplio():
	return metas > 0 and hechas >= metas

func abrir_salida():
	# Sin salida en la escena (las de prueba) la meta decide sola.
	if get_tree().get_first_node_in_group("salida") == null:
		entrar_salida()
		return
	if tarde:
		print("meta cumplida, pero la salida ya cerró")
		return
	abierta = true
	print("salida abierta")
	salida_abierta.emit()

# A los 5 minutos: quien llegue desde ahora, llega tarde.
func cerrar_salida():
	tarde = true
	abierta = false
	print("salida cerrada cuadro ", Engine.get_physics_frames(), " (", reloj_texto(tiempo), ")")
	salida_cerrada.emit()

# La llama la Salida cuando el zombi la pisa. La regla vive aquí, no en la Salida.
func entrar_salida():
	if estado != Estado.JUGANDO or not cumplio():
		return
	if tarde:
		perder("llegó tarde a la salida")
	else:
		ganar()

func ganar():
	terminar(Estado.GANO, "ganó", espera_reinicio)

func perder(motivo):
	terminar(Estado.PERDIO, motivo, espera_reinicio)

# La guarda: la partida termina una sola vez.
func terminar(nuevo, motivo, espera):
	if estado != Estado.JUGANDO:
		return
	estado = nuevo
	print("fin: ", Estado.keys()[estado], " cuadro ",
		Engine.get_physics_frames(), " (", motivo, ") a los ", reloj_texto(tiempo))
	get_tree().paused = true
	reloj = espera
	if estado == Estado.GANO and (mejor == 0.0 or tiempo < mejor):
		mejor = tiempo
	terminada.emit(estado, motivo)

# 133.4 s -> "02:13"
static func reloj_texto(segundos):
	var s = int(segundos)
	# floori dice a propósito "quédate con los minutos enteros"; s / 60 daba aviso.
	return "%02d:%02d" % [floori(s / 60.0), s % 60]

func reiniciar():
	intentos += 1
	# Primero quitar la pausa: si no, la escena nueva nace congelada.
	get_tree().paused = false
	get_tree().reload_current_scene()
