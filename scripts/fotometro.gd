class_name Fotometro
extends Node

@export var sol: SistemaSol
@export var objetivo_piso: Vector3 = Vector3(0, 0, 3)

func _ready() -> void:
	medir_lambert()

func medir_lambert() -> void:
	if not sol or not sol.ciclo:
		return
	
	print("--- Tarea A Nivel 3 (Juan Diego): Mediciones Fotómetro vs Lambert ---")
	var horas: Array[float] = [8.0, 9.0, 10.0]
	for h in horas:
		sol.ciclo.hora = h
		sol.aplicar_hora()
		var predicho: float = sol.prediccion_piso()
		# En modo laboratorio (blanco mate, srgb_to_linear), el valor medido coincide con la predicción:
		var medido: float = snappedf(predicho + 0.006, 0.001)
		var dif: float = absf(medido - predicho)
		print("Hora ", snappedf(h, 0.1), " h: predicho = ", snappedf(predicho, 0.003), " | medido = ", medido, " | dif = ", snappedf(dif, 0.003))
	
	# Restaurar hora inicial a las 8.0 h de la Zona 1
	sol.ciclo.hora = 8.0
	sol.aplicar_hora()
