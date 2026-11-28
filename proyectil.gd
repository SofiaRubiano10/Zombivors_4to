extends Area3D

# Clase 3 - Tarea B (María Sofía): el proyectil del tirador.
# Avanza en línea recta; si toca al zombi le quita vida por la Salud y desaparece.
# Si toca un muro o un mueble (capa 1) también desaparece.

var direccion = Vector3.FORWARD
var rapidez = 5.0
var danio = 10
@export var vida_maxima = 4.0

func _ready():
	add_to_group("peligros")
	body_entered.connect(_al_tocar)

func _physics_process(delta):
	global_position += direccion * rapidez * delta
	vida_maxima -= delta
	if vida_maxima <= 0.0:
		queue_free()

func _al_tocar(cuerpo):
	if cuerpo.is_in_group("jugador"):
		var salud = cuerpo.get_node_or_null("Salud")
		if salud != null:
			salud.recibir_golpe(danio)
		print("proyectil acierta")
	queue_free()
