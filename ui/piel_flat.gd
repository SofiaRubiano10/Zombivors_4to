class_name PielFlat
extends RefCounted

# Clase 7: la "piel" de la interfaz con el Flat Design UI Pack (SunGraphica).
# El tema (ui/tema_flat.tres) ya se ve plano con cajas de color. Si en
# res://ui/flat_ui/ están los PNG del pack con los nombres de abajo, al arrancar
# se cambian esas cajas por las texturas del pack (estiradas en 9 partes, así se
# adaptan a cualquier tamaño). Si falta un PNG, esa pieza sigue con el color plano:
# el juego nunca se rompe por un archivo que no está.
# Cómo elegir y nombrar los PNG: ui/flat_ui/LEEME.txt.

const CARPETA = "res://ui/flat_ui/"

# PNG -> [tipo del tema, nombre de la caja, margen 9-slice en px]
const CAJAS = {
	"panel.png": [["PanelContainer", "panel"]],
	"aviso.png": [["PanelAviso", "panel"]],
	"chip.png": [["PanelChip", "panel"]],
	"tecla.png": [["PanelTecla", "panel"]],
	"barra_fondo.png": [["ProgressBar", "background"], ["BarraRastro", "background"]],
	"barra_relleno.png": [["ProgressBar", "fill"], ["BarraEncima", "fill"]],
	"boton.png": [["Button", "normal"]],
	"boton_encima.png": [["Button", "hover"]],
	"boton_pulsado.png": [["Button", "pressed"], ["Button", "hover_pressed"]],
}

# Margen del 9-slice por PNG. Si los bordes del pack se ven estirados, se ajusta aquí.
const MARGENES = {
	"panel.png": 24,
	"aviso.png": 24,
	"chip.png": 12,
	"tecla.png": 10,
	"barra_fondo.png": 8,
	"barra_relleno.png": 8,
	"boton.png": 20,
	"boton_encima.png": 20,
	"boton_pulsado.png": 20,
}

static var aplicada = false
static var en_uso = false

# Se llama una vez; el tema es un recurso compartido, así que vale para todo.
static func aplicar(tema: Theme) -> void:
	if aplicada or tema == null:
		return
	aplicada = true
	for png in CAJAS:
		var textura = cargar(png)
		if textura == null:
			continue
		en_uso = true
		for destino in CAJAS[png]:
			var vieja = tema.get_stylebox(destino[1], destino[0])
			tema.set_stylebox(destino[1], destino[0], caja(textura, MARGENES[png], vieja))
	if en_uso:
		print("interfaz: usando el Flat Design UI Pack (SunGraphica)")

# Conserva los márgenes de contenido de la caja plana para que nada se mueva.
static func caja(textura: Texture2D, margen: int, vieja: StyleBox) -> StyleBoxTexture:
	var s = StyleBoxTexture.new()
	s.texture = textura
	s.texture_margin_left = margen
	s.texture_margin_top = margen
	s.texture_margin_right = margen
	s.texture_margin_bottom = margen
	if vieja != null:
		for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			s.set_content_margin(lado, vieja.get_content_margin(lado))
	return s

static func cargar(archivo: String) -> Texture2D:
	var ruta = CARPETA + archivo
	if not ResourceLoader.exists(ruta):
		return null
	return load(ruta) as Texture2D

# Iconos del HUD: res://ui/flat_ui/iconos/<nombre>.png, o null si no está.
static func icono(nombre: String) -> Texture2D:
	return cargar("iconos/" + nombre + ".png")

# Cambia el color de una caja (plana o de textura) sin tocar la del tema.
static func pintar(caja_base: StyleBox, color: Color) -> StyleBox:
	var copia = caja_base.duplicate()
	if copia is StyleBoxFlat:
		copia.bg_color = color
	elif copia is StyleBoxTexture:
		copia.modulate_color = color
	return copia
