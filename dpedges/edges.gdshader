shader_type spatial;

render_mode unshaded, fog_disabled;
uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D screen_texture : hint_screen_texture;

uniform mat3 weights_h;
uniform mat3 weights_v;
uniform float threshold : hint_range(0.0, 2.0, 0.01);
uniform vec3 edge_color : source_color;
uniform float edge_thickness : hint_range(0.0, 5.0, 0.1);

vec3 depth_nl_to_pos_view(vec2 scr_uv, float depth, mat4 pro_mat){
	vec3 ndc = vec3(scr_uv, depth) * 2.0 - 1.0;
	vec4 view = inverse(pro_mat) * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return view.xyz;
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {

	//find view-space position of all 9 pixels
	vec2 pixel_size = (1.0 / VIEWPORT_SIZE) * edge_thickness;
	vec3 vpos[9];
	for(int c = 0;c < 3;c ++){
		for(int r = 0;r < 3;r ++){
			vec2 uv = SCREEN_UV + pixel_size * vec2(float(c - 1),float(r - 1));
			float depth_nl = texture(depth_texture,uv).r * 10.0;
			vpos[c + r * 3] = depth_nl_to_pos_view(uv,depth_nl,PROJECTION_MATRIX);
		}
	}

	//add together neighbors on sides and take the weighted average
	vec3 left = (vpos[0] * weights_h[0][0] + vpos[3] * weights_h[1][0] + vpos[6] * weights_h[2][0])
			  / (weights_h[0][0] + weights_h[1][0] + weights_h[2][0]);
	vec3 center = (vpos[1] * weights_h[0][1] + vpos[4] * weights_h[1][1] + vpos[7] * weights_h[2][1])
			  / (weights_h[0][1] + weights_h[1][1] + weights_h[2][1]);
	vec3 right = (vpos[2] * weights_h[0][2] + vpos[5] * weights_h[1][2] + vpos[8] * weights_h[2][2])
			  / (weights_h[0][2] + weights_h[1][2] + weights_h[2][2]);
	vec3 top = (vpos[0] * weights_v[0][0] + vpos[1] * weights_v[0][1] + vpos[2] * weights_v[0][2])
			  / (weights_v[0][0] + weights_v[0][1] + weights_v[0][2]);
	vec3 middle = (vpos[3] * weights_v[1][0] + vpos[4] * weights_v[1][1] + vpos[5] * weights_v[1][2])
			  / (weights_v[1][0] + weights_v[1][1] + weights_v[1][2]);
	vec3 bottom = (vpos[6] * weights_v[2][0] + vpos[7] * weights_v[2][1] + vpos[8] * weights_v[2][2])
			  / (weights_v[2][0] + weights_v[2][1] + weights_v[2][2]);

	//compare change in direction and combine axes
	float edge_h = dot(center - left,right - center);
	float edge_v = dot(middle - top,bottom - middle);
	float edge = step(threshold * 0.001,sqrt(edge_h * edge_h + edge_v * edge_v));

	vec3 screen_color = texture(screen_texture,SCREEN_UV).rgb;
	ALBEDO = mix(screen_color,edge_color,edge);

}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
