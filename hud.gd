extends CanvasLayer

# Taller 10 - Tarea B (María Sofía): el HUD solo muestra; la vida vive en la Salud
# y el tiempo en la Partida.
# La vida llega por señal. El tiempo cambia cada cuadro, por eso se lee en _process.
# Clase 3: avisos de estado en texto, grandes y arriba: "TE VIO", "SOSPECHA",
# "SALIDA ABIERTA" y "SALIDA CERRADA". Duran unos segundos y se apagan.
# Clase 7: recuadros anclados con el tema flat (ui/tema_flat.tres); la vida es un
# elemento vivo (rastro, temblor, destello, latido y borde rojo); el HUD se adapta
# (lo secundario se atenúa, lo que tapa al zombi se vuelve transparente, modo
# compacto, escala) y se esconde con los menús.
# Clase 8: si el cazador te persigue, el borde rojo late con su corazón.
#
# Rediseño (HUD orgánico): cada cosa se muestra donde se entiende mejor.
#  Esquinas, lo que dura toda la partida:
#   arriba izquierda -> TU CUERPO: barra de carne cosida (vida) y la pudrición,
#                       que dice cuánto se pierde y cuándo (el reloj es tu cuerpo).
#   arriba centro    -> el objetivo como una frase: comida › salida › reloj, y
#                       debajo qué hacer ahora ("Come 2 para abrir la salida").
#   arriba derecha   -> puntos, récord y saldo (secundario: se atenúa).
#   abajo izquierda  -> SIGILO: si te ven y cuánto ruido haces; debajo, mutaciones.
#   abajo derecha    -> embestida.
#  En el mundo, lo que pasa en un sitio concreto:
#   - sobre la comida cercana, qué es, qué da y un anillo que se llena con E;
#   - sobre el humano que se puede morder, "DEVORAR" y su anillo;
#   - "?" sobre quien te busca, "!" sobre quien te vio, "zZ" sobre el aturdido;
#   - la salida abierta se marca (y si no se ve, una flecha en el borde);
#   - los números de vida salen del zombi.

const COLOR_PELIGRO = Color("#B22222")
const COLOR_ROJO = Color(0.937, 0.267, 0.227)
const COLOR_HUESO = Color(0.949, 0.929, 0.894)
const COLOR_TENUE = Color(0.949, 0.929, 0.894, 0.6)
const COLOR_COMIDA = Color(0.831, 0.639, 0.451)
const COLOR_APAGADO = Color(0.09, 0.094, 0.106, 0.9)
const COLOR_SANO = Color("#7FA650")
const COLOR_AMBAR = Color(0.96, 0.72, 0.28)
const COLOR_PODRIDO = Color(0.55, 0.85, 0.25)
const COLOR_CEREBRO = Color(0.96, 0.62, 0.7)
const COLOR_SALIDA = Color(0.2, 0.8, 0.3)
const COLOR_OSCURO = Color(0.06, 0.06, 0.07, 0.9)
const OJO_ABIERTO = preload("res://ui/iconos/ojo_abierto.png")
const OJO_CERRADO = preload("res://ui/iconos/ojo_cerrado.png")

@export var duracion_aviso = 2.0
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
# Segundos que se ven los controles al empezar la run.
@export var segundos_controles = 8.0
const MARGEN = 16.0

@onready var raiz = $Raiz
@onready var vineta = $Raiz/Vineta
@onready var mundo = %Mundo
@onready var panel_vida = %PanelVida
@onready var barra_vida = %BarraVida
@onready var valor_vida = %ValorVida
@onready var icono_vida = %IconoVida
@onready var icono_pudricion = %IconoPudricion
@onready var barra_pudricion = %BarraPudricion
@onready var texto_pudricion = %TextoPudricion
@onready var panel_objetivo = %PanelObjetivo
@onready var texto_piso = %Piso
@onready var huecos = %Huecos
@onready var puerta = %Puerta
@onready var anillo_reloj = %AnilloReloj
@onready var texto_tiempo = %Tiempo
@onready var pista = %Pista
@onready var panel_puntos = %PanelPuntos
@onready var texto_puntos = %Puntos
@onready var texto_record = %Record
@onready var texto_saldo = %Saldo
@onready var panel_embestida = %PanelEmbestida
@onready var recarga = %Recarga
@onready var estado_embestida = %EstadoEmbestida
@onready var panel_sigilo = %PanelSigilo
@onready var ojo = %Ojo
@onready var texto_sigilo = %TextoSigilo
@onready var barras_ruido = %BarrasRuido
@onready var texto_ruido = %TextoRuido
@onready var mutaciones = %Mutaciones
@onready var controles = %Controles
@onready var aviso = %Aviso
@onready var texto_aviso = %TextoAviso
@onready var aviso_e = %AvisoE
@onready var punta_e = %Punta
@onready var anillo_e = %AnilloE
@onready var icono_e = %IconoE
@onready var nombre_e = %NombreE
@onready var efecto_e = %EfectoE
@onready var accion_e = %AccionE
@onready var marca_salida = %MarcaSalida
@onready var flecha_salida = %Flecha

var jugador = null
var salud = null
var interactuar = null
var mordisco = null
var embestida = null
var partida = null
var puntos = null
var reloj_aviso = 0.0
# Un aviso importante (TE VIO) no lo tapa uno menor (SOSPECHA) mientras dura.
var prioridad_aviso = 0
# Mutación "Olfato": una flecha color comida alrededor del zombi que apunta al
# alimento más cercano.
var flecha = null
var vida_actual = 0
var vida_max = 100
var golpe_reciente = false
var sacudida = 0.0
var pos_vida = Vector2.ZERO
var latido = 0.0
var pos_aviso_y = 0.0
var puntos_mostrados = -1.0
var puntos_objetivo = -1
var cargas_vistas = -1
var segundo_visto = -1
var nivel_visto = 0
var t = 0.0
# Segundos que lleva cada recuadro secundario sin cambiar.
var calma = {}
var compacto = false
var instinto_avisado = false
# Lo que ya se dibujó: solo se reconstruye cuando cambia.
var metas_dibujadas = -1
var hechas_dibujadas = -1
var mutaciones_dibujadas = -1
# Iconos de lo que se comió, en orden: llenan las casillas de comida.
var comidos = []
# El cerebro detiene la pudrición: el HUD cuenta lo que le queda.
var pausa_cerebro = 0.0
# A quién apunta el aviso de la E (un alimento o un humano) y "?"/"!" por humano.
var aviso_de = null
var marcas = {}

func _ready():
	PielFlat.aplicar(raiz.theme)
	poner_iconos()
	jugador = get_tree().get_first_node_in_group("jugador")
	interactuar = jugador.get_node_or_null("Interactuar")
	mordisco = jugador.get_node_or_null("Mordisco")
	embestida = jugador.get_node_or_null("Embestida")
	panel_embestida.visible = embestida != null
	salud = jugador.get_node("Salud")
	vida_max = maxi(salud.vida_inicial if salud.vida_inicial > 0 else salud.vida, 1)
	vida_actual = salud.vida
	barra_vida.valor = float(vida_actual) / vida_max
	barra_vida.mostrado = barra_vida.valor
	barra_vida.rastro = barra_vida.valor
	barra_vida.anterior = barra_vida.valor
	valor_vida.text = str(vida_actual)
	pos_vida = panel_vida.position
	pos_aviso_y = aviso.position.y
	salud.cambio.connect(mostrar)
	salud.golpeado.connect(_al_recibir_golpe)
	if salud.has_signal("reaparecio"):
		salud.reaparecio.connect(avisar.bind("¡SEGUNDA VIDA!", COLOR_COMIDA, 3))
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
	for a in get_tree().get_nodes_in_group("alimentos"):
		conectar_alimento(a)
	get_tree().node_added.connect(_al_aparecer)
	call_deferred("conectar_partida")
	# Always: puede esconderse y volver aunque el juego esté en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for panel in [panel_puntos, panel_embestida, mutaciones, panel_sigilo]:
		calma[panel] = 0.0
	aviso_e.modulate.a = 0.0
	get_viewport().size_changed.connect(acomodar)
	acomodar.call_deferred()

# Iconos del pack (res://ui/flat_ui/iconos/). Vida, comida y salida usan los del
# juego (ui/iconos); puntos y embestida, el del pack si está.
func poner_iconos():
	var lugares = {"puntos": %IconoPuntos, "embestida": %IconoEmbestida}
	for nombre in lugares:
		var textura = PielFlat.icono(nombre)
		lugares[nombre].texture = textura
		lugares[nombre].visible = textura != null

func conectar_partida():
	var p = get_tree().get_first_node_in_group("partida")
	if p == null:
		return
	p.salida_abierta.connect(avisar.bind("SALIDA ABIERTA", COLOR_SALIDA, 1))
	p.zona_cambiada.connect(func(n): avisar("PISO " + str(n), COLOR_HUESO, 1))
	p.salida_cerrada.connect(avisar.bind("SALIDA CERRADA", COLOR_PELIGRO, 2))

# node_added llega antes de su _ready: el grupo todavía no está puesto.
func _al_aparecer(nodo):
	if nodo.has_signal("me_vio"):
		conectar_humano.call_deferred(nodo)
	if nodo.has_signal("aparecio"):
		nodo.aparecio.connect(avisar.bind("LLEGÓ EL CAZADOR", COLOR_PELIGRO, 3))
	if nodo.has_signal("comido"):
		conectar_alimento.call_deferred(nodo)

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
		h.sospecha.connect(avisar.bind("SOSPECHA", COLOR_AMBAR, 1))

func conectar_alimento(a):
	if is_instance_valid(a) and not a.comido.is_connected(_al_comer):
		a.comido.connect(_al_comer)

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
	var tw = control.create_tween()
	tw.tween_property(control, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	control.set_meta("salto", tw)

# Texto que sube y se desvanece ("+100", "+20", "−15").
func flotar(texto, color, donde, tamano = 20):
	var l = Label.new()
	l.text = texto
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", COLOR_OSCURO)
	l.add_theme_constant_override("outline_size", 7)
	l.add_theme_font_size_override("font_size", tamano)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mundo.add_child(l)
	l.position = donde - l.get_minimum_size() * 0.5
	var tw = l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", l.position.y - 40.0, 0.9).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.45)
	tw.chain().tween_callback(l.queue_free)

# Un recuadro anclado al centro se ajusta a su texto y vuelve al medio.
func centrar(control):
	control.reset_size()
	control.position.x = (raiz.size.x - control.size.x) * 0.5

func _process(delta):
	t += delta
	reloj_aviso = maxf(reloj_aviso - delta, 0.0)
	# El último medio segundo se desvanece y sube un poco.
	aviso.modulate.a = clampf(reloj_aviso / 0.5, 0.0, 1.0)
	aviso.visible = reloj_aviso > 0.0
	aviso.position.y = pos_aviso_y - (1.0 - aviso.modulate.a) * 14.0
	if partida == null:
		partida = get_tree().get_first_node_in_group("partida")
	if not get_tree().paused:
		pausa_cerebro = maxf(pausa_cerebro - delta, 0.0)
	esconder_en_menus(delta)
	apartar(delta)
	animar_vida(delta)
	actualizar_pudricion()
	actualizar_objetivo()
	actualizar_puntos()
	actualizar_embestida()
	actualizar_sigilo()
	actualizar_mutaciones()
	colocar_sigilo()
	actualizar_aviso_e(delta)
	actualizar_marcas()
	actualizar_salida()
	actualizar_flecha()
	actualizar_controles()

func jugando():
	return partida == null or partida.estado == partida.Estado.JUGANDO

# De la posición 3D a la pantalla, en coordenadas del HUD (con su escala).
# null si la cámara no lo ve (detrás).
func a_pantalla(pos):
	var camara = get_viewport().get_camera_3d()
	if camara == null or camara.is_position_behind(pos):
		return null
	return camara.unproject_position(pos) / escala

# ---------------------------------------------------------------- tu cuerpo

func mostrar(vida):
	var diferencia = vida - vida_actual
	if diferencia > 0 and vida_actual > 0:
		destellar(panel_vida, Color(1.0, 1.35, 0.9))
	vida_actual = vida
	valor_vida.text = str(vida)
	# Los números salen del zombi. Correr (−1) y regenerar (+1) no: serían ruido.
	var cabeza = a_pantalla(jugador.global_position + Vector3(0, 2.1, 0)) if jugador != null else null
	if cabeza != null and absi(diferencia) >= 2:
		if diferencia > 0:
			flotar("+%d" % diferencia, COLOR_COMIDA, cabeza, 26)
		elif golpe_reciente:
			flotar("−%d" % -diferencia, COLOR_ROJO, cabeza, 26)
		else:
			flotar("−%d" % -diferencia, COLOR_PODRIDO, cabeza, 22)
			saltar(icono_pudricion, 1.5)
	golpe_reciente = false

func _al_recibir_golpe(_danio):
	# El golpe llega antes que el cambio de vida: así se sabe si fue un humano.
	golpe_reciente = true
	sacudida = 0.3
	destellar(panel_vida, Color(1.8, 0.55, 0.55))
	saltar(icono_vida, 1.4)

# Un golpe de color que se apaga solo (lo devuelve a blanco animar_vida).
func destellar(control, color):
	control.modulate = color

func animar_vida(delta):
	var fraccion = float(vida_actual) / vida_max
	barra_vida.valor = fraccion
	barra_vida.color_lleno = color_vida(fraccion)
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
	valor_vida.modulate = Color.WHITE.lerp(COLOR_ROJO, pulso)
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

# La pudrición dice cuánto se pierde y cuándo; también lo que cuesta correr.
func actualizar_pudricion():
	if salud.vida == 0:
		texto_pudricion.text = "ya no queda cuerpo"
		return
	var intervalo = maxf(salud.intervalo_descomposicion, 0.01)
	var perdida = int(round(salud.vida_inicial * salud.porcentaje_descomposicion))
	barra_pudricion.valor = clampf(salud.acumulado / intervalo, 0.0, 1.0)
	if salud.factor_descomposicion <= 0.0:
		barra_pudricion.color_lleno = COLOR_CEREBRO
		icono_pudricion.modulate = COLOR_CEREBRO
		if pausa_cerebro > 0.0:
			texto_pudricion.text = "cerebro: no te pudres (%d s)" % ceili(pausa_cerebro)
		else:
			texto_pudricion.text = "cerebro: no te pudres"
		return
	barra_pudricion.color_lleno = COLOR_PODRIDO
	icono_pudricion.modulate = Color.WHITE
	if jugador.estado == Personaje.Estado.CORRER and "costo_correr" in jugador:
		texto_pudricion.text = "corriendo: −%s por segundo" % String.num(jugador.costo_correr, 1)
		return
	var falta = (intervalo - salud.acumulado) / maxf(salud.factor_descomposicion, 0.01)
	texto_pudricion.text = "te pudres: −%d en %d s" % [perdida, ceili(falta)]

# ---------------------------------------------------------------- el objetivo

# Comida › salida › reloj, y debajo una frase con lo que toca hacer ahora.
func actualizar_objetivo():
	panel_objetivo.visible = partida != null
	if partida == null:
		return
	texto_piso.text = "PISO " + str(Partida.zona) + "/" + str(partida.zonas_total)
	texto_tiempo.text = partida.reloj_texto(partida.tiempo)
	avisar_instinto()
	colocar_centro()
	huecos.visible = partida.metas > 0
	if partida.metas != metas_dibujadas or partida.hechas != hechas_dibujadas:
		dibujar_huecos(partida.metas, mini(partida.hechas, partida.metas))
	var falta_cierre = partida.tiempo_tarde - partida.tiempo
	var falta_fin = partida.tiempo_reinicio - partida.tiempo
	var cerca = not partida.tarde and falta_cierre <= aviso_cierre
	# El anillo es lo que queda hasta que la salida cierra; después, hasta el final.
	if partida.tarde:
		var tramo = maxf(partida.tiempo_reinicio - partida.tiempo_tarde, 0.01)
		anillo_reloj.valor = clampf(falta_fin / tramo, 0.0, 1.0)
	else:
		anillo_reloj.valor = clampf(falta_cierre / maxf(partida.tiempo_tarde, 0.01), 0.0, 1.0)
	var rojo = partida.tarde or cerca
	anillo_reloj.color_lleno = COLOR_ROJO if rojo else COLOR_HUESO
	texto_tiempo.modulate = COLOR_ROJO if rojo else Color.WHITE
	# Los últimos segundos antes del cierre el reloj late una vez por segundo.
	var segundo = ceili(falta_cierre)
	if cerca and segundo != segundo_visto:
		saltar(texto_tiempo, 1.25)
	segundo_visto = segundo
	var come = partida.metas - partida.hechas
	if partida.tarde:
		puerta.modulate = COLOR_ROJO
		if partida.cumplio():
			pista.text = "La salida cerró: si la pisas, pierdes · fin en " + partida.reloj_texto(falta_fin)
		else:
			pista.text = "La salida cerró · el piso acaba en " + partida.reloj_texto(falta_fin)
		pista.modulate = COLOR_ROJO
	elif partida.abierta:
		puerta.modulate = COLOR_SALIDA
		pista.text = "¡Ve a la salida! Cierra en " + partida.reloj_texto(falta_cierre)
		pista.modulate = COLOR_ROJO if cerca else COLOR_SALIDA.lerp(COLOR_HUESO, 0.35)
	elif partida.metas > 0:
		puerta.modulate = COLOR_TENUE
		var cuanto = "1 más" if come == 1 else str(come)
		pista.text = "Come %s para abrir la salida" % cuanto
		if cerca:
			pista.text += " · cierra en " + partida.reloj_texto(falta_cierre)
		pista.modulate = COLOR_ROJO if cerca else Color.WHITE
	else:
		pista.text = ""

# Mutación "Instinto": 15 s antes de que aparezca el cazador, un aviso.
func avisar_instinto():
	if instinto_avisado or not Mutaciones.tiene("Instinto"):
		return
	var cazador = get_tree().get_first_node_in_group("cazador")
	if cazador == null or not "antelacion" in cazador or cazador.activo:
		return
	if partida.tiempo >= partida.tiempo_tarde - cazador.antelacion - 15.0:
		instinto_avisado = true
		avisar("EL CAZADOR LLEGA EN 15 s", COLOR_PELIGRO, 2)

func _al_comer(alimento):
	comidos.append(alimento.icono if "icono" in alimento else null)
	if "pausa_descomposicion" in alimento and alimento.pausa_descomposicion > 0.0:
		pausa_cerebro = alimento.pausa_descomposicion

# Una casilla por alimento de la meta: se llena con el icono de lo comido.
func dibujar_huecos(metas, hechas):
	if metas != metas_dibujadas:
		for h in huecos.get_children():
			huecos.remove_child(h)
			h.queue_free()
		for i in metas:
			var hueco = Panel.new()
			hueco.custom_minimum_size = Vector2(34, 34)
			hueco.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var icono = TextureRect.new()
			icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icono.position = Vector2(2, 2)
			icono.size = Vector2(30, 30)
			hueco.add_child(icono)
			huecos.add_child(hueco)
		metas_dibujadas = metas
	for i in huecos.get_child_count():
		var hueco = huecos.get_child(i)
		var lleno = i < hechas
		hueco.add_theme_stylebox_override("panel", estilo_hueco(lleno))
		var icono = hueco.get_child(0)
		icono.texture = comidos[i] if lleno and i < comidos.size() else null
		# El que se acaba de comer salta.
		if lleno and i >= hechas_dibujadas and hechas_dibujadas >= 0:
			saltar.call_deferred(icono, 1.9)
	hechas_dibujadas = hechas

func estilo_hueco(lleno):
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.2, 0.17, 0.15, 0.95) if lleno else COLOR_APAGADO
	s.set_border_width_all(2)
	s.border_color = COLOR_COMIDA if lleno else Color(COLOR_COMIDA, 0.35)
	s.corner_radius_top_left = 13
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_right = 13
	s.corner_radius_bottom_left = 6
	s.anti_aliasing = true
	return s

# ---------------------------------------------------------------- puntos y embestida

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
		var donde = panel_puntos.position + Vector2(panel_puntos.size.x - 30.0, panel_puntos.size.y + 14.0)
		flotar("+" + str(objetivo - puntos_objetivo), COLOR_COMIDA, donde)
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
	var piso = Partida.zona if partida != null else 1
	texto_saldo.text = "SALDO " + str(Puntuacion.saldo()) + " · x" + String.num(Puntuacion.multiplicador(piso))

# Barra que se llena mientras recarga. "LISTA", "x2" con dos cargas.
func actualizar_embestida():
	if embestida == null:
		return
	var listas = embestida.cargas
	# Recuperó una carga: la tecla salta y el recuadro destella.
	if cargas_vistas >= 0 and listas > cargas_vistas:
		saltar(%Tecla, 1.35)
		panel_embestida.modulate = Color(1.35, 1.25, 1.0)
		despertar(panel_embestida)
	cargas_vistas = listas
	# Recargando no se atenúa: es información que se está usando.
	if listas < embestida.cargas_max:
		despertar(panel_embestida)
	if listas >= embestida.cargas_max:
		recarga.valor = 1.0
	else:
		recarga.valor = 1.0 - embestida.recarga / maxf(embestida.enfriamiento, 0.01)
	recarga.color_lleno = COLOR_COMIDA if listas > 0 else Color(COLOR_COMIDA, 0.55)
	if listas <= 0:
		estado_embestida.text = str(snappedf(embestida.recarga, 0.1)) + " s"
	elif embestida.cargas_max > 1:
		estado_embestida.text = "x" + str(listas)
	else:
		estado_embestida.text = "LISTA"

# ---------------------------------------------------------------- sigilo

# 3 te golpea, 2 te vio, 1 te busca (oyó o te perdió), 0 tranquilo, -1 aturdido.
func nivel_alerta(h):
	if not "estado" in h or not h.has_method("puede_verme"):
		return 0
	var e = h.estado
	var estados = h.Estado
	if e == estados.ATACAR:
		return 3
	if e == estados.PERSEGUIR:
		return 2
	if e == estados.SOSPECHA or e == estados.BUSCAR or e == estados.MIRAR:
		return 1
	if e == estados.ATURDIDO:
		return -1
	return 0

func actualizar_sigilo():
	var nivel = 0
	for h in get_tree().get_nodes_in_group("humanos"):
		nivel = maxi(nivel, nivel_alerta(h))
	if nivel != nivel_visto:
		despertar(panel_sigilo)
		if nivel > nivel_visto:
			saltar(ojo, 1.4)
		nivel_visto = nivel
	if nivel > 0:
		despertar(panel_sigilo)
	var textos = ["NADIE TE VE", "TE ESTÁN BUSCANDO", "¡TE VIERON!", "¡TE ESTÁN GOLPEANDO!"]
	var colores = [COLOR_TENUE, COLOR_AMBAR, COLOR_ROJO, COLOR_ROJO]
	var color = colores[nivel]
	if nivel >= 2:
		color = color.lerp(COLOR_HUESO, 0.35 * (0.5 + 0.5 * sin(t * 12.0)))
	texto_sigilo.text = textos[nivel]
	texto_sigilo.modulate = color
	ojo.texture = OJO_ABIERTO if nivel > 0 else OJO_CERRADO
	ojo.modulate = Color(COLOR_HUESO, 0.7) if nivel == 0 else color
	# Ruido: 0 quieto, 1 m caminando, 3 m corriendo (menos con "Pies de trapo").
	var ruido = jugador.ruido if "ruido" in jugador else 0.0
	var accion = "quieto"
	if jugador.estado == Personaje.Estado.CAMINAR:
		accion = "pasos · %s m" % String.num(ruido, 1)
	elif jugador.estado == Personaje.Estado.CORRER:
		accion = "corriendo · %s m" % String.num(ruido, 1)
		despertar(panel_sigilo)
	elif jugador.estado == Personaje.Estado.COMIENDO:
		accion = "comiendo"
	var encendidas = 0
	if ruido > 0.0:
		encendidas = 1 if ruido <= 1.0 else (2 if ruido < 3.0 else 3)
	var color_ruido = COLOR_AMBAR if encendidas >= 3 else COLOR_HUESO
	for i in barras_ruido.get_child_count():
		barras_ruido.get_child(i).color = color_ruido if i < encendidas else Color(COLOR_HUESO, 0.15)
	texto_ruido.text = accion

# "?" sobre quien te busca, "!" sobre quien te vio, "zZ" sobre el aturdido.
func actualizar_marcas():
	var hay_menu = raiz.modulate.a < 0.5
	var textos = {-1: "zZ", 1: "?", 2: "!", 3: "!!"}
	for h in get_tree().get_nodes_in_group("humanos"):
		var nivel = nivel_alerta(h) if jugando() and not hay_menu else 0
		var marca = marcas.get(h)
		var donde = a_pantalla(h.global_position + Vector3(0, 2.4, 0)) if nivel != 0 else null
		if donde == null:
			if marca != null:
				marca.visible = false
				marca.set_meta("nivel", 0)
			continue
		if marca == null:
			marca = crear_marca()
			marcas[h] = marca
		marca.visible = true
		marca.text = textos[nivel]
		marca.modulate = COLOR_HUESO if nivel == -1 else (COLOR_AMBAR if nivel == 1 else COLOR_ROJO)
		marca.position = donde - marca.size * 0.5
		# Salta cuando sube la alerta.
		if nivel > marca.get_meta("nivel", 0):
			saltar(marca, 1.8)
		marca.set_meta("nivel", nivel)
	# Los humanos que ya no están (devorados) se llevan su marca.
	for h in marcas.keys():
		if not is_instance_valid(h) or not h.is_in_group("humanos"):
			marcas[h].queue_free()
			marcas.erase(h)

func crear_marca():
	var marca = Label.new()
	marca.theme_type_variation = &"LabelGrande"
	marca.add_theme_font_size_override("font_size", 44)
	marca.add_theme_color_override("font_color", Color.WHITE)
	marca.add_theme_color_override("font_outline_color", COLOR_OSCURO)
	marca.add_theme_constant_override("outline_size", 10)
	marca.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marca.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	marca.size = Vector2(64, 56)
	marca.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mundo.add_child(marca)
	return marca

# ---------------------------------------------------------------- aviso de la E

# Sobre lo que se puede comer o morder: qué es, qué da y el anillo de progreso.
func actualizar_aviso_e(delta):
	var obj = null
	var es_humano = false
	var progreso = 0.0
	if jugando() and raiz.modulate.a > 0.5:
		if mordisco != null and mordisco.objetivo != null and is_instance_valid(mordisco.objetivo):
			obj = mordisco.objetivo
			es_humano = true
			progreso = mordisco.progreso
		elif interactuar != null:
			obj = interactuar.mas_cercano()
			if obj != null and interactuar.actual == obj:
				progreso = interactuar.progreso
			if obj == null and mordisco != null and mordisco.has_method("buscar"):
				obj = mordisco.buscar()
				es_humano = obj != null
	var meta = 1.0 if obj != null else 0.0
	aviso_e.modulate.a = aviso_e.modulate.a + (meta - aviso_e.modulate.a) * (1.0 - exp(-14.0 * delta))
	aviso_e.visible = aviso_e.modulate.a > 0.02
	if obj == null:
		anillo_e.valor = 0.0
		return
	if obj != aviso_de:
		aviso_de = obj
		llenar_aviso_e(obj, es_humano)
	anillo_e.valor = clampf(progreso, 0.0, 1.0)
	if progreso > 0.0:
		accion_e.text = "devorando…" if es_humano else "comiendo…"
	elif es_humano:
		accion_e.text = "mantén E · por la espalda"
	else:
		var tiempo = obj.tiempo_comer if "tiempo_comer" in obj else interactuar.tiempo_necesario
		accion_e.text = "mantén E · %s s" % String.num(tiempo, 1)
	var alto = 2.6 if es_humano else 1.1
	var donde = a_pantalla(obj.global_position + Vector3(0, alto, 0))
	if donde != null:
		colocar_aviso_e(donde)

func llenar_aviso_e(obj, es_humano):
	var color = COLOR_ROJO
	if es_humano:
		nombre_e.text = "DEVORAR"
		var cura = mordisco.curacion if "curacion" in mordisco else 35
		efecto_e.text = "+%d de vida · no te ve" % cura
		icono_e.texture = null
	else:
		color = obj.color if "color" in obj else COLOR_COMIDA
		var nombre = obj.nombre if "nombre" in obj else String(obj.name)
		nombre_e.text = nombre.to_upper()
		var efecto = ""
		if "curacion" in obj:
			efecto = "+%d de vida" % obj.curacion
		if "pausa_descomposicion" in obj and obj.pausa_descomposicion > 0.0:
			efecto += " · no te pudres %d s" % obj.pausa_descomposicion
		efecto_e.text = efecto
		icono_e.texture = obj.icono if "icono" in obj else null
	efecto_e.add_theme_color_override("font_color", color.lerp(COLOR_HUESO, 0.25))
	anillo_e.color_lleno = color
	anillo_e.mostrado = 0.0
	aviso_e.reset_size()

func colocar_aviso_e(p):
	var tam = aviso_e.size
	var pos = p - Vector2(tam.x * 0.5, tam.y + 12.0)
	pos.x = clampf(pos.x, 12.0, maxf(12.0, raiz.size.x - tam.x - 12.0))
	pos.y = clampf(pos.y, 12.0, maxf(12.0, raiz.size.y - tam.y - 12.0))
	aviso_e.position = pos
	punta_e.position = Vector2(clampf(p.x - pos.x, 18.0, tam.x - 18.0), tam.y)

# ---------------------------------------------------------------- la salida

# Con la salida abierta se marca dónde está; si no se ve, una flecha en el borde.
func actualizar_salida():
	var salida = get_tree().get_first_node_in_group("salida")
	var abierta = partida != null and partida.abierta and jugando() and raiz.modulate.a > 0.5
	marca_salida.visible = salida != null and abierta
	if not marca_salida.visible:
		return
	var camara = get_viewport().get_camera_3d()
	if camara == null:
		return
	var punto = salida.global_position + Vector3(0, 1.6, 0)
	var p = camara.unproject_position(punto) / escala
	var detras = camara.is_position_behind(punto)
	var margen = 40.0
	var dentro = not detras and p.x > margen and p.y > margen \
		and p.x < raiz.size.x - margen and p.y < raiz.size.y - margen
	var rebote = sin(t * 5.0) * 4.0
	var medio = marca_salida.size.x * 0.5
	if dentro:
		# Encima de la salida: "SALIDA" y una punta hacia abajo que rebota.
		marca_salida.position = p - Vector2(medio, 40.0 - rebote)
		flecha_salida.position = Vector2(medio, 34.0)
		flecha_salida.rotation = 0.0
		return
	# Fuera de la pantalla: pegada al borde, apuntando hacia la salida.
	var centro = raiz.size * 0.5
	var hacia = p - centro
	if detras:
		hacia = -hacia
	if hacia.length() < 1.0:
		return
	var limite = centro - Vector2(margen + 30.0, margen + 30.0)
	var kx = absf(limite.x / hacia.x) if absf(hacia.x) > 0.001 else INF
	var ky = absf(limite.y / hacia.y) if absf(hacia.y) > 0.001 else INF
	var dir = hacia.normalized()
	var borde = centro + hacia * minf(kx, ky) - dir * rebote
	marca_salida.position = borde - Vector2(medio, 30.0)
	flecha_salida.position = Vector2(medio, 34.0) + dir * 6.0
	# La punta dibujada apunta hacia abajo (+Y): se gira hacia la salida.
	flecha_salida.rotation = dir.angle() - PI * 0.5

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

# Al empezar la run se recuerdan los controles unos segundos.
func actualizar_controles():
	var dura = 0.0
	if Partida.zona == 1:
		dura = segundos_controles if Partida.intentos <= 1 else 3.0
	controles.modulate.a = clampf(dura - t, 0.0, 1.0)
	controles.visible = controles.modulate.a > 0.01

# ---------------------------------------------------------------- mutaciones y orden

# Una ficha por mutación elegida (la run entera).
func actualizar_mutaciones():
	if Mutaciones.elegidas.size() == mutaciones_dibujadas:
		return
	mutaciones_dibujadas = Mutaciones.elegidas.size()
	for c in mutaciones.get_children():
		mutaciones.remove_child(c)
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

# El sigilo va abajo a la izquierda, encima de las mutaciones si hay.
func colocar_sigilo():
	var abajo = raiz.size.y - MARGEN
	if mutaciones.get_child_count() > 0:
		abajo -= mutaciones.size.y + 8.0
	panel_sigilo.position = Vector2(MARGEN, abajo - panel_sigilo.size.y)

func despertar(panel):
	calma[panel] = 0.0

# Lo secundario se atenúa en calma; lo que tapa al zombi se vuelve transparente.
func apartar(delta):
	var zombi = posicion_zombi()
	var paneles = [panel_vida, panel_objetivo, panel_puntos, panel_embestida, mutaciones, panel_sigilo]
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
	if jugador == null:
		return null
	return a_pantalla(jugador.global_position + Vector3(0, 0.9, 0))

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
	barra_vida.custom_minimum_size.x = 150.0 if compacto else 210.0
	texto_record.visible = not compacto
	%TituloEmbestida.visible = not compacto
	%TextoTecla.text = "ESP" if compacto else "ESPACIO"
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
