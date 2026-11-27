class_name LuzJugador
extends SpotLight3D

# La visión del zombi: un cono amplio hacia delante y un halo tenue alrededor.
# No es una linterna: es lo que el zombi alcanza a ver.
# Ya no hay día ni noche: la luz depende de la sala. En una sala iluminada el
# zombi ve sin ayuda y el cono baja; en una sala oscura queda al máximo.
# Clase 8: la vista va con la vida. Un zombi que se pudre ve menos: con la vida
# llena el cono llega a "rango" y abre "apertura"; al acercarse a 0 se encoge hasta
# rango_min y apertura_min, y el halo también. Comer devuelve la vista.
# "alcance" (1 sano, más bajo con poca vida) lo leen las salas para cerrar antes la
# niebla de alrededor. La mutación "Ojos de noche" lo multiplica (factor_vision).

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
@export var rango_min: float = 5.5 # Metros de alcance con la vida a 0
@export var apertura_min: float = 28.0 # Grados de medio cono con la vida a 0
@export var halo_min: float = 0.6 # Parte del radio del halo que queda con la vida a 0

# 0 sano, 1 crítico. Lo escribe SistemaEventos: con poca vida se ve menos.
var peligro: float = 0.0
# Lo pone la mutación "Ojos de noche" (Mutaciones.aplicar): multiplica la vista.
var factor_vision: float = 1.0
# Parte de la vista sana que queda (rango actual / rango). Lo leen las salas.
var alcance: float = 1.0
var radio_halo: float = 1.0
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
		radio_halo = halo.omni_range

func _process(delta: float) -> void:
	var mezcla: float = 1.0 - exp(-suavizado * delta)
	# Al cruzar una puerta cambia poco a poco, no de golpe.
	oscuridad = lerpf(oscuridad, oscuridad_aqui(), mezcla)
	light_energy = lerpf(light_energy, energia_para(oscuridad, energia_max), mezcla)
	visible = light_energy > 0.01
	# La vista se encoge con la vida: despacio, para que se note sin dar saltos.
	var vista: float = 1.0 - peligro
	spot_range = lerpf(spot_range, lerpf(rango_min, rango, vista) * factor_vision, mezcla)
	spot_angle = lerpf(spot_angle, minf(lerpf(apertura_min, apertura, vista) * factor_vision, 60.0), mezcla)
	alcance = spot_range / rango
	if halo != null:
		halo.light_energy = lerpf(halo.light_energy, energia_halo * oscuridad, mezcla)
		halo.omni_range = radio_halo * lerpf(halo_min, 1.0, vista) * factor_vision
		halo.visible = halo.light_energy > 0.01

# La cuenta, aparte para poder probarla: sin oscuridad 0; a oscuras la energía base.
# (Antes subía con poca vida; desde la clase 8 la vida cambia el alcance, no la luz.)
static func energia_para(oscuro: float, base: float) -> float:
	return base * oscuro

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
