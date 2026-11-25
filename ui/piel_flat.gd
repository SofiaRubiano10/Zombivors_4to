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
	"panel_menu.png": [["PanelMenu", "panel"]],
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
	"panel_menu.png": 32,
	"chip.png": 12,
	"tecla.png": 10,
	"barra_fondo.png": 8,
	"barra_relleno.png": 8,
	"boton.png": 20,
	"boton_encima.png": 20,
	"boton_pulsado.png": 20,
}

const TEMA = preload("res://ui/tema_flat.tres")

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
			tema.set_stylebox(destino[1], destino[0], caja_de_textura(textura, MARGENES[png], vieja))
	if en_uso:
		print("interfaz: usando el Flat Design UI Pack (SunGraphica)")

# Conserva los márgenes de contenido de la caja plana para que nada se mueva.
static func caja_de_textura(textura: Texture2D, margen: int, vieja: StyleBox) -> StyleBoxTexture:
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

# Clase 7: los menús (pausa, mutaciones, fin de run) van en una tarjeta con el
# tema, que entra con un pequeño salto. padre es el CenterContainer del menú.
static func tarjeta(padre: Control) -> PanelContainer:
	aplicar(TEMA)
	padre.theme = TEMA
	var t = PanelContainer.new()
	t.theme_type_variation = &"PanelMenu"
	padre.add_child(t)
	# El tamaño se conoce al cuadro siguiente: el pivote se centra cuando cambia.
	t.resized.connect(func(): t.pivot_offset = t.size * 0.5)
	entrar(t)
	return t

# La entrada de la tarjeta; se puede repetir (la pausa la reusa cada vez).
static func entrar(t: Control) -> void:
	t.modulate.a = 0.0
	t.scale = Vector2.ONE * 0.9
	var tw = t.create_tween().set_parallel()
	tw.tween_property(t, "modulate:a", 1.0, 0.18)
	tw.tween_property(t, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# Iconos del HUD: res://ui/flat_ui/iconos/<nombre>.png, o null si no está.
static func icono(nombre: String) -> Texture2D:
	return cargar("iconos/" + nombre + ".png")

# Cambia el color de una caja (plana o de textura). Usar sobre una copia
# (duplicate()), no sobre la del tema, que la comparte toda la interfaz.
static func colorear(estilo: StyleBox, color: Color) -> void:
	if estilo is StyleBoxFlat:
		estilo.bg_color = color
	elif estilo is StyleBoxTexture:
		estilo.modulate_color = color
