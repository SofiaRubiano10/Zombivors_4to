extends Control

# El radar del olfato: un círculo en la esquina con lo que huele el zombi.
# Solo dibuja: los datos viven en el nodo Olfato del jugador (activo, duracion,
# reloj, radio y marcas). Si el jugador no tiene Olfato, no se dibuja nada.
# Arriba del radar = hacia donde mira la cámara: lo que está arriba en el
# radar está arriba en la pantalla, así no hay que girar la cabeza.
# _process solo pide redibujar; todo se pinta en _draw().

const COLOR_COMIDA = Color("7cfc6a")
const COLOR_SALIDA = Color("5be3ff")
# Cazador según su alerta: 0 tranquilo, 1 busca, 2 te persigue.
const COLOR_CAZADOR = [Color(1.0, 0.96, 0.78), Color("ffd23f"), Color("ff4040")]
const COLOR_LISTO = Color("7cfc6a")
const COLOR_RECARGA = Color(0.65, 0.65, 0.65)
const LETRA = 14

var pj = null
var olfato = null
var reloj = 0.0 # segundos desde el inicio, para el barrido y el parpadeo

func _process(delta):
	reloj += delta
	buscar()
	queue_redraw()

# Se busca aquí y no en _ready(): el jugador quizá todavía no existía.
func buscar():
	if is_instance_valid(olfato):
		return
	pj = get_tree().get_first_node_in_group("jugador")
	if pj != null:
		olfato = pj.get_node_or_null("Olfato")

# Lee una variable del Olfato sin fallar: si no existe, da el valor por defecto.
func leer(variable, defecto):
	var valor = olfato.get(variable)
	return defecto if valor == null else valor

func _draw():
	if not is_instance_valid(olfato) or not pj is Node3D:
		return
	var radio = minf(size.x, size.y - 24.0) / 2.0 - 6.0
	var centro = Vector2(size.x / 2.0, radio + 6.0)
	var activo = leer("activo", 0.0)
	var encendido = activo > 0.0
	# La base se ve siempre, discreta, para recordar que el olfato existe.
	draw_circle(centro, radio, Color(0.04, 0.06, 0.05, 0.55))
	var borde = Color(COLOR_LISTO, 0.9) if encendido else Color(1, 1, 1, 0.25)
	draw_arc(centro, radio, 0.0, TAU, 64, borde, 2.0, true)
	if encendido:
		var ejes = ejes_camara()
		dibujar_barrido(centro, radio)
		dibujar_marcas(centro, radio, ejes[0], ejes[1])
		dibujar_jugador(centro, ejes[0], ejes[1])
		# Arco del tiempo que queda: empieza arriba y se va acortando.
		var parte = clampf(activo / maxf(leer("duracion", 1.0), 0.01), 0.0, 1.0)
		draw_arc(centro, radio + 3.0, -PI / 2.0, -PI / 2.0 + TAU * parte, 64, COLOR_LISTO, 3.0, true)
		dibujar_rotulo("activo %d s" % ceili(activo), COLOR_LISTO)
	elif leer("reloj", 0.0) > 0.0:
		dibujar_rotulo("recarga %d s" % ceili(leer("reloj", 0.0)), COLOR_RECARGA)
	else:
		dibujar_rotulo("listo", COLOR_LISTO)

# Ejes del suelo vistos desde la cámara: adelante es "arriba en la pantalla".
func ejes_camara():
	var cam = get_viewport().get_camera_3d()
	if cam == null:
		return [Vector3.FORWARD, Vector3.RIGHT]
	var adelante = -cam.global_basis.z
	if absf(adelante.y) > 0.99: # mira recto hacia abajo: arriba es su eje y
		adelante = cam.global_basis.y
	var derecha = cam.global_basis.x
	adelante.y = 0.0
	derecha.y = 0.0
	return [adelante.normalized(), derecha.normalized()]

# Pasa un punto del mundo (relativo al jugador) a píxeles del radar.
func a_radar(rel, adelante, derecha):
	return Vector2(rel.dot(derecha), -rel.dot(adelante))

# Línea que gira con una estela translúcida detrás, como un sonar.
func dibujar_barrido(centro, radio):
	draw_arc(centro, radio * 0.5, 0.0, TAU, 48, Color(COLOR_LISTO, 0.2), 1.0, true)
	var angulo = reloj * PI # media vuelta por segundo
	var estela = PackedVector2Array([centro])
	for i in 9:
		estela.append(centro + Vector2.from_angle(angulo - 0.6 * i / 8.0) * radio)
	draw_colored_polygon(estela, Color(COLOR_LISTO, 0.12))
	draw_line(centro, centro + Vector2.from_angle(angulo) * radio, Color(COLOR_LISTO, 0.7), 2.0, true)

func dibujar_marcas(centro, radio, adelante, derecha):
	var escala = radio / maxf(leer("radio", 10.0), 0.1)
	for marca in leer("marcas", []):
		if not marca is Dictionary:
			continue
		var p = a_radar(marca.get("pos", Vector3.ZERO) - pj.global_position, adelante, derecha) * escala
		var color = color_marca(marca)
		# Lo que queda fuera del radio se pinta en el borde, un poco apagado.
		if p.length() > radio - 4.0:
			p = p.normalized() * (radio - 4.0)
			color.a *= 0.7
		if marca.get("tipo", "") == "salida":
			draw_circle(centro + p, 6.0, color)
			draw_arc(centro + p, 9.0, 0.0, TAU, 24, color, 1.5, true)
		else:
			draw_circle(centro + p, 4.0, color)

func color_marca(marca):
	match marca.get("tipo", ""):
		"comida":
			return COLOR_COMIDA
		"salida":
			return COLOR_SALIDA
		"cazador":
			var alerta = clampi(int(marca.get("alerta", 0)), 0, 2)
			var color = COLOR_CAZADOR[alerta]
			if alerta == 2:
				color.a = 0.3 + 0.7 * absf(sin(reloj * 8.0)) # parpadea
			return color
	return Color(1, 1, 1, 0.6)

# El jugador en el centro: un triángulo que apunta a donde mira en pantalla.
func dibujar_jugador(centro, adelante, derecha):
	var d = a_radar(-pj.global_basis.z, adelante, derecha)
	d = d.normalized() if d.length() > 0.01 else Vector2.UP
	var punta = centro + d * 9.0
	var izquierda = centro + d.rotated(2.5) * 6.0
	var derecha_px = centro + d.rotated(-2.5) * 6.0
	draw_colored_polygon(PackedVector2Array([punta, izquierda, derecha_px]), Color.WHITE)

# "OLFATO [Q] · estado" centrado debajo del círculo, con borde oscuro para leerse.
func dibujar_rotulo(estado, color):
	var fuente = get_theme_default_font()
	var titulo = "OLFATO [Q] ·"
	var hueco = 5.0
	var ancho_titulo = fuente.get_string_size(titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, LETRA).x
	var ancho_estado = fuente.get_string_size(estado, HORIZONTAL_ALIGNMENT_LEFT, -1, LETRA).x
	var pos = Vector2((size.x - ancho_titulo - hueco - ancho_estado) / 2.0, size.y - 5.0)
	var sombra = Color(0, 0, 0, 0.8)
	draw_string_outline(fuente, pos, titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, LETRA, 4, sombra)
	draw_string(fuente, pos, titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, LETRA, Color(1, 1, 1, 0.85))
	pos.x += ancho_titulo + hueco
	draw_string_outline(fuente, pos, estado, HORIZONTAL_ALIGNMENT_LEFT, -1, LETRA, 4, sombra)
	draw_string(fuente, pos, estado, HORIZONTAL_ALIGNMENT_LEFT, -1, LETRA, color)
