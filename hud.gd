extends CanvasLayer

# Taller 10 - Tarea B (María Sofía): el HUD solo muestra la vida; la vida vive en la Salud.

@onready var texto = $Texto

func _ready():
	var pj = get_tree().get_first_node_in_group("jugador")
	var salud = pj.get_node("Salud")
	salud.cambio.connect(mostrar)
	mostrar(salud.vida)

func mostrar(vida):
	texto.text = "Vida: " + str(vida)
	print("HUD -> ", texto.text)
