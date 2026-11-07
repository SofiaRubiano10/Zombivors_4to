extends CharacterBody3D

# Taller 9 - Tarea A (Juan Diego): el humano que patrulla.
# Nivel 1: patrulla por un array de puntos recorrido con un índice.

enum Estado { PATRULLAR, ESPERAR }

@export var rapidez = 2.0
@export var espera = 1.0
# Desplazamientos desde donde se colocó el NPC, no posiciones absolutas.
@export var ruta: Array[Vector3] = [Vector3.ZERO, Vector3(0, 0, -6)]

var estado = Estado.PATRULLAR
var puntos: Array[Vector3] = []
var indice = 0
var reloj = 0.0
# El proyecto no tiene el modelo .glb del taller: si no hay AnimationPlayer, no se anima.
@onready var anim = get_node_or_null("Modelo/AnimationPlayer")

func _ready():
	for d in ruta:
		puntos.append(global_position + d)

func _physics_process(delta):
	velocity += get_gravity() * delta
	reloj = maxf(reloj - delta, 0.0)
	# 1. DECIDIR
	var nuevo = decidir()
	if nuevo != estado:
		estado = nuevo
		print(name, " -> ", Estado.keys()[estado], " cuadro ",
			Engine.get_physics_frames(), " en ",
			global_position.snappedf(0.01))
	# 2. ACTUAR
	match estado:
		Estado.PATRULLAR:
			patrullar()
		Estado.ESPERAR:
			frenar()
	move_and_slide()

func decidir():
	if reloj > 0.001:
		return Estado.ESPERAR
	return Estado.PATRULLAR

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
