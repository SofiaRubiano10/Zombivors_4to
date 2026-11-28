extends CanvasLayer

# Taller 10 - Tarea B (María Sofía): el HUD solo muestra; la vida vive en la Salud
# y el tiempo en la Partida.
# La vida llega por señal. El tiempo cambia cada cuadro, por eso se lee en _process.
# Ampliación: el HUD le dice al jugador todo lo que necesita para escapar.
#   Por señal (pasa de vez en cuando): vida, golpes, hambre, salida y final.
#   Cada cuadro (cambia siempre): tiempo, peligro y qué puedes hacer ahora.
#   Avisos: cualquier script escribe en grande arriba al centro con
#     get_tree().call_group("hud", "aviso", "texto", Color(...))
# Nada se da por hecho: si un nodo o una variable no existe, esa parte del
# HUD simplemente no se muestra (get_node_or_null, has_signal y leer()).

const VERDE = Color("7cfc6a")
const AMARILLO = Color("ffd23f")
const ROJO = Color("ff4040")
const NARANJA = Color("ffa040")
const DURACION_DESTELLO = 0.3

@onready var marcador = $Texto
@onready var linea_objetivo = $Objetivo
@onready var peligro = $Peligro
@onready var vineta = $Vineta
@onready var destello = $Destello
@onready var cartel = $Aviso
@onready var contexto = $Contexto
@onready var barra = $Barra
@onready var pantalla_final = $Final

var vida_actual = null # null: no hay Salud y no se muestra la vida
var partida = null
var pj = null
var hambre = 0
var hambre_total = 3
var abierta = false
var terminado = false
# Relojes: segundos que le quedan a cada efecto que se desvanece.
var reloj_aviso = 0.0
var duracion_aviso = 1.0
var reloj_destello = 0.0
var reloj = 0.0 # segundos desde el inicio, para parpadear

func _ready():
	# Always: el HUD sigue vivo con el juego en pausa (para la pantalla final).
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("hud")
	buscar_jugador()
	buscar_partida()
	mostrar_objetivo()
	# Diferido: espera a que todos hayan hecho su _ready(), la Partida incluida.
	aviso_inicial.call_deferred()

func _process(delta):
	reloj += delta
	buscar_jugador()
	buscar_partida()
	actualizar_texto()
	desvanecer(delta)
	if not terminado:
		mostrar_peligro(delta)
		mostrar_contexto()

# Se busca aquí y no solo en _ready(): el jugador quizá todavía no existía.
func buscar_jugador():
	if is_instance_valid(pj):
		return
	pj = get_tree().get_first_node_in_group("jugador")
	if pj == null:
		return
	var salud = pj.get_node_or_null("Salud")
	if salud == null:
		return
	conectar(salud, "cambio", mostrar)
	conectar(salud, "golpeado", golpe)
	mostrar(leer(salud, "vida", 0))

# Lo mismo con la Partida: se busca hasta encontrarla.
func buscar_partida():
	if is_instance_valid(partida):
		return
	partida = get_tree().get_first_node_in_group("partida")
	if partida == null:
		return
	conectar(partida, "meta", _al_cumplir_meta)
	conectar(partida, "salida_abierta", _al_abrir_salida)
	conectar(partida, "terminada", _al_terminar)
	hambre = leer(partida, "hechas", hambre)
	hambre_total = leer(partida, "metas", hambre_total)
	abierta = leer(partida, "abierta", false)
	mostrar_objetivo()

# Conecta solo si la señal existe, y una sola vez.
func conectar(nodo, senal, funcion):
	if nodo.has_signal(senal) and not nodo.is_connected(senal, funcion):
		nodo.connect(senal, funcion)

# Lee una variable de otro nodo sin fallar: si no existe, da el valor por defecto.
func leer(nodo, variable, defecto):
	if not is_instance_valid(nodo):
		return defecto
	var valor = nodo.get(variable)
	return defecto if valor == null else valor

# La llama la señal cambio de la Salud.
func mostrar(vida):
	vida_actual = vida
	actualizar_texto()
	print("HUD -> ", marcador.text)

func actualizar_texto():
	var partes = PackedStringArray()
	if vida_actual != null:
		partes.append("Vida: " + str(vida_actual))
	if partida != null:
		partes.append("Tiempo: " + str(ceili(leer(partida, "tiempo", 0.0))) + " s")
	marcador.text = "   ".join(partes)

func mostrar_objetivo():
	if abierta:
		linea_objetivo.text = "¡SALIDA ABIERTA! Corre al ascensor verde"
		linea_objetivo.add_theme_color_override("font_color", VERDE)
		return
	linea_objetivo.text = "Hambre: %d/%d  ·  Come comida [E] o guardias por la espalda [Espacio]" % [hambre, hambre_total]

func _al_cumplir_meta(hechas, total):
	hambre = hechas
	hambre_total = total
	mostrar_objetivo()

func _al_abrir_salida():
	abierta = true
	mostrar_objetivo()

func aviso_inicial():
	buscar_partida()
	aviso("Escapa de las oficinas: sacia tu hambre (%d) para abrir la salida" % hambre_total, Color.WHITE, 4.0)

# Cartel grande arriba al centro. Si llega otro aviso, reemplaza al anterior.
func aviso(texto: String, color: Color = Color.WHITE, duracion: float = 2.5) -> void:
	cartel.text = texto
	cartel.add_theme_color_override("font_color", color)
	duracion_aviso = maxf(duracion, 0.1)
	reloj_aviso = duracion_aviso

# La llama la señal golpeado de la Salud: un destello rojo que se apaga solo.
func golpe(_danio):
	reloj_destello = DURACION_DESTELLO

# Los efectos que aparecen y se van: el aviso y el destello de daño.
func desvanecer(delta):
	if reloj_aviso > 0.0:
		reloj_aviso = maxf(reloj_aviso - delta, 0.0)
		var aparecer = clampf((duracion_aviso - reloj_aviso) / 0.2, 0.0, 1.0)
		var irse = clampf(reloj_aviso / 0.6, 0.0, 1.0)
		cartel.modulate.a = minf(aparecer, irse)
	reloj_destello = maxf(reloj_destello - delta, 0.0)
	destello.modulate.a = reloj_destello / DURACION_DESTELLO

# Peligro: manda el cazador más alerta (0 tranquilo, 1 te busca, 2 te persigue).
func mostrar_peligro(delta):
	var nivel = 0
	for cazador in get_tree().get_nodes_in_group("cazadores"):
		if cazador.has_method("nivel_alerta"):
			nivel = maxi(nivel, int(cazador.nivel_alerta()))
	peligro.visible = nivel > 0
	if nivel >= 2:
		peligro.text = "¡TE PERSIGUEN!"
		peligro.modulate = Color(ROJO, 0.55 + 0.45 * sin(reloj * 10.0)) # parpadea
	elif nivel == 1:
		peligro.text = "Te están buscando..."
		peligro.modulate = AMARILLO
	# La viñeta roja de los bordes entra y sale suave, y late mientras te persiguen.
	var alfa = 0.0
	if nivel >= 2:
		alfa = 0.8 + 0.2 * sin(reloj * 5.0)
	vineta.modulate.a = move_toward(vineta.modulate.a, alfa, delta * 3.0)

# Qué puedes hacer ahora mismo, en orden de prioridad: morder antes que comer.
func mostrar_contexto():
	contexto.visible = false
	barra.visible = false
	if not is_instance_valid(pj):
		return
	var mordisco = pj.get_node_or_null("Mordisco")
	var presa = leer(mordisco, "objetivo", null)
	if is_instance_valid(presa):
		var danio = leer(mordisco, "danio", 0)
		if leer(mordisco, "por_la_espalda", false):
			poner_contexto("[Espacio] ¡Cómetelo por la espalda!", VERDE)
		elif leer(presa, "vida", danio + 1) <= danio:
			# Tan herido que el mordisco se lo come aunque sea de frente.
			poner_contexto("[Espacio] ¡Cómetelo, está débil!", VERDE)
		else:
			poner_contexto("[Espacio] Morder (-%d) · Rodéalo para comértelo" % danio, NARANJA)
		# Mientras el mordisco recarga, el texto se ve apagado.
		if leer(mordisco, "reloj", 0.0) > 0.0:
			contexto.modulate.a = 0.5
		return
	var interactuar = pj.get_node_or_null("Interactuar")
	if interactuar and interactuar.has_method("mas_cercano") and interactuar.mas_cercano() != null:
		poner_contexto("Mantén [E] para comer", Color.WHITE)
		barra.value = leer(interactuar, "progreso", 0.0)
		barra.visible = true

func poner_contexto(texto, color):
	contexto.text = texto
	contexto.modulate = color
	contexto.visible = true

# Fin de partida: el mundo queda en pausa y el HUD (Always) muestra el resultado.
func _al_terminar(estado, motivo):
	terminado = true
	peligro.visible = false
	vineta.modulate.a = 0.0
	contexto.visible = false
	barra.visible = false
	reloj_aviso = 0.0
	cartel.modulate.a = 0.0
	var radar = get_node_or_null("Radar")
	if radar:
		radar.visible = false
	var gano = estado == 1
	var titulo = $Final/Titulo
	titulo.text = "¡ESCAPASTE!" if gano else "TE ATRAPARON"
	titulo.add_theme_color_override("font_color", VERDE if gano else ROJO)
	$Final/Motivo.text = texto_motivo(gano, str(motivo))
	$Final/Record.text = linea_record()
	pantalla_final.visible = true

# "sin vida" -> "Sin vida". Si gana sin un motivo propio, se explica cómo.
func texto_motivo(gano, motivo):
	if gano and (motivo == "" or motivo == "ganó"):
		motivo = "saliste de las oficinas"
	if motivo == "":
		return ""
	return motivo[0].to_upper() + motivo.substr(1)

func linea_record():
	if not is_instance_valid(partida):
		return ""
	var partes = PackedStringArray()
	if partida.has_method("intento_actual"):
		partes.append("Intento " + str(partida.intento_actual()))
	if partida.has_method("mejor_tiempo"):
		var mejor = partida.mejor_tiempo()
		if mejor > 0.0:
			partes.append("Mejor tiempo: %.1f s" % mejor)
		else:
			partes.append("sin récord aún")
	return " · ".join(partes)
