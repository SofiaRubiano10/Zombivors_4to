class_name Disparador
extends Area3D

signal evento(posicion: Vector3)

@export var tecla: Key = KEY_T
@export var que_representa := "recibir daño"
@export var dano: float = 15.0
@export var fuerza_empuje: float = 6.0

var antes := false

func _enter_tree() -> void:
	add_to_group("disparadores")

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(cuerpo: Node3D) -> void:
	if cuerpo == get_parent() or cuerpo is StaticBody3D:
		return
	if cuerpo.is_in_group("jugador") or cuerpo.name == "Personaje":
		# El daño pasa por la Salud del jugador: es la única que guarda la vida.
		var salud = cuerpo.get_node_or_null("Salud")
		if salud != null:
			salud.recibir_golpe(int(dano))
		if "empuje" in cuerpo:
			var dir_empuje: Vector3 = (cuerpo.global_position - global_position)
			dir_empuje.y = 0.0
			if dir_empuje.length() > 0.01:
				cuerpo.empuje = dir_empuje.normalized() * fuerza_empuje
		evento.emit(global_position)

func _physics_process(_delta: float) -> void:
	var ahora := Input.is_key_pressed(tecla)
	if ahora and not antes:
		evento.emit(global_position)
	antes = ahora
