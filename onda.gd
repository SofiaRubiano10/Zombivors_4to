class_name Onda
extends MeshInstance3D

# Clase 6 (María Sofía): la onda amarilla al comer.
# Un aro plano en el suelo, del amarillo carne de la paleta (el color de la comida),
# que se abre hasta "radio_final" y se desvanece. Se crea desde código con
# Onda.crear(padre, posicion): no hace falta tener nada en la escena.

const AMARILLO_CARNE = Color("#D4A373")

@export var duracion = 0.6
@export var radio_final = 3.0

var t = 0.0
var material = StandardMaterial3D.new()

static func crear(padre: Node, posicion: Vector3) -> void:
	var o = Onda.new()
	padre.add_child(o)
	o.global_position = Vector3(posicion.x, 0.05, posicion.z)

func _ready():
	var aro = TorusMesh.new()
	aro.inner_radius = 0.9
	aro.outer_radius = 1.0
	aro.rings = 48
	aro.ring_segments = 6
	mesh = aro
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = AMARILLO_CARNE
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	actualizar()

func _process(delta):
	t += delta / duracion
	if t >= 1.0:
		queue_free()
		return
	actualizar()

# Se abre rápido al principio y frena al final (1 - (1 - t)^2); se apaga parejo.
func actualizar():
	var abre = 1.0 - pow(1.0 - t, 2.0)
	var r = lerpf(0.2, radio_final, abre)
	scale = Vector3(r, 0.05, r)
	material.albedo_color.a = 1.0 - t
