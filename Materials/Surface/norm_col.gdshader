shader_type spatial;

render_mode unshaded;
uniform vec3 in_col : source_color;

/*int hilbert_index(int n, int x, int y) {
	int index = 0;
	int s = n / 2;  // Start from the largest division of the grid
	while (s > 0) {
		// Determine quadrant
		int rx = (x & s) > 0 ? 1 : 0;  // Get the s-th bit of x
		int ry = (y & s) > 0 ? 1 : 0;  // Get the s-th bit of y

		index += s * s * ((3 * rx) ^ ry); // Calculate index contribution for this level

		// Rotate or reflect based on quadrant
		if (ry == 0) {
			if (rx == 1) {
				x = n - 1 - x;
				y = n - 1 - y;
			}
			// Swap x and y
			int temp = x;
			x = y;
			y = temp;
		}
		s /= 2;  // Move to next level of subdivision
	}
	return index;
}*/

/*float pair(float x,float y){
	float x_s = round(x * 7.0);
	float y_s = round(y * 7.0);
	float paired = (0.5 * (x_s + y_s) * (x_s + y_s + 1.0) + y_s);
	return paired / 128.0;
}*/

/*ivec3 unit_vec_to_grid(vec3 vec,int grid_size){
	float gs = float(grid_size);
	return ivec3(ceil(clamp(vec * gs, 1.0, gs)) - 1.0);
}*/

vec3 snake_pair(vec3 x,vec3 y,float grid_size){
	vec3 grid_x = round(x * (grid_size - 1.0));//ceil(clamp(x * grid_size, 1.0, grid_size)) - 1.0;
	vec3 grid_y = round(y * (grid_size - 1.0));//ceil(clamp(y * grid_size, 1.0, grid_size)) - 1.0;
	vec3 y_is_odd = mod(grid_y,2.0);
	vec3 snake_index = round(grid_y * grid_size + y_is_odd * (grid_size - 1.0) + grid_x * (y_is_odd * -2.0 + 1.0));
	return snake_index / (pow(grid_size,2.0) - 1.0);
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 norm_s = (NORMAL + 1.0) / 2.0;
	//vec3 col = vec3(pair(norm_s.x,in_col.r),pair(norm_s.y,in_col.g),pair(norm_s.z,in_col.b));
	/*int grid_size = 8;
	int maximum_index = grid_size * grid_size - 1;
	
	ivec3 norm_grid = unit_vec_to_grid(norm_s,grid_size);
	ivec3 col_grid = unit_vec_to_grid(in_col,grid_size);
	
	vec3 col = vec3(float(hilbert_index(grid_size,norm_grid.x,col_grid.x)) / float(maximum_index)
				   ,float(hilbert_index(grid_size,norm_grid.y,col_grid.y)) / float(maximum_index)
				   ,float(hilbert_index(grid_size,norm_grid.z,col_grid.z)) / float(maximum_index));*/

	/*vec3 col = vec3(float(hilbert_index(grid_size,int(round(norm_s.x * float(grid_size - 1))),int(round(in_col.r * float(grid_size - 1))))) / float(maximum_index)
				   ,float(hilbert_index(grid_size,int(round(norm_s.y * float(grid_size - 1))),int(round(in_col.g * float(grid_size - 1))))) / float(maximum_index)
				   ,float(hilbert_index(grid_size,int(round(norm_s.z * float(grid_size - 1))),int(round(in_col.b * float(grid_size - 1))))) / float(maximum_index));*/
	//vec3 col = vec3(normal_xy_scaled,(sqrt(1.0 - NORMAL.x * NORMAL.x - NORMAL.y * NORMAL.y) + 1.0) / 2.0);
	
	float grid_size = 9.0;
	
	//vec3 col = snake_pair(in_col,norm_s,grid_size);
	vec3 col = snake_pair(norm_s,in_col,grid_size);
	
	ALBEDO = col;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
