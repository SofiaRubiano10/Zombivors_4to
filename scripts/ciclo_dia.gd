class_name CicloDia
extends Node

# Color bajo de nuestra paleta Zombivors: #2B2D31 -> Color(43/255.0, 45/255.0, 49/255.0)
const NARANJA := Color(0.1686, 0.1765, 0.1922)

@export var hora: float = 8.0 # 8 h según recuadro (elevación 30°)
@export var duracion_dia: float = 48.0 # Segundos reales que dura un ciclo completo de 24 h
@export var pausado: bool = true # Comportamiento fijo en Zona 1 (noche congelada)

func avanzar(dt: float) -> void:
	if not pausado:
		hora = fposmod(hora + (24.0 * dt / duracion_dia), 24.0)

static func elevacion(h: float) -> float:
	# 6 h -> 0°, 12 h -> 90°, 18 h -> 180°
	return (h - 6.0) * 15.0

static func factor_sol(h: float) -> float:
	# Convertimos grados a radianes antes de calcular el seno
	return maxf(0.0, sin(deg_to_rad(elevacion(h))))

static func color_sol(h: float) -> Color:
	return NARANJA.lerp(Color.WHITE, factor_sol(h))
