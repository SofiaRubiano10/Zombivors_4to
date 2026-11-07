extends StaticBody3D

# Alimento: al comerlo (mantener E junto a él) cura por la Salud y le avisa a la Partida.

@export var curacion: int = 20

func _ready() -> void:
	add_to_group("interactivos")

func usar() -> void:
	var pj = get_tree().get_first_node_in_group("jugador")
	var salud = pj.get_node_or_null("Salud") if pj else null
	if salud != null:
		salud.curar(curacion)
	print("alimento comido: ", name, " (+", curacion, " de vida)")
	var partida = get_tree().get_first_node_in_group("partida")
	if partida != null:
		partida.avisar_meta()
	queue_free()
