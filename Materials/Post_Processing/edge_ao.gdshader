shader_type spatial;

render_mode unshaded, fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture;
uniform sampler2D screen_tex : hint_screen_texture;
uniform float plane_thresh : hint_range(0.0, 1.0, 0.0001);
uniform float normal_thresh : hint_range(0.0, 3.14, 0.01);
uniform vec3 edge_color : source_color;
uniform float edge_thickness : hint_range(0.0002, 0.005, 0.00001);

/*vec3 srgb_to_linear(vec3 color) {
	// Approximation from http://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html
	return color * (color * (color * 0.305306011 + 0.682171111) + 0.012522878);
}*/

float dis_ray_plane(vec3 ray_origin, vec3 ray_dir, vec3 plane_point, vec3 plane_normal) {
	// Compute the denominator of the intersection formula
	float denom = dot(ray_dir, plane_normal);
	
	//if the ray and plane are parallel, treat it like a depth comparison
	if (abs(denom) < 0.000001) {
		return abs(ray_origin.z - plane_point.z);
	}
	
	// Calculate the intersection distance along the ray
	float t = dot(plane_point - ray_origin, plane_normal) / denom;

	// Calculate the intersection point
	return abs(t);
}

void rotate(int s, inout int x, inout int y, int rx, int ry) {
    // Rotate and reflect coordinates based on the quadrant
    if (ry == 0) {
        if (rx == 1) {
            x = s - 1 - x;
            y = s - 1 - y;
        }
        // Swap x and y
        int temp = x;
        x = y;
        y = temp;
    }
}

vec2 hilbert_coords(int n, int index) {
    int x = 0;
    int y = 0;
    int s = 1;
    int t = index;
    
    // Iterate over each level of subdivision (starting from the smallest)
    while (s < n) {
        // Determine the quadrant for the current index
        int rx = (t / 2) % 2;
        int ry = (t ^ rx) % 2;

        // Rotate and reflect the coordinates based on the quadrant
        rotate(s, x, y, rx, ry);

        // Update the coordinates for this level
        x += s * rx;
        y += s * ry;

        // Move to the next subdivision
        t /= 4;
        s *= 2;
    }

    // Return the (x, y) coordinates normalized to [0, 1]
    return vec2(float(x) / float(n), float(y) / float(n));
}

vec2 unpair(float z){
	//inverse cantor pairing scaled to be between 0 and 1
	float p = z * 128.0;
	float w = floor((sqrt(8.0 * p + 1.0) - 1.0) / 2.0);
	float t = ((w * w) + w) / 2.0;
	float y = p - t;
	return vec2(w - y, y) / 7.0;
}

vec3 decode_norm(vec3 color){
	int grid_size = 8;
	int maximum_index = grid_size * grid_size - 1;
	
	
	vec2 r_unpaired = hilbert_coords(grid_size,int(round(color.r * float(maximum_index))));
	float norm_x = 2.0 * r_unpaired.x - 1.0;
	vec2 g_unpaired = hilbert_coords(grid_size,int(round(color.g * float(maximum_index))));
	float norm_y = 2.0 * g_unpaired.x - 1.0;
	vec2 b_unpaired = hilbert_coords(grid_size,int(round(color.b * float(maximum_index))));
	float norm_z = 2.0 * b_unpaired.x - 1.0;
	return normalize(vec3(norm_x,norm_y,norm_z));
}


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
	
	int grid_size = 8;
	int maximum_index = grid_size * grid_size - 1;
	
	vec2 r_unpaired = hilbert_coords(grid_size,int(round(screen_color.r * float(maximum_index))));
	float norm_x = 2.0 * r_unpaired.x - 1.0;
	vec2 g_unpaired = hilbert_coords(grid_size,int(round(screen_color.g * float(maximum_index))));
	float norm_y = 2.0 * g_unpaired.x - 1.0;
	vec2 b_unpaired = hilbert_coords(grid_size,int(round(screen_color.b * float(maximum_index))));
	float norm_z = 2.0 * b_unpaired.x - 1.0;
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
	vec3 vpos_north = depth_nl_to_pos_view(uv_north,depth_north,PROJECTION_MATRIX);
	vec3 vpos_south = depth_nl_to_pos_view(uv_south,depth_south,PROJECTION_MATRIX);
	vec3 vpos_west = depth_nl_to_pos_view(uv_west,depth_west,PROJECTION_MATRIX);
	vec3 vpos_east = depth_nl_to_pos_view(uv_east,depth_east,PROJECTION_MATRIX);

	//using own view-position as the origin of a plane that is parallel to own normal,
	//find the depth from each pixel to the plane in view space

	/*float plane_d = -dot(norm, vpos);

	float dis_north_plane = dis_to_plane(vpos_north,norm,plane_d);
	float dis_south_plane = dis_to_plane(vpos_south,norm,plane_d);
	float dis_west_plane = dis_to_plane(vpos_west,norm,plane_d);
	float dis_east_plane = dis_to_plane(vpos_east,norm,plane_d);*/
	
	//find the depth between each neighbor's vpos and the intersection between
	//a ray along the z axis and the normal plane
	
	float dif_dep_north = dis_ray_plane(vpos_north,vec3(0.0,0.0,1.0),vpos,norm);
	float dif_dep_south = dis_ray_plane(vpos_south,vec3(0.0,0.0,1.0),vpos,norm);
	float dif_dep_west = dis_ray_plane(vpos_west,vec3(0.0,0.0,1.0),vpos,norm);
	float dif_dep_east = dis_ray_plane(vpos_east,vec3(0.0,0.0,1.0),vpos,norm);

	//decode normals of neighbors from screen texture
	vec3 norm_north = decode_norm(texture(screen_tex,uv_north).rgb);
	vec3 norm_south = decode_norm(texture(screen_tex,uv_south).rgb);
	vec3 norm_west = decode_norm(texture(screen_tex,uv_west).rgb);
	vec3 norm_east = decode_norm(texture(screen_tex,uv_east).rgb);

	float dis_north_normal = (dot(norm,norm_north) + 1.0) / 2.0;
	float dis_south_normal = (dot(norm,norm_south) + 1.0) / 2.0;
	float dis_west_normal = (dot(norm,norm_west) + 1.0) / 2.0;
	float dis_east_normal = (dot(norm,norm_east) + 1.0) / 2.0;

	/*vec3 col = mix(vec3(r_unpaired.y,g_unpaired.y,b_unpaired.y),edge_color,clamp(step(plane_thresh,dis_north_plane)
													   + step(plane_thresh,dis_south_plane)
													   + step(plane_thresh,dis_west_plane)
													   + step(plane_thresh,dis_east_plane)
													   + step(dis_north_normal,cos(normal_thresh))
													   + step(dis_south_normal,cos(normal_thresh))
													   + step(dis_west_normal,cos(normal_thresh))
													   + step(dis_east_normal,cos(normal_thresh)),0.0,1.0));*/
													
	/*vec3 col = mix(vec3(r_unpaired.y,g_unpaired.y,b_unpaired.y),edge_color,clamp(
														 step(plane_thresh,dis_north_plane)
													   + step(plane_thresh,dis_south_plane)
													   + step(plane_thresh,dis_west_plane)
													   + step(plane_thresh,dis_east_plane),0.0,1.0));*/
													
	vec3 col = mix(vec3(r_unpaired.y,g_unpaired.y,b_unpaired.y),edge_color,clamp(
														 step(plane_thresh,dif_dep_north)
													   + step(plane_thresh,dif_dep_south)
													   + step(plane_thresh,dif_dep_west)
													   + step(plane_thresh,dif_dep_east)
													   + step(dis_north_normal,cos(normal_thresh))
													   + step(dis_south_normal,cos(normal_thresh))
													   + step(dis_west_normal,cos(normal_thresh))
													   + step(dis_east_normal,cos(normal_thresh)),0.0,1.0));

	//ALBEDO = vec3(r_unpaired.y,screen_color.g,b_unpaired.y);//col;
	ALBEDO = col;
	//ALBEDO = norm;
	//ALBEDO = (norm + 1.0) / 2.0;
	//ALBEDO = vec3(r_unpaired.y,g_unpaired.y,b_unpaired.y);

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
