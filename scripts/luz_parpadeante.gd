class_name LuzParpadeante
extends OmniLight3D

# Paleta oficial Zombivors: Rojo peligro / humanos #B22222
const COLOR_PELIGRO := Color(0.698, 0.133, 0.133, 1.0)

@export var energia_base: float = 1.0
@export var amplitud: float = 0.4
@export var velocidad: float = 8.0

var ruido: FastNoiseLite = FastNoiseLite.new()
var t: float = 0.0

func _ready() -> void:
	ruido.seed = randi()
	ruido.frequency = 0.5
	light_color = COLOR_PELIGRO
	# Prueba de verificación matemática de la función pura:
	print("--- Prueba Nivel 1 (Sofía): LuzParpadeante ---")
	print("Energía mínima con ruido -1.0: ", energia(1.0, 0.4, -1.0), " (Esperado: 0.6)")
	print("Energía media con ruido 0.0: ", energia(1.0, 0.4, 0.0), " (Esperado: 1.0)")
	print("Energía máxima con ruido +1.0: ", energia(1.0, 0.4, 1.0), " (Esperado: 1.4)")

func _process(delta: float) -> void:
	t += delta
	var val_ruido: float = ruido.get_noise_1d(t * velocidad)
	light_energy = energia(energia_base, amplitud, val_ruido)

## Función pura static que calcula la energía de luz modulada con ruido suave
static func energia(base: float, amp: float, valor_ruido: float) -> float:
	return maxf(0.0, base + (amp * valor_ruido))
