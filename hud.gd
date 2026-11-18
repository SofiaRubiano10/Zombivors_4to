extends CanvasLayer

# Taller 10 - Tarea B (María Sofía): el HUD solo muestra; la vida vive en la Salud
# y el tiempo en la Partida.
# La vida llega por señal. El tiempo cambia cada cuadro, por eso se lee en _process.

@onready var texto = $Texto
# Barra de progreso al comer: aparece sobre la cabeza del zombi mientras se
# mantiene E junto a un alimento. Amarillo carne, el color de la comida.
@onready var barra = $BarraComer
var vida_actual = 0
var partida = null
var jugador = null
var interactuar = null

func _ready():
	var pj = get_tree().get_first_node_in_group("jugador")
	jugador = pj
	interactuar = pj.get_node_or_null("Interactuar")
	var salud = pj.get_node("Salud")
	salud.cambio.connect(mostrar)
	mostrar(salud.vida)

func _process(_delta):
	actualizar_texto()
	actualizar_barra()

# El progreso lo lleva Interactuar (de 0 a 1); el HUD solo lo dibuja.
func actualizar_barra():
	var progreso = interactuar.progreso if interactuar != null else 0.0
	var camara = get_viewport().get_camera_3d()
	if progreso <= 0.0 or camara == null:
		barra.visible = false
		return
	barra.visible = true
	barra.value = progreso
	# Un poco por encima de la cabeza (el zombi mide unos 1.8 m).
	var cabeza = jugador.global_position + Vector3(0, 2.3, 0)
	barra.position = camara.unproject_position(cabeza) - barra.size * 0.5

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
		# Cronómetro (sube) y comida que falta para abrir la salida.
		linea += "   Tiempo: " + partida.reloj_texto(partida.tiempo)
		if partida.metas > 0:
			linea += "   Comida: " + str(mini(partida.hechas, partida.metas)) + "/" + str(partida.metas)
		if partida.tarde:
			linea += "   SALIDA CERRADA"
		elif partida.abierta:
			linea += "   SALIDA ABIERTA"
	texto.text = linea
