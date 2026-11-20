extends Node

# Clase 6 - Criterio visual 3 (María Sofía): hit flash y desaturación del zombi.
# Hijo del Personaje. Escucha a la Salud (no le pregunta cada cuadro):
#  - golpeado -> destello blanco que se apaga en 0.5 s.
#  - cambio(vida) -> el gris sube a medida que baja la vida.
# El material del modelo se cambia por efecto_zombi.gdshader (misma textura).
# Las curvas son las de ControlEfectos (Taller 5): decaer() con k = 3 / duración para
# el destello, y k = 2 para la desaturación (en t = 0.5 ya recorrió el 63.21 %).

@export var dura_flash = 0.5
@export var k_desaturar = 2.0
# Con la vida llena no hay gris; al llegar a 0 queda en este máximo.
@export var desaturacion_max = 1.0

# Un material por textura del modelo (el de Kenney usa una sola).
var materiales = {}
var flash = 0.0
var desaturar = 0.0
var objetivo_desaturar = 0.0
@onready var pj = get_parent()
@onready var salud = pj.get_node_or_null("Salud")

func _ready():
	var modelo = pj.get_node_or_null("Modelo")
	if modelo != null:
		for malla in modelo.find_children("*", "MeshInstance3D", true, false):
			cambiar_material(malla)
	if salud != null:
		salud.golpeado.connect(_al_golpe)
		salud.cambio.connect(_al_cambiar)
		_al_cambiar(salud.vida)

# Cambia el material de cada superficie por el del efecto, con la misma textura.
func cambiar_material(malla):
	for i in malla.mesh.get_surface_count():
		var original = malla.get_active_material(i)
		var textura = original.albedo_texture if original is StandardMaterial3D else null
		if not materiales.has(textura):
			var m = ShaderMaterial.new()
			m.shader = preload("res://efecto_zombi.gdshader")
			m.set_shader_parameter("textura", textura)
			materiales[textura] = m
		malla.set_surface_override_material(i, materiales[textura])

func _al_golpe(_danio):
	flash = 1.0

func _al_cambiar(vida):
	var inicial = maxf(1.0, salud.vida_inicial)
	objetivo_desaturar = clampf(1.0 - float(vida) / inicial, 0.0, 1.0) * desaturacion_max

func _process(delta):
	# Los bordes rojos de humanos y trampas se encienden según dónde está el zombi.
	BordeRojo.seguir(pj.global_position)
	flash = ControlEfectos.decaer(flash, 0.0, ControlEfectos.k_para(dura_flash), delta)
	desaturar = ControlEfectos.decaer(desaturar, objetivo_desaturar, k_desaturar, delta)
	for m in materiales.values():
		m.set_shader_parameter("flash", flash)
		m.set_shader_parameter("desaturar", desaturar)
