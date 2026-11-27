extends CanvasLayer

# Clase 5 - Tarea A (Juan Diego): la pantalla entre zonas. Sin arte: texto y
# tres botones con mutaciones al azar. También se elige con las teclas 1, 2 y 3.
# Funciona con el juego en pausa (process_mode Always).
# Clase 7: va en una tarjeta con el tema flat (PielFlat.tarjeta).

signal elegida(nombre)

const HUESO = Color(0.949, 0.929, 0.894)
const FONDO = Color(0.169, 0.176, 0.192, 0.92)

var opciones = []
var fondo = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("pantalla_mutaciones")
	layer = 10
	visible = false

func mostrar(numero_zona):
	opciones = Mutaciones.ofrecer(3)
	if opciones.is_empty():
		elegida.emit("")
		return
	armar(numero_zona)
	visible = true

func armar(numero_zona):
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
	columna.add_theme_constant_override("separation", 14)
	PielFlat.tarjeta(centro).add_child(columna)
	var titulo = Label.new()
	titulo.text = "PISO " + str(numero_zona) + " SUPERADO\nElige una mutación"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 30)
	titulo.add_theme_color_override("font_color", HUESO)
	columna.add_child(titulo)
	for i in opciones.size():
		var boton = Button.new()
		boton.text = str(i + 1) + ". " + opciones[i] + "\n" + Mutaciones.descripcion(opciones[i])
		boton.custom_minimum_size = Vector2(520, 70)
		boton.add_theme_font_size_override("font_size", 20)
		boton.pressed.connect(elegir.bind(i))
		columna.add_child(boton)
		if i == 0:
			boton.grab_focus.call_deferred()

func _unhandled_input(evento):
	if not visible or not evento is InputEventKey or not evento.pressed:
		return
	var i = evento.keycode - KEY_1
	if i >= 0 and i < opciones.size():
		elegir(i)

func elegir(i):
	if not visible:
		return
	visible = false
	print("mutación elegida: ", opciones[i])
	elegida.emit(opciones[i])
