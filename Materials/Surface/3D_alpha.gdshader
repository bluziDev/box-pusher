shader_type spatial;

render_mode fog_disabled,depth_prepass_alpha;

uniform float edge_strength : hint_range(0.0, 1.0, 0.01);
uniform float ambient_light : hint_range(0.0,1.0,0.01);
uniform float shadow_brightness : hint_range(0.0, 1.0, 0.1);
//uniform sampler2D dot_texture;
uniform sampler2D depth_tex : hint_depth_texture;

vec2 view_to_screen(vec2 view_space,mat4 pro_mat){
	vec4 clip_space = vec4(view_space,0.0,1.0) * pro_mat;
	vec3 ndc = clip_space.xyz / clip_space.w;
	return (ndc.xy * 0.5) + 0.5;
}

/*float prox_ease(float num){
	return
}*/

void fragment() {
	//ALBEDO = vec3(edge_strength,1.0,1.0);
	float depth = texture(depth_tex,SCREEN_UV).r;
	bool behind = depth > FRAGCOORD.z;
	DEPTH = mix(FRAGCOORD.z,1.0,float(behind));
	ALBEDO = vec3(edge_strength * float(!behind),1.0,1.0 * float(!behind) + 0.6 * float(behind));
	//ALPHA_SCISSOR_THRESHOLD = 1.0;
	//ALPHA = 1.0;

}

void light() {

	float lighting = ambient_light + (1.0 - ambient_light) * ATTENUATION;
	DIFFUSE_LIGHT += vec3(1.0,1.0,mix(shadow_brightness,1.0,round(lighting)));
	//DIFFUSE_LIGHT += vec3(1.0,1.0,ceil(max(floor(1.0 - abs(dot(NORMAL, LIGHT))), ATTENUATION)));
}
