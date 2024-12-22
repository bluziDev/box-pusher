shader_type spatial;

render_mode unshaded,fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = vec3(1.0 - texture(depth_tex,SCREEN_UV).r * 1000.0);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
