extends Node

# Clase 5 - Tarea A (Juan Diego): la run de 3 zonas.
# Pilar 4, una partida más. La run son los tres pisos del edificio de oficinas:
# el mismo mapa con otra configuración, cada piso más difícil. Este nodo lee en
# qué zona va la run (Partida.zona, static) y al empezar deja en la escena solo
# los humanos y trampas que le tocan, y le pasa los tiempos a la Partida.
# Clase 5 (variación): en cada intento sortea dónde va la comida, la salida, las
# trampas y por dónde patrulla cada humano, entre puntos ya probados contra el mapa
# (sin muebles encima y con las rutas libres). Ningún intento se juega igual.

const ZONAS = [
	{"nombre": "Piso 1", "humanos": 1, "tiradores": 0, "trampas": 0, "tarde": 300.0, "reinicio": 480.0},
	{"nombre": "Piso 2", "humanos": 2, "tiradores": 1, "trampas": 2, "tarde": 270.0, "reinicio": 450.0},
	{"nombre": "Piso 3", "humanos": 3, "tiradores": 1, "trampas": 3, "tarde": 240.0, "reinicio": 420.0},
]

# Puntos válidos (x, z). Ninguno está en la Recepción, donde empieza el zombi.
const PUNTOS_COMIDA = [
	Vector2(-18, -12), Vector2(-22, -5), Vector2(-6, -14), Vector2(-3, -10), Vector2(-10, -5),
	Vector2(6, -10), Vector2(6, -4), Vector2(10, -14), Vector2(20, -4), Vector2(-8, 14),
	Vector2(8, 6), Vector2(-6, 12), Vector2(-2, 6), Vector2(14, 7), Vector2(22, 12),
]
const PUNTOS_SALIDA = [Vector2(20, -14), Vector2(9, -15), Vector2(21, 16), Vector2(-19, -15)]
# Puertas y pasillo: obligan a elegir por dónde ir. La puerta de la Recepción no.
const PUNTOS_TRAMPA = [
	Vector2(18, -3.2), Vector2(19.6, 13.8), Vector2(-6, -3), Vector2(6, -3), Vector2(-4, 3),
	Vector2(4, 3), Vector2(0, 0.8), Vector2(-12, 0.5), Vector2(12, -0.5),
]
# Rutas de patrulla en puntos absolutos; cada humano toma una distinta.
const RUTAS = [
	[Vector2(-20, 0), Vector2(20, 0)],
	[Vector2(-18, 0), Vector2(-18, -13), Vector2(-22, -13), Vector2(-18, -13)],
	[Vector2(-6, 0), Vector2(-6, -9), Vector2(-10, -9), Vector2(-6, -9)],
	[Vector2(6, 0), Vector2(6, -3), Vector2(10, -3), Vector2(10, -14), Vector2(10, -3), Vector2(6, -3)],
	[Vector2(18, 0), Vector2(18, -13), Vector2(14, -13), Vector2(18, -13)],
	[Vector2(-4, 0), Vector2(-4, 7), Vector2(4, 7), Vector2(4, 0)],
	[Vector2(18, 0), Vector2(18, 13), Vector2(14, 13), Vector2(18, 13)],
]
const RUTAS_TIRADOR = [
	[Vector2(0, 6), Vector2(0, 9)],
	[Vector2(9, -6), Vector2(9, -9)],
	[Vector2(15, -8), Vector2(15, -12)],
]

# Todos los que PUEDEN aparecer; la zona se queda con los primeros que necesite.
@export var humanos: Array[NodePath] = []
@export var tiradores: Array[NodePath] = []
@export var trampas: Array[NodePath] = []
@export var partida: NodePath = ^"../Partida"
@export var comida: NodePath = ^"../Cajas"
@export var salida: NodePath = ^"../Salida"
@export var jugador: NodePath = ^"../Personaje"
# Apagado deja todo donde está en la escena (para probar algo fijo).
@export var variar = true

static func datos(numero):
	return ZONAS[clampi(numero, 1, ZONAS.size()) - 1]

func _ready():
	var z = datos(Partida.zona)
	var p = get_node(partida)
	p.zonas_total = ZONAS.size()
	p.tiempo_tarde = z.tarde
	p.tiempo_reinicio = z.reinicio
	if variar:
		sortear()
	# Diferido: mientras la escena arranca no se puede sacar a sus hermanos.
	quedarse_con.call_deferred(humanos, z.humanos)
	quedarse_con.call_deferred(tiradores, z.tiradores)
	quedarse_con.call_deferred(trampas, z.trampas)
	print("zona ", Partida.zona, " (", z.nombre, "): ", z.humanos, " humanos, ",
		z.tiradores, " tiradores, ", z.trampas, " trampas")

# Antes de que los humanos calculen su ruta en su _ready (van después en la escena).
func sortear():
	var inicio = get_node(jugador).global_position
	# Comida: puntos distintos al azar; el cerebro al más lejano del zombi.
	var puntos = PUNTOS_COMIDA.duplicate()
	puntos.shuffle()
	var cajas = get_node(comida).get_children()
	var elegidos = puntos.slice(0, cajas.size())
	elegidos.sort_custom(func(a, b): return lejos(a, inicio) > lejos(b, inicio))
	var resto = elegidos.slice(1)
	for caja in cajas:
		var p = elegidos[0] if caja.name == "Cerebro" else resto.pop_back()
		caja.global_position = Vector3(p.x, caja.global_position.y, p.y)
	var s = PUNTOS_SALIDA.pick_random()
	get_node(salida).global_position = Vector3(s.x, 0, s.y)
	var lugares = PUNTOS_TRAMPA.duplicate()
	lugares.shuffle()
	for i in trampas.size():
		var t = lugares[i]
		get_node(trampas[i]).global_position = Vector3(t.x, 0, t.y)
	repartir_rutas(humanos, RUTAS)
	repartir_rutas(tiradores, RUTAS_TIRADOR)
	print("variación: salida en ", s, ", cerebro en ", elegidos[0])

func repartir_rutas(lista, rutas):
	var mezcla = rutas.duplicate()
	mezcla.shuffle()
	for i in mini(lista.size(), mezcla.size()):
		var h = get_node(lista[i])
		var r = mezcla[i]
		h.global_position = Vector3(r[0].x, 0, r[0].y)
		# La ruta del humano son desplazamientos desde donde empieza.
		var desplazamientos: Array[Vector3] = []
		for p in r:
			desplazamientos.append(Vector3(p.x - r[0].x, 0, p.y - r[0].y))
		h.ruta = desplazamientos

static func lejos(p, inicio):
	return Vector2(inicio.x, inicio.z).distance_to(p)

# Los que sobran se quitan antes de que empiecen a moverse.
func quedarse_con(lista, cuantos):
	for i in lista.size():
		if i >= cuantos:
			var sobra = get_node(lista[i])
			# Fuera de los grupos ya, para que nadie lo cuente en este cuadro.
			for g in sobra.get_groups():
				sobra.remove_from_group(g)
			sobra.queue_free()
