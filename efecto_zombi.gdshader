shader_type spatial;

// Clase 6 - Criterio visual 3 (María Sofía): el material del zombi con efectos.
// Usa la misma textura del modelo de Kenney y le agrega dos números:
// - flash: destello blanco al recibir un golpe (emisión: se ve aunque esté oscuro).
// - desaturar: mezcla cada color con su gris (luminancia): con poca vida el zombi
//   pierde el color y se va pareciendo a un cadáver.

uniform sampler2D textura : source_color, filter_nearest;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float desaturar : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 color = texture(textura, UV).rgb;
	float gris = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(color, vec3(gris) * 0.8, desaturar);
	ALBEDO = mix(color, vec3(1.0), flash);
	EMISSION = vec3(1.0) * flash * 1.5;
	ROUGHNESS = 0.8;
}
