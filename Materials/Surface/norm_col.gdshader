shader_type spatial;

render_mode unshaded;
uniform vec3 in_col : source_color;

int hilbert_index(int n, int x, int y) {
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
}

float pair(float x,float y){
	float x_s = round(x * 7.0);
	float y_s = round(y * 7.0);
	float paired = (0.5 * (x_s + y_s) * (x_s + y_s + 1.0) + y_s);
	return paired / 128.0;
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 norm_s = (NORMAL + 1.0) / 2.0;
	//vec3 col = vec3(pair(norm_s.x,in_col.r),pair(norm_s.y,in_col.g),pair(norm_s.z,in_col.b));
	int grid_size = 8;
	int maximum_index = grid_size * grid_size - 1;

	vec3 col = vec3(float(hilbert_index(grid_size,int(round(norm_s.x * float(grid_size - 1))),int(round(in_col.r * float(grid_size - 1))))) / float(maximum_index)
				   ,float(hilbert_index(grid_size,int(round(norm_s.y * float(grid_size - 1))),int(round(in_col.g * float(grid_size - 1))))) / float(maximum_index)
				   ,float(hilbert_index(grid_size,int(round(norm_s.z * float(grid_size - 1))),int(round(in_col.b * float(grid_size - 1))))) / float(maximum_index));
	//vec3 col = vec3(normal_xy_scaled,(sqrt(1.0 - NORMAL.x * NORMAL.x - NORMAL.y * NORMAL.y) + 1.0) / 2.0);
	ALBEDO = col;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
