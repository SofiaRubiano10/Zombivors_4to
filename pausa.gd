extends CanvasLayer

# Clase 5 - Tarea B (María Sofía): menú de pausa.
# Escape (la acción ui_cancel) congela el juego y muestra Continuar / Reiniciar.
# Solo mientras se juega: si la partida ya terminó, la pausa es de la Partida.
# Reiniciar empieza una run nueva desde el Piso 1.
# Clase 7: va en una tarjeta con el tema flat (PielFlat.tarjeta) que entra con un
# salto al abrir y, si se usa el Flat Design UI Pack, da el crédito a su autor.

const HUESO = Color(0.949, 0.929, 0.894)
const FONDO = Color(0.169, 0.176, 0.192, 0.85)

var fondo = null
var continuar = null
var tarjeta = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 12
	armar()
	visible = false

func armar():
	fondo = ColorRect.new()
	fondo.color = FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var centro = CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.add_child(centro)
	tarjeta = PielFlat.tarjeta(centro)
	var columna = VBoxContainer.new()
	columna.add_theme_constant_override("separation", 12)
	tarjeta.add_child(columna)
	var titulo = Label.new()
	titulo.text = "PAUSA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 40)
	titulo.add_theme_color_override("font_color", HUESO)
	columna.add_child(titulo)
	continuar = boton(columna, "Continuar", cerrar)
	boton(columna, "Reiniciar run", reiniciar)
	if PielFlat.en_uso:
		var credito = Label.new()
		credito.text = "Interfaz: SunGraphica"
		credito.theme_type_variation = &"LabelPequeno"
		credito.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		columna.add_child(credito)

func boton(padre, texto, accion):
	var b = Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(300, 52)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(accion)
	padre.add_child(b)
	return b

func _unhandled_input(evento):
	if not evento.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if visible:
		cerrar()
	elif se_puede_pausar():
		abrir()

func se_puede_pausar():
	var p = get_tree().get_first_node_in_group("partida")
	return p != null and p.estado == p.Estado.JUGANDO and not get_tree().paused

func abrir():
	visible = true
	PielFlat.entrar(tarjeta)
	get_tree().paused = true
	continuar.grab_focus.call_deferred()

func cerrar():
	visible = false
	get_tree().paused = false

func reiniciar():
	visible = false
	var p = get_tree().get_first_node_in_group("partida")
	if p != null:
		p.reiniciar_run()
