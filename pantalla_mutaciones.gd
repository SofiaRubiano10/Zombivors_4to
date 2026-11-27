extends CanvasLayer

# Clase 5 - Tarea A (Juan Diego): la pantalla entre zonas. Sin arte: texto y
# tres botones con mutaciones al azar. También se elige con las teclas 1, 2 y 3.
# Funciona con el juego en pausa (process_mode Always).
# Clase 7: va en una tarjeta con el tema flat (PielFlat.tarjeta).
# Clase 8: es una tienda. Las mutaciones se compran con los puntos de la run
# (Puntuacion.saldo). Hay 4 ofertas con su precio, que sube con el piso; se pueden
# comprar varias (botón o teclas 1 a 4) y se sigue con "Continuar" (o Enter).
# Lo que no alcanza sale apagado. Si no alcanza para ninguna, la más barata sale
# gratis una vez: nadie se queda sin progresar.

# Al cerrar la tienda. Para no tocar a quien escucha, se manda "" (nada que agregar:
# las compras ya se agregaron a Mutaciones al pagarlas).
signal elegida(nombre)

const HUESO = Color(0.949, 0.929, 0.894)
const COMIDA = Color(0.831, 0.639, 0.451)
const PELIGRO = Color("#B22222")
const FONDO = Color(0.169, 0.176, 0.192, 0.92)

var opciones = []
var botones = []
var fondo = null
var piso = 1
var texto_saldo = null
# Índice de la oferta que sale gratis (-1 = ninguna).
var gratis = -1
var continuar = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("pantalla_mutaciones")
	layer = 10
	visible = false

func mostrar(numero_zona):
	piso = numero_zona
	opciones = Mutaciones.ofrecer_tienda(piso)
	if opciones.is_empty():
		elegida.emit("")
		return
	gratis = -1
	var mas_barata = precio(0)
	if Puntuacion.saldo() < mas_barata:
		gratis = 0
	armar(numero_zona)
	visible = true

func precio(i):
	return 0 if i == gratis else Mutaciones.precio(opciones[i], piso)

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
	columna.add_theme_constant_override("separation", 10)
	PielFlat.tarjeta(centro).add_child(columna)
	etiqueta(columna, "PISO " + str(numero_zona) + " SUPERADO", 30, HUESO)
	etiqueta(columna, "Tienda de mutaciones", 20, COMIDA)
	texto_saldo = etiqueta(columna, "", 22, HUESO)
	if gratis >= 0:
		etiqueta(columna, "No te alcanza: la primera va gratis", 16, COMIDA)
	botones = []
	for i in opciones.size():
		var boton = Button.new()
		boton.custom_minimum_size = Vector2(560, 66)
		boton.add_theme_font_size_override("font_size", 18)
		boton.pressed.connect(comprar.bind(i))
		columna.add_child(boton)
		botones.append(boton)
	continuar = Button.new()
	continuar.text = "Continuar (Enter)"
	continuar.custom_minimum_size = Vector2(560, 52)
	continuar.pressed.connect(cerrar)
	columna.add_child(continuar)
	refrescar()

func etiqueta(padre, texto, tamano, color):
	var l = Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tamano)
	l.add_theme_color_override("font_color", color)
	padre.add_child(l)
	return l

# Texto y estado de cada oferta según lo que ya se compró y el saldo que queda.
func refrescar():
	texto_saldo.text = "Puntos para gastar: " + str(Puntuacion.saldo())
	for i in opciones.size():
		var b = botones[i]
		var nombre = opciones[i]
		var nivel = "I".repeat(Mutaciones.nivel(nombre))
		var etiqueta_precio = "GRATIS" if i == gratis else str(precio(i)) + " pts"
		if Mutaciones.tiene(nombre):
			b.text = nombre + " · COMPRADA"
			b.disabled = true
		else:
			b.text = str(i + 1) + ". " + nombre + " (nivel " + nivel + ") · " + etiqueta_precio + "\n" + Mutaciones.descripcion(nombre)
			b.disabled = precio(i) > Puntuacion.saldo()
	# El foco en Continuar: así Enter sigue y no compra por accidente.
	continuar.grab_focus.call_deferred()

func comprar(i):
	if not visible or i >= opciones.size() or Mutaciones.tiene(opciones[i]):
		return
	if not Puntuacion.gastar(precio(i)):
		return
	Mutaciones.agregar(opciones[i])
	Sonidos.tocar("comer")
	print("mutación comprada: ", opciones[i], " por ", precio(i), " · saldo ", Puntuacion.saldo())
	# Lo gratis es una sola vez.
	if i == gratis:
		gratis = -1
	destellar(botones[i])
	refrescar()

func destellar(boton):
	boton.modulate = Color(1.5, 1.35, 1.0)
	boton.create_tween().tween_property(boton, "modulate", Color.WHITE, 0.4)

func _unhandled_input(evento):
	if not visible or not evento is InputEventKey or not evento.pressed:
		return
	if evento.keycode == KEY_ENTER or evento.keycode == KEY_KP_ENTER:
		get_viewport().set_input_as_handled()
		cerrar()
		return
	var i = evento.keycode - KEY_1
	if i >= 0 and i < opciones.size():
		get_viewport().set_input_as_handled()
		comprar(i)

func cerrar():
	if not visible:
		return
	visible = false
	elegida.emit("")
