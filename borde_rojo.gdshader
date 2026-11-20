shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;

// Clase 6 - Criterio visual 1 (María Sofía): borde brillante rojo en lo peligroso.
// Va encima del modelo (material_overlay). Fresnel: brilla donde la superficie se
// pone de canto respecto a la cámara, o sea en el contorno. Solo se enciende cerca
// del zombi (a 5 m o menos): avisa del peligro que tienes al lado, no del mapa entero.

uniform vec3 color : source_color = vec3(0.698, 0.133, 0.133);
uniform vec3 jugador = vec3(0.0);
uniform float alcance = 5.0;
uniform float intensidad = 2.5;

varying vec3 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Una base pareja (las trampas son casi planas vistas desde arriba) más el contorno.
	float canto = 0.25 + 0.75 * pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	float cerca = 1.0 - smoothstep(alcance - 1.0, alcance, distance(mundo.xz, jugador.xz));
	ALBEDO = color * canto * intensidad * cerca;
}
