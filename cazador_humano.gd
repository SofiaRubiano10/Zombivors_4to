extends CharacterBody3D

# Taller 9 - Tarea B (María Sofía): el golpe del humano.
# Nivel 1: el ciclo del ataque ACERCARSE -> AVISO -> GOLPE -> RECARGA.
# Nivel 2: el golpe mira dónde está el jugador y le quita vida a su Salud.
# Nivel 3: el cazador también tiene vida y huye cuando le queda poca.
# Clase 2: ya no sabe siempre dónde está el zombi. Lo ve a rango_vision si no hay
# muro en medio; si lo pierde va a donde lo vio por última vez, mira y vuelve a casa.

enum Estado { ACERCARSE, AVISO, GOLPE, RECARGA, HUIR, ESPERAR, BUSCAR, MIRAR, VOLVER }

@export var rapidez = 2.0
@export var rango_ataque = 1.5
@export var tiempo_aviso = 0.5
@export var tiempo_recarga = 1.0
@export var alcance_golpe = 1.8
@export var danio = 1
# Retroceso del documento (enchufe empuje del Personaje). 0 = sin retroceso.
@export var fuerza_empuje = 0.0
@export var vida = 100.0
@export var vida_huida = 30.0
@export var danio_prueba = 25.0
# Sentidos: ve alrededor (sin cono) a esta distancia; peleando, lo suelta más lejos.
@export var rango_vision = 7.0
@export var rango_perder = 10.0
@export var tiempo_busqueda = 2.0
@export var tiempo_max_buscar = 8.0
@export var giro_mirar = 90.0

var estado = Estado.ESPERAR
var reloj = 0.0
var jugador = null
var casa = Vector3.ZERO
var ultimo_visto = Vector3.ZERO
# El proyecto no tiene el modelo .glb del taller: si no hay AnimationPlayer, no se anima.
@onready var anim = get_node_or_null("Modelo/AnimationPlayer")

func _ready():
	jugador = get_tree().get_first_node_in_group("jugador")
	casa = global_position

func _physics_process(delta):
	velocity += get_gravity() * delta
	reloj = maxf(reloj - delta, 0.0)
	var limite = rango_perder if en_combate() else rango_vision
	var ve = distancia() <= limite and lo_ve()
	if ve:
		ultimo_visto = jugador.global_position
	var nuevo = decidir(ve)
	if nuevo != estado:
		cambiar_a(nuevo)
	match estado:
		Estado.ACERCARSE:
			ir_a(jugador.global_position)
		Estado.AVISO:
			frenar("interact-right")
		Estado.GOLPE:
			frenar("attack-melee-right")
			golpear()
		Estado.RECARGA:
			frenar("idle")
		Estado.HUIR:
			# Huir es perseguir con la flecha al revés.
			var lejos = global_position - jugador.global_position
			ir_a(global_position + lejos)
		Estado.ESPERAR:
			frenar("idle")
		Estado.BUSCAR:
			ir_a(ultimo_visto)
		Estado.MIRAR:
			frenar("idle")
			rotate_y(deg_to_rad(giro_mirar) * delta)
		Estado.VOLVER:
			ir_a(casa)
	move_and_slide()

func en_combate():
	return estado in [Estado.ACERCARSE, Estado.AVISO, Estado.GOLPE, Estado.RECARGA]

# Desde cada estado solo se puede pasar a uno: el ciclo del ataque.
func decidir(ve):
	# Va primero: le gana a cualquier estado, también al AVISO.
	if vida <= vida_huida:
		return Estado.HUIR
	match estado:
		Estado.ESPERAR, Estado.BUSCAR, Estado.MIRAR, Estado.VOLVER:
			if ve:
				return Estado.ACERCARSE
	match estado:
		Estado.ACERCARSE:
			# Lo perdió (muro o distancia): va a donde lo vio por última vez.
			if not ve:
				return Estado.BUSCAR
			if distancia() <= rango_ataque:
				return Estado.AVISO
		Estado.AVISO:
			if reloj <= 0.001:
				return Estado.GOLPE
		Estado.GOLPE:
			return Estado.RECARGA
		Estado.RECARGA:
			if reloj <= 0.001:
				return Estado.ACERCARSE
		Estado.BUSCAR:
			if distancia_a(ultimo_visto) <= 0.3 or reloj <= 0.001:
				return Estado.MIRAR
		Estado.MIRAR:
			if reloj <= 0.001:
				return Estado.VOLVER
		Estado.VOLVER:
			if distancia_a(casa) <= 0.3:
				return Estado.ESPERAR
	return estado

func cambiar_a(nuevo):
	estado = nuevo
	print(name, " -> ", Estado.keys()[estado], " cuadro ",
		Engine.get_physics_frames(), " a ",
		snappedf(distancia(), 0.01), " m")
	if estado == Estado.AVISO:
		reloj = tiempo_aviso
	elif estado == Estado.RECARGA:
		reloj = tiempo_recarga
	elif estado == Estado.BUSCAR:
		reloj = tiempo_max_buscar
	elif estado == Estado.MIRAR:
		reloj = tiempo_busqueda

# Rayo de pecho a pecho contra la capa 1 (mundo): si choca con algo, hay un muro en medio.
func lo_ve():
	var desde = global_position + Vector3(0, 0.9, 0)
	var hasta = jugador.global_position + Vector3(0, 0.9, 0)
	var consulta = PhysicsRayQueryParameters3D.create(desde, hasta, 1)
	consulta.exclude = [get_rid(), jugador.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(consulta).is_empty()

# El aviso le da tiempo al jugador: el golpe mira DÓNDE ESTÁ AHORA.
func golpear():
	if distancia() > alcance_golpe:
		print(name, " falla a ", snappedf(distancia(), 0.01), " m")
		return
	var salud = jugador.get_node_or_null("Salud")
	if salud != null:
		salud.recibir_golpe(danio)
	if fuerza_empuje > 0.0 and "empuje" in jugador:
		var lejos = jugador.global_position - global_position
		lejos.y = 0.0
		jugador.empuje = lejos.normalized() * fuerza_empuje

# Se llama igual que en la diana del Taller 8: el rayo ya la sabe usar.
func recibir_golpe(cuanto):
	vida -= cuanto
	print(name, " vida ", vida)
	if vida <= 0.0:
		print(name, " vencido")
		queue_free()

func ir_a(destino):
	var hacia = destino - global_position
	hacia.y = 0.0
	# Ya está encima: Basis.looking_at no acepta un vector cero.
	if hacia.length() < 0.05:
		frenar("idle")
		return
	var dir = hacia.normalized()
	velocity.x = dir.x * rapidez
	velocity.z = dir.z * rapidez
	basis = Basis.looking_at(dir)
	reproducir("walk")

func frenar(animacion):
	velocity.x = 0.0
	velocity.z = 0.0
	reproducir(animacion)

func reproducir(animacion):
	if anim != null:
		anim.play(animacion)

func distancia():
	return distancia_a(jugador.global_position)

# Distancia en el suelo: si el otro salta, no "se aleja".
func distancia_a(p):
	var o = global_position
	return Vector2(p.x - o.x, p.z - o.z).length()
