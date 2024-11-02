shader_type spatial;

render_mode fog_disabled;

uniform float edge_strength : hint_range(0.0, 1.0, 0.01);
uniform float ambient_light : hint_range(0.0,1.0,0.01);
uniform float shadow_brightness : hint_range(0.0, 1.0, 0.1);
//uniform sampler2D dot_texture;
uniform float dot_grid_size : hint_range(1.0, 200.0, 0.1);
uniform float dot_radius : hint_range(1.0, 200.0, 0.1);
uniform float dot_brightness : hint_range(0.0, 1.0, 0.1);

void fragment() {
	//float view_ratio = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
	vec4 node_clip = vec4(NODE_POSITION_VIEW.xy,0.0,1.0) * PROJECTION_MATRIX; 
	vec3 node_ndc = node_clip.xyz / node_clip.w;
	vec2 node_screen = (node_ndc.xy * 0.5) + 0.5;
	vec2 sample_pos = (FRAGCOORD.xy - node_screen * VIEWPORT_SIZE);
	float dot_distance = length(sample_pos - round(sample_pos / dot_grid_size) * dot_grid_size);
	float is_dot = sign(dot_radius - dot_distance);
	ALBEDO = vec3(edge_strength,1.0,(is_dot + 1.0) / 2.0 * dot_brightness + (-is_dot + 1.0) / 2.0);
	
}

void light() {

	float lighting = ambient_light + (1.0 - ambient_light) * ATTENUATION;
	DIFFUSE_LIGHT += vec3(1.0,1.0,mix(shadow_brightness,1.0,round(lighting)));
	//DIFFUSE_LIGHT += vec3(1.0,1.0,ceil(max(floor(1.0 - abs(dot(NORMAL, LIGHT))), ATTENUATION)));
}
