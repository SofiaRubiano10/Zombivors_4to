extends Node

# Clase 2 (Sofía y Juan): el olfato del zombi, un radar (Q).
# Al usarlo, durante "duracion" segundos hueles lo que hay a menos de "radio"
# metros aunque haya muros: comida, cazadores (con su alerta) y, siempre, la
# salida. Después hay que esperar la recarga: úsalo para planear, no a ciegas.
# Lo que hueles se ve dos veces: puntos en el radar del HUD (marcas) y
# columnas de olor en el mundo, que se ven a través de las paredes.

signal olfateo(cuantos)

const COLOR_COMIDA = Color(0.49, 0.99, 0.42)
const COLOR_SALIDA = Color(0.36, 0.89, 1.0)
const COLORES_CAZADOR = [Color(1.0, 0.93, 0.75), Color(1.0, 0.82, 0.25), Color(1.0, 0.25, 0.25)]

@export var tecla: String = "olfato"
@export var radio: float = 16.0
@export var duracion: float = 5.0
@export var recarga: float = 10.0

# Segundos que le quedan al olfato encendido (0 = apagado).
var activo: float = 0.0
# Segundos de recarga que faltan (0 = listo).
var reloj: float = 0.0
# Lo que se huele ahora: {"pos": Vector3, "tipo": "comida"/"cazador"/"salida", "alerta": int}
var marcas: Array = []
# Cada nodo olido -> su columna de olor.
var columnas: Dictionary = {}

@onready var pj = get_parent()

func _physics_process(delta: float) -> void:
	reloj = maxf(reloj - delta, 0.0)
	if activo > 0.0:
		activo = maxf(activo - delta, 0.0)
		oler()
		if activo <= 0.0:
			apagar()
	elif Input.is_action_just_pressed(tecla):
		if reloj <= 0.001:
			activar()
		else:
			Sentidos.aviso(get_tree(), "El olfato se recarga: %d s" % ceili(reloj), Color(0.7, 0.7, 0.7))

func activar() -> void:
	activo = duracion
	oler()
	print("olfato: ", marcas.size(), " rastros")
	olfateo.emit(marcas.size())

func apagar() -> void:
	reloj = recarga
	marcas.clear()
	for n in columnas.keys():
		if is_instance_valid(columnas[n]):
			columnas[n].queue_free()
	columnas.clear()

func oler() -> void:
	marcas.clear()
	var olidos := {}
	for n in get_tree().get_nodes_in_group("comida"):
		if cerca(n):
			anotar(n, "comida", 0, COLOR_COMIDA, olidos)
	for n in get_tree().get_nodes_in_group("cazadores"):
		if cerca(n) and not n.get("muerto"):
			var nivel: int = n.nivel_alerta() if n.has_method("nivel_alerta") else 0
			anotar(n, "cazador", nivel, COLORES_CAZADOR[nivel], olidos)
	# La salida se huele siempre: en el radar hace de brújula.
	for n in get_tree().get_nodes_in_group("salida"):
		anotar(n, "salida", 0, COLOR_SALIDA, olidos)
	# Lo que ya no se huele (comido, lejos) pierde su columna.
	for n in columnas.keys():
		if not olidos.has(n):
			if is_instance_valid(columnas[n]):
				columnas[n].queue_free()
			columnas.erase(n)

func cerca(n: Node3D) -> bool:
	return Sentidos.distancia(pj.global_position, n.global_position) <= radio

func anotar(n: Node3D, tipo: String, nivel: int, color: Color, olidos: Dictionary) -> void:
	marcas.append({"pos": n.global_position, "tipo": tipo, "alerta": nivel})
	olidos[n] = true
	if not columnas.has(n) or not is_instance_valid(columnas[n]):
		columnas[n] = crear_columna(n)
	var material: StandardMaterial3D = columnas[n].material_override
	material.albedo_color = Color(color, 0.55)

# Una columna de luz sin sombras que se dibuja encima de todo (no_depth_test).
func crear_columna(n: Node3D) -> MeshInstance3D:
	var malla := CylinderMesh.new()
	malla.top_radius = 0.12
	malla.bottom_radius = 0.12
	malla.height = 3.0
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	material.render_priority = 1
	var columna := MeshInstance3D.new()
	columna.name = "ColumnaOlor"
	columna.mesh = malla
	columna.material_override = material
	columna.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(columna)
	columna.position = Vector3(0, 2.0, 0)
	return columna
