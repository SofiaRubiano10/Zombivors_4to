extends Node3D

# Un mueble de la oficina. Los modelos son del Furniture Kit de Kenney (CC0,
# https://kenney.nl/assets/furniture-kit), en la carpeta muebles/.
# Al empezar: pone el modelo centrado en este nodo, lo escala, le cambia los
# colores por los grises de nuestra paleta y, si es sólido, le arma una caja de
# choque del tamaño del modelo. Así en la escena solo hay que elegir el modelo,
# moverlo y girarlo.

@export var modelo: PackedScene
# Los modelos de Kenney vienen pequeños: con 2 un escritorio mide 1.5 m.
@export var escala = 2.0
# Sólido: choca con el zombi y el humano, y si es alto (más de 0.9 m) tapa la vista.
@export var solido = true

# Paleta: los muebles son "estructura", así que van en grises cerca del gris
# decadente #2B2D31 (el suelo), un poco más claros para que se distingan.
# Nada de verde, rojo ni amarillo: esos colores son del zombi, del peligro y de
# la comida. Las plantas quedan grises: están muertas.
const COLORES = {
	"wood": Color("#5A5D63"),
	"woodDark": Color("#45484E"),
	"metal": Color("#6E7278"),
	"metalMedium": Color("#55595F"),
	"metalDark": Color("#3A3C41"),
	"carpet": Color("#3F4249"),
	"plant": Color("#34383A"),
}
const GRIS_POR_DEFECTO = Color("#4A4D54")

# Un material por color, compartido por todos los muebles.
static var materiales = {}

func _ready():
	if modelo == null:
		return
	var pieza = modelo.instantiate()
	add_child(pieza)
	pieza.scale = Vector3.ONE * escala
	var mallas = pieza.find_children("*", "MeshInstance3D", true, false)
	for m in mallas:
		pintar(m)
	# Centrar en x y z (los modelos traen el origen en una esquina) y dejarlo en el suelo.
	var caja = caja_local(mallas)
	var centro = caja.get_center()
	pieza.position = Vector3(-centro.x, -caja.position.y, -centro.z)
	if solido:
		armar_choque(caja.size)

func pintar(malla):
	for i in malla.mesh.get_surface_count():
		var original = malla.mesh.surface_get_material(i)
		var nombre = original.resource_name if original else ""
		malla.set_surface_override_material(i, material_para(nombre))

static func material_para(nombre):
	if not materiales.has(nombre):
		var m = StandardMaterial3D.new()
		m.albedo_color = COLORES.get(nombre, GRIS_POR_DEFECTO)
		m.roughness = 0.9
		materiales[nombre] = m
	return materiales[nombre]

# La caja que encierra todas las mallas, medida desde este nodo.
func caja_local(mallas):
	var caja = AABB()
	var primero = true
	var inversa = global_transform.affine_inverse()
	for m in mallas:
		var b = (inversa * m.global_transform) * m.get_aabb()
		caja = b if primero else caja.merge(b)
		primero = false
	return caja

# Capa 1 (mundo), como los muros: el zombi choca y el rayo de visión del humano
# se corta si el mueble es más alto que sus ojos.
func armar_choque(tam):
	var cuerpo = StaticBody3D.new()
	cuerpo.collision_layer = 1
	cuerpo.collision_mask = 0
	var forma = CollisionShape3D.new()
	var caja = BoxShape3D.new()
	caja.size = tam
	forma.shape = caja
	forma.position = Vector3(0, tam.y * 0.5, 0)
	cuerpo.add_child(forma)
	add_child(cuerpo)
