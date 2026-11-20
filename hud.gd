extends CanvasLayer

# Taller 10 - Tarea B (María Sofía): el HUD solo muestra; la vida vive en la Salud
# y el tiempo en la Partida.
# La vida llega por señal. El tiempo cambia cada cuadro, por eso se lee en _process.
# Clase 3: avisos de estado en texto, grandes y arriba: "TE VIO" (rojo, peligro),
# "SOSPECHA", "SALIDA ABIERTA" y "SALIDA CERRADA". Duran unos segundos y se apagan.

const COLOR_PELIGRO = Color("#B22222")
const COLOR_HUESO = Color(0.949, 0.929, 0.894)
@export var duracion_aviso = 2.0

@onready var texto = $Texto
# Barra de progreso al comer: aparece sobre la cabeza del zombi mientras se
# mantiene E junto a un alimento. Amarillo carne, el color de la comida.
@onready var barra = $BarraComer
@onready var aviso = $Aviso
var mordisco = null
var embestida = null
var reloj_aviso = 0.0
# Un aviso importante (TE VIO) no lo tapa uno menor (SOSPECHA) mientras dura.
var prioridad_aviso = 0
# Mutación "Olfato": una flecha color comida alrededor del zombi que apunta al
# alimento más cercano.
var flecha = Polygon2D.new()
var vida_actual = 0
var partida = null
var jugador = null
var interactuar = null

func _ready():
	var pj = get_tree().get_first_node_in_group("jugador")
	jugador = pj
	interactuar = pj.get_node_or_null("Interactuar")
	mordisco = pj.get_node_or_null("Mordisco")
	embestida = pj.get_node_or_null("Embestida")
	var salud = pj.get_node("Salud")
	salud.cambio.connect(mostrar)
	mostrar(salud.vida)
	aviso.text = ""
	flecha.polygon = PackedVector2Array([Vector2(14, 0), Vector2(-8, -9), Vector2(-8, 9)])
	flecha.color = Color(0.831, 0.639, 0.451)
	flecha.visible = false
	add_child(flecha)
	# Los humanos pueden aparecer después (el cazador): se conectan al entrar.
	for h in get_tree().get_nodes_in_group("humanos"):
		conectar_humano(h)
	# El cazador está escondido (fuera del grupo) hasta que aparece.
	for nodo in get_tree().get_nodes_in_group("cazador"):
		conectar_humano(nodo)
		nodo.aparecio.connect(avisar.bind("LLEGÓ EL CAZADOR", COLOR_PELIGRO, 3))
	get_tree().node_added.connect(_al_aparecer)
	call_deferred("conectar_partida")

func conectar_partida():
	var p = get_tree().get_first_node_in_group("partida")
	if p == null:
		return
	p.salida_abierta.connect(avisar.bind("SALIDA ABIERTA", COLOR_HUESO, 1))
	p.zona_cambiada.connect(func(n): avisar("PISO " + str(n), COLOR_HUESO, 1))
	p.salida_cerrada.connect(avisar.bind("SALIDA CERRADA", COLOR_PELIGRO, 2))

# node_added llega antes de su _ready: el grupo todavía no está puesto.
func _al_aparecer(nodo):
	if nodo.has_signal("me_vio"):
		conectar_humano.call_deferred(nodo)
	if nodo.has_signal("aparecio"):
		nodo.aparecio.connect(avisar.bind("LLEGÓ EL CAZADOR", COLOR_PELIGRO, 3))

func conectar_humano(h):
	if not is_instance_valid(h) or h.me_vio.is_connected(avisar):
		return
	h.me_vio.connect(avisar.bind("TE VIO", COLOR_PELIGRO, 2))
	if h.has_signal("sospecha"):
		h.sospecha.connect(avisar.bind("SOSPECHA", COLOR_HUESO, 1))

func avisar(texto_aviso, color, prioridad):
	if reloj_aviso > 0.0 and prioridad < prioridad_aviso:
		return
	aviso.text = texto_aviso
	aviso.add_theme_color_override("font_color", color)
	reloj_aviso = duracion_aviso
	prioridad_aviso = prioridad

func _process(delta):
	reloj_aviso = maxf(reloj_aviso - delta, 0.0)
	# El último medio segundo se desvanece.
	aviso.modulate.a = clampf(reloj_aviso / 0.5, 0.0, 1.0)
	actualizar_texto()
	actualizar_barra()
	actualizar_flecha()

# El progreso lo lleva Interactuar (de 0 a 1); el HUD solo lo dibuja.
func actualizar_barra():
	var progreso = interactuar.progreso if interactuar != null else 0.0
	# El mordisco usa la misma barra: también es comer.
	if mordisco != null:
		progreso = maxf(progreso, mordisco.progreso)
	var camara = get_viewport().get_camera_3d()
	if progreso <= 0.0 or camara == null:
		barra.visible = false
		return
	barra.visible = true
	barra.value = progreso
	# Un poco por encima de la cabeza (el zombi mide unos 1.8 m).
	var cabeza = jugador.global_position + Vector3(0, 2.3, 0)
	barra.position = camara.unproject_position(cabeza) - barra.size * 0.5

func actualizar_flecha():
	var camara = get_viewport().get_camera_3d()
	flecha.visible = false
	if not Mutaciones.tiene("Olfato") or camara == null:
		return
	var mejor = null
	var cerca = INF
	for a in get_tree().get_nodes_in_group("alimentos"):
		var d = a.global_position.distance_to(jugador.global_position)
		if d < cerca:
			cerca = d
			mejor = a
	if mejor == null:
		return
	var centro = camara.unproject_position(jugador.global_position + Vector3(0, 0.9, 0))
	var hacia = camara.unproject_position(mejor.global_position) - centro
	if hacia.length() < 1.0:
		return
	flecha.visible = true
	flecha.position = centro + hacia.normalized() * 70.0
	flecha.rotation = hacia.angle()

func mostrar(vida):
	vida_actual = vida
	actualizar_texto()
	print("HUD -> ", texto.text)

# "lista", "x2" con dos cargas, o los segundos que faltan.
func texto_embestida():
	if embestida.cargas > 0:
		return "lista" if embestida.cargas == 1 else "x" + str(embestida.cargas)
	return str(snappedf(embestida.recarga, 0.1)) + " s"

func actualizar_texto():
	# Se busca aquí: la Partida quizá todavía no existía en _ready().
	if partida == null:
		partida = get_tree().get_first_node_in_group("partida")
	var linea = "Vida: " + str(vida_actual)
	if partida != null:
		# Cronómetro (sube) y comida que falta para abrir la salida.
		linea += "   Piso: " + str(Partida.zona) + "/" + str(partida.zonas_total)
		linea += "   Tiempo: " + partida.reloj_texto(partida.tiempo)
		if partida.metas > 0:
			linea += "   Comida: " + str(mini(partida.hechas, partida.metas)) + "/" + str(partida.metas)
		if not Mutaciones.elegidas.is_empty():
			linea += "\nMutaciones: " + ", ".join(Mutaciones.elegidas)
		if embestida != null:
			linea += "   Embestida: " + texto_embestida()
		if partida.tarde:
			linea += "   SALIDA CERRADA"
		elif partida.abierta:
			linea += "   SALIDA ABIERTA"
	texto.text = linea
