shader_type spatial;


//render_mode unshaded;
//uniform vec3 col : source_color;
uniform float shadow : hint_range(0.0, 1.0, 0.05);

void vertex() {
}

void fragment() {
	//vec3 decimated = NORMAL;//ceil(NORMAL / 0.1) * 0.1;
	vec3 normal_scaled = (NORMAL + 1.0) * 0.5;
	vec3 col = vec3(normal_scaled.x,normal_scaled.y * 0.49 + 0.5 * round(normal_scaled.z),1.0);
	//vec3 col = vec3(normal_xy_scaled,(sqrt(1.0 - NORMAL.x * NORMAL.x - NORMAL.y * NORMAL.y) + 1.0) / 2.0);
	ALBEDO = col;
	//ALBEDO = normal_scaled;
	//normal_xy.y = normal_xy.xy
	//ALBEDO = vec3(normal_xy,1.0);
	//ALBEDO = vec3(SCREEN_UV,0.0);
	//ALBEDO = vec3(1.0,1.0,1.0);
}

void light() {
	//DIFFUSE_LIGHT = vec3(1.0,0.0,0.0);
	DIFFUSE_LIGHT += vec3(1.0,1.0,1.0 - (1.0 - ceil(max(floor(1.0 - abs(dot(NORMAL, LIGHT))), ATTENUATION))) * shadow);// * ALBEDO;// * LIGHT_COLOR;
}
