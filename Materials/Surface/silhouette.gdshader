shader_type spatial;

render_mode unshaded,fog_disabled,depth_test_disabled;//,blend_premul_alpha;

uniform vec3 silhouette_color : source_color;

void fragment() {
	ALBEDO = silhouette_color;
	//ALBEDO = silhouette_color;
	//ALBEDO = screen_color;
	//ALPHA = 0.75;
	//ALPHA = 0.6;
	//DEPTH = 1.0;
	//ALPHA = 1.0;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
