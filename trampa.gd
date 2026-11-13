extends Area3D

# Clase 2 - Tarea B (María Sofía): trampa fija en un pasillo.
# Clase 4: es una trampa de oso de tamaño real (70 cm): hay que verla para esquivarla.
# Al pisarla quita vida por la Salud y deja al zombi congelado unos segundos;
# después puede seguir caminando (sale de la trampa sin que lo vuelva a atrapar).

@export var danio = 15
@export var tiempo_congelado = 3.0

func _ready():
	add_to_group("peligros")
	body_entered.connect(_al_entrar)

func _al_entrar(cuerpo):
	if not cuerpo.is_in_group("jugador"):
		return
	var salud = cuerpo.get_node_or_null("Salud")
	if salud != null:
		salud.recibir_golpe(danio)
	if cuerpo.has_method("congelar"):
		cuerpo.congelar(tiempo_congelado)
	print(name, ": trampa pisada")
