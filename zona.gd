extends Node

# Clase 5 - Tarea A (Juan Diego): la run de 3 zonas.
# Pilar 4, una partida más. La run son los tres pisos del edificio de oficinas:
# el mismo mapa con otra configuración, cada piso más difícil. Este nodo lee en
# qué zona va la run (Partida.zona, static) y al empezar deja en la escena solo
# los humanos y trampas que le tocan, y le pasa los tiempos a la Partida.

const ZONAS = [
	{"nombre": "Piso 1", "humanos": 1, "tiradores": 0, "trampas": 0, "tarde": 300.0, "reinicio": 480.0},
	{"nombre": "Piso 2", "humanos": 2, "tiradores": 1, "trampas": 2, "tarde": 270.0, "reinicio": 450.0},
	{"nombre": "Piso 3", "humanos": 3, "tiradores": 1, "trampas": 3, "tarde": 240.0, "reinicio": 420.0},
]

# Todos los que PUEDEN aparecer; la zona se queda con los primeros que necesite.
@export var humanos: Array[NodePath] = []
@export var tiradores: Array[NodePath] = []
@export var trampas: Array[NodePath] = []
@export var partida: NodePath = ^"../Partida"

static func datos(numero):
	return ZONAS[clampi(numero, 1, ZONAS.size()) - 1]

func _ready():
	var z = datos(Partida.zona)
	var p = get_node(partida)
	p.zonas_total = ZONAS.size()
	p.tiempo_tarde = z.tarde
	p.tiempo_reinicio = z.reinicio
	# Diferido: mientras la escena arranca no se puede sacar a sus hermanos.
	quedarse_con.call_deferred(humanos, z.humanos)
	quedarse_con.call_deferred(tiradores, z.tiradores)
	quedarse_con.call_deferred(trampas, z.trampas)
	print("zona ", Partida.zona, " (", z.nombre, "): ", z.humanos, " humanos, ",
		z.tiradores, " tiradores, ", z.trampas, " trampas")

# Los que sobran se quitan antes de que empiecen a moverse.
func quedarse_con(lista, cuantos):
	for i in lista.size():
		if i >= cuantos:
			var sobra = get_node(lista[i])
			# Fuera de los grupos ya, para que nadie lo cuente en este cuadro.
			for g in sobra.get_groups():
				sobra.remove_from_group(g)
			sobra.queue_free()
