shader_type spatial;

render_mode unshaded,fog_disabled;

uniform vec3 base_col : source_color;
uniform float frequency : hint_range(0.0, 15.0, 0.01);
uniform float amplitude : hint_range(0.0, 3.0, 0.01);
//uniform sampler2D noise_tex;

void vertex() {
	vec4 world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0));
	world_vertex.y += amplitude;// - sqrt(pow(sin(world_vertex.x * frequency),2.0) * amplitude;
	VERTEX = (inverse(MODEL_MATRIX) * world_vertex).xyz;
}

void fragment() {
	ALBEDO = base_col;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
