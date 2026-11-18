class_name LuzJugador
extends SpotLight3D

# La visión del zombi: un cono amplio hacia delante y un halo tenue alrededor.
# No es una linterna: es lo que el zombi alcanza a ver.
# Ya no hay día ni noche: la luz depende de la sala. En una sala iluminada el
# zombi ve sin ayuda y el cono baja; en una sala oscura queda al máximo.

@export var rango: float = 10.0 # Metros de alcance de la luz (ve unos 8 m por delante)
@export var apertura: float = 40.0 # Grados de medio cono (35 y horizontal era una linterna)
# La luz va alta y mirando hacia abajo: así ilumina el suelo de delante de forma pareja.
# A la altura de los ojos el suelo lejano casi no recibe luz (le llega de lado).
@export var altura: float = 3.0 # Metros sobre los pies del zombi
@export var inclinacion: float = 35.0 # Grados hacia abajo: apunta a unos 4 m por delante
@export var energia_max: float = 25.0 # Energía del cono en una sala sin luz
@export var halo: OmniLight3D # Luz redonda y débil alrededor del zombi
@export var energia_halo: float = 3.0
@export var suavizado: float = 4.0 # Qué tan rápido sigue al valor que le toca

# 0 sano, 1 crítico. Lo escribe SistemaEventos: con poca vida la luz sube un poco.
var peligro: float = 0.0
# 0 con luz alrededor, 1 a oscuras. Sale de la sala donde está el zombi.
var oscuridad: float = 1.0

func _ready() -> void:
	position = Vector3(0.0, altura, 0.0)
	rotation_degrees = Vector3(-inclinacion, 0.0, 0.0)
	spot_range = rango
	spot_attenuation = 1.0
	spot_angle = apertura
	light_color = Color("#D4A373") # Tono cálido de nuestra paleta
	spot_angle_attenuation = 0.5 # Borde suave pero sin oscurecer medio cono
	shadow_bias = 0.2 # Evita rayas de sombra en los muros
	light_energy = 0.0
	if halo != null:
		halo.light_color = light_color
		halo.light_energy = 0.0

func _process(delta: float) -> void:
	var mezcla: float = 1.0 - exp(-suavizado * delta)
	# Al cruzar una puerta cambia poco a poco, no de golpe.
	oscuridad = lerpf(oscuridad, oscuridad_aqui(), mezcla)
	light_energy = lerpf(light_energy, energia_para(oscuridad, peligro, energia_max), mezcla)
	visible = light_energy > 0.01
	if halo != null:
		halo.light_energy = lerpf(halo.light_energy, energia_halo * oscuridad, mezcla)
		halo.visible = halo.light_energy > 0.01

# La cuenta, aparte para poder probarla: sin oscuridad 0; a oscuras la energía base,
# y hasta un 60 % más cuando al zombi le queda poca vida.
static func energia_para(oscuro: float, riesgo: float, base: float) -> float:
	return base * (1.0 + 0.6 * riesgo) * oscuro

# La oscuridad de la sala donde está el zombi: la más cercana (dentro de una sala
# la distancia es 0). Sin salas en la escena, todo cuenta como oscuro.
func oscuridad_aqui() -> float:
	var mejor: float = INF
	var valor: float = 1.0
	var pos: Vector3 = get_parent().global_position
	for sala in get_tree().get_nodes_in_group("salas"):
		var d: float = sala.distancia_a_sala(pos)
		if d < mejor:
			mejor = d
			valor = sala.oscuridad
	return valor

static func atenuacion(d: float, exponente: float = 2.0) -> float:
	return 1.0 / pow(maxf(d, 0.0001), exponente)
