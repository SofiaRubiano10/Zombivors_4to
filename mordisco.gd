extends Node

# Clase 4 - Tarea A (Juan Diego): el mordisco sigiloso. Hijo del Personaje.
# Pilar 2, cazador y presa: el humano que te mata también es la mejor comida,
# si lo pillas por la espalda.
#  - Busca un humano a menos de 1.2 m que NO pueda verte (puede_verme() == false).
#  - Mantener E 1.2 s lo devora: devorado() y +35 de vida.
#  - Mientras tanto el humano queda sujetado y se va girando: si te ve, se cancela
#    y el humano ataca. Por eso conviene entrar justo por detrás.
# Medido (C4-04): termina si entras hasta 45° de la espalda exacta; a 50° te ve.

@export var tecla = "interactuar"
@export var alcance = 1.2
@export var tiempo_mordisco = 1.2
@export var curacion = 35

@onready var pj = get_parent()
@onready var interactuar = pj.get_node_or_null("Interactuar")

# De 0 a 1. El HUD lo dibuja en la barra de progreso.
var progreso = 0.0
var objetivo = null

func _physics_process(delta):
	if not Input.is_action_pressed(tecla):
		soltar()
		return
	if objetivo == null:
		# Si ya está comiendo un alimento, la E es de Interactuar.
		if interactuar != null and interactuar.progreso > 0.0:
			return
		objetivo = buscar()
		if objetivo == null:
			return
		print("mordisco: empieza con ", objetivo.name)
	if not is_instance_valid(objetivo):
		soltar()
		return
	# Un poco más de margen para seguir que para empezar: si no, temblaría en el borde.
	if distancia_a(objetivo) > alcance + 0.3:
		print("mordisco: se alejó")
		soltar()
		return
	if objetivo.puede_verme(pj.global_position):
		print("mordisco: te vio, cancelado al ", int(progreso * 100), " %")
		soltar()
		return
	objetivo.sujetar(0.25)
	pj.multiplicador = 0.0
	pj.accion = "attack-melee-right"
	progreso += delta / maxf(0.05, tiempo_mordisco)
	if progreso >= 1.0:
		completar()

func completar():
	var presa = objetivo
	soltar()
	print("mordisco: devoró a ", presa.name)
	Sonidos.tocar("mordisco")
	Onda.crear(presa.get_parent(), presa.global_position)
	var salud = pj.get_node_or_null("Salud")
	if salud != null:
		salud.curar(curacion)
	presa.devorado()

func soltar():
	if objetivo != null:
		pj.multiplicador = 1.0
		pj.accion = ""
	objetivo = null
	progreso = 0.0

# El humano más cercano que esté a tiro y no pueda verme.
func buscar():
	var mejor = null
	for h in get_tree().get_nodes_in_group("humanos"):
		if not h.has_method("puede_verme"):
			continue
		var d = distancia_a(h)
		if d > alcance or h.puede_verme(pj.global_position):
			continue
		if mejor == null or d < distancia_a(mejor):
			mejor = h
	return mejor

func distancia_a(nodo):
	var a = pj.global_position
	var b = nodo.global_position
	return Vector2(a.x - b.x, a.z - b.z).length()
