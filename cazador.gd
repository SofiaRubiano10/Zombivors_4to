extends "res://humano.gd"

# Clase 4 - Tarea B (María Sofía): el cazador, la presión final.
# Pilar 1, el reloj es tu cuerpo: castiga quedarse esperando.
#  - Empieza escondido. Aparece cuando faltan 30 s para que se cierre la salida,
#    en el extremo del pasillo más lejos del zombi.
#  - Oye TODOS los ruidos del zombi, estén donde estén, y va al último a 2.8 m/s.
#  - Si no hay ruido que seguir, va a vigilar la salida.
#  - Por lo demás es un humano: ve, persigue, golpea, y se le puede morder o aturdir.

signal aparecio

@export var antelacion = 30.0
@export var entradas: Array[Vector3] = [Vector3(-22, 0, 0), Vector3(22, 0, 0)]

var activo = false
var partida = null
var oyo_algo = false
var capa_original = 0

func _ready():
	super()
	add_to_group("cazador")
	capa_original = collision_layer
	esconder()

func esconder():
	visible = false
	collision_layer = 0
	remove_from_group("humanos")
	set_physics_process(false)

func _process(_delta):
	if activo:
		return
	if partida == null:
		partida = get_tree().get_first_node_in_group("partida")
		if partida == null:
			return
	if partida.estado == partida.Estado.JUGANDO and partida.tiempo >= partida.tiempo_tarde - antelacion:
		aparecer()

func aparecer():
	activo = true
	global_position = entrada_lejana()
	visible = true
	collision_layer = capa_original
	add_to_group("humanos")
	set_physics_process(true)
	# Sin ruido que seguir, su "ruta" es la salida: ahí espera.
	var salida = get_tree().get_first_node_in_group("salida")
	puntos = [salida.global_position if salida != null else global_position]
	indice = 0
	if oyo_algo:
		cambiar_a(Estado.SOSPECHA, distancia_a(punto_ruido))
	else:
		cambiar_a(Estado.VOLVER, 0.0)
	print(name, " aparece en ", global_position)
	Sonidos.tocar("alerta")
	aparecio.emit()

func entrada_lejana():
	var mejor = entradas[0]
	for e in entradas:
		if distancia_a_jugador(e) > distancia_a_jugador(mejor):
			mejor = e
	return mejor

func distancia_a_jugador(p):
	return p.distance_to(jugador.global_position)

# Oye en todo el mapa. Antes de aparecer solo apunta dónde fue el último ruido.
func _al_oir(posicion, _radio):
	punto_ruido = posicion
	oyo_algo = true
	if not activo or alerta_en(estado) or estado == Estado.ATURDIDO or estado == Estado.SUJETADO:
		return
	if estado != Estado.SOSPECHA:
		cambiar_a(Estado.SOSPECHA, distancia_a(posicion))
		sospecha.emit()
	else:
		reloj = tiempo_max_buscar
