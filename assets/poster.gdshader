shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float intensity = 1.0;

const float yellow_strength = 0.7;
const float blue_strength = 0.7;

void fragment() {
	vec4 input = texture(screen_texture, SCREEN_UV);
	
	float blue = 1.0 + input.b * blue_strength * intensity;
	
	float 	yellow = 1.0 + 
			input.r * yellow_strength * intensity * 0.5 + 
			input.g * yellow_strength * intensity * 0.5;
	
	COLOR = vec4(	input.r * yellow / blue, 
					input.g * yellow / blue, 
					input.b * blue / yellow, 
					input.a);
}