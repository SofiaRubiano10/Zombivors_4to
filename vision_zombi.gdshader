shader_type canvas_item;

// Clase 8: lo que el zombi alcanza a ver, en pantalla. Fuera de un círculo
// alrededor del zombi todo se oscurece. El círculo se cierra con poca vida y con
// el cazador encima (visión de túnel), y entonces la oscuridad se tiñe de rojo.
// Lo maneja LuzJugador (scripts/luz_jugador.gd); aquí solo se dibuja.

uniform vec2 centro = vec2(0.5, 0.5); // Dónde está el zombi, en UV de la pantalla
uniform float aspecto = 1.7778;        // Ancho / alto, para que sea un círculo
uniform float radio = 0.6;             // Radio claro, en partes del alto de pantalla
uniform float borde = 0.25;            // Ancho del paso de claro a oscuro
uniform float oscuridad = 0.5;         // Opacidad de la zona oscura (0 a 1)
uniform vec4 tinte : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 d = UV - centro;
	d.x *= aspecto;
	float lejos = smoothstep(radio, radio + borde, length(d));
	COLOR = vec4(tinte.rgb, lejos * oscuridad);
}
