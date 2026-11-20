extends "res://humano.gd"

# Clase 3 - Tarea B (María Sofía): el tirador.
# Es un humano con los mismos sentidos y el mismo contrato (se le puede morder,
# aturdir, oye el ruido), pero no persigue: al verte se queda quieto, te apunta y
# dispara un proyectil lento cada 2 s. Se le esquiva caminando de lado o se le
# rodea por detrás.

@export var cadencia = 2.0
@export var danio_proyectil = 10
# Lento a propósito: a 6 m tarda 1.2 s en llegar y caminando (2.5 m/s) te apartas.
@export var velocidad_proyectil = 5.0
# Antes del primer disparo, para que el aviso "TE VIO" dé tiempo a reaccionar.
@export var aviso_disparo = 0.6
@export var escena_proyectil: PackedScene = preload("res://proyectil.tscn")

var recarga = 0.0

func _physics_process(delta):
	recarga = maxf(recarga - delta, 0.0)
	super(delta)

func cambiar_a(nuevo, d):
	if alerta_en(nuevo) and not alerta_en(estado):
		recarga = aviso_disparo
	super(nuevo, d)

func perseguir(delta):
	apuntar_y_disparar(delta)

func atacar(delta):
	apuntar_y_disparar(delta)

func apuntar_y_disparar(delta):
	frenar()
	girar_hacia(jugador.global_position, 360.0 * delta)
	if recarga > 0.0:
		return
	recarga = cadencia
	reproducir("attack-melee-right")
	var bala = escena_proyectil.instantiate()
	bala.danio = danio_proyectil
	bala.rapidez = velocidad_proyectil
	get_parent().add_child(bala)
	var boca = global_position + Vector3(0, 1.1, 0)
	var hacia = (jugador.global_position + Vector3(0, 0.9, 0)) - boca
	bala.global_position = boca + hacia.normalized() * 0.6
	bala.direccion = hacia.normalized()
	print(name, " dispara")
