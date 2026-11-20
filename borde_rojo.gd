class_name BordeRojo
extends RefCounted

# Clase 6 - Criterio visual 1 (María Sofía): pone el borde rojo (borde_rojo.gdshader)
# a todas las mallas de un nodo: humanos, tirador, cazador y trampas lo llaman en su
# _ready(). Un solo material compartido: cuando el zombi se mueve se avisa una vez
# (seguir) y todos los bordes saben a qué distancia está.

static var material: ShaderMaterial = null

static func poner(nodo: Node) -> void:
	if material == null:
		material = ShaderMaterial.new()
		material.shader = preload("res://borde_rojo.gdshader")
	for malla in nodo.find_children("*", "MeshInstance3D", true, false):
		malla.material_overlay = material

static func seguir(posicion: Vector3) -> void:
	if material != null:
		material.set_shader_parameter("jugador", posicion)
