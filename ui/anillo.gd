@tool
extends Control

# Anillo de progreso del HUD: el reloj de la zona y el "comiendo" del alimento.
# valor va de 0 a 1 y se dibuja desde arriba en sentido horario.

@export_range(0.0, 1.0) var valor: float = 1.0
@export var grosor: float = 5.0
@export var color_lleno: Color = Color(0.949, 0.929, 0.894, 1)
@export var color_pista: Color = Color(0.949, 0.929, 0.894, 0.15)
@export var color_centro: Color = Color(0.06, 0.06, 0.07, 0.85)
@export var k_suave: float = 12.0

var mostrado = 1.0

func _ready():
	mostrado = valor

func _process(delta):
	mostrado = mostrado + (valor - mostrado) * (1.0 - exp(-k_suave * delta))
	queue_redraw()

func _draw():
	var centro = size * 0.5
	var radio = minf(size.x, size.y) * 0.5 - grosor * 0.5
	if radio <= 1.0:
		return
	if color_centro.a > 0.0:
		draw_circle(centro, radio + grosor * 0.5, color_centro)
	draw_arc(centro, radio, 0.0, TAU, 48, color_pista, grosor, true)
	if mostrado > 0.002:
		var inicio = -PI * 0.5
		draw_arc(centro, radio, inicio, inicio + TAU * minf(mostrado, 1.0),
			maxi(4, int(48 * mostrado)), color_lleno, grosor, true)
