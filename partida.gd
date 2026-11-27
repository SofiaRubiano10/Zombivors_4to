class_name Partida
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
# Clase 5: la run tiene 3 zonas (zona.gd las configura). Ganar una zona recarga la
# escena en la siguiente con la misma vida (static); ganar la última es la victoria
# final. Perder en cualquier zona termina la run: se vuelve a la zona 1.
# Clase 5: entre zonas se elige una mutación (pantalla_mutaciones.tscn).
# Clase 8: esa pantalla es ahora una tienda: las compras se agregan al pagarlas y al
# cerrarla manda "" (no hay nada más que agregar).
# Clase 5: cuando la run termina se muestra el resumen (fin_run.tscn) y se espera
# a que el jugador pida otra.

signal terminada(estado, motivo)
signal meta(hechas, total)
signal salida_abierta
signal salida_cerrada
signal zona_cambiada(numero)
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
# En qué zona va la run (1, 2 o 3) y la vida con la que se llega a ella (-1 = llena).
static var zona = 1
static var vida_guardada = -1
# Lo pone la Zona; sin Zona en la escena (las de prueba) hay una sola.
var zonas_total = 1

var estado = Estado.JUGANDO
# Cronómetro: segundos jugados en este intento.
var tiempo = 0.0
# Cuántos alimentos pide la meta. Se calcula al empezar con la comida que haya.
var metas = 0
var hechas = 0
var abierta = false
var tarde = false
var reloj = 0.0
var motivo_fin = ""

func _ready():
	# Always: este nodo sigue vivo aunque el juego quede en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("partida")
	print("intento ", intentos, " · zona ", zona, " · mejor tiempo ", snappedf(mejor, 0.01))
	traer_vida()
	Mutaciones.aplicar(get_tree().get_first_node_in_group("jugador"))
	zona_cambiada.emit.call_deferred(zona)
	# Diferido: los alimentos entran a su grupo en su propio _ready().
	call_deferred("contar_metas")

# La vida de la zona anterior. Se hace aquí, antes de que el HUD la lea.
func traer_vida():
	if vida_guardada < 0:
		return
	var salud = salud_del_jugador()
	if salud != null:
		salud.vida = vida_guardada
		salud.cambio.emit(salud.vida)

func salud_del_jugador():
	var pj = get_tree().get_first_node_in_group("jugador")
	return pj.get_node_or_null("Salud") if pj != null else null

func ultima_zona():
	return zona >= zonas_total

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
		if reloj <= 0.0:
			return
		reloj -= delta
		if reloj <= 0.001:
			reloj = 0.0
			despues_de_terminar()
		return
	# Menú de pausa abierto: la Partida sigue viva (Always) pero el tiempo no corre.
	if get_tree().paused:
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
	Sonidos.tocar("salida")
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
	motivo_fin = motivo
	print("fin: ", Estado.keys()[estado], " cuadro ",
		Engine.get_physics_frames(), " (", motivo, ") a los ", reloj_texto(tiempo))
	get_tree().paused = true
	reloj = espera
	if estado == Estado.GANO and (mejor == 0.0 or tiempo < mejor):
		mejor = tiempo
	terminada.emit(estado, motivo)

# Desde el menú de pausa: se abandona la run y se empieza otra.
func reiniciar_run():
	nueva_run()
	intentos += 1
	get_tree().paused = false
	get_tree().reload_current_scene()

func siguiente_zona():
	var salud = salud_del_jugador()
	vida_guardada = salud.vida if salud != null else -1
	zona += 1
	print("pasa a la zona ", zona, " con ", vida_guardada, " de vida")

# Todo lo que dura una run vuelve a empezar.
static func nueva_run():
	zona = 1
	vida_guardada = -1
	Mutaciones.elegidas.clear()

# 133.4 s -> "02:13"
static func reloj_texto(segundos):
	var s = int(segundos)
	# floori dice a propósito "quédate con los minutos enteros"; s / 60 daba aviso.
	return "%02d:%02d" % [floori(s / 60.0), s % 60]

# Al ganar una zona que no es la última se elige mutación antes de seguir.
func despues_de_terminar():
	var pantalla = get_tree().get_first_node_in_group("pantalla_mutaciones")
	if estado == Estado.GANO and not ultima_zona() and pantalla != null:
		pantalla.elegida.connect(_al_elegir_mutacion, CONNECT_ONE_SHOT)
		pantalla.mostrar(zona)
		return
	var fin = get_tree().get_first_node_in_group("fin_run")
	if fin != null and not (estado == Estado.GANO and not ultima_zona()):
		mostrar_fin(fin)
		return
	reiniciar()

func mostrar_fin(fin):
	var gano = estado == Estado.GANO
	var pisos = zona if gano else zona - 1
	var p = get_tree().get_first_node_in_group("puntuacion")
	var puntos = p.total if p != null else 0
	var record = p.record if p != null else 0
	var nuevo = p.nuevo_record if p != null else false
	var devorados = p.devorados if p != null else 0
	fin.otra_vez.connect(reiniciar, CONNECT_ONE_SHOT)
	var gastado = p.gastado if p != null else 0
	fin.mostrar(gano, motivo_fin, pisos, zonas_total, devorados, puntos, record, nuevo, gastado)

func _al_elegir_mutacion(nombre):
	if nombre != "":
		Mutaciones.agregar(nombre)
	reiniciar()

func reiniciar():
	if estado == Estado.GANO and not ultima_zona():
		siguiente_zona()
	else:
		nueva_run()
		intentos += 1
	# Primero quitar la pausa: si no, la escena nueva nace congelada.
	get_tree().paused = false
	get_tree().reload_current_scene()
