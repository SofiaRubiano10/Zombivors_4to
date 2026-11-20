extends CharacterBody3D

# Taller 9 - Tarea A (Juan Diego): el humano que patrulla.
# Nivel 1: patrulla por un array de puntos recorrido con un índice.
# Nivel 2: ve con un rayo (RayCast3D "Vision") y persigue.
# Nivel 3: ataca de cerca, lo pierde con histéresis y lo busca donde lo vio.
# Avance T10: el ataque quita vida por la Salud (la invulnerabilidad limita la frecuencia).
# Clase 2: ve en un cono de 6 m y 90 grados hacia delante; los muros tapan la vista.
# Clase 2: si lo pierde (muro o distancia) no lo olvida: va a donde lo vio por
# última vez, mira alrededor y vuelve a su ruta.
# Clase 3: oye. Si el zombi hace ruido (hizo_ruido) y el radio del ruido lo alcanza,
# pasa a SOSPECHA: va a ese punto, mira alrededor y vuelve a su ruta.
# PATRULLA -> SOSPECHA -> PERSIGUE -> VUELVE.
# Clase 3: el contrato con el zombi (grupo "humanos"):
#  - puede_verme(pos): ¿vería al zombi si estuviera en pos? Lo usa el mordisco.
#  - aturdir(segundos): lo deja quieto y ciego (lo usa la embestida).
#  - sujetar(segundos): el zombi lo está mordiendo; no camina y se gira hacia él.
#    Si termina de girarse y lo ve, se suelta y ataca.
#  - devorado(): se lo comieron; avisa y desaparece.

signal sospecha
signal me_vio
signal devorado_signal

enum Estado { PATRULLAR, ESPERAR, PERSEGUIR, ATACAR, BUSCAR, MIRAR, VOLVER, SOSPECHA, ATURDIDO, SUJETADO }

@export var rapidez = 2.0
@export var espera = 1.0
@export var rango_vision = 6.0
# Apertura total del cono, en grados. La mitad a cada lado del frente.
@export var angulo_vision = 90.0
@export var rango_ataque = 1.2
@export var rango_perder = 10.0
# Lo que se queda mirando alrededor en el último lugar donde lo vio.
@export var tiempo_busqueda = 3.0
# Si no logra llegar al último lugar (un muro en medio), se rinde a este tiempo.
@export var tiempo_max_buscar = 8.0
# Grados por segundo que gira mientras mira alrededor.
@export var giro_mirar = 90.0
@export var danio = 15
# Grados por segundo que se gira hacia el zombi mientras lo muerden.
# De espaldas le faltan 135° para verlo: 1.5 s, más que el mordisco (1.2 s).
@export var giro_forcejeo = 90.0
# Desplazamientos desde donde se colocó el NPC, no posiciones absolutas.
@export var ruta: Array[Vector3] = [Vector3.ZERO, Vector3(0, 0, -6)]

var estado = Estado.PATRULLAR
var puntos: Array[Vector3] = []
var indice = 0
var reloj = 0.0
var jugador = null
var ultimo_visto = Vector3.ZERO
# Dónde sonó el último ruido que oyó.
var punto_ruido = Vector3.ZERO
# Lo que le queda sujetado por el mordisco.
var sujetado = 0.0
# El modelo (personaje/modelo_guardia.tscn) trae el AnimationPlayer; sin modelo, no se anima.
@onready var anim = get_node_or_null("Modelo/AnimationPlayer")
@onready var vision = $Vision

func _ready():
	add_to_group("humanos")
	jugador = get_tree().get_first_node_in_group("jugador")
	for d in ruta:
		puntos.append(global_position + d)
	if jugador != null and jugador.has_signal("hizo_ruido"):
		jugador.hizo_ruido.connect(_al_oir)

func _physics_process(delta):
	velocity += get_gravity() * delta
	reloj = maxf(reloj - delta, 0.0)
	sujetado = maxf(sujetado - delta, 0.0)
	# 1. MEDIR: solo cuenta como visto si está en rango y sin muro en medio.
	var d = distancia_a(jugador.global_position)
	var alerta = estado == Estado.PERSEGUIR or estado == Estado.ATACAR
	# Ya alerta, necesita más distancia para soltarlo: histéresis.
	var limite = rango_perder if alerta else rango_vision
	var ve = estado != Estado.ATURDIDO and d <= limite and lo_ve()
	if ve:
		ultimo_visto = jugador.global_position
	# 2. DECIDIR
	var nuevo = decidir(d, ve, alerta)
	if nuevo != estado:
		cambiar_a(nuevo, d)
	# 3. ACTUAR
	match estado:
		Estado.PATRULLAR:
			patrullar()
		Estado.ESPERAR:
			frenar()
		Estado.PERSEGUIR:
			perseguir(delta)
		Estado.ATACAR:
			atacar(delta)
		Estado.BUSCAR:
			ir_a(ultimo_visto)
		Estado.SOSPECHA:
			ir_a(punto_ruido)
		Estado.MIRAR:
			frenar()
			rotate_y(deg_to_rad(giro_mirar) * delta)
		Estado.VOLVER:
			ir_a(puntos[indice])
		Estado.ATURDIDO:
			frenar()
		Estado.SUJETADO:
			frenar()
			girar_hacia(jugador.global_position, giro_forcejeo * delta)
	move_and_slide()

# El orden ES la regla: el primer if que se cumple gana.
func decidir(d, ve, alerta):
	# Aturdido no decide nada hasta que se le pasa; luego mira alrededor.
	if estado == Estado.ATURDIDO:
		return Estado.MIRAR if reloj <= 0.001 else estado
	# Sujetado: si ya se giró lo suficiente para verlo, se suelta (abajo, ATACAR).
	if estado == Estado.SUJETADO and not ve:
		return Estado.MIRAR if sujetado <= 0.001 else estado
	if ve and d <= rango_ataque:
		return Estado.ATACAR
	if ve:
		return Estado.PERSEGUIR
	# Lo acaba de perder: va a donde lo vio por última vez.
	if alerta:
		return Estado.BUSCAR
	match estado:
		Estado.BUSCAR:
			if distancia_a(ultimo_visto) <= 0.3 or reloj <= 0.001:
				return Estado.MIRAR
		Estado.SOSPECHA:
			if distancia_a(punto_ruido) <= 0.3 or reloj <= 0.001:
				return Estado.MIRAR
		Estado.MIRAR:
			if reloj <= 0.001:
				return Estado.VOLVER
		Estado.VOLVER:
			if distancia_a(puntos[indice]) <= 0.3:
				return Estado.PATRULLAR
		Estado.PATRULLAR:
			if reloj > 0.001:
				return Estado.ESPERAR
		Estado.ESPERAR:
			if reloj <= 0.001:
				return Estado.PATRULLAR
	return estado

# Los relojes se ponen al ENTRAR al estado, no mientras dura.
func cambiar_a(nuevo, d):
	var antes = estado
	estado = nuevo
	if alerta_en(nuevo) and not alerta_en(antes):
		me_vio.emit()
	if estado == Estado.BUSCAR or estado == Estado.SOSPECHA:
		reloj = tiempo_max_buscar
	elif estado == Estado.MIRAR:
		reloj = tiempo_busqueda
	print(name, " -> ", Estado.keys()[estado], " cuadro ",
		Engine.get_physics_frames(), " a ", snappedf(d, 0.01), " m")

# El ruido llega hasta "radio" metros desde donde sonó: si estoy dentro, lo oigo.
# Persiguiendo no se distrae: ya sabe dónde está el zombi.
func _al_oir(posicion, radio):
	if estado == Estado.PERSEGUIR or estado == Estado.ATACAR:
		return
	if distancia_a(posicion) > radio:
		return
	punto_ruido = posicion
	if estado != Estado.SOSPECHA:
		cambiar_a(Estado.SOSPECHA, distancia_a(posicion))
		sospecha.emit()
	else:
		# Otro ruido mientras ya sospechaba: cambia de destino y renueva la paciencia.
		reloj = tiempo_max_buscar

# Lo que hace al verlo, aparte para que otros tipos de humano (el tirador) lo cambien.
func perseguir(_delta):
	ir_a(jugador.global_position)

func atacar(_delta):
	frenar()
	reproducir("attack-melee-right")
	golpear()

# Mientras siga pegado, golpea: la invulnerabilidad de la Salud decide cada cuánto cuenta.
func golpear():
	var salud = jugador.get_node_or_null("Salud")
	if salud != null:
		salud.recibir_golpe(danio)

static func alerta_en(e):
	return e == Estado.PERSEGUIR or e == Estado.ATACAR

# --- Contrato ---------------------------------------------------------------

# ¿Vería al zombi si estuviera en pos? Misma regla que usa para decidir.
func puede_verme(pos):
	if estado == Estado.ATURDIDO:
		return false
	var limite = rango_perder if alerta_en(estado) else rango_vision
	return distancia_a(pos) <= limite and ve_punto(pos)

func aturdir(segundos):
	reloj = segundos
	if estado != Estado.ATURDIDO:
		cambiar_a(Estado.ATURDIDO, distancia_a(jugador.global_position))
	frenar()

# El mordisco lo llama cada cuadro con un margen corto: si el zombi suelta,
# al rato el humano queda libre.
func sujetar(segundos):
	if estado == Estado.ATURDIDO:
		return
	sujetado = maxf(sujetado, segundos)
	if estado != Estado.SUJETADO and not alerta_en(estado):
		cambiar_a(Estado.SUJETADO, distancia_a(jugador.global_position))

func devorado():
	print(name, " devorado")
	devorado_signal.emit()
	queue_free()

# ---------------------------------------------------------------------------

func lo_ve():
	return ve_punto(jugador.global_position)

# Alerta, ya no necesita el cono: le basta con no tener un muro en medio.
func ve_punto(pos):
	if not alerta_en(estado) and not en_cono_de(pos):
		return false
	# Se apunta al pecho: el origen del jugador está en los pies.
	var pecho = pos + Vector3(0, 0.9, 0)
	vision.target_position = vision.to_local(pecho)
	vision.force_raycast_update()
	if vision.is_colliding():
		# ¿Lo primero que tocó fue el jugador, o una pared?
		return vision.get_collider() == jugador
	return true

func patrullar():
	var destino = puntos[indice]
	if distancia_a(destino) < 0.1:
		indice = (indice + 1) % puntos.size()
		reloj = espera
		frenar()
		return
	ir_a(destino)

func ir_a(destino):
	var hacia = destino - global_position
	hacia.y = 0.0
	# Ya está encima: Basis.looking_at no acepta un vector cero.
	if hacia.length() < 0.05:
		frenar()
		return
	var dir = hacia.normalized()
	velocity.x = dir.x * rapidez
	velocity.z = dir.z * rapidez
	basis = Basis.looking_at(dir)
	reproducir("walk")

func frenar():
	velocity.x = 0.0
	velocity.z = 0.0
	reproducir("idle")

func reproducir(animacion):
	if anim != null:
		anim.play(animacion)

# Distancia en el suelo: si el otro salta, no "se aleja".
func distancia_a(p):
	var o = global_position
	return Vector2(p.x - o.x, p.z - o.z).length()

# El frente del humano es -Z (Basis.looking_at mira hacia -Z).
func en_cono_de(pos):
	var hacia = pos - global_position
	hacia.y = 0.0
	if hacia.length() < 0.01:
		return true
	var frente = -global_transform.basis.z
	frente.y = 0.0
	return rad_to_deg(frente.angle_to(hacia)) <= angulo_vision / 2.0

# Gira sobre sí mismo hacia un punto, sin pasar de "maximo" grados en este cuadro.
func girar_hacia(pos, maximo):
	var hacia = pos - global_position
	hacia.y = 0.0
	if hacia.length() < 0.01:
		return
	var frente = -global_transform.basis.z
	frente.y = 0.0
	var angulo = rad_to_deg(frente.signed_angle_to(hacia, Vector3.UP))
	rotate_y(deg_to_rad(clampf(angulo, -maximo, maximo)))
