// Bloques de piedra (o tablas de madera, o baldosas) dibujados con matemáticas,
// sin imágenes. El patrón se calcula con la posición en el mundo, así que todas
// las paredes encajan solas sin necesidad de coordenadas de textura.
// Cada hilada tiene bloques de largo distinto, como la cantería del Panóptico.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform vec3 color_base : source_color = vec3(0.64, 0.51, 0.37);
uniform vec3 color_junta : source_color = vec3(0.36, 0.30, 0.24);
uniform vec2 tam_bloque = vec2(0.9, 0.42);   // Largo medio y alto de cada bloque, en metros.
uniform float junta = 0.035;                  // Grosor de la junta, en metros.
uniform float variacion = 0.18;               // Cuánto cambia el tono de un bloque a otro.
uniform float irregular = 0.45;               // Cuánto varía el largo de los bloques.
uniform float grano = 0.06;                   // Textura granulada de la superficie.
uniform float rugosidad = 0.95;

varying vec3 pos_mundo;
varying vec3 normal_mundo;

void vertex() {
	pos_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normal_mundo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(azar(i), azar(i + vec2(1.0, 0.0)), f.x), mix(azar(i + vec2(0.0, 1.0)), azar(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec3 n = abs(normal_mundo);
	// En paredes: horizontal a lo largo del muro y vertical en y. En pisos: x y z.
	vec2 uv;
	if (n.y > 0.7) {
		uv = pos_mundo.xz;
	} else if (n.x > n.z) {
		uv = vec2(pos_mundo.z, pos_mundo.y);
	} else {
		uv = vec2(pos_mundo.x, pos_mundo.y);
	}
	float fila = floor(uv.y / tam_bloque.y);
	// Cada hilada tiene su propio largo de bloque y su propio desplazamiento.
	float largo = tam_bloque.x * (1.0 + (azar(vec2(fila, 3.7)) - 0.5) * irregular * 2.0);
	float x = uv.x / largo + azar(vec2(fila, 9.1));
	float col = floor(x);
	vec2 f = vec2(fract(x) * largo, fract(uv.y / tam_bloque.y) * tam_bloque.y);
	float borde = min(min(f.x, largo - f.x), min(f.y, tam_bloque.y - f.y));
	float es_junta = 1.0 - smoothstep(junta * 0.4, junta, borde);
	float tono = (azar(vec2(col, fila)) - 0.5) * variacion;
	float textura = (ruido(uv * 9.0) - 0.5) * grano + (ruido(uv * 2.3 + col) - 0.5) * grano;
	vec3 bloque = color_base * (1.0 + tono + textura);
	ALBEDO = mix(bloque, color_junta, es_junta);
	ROUGHNESS = rugosidad;
}
