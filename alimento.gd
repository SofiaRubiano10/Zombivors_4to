extends Area3D

# Alimento: al comerlo (mantener E junto a él) cura por la Salud y le avisa a la Partida.
# Es un Area3D en la capa 4 (recogibles): no estorba al caminar.
# Clase 4: tres tipos con los mismos @export. Carne 20 / 1.5 s, Carroña 8 / 0.5 s,
# Cerebro 40 / 1.5 s y detiene la descomposición 20 s.

@export var curacion: int = 20
# Segundos manteniendo E para comerlo. Lo lee Interactuar.
@export var tiempo_comer: float = 1.5
# Segundos que se detiene la descomposición al comerlo. 0 = no la detiene.
@export var pausa_descomposicion: float = 0.0

func _ready() -> void:
	add_to_group("interactivos")
	# La Partida cuenta este grupo para saber cuánta comida hay en el mapa.
	add_to_group("alimentos")

func usar() -> void:
	var pj = get_tree().get_first_node_in_group("jugador")
	var salud = pj.get_node_or_null("Salud") if pj else null
	if salud != null:
		salud.curar(curacion)
		pausar_descomposicion(salud)
	print("alimento comido: ", name, " (+", curacion, " de vida)")
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
