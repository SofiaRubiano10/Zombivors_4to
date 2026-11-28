extends Area3D

# Alimento: al comerlo (mantener E junto a él) cura por la Salud y le avisa a la Partida.
# Es un Area3D en la capa 4 (recogibles): no estorba al caminar.
# Clase 4: tres tipos con los mismos @export. Carne 20 / 1.5 s, Carroña 8 / 0.5 s,
# Cerebro 40 / 1.5 s y detiene la descomposición 20 s.

# Rediseño: cada tipo es una escena con su modelo 3D (alimento_carne.tscn,
# alimento_carrona.tscn, alimento_cerebro.tscn). El HUD lee nombre, icono y color
# para el aviso de "mantén E" y para las casillas de comida.
signal comido(alimento)

@export var nombre: String = "Carne"
@export var icono: Texture2D
# Color del acento en el HUD y de la emisión tenue del modelo.
@export var color: Color = Color(0.831, 0.639, 0.451, 1)
# Cuánto "respira" el modelo (se infla y desinfla): se nota que está ahí para comerse.
@export var latido: float = 0.04
# Emisión tenue (criterio de la noche): parte del color propio que brilla.
@export var brillo: float = 0.35
@export var curacion: int = 20
# Segundos manteniendo E para comerlo. Lo lee Interactuar.
@export var tiempo_comer: float = 1.5
# Segundos que se detiene la descomposición al comerlo. 0 = no la detiene.
@export var pausa_descomposicion: float = 0.0

var t = 0.0
var escala_base = Vector3.ONE
@onready var modelo: Node3D = get_node_or_null("Modelo")

func _ready() -> void:
	add_to_group("interactivos")
	# La Partida cuenta este grupo para saber cuánta comida hay en el mapa.
	add_to_group("alimentos")
	t = randf() * TAU
	if modelo != null:
		escala_base = modelo.scale
		encender(modelo)

# Los materiales del .glb no brillan: se copian con una emisión tenue de su color.
func encender(nodo: Node) -> void:
	if nodo is MeshInstance3D and nodo.mesh != null:
		for i in nodo.mesh.get_surface_count():
			var m = nodo.get_active_material(i)
			if m is StandardMaterial3D:
				m = m.duplicate()
				m.emission_enabled = true
				m.emission = m.albedo_color
				m.emission_energy_multiplier = brillo
				nodo.set_surface_override_material(i, m)
	for hijo in nodo.get_children():
		encender(hijo)

func _process(delta: float) -> void:
	if modelo == null:
		return
	t += delta
	modelo.scale = escala_base * (1.0 + latido * sin(t * 2.4))

func usar() -> void:
	comido.emit(self)
	var pj = get_tree().get_first_node_in_group("jugador")
	var salud = pj.get_node_or_null("Salud") if pj else null
	if salud != null:
		# Mutación "Hambre voraz": la comida cura un 50 % más.
		var factor = 1.5 if Mutaciones.tiene("Hambre voraz") else 1.0
		salud.curar(int(round(curacion * factor)))
		pausar_descomposicion(salud)
	Sonidos.tocar("comer")
	Onda.crear(get_parent(), global_position)
	print("alimento comido: ", nombre, " (+", curacion, " de vida)")
	var partida = get_tree().get_first_node_in_group("partida")
	if partida != null:
		partida.avisar_meta()
	queue_free()

# El factor es de la Salud (contrato): 0 detiene la descomposición, 1 es lo normal.
func pausar_descomposicion(salud) -> void:
	if pausa_descomposicion <= 0.0:
		return
	if not "factor_descomposicion" in salud:
		print(name, ": la Salud no tiene factor_descomposicion, no se detiene")
		return
	salud.factor_descomposicion = 0.0
	print("descomposición detenida ", pausa_descomposicion, " s")
	# El alimento se borra ya: quien restaura el factor es la propia Salud.
	var espera = get_tree().create_timer(pausa_descomposicion, false)
	espera.timeout.connect(salud.set.bind("factor_descomposicion", 1.0))
