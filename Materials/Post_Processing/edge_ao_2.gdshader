shader_type spatial;

render_mode unshaded, fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture;
uniform sampler2D screen_tex : hint_screen_texture;

uniform vec3 edge_color : source_color;
uniform float edge_thickness : hint_range(0.0002, 0.005, 0.00001);
uniform float edge_strength : hint_range(0.0, 100.0, 0.01);

uniform float ao_spread : hint_range(0.001, 0.01, 0.00001);
uniform float ao_falloff : hint_range(0.0,100.0,0.01);
uniform float ao_strength : hint_range(0.0, 20.0, 0.1);
uniform float ao_ease : hint_range(0.25, 20.0, 0.01);

//converts nonlinear depth to view-space position
vec3 depth_nl_to_pos_view(vec2 scr_uv, float depth, mat4 pro_mat){
	vec3 ndc = vec3(scr_uv, depth) * 2.0 - 1.0;
	vec4 view = inverse(pro_mat) * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return view.xyz;
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {

	//get the depth
	float depth = texture(depth_tex, SCREEN_UV).r;
	vec3 vpos = depth_nl_to_pos_view(SCREEN_UV,depth,PROJECTION_MATRIX);
	
	vec3 screen_color = texture(screen_tex,SCREEN_UV).rgb;
	vec3 base_col = vec3(1.0,1.0,1.0);

	//ssao

	float view_ratio = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;

	/*vec2 ao_spread_xy = vec2(ao_spread, ao_spread * view_ratio);

	//get neighbor uvs for ssao
	vec2 uv_north_ao = SCREEN_UV + vec2(0.0,-1.0) * ao_spread_xy;
	vec2 uv_south_ao = SCREEN_UV + vec2(0.0,1.0) * ao_spread_xy;
	vec2 uv_west_ao = SCREEN_UV + vec2(-1.0,0.0) * ao_spread_xy;
	vec2 uv_east_ao = SCREEN_UV + vec2(1.0,0.0) * ao_spread_xy;

	//get depth of neighbors for ssao
	float depth_north_ao = texture(depth_tex, uv_north_ao).r;
	float depth_south_ao = texture(depth_tex, uv_south_ao).r;
	float depth_west_ao = texture(depth_tex, uv_west_ao).r;
	float depth_east_ao = texture(depth_tex, uv_east_ao).r;

	//use depth to find position in view space
	vec3 vpos_north_ao = depth_nl_to_pos_view(uv_north_ao,depth_north_ao,PROJECTION_MATRIX);
	vec3 vpos_south_ao = depth_nl_to_pos_view(uv_south_ao,depth_south_ao,PROJECTION_MATRIX);
	vec3 vpos_west_ao = depth_nl_to_pos_view(uv_west_ao,depth_west_ao,PROJECTION_MATRIX);
	vec3 vpos_east_ao = depth_nl_to_pos_view(uv_east_ao,depth_east_ao,PROJECTION_MATRIX);

	vec3 to_north = (vpos_north_ao - vpos);
	vec3 to_south = (vpos_south_ao - vpos);
	vec3 to_west = (vpos_west_ao - vpos);
	vec3 to_east = (vpos_east_ao - vpos);

	float occlusion_north = dot(vec3(0.0,0.0,1.0),to_north);// / (1.0 + pow(abs(vpos.z - vpos_north_ao.z),ao_falloff));
	float occlusion_south = dot(vec3(0.0,0.0,1.0),to_south);// / (1.0 + pow(abs(vpos.z - vpos_south_ao.z),ao_falloff));
	float occlusion_west = dot(vec3(0.0,0.0,1.0),to_west);// / (1.0 + pow(abs(vpos.z - vpos_west_ao.z),ao_falloff));
	float occlusion_east = dot(vec3(0.0,0.0,1.0),to_east);// / (1.0 + pow(abs(vpos.z - vpos_east_ao.z),ao_falloff));*/
	
	/*occlusion_north = pow(occlusion_north,ao_ease);
	occlusion_south = pow(occlusion_south,ao_ease);
	occlusion_west = pow(occlusion_west,ao_ease);
	occlusion_east = pow(occlusion_east,ao_ease);*/
	
	/*float ao_falloff_x = pow(1.0 + abs((to_west.z + to_east.z) / 2.0), ao_falloff);
	float ao_falloff_y = pow(1.0 + abs((to_north.z + to_south.z) / 2.0), ao_falloff);
	//float ao_falloff_x = pow(1.0 + abs(vpos.z - (vpos_west_ao.z + vpos_east_ao.z) / 2.0), ao_falloff);
	//float ao_falloff_y = pow(1.0 + abs(vpos.z - (vpos_north_ao.z + vpos_south_ao.z) / 2.0), ao_falloff);
	
	float occlusion_h = occlusion_west + occlusion_east;
	float occlusion_v = occlusion_north + occlusion_south;

	float occlusion_x = max(0.0,pow(occlusion_h * ao_strength,ao_ease) * sign(occlusion_h)) / ao_falloff_x;
	float occlusion_y = max(0.0,pow(occlusion_v * ao_strength,ao_ease) * sign(occlusion_v)) / ao_falloff_y;

	float occlusion = 1.0 + sqrt(pow(occlusion_x,2.0) + pow(occlusion_y,2.0));

	vec3 col_ao = base_col / occlusion;*/
	
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

	//use depth to find position in view space
	vec3 vpos_north = depth_nl_to_pos_view(uv_north,depth_north,PROJECTION_MATRIX);
	vec3 vpos_south = depth_nl_to_pos_view(uv_south,depth_south,PROJECTION_MATRIX);
	vec3 vpos_west = depth_nl_to_pos_view(uv_west,depth_west,PROJECTION_MATRIX);
	vec3 vpos_east = depth_nl_to_pos_view(uv_east,depth_east,PROJECTION_MATRIX);
	
	float to_north_z = (vpos_north.z - vpos.z);
	float to_south_z = (vpos_south.z - vpos.z);
	float to_west_z = (vpos_west.z - vpos.z);
	float to_east_z = (vpos_east.z - vpos.z);
	
	float edge_x = abs(to_west_z + to_east_z);
	float edge_y = abs(to_north_z + to_south_z);
	float edge = (edge_x + edge_y) * edge_strength * screen_color.r;
	
	vec3 col = mix(col_ao,edge_color,step(1.0,edge));
	
	ALBEDO = col;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
