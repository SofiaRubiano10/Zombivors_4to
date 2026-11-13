extends Node3D

# Lámpara de techo de la oficina. No hay techo dibujado: el panel y su luz hacen
# pensar que sí lo hay. Tres estados, el mismo script:
#  - Buena: luz fija.
#  - Dañada: parpadea a ratos, como un tubo fluorescente que falla.
#  - Fundida: apagada; solo queda el panel oscuro.
# Se enciende según lo cerca que esté el zombi: lejos se apaga del todo. Así
# "aparece" al acercarse (como la niebla de las salas) y, de paso, nunca hay
# muchas luces encendidas a la vez (el renderizador Compatibility admite pocas).

@export_enum("Buena", "Dañada", "Fundida") var estado: int = 0
@export var energia = 10.0
@export var color = Color(0.78, 0.86, 1.0) # Blanco frío de oficina
# Hasta esta distancia del zombi alumbra completa.
@export var distancia_plena = 9.0
# Desde esta distancia queda apagada.
@export var distancia_apagada = 14.0

var jugador = null
var material = StandardMaterial3D.new()
# Cuánto deja pasar el parpadeo ahora mismo: 1 encendida, 0 apagada.
var parpadeo = 1.0
var reloj = 0.0
@onready var luz = $Luz
@onready var panel = $Panel

func _ready():
	material.albedo_color = Color(0.12, 0.12, 0.13)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.0
	panel.material_override = material
	luz.light_color = color
	luz.light_energy = 0.0
	if estado == 2:
		# Fundida: no hay nada que calcular nunca.
		luz.visible = false
		set_process(false)

func _process(delta):
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")
		if jugador == null:
			return
	if estado == 1:
		parpadear(delta)
	var fuerza = cercania(distancia_a(jugador.global_position), distancia_plena, distancia_apagada) * parpadeo
	luz.light_energy = energia * fuerza
	luz.visible = fuerza > 0.01
	material.emission_energy_multiplier = 1.5 * fuerza

# Cada cierto rato elige al azar: un tramo encendida (largo) o un apagón (corto).
func parpadear(delta):
	reloj -= delta
	if reloj > 0.0:
		return
	if parpadeo > 0.5 and randf() < 0.6:
		parpadeo = randf_range(0.0, 0.15)
		reloj = randf_range(0.04, 0.25)
	else:
		parpadeo = randf_range(0.8, 1.0)
		reloj = randf_range(0.08, 0.9)

# 1 cerca, 0 lejos, y una bajada suave entre las dos distancias.
static func cercania(d, plena, apagada):
	return 1.0 - smoothstep(plena, apagada, d)

# Distancia en el suelo: la altura de la lámpara no cuenta.
func distancia_a(p):
	var o = global_position
	return Vector2(p.x - o.x, p.z - o.z).length()
