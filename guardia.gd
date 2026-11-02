extends CharacterBody3D

enum Estado { PATRULLA, PERSEGUIR }

@export var objetivo: Node3D
@export var rapidez: float = 2.0
@export var radio_ver: float = 6.0
@export var radio_perder: float = 9.0
@export var puntos: Array[Vector3] = [
	Vector3(-6, 0, -3),
	Vector3(6, 0, -3)
]

@onready var anim: AnimationPlayer = $Modelo/AnimationPlayer if has_node("Modelo/AnimationPlayer") else null

var estado: Estado = Estado.PATRULLA
var punto: int = 0

func _physics_process(delta: float) -> void:
	velocity += get_gravity() * delta
	if not objetivo:
		move_and_slide()
		return
	
	var hacia: Vector3 = objetivo.global_position - global_position
	hacia.y = 0.0
	var distancia: float = hacia.length()
	
	match estado:
		Estado.PATRULLA:
			if distancia < radio_ver:
				estado = Estado.PERSEGUIR
				print("lo vio a ", snappedf(distancia, 0.01), " m")
			if puntos.size() > 0:
				ir_a(puntos[punto])
				if global_position.distance_to(puntos[punto]) < 0.3:
					punto = (punto + 1) % puntos.size()
		Estado.PERSEGUIR:
			if distancia > radio_perder:
				estado = Estado.PATRULLA
				print("lo perdió a ", snappedf(distancia, 0.01), " m")
			ir_a(objetivo.global_position)
	
	move_and_slide()
	
	if Engine.get_physics_frames() % 30 == 0:
		print("distancia ", snappedf(distancia, 0.01))

func ir_a(p: Vector3) -> void:
	var hacia: Vector3 = p - global_position
	hacia.y = 0.0
	if hacia.length() < 0.05:
		velocity.x = 0.0
		velocity.z = 0.0
		if anim:
			anim.play("idle")
		return
	var dir: Vector3 = hacia.normalized()
	velocity.x = dir.x * rapidez
	velocity.z = dir.z * rapidez
	basis = Basis.looking_at(dir)
	if anim:
		anim.play("walk")
