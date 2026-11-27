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
# Clase 7: la vida es un elemento vivo. La barra baja con un rastro claro que se
# queda un momento (se ve cuánto dolió), el recuadro tiembla y se pone rojo con
# cada golpe, destella al curar y, con poca vida, late junto a un borde rojo en
# la pantalla. El color va de verde (sano) a ámbar y a rojo.
# Clase 7: lo demás también reacciona. Los avisos entran con un salto y salen
# subiendo; los puntos cuentan hacia arriba y sueltan un "+100" flotante; cada
# alimento comido hace saltar su punto; el reloj se pone rojo y late en los
# últimos 30 s antes de que cierre la salida; la embestida destella al recargarse.
# Clase 7: el HUD se adapta y se aparta.
#  - Lo secundario (puntos, embestida llena, mutaciones) se atenúa si no cambia en
#    unos segundos y vuelve a encenderse cuando pasa algo. Vida y objetivo, no:
#    son lo que hace falta para sobrevivir.
#  - Si el zombi pasa por debajo de un recuadro, ese recuadro se vuelve transparente.
#  - Con la ventana estrecha pasa a modo compacto, y si el recuadro del centro choca
#    con los de las esquinas, baja a la fila de abajo. Nada se tapa.
#  - escala agranda o achica todo el HUD (accesibilidad).
#  - Con el menú de pausa, las mutaciones o el fin de run abiertos, se esconde.
# Clase 8: si el cazador te persigue, el borde rojo late con su corazón (lo marca
# Cazador.amenaza) aunque tengas la vida llena, y su aviso tiene prioridad.

const COLOR_PELIGRO = Color("#B22222")
const COLOR_HUESO = Color(0.949, 0.929, 0.894)
const COLOR_COMIDA = Color(0.831, 0.639, 0.451)
const COLOR_APAGADO = Color(0.09, 0.094, 0.106, 0.9)
const COLOR_SANO = Color("#7FA650")
@export var duracion_aviso = 2.0
# Lo que el rastro de daño espera antes de bajar y lo rápido que baja (vida/s).
@export var espera_rastro = 0.45
@export var rapidez_rastro = 60.0
# Por debajo de esta fracción de vida el recuadro late y aparece el borde rojo.
@export var umbral_poca_vida = 0.3
# Segundos antes del cierre de la salida en los que el reloj avisa.
@export var aviso_cierre = 30.0
# Tamaño de todo el HUD (1 = normal). Para pantallas pequeñas o lejos de la tele.
@export_range(0.6, 2.0, 0.05) var escala = 1.0
# Segundos sin cambios para que lo secundario se atenúe, y cuánto se atenúa.
@export var espera_calma = 4.0
@export var alfa_calma = 0.55
# Por debajo de este ancho (en píxeles del HUD) se usa el modo compacto.
@export var ancho_compacto = 980.0
const MARGEN = 16.0

@onready var raiz = $Raiz
@onready var panel_vida = $Raiz/PanelVida
@onready var valor_vida = $Raiz/PanelVida/Fila/Datos/Cabecera/Valor
@onready var barra_vida = $Raiz/PanelVida/Fila/Datos/Barras/Barra
@onready var rastro_vida = $Raiz/PanelVida/Fila/Datos/Barras/Rastro
@onready var vineta = $Raiz/Vineta
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
var flecha = null
var vida_actual = 0
var vida_max = 100
var reloj_rastro = 0.0
var sacudida = 0.0
var pos_vida = Vector2.ZERO
var relleno_vida = null
var latido = 0.0
var pos_aviso_y = 0.0
var puntos_mostrados = -1.0
var puntos_objetivo = -1
var cargas_vistas = -1
var segundo_visto = -1
# Segundos que lleva cada recuadro secundario sin cambiar.
var calma = {}
var compacto = false
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
	relleno_vida = barra_vida.get_theme_stylebox("fill").duplicate()
	barra_vida.add_theme_stylebox_override("fill", relleno_vida)
	# Las otras barras, color comida: así un relleno blanco del pack sirve para todas.
	for b in [recarga, barra]:
		var relleno = b.get_theme_stylebox("fill").duplicate()
		PielFlat.colorear(relleno, COLOR_COMIDA)
		b.add_theme_stylebox_override("fill", relleno)
	pos_vida = panel_vida.position
	pos_aviso_y = aviso.position.y
	salud.cambio.connect(mostrar)
	salud.golpeado.connect(_al_recibir_golpe)
	mostrar(salud.vida)
	barra_vida.value = salud.vida
	rastro_vida.value = salud.vida
	# Se crea aquí y no al declarar: así no queda suelta si el HUD se borra antes.
	flecha = Polygon2D.new()
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
	# Always: puede esconderse y volver aunque el juego esté en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for panel in [panel_puntos, panel_embestida, mutaciones]:
		calma[panel] = 0.0
	get_viewport().size_changed.connect(acomodar)
	acomodar.call_deferred()

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
	# Una sola vez por humano (las señales con bind no se reconocen con is_connected).
	if not is_instance_valid(h) or h.has_meta("hud_conectado"):
		return
	h.set_meta("hud_conectado", true)
	# El cazador es el peor: su aviso tapa a los demás.
	if h.has_signal("aparecio"):
		h.me_vio.connect(avisar.bind("¡EL CAZADOR TE VIO!", COLOR_PELIGRO, 3))
	else:
		h.me_vio.connect(avisar.bind("TE VIO", COLOR_PELIGRO, 2))
	if h.has_signal("sospecha"):
		h.sospecha.connect(avisar.bind("SOSPECHA", COLOR_HUESO, 1))

func avisar(texto, color, prioridad):
	if reloj_aviso > 0.0 and prioridad < prioridad_aviso:
		return
	texto_aviso.text = texto
	texto_aviso.add_theme_color_override("font_color", color)
	var caja = aviso.get_theme_stylebox("panel").duplicate()
	if caja is StyleBoxFlat:
		caja.border_color = color
	aviso.add_theme_stylebox_override("panel", caja)
	aviso.visible = true
	centrar(aviso)
	saltar(aviso, 0.6)
	reloj_aviso = duracion_aviso
	prioridad_aviso = prioridad

# Un salto de tamaño que vuelve a 1 con rebote. desde < 1 crece, > 1 encoge.
func saltar(control, desde = 1.3):
	control.pivot_offset = control.size * 0.5
	if control.has_meta("salto") and control.get_meta("salto").is_valid():
		control.get_meta("salto").kill()
	control.scale = Vector2.ONE * desde
	var t = control.create_tween()
	t.tween_property(control, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	control.set_meta("salto", t)

# Texto que sube y se desvanece ("+100").
func flotar(texto, color, donde):
	var l = Label.new()
	l.text = texto
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", 20)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(l)
	l.position = donde - l.get_minimum_size() * Vector2(1.0, 0.0)
	var t = l.create_tween().set_parallel()
	t.tween_property(l, "position:y", donde.y - 34.0, 0.9).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.3)
	t.chain().tween_callback(l.queue_free)

# Un recuadro anclado al centro se ajusta a su texto y vuelve al medio.
func centrar(control):
	control.reset_size()
	control.position.x = (raiz.size.x - control.size.x) * 0.5

func _process(delta):
	reloj_aviso = maxf(reloj_aviso - delta, 0.0)
	# El último medio segundo se desvanece.
	aviso.modulate.a = clampf(reloj_aviso / 0.5, 0.0, 1.0)
	aviso.visible = reloj_aviso > 0.0
	# Y mientras se desvanece, sube un poco.
	aviso.position.y = pos_aviso_y - (1.0 - aviso.modulate.a) * 14.0
	esconder_en_menus(delta)
	apartar(delta)
	animar_vida(delta)
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
	barra.position = camara.unproject_position(cabeza) / escala - barra.size * 0.5

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
	if vida > vida_actual and vida_actual > 0:
		destellar(panel_vida, Color(1.0, 1.35, 0.9))
	elif vida < vida_actual:
		# Cada pérdida reinicia la espera: el rastro baja cuando paran los golpes.
		reloj_rastro = espera_rastro
	vida_actual = vida
	valor_vida.text = str(vida)

func _al_recibir_golpe(_danio):
	sacudida = 0.3
	destellar(panel_vida, Color(1.8, 0.55, 0.55))

# Un golpe de color que se apaga solo (lo devuelve a blanco animar_vida).
func destellar(control, color):
	control.modulate = color

func animar_vida(delta):
	# La barra sigue a la vida rápido; el rastro espera y luego baja despacio.
	barra_vida.value = lerpf(barra_vida.value, vida_actual, 1.0 - exp(-14.0 * delta))
	if rastro_vida.value < vida_actual:
		rastro_vida.value = vida_actual
	reloj_rastro = maxf(reloj_rastro - delta, 0.0)
	if reloj_rastro <= 0.0:
		rastro_vida.value = move_toward(rastro_vida.value, vida_actual, rapidez_rastro * delta)
	var fraccion = float(vida_actual) / vida_max
	PielFlat.colorear(relleno_vida, color_vida(fraccion))
	# Temblor del recuadro tras un golpe.
	sacudida = maxf(sacudida - delta, 0.0)
	var fuerza = 7.0 * sacudida / 0.3
	panel_vida.position = pos_vida + Vector2(randf_range(-fuerza, fuerza), randf_range(-fuerza, fuerza))
	# Con poca vida late (más rápido cuanto menos queda) y el borde rojo aparece.
	var peligro = clampf(1.0 - fraccion / umbral_poca_vida, 0.0, 1.0) if vida_actual > 0 else 0.0
	latido += delta * lerpf(4.0, 9.0, peligro)
	var pulso = (sin(latido) * 0.5 + 0.5) * peligro
	var base = Color.WHITE.lerp(Color(1.4, 0.75, 0.75), pulso)
	panel_vida.modulate = panel_vida.modulate.lerp(base, 1.0 - exp(-8.0 * delta))
	var rojo = peligro * (0.35 + 0.35 * pulso)
	# El cazador: un golpe de rojo con cada latido que se apaga enseguida.
	var cazador = get_tree().get_first_node_in_group("cazador")
	if cazador != null and "amenaza" in cazador and cazador.amenaza > 0.0:
		rojo = maxf(rojo, cazador.amenaza * (0.25 + 0.45 * exp(-7.0 * cazador.desde_latido)))
	vineta.modulate.a = lerpf(vineta.modulate.a, rojo, 1.0 - exp(-14.0 * delta))

# Verde sano -> ámbar a media vida -> rojo con poca.
func color_vida(fraccion):
	if fraccion > 0.5:
		return COLOR_COMIDA.lerp(COLOR_SANO, (fraccion - 0.5) / 0.5)
	return COLOR_PELIGRO.lerp(COLOR_COMIDA, clampf((fraccion - 0.15) / 0.35, 0.0, 1.0))

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
	avisar_cierre()
	colocar_centro()
	fila_comida.visible = partida.metas > 0
	if partida.metas != metas_dibujadas or partida.hechas != hechas_dibujadas:
		dibujar_pips(partida.metas, mini(partida.hechas, partida.metas))
	var falta = partida.tiempo_tarde - partida.tiempo
	if partida.tarde:
		mostrar_estado_salida("SALIDA CERRADA", COLOR_PELIGRO)
	elif partida.abierta and falta <= aviso_cierre:
		mostrar_estado_salida("CIERRA EN " + str(ceili(falta)) + " s", COLOR_PELIGRO)
	elif partida.abierta:
		mostrar_estado_salida("SALIDA ABIERTA", COLOR_COMIDA)
	else:
		estado_salida.visible = false

# Los últimos segundos antes de que cierre la salida: el reloj se pone rojo y late
# una vez por segundo.
func avisar_cierre():
	var falta = partida.tiempo_tarde - partida.tiempo
	var cerca = not partida.tarde and falta <= aviso_cierre
	texto_tiempo.add_theme_color_override("font_color", COLOR_PELIGRO if cerca or partida.tarde else COLOR_HUESO)
	var segundo = ceili(falta)
	if cerca and segundo != segundo_visto:
		saltar(texto_tiempo, 1.25)
	segundo_visto = segundo

func mostrar_estado_salida(texto, color):
	if not estado_salida.visible or estado_salida.text.begins_with("SALIDA") != texto.begins_with("SALIDA"):
		saltar(panel_objetivo, 1.12)
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
		# El que se acaba de comer salta.
		if i < hechas and i >= hechas_dibujadas and hechas_dibujadas >= 0:
			saltar.call_deferred(pips.get_child(i), 1.8)
	hechas_dibujadas = hechas

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
	var objetivo = puntos.en_curso()
	if puntos_mostrados < 0.0:
		puntos_mostrados = objetivo
	elif objetivo > puntos_objetivo:
		var r = texto_puntos.get_global_rect()
		flotar("+" + str(objetivo - puntos_objetivo), COLOR_COMIDA, Vector2(r.end.x, r.end.y + 48.0))
		saltar(texto_puntos, 1.3)
		despertar(panel_puntos)
		panel_puntos.modulate = Color(1.3, 1.2, 1.0)
	puntos_objetivo = objetivo
	# Cuenta hacia arriba: rápido si es mucho, nunca más de un segundo.
	var rapidez = maxf(absf(objetivo - puntos_mostrados) * 3.0, 120.0)
	puntos_mostrados = move_toward(puntos_mostrados, objetivo, rapidez * get_process_delta_time())
	texto_puntos.text = str(int(round(puntos_mostrados)))
	texto_record.text = "RÉCORD " + str(maxi(puntos.record, 0))
	# Récord superado en esta run: lo dice.
	if puntos.record > 0 and objetivo > puntos.record:
		texto_record.text = "¡NUEVO RÉCORD!"

# Barra que se llena mientras recarga. "LISTA", "x2" con dos cargas.
func actualizar_embestida():
	if embestida == null:
		return
	var listas = embestida.cargas
	# Recuperó una carga: la tecla salta y el recuadro destella.
	if cargas_vistas >= 0 and listas > cargas_vistas:
		saltar($Raiz/PanelEmbestida/Fila/Tecla, 1.35)
		panel_embestida.modulate = Color(1.35, 1.25, 1.0)
		despertar(panel_embestida)
	cargas_vistas = listas
	# Recargando no se atenúa: es información que se está usando.
	if listas < embestida.cargas_max:
		despertar(panel_embestida)
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
		ficha.tooltip_text = Mutaciones.descripcion(nombre)
		var texto = Label.new()
		texto.theme_type_variation = &"LabelChip"
		texto.text = nombre_corto(nombre) if compacto else nombre
		ficha.add_child(texto)
		mutaciones.add_child(ficha)
	despertar(mutaciones)

# "Estómago de hierro" -> "Estómago" en modo compacto.
func nombre_corto(nombre):
	return nombre.split(" ")[0]

func despertar(panel):
	calma[panel] = 0.0

# Lo secundario se atenúa en calma; lo que tapa al zombi se vuelve transparente.
func apartar(delta):
	var zombi = posicion_zombi()
	var paneles = [panel_vida, panel_objetivo, panel_puntos, panel_embestida, mutaciones]
	for panel in paneles:
		var alfa = 1.0
		if calma.has(panel):
			calma[panel] += delta
			if calma[panel] > espera_calma:
				alfa = alfa_calma
		if zombi != null and panel.visible and panel.get_rect().grow(24.0).has_point(zombi):
			alfa = minf(alfa, 0.3)
		var objetivo = Color(1, 1, 1, alfa)
		if panel == panel_vida:
			# La vida lleva su propio color (latido); aquí solo se toca su alfa.
			panel.modulate.a = lerpf(panel.modulate.a, alfa, 1.0 - exp(-6.0 * delta))
		else:
			panel.modulate = panel.modulate.lerp(objetivo, 1.0 - exp(-6.0 * delta))

# Dónde está el zombi en la pantalla, en coordenadas del HUD (con su escala).
func posicion_zombi():
	var camara = get_viewport().get_camera_3d()
	if camara == null or jugador == null:
		return null
	return camara.unproject_position(jugador.global_position + Vector3(0, 0.9, 0)) / escala

# Pausa, mutaciones o fin de run: el HUD se esconde para no competir con el menú.
func esconder_en_menus(delta):
	var hay_menu = false
	for grupo in ["fin_run", "pantalla_mutaciones"]:
		var m = get_tree().get_first_node_in_group(grupo)
		if m != null and m.visible:
			hay_menu = true
	# Pausa con el juego en marcha = el menú de pausa (al terminar la zona también
	# se pausa, pero ahí el HUD sigue para ver los puntos del piso).
	if get_tree().paused and partida != null and partida.estado == partida.Estado.JUGANDO:
		hay_menu = true
	raiz.modulate.a = move_toward(raiz.modulate.a, 0.0 if hay_menu else 1.0, delta / 0.2)

# Escala, modo compacto y que el centro no choque con las esquinas.
func acomodar():
	var pantalla = get_viewport().get_visible_rect().size
	raiz.scale = Vector2.ONE * escala
	# Raiz ocupa toda la pantalla medida en píxeles del HUD (ya escalados).
	raiz.offset_right = pantalla.x / escala - pantalla.x
	raiz.offset_bottom = pantalla.y / escala - pantalla.y
	var ancho = pantalla.x / escala
	var antes = compacto
	compacto = ancho < ancho_compacto
	$Raiz/PanelVida/Fila/Datos/Barras.custom_minimum_size.x = 150.0 if compacto else 220.0
	texto_record.visible = not compacto
	$Raiz/PanelEmbestida/Fila/Datos/Cabecera/Titulo.visible = not compacto
	$Raiz/PanelEmbestida/Fila/Tecla/Texto.text = "ESP" if compacto else "ESPACIO"
	if antes != compacto:
		mutaciones_dibujadas = -1
	for panel in [panel_vida, panel_puntos, panel_embestida]:
		panel.reset_size()
	panel_puntos.position.x = ancho - MARGEN - panel_puntos.size.x
	panel_embestida.position = Vector2(ancho, pantalla.y / escala) - panel_embestida.size - Vector2(MARGEN, MARGEN)
	pos_vida = Vector2(MARGEN, MARGEN)
	if partida != null:
		colocar_centro.call_deferred()

# El recuadro del centro va arriba; si no cabe entre las esquinas, baja.
func colocar_centro():
	centrar(panel_objetivo)
	var izquierda = panel_vida.position.x + panel_vida.size.x + 8.0
	var derecha = panel_puntos.position.x - 8.0
	var cabe = panel_objetivo.position.x >= izquierda and panel_objetivo.position.x + panel_objetivo.size.x <= derecha
	var abajo = maxf(panel_vida.position.y + panel_vida.size.y, panel_puntos.position.y + panel_puntos.size.y) + 8.0
	panel_objetivo.position.y = MARGEN if cabe else abajo
	pos_aviso_y = panel_objetivo.position.y + panel_objetivo.size.y + 22.0
