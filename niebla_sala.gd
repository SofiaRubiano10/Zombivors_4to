extends MeshInstance3D

# Niebla de una sala. Es una caja negra y transparente del tamaño de la sala:
# donde está el zombi se vuelve invisible, y se va cerrando a negro cuanto más
# lejos está el zombi de ESTA sala. Como es una caja (y no una tapa), oculta lo
# que hay dentro desde cualquier ángulo de la cámara: muebles, comida, humanos.
# Cada sala tiene su nodo con este script; no se conocen entre sí.

# Hasta esta distancia de la sala (en metros) se ve del todo.
@export var distancia_clara = 0.5
# Desde esta distancia queda cerrada.
@export var distancia_oscura = 4.0
# 1 sería negro total; un poco menos deja adivinar los muros.
@export var opacidad_max = 0.97
# Qué tan rápido se abre o se cierra (más alto = más rápido).
@export var suavizado = 5.0

var jugador = null
var material = StandardMaterial3D.new()
var opacidad = 1.0

func _ready():
	# Sin sombreado: la niebla no recibe luz, siempre es negra.
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0, 0, 0, opacidad_max)
	material_override = material
	# La niebla no hace sombra: si no, taparía la luz de la sala.
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	opacidad = opacidad_max

func _process(delta):
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")
		if jugador == null:
			return
	var d = distancia_a_sala(jugador.global_position)
	var objetivo = opacidad_para(d, distancia_clara, distancia_oscura) * opacidad_max
	opacidad = lerpf(opacidad, objetivo, 1.0 - exp(-suavizado * delta))
	material.albedo_color.a = opacidad
	# Del todo abierta no se dibuja: no gasta nada.
	visible = opacidad > 0.01

# Distancia en el suelo desde un punto hasta el rectángulo de la sala. Dentro es 0.
func distancia_a_sala(p):
	var mitad = mesh.size * 0.5
	var c = global_position
	var dx = maxf(absf(p.x - c.x) - mitad.x, 0.0)
	var dz = maxf(absf(p.z - c.z) - mitad.z, 0.0)
	return Vector2(dx, dz).length()

# La cuenta, aparte para probarla: 0 hasta "clara", 1 desde "oscura", curva suave en medio.
static func opacidad_para(d, clara, oscura):
	return smoothstep(clara, oscura, d)
