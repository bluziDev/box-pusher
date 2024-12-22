// NOTE: Shader automatically converted from Godot Engine 4.3.stable's StandardMaterial3D.

shader_type spatial;
render_mode unshaded,depth_test_disabled;

uniform vec3 base_color : source_color;

void fragment() {
	ALBEDO = base_color;
	//ALPHA = 1.0;
}
