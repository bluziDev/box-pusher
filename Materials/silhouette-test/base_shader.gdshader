shader_type spatial;
//render_mode unshaded;

uniform vec3 base_color : source_color;

void fragment() {
	ALBEDO = base_color;
	ALPHA = 1.0;
}
