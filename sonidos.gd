extends Node

# Clase 3 - Tarea B (María Sofía): sonidos del juego.
# Es un autoload (Proyecto > Autoload, nombre "Sonidos"): existe siempre, en
# cualquier escena, y cualquiera lo llama con Sonidos.tocar("nombre").
# Los .wav están en sonidos/ y los genera sonidos/generar_sonidos.py (síntesis
# propia, sin licencias de terceros).

const VOLUMENES = {
	"golpe": -4.0, "mordisco": -2.0, "comer": -6.0, "alerta": -8.0,
	"salida": -6.0, "disparo": -10.0, "trampa": -6.0, "embestida": -6.0,
}
# Varios reproductores: dos sonidos a la vez no se cortan entre sí.
const CANALES = 8

var sonidos = {}
var canales = []
var siguiente = 0

func _ready():
	# Siguen sonando con el juego en pausa (el golpe que te mató, la salida).
	process_mode = Node.PROCESS_MODE_ALWAYS
	for nombre in VOLUMENES:
		sonidos[nombre] = load("res://sonidos/" + nombre + ".wav")
	for i in CANALES:
		var c = AudioStreamPlayer.new()
		add_child(c)
		canales.append(c)

func tocar(nombre):
	if not sonidos.has(nombre):
		push_warning("sonido desconocido: " + nombre)
		return
	var c = canales[siguiente]
	siguiente = (siguiente + 1) % CANALES
	c.stream = sonidos[nombre]
	c.volume_db = VOLUMENES[nombre]
	# Un poco de variación para que repetirse no suene a máquina.
	c.pitch_scale = randf_range(0.93, 1.07)
	c.play()
