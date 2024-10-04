shader_type spatial;

render_mode unshaded, fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture;
uniform sampler2D screen_tex : hint_screen_texture;
uniform float plane_thresh : hint_range(3.0, 10.0, 0.01);
uniform float normal_thresh : hint_range(0.0, 2.0, 0.001);
uniform vec3 edge_color : source_color;
uniform float edge_thickness : hint_range(0.0002, 0.005, 0.00001);

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


	//edges

	vec2 edge_thickness_xy = vec2(edge_thickness, edge_thickness * (VIEWPORT_SIZE.x / VIEWPORT_SIZE.y));

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

	float ratio_north = dif_dep_north / abs(vpos.y - vpos_north.y);
	float ratio_south = dif_dep_south / abs(vpos.y - vpos_south.y);
	float ratio_west = dif_dep_west / abs(vpos.x - vpos_west.x);
	float ratio_east = dif_dep_east / abs(vpos.x - vpos_east.x);

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

	vec3 col = mix(base_col,edge_color,clamp(step(plane_thresh,ratio_north)
										   + step(plane_thresh,ratio_south)
										   + step(plane_thresh,ratio_west)
										   + step(plane_thresh,ratio_east)
										   + step(dis_north_normal,cos(normal_thresh))
										   + step(dis_south_normal,cos(normal_thresh))
										   + step(dis_west_normal,cos(normal_thresh))
										   + step(dis_east_normal,cos(normal_thresh)),0.0,1.0));

	ALBEDO = col;
	//ALBEDO = norm;
	//ALBEDO = (norm + 1.0) / 2.0;
	//ALBEDO = base_col;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
