shader_type spatial;

render_mode unshaded, fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture;
uniform sampler2D screen_tex : hint_screen_texture;

uniform vec3 edge_color : source_color;
uniform float edge_thickness : hint_range(0.0002, 0.005, 0.00001);
uniform float edge_strength : hint_range(0.0, 100.0, 0.1);

//converts nonlinear depth to view-space position
vec3 depth_nl_to_pos_view(vec2 scr_uv, float depth, mat4 pro_mat){

	//float grass_base_depth = texture(depth_tex,scr_uv + vec2(0.0,grass_length));

	vec3 ndc = vec3(scr_uv, depth) * 2.0 - 1.0;
	vec4 view = inverse(pro_mat) * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return view.xyz;
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {

	vec3 screen_color = texture(screen_tex,SCREEN_UV).rgb;

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

	vec3 screen_color_north = texture(screen_tex,uv_north).xyz;
	vec3 screen_color_south = texture(screen_tex,uv_south).xyz;
	vec3 screen_color_west = texture(screen_tex,uv_west).xyz;
	vec3 screen_color_east = texture(screen_tex,uv_east).xyz;

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
	float edge = (edge_x + edge_y) * edge_strength * edge_multiplier;

	vec3 col = mix(col_ao,edge_color,step(1.0,edge));

	ALBEDO = col;
}
