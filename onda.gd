class_name Onda
extends RefCounted

# Taller 5 (Programación gráfica) - Tarea A (Juan Diego): las cuentas del agua sucia.
# Son las mismas que hace material_mundo.gdshader, escritas en GDScript para probarlas con print.

static func k(longitud: float) -> float:
	return TAU / longitud

static func w(periodo: float) -> float:
	return TAU / periodo

static func altura(x: float, t: float, amplitud: float, longitud: float, periodo: float) -> float:
	return amplitud * sin(k(longitud) * x - w(periodo) * t)

static func pendiente(x: float, t: float, amplitud: float, longitud: float, periodo: float) -> float:
	return amplitud * k(longitud) * cos(k(longitud) * x - w(periodo) * t)

static func normal(s: float) -> Vector3:
	return Vector3(-s, 1.0, 0.0).normalized()
