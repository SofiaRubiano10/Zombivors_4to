extends StaticBody3D

@export var curacion: float = 20.0

func _ready() -> void:
	add_to_group("interactivos")

func usar() -> void:
	print("Alimento orgánico consumido (+", curacion, " HP): regenerando tejido del zombi...")
	var pj = get_tree().get_first_node_in_group("jugador")
	if pj and "salud" in pj:
		pj.salud = minf(pj.salud_maxima, pj.salud + curacion)
		print("Salud actualizada del zombi: ", pj.salud, " / ", pj.salud_maxima)
	queue_free()
