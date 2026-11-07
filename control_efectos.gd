class_name ControlEfectos
extends Node

# Taller 5 - Tarea B (María Sofía): traduce eventos del juego en números del shader.
# No pinta nada: solo escribe el uniform "flash".

@export var objetivo: GeometryInstance3D
@export var tecla := KEY_F  # para probar sin la mecánica

var mat: ShaderMaterial
var flash := 0.0

func _ready() -> void:
	mat = objetivo.material_override

func _process(delta: float) -> void:
	if Input.is_physical_key_pressed(tecla):
		golpe()
	mat.set_shader_parameter("flash", flash)

func golpe() -> void:
	flash = 1.0

static func mezclar(base: Color, color_flash: Color, t: float) -> Color:
	return base + (color_flash - base) * t
