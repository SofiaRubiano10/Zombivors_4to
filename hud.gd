extends CanvasLayer

# Taller 10 - Tarea B (María Sofía): el HUD solo muestra; la vida vive en la Salud
# y el tiempo en la Partida.
# La vida llega por señal. El tiempo cambia cada cuadro, por eso se lee en _process.
# Clase 3: avisos de estado en texto, grandes y arriba: "TE VIO" (rojo, peligro),
# "SOSPECHA", "SALIDA ABIERTA" y "SALIDA CERRADA". Duran unos segundos y se apagan.
# Clase 7: el HUD se ordena en recuadros anclados a las esquinas, con el tema flat
# (ui/tema_flat.tres) y, si están, las texturas del Flat Design UI Pack:
#   arriba izquierda -> vida          arriba centro -> piso, tiempo y comida
#   arriba derecha   -> puntos        abajo derecha -> embestida
#   abajo izquierda  -> mutaciones    centro arriba -> avisos

const COLOR_PELIGRO = Color("#B22222")
const COLOR_HUESO = Color(0.949, 0.929, 0.894)
const COLOR_COMIDA = Color(0.831, 0.639, 0.451)
const COLOR_APAGADO = Color(0.09, 0.094, 0.106, 0.9)
@export var duracion_aviso = 2.0

@onready var raiz = $Raiz
@onready var panel_vida = $Raiz/PanelVida
@onready var valor_vida = $Raiz/PanelVida/Fila/Datos/Cabecera/Valor
@onready var barra_vida = $Raiz/PanelVida/Fila/Datos/Barras/Barra
@onready var rastro_vida = $Raiz/PanelVida/Fila/Datos/Barras/Rastro
@onready var panel_objetivo = $Raiz/PanelObjetivo
@onready var texto_piso = $Raiz/PanelObjetivo/Columna/Fila/Piso
@onready var texto_tiempo = $Raiz/PanelObjetivo/Columna/Fila/Tiempo
@onready var fila_comida = $Raiz/PanelObjetivo/Columna/FilaComida
@onready var pips = $Raiz/PanelObjetivo/Columna/FilaComida/Pips
@onready var estado_salida = $Raiz/PanelObjetivo/Columna/FilaComida/Estado
@onready var panel_puntos = $Raiz/PanelPuntos
@onready var texto_puntos = $Raiz/PanelPuntos/Columna/Fila/Puntos
@onready var texto_record = $Raiz/PanelPuntos/Columna/Record
@onready var panel_embestida = $Raiz/PanelEmbestida
@onready var recarga = $Raiz/PanelEmbestida/Fila/Datos/Recarga
@onready var estado_embestida = $Raiz/PanelEmbestida/Fila/Datos/Cabecera/Estado
@onready var mutaciones = $Raiz/Mutaciones
# Barra de progreso al comer: aparece sobre la cabeza del zombi mientras se
# mantiene E junto a un alimento. Amarillo carne, el color de la comida.
@onready var barra = $Raiz/BarraComer
@onready var aviso = $Raiz/Aviso
@onready var texto_aviso = $Raiz/Aviso/Texto
var mordisco = null
var embestida = null
var reloj_aviso = 0.0
# Un aviso importante (TE VIO) no lo tapa uno menor (SOSPECHA) mientras dura.
var prioridad_aviso = 0
# Mutación "Olfato": una flecha color comida alrededor del zombi que apunta al
# alimento más cercano.
var flecha = Polygon2D.new()
var vida_actual = 0
var vida_max = 100
var partida = null
var jugador = null
var interactuar = null
var puntos = null
# Lo que ya se dibujó: solo se reconstruye cuando cambia.
var metas_dibujadas = -1
var hechas_dibujadas = -1
var mutaciones_dibujadas = -1

func _ready():
	PielFlat.aplicar(raiz.theme)
	poner_iconos()
	var pj = get_tree().get_first_node_in_group("jugador")
	jugador = pj
	interactuar = pj.get_node_or_null("Interactuar")
	mordisco = pj.get_node_or_null("Mordisco")
	embestida = pj.get_node_or_null("Embestida")
	panel_embestida.visible = embestida != null
	var salud = pj.get_node("Salud")
	vida_max = maxi(salud.vida_inicial if salud.vida_inicial > 0 else salud.vida, 1)
	barra_vida.max_value = vida_max
	rastro_vida.max_value = vida_max
	salud.cambio.connect(mostrar)
	mostrar(salud.vida)
	flecha.polygon = PackedVector2Array([Vector2(14, 0), Vector2(-8, -9), Vector2(-8, 9)])
	flecha.color = COLOR_COMIDA
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

# Iconos del pack (res://ui/flat_ui/iconos/). Sin el PNG, el recuadro queda solo con texto.
func poner_iconos():
	var lugares = {
		"vida": $Raiz/PanelVida/Fila/Icono,
		"piso": $Raiz/PanelObjetivo/Columna/Fila/IconoPiso,
		"tiempo": $Raiz/PanelObjetivo/Columna/Fila/IconoTiempo,
		"comida": $Raiz/PanelObjetivo/Columna/FilaComida/IconoComida,
		"puntos": $Raiz/PanelPuntos/Columna/Fila/Icono,
		"embestida": $Raiz/PanelEmbestida/Fila/Icono,
	}
	for nombre in lugares:
		var textura = PielFlat.icono(nombre)
		lugares[nombre].texture = textura
		lugares[nombre].visible = textura != null

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

func avisar(texto, color, prioridad):
	if reloj_aviso > 0.0 and prioridad < prioridad_aviso:
		return
	texto_aviso.text = texto
	texto_aviso.add_theme_color_override("font_color", color)
	aviso.visible = true
	centrar(aviso)
	reloj_aviso = duracion_aviso
	prioridad_aviso = prioridad

# Un recuadro anclado al centro se ajusta a su texto y vuelve al medio.
func centrar(control):
	control.reset_size()
	control.position.x = (raiz.size.x - control.size.x) * 0.5

func _process(delta):
	reloj_aviso = maxf(reloj_aviso - delta, 0.0)
	# El último medio segundo se desvanece.
	aviso.modulate.a = clampf(reloj_aviso / 0.5, 0.0, 1.0)
	aviso.visible = reloj_aviso > 0.0
	actualizar_objetivo()
	actualizar_puntos()
	actualizar_embestida()
	actualizar_mutaciones()
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
	barra_vida.value = vida
	rastro_vida.value = vida
	valor_vida.text = str(vida)
	print("HUD -> vida ", vida)

# Piso, cronómetro y comida que falta para abrir la salida.
func actualizar_objetivo():
	# Se busca aquí: la Partida quizá todavía no existía en _ready().
	if partida == null:
		partida = get_tree().get_first_node_in_group("partida")
	panel_objetivo.visible = partida != null
	if partida == null:
		return
	texto_piso.text = "PISO " + str(Partida.zona) + "/" + str(partida.zonas_total)
	texto_tiempo.text = partida.reloj_texto(partida.tiempo)
	fila_comida.visible = partida.metas > 0
	if partida.metas != metas_dibujadas or partida.hechas != hechas_dibujadas:
		dibujar_pips(partida.metas, mini(partida.hechas, partida.metas))
	if partida.tarde:
		mostrar_estado_salida("SALIDA CERRADA", COLOR_PELIGRO)
	elif partida.abierta:
		mostrar_estado_salida("SALIDA ABIERTA", COLOR_COMIDA)
	else:
		estado_salida.visible = false

func mostrar_estado_salida(texto, color):
	estado_salida.visible = true
	estado_salida.text = texto
	estado_salida.add_theme_color_override("font_color", color)

# Un punto por alimento de la meta: lleno = comido.
func dibujar_pips(metas, hechas):
	if metas != metas_dibujadas:
		for p in pips.get_children():
			p.queue_free()
		for i in metas:
			var pip = Panel.new()
			pip.custom_minimum_size = Vector2(14, 14)
			pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pips.add_child(pip)
		metas_dibujadas = metas
	for i in pips.get_child_count():
		pintar_pip(pips.get_child(i), i < hechas)
	hechas_dibujadas = hechas
	centrar(panel_objetivo)

func pintar_pip(pip, lleno):
	var caja = StyleBoxFlat.new()
	caja.bg_color = COLOR_COMIDA if lleno else COLOR_APAGADO
	caja.set_corner_radius_all(7)
	caja.set_border_width_all(2)
	caja.border_color = COLOR_COMIDA
	pip.add_theme_stylebox_override("panel", caja)

func actualizar_puntos():
	if puntos == null:
		puntos = get_tree().get_first_node_in_group("puntuacion")
	panel_puntos.visible = puntos != null
	if puntos == null:
		return
	texto_puntos.text = str(puntos.en_curso())
	texto_record.text = "RÉCORD " + str(maxi(puntos.record, 0))

# Barra que se llena mientras recarga. "LISTA", "x2" con dos cargas.
func actualizar_embestida():
	if embestida == null:
		return
	var listas = embestida.cargas
	if listas >= embestida.cargas_max:
		recarga.value = 1.0
	else:
		recarga.value = 1.0 - embestida.recarga / maxf(embestida.enfriamiento, 0.01)
	if listas <= 0:
		estado_embestida.text = str(snappedf(embestida.recarga, 0.1)) + " s"
	elif embestida.cargas_max > 1:
		estado_embestida.text = "x" + str(listas)
	else:
		estado_embestida.text = "LISTA"

# Una ficha por mutación elegida (la run entera).
func actualizar_mutaciones():
	if Mutaciones.elegidas.size() == mutaciones_dibujadas:
		return
	mutaciones_dibujadas = Mutaciones.elegidas.size()
	for c in mutaciones.get_children():
		c.queue_free()
	for nombre in Mutaciones.elegidas:
		var ficha = PanelContainer.new()
		ficha.theme_type_variation = &"PanelChip"
		ficha.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ficha.tooltip_text = Mutaciones.LISTA.get(nombre, "")
		var texto = Label.new()
		texto.theme_type_variation = &"LabelChip"
		texto.text = nombre
		ficha.add_child(texto)
		mutaciones.add_child(ficha)
