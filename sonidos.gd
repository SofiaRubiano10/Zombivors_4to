extends Node

# Clase 3 - Tarea B (María Sofía): sonidos del juego.
# Es un autoload (Proyecto > Autoload, nombre "Sonidos"): existe siempre, en
# cualquier escena, y cualquiera lo llama con Sonidos.tocar("nombre").
# Los .ogg de sonidos/ son de los paquetes Impact Sounds, Interface Sounds y
# RPG Audio de Kenney (CC0): https://kenney.nl/assets

const VOLUMENES = {
	"golpe": -4.0, "mordisco": -2.0, "comer": -6.0, "alerta": -8.0,
	"salida": -6.0, "disparo": -10.0, "trampa": -6.0, "embestida": -6.0,
}
# Varios reproductores: dos sonidos a la vez no se cortan entre sí.
const CANALES = 8
# Clase 8: el latido del cazador no es un .ogg: se genera con dos golpes graves
# ("lub-dub") que se apagan solos. Se arma una vez y se reutiliza.
var latido_cache: AudioStreamWAV = null

var sonidos = {}
var canales = []
var siguiente = 0

func _ready():
	# Siguen sonando con el juego en pausa (el golpe que te mató, la salida).
	process_mode = Node.PROCESS_MODE_ALWAYS
	for nombre in VOLUMENES:
		sonidos[nombre] = load("res://sonidos/" + nombre + ".ogg")
	for i in CANALES:
		var c = AudioStreamPlayer.new()
		add_child(c)
		canales.append(c)

func latido() -> AudioStreamWAV:
	if latido_cache != null:
		return latido_cache
	var muestras = 22050
	var dur = 0.45
	var datos = PackedByteArray()
	datos.resize(int(muestras * dur) * 2)
	for i in int(muestras * dur):
		var t = float(i) / muestras
		var v = golpe_grave(t, 0.0, 82.0, 0.8) + golpe_grave(t, 0.17, 70.0, 0.6)
		datos.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 30000.0))
	var w = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = muestras
	w.stereo = false
	w.data = datos
	latido_cache = w
	return w

# Un golpe sordo: seno grave que baja un poco de tono y se apaga rápido. Lleva dos
# armónicos y un chasquido al empezar: un parlante de portátil no reproduce los
# graves solos (por debajo de unos 100 Hz casi no suenan) y el latido no se oía.
static func golpe_grave(t: float, inicio: float, hz: float, fuerza: float) -> float:
	var x = t - inicio
	if x < 0.0:
		return 0.0
	var envolvente = minf(x / 0.006, 1.0) * exp(-x * 20.0)
	var fase = TAU * hz * x * (1.0 - 0.6 * x)
	var tono = sin(fase) + 0.6 * sin(2.0 * fase) + 0.35 * sin(3.0 * fase)
	var chasquido = sin(TAU * 900.0 * x) * exp(-x * 400.0) * 0.5
	return (tono / 1.95 + chasquido) * envolvente * fuerza

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
