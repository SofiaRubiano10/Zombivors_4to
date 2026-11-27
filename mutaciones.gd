class_name Mutaciones
extends RefCounted

# Clase 5 - Tarea A (Juan Diego): mutaciones entre zonas, estilo roguelite.
# Pilar 4, una partida más: cada run se siente distinta según lo que elijas.
# Las elegidas son static: sobreviven a recargar la escena al cambiar de zona, y
# se borran al empezar una run nueva (Partida.nueva_run()).
# Clase 8: se compran. Cada mutación tiene un nivel según cuánta ventaja da, y el
# nivel fija su precio base (400, 800 o 1400 puntos). El precio real se multiplica
# por el piso, igual que los puntos (Puntuacion.multiplicador): los pisos altos dan
# más puntos y las cosas cuestan más. Tras el piso 1 la tienda ofrece niveles 1 y 2;
# después, 2 y 3: las mejores mutaciones llegan más tarde.

const LISTA = {
	"Pies de trapo": {"texto": "Haces la mitad de ruido.", "nivel": 1},
	"Tendones nuevos": {"texto": "+0.3 m/s caminando y corriendo.", "nivel": 1},
	"Carne dura": {"texto": "Tras un golpe eres invulnerable 0.5 s más.", "nivel": 1},
	"Olfato": {"texto": "Una flecha señala la comida más cercana.", "nivel": 1},
	"Estómago de hierro": {"texto": "La descomposición es 25 % más lenta.", "nivel": 2},
	"Hambre voraz": {"texto": "La comida cura un 50 % más.", "nivel": 2},
	"Mandíbula": {"texto": "El mordisco tarda 0.7 s.", "nivel": 2},
	"Embestida doble": {"texto": "Dos cargas de embestida.", "nivel": 2},
}
const PRECIO_NIVEL = {1: 400, 2: 800, 3: 1400}

static var elegidas: Array[String] = []

static func tiene(nombre: String) -> bool:
	return nombre in elegidas

static func agregar(nombre: String) -> void:
	if not tiene(nombre):
		elegidas.append(nombre)

static func descripcion(nombre: String) -> String:
	return LISTA[nombre].texto if LISTA.has(nombre) else ""

static func nivel(nombre: String) -> int:
	return LISTA[nombre].nivel if LISTA.has(nombre) else 1

# Precio en la tienda que sale al terminar "piso", redondeado a 50.
static func precio(nombre: String, piso: int) -> int:
	var base = PRECIO_NIVEL[nivel(nombre)] * Puntuacion.multiplicador(piso)
	return int(round(base / 50.0)) * 50

# Niveles que ofrece la tienda al terminar ese piso.
static func niveles_para(piso: int) -> Array:
	return [1, 2] if piso <= 1 else [2, 3]

# Tres al azar que todavía no se tengan.
static func ofrecer(cuantas: int = 3) -> Array:
	var libres = LISTA.keys().filter(func(n): return not tiene(n))
	libres.shuffle()
	return libres.slice(0, cuantas)

# Las ofertas de la tienda: de los niveles del piso, sin repetir lo que ya se tiene,
# con al menos una del nivel más barato. Si faltan, se completa con cualquier otra.
static func ofrecer_tienda(piso: int, cuantas: int = 4) -> Array:
	var niveles = niveles_para(piso)
	var libres = LISTA.keys().filter(func(n): return not tiene(n))
	libres.shuffle()
	var del_piso = libres.filter(func(n): return nivel(n) in niveles)
	var baratas = del_piso.filter(func(n): return nivel(n) == niveles[0])
	var elegidas_tienda = []
	if not baratas.is_empty():
		elegidas_tienda.append(baratas[0])
	for n in del_piso + libres:
		if elegidas_tienda.size() >= cuantas:
			break
		if not n in elegidas_tienda:
			elegidas_tienda.append(n)
	# De la más barata a la más cara.
	elegidas_tienda.sort_custom(func(a, b): return nivel(a) < nivel(b))
	return elegidas_tienda

# Se aplica al empezar cada zona: los nodos nacen con sus números normales.
static func aplicar(pj: Node) -> void:
	if pj == null:
		return
	var salud = pj.get_node_or_null("Salud")
	var mordisco = pj.get_node_or_null("Mordisco")
	var embestida = pj.get_node_or_null("Embestida")
	if tiene("Estómago de hierro") and salud != null:
		# 25 % más lenta: el mismo 2 % cada 13.3 s en vez de cada 10 s.
		salud.intervalo_descomposicion /= 0.75
	if tiene("Tendones nuevos"):
		pj.speed_caminar += 0.3
		pj.speed_correr += 0.3
	if tiene("Mandíbula") and mordisco != null:
		mordisco.tiempo_mordisco = 0.7
	if tiene("Pies de trapo"):
		pj.factor_ruido = 0.5
	if tiene("Carne dura") and salud != null:
		salud.invulnerable += 0.5
	if tiene("Embestida doble") and embestida != null:
		embestida.cargas_max = 2
		embestida.cargas = 2
	# Hambre voraz la mira el alimento al comerse; Olfato, el HUD.
	if not elegidas.is_empty():
		print("mutaciones: ", elegidas)
