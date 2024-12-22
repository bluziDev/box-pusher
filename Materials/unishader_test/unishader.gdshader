shader_type spatial;

render_mode fog_disabled,depth_prepass_alpha;

uniform float edge_strength : hint_range(0.0, 1.0, 0.01);
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

uniform sampler2D depth_tex : hint_depth_texture;
uniform sampler2D screen_tex : hint_screen_texture;

uniform vec3 edge_color : source_color;
uniform float edge_thickness : hint_range(0.0002, 0.005, 0.00001);
uniform float global_edge_strength : hint_range(0.0, 100.0, 0.1);

//converts nonlinear depth to view-space position
vec3 depth_nl_to_pos_view(vec2 scr_uv, float depth, mat4 pro_mat){

	//float grass_base_depth = texture(depth_tex,scr_uv + vec2(0.0,grass_length));

	vec3 ndc = vec3(scr_uv, depth) * 2.0 - 1.0;
	vec4 view = inverse(pro_mat) * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return view.xyz;
}

vec2 view_to_screen(vec2 view_space,mat4 pro_mat){
	vec4 clip_space = vec4(view_space,0.0,1.0) * pro_mat;
	vec3 ndc = clip_space.xyz / clip_space.w;
	return (ndc.xy * 0.5) + 0.5;
}

/*float prox_ease(float num){
	return
}*/

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
	vec3 screen_color = vec3(edge_strength,1.0,(is_dot + 1.0) / 2.0 * dot_brightness + (-is_dot + 1.0) / 2.0);
	//ALPHA_SCISSOR_THRESHOLD = 1.0;
	//ALPHA = 1.0;vec3 screen_color = texture(screen_tex,SCREEN_UV).rgb;

	float depth = texture(depth_tex,SCREEN_UV).r;
	float linear_depth = depth_nl_to_pos_view(SCREEN_UV,depth,PROJECTION_MATRIX).z;
	float edge_multiplier = screen_color.r;

	vec3 base_col = vec3(screen_color.b);

	//ssao

	float view_ratio = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;

	vec3 col_ao = base_col;

	//edges

	vec2 edge_thickness_xy = vec2(edge_thickness, edge_thickness * view_ratio);

	vec2 uv_north = SCREEN_UV + vec2(0.0,-1.0) * edge_thickness_xy;
	vec2 uv_south = SCREEN_UV + vec2(0.0,1.0) * edge_thickness_xy;
	vec2 uv_west = SCREEN_UV + vec2(-1.0,0.0) * edge_thickness_xy;
	vec2 uv_east = SCREEN_UV + vec2(1.0,0.0) * edge_thickness_xy;

	//get the depth of 4 neighboring pixels
	float depth_north = texture(depth_tex, uv_north).r;
	float depth_south = texture(depth_tex, uv_south).r;
	float depth_west = texture(depth_tex, uv_west).r;
	float depth_east = texture(depth_tex, uv_east).r;

	/*vec3 screen_color_north = texture(screen_tex,uv_north).xyz;
	vec3 screen_color_south = texture(screen_tex,uv_south).xyz;
	vec3 screen_color_west = texture(screen_tex,uv_west).xyz;
	vec3 screen_color_east = texture(screen_tex,uv_east).xyz;*/

	float linear_depth_north = depth_nl_to_pos_view(uv_north,depth_north,PROJECTION_MATRIX).z;
	float linear_depth_south = depth_nl_to_pos_view(uv_south,depth_south,PROJECTION_MATRIX).z;
	float linear_depth_west = depth_nl_to_pos_view(uv_west,depth_west,PROJECTION_MATRIX).z;
	float linear_depth_east = depth_nl_to_pos_view(uv_east,depth_east,PROJECTION_MATRIX).z;

	float to_north = (linear_depth_north - linear_depth);
	float to_south = (linear_depth_south - linear_depth);
	float to_west = (linear_depth_west - linear_depth);
	float to_east = (linear_depth_east - linear_depth);

	float edge_x = abs(to_west + to_east);
	float edge_y = abs(to_north + to_south);
	float edge = (edge_x + edge_y) * global_edge_strength * edge_multiplier;

	vec3 col = mix(col_ao,edge_color,step(1.0,edge));

	//ALBEDO = vec3(screen_color.b);//vec3(-linear_depth * 0.01);//col;
	ALBEDO = col;
	//ALPHA = 1.0;

}

void light() {

	float lighting = ambient_light + (1.0 - ambient_light) * ATTENUATION;
	DIFFUSE_LIGHT += vec3(mix(shadow_brightness,1.0,round(lighting)));
	//DIFFUSE_LIGHT += vec3(1.0,1.0,ceil(max(floor(1.0 - abs(dot(NORMAL, LIGHT))), ATTENUATION)));
}
