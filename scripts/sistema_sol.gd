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


func _process(delta: float) -> void:
	if not ciclo:
		return
	ciclo.avanzar(delta)
	aplicar_hora()

	
	var es_noche: bool = CicloDia.factor_sol(ciclo.hora) <= 0.0
	if es_noche != era_noche:
		era_noche = es_noche
		cambio_noche.emit(es_noche)


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
