shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;


uniform float intensity = 0.0;


const float blue_intensity = 0.027;
const float yellow_intensity = 0.02;


void fragment() {
	vec4 input = texture(screen_texture, SCREEN_UV);
	
	float blue = pow(input.b * 10.0, 2) * blue_intensity;
	
	float yellow = pow(input.r * 5.0 + input.g * 5.0, 2) * yellow_intensity;
	
	COLOR = vec4(mix(input.r, yellow * 1.1, 0.3), mix(input.g, yellow * 0.9, 0.3), mix(input.b, blue, 0.3), input.a);
}