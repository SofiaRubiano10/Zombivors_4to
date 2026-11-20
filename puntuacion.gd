class_name Puntuacion
extends Node

# Clase 5 - Tarea B (María Sofía): puntuación y récord guardado.
# Pilar 4, una partida más. Contrato: grupo "puntuacion", sumar(puntos, motivo),
# total y record.
#  - +100 por alimento comido y +250 por humano devorado.
#  - Al ganar un piso: +10 por cada segundo que sobre antes del cierre de la salida,
#    y todo lo del piso x1.5 si no recibiste ni un golpe (la descomposición no cuenta).
#  - El récord se guarda en disco (ConfigFile en user://): sobrevive a cerrar el juego.
# total y devorados son static: se acumulan durante toda la run.

# static para que las pruebas puedan usar otro archivo y no pisar el récord real.
static var archivo = "user://zombivors.cfg"

static var total = 0
static var devorados = 0
static var record = -1

# Lo ganado en este piso; se suma al total al terminarlo.
var puntos_zona = 0
var sin_danio = true
var nuevo_record = false
var partida = null

func _ready():
	add_to_group("puntuacion")
	if record < 0:
		record = leer_record()
	call_deferred("conectar")

func conectar():
	partida = get_tree().get_first_node_in_group("partida")
	if partida != null:
		# Piso 1 = run nueva: el puntaje vuelve a cero.
		if partida.zona == 1:
			total = 0
			devorados = 0
		partida.meta.connect(_al_comer)
		partida.terminada.connect(_al_terminar)
	var pj = get_tree().get_first_node_in_group("jugador")
	var salud = pj.get_node_or_null("Salud") if pj != null else null
	if salud != null:
		salud.golpeado.connect(func(_d): sin_danio = false)
	for h in get_tree().get_nodes_in_group("humanos"):
		conectar_humano(h)
	for h in get_tree().get_nodes_in_group("cazador"):
		conectar_humano(h)

func conectar_humano(h):
	if not h.devorado_signal.is_connected(_al_devorar):
		h.devorado_signal.connect(_al_devorar)

func sumar(puntos, motivo):
	puntos_zona += puntos
	print("+", puntos, " (", motivo, ") · piso ", puntos_zona, " · run ", total + puntos_zona)

# La Partida emite meta(hechas, total) al empezar (hechas = 0) y con cada alimento.
func _al_comer(hechas, _metas):
	if hechas > 0:
		sumar(100, "alimento")

func _al_devorar():
	devorados += 1
	sumar(250, "humano devorado")

func _al_terminar(estado, _motivo):
	if estado == partida.Estado.GANO:
		var sobra = maxf(0.0, partida.tiempo_tarde - partida.tiempo)
		sumar(int(sobra) * 10, str(int(sobra)) + " s de sobra")
		if sin_danio:
			puntos_zona = int(round(puntos_zona * 1.5))
			print("x1.5 sin daño · piso ", puntos_zona)
	total += puntos_zona
	puntos_zona = 0
	if fin_de_run(estado) and total > record:
		record = total
		nuevo_record = true
		guardar_record()
		print("NUEVO RÉCORD ", record)

func fin_de_run(estado):
	return estado != partida.Estado.GANO or partida.ultima_zona()

# Lo que se ve en el HUD durante la run.
func en_curso():
	return total + puntos_zona

static func leer_record():
	var cfg = ConfigFile.new()
	if cfg.load(archivo) != OK:
		return 0
	return int(cfg.get_value("record", "puntos", 0))

static func guardar_record():
	var cfg = ConfigFile.new()
	cfg.load(archivo)
	cfg.set_value("record", "puntos", record)
	cfg.save(archivo)
