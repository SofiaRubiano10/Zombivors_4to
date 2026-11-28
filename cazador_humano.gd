extends CharacterBody3D

# Taller 9 - Tarea B (María Sofía): el golpe del humano.
# Nivel 1: el ciclo del ataque ACERCARSE -> AVISO -> GOLPE -> RECARGA.
# Nivel 2: el golpe mira dónde está el jugador y le quita vida a su Salud.
# Nivel 3: el cazador también tiene vida y huye cuando le queda poca.
# Clase 2: empieza VIGILANDO su puesto y gira la cabeza a un lado y a otro.
# Si te ve en su cono, te oye correr o lo avisa otro, empieza a cazarte y grita.
# Clase 2: su ciclo se VE: "!!" naranja en el AVISO (¡apártate!) y "~" gris
# en la RECARGA (se queda quieto: ¡rodéalo y muérdelo por la espalda!).
# Clase 2: la huida termina: tras unos segundos vuelve a vigilar donde esté.

signal devorado

enum Estado { VIGILAR, ACERCARSE, AVISO, GOLPE, RECARGA, HUIR }

const COLOR_CALMA = Color(1.0, 0.93, 0.75)
const COLOR_ALERTA = Color(1.0, 0.25, 0.25)
const COLOR_AVISO = Color(1.0, 0.55, 0.1)
const COLOR_RECARGA = Color(0.62, 0.71, 0.75)
const COLOR_HUIDA = Color(0.45, 0.75, 1.0)

@export var rapidez = 2.0
@export var rango_ataque = 1.5
@export var tiempo_aviso = 0.5
@export var tiempo_recarga = 1.0
@export var alcance_golpe = 1.8
@export var danio = 1
# Retroceso del documento (enchufe empuje del Personaje). 0 = sin retroceso.
@export var fuerza_empuje = 0.0
@export var vida = 100.0
@export var vida_huida = 30.0
# Clase 2: sentidos y vigilancia.
@export var rango_vision = 6.0
@export var angulo_vision = 40.0
# Cuántos grados gira la cabeza a cada lado y cuánto tarda en ir y volver.
@export var giro_vigilancia = 50.0
@export var periodo_vigilancia = 5.0
@export var radio_alerta = 12.0
@export var tiempo_huida = 4.0
# true: caza desde el primer cuadro, como en el Taller 9 (escenas de prueba).
@export var empieza_cazando = false

var estado = Estado.VIGILAR
var reloj = 0.0
var jugador = null
var muerto = false
var giro_base = 0.0
var t_vigilancia = 0.0
# El proyecto no tiene el modelo .glb del taller: si no hay AnimationPlayer, no se anima.
@onready var anim = get_node_or_null("Modelo/AnimationPlayer")
@onready var agente = get_node_or_null("Agente")
@onready var marca = get_node_or_null("Alerta")
@onready var linterna = get_node_or_null("Linterna")

func _ready():
	add_to_group("cazadores")
	jugador = get_tree().get_first_node_in_group("jugador")
	giro_base = rotation.y
	if empieza_cazando:
		estado = Estado.ACERCARSE
	pintar()

func _physics_process(delta):
	if muerto or jugador == null:
		return
	velocity += get_gravity() * delta
	reloj = maxf(reloj - delta, 0.0)
	var nuevo = decidir()
	if nuevo != estado:
		cambiar_a(nuevo)
	match estado:
		Estado.VIGILAR:
			frenar("idle")
			# La cabeza va y viene con un seno: barre su zona.
			t_vigilancia += delta
			var fase = sin(t_vigilancia * TAU / periodo_vigilancia)
			rotation.y = giro_base + deg_to_rad(giro_vigilancia) * fase
		Estado.ACERCARSE:
			ir_a(jugador.global_position)
		Estado.AVISO:
			frenar("interact-right")
		Estado.GOLPE:
			frenar("attack-melee-right")
			golpear()
		Estado.RECARGA:
			frenar("idle")
		Estado.HUIR:
			# Huir es perseguir con la flecha al revés.
			var lejos = global_position - jugador.global_position
			ir_a(global_position + lejos)
	move_and_slide()

# Desde cada estado solo se puede pasar a uno: el ciclo del ataque.
# La huida ya no se decide aquí: la dispara recibir_golpe() al quedar poca vida.
func decidir():
	match estado:
		Estado.VIGILAR:
			if lo_ve() or oye():
				return Estado.ACERCARSE
		Estado.ACERCARSE:
			if distancia() <= rango_ataque:
				return Estado.AVISO
		Estado.AVISO:
			if reloj <= 0.001:
				return Estado.GOLPE
		Estado.GOLPE:
			return Estado.RECARGA
		Estado.RECARGA:
			if reloj <= 0.001:
				return Estado.ACERCARSE
		Estado.HUIR:
			if reloj <= 0.001:
				return Estado.VIGILAR
	return estado

func cambiar_a(nuevo):
	var antes = estado
	estado = nuevo
	print(name, " -> ", Estado.keys()[estado], " cuadro ",
		Engine.get_physics_frames(), " a ",
		snappedf(distancia(), 0.01), " m")
	if estado == Estado.AVISO:
		reloj = tiempo_aviso
	elif estado == Estado.RECARGA:
		reloj = tiempo_recarga
	elif estado == Estado.HUIR:
		reloj = tiempo_huida
	elif estado == Estado.VIGILAR:
		# Vigila desde donde está, mirando hacia donde miraba.
		giro_base = rotation.y
		t_vigilancia = 0.0
	if estado == Estado.ACERCARSE and antes == Estado.VIGILAR:
		gritar()
	pintar()

# El aviso le da tiempo al jugador: el golpe mira DÓNDE ESTÁ AHORA.
func golpear():
	if distancia() > alcance_golpe:
		print(name, " falla a ", snappedf(distancia(), 0.01), " m")
		return
	var salud = jugador.get_node_or_null("Salud")
	if salud != null:
		salud.recibir_golpe(danio)
	if fuerza_empuje > 0.0 and "empuje" in jugador:
		var lejos = jugador.global_position - global_position
		lejos.y = 0.0
		jugador.empuje = lejos.normalized() * fuerza_empuje

# Ve en un cono y con línea de vista (los muros tapan).
func lo_ve():
	return Sentidos.en_cono(self, jugador.global_position, rango_vision, angulo_vision) \
		and Sentidos.linea_de_vista(self, jugador)

# Oído fino de cazador: si corres cerca, te oye.
func oye():
	return "ruido" in jugador and distancia() <= jugador.ruido

func gritar():
	var avisados = Sentidos.alertar(self, jugador.global_position, radio_alerta)
	var texto = "¡El cazador te descubrió!"
	if avisados > 0:
		texto += " Avisó a %d más" % avisados
	Sentidos.aviso(get_tree(), texto, COLOR_ALERTA)

# La llama el grito de otro cazador: deja su puesto y viene a por ti.
func recibir_alerta(_posicion):
	if muerto or estado != Estado.VIGILAR:
		return false
	cambiar_a(Estado.ACERCARSE)
	return true

# 0 tranquilo (vigila o huye), 2 te está cazando. La usan el HUD y el olfato.
func nivel_alerta():
	if estado == Estado.VIGILAR or estado == Estado.HUIR:
		return 0
	return 2

func pintar():
	var texto = ""
	var color = COLOR_CALMA
	match estado:
		Estado.ACERCARSE, Estado.GOLPE:
			texto = "!"
			color = COLOR_ALERTA
		Estado.AVISO:
			texto = "!!"
			color = COLOR_AVISO
		Estado.RECARGA:
			texto = "~"
			color = COLOR_RECARGA
		Estado.HUIR:
			texto = "¡!"
			color = COLOR_HUIDA
	if marca != null:
		marca.text = texto
		marca.modulate = color
	if linterna != null:
		linterna.light_color = color

# Se llama igual que en la diana del Taller 8: ahora la usa el Mordisco del zombi.
func recibir_golpe(cuanto):
	vida -= cuanto
	print(name, " vida ", vida)
	sacudir()
	if vida <= 0.0:
		devorar()
	elif vida <= vida_huida:
		cambiar_a(Estado.HUIR)
	elif estado == Estado.VIGILAR:
		cambiar_a(Estado.ACERCARSE)

# El zombi se lo come: deja de actuar, se encoge y desaparece.
func devorar():
	if muerto:
		return
	muerto = true
	remove_from_group("cazadores")
	devorado.emit()
	print(name, " devorado")
	$CollisionShape3D.set_deferred("disabled", true)
	if linterna != null:
		linterna.visible = false
	if marca != null:
		marca.text = ""
	var t = create_tween()
	t.tween_property(self, "scale", Vector3(1.3, 0.05, 1.3), 0.35)
	t.tween_callback(queue_free)

func sacudir():
	var modelo = get_node_or_null("Modelo")
	if modelo == null:
		return
	var t = create_tween()
	t.tween_property(modelo, "scale", Vector3(1.25, 0.85, 1.25), 0.06)
	t.tween_property(modelo, "scale", Vector3.ONE, 0.12)

# Con NavigationAgent3D rodea los muros; sin mapa, va en línea recta.
func ir_a(destino):
	var siguiente = destino
	if agente != null:
		if agente.target_position.distance_to(destino) > 0.25:
			agente.target_position = destino
		var p = agente.get_next_path_position()
		if Sentidos.distancia(p, global_position) > 0.05:
			siguiente = p
	var hacia = siguiente - global_position
	hacia.y = 0.0
	if hacia.length() < 0.01:
		frenar("idle")
		return
	var dir = hacia.normalized()
	velocity.x = dir.x * rapidez
	velocity.z = dir.z * rapidez
	basis = Basis.looking_at(dir)
	reproducir("walk")

func frenar(animacion):
	velocity.x = 0.0
	velocity.z = 0.0
	reproducir(animacion)

func reproducir(animacion):
	if anim != null and anim.current_animation != animacion:
		anim.play(animacion)

func distancia():
	var p = jugador.global_position
	var o = global_position
	return Vector2(p.x - o.x, p.z - o.z).length()
