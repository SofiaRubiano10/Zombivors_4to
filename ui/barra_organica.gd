@tool
extends Control

# Barra "de carne" del HUD. Se dibuja con polígonos para que el borde no sea
# una caja recta: es irregular, como un trozo de cuerpo.
# - valor va de 0 a 1. El relleno llega a él con suavidad (decaer).
# - El borde del relleno ondula: parece algo vivo, no una regla.
# - Al perder, queda un rastro claro que baja más lento: se ve cuánto dolió.
# - Las puntadas parten la barra en trozos iguales (con 3, cada uno es un 25 %).

@export_range(0.0, 1.0) var valor: float = 1.0
@export var color_lleno: Color = Color(0.831, 0.639, 0.451, 1)
@export var color_vacio: Color = Color(0.698, 0.133, 0.133, 1)
@export var color_fondo: Color = Color(0.06, 0.06, 0.07, 0.9)
@export var color_borde: Color = Color(0.949, 0.929, 0.894, 0.85)
@export var color_rastro: Color = Color(0.949, 0.929, 0.894, 0.45)
@export var grosor_borde: float = 2.0
# Píxeles que se deforma el contorno. 0 = cápsula perfecta.
@export var rugosidad: float = 1.2
@export var puntadas: int = 3
@export var semilla: int = 3
@export var k_suave: float = 10.0
# Fracción por segundo que baja el rastro.
@export var caida_rastro: float = 0.35
# Por debajo de este valor la barra palpita.
@export var umbral_latido: float = 0.3

var mostrado = 1.0
var rastro = 1.0
var t = 0.0

func _ready():
	mostrado = valor
	rastro = valor

func _process(delta):
	t += delta
	mostrado = decaer(mostrado, valor, k_suave, delta)
	rastro = maxf(mostrado, move_toward(rastro, mostrado, caida_rastro * delta))
	queue_redraw()

func _draw():
	if size.x < 4.0 or size.y < 4.0:
		return
	var contorno = forma(grosor_borde * 0.5)
	draw_colored_polygon(contorno, color_fondo)
	var interior = forma(grosor_borde + 1.0)
	# Rastro de lo que se acaba de perder.
	if rastro > mostrado + 0.002:
		pintar_recorte(interior, rastro, color_rastro, false)
	# Relleno: pasa de rojo a carne según el valor, y palpita si queda poco.
	var color = color_vacio.lerp(color_lleno, smoothstep(0.15, 0.7, mostrado))
	if mostrado < umbral_latido:
		color = color.lerp(Color(1, 0.85, 0.8), 0.25 * (0.5 + 0.5 * sin(t * 9.0)))
	pintar_recorte(interior, mostrado, color, true)
	# Brillo húmedo en la parte de arriba del relleno.
	var brillo = Color(1, 1, 1, 0.16)
	var franja = PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0),
		Vector2(size.x, size.y * 0.42), Vector2(0, size.y * 0.42)])
	for p in Geometry2D.intersect_polygons(interior, franja):
		for q in Geometry2D.intersect_polygons(p, corte(mostrado)):
			pintar(q, brillo)
	dibujar_puntadas()
	var cerrado = contorno.duplicate()
	cerrado.append(contorno[0])
	draw_polyline(cerrado, color_borde, grosor_borde, true)

# Recorta la forma interior hasta la fracción indicada y la pinta.
func pintar_recorte(interior, fraccion, color, ondula):
	if fraccion <= 0.002:
		return
	for p in Geometry2D.intersect_polygons(interior, corte(fraccion, ondula)):
		pintar(p, color)

# Un recorte muy fino puede quedar sin área: no se dibuja (Godot no lo triangula).
func pintar(poligono, color):
	if poligono.size() < 3:
		return
	var area = 0.0
	for i in poligono.size():
		var a = poligono[i]
		var b = poligono[(i + 1) % poligono.size()]
		area += a.x * b.y - b.x * a.y
	if absf(area) > 2.0:
		draw_colored_polygon(poligono, color)

# Polígono que tapa desde la izquierda hasta la fracción; su borde derecho ondula.
func corte(fraccion, ondula = true):
	var pts = PackedVector2Array()
	var ancho = size.x * fraccion
	pts.append(Vector2(-10, -10))
	var pasos = 8
	for i in pasos + 1:
		var y = -10.0 + (size.y + 20.0) * i / pasos
		var x = ancho
		if ondula and fraccion < 0.999:
			x += sin(y * 0.45 + t * 5.0) * 1.8
		pts.append(Vector2(x, y))
	pts.append(Vector2(-10, size.y + 10))
	return pts

# Cápsula con el borde un poco irregular. La semilla fija la forma: no tiembla.
func forma(margen):
	var rng = RandomNumberGenerator.new()
	rng.seed = semilla
	var pts = PackedVector2Array()
	var alto = size.y - margen * 2.0
	var radio = alto * 0.5
	var izq = Vector2(margen + radio, margen + radio)
	var der = Vector2(maxf(size.x - margen - radio, izq.x), margen + radio)
	var lados = 10
	# Media luna derecha: de arriba hacia abajo.
	for i in lados + 1:
		var a = -PI * 0.5 + PI * i / lados
		pts.append(der + Vector2(cos(a), sin(a)) * (radio + rng.randf_range(-rugosidad, rugosidad) * 0.5))
	# Borde de abajo, de derecha a izquierda.
	var tramos = maxi(1, int((der.x - izq.x) / 18.0))
	for i in range(1, tramos):
		var x = lerpf(der.x, izq.x, float(i) / tramos)
		pts.append(Vector2(x, izq.y + radio + rng.randf_range(-rugosidad, rugosidad)))
	# Media luna izquierda: de abajo hacia arriba.
	for i in lados + 1:
		var a = PI * 0.5 + PI * i / lados
		pts.append(izq + Vector2(cos(a), sin(a)) * (radio + rng.randf_range(-rugosidad, rugosidad) * 0.5))
	# Borde de arriba, de izquierda a derecha.
	for i in range(1, tramos):
		var x = lerpf(izq.x, der.x, float(i) / tramos)
		pts.append(Vector2(x, izq.y - radio + rng.randf_range(-rugosidad, rugosidad)))
	return pts

# Puntadas de sutura: una costura vertical con dos cruces.
func dibujar_puntadas():
	if puntadas <= 0:
		return
	var oscuro = Color(color_fondo.r, color_fondo.g, color_fondo.b, 0.75)
	var hilo = Color(color_borde.r, color_borde.g, color_borde.b, 0.7)
	for k in range(1, puntadas + 1):
		var x = size.x * k / (puntadas + 1)
		draw_line(Vector2(x, 3), Vector2(x, size.y - 3), oscuro, 2.0, true)
		for y in [size.y * 0.3, size.y * 0.7]:
			draw_line(Vector2(x - 3, y - 2), Vector2(x + 3, y + 2), hilo, 1.5, true)

static func decaer(actual, base, k, dt):
	return actual + (base - actual) * (1.0 - exp(-k * dt))
