class_name Sentidos
extends RefCounted

# Clase 2 (Sofía y Juan): los sentidos que comparten los cazadores y el zombi.
# Son funciones static: no hace falta crear un nodo, se llaman como
# Sentidos.en_cono(...) desde cualquier script.
# Todo se mide en el suelo (x, z): saltar o agacharse no cambia nada.

# Hacia dónde mira un cuerpo. Godot mira hacia -Z (Basis.looking_at).
static func frente(cuerpo: Node3D) -> Vector3:
	var f := -cuerpo.global_basis.z
	f.y = 0.0
	return f.normalized()

# Dirección en el suelo desde el punto a hasta el punto b.
static func hacia(a: Vector3, b: Vector3) -> Vector3:
	var d := b - a
	d.y = 0.0
	return d.normalized()

static func distancia(a: Vector3, b: Vector3) -> float:
	return Vector2(b.x - a.x, b.z - a.z).length()

# El cono de visión: cerca Y delante. medio_angulo = 45 -> 90° de campo.
static func en_cono(cuerpo: Node3D, punto: Vector3, rango: float, medio_angulo: float) -> bool:
	if distancia(cuerpo.global_position, punto) > rango:
		return false
	var dir := hacia(cuerpo.global_position, punto)
	return frente(cuerpo).dot(dir) >= cos(deg_to_rad(medio_angulo))

# ¿El atacante está detrás del cuerpo? -0.25 deja la espalda con unos 150°:
# basta con no estar delante ni pegado a su hombro.
static func a_la_espalda(cuerpo: Node3D, atacante: Vector3) -> bool:
	var dir := hacia(cuerpo.global_position, atacante)
	return frente(cuerpo).dot(dir) <= -0.25

# Línea de vista: un rayo de pecho a pecho. Si lo primero que toca es el
# objetivo, nada lo tapa. Los muros, las mesas y otros cuerpos sí tapan.
static func linea_de_vista(cuerpo: CollisionObject3D, objetivo: CollisionObject3D) -> bool:
	var pecho := Vector3(0, 0.9, 0)
	var consulta := PhysicsRayQueryParameters3D.create(
		cuerpo.global_position + pecho, objetivo.global_position + pecho)
	consulta.exclude = [cuerpo.get_rid()]
	var choque := cuerpo.get_world_3d().direct_space_state.intersect_ray(consulta)
	return choque.is_empty() or choque.collider == objetivo

# Avisa a los cazadores cercanos de dónde está el zombi. Devuelve a cuántos.
static func alertar(emisor: Node3D, posicion: Vector3, radio: float) -> int:
	var avisados := 0
	for otro in emisor.get_tree().get_nodes_in_group("cazadores"):
		if otro == emisor or not otro.has_method("recibir_alerta"):
			continue
		if distancia(emisor.global_position, otro.global_position) <= radio:
			if otro.recibir_alerta(posicion):
				avisados += 1
	return avisados

# El HUD es opcional: si no está, el aviso se pierde sin romper nada.
static func aviso(arbol: SceneTree, texto: String, color: Color = Color.WHITE) -> void:
	arbol.call_group("hud", "aviso", texto, color)
