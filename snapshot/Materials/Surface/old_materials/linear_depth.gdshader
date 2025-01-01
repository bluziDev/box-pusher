shader_type spatial;

render_mode fog_disabled,depth_draw_opaque;

uniform float edge_strength : hint_range(0.0, 1.0, 0.01);
uniform float ambient_light : hint_range(0.0,1.0,0.01);
uniform float shadow_brightness : hint_range(0.0, 1.0, 0.1);

/*void vertex() {

}*/

void fragment() {
	ALBEDO = vec3(edge_strength,1.0,1.0);
	//ALPHA_SCISSOR_THRESHOLD = 1.0;
}

void light() {

	float lighting = ambient_light + (1.0 - ambient_light) * ATTENUATION;
	DIFFUSE_LIGHT += vec3(1.0,1.0,mix(shadow_brightness,1.0,round(lighting)));
	//DIFFUSE_LIGHT += vec3(1.0,1.0,ceil(max(floor(1.0 - abs(dot(NORMAL, LIGHT))), ATTENUATION)));
}
