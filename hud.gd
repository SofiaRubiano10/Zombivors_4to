extends CanvasLayer

# Taller 10 - Tarea B (María Sofía): el HUD solo muestra; la vida vive en la Salud
# y el tiempo en la Partida.
# La vida llega por señal. El tiempo cambia cada cuadro, por eso se lee en _process.
#
# Rediseño: el HUD se ordena por lo que el jugador necesita saber, en cuatro
# esquinas que se leen de un vistazo, con la paleta del juego:
#   Arriba a la izquierda  -> TU CUERPO: vida y descomposición (el reloj es tu cuerpo).
#   Arriba al centro       -> el reloj de la zona.
#   Arriba a la derecha    -> COMIDA: lo que llevas y lo que falta para ganar.
#   Abajo a la izquierda   -> SIGILO: si te ven y cuánto ruido haces.
# Y pegado al mundo: el aviso para comer sobre el alimento, "?" / "!" sobre los
# humanos y los números de vida que salen del zombi.

const Partida = preload("res://partida.gd")
const OJO_ABIERTO = preload("res://ui/iconos/ojo_abierto.png")
const OJO_CERRADO = preload("res://ui/iconos/ojo_cerrado.png")
const FUENTE_GRUESA = preload("res://ui/fuentes/BarlowCondensed-ExtraBold.ttf")

# Paleta Zombivors.
const HUESO = Color(0.949, 0.929, 0.894)
const TENUE = Color(0.949, 0.929, 0.894, 0.6)
const CARNE = Color(0.831, 0.639, 0.451)
const SANGRE = Color(0.698, 0.133, 0.133)
const ROJO_VIVO = Color(0.937, 0.267, 0.227)
const AMBAR = Color(0.96, 0.72, 0.28)
const PODRIDO = Color(0.55, 0.85, 0.25)
const CEREBRO = Color(0.96, 0.62, 0.70)
const OSCURO = Color(0.06, 0.06, 0.07, 0.9)

# Segundos que se ven los controles al empezar (en el primer intento).
@export var segundos_controles = 8.0

@onready var vineta = $Vineta
@onready var marcadores = %Marcadores
@onready var cuerpo = %Cuerpo
@onready var barra_vida = %BarraVida
@onready var numero_vida = %NumeroVida
@onready var icono_vida = %IconoVida
@onready var icono_pudricion = %IconoPudricion
@onready var barra_pudricion = %BarraPudricion
@onready var texto_pudricion = %TextoPudricion
@onready var reloj = %Reloj
@onready var anillo_reloj = %AnilloReloj
@onready var texto_tiempo = %TextoTiempo
@onready var titulo_tiempo = %TituloTiempo
@onready var comida = %Comida
@onready var cuenta_comida = %CuentaComida
@onready var huecos = %Huecos
@onready var pista_comida = %PistaComida
@onready var ojo = %Ojo
@onready var texto_sigilo = %TextoSigilo
@onready var barras_ruido = %BarrasRuido
@onready var texto_ruido = %TextoRuido
@onready var aviso = %Aviso
@onready var punta_aviso = %PuntaAviso
@onready var anillo_aviso = %AnilloAviso
@onready var icono_aviso = %IconoAviso
@onready var nombre_aviso = %NombreAviso
@onready var efecto_aviso = %EfectoAviso
@onready var accion_aviso = %AccionAviso
@onready var controles = %Controles
@onready var final = %Final
@onready var banda_final = %BandaFinal
@onready var titulo_final = %TituloFinal
@onready var detalle_final = %DetalleFinal

var pj = null
var salud = null
var interactuar = null
var partida = null
var vida_actual = 0
var vida_max = 100
var golpe_reciente = false
var flash = 0.0
var t = 0.0
var comidas = 0
var aviso_de = null
var marcas = {}
var pausa_max = 0.0
var pos_cuerpo = Vector2.ZERO

func _ready():
	# El HUD sigue vivo en la pausa del final para mostrar el resultado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	pos_cuerpo = cuerpo.position
	pj = get_tree().get_first_node_in_group("jugador")
	if pj != null:
		salud = pj.get_node_or_null("Salud")
		interactuar = pj.get_node_or_null("Interactuar")
	if salud != null:
		salud.cambio.connect(mostrar)
		salud.golpeado.connect(_al_golpe)
		vida_max = maxi(1, salud.vida_inicial if salud.vida_inicial > 0 else salud.vida)
		vida_actual = salud.vida
		barra_vida.valor = float(vida_actual) / vida_max
		barra_vida.mostrado = barra_vida.valor
		barra_vida.rastro = barra_vida.valor
	for a in get_tree().get_nodes_in_group("alimentos"):
		if a.has_signal("comido"):
			a.comido.connect(_al_comer)
	final.visible = false
	aviso.modulate.a = 0.0
	aviso.visible = false
	crear_huecos(3)
	buscar_partida()
	actualizar_vida()

func _process(delta):
	t += delta
	if partida == null:
		buscar_partida()
	actualizar_vida()
	actualizar_pudricion()
	actualizar_reloj()
	actualizar_sigilo()
	actualizar_aviso(delta)
	actualizar_marcas()
	actualizar_vineta(delta)
	actualizar_controles()

# Se busca aquí: la Partida quizá todavía no existía en _ready().
func buscar_partida():
	partida = get_tree().get_first_node_in_group("partida")
	if partida == null:
		return
	partida.terminada.connect(_al_terminar)
	crear_huecos(partida.metas)
	comida.visible = partida.metas > 0
	titulo_tiempo.text = "AGUANTA" if partida.gana_con_tiempo else "TIEMPO"

func jugando():
	return partida == null or partida.estado == Partida.Estado.JUGANDO

# ---------------------------------------------------------------- tu cuerpo

func mostrar(vida):
	var diferencia = vida - vida_actual
	vida_actual = vida
	if diferencia > 0:
		flotar("+%d" % diferencia, CARNE)
	elif diferencia < 0:
		# El golpe llega antes que el cambio: así se sabe si fue un humano o la pudrición.
		flotar("−%d" % -diferencia, ROJO_VIVO if golpe_reciente else PODRIDO)
		if not golpe_reciente:
			latir(icono_pudricion)
	golpe_reciente = false
	actualizar_vida()
	print("HUD -> vida ", vida, " / ", vida_max)

func _al_golpe(_danio):
	golpe_reciente = true
	flash = 1.0
	latir(icono_vida)
	# Sacudida corta del panel del cuerpo.
	var tw = cuerpo.create_tween()
	tw.tween_property(cuerpo, "position", pos_cuerpo + Vector2(7, 0), 0.04)
	tw.tween_property(cuerpo, "position", pos_cuerpo - Vector2(5, 0), 0.05)
	tw.tween_property(cuerpo, "position", pos_cuerpo, 0.08)

func actualizar_vida():
	var fraccion = float(vida_actual) / vida_max
	barra_vida.valor = fraccion
	numero_vida.text = str(vida_actual)
	# modulate tiñe sin rehacer el texto: se puede cambiar en cada cuadro.
	numero_vida.modulate = Color.WHITE
	if fraccion < 0.3:
		numero_vida.modulate = Color.WHITE.lerp(ROJO_VIVO, 0.5 + 0.5 * sin(t * 9.0))

func actualizar_pudricion():
	if salud == null:
		return
	if salud.vida == 0:
		texto_pudricion.text = "ya no queda cuerpo"
		return
	if salud.pausa > 0.0:
		# El cerebro detiene la descomposición: la barra muestra lo que le queda.
		pausa_max = maxf(pausa_max, salud.pausa)
		barra_pudricion.valor = salud.pausa / pausa_max
		barra_pudricion.color_lleno = CEREBRO
		icono_pudricion.modulate = CEREBRO
		texto_pudricion.text = "cerebro: no te pudres %d s" % ceili(salud.pausa)
		return
	pausa_max = 0.0
	var intervalo = maxf(salud.intervalo_descomposicion, 0.01)
	var perdida = int(round(salud.vida_inicial * salud.porcentaje_descomposicion))
	barra_pudricion.valor = clampf(salud.acumulado / intervalo, 0.0, 1.0)
	barra_pudricion.color_lleno = PODRIDO
	icono_pudricion.modulate = Color.WHITE
	texto_pudricion.text = "te pudres: −%d en %d s" % [perdida, ceili(intervalo - salud.acumulado)]

# ---------------------------------------------------------------- la zona

func actualizar_reloj():
	reloj.visible = partida != null
	if partida == null:
		return
	var resto = maxf(partida.tiempo, 0.0)
	anillo_reloj.valor = resto / maxf(partida.tiempo_limite, 0.01)
	var s = ceili(resto)
	texto_tiempo.text = "%d:%02d" % [floori(s / 60.0), s % 60]
	var color = HUESO
	if resto <= 30.0 and jugando():
		# Últimos 30 s: el reloj se pone rojo y late.
		color = HUESO.lerp(ROJO_VIVO, 0.6 + 0.4 * sin(t * 8.0))
	anillo_reloj.color_lleno = color
	texto_tiempo.modulate = Color.WHITE if color == HUESO else color

func crear_huecos(total):
	for h in huecos.get_children():
		huecos.remove_child(h)
		h.queue_free()
	for i in clampi(total, 0, 8):
		var hueco = Panel.new()
		hueco.custom_minimum_size = Vector2(46, 46)
		hueco.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hueco.add_theme_stylebox_override("panel", estilo_hueco(Color(HUESO, 0.22), false))
		var icono = TextureRect.new()
		icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icono.position = Vector2(3, 3)
		icono.size = Vector2(40, 40)
		icono.pivot_offset = Vector2(20, 20)
		hueco.add_child(icono)
		huecos.add_child(hueco)
	comidas = 0
	cuenta_comida.text = "0 / %d" % total
	pista_comida.text = "Come %d para ganar" % total

func estilo_hueco(borde, lleno):
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.13, 0.12, 0.12, 0.95) if lleno else Color(0.04, 0.04, 0.05, 0.6)
	s.set_border_width_all(2)
	s.border_color = borde
	s.corner_radius_top_left = 16
	s.corner_radius_top_right = 7
	s.corner_radius_bottom_right = 16
	s.corner_radius_bottom_left = 7
	s.anti_aliasing = true
	return s

func _al_comer(alimento):
	var total = huecos.get_child_count()
	if comidas < total:
		var hueco = huecos.get_child(comidas)
		var color = alimento.color if "color" in alimento else CARNE
		hueco.add_theme_stylebox_override("panel", estilo_hueco(color, true))
		var icono = hueco.get_child(0)
		icono.texture = alimento.icono if "icono" in alimento else null
		var tw = icono.create_tween()
		tw.tween_property(icono, "scale", Vector2.ONE, 0.35).from(Vector2(1.9, 1.9)) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	comidas += 1
	cuenta_comida.text = "%d / %d" % [mini(comidas, total), total]
	latir(cuenta_comida)

# ---------------------------------------------------------------- sigilo

func actualizar_sigilo():
	var nivel = 0
	for h in get_tree().get_nodes_in_group("humanos"):
		if h.has_method("alerta"):
			nivel = maxi(nivel, h.alerta())
	var textos = ["NADIE TE VE", "TE ESTÁN BUSCANDO", "¡TE VIERON!", "¡CUIDADO!"]
	var colores = [TENUE, AMBAR, ROJO_VIVO, ROJO_VIVO]
	var color = colores[nivel]
	if nivel >= 2:
		color = color.lerp(HUESO, 0.35 * (0.5 + 0.5 * sin(t * 12.0)))
	texto_sigilo.text = textos[nivel]
	texto_sigilo.modulate = color
	ojo.texture = OJO_ABIERTO if nivel > 0 else OJO_CERRADO
	ojo.modulate = Color(TENUE, 0.8) if nivel == 0 else color
	# Ruido: 0 m quieto, 1 m caminando, 3 m corriendo.
	var ruido = 0.0
	var accion = "quieto"
	if pj != null and "ruido" in pj:
		ruido = pj.ruido
		if pj.estado == Personaje.Estado.CAMINAR:
			accion = "pasos · %d m" % ruido
		elif pj.estado == Personaje.Estado.CORRER:
			accion = "corriendo · %d m" % ruido
		elif pj.estado == Personaje.Estado.COMIENDO:
			accion = "comiendo"
	var encendidas = 0
	if ruido > 0.0:
		encendidas = 1 if ruido <= 1.0 else (2 if ruido < 3.0 else 3)
	var color_ruido = AMBAR if encendidas >= 3 else HUESO
	for i in barras_ruido.get_child_count():
		var barra = barras_ruido.get_child(i)
		barra.color = color_ruido if i < encendidas else Color(HUESO, 0.15)
	texto_ruido.text = accion

func actualizar_marcas():
	var cam = get_viewport().get_camera_3d()
	for h in get_tree().get_nodes_in_group("humanos"):
		if not h.has_method("alerta"):
			continue
		var nivel = h.alerta() if jugando() else 0
		var marca = marcas.get(h)
		if nivel == 0 or cam == null:
			if marca != null:
				marca.visible = false
				marca.set_meta("nivel", 0)
			continue
		if marca == null:
			marca = crear_marca()
			marcas[h] = marca
		var punto = h.global_position + Vector3.UP * 2.3
		if cam.is_position_behind(punto):
			marca.visible = false
			continue
		marca.visible = true
		marca.text = "?" if nivel == 1 else ("!" if nivel == 2 else "!!")
		marca.modulate = AMBAR if nivel == 1 else ROJO_VIVO
		marca.position = cam.unproject_position(punto) - marca.size * 0.5
		# Salta cuando sube la alerta.
		if nivel > marca.get_meta("nivel", 0):
			var tw = marca.create_tween()
			tw.tween_property(marca, "scale", Vector2.ONE, 0.3).from(Vector2(1.8, 1.8)) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		marca.set_meta("nivel", nivel)
	# Los humanos que ya no existen (vencidos) se llevan su marca.
	for h in marcas.keys():
		if not is_instance_valid(h):
			marcas[h].queue_free()
			marcas.erase(h)

func crear_marca():
	var marca = Label.new()
	marca.add_theme_font_override("font", FUENTE_GRUESA)
	marca.add_theme_font_size_override("font_size", 46)
	marca.add_theme_color_override("font_color", Color.WHITE)
	marca.add_theme_color_override("font_outline_color", OSCURO)
	marca.add_theme_constant_override("outline_size", 10)
	marca.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marca.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	marca.size = Vector2(64, 56)
	marca.pivot_offset = marca.size * 0.5
	marca.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marcadores.add_child(marca)
	return marca

# ---------------------------------------------------------------- aviso para comer

func actualizar_aviso(delta):
	var obj = null
	if interactuar != null and jugando():
		obj = interactuar.mas_cercano()
	var meta = 1.0 if obj != null else 0.0
	aviso.modulate.a = aviso.modulate.a + (meta - aviso.modulate.a) * (1.0 - exp(-14.0 * delta))
	aviso.visible = aviso.modulate.a > 0.02
	if obj == null:
		anillo_aviso.valor = 0.0
		return
	if obj != aviso_de:
		aviso_de = obj
		llenar_aviso(obj)
	var comiendo = interactuar.actual == obj and interactuar.progreso > 0.0
	anillo_aviso.valor = clampf(interactuar.progreso, 0.0, 1.0) if comiendo else 0.0
	accion_aviso.text = "comiendo…" if comiendo else "mantén E · %s s" % str(snappedf(interactuar.tiempo_de(obj), 0.1))
	colocar_aviso(obj)

func llenar_aviso(obj):
	var color = obj.color if "color" in obj else CARNE
	var nombre = obj.nombre if "nombre" in obj else String(obj.name)
	nombre_aviso.text = nombre.to_upper()
	var efecto = ""
	if "curacion" in obj:
		efecto = "+%d de vida" % obj.curacion
	if "pausa_descomposicion" in obj and obj.pausa_descomposicion > 0.0:
		efecto += " · no te pudres %d s" % obj.pausa_descomposicion
	efecto_aviso.text = efecto
	efecto_aviso.add_theme_color_override("font_color", color.lerp(HUESO, 0.25))
	icono_aviso.texture = obj.icono if "icono" in obj else null
	anillo_aviso.color_lleno = color
	anillo_aviso.mostrado = 0.0
	aviso.reset_size()

# El aviso flota sobre el alimento: se proyecta su posición 3D a la pantalla.
func colocar_aviso(obj):
	var cam = get_viewport().get_camera_3d()
	if cam == null:
		return
	var punto = obj.global_position + Vector3.UP * 1.0
	if cam.is_position_behind(punto):
		return
	var p = cam.unproject_position(punto)
	var tam = aviso.size
	var pantalla = get_viewport().get_visible_rect().size
	var pos = p - Vector2(tam.x * 0.5, tam.y + 12.0)
	pos.x = clampf(pos.x, 12.0, maxf(12.0, pantalla.x - tam.x - 12.0))
	pos.y = clampf(pos.y, 12.0, maxf(12.0, pantalla.y - tam.y - 12.0))
	aviso.position = pos
	punta_aviso.position = Vector2(clampf(p.x - pos.x, 18.0, tam.x - 18.0), tam.y)

# ---------------------------------------------------------------- efectos

# Número que sube desde la cabeza del zombi y se desvanece.
func flotar(texto, color):
	if pj == null:
		return
	var cam = get_viewport().get_camera_3d()
	if cam == null:
		return
	var punto = pj.global_position + Vector3.UP * 2.0
	if cam.is_position_behind(punto):
		return
	var l = Label.new()
	l.text = texto
	l.add_theme_font_override("font", FUENTE_GRUESA)
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", OSCURO)
	l.add_theme_constant_override("outline_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.size = Vector2(120, 36)
	l.position = cam.unproject_position(punto) - l.size * 0.5 + Vector2(randf_range(-16.0, 16.0), 0.0)
	marcadores.add_child(l)
	var tw = l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 48.0, 1.0) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.45).set_delay(0.55)
	tw.chain().tween_callback(l.queue_free)

# Pequeño "latido" de un control (crece y vuelve).
func latir(nodo):
	nodo.pivot_offset = nodo.size * 0.5
	var tw = nodo.create_tween()
	tw.tween_property(nodo, "scale", Vector2.ONE, 0.3).from(Vector2(1.35, 1.35)) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# Bordes rojos: destello al recibir un golpe y pulso cuando queda poca vida.
func actualizar_vineta(delta):
	flash = flash + (0.0 - flash) * (1.0 - exp(-5.0 * delta))
	var fraccion = float(vida_actual) / vida_max
	var peligro = 0.0
	if fraccion < 0.3 and vida_actual > 0:
		peligro = (0.3 - fraccion) / 0.3 * (0.6 + 0.4 * sin(t * 6.0)) * 0.55
	vineta.modulate.a = clampf(maxf(flash * 0.85, peligro), 0.0, 1.0)

func actualizar_controles():
	var dura = segundos_controles if Partida.intentos <= 1 else 3.0
	controles.modulate.a = clampf(dura - t, 0.0, 1.0)
	controles.visible = controles.modulate.a > 0.01

# ---------------------------------------------------------------- final

func _al_terminar(estado, motivo):
	var gano = estado == Partida.Estado.GANO
	var color = CARNE if gano else ROJO_VIVO
	if gano:
		titulo_final.text = "¡BANQUETE!"
		var usado = partida.tiempo_limite - partida.tiempo
		detalle_final.text = "Te lo comiste todo en %s s  ·  mejor: %s s" % [
			str(snappedf(usado, 0.1)), str(snappedf(Partida.mejor, 0.1))]
	elif motivo == "se acabó el tiempo":
		titulo_final.text = "SE ACABÓ EL TIEMPO"
		detalle_final.text = "Intento %d  ·  volviendo a empezar…" % Partida.intentos
	else:
		titulo_final.text = "TE DESHICISTE"
		detalle_final.text = "Intento %d  ·  volviendo a empezar…" % Partida.intentos
	titulo_final.add_theme_color_override("font_color", color)
	var estilo = banda_final.get_theme_stylebox("panel").duplicate()
	estilo.border_color = color
	banda_final.add_theme_stylebox_override("panel", estilo)
	final.visible = true
	final.modulate.a = 0.0
	banda_final.pivot_offset = banda_final.size * 0.5
	var tw = create_tween().set_parallel(true)
	tw.tween_property(final, "modulate:a", 1.0, 0.15)
	tw.tween_property(banda_final, "scale", Vector2.ONE, 0.3).from(Vector2(1.0, 0.1)) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
