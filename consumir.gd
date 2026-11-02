extends Node

@export var tecla: String = "consumir"
@onready var pj = get_parent()

var usos: int = 0

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed(tecla):
		usos += 1
		print("empieza: ", tecla, " · uso número ", usos)
