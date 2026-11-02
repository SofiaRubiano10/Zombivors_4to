extends Node

enum Estado { LISTA, ACTIVA, RECARGA }

@export var tecla: String = "consumir"
@export var duracion: float = 1.5
@export var recarga: float = 0.5
@export var curacion: float = 20.0

@onready var pj = get_parent()

var estado: Estado = Estado.LISTA
var tiempo: float = 0.0
var usos: int = 0

func _physics_process(delta: float) -> void:
	tiempo -= delta
	match estado:
		Estado.LISTA:
			if Input.is_action_just_pressed(tecla) and puede():
				empezar()
		Estado.ACTIVA:
			if tiempo <= 0.001:
				terminar()
		Estado.RECARGA:
			if tiempo <= 0.001:
				estado = Estado.LISTA

func puede() -> bool:
	return pj != null and pj.is_on_floor()

func empezar() -> void:
	estado = Estado.ACTIVA
	tiempo = duracion
	usos += 1
	pj.multiplicador = 0.0
	pj.accion = "pick-up"
	print("empieza: ", tecla, " · uso número ", usos)

func terminar() -> void:
	estado = Estado.RECARGA
	tiempo = recarga
	pj.salud = minf(pj.salud_maxima, pj.salud + curacion)
	print("termina: ", tecla, " · curó +", curacion, " HP · salud resultante: ", pj.salud)
	pj.empuje = Vector3.ZERO
	pj.multiplicador = 1.0
	pj.accion = ""

## Función de apoyo para retroceso táctico al chocar contra amenazas (extra)
func aplicar_retroceso_impacto(fuerza: float = 4.0) -> void:
	if pj:
		pj.empuje = -pj.basis.z * fuerza
		print("Retroceso recibido por impacto: fuerza = ", fuerza, " m/s")
