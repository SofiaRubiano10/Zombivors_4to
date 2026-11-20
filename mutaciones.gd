class_name Mutaciones
extends RefCounted

# Clase 5 - Tarea A (Juan Diego): mutaciones entre zonas, estilo roguelite.
# Pilar 4, una partida más: cada run se siente distinta según lo que elijas.
# Las elegidas son static: sobreviven a recargar la escena al cambiar de zona, y
# se borran al empezar una run nueva (Partida.nueva_run()).

const LISTA = {
	"Estómago de hierro": "La descomposición es 25 % más lenta.",
	"Tendones nuevos": "+0.3 m/s caminando y corriendo.",
	"Mandíbula": "El mordisco tarda 0.7 s.",
	"Pies de trapo": "Haces la mitad de ruido.",
	"Hambre voraz": "La comida cura un 50 % más.",
	"Carne dura": "Tras un golpe eres invulnerable 0.5 s más.",
	"Embestida doble": "Dos cargas de embestida.",
	"Olfato": "Una flecha señala la comida más cercana.",
}

static var elegidas: Array[String] = []

static func tiene(nombre: String) -> bool:
	return nombre in elegidas

static func agregar(nombre: String) -> void:
	if not tiene(nombre):
		elegidas.append(nombre)

# Tres al azar que todavía no se tengan.
static func ofrecer(cuantas: int = 3) -> Array:
	var libres = LISTA.keys().filter(func(n): return not tiene(n))
	libres.shuffle()
	return libres.slice(0, cuantas)

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
