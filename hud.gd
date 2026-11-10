extends CanvasLayer

# Taller 10 - Tarea B (María Sofía): el HUD solo muestra; la vida vive en la Salud
# y el tiempo en la Partida.
# La vida llega por señal. El tiempo cambia cada cuadro, por eso se lee en _process.

@onready var texto = $Texto
var vida_actual = 0
var partida = null

func _ready():
	var pj = get_tree().get_first_node_in_group("jugador")
	var salud = pj.get_node("Salud")
	salud.cambio.connect(mostrar)
	mostrar(salud.vida)

func _process(_delta):
	actualizar_texto()

func mostrar(vida):
	vida_actual = vida
	actualizar_texto()
	print("HUD -> ", texto.text)

func actualizar_texto():
	# Se busca aquí: la Partida quizá todavía no existía en _ready().
	if partida == null:
		partida = get_tree().get_first_node_in_group("partida")
	var linea = "Vida: " + str(vida_actual)
	if partida != null:
		linea += "   Tiempo: " + str(ceili(partida.tiempo)) + " s"
	texto.text = linea
