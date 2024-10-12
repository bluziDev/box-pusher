shader_type spatial;

render_mode unshaded, fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture;
uniform sampler2D screen_tex : hint_screen_texture;
uniform float plane_thresh : hint_range(0.0, 10.0, 0.01);
uniform float normal_thresh : hint_range(0.0, 2.0, 0.001);
uniform vec3 edge_color : source_color;
uniform float edge_thickness : hint_range(0.0002, 0.005, 0.00001);
//uniform float edge_thickness_norm : hint_range(0.0002, 0.005, 0.00001);
uniform float ao_spread : hint_range(0.001, 0.01, 0.00001);
uniform vec3 occlusion_color : source_color;
uniform float ao_falloff : hint_range(0.0,10.0,0.01);
uniform float ao_strength : hint_range(0.0, 10.0, 0.1);

float dis_ray_plane(vec3 ray_origin, vec3 ray_dir, vec3 plane_point, vec3 plane_normal) {
	// Compute the denominator of the intersection formula
	float denom = dot(ray_dir, plane_normal);

	// Calculate the intersection distance along the ray
	float t = dot(plane_point - ray_origin, plane_normal) / denom;

	//if the ray and plane are parallel, treat it like a depth comparison
	//otherwise, return the distance to the plane
	float denom_is_zero = step(abs(denom),0.000001);
	return (1.0 - denom_is_zero) * abs(t) + denom_is_zero * abs(ray_origin.z - plane_point.z);
}

vec3[2] snake_unpair(vec3 scaled_index,float grid_size){
	vec3 snake_index = round(scaled_index * (pow(grid_size,2.0) - 1.0));
	vec3 snake_div = snake_index / grid_size;

	vec3 grid_y = trunc(snake_div);
	vec3 y_is_odd = mod(grid_y,2.0);

	float max_grid_coord = grid_size - 1.0;
	vec3 grid_x = y_is_odd * max_grid_coord + round(fract(snake_div) * grid_size) * (y_is_odd * -2.0 + 1.0);

	//return vec3[2](grid_y / max_grid_coord,grid_x / max_grid_coord);
	return vec3[2](grid_x / max_grid_coord,grid_y / max_grid_coord);
}

//converts nonlinear depth to view-space position
vec3 depth_nl_to_pos_view(vec2 scr_uv, float depth, mat4 pro_mat){
	vec3 ndc = vec3(scr_uv, depth) * 2.0 - 1.0;
	vec4 view = inverse(pro_mat) * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return view.xyz;
}

/*float dis_to_plane(vec3 point,vec3 plane_normal,float plane_d){
	float dis = abs(dot(plane_normal, point) + plane_d);
	return dis;
}*/

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {

	//get the depth
	float depth = texture(depth_tex, SCREEN_UV).r;
	vec3 vpos = depth_nl_to_pos_view(SCREEN_UV,depth,PROJECTION_MATRIX);
	//float linear_depth = -view_pos.z;

	vec3 screen_color = texture(screen_tex,SCREEN_UV).rgb;

	//decode normal
	float grid_size = 9.0;

	vec3 unpaired[2] = snake_unpair(screen_color,grid_size);

	vec3 norm = normalize(unpaired[0] * 2.0 - 1.0);
	vec3 base_col = unpaired[1];

	//ssao

	float view_ratio = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;

	vec2 ao_spread_xy = vec2(ao_spread, ao_spread * view_ratio);

	//get neighbor uvs for ssao
	vec2 uv_north_ao = SCREEN_UV + vec2(0.0,-1.0) * ao_spread_xy;
	vec2 uv_south_ao = SCREEN_UV + vec2(0.0,1.0) * ao_spread_xy;
	vec2 uv_west_ao = SCREEN_UV + vec2(-1.0,0.0) * ao_spread_xy;
	vec2 uv_east_ao = SCREEN_UV + vec2(1.0,0.0) * ao_spread_xy;

	/*vec3 col_north_ao = texture(screen_tex,uv_north_ao).rgb;
	vec3 col_south_ao = texture(screen_tex,uv_south_ao).rgb;
	vec3 col_west_ao = texture(screen_tex,uv_west_ao).rgb;
	vec3 col_east_ao = texture(screen_tex,uv_east_ao).rgb;
	vec3 unpaired_north_ao[2] = snake_unpair(col_north_ao,grid_size);
	vec3 unpaired_south_ao[2] = snake_unpair(col_south_ao,grid_size);
	vec3 unpaired_west_ao[2] = snake_unpair(col_west_ao,grid_size);
	vec3 unpaired_east_ao[2] = snake_unpair(col_east_ao,grid_size);
	vec3 norm_north_ao = normalize(unpaired_north_ao[0] * 2.0 - 1.0);
	vec3 norm_south_ao = normalize(unpaired_south_ao[0] * 2.0 - 1.0);
	vec3 norm_west_ao = normalize(unpaired_west_ao[0] * 2.0 - 1.0);
	vec3 norm_east_ao = normalize(unpaired_east_ao[0] * 2.0 - 1.0);*/

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

	vec3 to_north = normalize(vpos_north_ao - vpos);
	vec3 to_south = normalize(vpos_south_ao - vpos);
	vec3 to_west = normalize(vpos_west_ao - vpos);
	vec3 to_east = normalize(vpos_east_ao - vpos);

	float occlusion_north = dot(norm.yz,to_north.yz) / (1.0 + pow(abs(vpos.z - vpos_north_ao.z),ao_falloff));
	float occlusion_south = dot(norm.yz,to_south.yz) / (1.0 + pow(abs(vpos.z - vpos_south_ao.z),ao_falloff));
	float occlusion_west = dot(norm.xz,to_west.xz) / (1.0 + pow(abs(vpos.z - vpos_west_ao.z),ao_falloff));
	float occlusion_east = dot(norm.xz,to_east.xz) / (1.0 + pow(abs(vpos.z - vpos_east_ao.z),ao_falloff));

	/*float occlusion_north = max(0.0,norm.y - norm_north_ao.y) / (1.0 + abs(vpos.z - vpos_north_ao.z) * ao_falloff);
	float occlusion_south = max(0.0,-norm.y + norm_south_ao.y) / (1.0 + abs(vpos.z - vpos_south_ao.z) * ao_falloff);
	float occlusion_west = max(0.0,-norm.x + norm_west_ao.x) / (1.0 + abs(vpos.z - vpos_west_ao.z) * ao_falloff);
	float occlusion_east = max(0.0,norm.x - norm_east_ao.x) / (1.0 + abs(vpos.z - vpos_east_ao.z) * ao_falloff);*/

	float occlusion_x = max(0.0,occlusion_west + occlusion_east);
	float occlusion_y = max(0.0,occlusion_north + occlusion_south);

	float occlusion = 1.0 + sqrt(pow(occlusion_x,2.0) + pow(occlusion_y,2.0)) * ao_strength;

	vec3 col_ao = base_col / occlusion;

	/*float occlusion_north = max(0.0,vpos_north_ao.z - vpos.z);
	float occlusion_south = max(0.0,vpos_south_ao.z - vpos.z);
	float occlusion_west = max(0.0,vpos_west_ao.z - vpos.z);
	float occlusion_east = max(0.0,vpos_east_ao.z - vpos.z);

	float range_x = max(vpos.z,max(vpos_west_ao.z,vpos_east_ao.z)) - min(vpos.z,min(vpos_west_ao.z,vpos_east_ao.z));
	float range_y = max(vpos.z,max(vpos_north_ao.z,vpos_south_ao.z)) - min(vpos.z,min(vpos_north_ao.z,vpos_south_ao.z));

	float occlusion_x = ao_strength * (occlusion_west + occlusion_east) / 2.0 / (1.0 + range_x * ao_falloff);//(dot(to_west,to_east) + 1.0) / 2.0;
	float occlusion_y = ao_strength * (occlusion_north + occlusion_south) / 2.0 / (1.0 + range_y * ao_falloff);//(dot(to_north,to_south) + 1.0) / 2.0;

	float occlusion = 1.0 + sqrt(pow(occlusion_x,2.0) + pow(occlusion_y,2.0));

	vec3 col_ao = base_col / occlusion;*/

	//vec3 col_ao = base_col;

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

	//find the depth between each neighbor's vpos and the intersection between
	//a ray along the z axis and the normal plane

	float dif_dep_north = dis_ray_plane(vpos_north,vec3(0.0,0.0,1.0),vpos,norm);
	float dif_dep_south = dis_ray_plane(vpos_south,vec3(0.0,0.0,1.0),vpos,norm);
	float dif_dep_west = dis_ray_plane(vpos_west,vec3(0.0,0.0,1.0),vpos,norm);
	float dif_dep_east = dis_ray_plane(vpos_east,vec3(0.0,0.0,1.0),vpos,norm);

	//calculate the ratio between the z difference and the x/y difference

	float ratio_north = dif_dep_north / (1.0 + abs(vpos.y - vpos_north.y));
	float ratio_south = dif_dep_south / (1.0 + abs(vpos.y - vpos_south.y));
	float ratio_west = dif_dep_west / (1.0 + abs(vpos.x - vpos_west.x));
	float ratio_east = dif_dep_east / (1.0 + abs(vpos.x - vpos_east.x));

	//decode normals of neighbors from screen texture

	vec3 col_north = texture(screen_tex,uv_north).rgb;
	vec3 col_south = texture(screen_tex,uv_south).rgb;
	vec3 col_west = texture(screen_tex,uv_west).rgb;
	vec3 col_east = texture(screen_tex,uv_east).rgb;
	vec3 unpaired_north[2] = snake_unpair(col_north,grid_size);
	vec3 unpaired_south[2] = snake_unpair(col_south,grid_size);
	vec3 unpaired_west[2] = snake_unpair(col_west,grid_size);
	vec3 unpaired_east[2] = snake_unpair(col_east,grid_size);
	vec3 norm_north = normalize(unpaired_north[0] * 2.0 - 1.0);
	vec3 norm_south = normalize(unpaired_south[0] * 2.0 - 1.0);
	vec3 norm_west = normalize(unpaired_west[0] * 2.0 - 1.0);
	vec3 norm_east = normalize(unpaired_east[0] * 2.0 - 1.0);

	float dis_north_normal = (dot(norm,norm_north) + 1.0) / 2.0;
	float dis_south_normal = (dot(norm,norm_south) + 1.0) / 2.0;
	float dis_west_normal = (dot(norm,norm_west) + 1.0) / 2.0;
	float dis_east_normal = (dot(norm,norm_east) + 1.0) / 2.0;

	vec3 col = mix(col_ao,edge_color,clamp(step(plane_thresh,ratio_north)
										   + step(plane_thresh,ratio_south)
										   + step(plane_thresh,ratio_west)
										   + step(plane_thresh,ratio_east)
										   + step(dis_north_normal,normal_thresh)
										   + step(dis_south_normal,normal_thresh)
										   + step(dis_west_normal,normal_thresh)
										   + step(dis_east_normal,normal_thresh),0.0,1.0));

	//ALBEDO = norm;
	//ALBEDO = (norm + 1.0) / 2.0;
	//ALBEDO = vec3(1.0 + vpos.z * 0.05);
	ALBEDO = col;
	//ALBEDO = col_ao;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
