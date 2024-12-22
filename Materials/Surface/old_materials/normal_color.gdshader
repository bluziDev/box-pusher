shader_type spatial;

//render_mode unshaded;
varying vec3 world_normal;
uniform vec3 col : source_color;

void vertex() {

	//convert model normal to world normal
    NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	world_normal = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

void fragment() {
	//use normal remapped to 0...1 as color for next pass
	ALBEDO = col;
	//ALBEDO.rgb = (world_normal.xyz + vec3(1.0)) / 2.0;
}