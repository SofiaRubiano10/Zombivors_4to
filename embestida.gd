extends Node

# Clase 4 - Tarea A (Juan Diego): la embestida. Hijo del Personaje.
# Pilar 3, cada decisión cuesta: sirve para salir de un apuro, pero se paga.
#  - Espacio: impulso de 0.25 s a 7 m/s hacia donde mira el zombi (1.75 m).
#  - Cuesta 3 de vida, hace 3 m de ruido y tarda 3 s en recargarse.
#  - Si choca con un humano lo aturde 1.5 s: entonces se le puede morder de frente.
#  - cargas_max lo sube la mutación "Embestida doble".
# Medido (C4-04): recorre 1.75 m; tras el choque hay 1.5 s para empezar a morder,
# y mientras lo muerdes sigue aturdido.

@export var tecla = "embestir"
@export var duracion = 0.25
@export var rapidez = 7.0
@export var enfriamiento = 3.0
@export var costo = 3
@export var aturdimiento = 1.5
# Distancia entre centros a la que cuenta como choque (dos cápsulas de 0.35 m + margen).
@export var alcance_choque = 0.95
@export var ruido = 3.0
@export var cargas_max = 1

@onready var pj = get_parent()

var cargas = 1
# Lo que falta para recuperar una carga.
var recarga = 0.0
# Lo que le queda al impulso en curso.
var activo = 0.0
var direccion = Vector3.ZERO

func _ready():
	cargas = cargas_max

func _physics_process(delta):
	recargar(delta)
	if activo > 0.0:
		impulsar(delta)
	elif Input.is_action_just_pressed(tecla) and puede_embestir():
		empezar()

func recargar(delta):
	if cargas >= cargas_max:
		recarga = 0.0
		return
	recarga -= delta
	if recarga <= 0.0:
		cargas += 1
		recarga = enfriamiento if cargas < cargas_max else 0.0

func puede_embestir():
	return cargas > 0 and pj.congelado <= 0.0 and pj.accion == ""

func empezar():
	cargas -= 1
	if recarga <= 0.0:
		recarga = enfriamiento
	activo = duracion
	direccion = -pj.global_transform.basis.z
	direccion.y = 0.0
	direccion = direccion.normalized()
	var salud = pj.get_node_or_null("Salud")
	if salud != null:
		salud.quitar_vida(costo)
	Sonidos.tocar("embestida")
	pj.hizo_ruido.emit(pj.global_position, ruido * pj.factor_ruido)
	print("embestida (quedan ", cargas, " cargas)")

func impulsar(delta):
	activo -= delta
	# El impulso reemplaza a la caminata mientras dura.
	pj.avance = Vector3.ZERO
	pj.empuje = direccion * rapidez
	var presa = choque()
	if presa != null:
		print("embestida: aturde a ", presa.name)
		Sonidos.tocar("golpe")
		presa.aturdir(aturdimiento)
		terminar()
	elif activo <= 0.0:
		terminar()

func terminar():
	activo = 0.0
	pj.empuje = Vector3.ZERO

func choque():
	for h in get_tree().get_nodes_in_group("humanos"):
		var a = pj.global_position
		var b = h.global_position
		if Vector2(a.x - b.x, a.z - b.z).length() <= alcance_choque:
			return h
	return null
