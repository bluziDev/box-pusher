shader_type spatial;

render_mode fog_disabled;//,depth_prepass_alpha;

uniform float ambient_light : hint_range(0.0,1.0,0.01);
uniform float shadow_brightness : hint_range(0.0, 1.0, 0.1);
//uniform sampler2D dot_texture;
uniform float dot_grid_size : hint_range(1.0, 200.0, 0.1);
uniform float dot_radius : hint_range(1.0, 200.0, 0.1);
uniform float dot_brightness : hint_range(0.0, 1.0, 0.1);

uniform vec3 player_pos_world;
uniform float prox_size : hint_range(1.0, 10.0, 0.1);
uniform float prox_light : hint_range(0.0,1.0,0.1);
uniform float prox_range : hint_range(0.0, 1000.0, 0.1);
uniform float atten_amp : hint_range(0.0, 10.0, 0.1);
uniform float atten_freq : hint_range(0.0, 1.0, 0.1);
uniform float atten_shift : hint_range(0.0, 1.0, 0.1);

vec2 view_to_screen(vec2 view_space,mat4 pro_mat){
	vec4 clip_space = vec4(view_space,0.0,1.0) * pro_mat;
	vec3 ndc = clip_space.xyz / clip_space.w;
	return (ndc.xy * 0.5) + 0.5;
}

void fragment() {
	//float view_ratio = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
	vec2 player_view = (vec4(player_pos_world * vec3(1.0,-1.0,1.0),1.0) * VIEW_MATRIX).xy;
	vec2 player_screen = view_to_screen(player_view * vec2(1.0,-1.0),PROJECTION_MATRIX);
	vec2 node_screen = view_to_screen(NODE_POSITION_VIEW.xy,PROJECTION_MATRIX);
	vec2 sample_pos = FRAGCOORD.xy - node_screen * VIEWPORT_SIZE;
	vec2 dot_pos = round(sample_pos / dot_grid_size) * dot_grid_size;
	float player_dis = length(dot_pos - player_screen * VIEWPORT_SIZE + node_screen * VIEWPORT_SIZE);
	float size_mult = max(1.0,prox_size - 1.0 / prox_range * player_dis);
	float dot_distance = length(sample_pos - dot_pos);
	float is_dot = sign(size_mult * dot_radius - dot_distance);
	ALBEDO = vec3((is_dot + 1.0) / 2.0 * dot_brightness + (-is_dot + 1.0) / 2.0);
	//ALPHA = 1.0;
}

void light() {

	float lighting = ambient_light + (1.0 - ambient_light) * ATTENUATION;
	DIFFUSE_LIGHT += vec3(mix(shadow_brightness,1.0,round(lighting)));
	//DIFFUSE_LIGHT += vec3(1.0,1.0,ceil(max(floor(1.0 - abs(dot(NORMAL, LIGHT))), ATTENUATION)));
}
