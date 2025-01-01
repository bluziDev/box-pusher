shader_type spatial;

render_mode unshaded, fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture;
uniform sampler2D screen_tex : hint_screen_texture;
uniform float plane_thresh : hint_range(0.0, 0.5, 0.001);
uniform float normal_thresh : hint_range(0.0, 3.14, 0.01);
uniform vec3 edge_color : source_color;
uniform float edge_thickness : hint_range(0.0002, 0.005, 0.00001);

/*vec3 srgb_to_linear(vec3 color) {
	// Approximation from http://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html
	return color * (color * (color * 0.305306011 + 0.682171111) + 0.012522878);
}*/

//converts nonlinear depth to view-space position
vec3 depth_nl_to_pos_view(vec2 scr_uv, float depth, mat4 pro_mat){
	vec3 ndc = vec3(scr_uv, depth) * 2.0 - 1.0;
	vec4 view = inverse(pro_mat) * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return view.xyz;
}

float dis_to_plane(vec3 point,vec3 plane_normal,float plane_d){
	float dis = abs(dot(plane_normal, point) + plane_d);
	return dis;
}

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

	//get the normal
	vec3 screen_color = texture(screen_tex,SCREEN_UV).rgb;
	//decode normal
	float norm_x = 2.0 * screen_color.r - 1.0;
	float norm_y = mod(screen_color.g,0.5) / 0.49 * 2.0 - 1.0;
	float norm_z = sqrt(max(0.0,1.0 - norm_x * norm_x - norm_y * norm_y)) * (2.0 * round(screen_color.g) - 1.0);
	vec3 norm = normalize(vec3(norm_x,norm_y,norm_z));

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
	vec3 vpos_north = depth_nl_to_pos_view(SCREEN_UV,depth_north,PROJECTION_MATRIX);
	vec3 vpos_south = depth_nl_to_pos_view(SCREEN_UV,depth_south,PROJECTION_MATRIX);
	vec3 vpos_west = depth_nl_to_pos_view(SCREEN_UV,depth_west,PROJECTION_MATRIX);
	vec3 vpos_east = depth_nl_to_pos_view(SCREEN_UV,depth_east,PROJECTION_MATRIX);

	//using own view-position as the origin of a plane that is parallel to own normal,
	//find the distance from each pixel to the plane in view space

	float plane_d = -dot(norm, vpos);

	float dis_north_plane = dis_to_plane(vpos_north,norm,plane_d);
	float dis_south_plane = dis_to_plane(vpos_south,norm,plane_d);
	float dis_west_plane = dis_to_plane(vpos_west,norm,plane_d);
	float dis_east_plane = dis_to_plane(vpos_east,norm,plane_d);

	//decode normals of neighbors from screen texture
	//north
	vec3 screen_color_north = texture(screen_tex,uv_north).rgb;
	float norm_x_north = 2.0 * screen_color_north.r - 1.0;
	float norm_y_north = mod(screen_color_north.g,0.5) / 0.49 * 2.0 - 1.0;
	float norm_z_north = sqrt(max(0.0,1.0 - norm_x_north * norm_x_north - norm_y_north * norm_y_north)) * (2.0 * round(screen_color_north.g) - 1.0);
	vec3 norm_north = normalize(vec3(norm_x_north,norm_y_north,norm_z_north));
	//south
	vec3 screen_color_south = texture(screen_tex,uv_south).rgb;
	float norm_x_south = 2.0 * screen_color_south.r - 1.0;
	float norm_y_south = mod(screen_color_south.g,0.5) / 0.49 * 2.0 - 1.0;
	float norm_z_south = sqrt(max(0.0,1.0 - norm_x_south * norm_x_south - norm_y_south * norm_y_south)) * (2.0 * round(screen_color_south.g) - 1.0);
	vec3 norm_south = normalize(vec3(norm_x_south,norm_y_south,norm_z_south));
	//west
	vec3 screen_color_west = texture(screen_tex,uv_west).rgb;
	float norm_x_west = 2.0 * screen_color_west.r - 1.0;
	float norm_y_west = mod(screen_color_west.g,0.5) / 0.49 * 2.0 - 1.0;
	float norm_z_west = sqrt(max(0.0,1.0 - norm_x_west * norm_x_west - norm_y_west * norm_y_west)) * (2.0 * round(screen_color_west.g) - 1.0);
	vec3 norm_west = normalize(vec3(norm_x_west,norm_y_west,norm_z_west));
	//east
	vec3 screen_color_east = texture(screen_tex,uv_east).rgb;
	float norm_x_east = 2.0 * screen_color_east.r - 1.0;
	float norm_y_east = mod(screen_color_east.g,0.5) / 0.49 * 2.0 - 1.0;
	float norm_z_east = sqrt(max(0.0,1.0 - norm_x_east * norm_x_east - norm_y_east * norm_y_east)) * (2.0 * round(screen_color_east.g) - 1.0);
	vec3 norm_east = normalize(vec3(norm_x_east,norm_y_east,norm_z_east));

	float dis_north_normal = dot(norm,norm_north);
	float dis_south_normal = dot(norm,norm_south);
	float dis_west_normal = dot(norm,norm_west);
	float dis_east_normal = dot(norm,norm_east);

	vec3 col = mix(vec3(screen_color.b),edge_color,clamp(step(plane_thresh,dis_north_plane)
													   + step(plane_thresh,dis_south_plane)
													   + step(plane_thresh,dis_west_plane)
													   + step(plane_thresh,dis_east_plane)
													   + step(dis_north_normal,cos(normal_thresh))
													   + step(dis_south_normal,cos(normal_thresh))
													   + step(dis_west_normal,cos(normal_thresh))
													   + step(dis_east_normal,cos(normal_thresh)),0.0,1.0));

	ALBEDO = col;

	//ALBEDO = vec3(0.0,0.0,(normal.b + 1.0) / 2.0);
	//ALBEDO = (norm + 1.0) / 2.0;
	//ALBEDO = vec3((normal_xy + 1.0) / 2.0,0.0);
	//ALBEDO = vec3(screen_color.b);
	//ALBEDO = screen_color;
	//ALBEDO = vec3(linear_depth * 0.1);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
