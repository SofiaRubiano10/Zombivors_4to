class_name SistemaSol
extends Node

signal cambio_noche(es_noche: bool)

@export var sol: DirectionalLight3D
@export var entorno: WorldEnvironment
@export var energia_sol: float = 0.35 # Tenue para noche azul oscura
@export var azimut: float = -30.0 # Grados en Y: dirección hacia donde caen las sombras
@export var ambiente_dia: float = 0.30
@export var ambiente_noche: float = 0.05

var era_noche: bool = false
@onready var ciclo: CicloDia = $CicloDia

func _ready() -> void:
	aplicar_hora()
	if ciclo:
		era_noche = CicloDia.factor_sol(ciclo.hora) <= 0.0
	
	# Verificación de detección de flanco único para el Nivel 2:
	print("--- Prueba Nivel 2 (Juan Diego): Señal cambio_noche con Detección de Flanco ---")
	print("Estado inicial a las 8.0 h: es_noche = ", era_noche, " (Sol activo a 30°)")
	_probar_transicion_noche()

func _process(delta: float) -> void:
	if not ciclo:
		return
	ciclo.avanzar(delta)
	aplicar_hora()
	
	var es_noche: bool = CicloDia.factor_sol(ciclo.hora) <= 0.0
	if es_noche != era_noche:
		era_noche = es_noche
		cambio_noche.emit(es_noche)
		print("Aviso único de flanco emitido: cambio_noche(", es_noche, ") a las ", snappedf(ciclo.hora, 0.1), " h")

func aplicar_hora() -> void:
	if not ciclo:
		return
	var h: float = ciclo.hora
	var f: float = CicloDia.factor_sol(h)
	
	if sol:
		# Rotación X negativa para que la luz apunte desde arriba hacia el suelo
		sol.rotation_degrees = Vector3(-CicloDia.elevacion(h), azimut, 0.0)
		sol.light_energy = energia_sol * f
		sol.light_color = CicloDia.color_sol(h)
	
	if entorno and entorno.environment:
		entorno.environment.ambient_light_energy = lerpf(ambiente_noche, ambiente_dia, f)

## Prueba matemática de simulación del cruce de las 18:00 h y las 06:00 h
func _probar_transicion_noche() -> void:
	var horas_prueba: Array[float] = [17.5, 18.0, 18.5, 5.5, 6.0, 6.5]
	var estado_simulado: bool = era_noche
	for hp in horas_prueba:
		var es_noche_sim: bool = CicloDia.factor_sol(hp) <= 0.0
		if es_noche_sim != estado_simulado:
			estado_simulado = es_noche_sim
			print(" -> Cruce detectado a las ", hp, " h: emitido cambio_noche(", es_noche_sim, ") [1 solo aviso]")
