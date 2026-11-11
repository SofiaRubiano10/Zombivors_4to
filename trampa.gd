extends Area3D

# Clase 2 - Tarea B (María Sofía): trampa fija en un pasillo.
# Al pisarla quita vida por la Salud (la invulnerabilidad evita golpes seguidos)
# y empuja al zombi hacia fuera con el enchufe empuje del Personaje.

@export var danio = 15
@export var fuerza_empuje = 6.0

func _ready():
	add_to_group("peligros")
	body_entered.connect(_al_entrar)

func _al_entrar(cuerpo):
	if not cuerpo.is_in_group("jugador"):
		return
	var salud = cuerpo.get_node_or_null("Salud")
	if salud != null:
		salud.recibir_golpe(danio)
	if "empuje" in cuerpo:
		var fuera = cuerpo.global_position - global_position
		fuera.y = 0.0
		if fuera.length() < 0.01:
			fuera = Vector3.BACK
		cuerpo.empuje = fuera.normalized() * fuerza_empuje
	print(name, ": trampa pisada")
