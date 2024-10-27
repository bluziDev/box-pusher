shader_type spatial;

render_mode unshaded, fog_disabled;

//uniform sampler2D depth_tex : hint_depth_texture;
uniform sampler2D screen_tex : hint_screen_texture;

uniform vec3 edge_color : source_color;
uniform float edge_thickness : hint_range(0.0002, 0.005, 0.00001);
uniform float edge_strength : hint_range(0.0, 100.0, 0.1);

/*uniform float ao_spread : hint_range(0.001, 0.01, 0.00001);
uniform float ao_falloff : hint_range(0.0,100.0,0.01);
uniform float ao_strength : hint_range(0.0, 20.0, 0.1);
uniform float ao_ease : hint_range(0.25, 20.0, 0.01);*/

//converts nonlinear depth to view-space position
/*vec3 depth_nl_to_pos_view(vec2 scr_uv, float depth, mat4 pro_mat){

	//float grass_base_depth = texture(depth_tex,scr_uv + vec2(0.0,grass_length));

	vec3 ndc = vec3(scr_uv, depth) * 2.0 - 1.0;
	vec4 view = inverse(pro_mat) * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return view.xyz;
}*/

//vec3 get_vpos(vec2 scr_uv, float depth, mat4 pro_mat){

//}

//float grass_sample(vec2 scr_uv){
//	return texture(grass_noise,scr_uv).r;
//}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {

	//get the depth

	//vec2 scr_uv = SCREEN_UV;// + vec2(0.0,grass_length * texture(grass_noise,SCREEN_UV).r);
	//vec2 scr_uv
	//vec2 uv_grass = SCREEN_UV + vec2(0.0,grass_length);

	//float depth = texture(depth_tex, SCREEN_UV).r;
	//vec3 vpos = depth_nl_to_pos_view(SCREEN_UV,depth,PROJECTION_MATRIX);

	/*float depth_grass = texture(depth_tex, uv_grass).r;
	vec3 vpos_grass = depth_nl_to_pos_view(uv_grass,depth_grass,PROJECTION_MATRIX);
	float grass_length_here = texture(grass_noise,vpos_grass.xy).r;
	vpos.z = mix(vpos.z,vpos_grass.z,grass_length_here);*/

	vec3 screen_color = texture(screen_tex,SCREEN_UV).rgb;

	float depth = screen_color.b;
	float edge_multiplier = screen_color.r;

	/*vec3 world_pos = (inverse(VIEW_MATRIX) * vec4(vpos, 1.0)).xyz;
	world_pos += vec3(1.0 + grass_tilt * world_pos.z,1.0,1.0);

	vec2 nearest_grass = round(world_pos.xz / grass_frequency) * grass_frequency;

	vec2 grass_distance = world_pos.xz - nearest_grass;
	vec3 base_col = vec3(1.0 - (abs(grass_distance.x / (grass_frequency.x / 2.0)) + abs(grass_distance.y / (grass_frequency.y / 2.0))));*/
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

	/*vec2 uv_north_grass = uv_north + vec2(0.0,grass_length);
	vec2 uv_south_grass = uv_south + vec2(0.0,grass_length);
	vec2 uv_west_grass = uv_west + vec2(0.0,grass_length);
	vec2 uv_east_grass = uv_east + vec2(0.0,grass_length);*/
	//uv_north = uv_north + vec2(0.0,grass_length * texture(grass_noise,uv_north).r);
	//uv_south = uv_south + vec2(0.0,grass_length * texture(grass_noise,uv_south).r);
	//uv_west = uv_west + vec2(0.0,grass_length * texture(grass_noise,uv_west).r);
	//uv_east = uv_east + vec2(0.0,grass_length * texture(grass_noise,uv_east).r);

	//get the depth of 4 neighboring pixels
	//float depth_north = texture(depth_tex, uv_north).r;
	//float depth_south = texture(depth_tex, uv_south).r;
	//float depth_west = texture(depth_tex, uv_west).r;
	//float depth_east = texture(depth_tex, uv_east).r;

	/*float depth_north_grass = texture(depth_tex, uv_north_grass).r;
	float depth_south_grass = texture(depth_tex, uv_south_grass).r;
	float depth_west_grass = texture(depth_tex, uv_west_grass).r;
	float depth_east_grass = texture(depth_tex, uv_east_grass).r;*/

	//use depth to find position in view space
	//vec3 vpos_north = depth_nl_to_pos_view(uv_north,depth_north,PROJECTION_MATRIX);
	//vec3 vpos_south = depth_nl_to_pos_view(uv_south,depth_south,PROJECTION_MATRIX);
	//vec3 vpos_west = depth_nl_to_pos_view(uv_west,depth_west,PROJECTION_MATRIX);
	//vec3 vpos_east = depth_nl_to_pos_view(uv_east,depth_east,PROJECTION_MATRIX);

	/*vec3 vpos_north_grass = depth_nl_to_pos_view(uv_north_grass,depth_north_grass,PROJECTION_MATRIX);
	vec3 vpos_south_grass = depth_nl_to_pos_view(uv_south_grass,depth_south_grass,PROJECTION_MATRIX);
	vec3 vpos_west_grass = depth_nl_to_pos_view(uv_west_grass,depth_west_grass,PROJECTION_MATRIX);
	vec3 vpos_east_grass = depth_nl_to_pos_view(uv_east_grass,depth_east_grass,PROJECTION_MATRIX);

	float grass_length_north = texture(grass_noise,vpos_north_grass.xy).r;
	float grass_length_south = texture(grass_noise,vpos_south_grass.xy).r;
	float grass_length_west = texture(grass_noise,vpos_west_grass.xy).r;
	float grass_length_east = texture(grass_noise,vpos_east_grass.xy).r;

	vpos_north.z = mix(vpos_north.z,vpos_north_grass.z,grass_length_north);
	vpos_south.z = mix(vpos_south.z,vpos_south_grass.z,grass_length_south);
	vpos_west.z = mix(vpos_west.z,vpos_west_grass.z,grass_length_west);
	vpos_east.z = mix(vpos_east.z,vpos_east_grass.z,grass_length_east);*/

	vec3 screen_color_north = texture(screen_tex,uv_north).xyz;
	vec3 screen_color_south = texture(screen_tex,uv_south).xyz;
	vec3 screen_color_west = texture(screen_tex,uv_west).xyz;
	vec3 screen_color_east = texture(screen_tex,uv_east).xyz;

	float depth_north = screen_color_north.b;
	float depth_south = screen_color_south.b;
	float depth_west = screen_color_west.b;
	float depth_east = screen_color_east.b;

	//depth = (depth + depth_north + depth_south + depth_west + depth_east) / 5.0;

	/*float to_north_z = (vpos_north.z - vpos.z);
	float to_south_z = (vpos_south.z - vpos.z);
	float to_west_z = (vpos_west.z - vpos.z);
	float to_east_z = (vpos_east.z - vpos.z);*/

	float to_north = (depth_north - depth);
	float to_south = (depth_south - depth);
	float to_west = (depth_west - depth);
	float to_east = (depth_east - depth);

	float edge_x = abs(to_west + to_east);
	float edge_y = abs(to_north + to_south);
	float edge = (edge_x + edge_y) * edge_strength * edge_multiplier;

	vec3 col = mix(col_ao,edge_color,step(1.0,edge));

	ALBEDO = col;
	//ALBEDO = vec3(depth);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
