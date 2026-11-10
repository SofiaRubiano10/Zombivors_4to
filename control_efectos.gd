class_name ControlEfectos
extends Node

# Taller 5 - Tarea B (María Sofía): traduce eventos del juego en números del shader.
# No pinta nada: solo escribe el uniform "flash".
# Nivel 2: lo dispara la mecánica (grupo "disparadores") y se apaga solo con decaer.
# Nivel 3: disolver(): el objeto desaparece a mordiscos con una textura de ruido.

@export var objetivo: GeometryInstance3D
@export var tecla := KEY_F  # para probar sin la mecánica
@export var radio := 3.0       # m: hasta dónde lo alcanza un evento
@export var dura_flash := 0.5  # s: lo que se nota el destello
@export var dura_dissolve := 1.0
@export var tecla_disolver := KEY_G  # para probar sin la mecánica

var mat: ShaderMaterial
var flash := 0.0
var avance := 0.0
var disolviendo := false

func _ready() -> void:
	mat = objetivo.material_override.duplicate() # cada objeto con su copia
	objetivo.material_override = mat
	for d in get_tree().get_nodes_in_group("disparadores"):
		d.evento.connect(_on_evento)

func _process(delta: float) -> void:
	if Input.is_physical_key_pressed(tecla):
		golpe()
	flash = decaer(flash, 0.0, k_para(dura_flash), delta)
	mat.set_shader_parameter("flash", flash)
	if Input.is_physical_key_pressed(tecla_disolver):
		disolver()
	if disolviendo:
		avance = avance_en(avance, delta, dura_dissolve)
		mat.set_shader_parameter("avance", avance_visible(avance))
		if avance >= 1.0:
			objetivo.visible = false
			disolviendo = false

func disolver() -> void:
	disolviendo = true

func _on_evento(posicion: Vector3) -> void:
	if objetivo.global_position.distance_to(posicion) <= radio:
		golpe()

func golpe() -> void:
	flash = 1.0

static func mezclar(base: Color, color_flash: Color, t: float) -> Color:
	return base + (color_flash - base) * t

static func decaer(actual: float, base: float, k: float, dt: float) -> float:
	return actual + (base - actual) * (1.0 - exp(-k * dt))

static func k_para(duracion: float) -> float:
	return 3.0 / duracion

static func avance_en(actual: float, dt: float, duracion: float) -> float:
	return minf(1.0, actual + dt / duracion)

static func avance_visible(a: float) -> float:
	return lerpf(0.2, 0.8, a) # el tramo donde sí se ve desaparecer
