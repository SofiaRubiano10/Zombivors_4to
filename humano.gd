extends CharacterBody3D

# Taller 9 - Tarea A (Juan Diego): el humano que patrulla.
# Nivel 1: patrulla por un array de puntos recorrido con un índice.
# Nivel 2: ve con un rayo (RayCast3D "Vision") y persigue.
# Nivel 3: ataca de cerca, lo pierde con histéresis y lo busca donde lo vio.
# Avance T10: el ataque quita vida por la Salud (la invulnerabilidad limita la frecuencia).
# Clase 2: ve en un CONO (no en 360°): por la espalda no te ve. Su linterna
# muestra hacia dónde mira y cambia de color con su alerta.
# Clase 2: OYE el ruido del zombi (correr hace ruido) y va a mirar.
# Clase 2: si te ve, GRITA y avisa a los cazadores cercanos, que corren a buscarte.
# Clase 2: antes de golpear se frena un instante (aviso) y golpea con cadencia.
# Clase 2: tiene vida. El Mordisco del zombi lo hiere de frente y lo devora
# por la espalda. Camina con un NavigationAgent3D para rodear los muros.

signal devorado

enum Estado { PATRULLAR, ESPERAR, PERSEGUIR, ATACAR, BUSCAR }

const COLOR_CALMA = Color(1.0, 0.93, 0.75)
const COLOR_SOSPECHA = Color(1.0, 0.82, 0.25)
const COLOR_ALERTA = Color(1.0, 0.25, 0.25)

@export var rapidez = 2.0
# Persiguiendo o avisado va más rápido que el zombi caminando (2.5): hay que correr.
@export var rapidez_alerta = 2.8
@export var espera = 1.0
@export var rango_vision = 7.0
# Medio ángulo del cono: 45 -> 90° de campo de visión.
@export var angulo_vision = 45.0
@export var rango_ataque = 1.2
@export var rango_perder = 10.0
@export var tiempo_busqueda = 3.0
@export var danio = 15
# Segundos entre que se planta delante y el primer golpe: tiempo para huir.
@export var tiempo_aviso = 0.35
@export var cadencia = 0.9
# Hasta dónde llega su grito de alerta.
@export var radio_alerta = 12.0
@export var vida = 45.0
# Desplazamientos desde donde se colocó el NPC, no posiciones absolutas.
@export var ruta: Array[Vector3] = [Vector3.ZERO, Vector3(0, 0, -6)]

var estado = Estado.PATRULLAR
var puntos: Array[Vector3] = []
var indice = 0
var reloj = 0.0
var jugador = null
var ultimo_visto = Vector3.ZERO
var busca = 0.0
var golpe = 0.0
# true si lo avisó otro: busca más rápido y durante más tiempo.
var alertado = false
# Para no gritar en cada cuadro: un grito cada pocos segundos.
var grito = 0.0
var muerto = false
# El proyecto no tiene el modelo .glb del taller: si no hay AnimationPlayer, no se anima.
@onready var anim = get_node_or_null("Modelo/AnimationPlayer")
@onready var vision = $Vision
@onready var agente = get_node_or_null("Agente")
@onready var marca = get_node_or_null("Alerta")
@onready var linterna = get_node_or_null("Linterna")

func _ready():
	add_to_group("cazadores")
	jugador = get_tree().get_first_node_in_group("jugador")
	for d in ruta:
		puntos.append(global_position + d)
	# Empieza mirando hacia su primer tramo de patrulla.
	if puntos.size() > 1 and Sentidos.distancia(puntos[0], puntos[1]) > 0.1:
		basis = Basis.looking_at(Sentidos.hacia(puntos[0], puntos[1]))
	pintar()

func _physics_process(delta):
	if muerto or jugador == null:
		return
	velocity += get_gravity() * delta
	reloj = maxf(reloj - delta, 0.0)
	busca = maxf(busca - delta, 0.0)
	golpe = maxf(golpe - delta, 0.0)
	grito = maxf(grito - delta, 0.0)
	# 1. MEDIR
	var d = distancia_a(jugador.global_position)
	var ve = lo_ve(d)
	if ve:
		ultimo_visto = jugador.global_position
	elif oye(d):
		sospechar(jugador.global_position)
	# 2. DECIDIR
	var nuevo = decidir(d, ve)
	if nuevo != estado:
		cambiar_a(nuevo)
	# 3. ACTUAR
	match estado:
		Estado.PATRULLAR:
			patrullar()
		Estado.ESPERAR:
			frenar()
		Estado.PERSEGUIR:
			ir_a(jugador.global_position, rapidez_alerta)
		Estado.ATACAR:
			frenar("attack-melee-right")
			mirar_a(jugador.global_position)
			if golpe <= 0.001:
				golpear()
				golpe = cadencia
		Estado.BUSCAR:
			if distancia_a(ultimo_visto) > 0.4:
				ir_a(ultimo_visto, rapidez_alerta if alertado else rapidez)
			else:
				# Llegó y no está: gira mirando alrededor.
				frenar()
				rotate_y(2.0 * delta)
	move_and_slide()

# El orden ES la regla: el primer if que se cumple gana.
func decidir(d, ve):
	var alerta = estado == Estado.PERSEGUIR or estado == Estado.ATACAR
	# Ya alerta, necesita más distancia para soltarlo: histéresis.
	var limite = rango_perder if alerta else rango_vision
	if ve and d <= rango_ataque:
		return Estado.ATACAR
	if ve and d <= limite:
		return Estado.PERSEGUIR
	if alerta:
		busca = tiempo_busqueda
		return Estado.BUSCAR
	if busca > 0.001:
		return Estado.BUSCAR
	if reloj > 0.001:
		return Estado.ESPERAR
	return Estado.PATRULLAR

func cambiar_a(nuevo):
	var antes = estado
	estado = nuevo
	print(name, " -> ", Estado.keys()[estado], " cuadro ",
		Engine.get_physics_frames(), " a ",
		snappedf(distancia_a(jugador.global_position), 0.01), " m")
	if estado == Estado.ATACAR:
		# El aviso: se planta y todavía no golpea.
		golpe = tiempo_aviso
	if estado == Estado.PERSEGUIR and antes != Estado.ATACAR:
		gritar()
	if estado == Estado.PATRULLAR:
		alertado = false
	pintar()

# Mientras siga pegado, golpea cada "cadencia" segundos.
func golpear():
	var salud = jugador.get_node_or_null("Salud")
	if salud != null:
		salud.recibir_golpe(danio)

# Ve si está en su cono Y el rayo llega sin chocar antes con un muro.
func lo_ve(d):
	var alerta = estado == Estado.PERSEGUIR or estado == Estado.ATACAR
	if alerta:
		# Ya lo tiene fichado: lo sigue con la mirada mientras no se aleje.
		if d > rango_perder:
			return false
	elif not Sentidos.en_cono(self, jugador.global_position, rango_vision, angulo_vision):
		return false
	# Se apunta al pecho: el origen del jugador está en los pies.
	var pecho = jugador.global_position + Vector3(0, 0.9, 0)
	vision.target_position = vision.to_local(pecho)
	vision.force_raycast_update()
	if vision.is_colliding():
		# ¿Lo primero que tocó fue el jugador, o una pared?
		return vision.get_collider() == jugador
	return true

# El Personaje calcula cuántos metros se oye (0 quieto, 1 caminando, 3 corriendo).
func oye(d):
	return "ruido" in jugador and d <= jugador.ruido

# Un ruido o un aviso: va a mirar a ese punto, todavía sin perseguir.
func sospechar(posicion):
	if estado == Estado.PERSEGUIR or estado == Estado.ATACAR:
		return
	ultimo_visto = posicion
	busca = maxf(busca, tiempo_busqueda)

# Lo acaba de ver: grita y avisa a los cazadores que estén cerca.
func gritar():
	if grito > 0.001:
		return
	grito = 3.0
	var avisados = Sentidos.alertar(self, jugador.global_position, radio_alerta)
	if avisados > 0:
		Sentidos.aviso(get_tree(), "¡Te vieron! El guardia avisó a %d más" % avisados, COLOR_ALERTA)
	else:
		Sentidos.aviso(get_tree(), "¡Un guardia te vio!", COLOR_ALERTA)

# La llama el grito de otro cazador. Devuelve true si se dio por avisado.
func recibir_alerta(posicion):
	if muerto or estado == Estado.PERSEGUIR or estado == Estado.ATACAR:
		return false
	alertado = true
	ultimo_visto = posicion
	busca = tiempo_busqueda * 2.0
	return true

# 0 tranquilo, 1 buscando, 2 persiguiendo. La usan el HUD y el olfato.
func nivel_alerta():
	if estado == Estado.PERSEGUIR or estado == Estado.ATACAR:
		return 2
	if estado == Estado.BUSCAR:
		return 1
	return 0

# El "?" o "!" sobre la cabeza y el color de la linterna cuentan su alerta.
func pintar():
	var nivel = nivel_alerta()
	var color = [COLOR_CALMA, COLOR_SOSPECHA, COLOR_ALERTA][nivel]
	if marca != null:
		marca.text = ["", "?", "!"][nivel]
		marca.modulate = color
	if linterna != null:
		linterna.light_color = color

# El Mordisco de frente: duele y se entera de que estás ahí.
func recibir_golpe(cuanto):
	vida -= cuanto
	print(name, " vida ", vida)
	sacudir()
	if vida <= 0.0:
		devorar()
		return
	ultimo_visto = jugador.global_position
	busca = tiempo_busqueda
	mirar_a(jugador.global_position)

# El zombi se lo come: deja de actuar, se encoge y desaparece.
func devorar():
	if muerto:
		return
	muerto = true
	remove_from_group("cazadores")
	devorado.emit()
	print(name, " devorado")
	$CollisionShape3D.set_deferred("disabled", true)
	if linterna != null:
		linterna.visible = false
	if marca != null:
		marca.text = ""
	var t = create_tween()
	t.tween_property(self, "scale", Vector3(1.3, 0.05, 1.3), 0.35)
	t.tween_callback(queue_free)

func sacudir():
	var modelo = get_node_or_null("Modelo")
	if modelo == null:
		return
	var t = create_tween()
	t.tween_property(modelo, "scale", Vector3(1.25, 0.85, 1.25), 0.06)
	t.tween_property(modelo, "scale", Vector3.ONE, 0.12)

func patrullar():
	var destino = puntos[indice]
	if distancia_a(destino) < 0.3:
		indice = (indice + 1) % puntos.size()
		reloj = espera
		frenar()
		return
	ir_a(destino)

# El NavigationAgent3D da el siguiente punto del camino que rodea los muros.
# Si todavía no hay mapa de navegación, va en línea recta como antes.
func ir_a(destino, vel = rapidez):
	var siguiente = destino
	if agente != null:
		if agente.target_position.distance_to(destino) > 0.25:
			agente.target_position = destino
		var p = agente.get_next_path_position()
		if distancia_a(p) > 0.05:
			siguiente = p
	var hacia = siguiente - global_position
	hacia.y = 0.0
	if hacia.length() < 0.01:
		frenar()
		return
	var dir = hacia.normalized()
	velocity.x = dir.x * vel
	velocity.z = dir.z * vel
	basis = Basis.looking_at(dir)
	reproducir("walk")

func mirar_a(punto):
	if distancia_a(punto) > 0.05:
		basis = Basis.looking_at(Sentidos.hacia(global_position, punto))

func frenar(animacion = "idle"):
	velocity.x = 0.0
	velocity.z = 0.0
	reproducir(animacion)

func reproducir(animacion):
	if anim != null and anim.current_animation != animacion:
		anim.play(animacion)

# Distancia en el suelo: si el otro salta, no "se aleja".
func distancia_a(p):
	var o = global_position
	return Vector2(p.x - o.x, p.z - o.z).length()
