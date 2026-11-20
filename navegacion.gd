class_name Navegacion
extends NavigationRegion3D

# Navegación del mapa de oficina: para que los humanos rodeen muros y muebles y
# crucen por las puertas cuando van a otra sala (el cazador, o al ir a ver dónde
# sonó un ruido). Al empezar la partida se calcula la malla de navegación a partir
# de los choques del suelo, los muros y los muebles (capa 1), así que si se mueve
# un mueble en el editor no hay que rehacer nada.

@export var fuentes: Array[NodePath] = [^"../Suelo", ^"../Mapa"]
# Un poco menos que el radio de la cápsula (0.35): las puertas no se cierran.
@export var radio = 0.3
# Igual a navigation/3d/default_cell_size del proyecto (si no, Godot avisa).
@export var celda = 0.1

func _ready():
	var malla = NavigationMesh.new()
	malla.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	malla.geometry_collision_mask = 1
	malla.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	malla.geometry_source_group_name = "navegable"
	malla.cell_size = celda
	malla.cell_height = celda
	malla.agent_radius = radio
	malla.agent_height = 1.7
	malla.agent_max_climb = 0.2
	navigation_mesh = malla
	for f in fuentes:
		get_node(f).add_to_group("navegable")
	# Diferido: los muebles arman su caja de choque en su propio _ready().
	bake_finished.connect(func(): print("navegación lista"))
	bake_navigation_mesh.call_deferred(false)

# El próximo punto al que caminar para llegar a "hacia". Sin malla, en línea recta.
static func siguiente_paso(mundo: World3D, desde: Vector3, hacia: Vector3) -> Vector3:
	var camino = NavigationServer3D.map_get_path(mundo.navigation_map, desde, hacia, true)
	for p in camino:
		if Vector2(p.x - desde.x, p.z - desde.z).length() > 0.25:
			return p
	return hacia
