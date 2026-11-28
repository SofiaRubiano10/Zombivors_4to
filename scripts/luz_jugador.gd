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
# Clase 8 (se notaba poco): en las salas iluminadas el cono casi se apaga, así que
# encogerlo no se veía. Ahora la vista también es un efecto en pantalla
# (vision_zombi.gdshader): fuera de un círculo alrededor del zombi todo se oscurece.
# Con la vida llena el círculo es grande y la sombra suave; con poca vida se cierra
# y se vuelve casi negra. Si el cazador está cerca, visión de túnel: el círculo se
# achica más y la sombra se tiñe de rojo (lee Cazador.amenaza).

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
@export var radio_sano: float = 0.62 # Radio claro con la vida llena (parte del alto de pantalla)
@export var radio_critico: float = 0.2 # Radio claro con la vida a 0
@export var sombra_sana: float = 0.45 # Opacidad de la sombra con la vida llena
@export var sombra_critica: float = 0.9 # Opacidad de la sombra con la vida a 0
@export var tunel_cazador: float = 0.4 # Cuánto se cierra el círculo con el cazador encima
var vista_suave: float = 1.0
var amenaza_suave: float = 0.0
var pantalla: ColorRect = null
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
	crear_pantalla()

# La capa de la vista: debajo del HUD (que está en la capa 1), encima del mundo.
func crear_pantalla() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 0
	add_child(capa)
	pantalla = ColorRect.new()
	pantalla.set_anchors_preset(Control.PRESET_FULL_RECT)
	pantalla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = preload("res://vision_zombi.gdshader")
	pantalla.material = material
	capa.add_child(pantalla)

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
	vista_suave = lerpf(vista_suave, vista, mezcla)
	amenaza_suave = lerpf(amenaza_suave, amenaza_cazador(), 1.0 - exp(-6.0 * delta))
	pintar_pantalla()

func amenaza_cazador() -> float:
	var cazador: Node = get_tree().get_first_node_in_group("cazador")
	return cazador.amenaza if cazador != null and "amenaza" in cazador else 0.0

func pintar_pantalla() -> void:
	var camara: Camera3D = get_viewport().get_camera_3d()
	if pantalla == null or camara == null:
		return
	var tam: Vector2 = get_viewport().get_visible_rect().size
	var zombi: Vector2 = camara.unproject_position(get_parent().global_position + Vector3(0.0, 0.9, 0.0))
	var radio: float = lerpf(radio_critico, radio_sano, vista_suave) * factor_vision
	radio *= 1.0 - tunel_cazador * amenaza_suave
	var sombra: float = maxf(lerpf(sombra_critica, sombra_sana, vista_suave), sombra_sana + 0.3 * amenaza_suave)
	var m: ShaderMaterial = pantalla.material
	m.set_shader_parameter("centro", zombi / tam)
	m.set_shader_parameter("aspecto", tam.x / maxf(tam.y, 1.0))
	m.set_shader_parameter("radio", radio)
	m.set_shader_parameter("oscuridad", minf(sombra, 0.95))
	m.set_shader_parameter("tinte", Color.BLACK.lerp(Color(0.2, 0.0, 0.01), amenaza_suave))

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
