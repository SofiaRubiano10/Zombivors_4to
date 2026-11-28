extends NavigationRegion3D

# Clase 2 (Juan): el mapa de navegación de las oficinas.
# Al empezar se "hornea" con los muros y el suelo que cuelgan de este nodo.
# Los cazadores lo usan con su NavigationAgent3D para rodear las paredes.
# Se hornea al arrancar (y no en el editor) para que al mover un muro
# no haya que acordarse de volver a hornear.

func _ready():
	bake_navigation_mesh(false)
