class_name SistemaSol
extends Node

@export var sol: DirectionalLight3D
@export var entorno: WorldEnvironment
@export var energia_sol: float = 0.35 # Tenue para noche azul oscura
@export var azimut: float = -30.0 # Grados en Y: dirección hacia donde caen las sombras
@export var ambiente_dia: float = 0.30
@export var ambiente_noche: float = 0.05

@onready var ciclo: CicloDia = $CicloDia

func _ready() -> void:
	aplicar_hora()
	# Prueba de verificación inicial en consola (Nivel 1):
	print("--- Prueba Nivel 1: CicloDia y SistemaSol ---")
	print("Elevación a las 8.0 h: ", CicloDia.elevacion(8.0), "° (Esperado: 30.0°)")
	print("Factor solar: ", CicloDia.factor_sol(8.0), " (Esperado: 0.5)")
	print("Color del sol: ", CicloDia.color_sol(8.0), " (Esperado: 0.5843, 0.5882, 0.5961)")

func _process(delta: float) -> void:
	if not ciclo:
		return
	ciclo.avanzar(delta)
	aplicar_hora()

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
