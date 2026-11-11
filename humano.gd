extends CharacterBody3D

# Taller 9 - Tarea A (Juan Diego): el humano que patrulla.
# Nivel 1: patrulla por un array de puntos recorrido con un índice.
# Nivel 2: ve con un rayo (RayCast3D "Vision") y persigue.
# Nivel 3: ataca de cerca, lo pierde con histéresis y lo busca donde lo vio.
# Avance T10: el ataque quita vida por la Salud (la invulnerabilidad limita la frecuencia).
# Clase 2: ve en un cono de 6 m y 90 grados hacia delante; los muros tapan la vista.
# Clase 2: si lo pierde (muro o distancia) no lo olvida: va a donde lo vio por
# última vez, mira alrededor y vuelve a su ruta.

enum Estado { PATRULLAR, ESPERAR, PERSEGUIR, ATACAR, BUSCAR, MIRAR, VOLVER }

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
# Desplazamientos desde donde se colocó el NPC, no posiciones absolutas.
@export var ruta: Array[Vector3] = [Vector3.ZERO, Vector3(0, 0, -6)]

var estado = Estado.PATRULLAR
var puntos: Array[Vector3] = []
var indice = 0
var reloj = 0.0
var jugador = null
var ultimo_visto = Vector3.ZERO
# El proyecto no tiene el modelo .glb del taller: si no hay AnimationPlayer, no se anima.
@onready var anim = get_node_or_null("Modelo/AnimationPlayer")
@onready var vision = $Vision

func _ready():
	jugador = get_tree().get_first_node_in_group("jugador")
	for d in ruta:
		puntos.append(global_position + d)

func _physics_process(delta):
	velocity += get_gravity() * delta
	reloj = maxf(reloj - delta, 0.0)
	# 1. MEDIR: solo cuenta como visto si está en rango y sin muro en medio.
	var d = distancia_a(jugador.global_position)
	var alerta = estado == Estado.PERSEGUIR or estado == Estado.ATACAR
	# Ya alerta, necesita más distancia para soltarlo: histéresis.
	var limite = rango_perder if alerta else rango_vision
	var ve = d <= limite and lo_ve()
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
			ir_a(jugador.global_position)
		Estado.ATACAR:
			frenar()
			reproducir("attack-melee-right")
			golpear()
		Estado.BUSCAR:
			ir_a(ultimo_visto)
		Estado.MIRAR:
			frenar()
			rotate_y(deg_to_rad(giro_mirar) * delta)
		Estado.VOLVER:
			ir_a(puntos[indice])
	move_and_slide()

# El orden ES la regla: el primer if que se cumple gana.
func decidir(d, ve, alerta):
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
	estado = nuevo
	if estado == Estado.BUSCAR:
		reloj = tiempo_max_buscar
	elif estado == Estado.MIRAR:
		reloj = tiempo_busqueda
	print(name, " -> ", Estado.keys()[estado], " cuadro ",
		Engine.get_physics_frames(), " a ", snappedf(d, 0.01), " m")

# Mientras siga pegado, golpea: la invulnerabilidad de la Salud decide cada cuánto cuenta.
func golpear():
	var salud = jugador.get_node_or_null("Salud")
	if salud != null:
		salud.recibir_golpe(danio)

# Alerta, ya no necesita el cono: le basta con no tener un muro en medio.
func lo_ve():
	var alerta = estado == Estado.PERSEGUIR or estado == Estado.ATACAR
	if not alerta and not en_cono():
		return false
	# Se apunta al pecho: el origen del jugador está en los pies.
	var pecho = jugador.global_position + Vector3(0, 0.9, 0)
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
func en_cono():
	var hacia = jugador.global_position - global_position
	hacia.y = 0.0
	if hacia.length() < 0.01:
		return true
	var frente = -global_transform.basis.z
	frente.y = 0.0
	return rad_to_deg(frente.angle_to(hacia)) <= angulo_vision / 2.0
