shader_type spatial;

render_mode unshaded, fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture;
uniform sampler2D screen_tex : hint_screen_texture;
uniform float plane_thresh : hint_range(0.0, 100.0, 0.1);
uniform float normal_thresh : hint_range(0.0, 100.0, 0.1);
uniform vec3 edge_color : source_color;
uniform float edge_thickness_plane : hint_range(0.0002, 0.005, 0.00001);
uniform float edge_thickness_norm : hint_range(0.0002, 0.005, 0.00001);
uniform float ao_spread : hint_range(0.001, 0.01, 0.00001);
uniform vec3 occlusion_color : source_color;

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
	//vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	//vec4 view = inverse(PROJECTION_MATRIX) * vec4(ndc, 1.0);
	//view.xyz /= view.w;
	vec3 vpos = depth_nl_to_pos_view(SCREEN_UV,depth,PROJECTION_MATRIX);
	//float linear_depth = -view_pos.z;

	vec3 screen_color = texture(screen_tex,SCREEN_UV).rgb;

	//decode normal
	float grid_size = 8.0;

	vec3 unpaired[2] = snake_unpair(screen_color,grid_size);

	vec3 norm = normalize(unpaired[0] * 2.0 - 1.0);
	vec3 base_col = unpaired[1];

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
	vec3 vpos_north = depth_nl_to_pos_view(uv_north,depth_north,PROJECTION_MATRIX);
	vec3 vpos_south = depth_nl_to_pos_view(uv_south,depth_south,PROJECTION_MATRIX);
	vec3 vpos_west = depth_nl_to_pos_view(uv_west,depth_west,PROJECTION_MATRIX);
	vec3 vpos_east = depth_nl_to_pos_view(uv_east,depth_east,PROJECTION_MATRIX);

	float occlusion_x =
	float occlusion = sqrt(pow(occlusion_x,2.0) + pow(occlusion_y,2.0));

	vec3 col_ao = mix(base_col,occlusion_color,occlusion);*/

	//edges

	vec2 edge_thickness_xy_plane = vec2(edge_thickness_plane, edge_thickness_plane * view_ratio);

	vec2 uv_north_plane = SCREEN_UV + vec2(0.0,-1.0) * edge_thickness_xy_plane;
	vec2 uv_south_plane = SCREEN_UV + vec2(0.0,1.0) * edge_thickness_xy_plane;
	vec2 uv_west_plane = SCREEN_UV + vec2(-1.0,0.0) * edge_thickness_xy_plane;
	vec2 uv_east_plane = SCREEN_UV + vec2(1.0,0.0) * edge_thickness_xy_plane;

	//get the depth of 4 neighboring pixels
	float depth_north = texture(depth_tex, uv_north_plane).r;
	float depth_south = texture(depth_tex, uv_south_plane).r;
	float depth_west = texture(depth_tex, uv_west_plane).r;
	float depth_east = texture(depth_tex, uv_east_plane).r;

	//use depth to find position in view space
	
	float depth_average = (depth_north + depth_south + depth_west + depth_east) / 4.0;
	vec3 vpos_average = depth_nl_to_pos_view(SCREEN_UV,depth_average,PROJECTION_MATRIX);
	
	//vec3 vpos_north = depth_nl_to_pos_view(uv_north,depth_north,PROJECTION_MATRIX);
	//vec3 vpos_south = depth_nl_to_pos_view(uv_south,depth_south,PROJECTION_MATRIX);
	//vec3 vpos_west = depth_nl_to_pos_view(uv_west,depth_west,PROJECTION_MATRIX);
	//vec3 vpos_east = depth_nl_to_pos_view(uv_east,depth_east,PROJECTION_MATRIX);

	//decode normals of neighbors from screen texture
	
	vec2 edge_thickness_xy_norm = vec2(edge_thickness_norm, edge_thickness_norm * view_ratio);

	vec2 uv_north_norm = SCREEN_UV + vec2(0.0,-1.0) * edge_thickness_xy_norm;
	vec2 uv_south_norm = SCREEN_UV + vec2(0.0,1.0) * edge_thickness_xy_norm;
	vec2 uv_west_norm = SCREEN_UV + vec2(-1.0,0.0) * edge_thickness_xy_norm;
	vec2 uv_east_norm = SCREEN_UV + vec2(1.0,0.0) * edge_thickness_xy_norm;

	vec3 col_north = texture(screen_tex,uv_north_norm).rgb;
	vec3 col_south = texture(screen_tex,uv_south_norm).rgb;
	vec3 col_west = texture(screen_tex,uv_west_norm).rgb;
	vec3 col_east = texture(screen_tex,uv_east_norm).rgb;
	vec3 unpaired_north[2] = snake_unpair(col_north,grid_size);
	vec3 unpaired_south[2] = snake_unpair(col_south,grid_size);
	vec3 unpaired_west[2] = snake_unpair(col_west,grid_size);
	vec3 unpaired_east[2] = snake_unpair(col_east,grid_size);
	vec3 norm_north = unpaired_north[0] * 2.0 - 1.0;
	vec3 norm_south = unpaired_south[0] * 2.0 - 1.0;
	vec3 norm_west = unpaired_west[0] * 2.0 - 1.0;
	vec3 norm_east = unpaired_east[0] * 2.0 - 1.0;
	
	vec3 norm_avg = normalize(norm_north + norm_south + norm_west + norm_east);

	//find the depth between each neighbor's vpos and the intersection between
	//a ray along the z axis and the normal plane

	float dif_depth = dis_ray_plane(vpos,vec3(0.0,0.0,1.0),vpos_average,norm_avg);
	//float dif_dep_north = dis_ray_plane(vpos_north,vec3(0.0,0.0,1.0),vpos,norm);
	//float dif_dep_south = dis_ray_plane(vpos_south,vec3(0.0,0.0,1.0),vpos,norm);
	//float dif_dep_west = dis_ray_plane(vpos_west,vec3(0.0,0.0,1.0),vpos,norm);
	//float dif_dep_east = dis_ray_plane(vpos_east,vec3(0.0,0.0,1.0),vpos,norm);

	//calculate the ratio between the z difference and the x/y difference

	float vpos_xy_dis = max(length(vpos_average.xy - vpos.xy),0.000001);

	float ratio_depth = dif_depth / (vpos_xy_dis * 100.0);
	//float ratio_north = dif_dep_north / abs(vpos.y - vpos_north.y);
	//float ratio_south = dif_dep_south / abs(vpos.y - vpos_south.y);
	//float ratio_west = dif_dep_west / abs(vpos.x - vpos_west.x);
	//float ratio_east = dif_dep_east / abs(vpos.x - vpos_east.x);

	float dis_normal = 1.0 - (dot(norm_avg,norm) + 100.0) / 2.0;
	//float dis_north_normal = (dot(norm,norm_north) + 1.0) / 2.0;
	//float dis_south_normal = (dot(norm,norm_south) + 1.0) / 2.0;
	//float dis_west_normal = (dot(norm,norm_west) + 1.0) / 2.0;
	//float dis_east_normal = (dot(norm,norm_east) + 1.0) / 2.0;
	
	float ratio_normal = dis_normal / (vpos_xy_dis * 1.0);

	/*vec3 col = mix(vec3(r_unpaired.y,g_unpaired.y,b_unpaired.y),edge_color,clamp(
														 step(plane_thresh,dis_north_plane)
													   + step(plane_thresh,dis_south_plane)
													   + step(plane_thresh,dis_west_plane)
													   + step(plane_thresh,dis_east_plane),0.0,1.0));*/

	/*vec3 col = mix(base_col,edge_color,clamp(step(plane_thresh,dif_dep_north)
										   + step(plane_thresh,dif_dep_south)
										   + step(plane_thresh,dif_dep_west)
										   + step(plane_thresh,dif_dep_east)
										   + step(dis_north_normal,cos(normal_thresh))
										   + step(dis_south_normal,cos(normal_thresh))
										   + step(dis_west_normal,cos(normal_thresh))
										   + step(dis_east_normal,cos(normal_thresh)),0.0,1.0));*/

	//float cos_norm_thresh = cos(normal_thresh);

	/*vec3 col = mix(base_col,edge_color,clamp(step(plane_thresh,ratio_north)
										   + step(plane_thresh,ratio_south)
										   + step(plane_thresh,ratio_west)
										   + step(plane_thresh,ratio_east)
										   + step(dis_north_normal,cos_norm_thresh)
										   + step(dis_south_normal,cos_norm_thresh)
										   + step(dis_west_normal,cos_norm_thresh)
										   + step(dis_east_normal,cos_norm_thresh),0.0,1.0));*/
										
	//vec3 col = mix(base_col,edge_color,min(1.0,step(plane_thresh,ratio_depth) + step(normal_thresh,ratio_normal)));
	
	vec3 col = mix(base_col,edge_color,min(1.0,pow(ratio_depth,0.2) / plane_thresh + pow(ratio_normal,0.2) / normal_thresh));// + ratio_normal / normal_thresh));

	/*vec3 col = mix(base_col,edge_color,clamp(ratio_north / plane_thresh
										   + ratio_south / plane_thresh
										   + ratio_west / plane_thresh
										   + ratio_east / plane_thresh
										   + cos_norm_thresh / dis_north_normal
										   + cos_norm_thresh / dis_south_normal
										   + cos_norm_thresh / dis_west_normal
										   + cos_norm_thresh / dis_east_normal,0.0,1.0));*/

	/*float depth_ratio = sqrt(pow(ratio_north - ratio_south,2.0) + pow(ratio_west - ratio_east,2.0));
	float dis_normal = sqrt(pow(dis_north_normal - dis_south_normal,2.0) + pow(dis_west_normal - dis_east_normal,2.0));

	vec3 col = mix(base_col
				  ,edge_color
				  ,clamp(step(plane_thresh,depth_ratio)
					   + step(cos(normal_thresh),dis_normal),0.0,1.0));*/

	ALBEDO = col;
	//ALBEDO = norm;
	//ALBEDO = (norm + 1.0) / 2.0;
	//ALBEDO = base_col;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
