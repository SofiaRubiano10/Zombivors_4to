extends CanvasLayer

# Clase 5 - Tarea B (María Sofía): la pantalla de fin de run.
# Cuando la run termina (perdiste en cualquier piso, o escapaste del tercero) la
# Partida la muestra en vez de reiniciar sola: pisos superados, humanos devorados,
# puntaje total y, si toca, "NUEVO RÉCORD". Enter o el botón empiezan otra run.
# Clase 7: el resumen va en una tarjeta con el tema flat (PielFlat.tarjeta).
# Clase 8: también dice cuánto se gastó en la tienda de mutaciones.

signal otra_vez

const HUESO = Color(0.949, 0.929, 0.894)
const PELIGRO = Color("#B22222")
const COMIDA = Color(0.831, 0.639, 0.451)
const FONDO = Color(0.169, 0.176, 0.192, 0.94)

var fondo = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("fin_run")
	layer = 11
	visible = false

func mostrar(gano, motivo, pisos, pisos_total, devorados, puntos, record, nuevo_record, gastado = 0):
	if fondo != null:
		fondo.queue_free()
	fondo = ColorRect.new()
	fondo.color = FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var centro = CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.add_child(centro)
	var columna = VBoxContainer.new()
	columna.add_theme_constant_override("separation", 10)
	PielFlat.tarjeta(centro).add_child(columna)
	etiqueta(columna, "¡ESCAPASTE DEL EDIFICIO!" if gano else "FIN DE LA RUN", 40, COMIDA if gano else PELIGRO)
	if not gano:
		etiqueta(columna, "(" + motivo + ")", 20, HUESO)
	etiqueta(columna, "Pisos superados: " + str(pisos) + " / " + str(pisos_total), 24, HUESO)
	etiqueta(columna, "Humanos devorados: " + str(devorados), 24, HUESO)
	etiqueta(columna, "Puntaje: " + str(puntos), 30, HUESO)
	if gastado > 0:
		etiqueta(columna, "Gastado en mutaciones: " + str(gastado), 20, COMIDA)
	if nuevo_record:
		etiqueta(columna, "NUEVO RÉCORD", 34, COMIDA)
	else:
		etiqueta(columna, "Récord: " + str(record), 22, HUESO)
	var boton = Button.new()
	boton.text = "Jugar otra vez (Enter)"
	boton.custom_minimum_size = Vector2(320, 54)
	boton.add_theme_font_size_override("font_size", 22)
	boton.pressed.connect(elegir)
	columna.add_child(boton)
	boton.grab_focus.call_deferred()
	visible = true

func etiqueta(padre, texto, tamano, color):
	var l = Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tamano)
	l.add_theme_color_override("font_color", color)
	padre.add_child(l)

func elegir():
	if not visible:
		return
	visible = false
	otra_vez.emit()
