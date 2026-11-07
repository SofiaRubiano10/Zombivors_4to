extends CanvasLayer

# Taller 10 - Tarea B (María Sofía): el HUD solo muestra; la vida vive en la Salud
# y el tiempo en la Partida.

@onready var texto = $Texto
var vida = 0

func _ready():
	var pj = get_tree().get_first_node_in_group("jugador")
	var salud = pj.get_node("Salud")
	salud.cambio.connect(mostrar)
	mostrar(salud.vida)

func _process(_delta):
	actualizar()

func mostrar(nueva):
	vida = nueva
	actualizar()
	print("HUD -> Vida: ", vida)

func actualizar():
	var t = "Vida: " + str(vida)
	var partida = get_tree().get_first_node_in_group("partida")
	if partida != null:
		t += "   ·   Tiempo: " + str(ceili(partida.tiempo)) + " s"
		if "metas" in partida and partida.metas > 0:
			t += "   ·   Alimento: " + str(partida.hechas) + "/" + str(partida.metas)
	texto.text = t
