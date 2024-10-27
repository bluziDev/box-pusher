shader_type spatial;

render_mode unshaded,fog_disabled;

uniform float edge_strength : hint_range(0.0, 1.0, 0.01);

void vertex() {

}

void fragment() {
	float linear_depth = -VERTEX.z;//-(vec4(VERTEX,1.0) * PROJECTION_MATRIX).z;
	ALBEDO = vec3(edge_strength,1.0,linear_depth);
	//float linear_depth = -(vec4(VERTEX,1.0) * PROJECTION_MATRIX).z;
	//ALBEDO = vec3(edge_strength,linear_depth / 2.0,linear_depth / 2.0);
	//float linear_depth_half = -(vec4(VERTEX / 2.0,1.0) * PROJECTION_MATRIX).z;
	//ALBEDO = vec3(edge_strength,linear_depth_half,linear_depth_half);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
