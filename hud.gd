class_name HUDZombivors
extends CanvasLayer

@export var personaje: Personaje
@export var guardia: CharacterBody3D
@export var sistema_sol: SistemaSol

var panel: PanelContainer
var etiqueta_titulo: Label
var etiqueta_salud: Label
var etiqueta_estado: Label
var etiqueta_interaccion: Label
var etiqueta_guardia: Label
var etiqueta_controles: Label

func _ready() -> void:
	panel = PanelContainer.new()
	panel.position = Vector2(18, 18)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.169, 0.176, 0.192, 0.85) # #2B2D31 con transparencia
	estilo.border_color = Color("#D4A373")
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(6)
	estilo.content_margin_left = 14
	estilo.content_margin_right = 14
	estilo.content_margin_top = 10
	estilo.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", estilo)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	etiqueta_titulo = _crear_label("ZOMBIVORS — DEMO JUGABLE (TALLERES 4, 7 Y 8)", 16, Color("#D4A373"))
	etiqueta_salud = _crear_label("", 14, Color("#F2EDE4"))
	etiqueta_estado = _crear_label("", 14, Color("#F2EDE4"))
	etiqueta_interaccion = _crear_label("", 14, Color("#F2EDE4"))
	etiqueta_guardia = _crear_label("", 14, Color("#F2EDE4"))
	etiqueta_controles = _crear_label("Controles: WASD Mover | Shift Correr | Mantener E Consumir caja (+20 HP) | T Destello daño", 12, Color("#D4A373"))

	vbox.add_child(etiqueta_titulo)
	vbox.add_child(etiqueta_salud)
	vbox.add_child(etiqueta_estado)
	vbox.add_child(etiqueta_interaccion)
	vbox.add_child(etiqueta_guardia)
	vbox.add_child(etiqueta_controles)

func _crear_label(texto: String, tamano: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = texto
	lbl.add_theme_font_size_override("font_size", tamano)
	lbl.add_theme_color_override("font_color", color)
	return lbl

func _process(_delta: float) -> void:
	if not personaje:
		return

	# 1. Salud biológica y descomposición
	var salud_actual: float = snappedf(personaje.salud, 0.1)
	var prox_desc: float = snappedf(maxf(0.0, 10.0 - personaje.tiempo_descomposicion), 0.1)
	etiqueta_salud.text = "Salud biológica: " + str(salud_actual) + " / " + str(personaje.salud_maxima) + " HP  (Descomposición en " + str(prox_desc) + " s)"
	if personaje.salud > 60.0:
		etiqueta_salud.add_theme_color_override("font_color", Color("#F2EDE4"))
	elif personaje.salud > 30.0:
		etiqueta_salud.add_theme_color_override("font_color", Color("#D4A373"))
	else:
		etiqueta_salud.add_theme_color_override("font_color", Color("#B22222"))

	# 2. Estado de movimiento, ruido y hora solar
	var nombre_estado: String = Personaje.Estado.keys()[personaje.estado]
	var texto_hora: String = ""
	if sistema_sol and sistema_sol.ciclo:
		texto_hora = "  |  Hora solar: " + str(snappedf(sistema_sol.ciclo.hora, 0.1)) + " h"
	etiqueta_estado.text = "Estado Zombi: " + nombre_estado + "  |  Ruido: " + str(personaje.ruido) + " m" + texto_hora

	# 3. Interacción con alimentos (Taller 8)
	var restantes: int = get_tree().get_nodes_in_group("interactivos").size()
	var nodo_inter: Node = personaje.get_node_or_null("Interactuar")
	if restantes == 0:
		etiqueta_interaccion.text = "Alimentos: ¡3/3 consumidos! Biología estabilizada."
		etiqueta_interaccion.add_theme_color_override("font_color", Color("#577336"))
	elif nodo_inter and nodo_inter.has_method("mas_cercano_global"):
		var cercano: Node = nodo_inter.mas_cercano_global()
		if cercano:
			var dist: float = snappedf(nodo_inter.distancia_a(cercano), 0.01)
			var en_rango: bool = dist <= nodo_inter.alcance
			var prog: float = nodo_inter.progreso if "progreso" in nodo_inter else 0.0
			var porc: int = int(clampf(prog * 100.0, 0.0, 100.0))
			var estado_rango: String = "[EN ALCANCE - Mantén E: " + str(porc) + "%]" if en_rango else "[Acércate a < 1.5 m]"
			etiqueta_interaccion.text = "Alimentos restantes: " + str(restantes) + "  |  Más cercano: " + cercano.name + " a " + str(dist) + " m " + estado_rango
			etiqueta_interaccion.add_theme_color_override("font_color", Color("#D4A373") if en_rango else Color("#F2EDE4"))

	# 4. Estado del guardia centinela (Taller 7 Tarea C)
	if guardia and "estado" in guardia:
		var persiguiendo: bool = guardia.estado == 1
		var dist_g: float = snappedf(guardia.global_position.distance_to(personaje.global_position), 0.1)
		if persiguiendo:
			etiqueta_guardia.text = "Centinela Humano: ¡ALERTA PERSECUCIÓN! (Distancia: " + str(dist_g) + " m)"
			etiqueta_guardia.add_theme_color_override("font_color", Color("#B22222"))
		else:
			etiqueta_guardia.text = "Centinela Humano: Patrullando (Distancia: " + str(dist_g) + " m)"
			etiqueta_guardia.add_theme_color_override("font_color", Color("#F2EDE4"))
