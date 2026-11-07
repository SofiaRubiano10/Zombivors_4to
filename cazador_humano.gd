extends CharacterBody3D

# Taller 9 - Tarea B (María Sofía): el golpe del humano.
# Nivel 1: el ciclo del ataque ACERCARSE -> AVISO -> GOLPE -> RECARGA.
# Nivel 2: el golpe mira dónde está el jugador y le quita vida a su Salud.
# Nivel 3: el cazador también tiene vida y huye cuando le queda poca.

enum Estado { ACERCARSE, AVISO, GOLPE, RECARGA, HUIR }

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

var estado = Estado.ACERCARSE
var reloj = 0.0
var jugador = null
# El proyecto no tiene el modelo .glb del taller: si no hay AnimationPlayer, no se anima.
@onready var anim = get_node_or_null("Modelo/AnimationPlayer")

func _ready():
	jugador = get_tree().get_first_node_in_group("jugador")

func _physics_process(delta):
	velocity += get_gravity() * delta
	reloj = maxf(reloj - delta, 0.0)
	var nuevo = decidir()
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
	move_and_slide()

# Desde cada estado solo se puede pasar a uno: el ciclo del ataque.
func decidir():
	# Va primero: le gana a cualquier estado, también al AVISO.
	if vida <= vida_huida:
		return Estado.HUIR
	match estado:
		Estado.ACERCARSE:
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
	var p = jugador.global_position
	var o = global_position
	return Vector2(p.x - o.x, p.z - o.z).length()
