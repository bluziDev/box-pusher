// NOTE: Shader automatically converted from Godot Engine 4.3.stable's StandardMaterial3D.

shader_type spatial;
render_mode depth_draw_opaque;

uniform vec4 albedo : source_color;

void fragment() {
	ALBEDO = albedo.rgb;
}
