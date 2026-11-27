extends Camera3D

# Cámara diagonal que sigue al zombi.
# Feedback del profesor: proyección ortogonal en vez de perspectiva. En ortogonal
# los objetos no se achican con la distancia y los muros se ven paralelos, como en
# un tablero; size (en la escena, 13 m) es el alto del mundo que cabe en pantalla.
# Clase 6 (sensación de juego): al recibir daño la cámara se sacude 0.15 s. Usa
# h_offset y v_offset (corren la imagen, no la cámara), así no estorba al seguimiento.
# Clase 8: cuando el cazador te persigue la cámara se cierra un poco sobre el zombi
# (size baja hasta un 12 %) y, si está muy cerca, tiembla suave sin parar. Lo marca
# la "amenaza" del cazador (0 a 1); cuando te pierde, la cámara se abre despacio.

@export var objetivo: Node3D
@export var distancia: Vector3 = Vector3(6, 8, 6)
@export var suavizado: float = 2.5
@export var limite_min: Vector2 = Vector2(-14, -14) # x y z mínimas del mapa
@export var limite_max: Vector2 = Vector2(14, 14)   # x y z máximas del mapa
@export var dura_sacudida: float = 0.15
@export var fuerza_sacudida: float = 0.25 # metros que se corre la imagen como mucho

var sacudida: float = 0.0
@export var cierre_amenaza: float = 0.12 # Parte del size que se cierra con amenaza 1
@export var temblor_amenaza: float = 0.05 # Metros de temblor continuo con amenaza 1
var size_base: float = 0.0
var amenaza: float = 0.0

func _ready() -> void:
	top_level = true
	size_base = size
	if objetivo:
		# Se orienta UNA vez en _ready(), mirando al objetivo desde la distancia inicial
		look_at_from_position(objetivo.global_position + distancia, objetivo.global_position)
		# Arranca ya encima del zombi: sin esto se desliza desde el centro del mapa.
		global_position = foco_de(objetivo.global_position) + distancia
		var salud = objetivo.get_node_or_null("Salud")
		if salud != null:
			salud.golpeado.connect(func(_d): sacudir())

func sacudir() -> void:
	sacudida = dura_sacudida

func _physics_process(delta: float) -> void:
	if not objetivo:
		return
	
	# Clamp al foco de seguimiento para que la vista respete los bordes del mapa
	var destino: Vector3 = foco_de(objetivo.global_position) + distancia
	global_position = global_position.lerp(destino, suavizado * delta)
	leer_amenaza()
	size = lerpf(size, size_base * (1.0 - cierre_amenaza * amenaza), 1.0 - exp(-3.0 * delta))
	temblar(delta)

func leer_amenaza() -> void:
	var cazador: Node = get_tree().get_first_node_in_group("cazador")
	amenaza = cazador.amenaza if cazador != null and "amenaza" in cazador else 0.0

# Cada cuadro un desplazamiento al azar que se achica hasta cero en dura_sacudida.
# Con el cazador encima (amenaza > 0.6) queda un temblor pequeño y continuo.
func temblar(delta: float) -> void:
	var continuo: float = temblor_amenaza * clampf((amenaza - 0.6) / 0.4, 0.0, 1.0)
	if sacudida <= 0.0 and continuo <= 0.0:
		h_offset = 0.0
		v_offset = 0.0
		return
	sacudida = maxf(sacudida - delta, 0.0)
	var f: float = maxf(fuerza_sacudida * sacudida / dura_sacudida, continuo)
	h_offset = randf_range(-f, f)
	v_offset = randf_range(-f, f)

func foco_de(punto: Vector3) -> Vector3:
	var foco: Vector3 = punto
	foco.x = clamp(foco.x, limite_min.x, limite_max.x)
	foco.z = clamp(foco.z, limite_min.y, limite_max.y)
	return foco
