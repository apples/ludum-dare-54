shader_type canvas_item;
render_mode blend_add;

uniform sampler2D noise : repeat_enable;
uniform sampler2D noise2 : repeat_enable;

void fragment() {
	vec2 adjusted_uv = (UV * vec2(.05, .5)) + vec2(TIME * .01, 0);
	float layer1 = (texture(noise, adjusted_uv).x - .5) * .6;
	
	adjusted_uv = (UV * vec2(.1, .5)) + vec2(TIME * -.003, TIME * -.003);
	float layer2 = (texture(noise2, adjusted_uv).x - .5) * .9;
	
	float combined = layer1 + layer2;
	float peak = clamp(combined * 1.5, 0.0, 1.0);
	float test = clamp(combined - .1, 0.0, 1.0);
	//float test = step(0.0, combined - 0.1) - 0.5;
	float sparkle = pow(peak, 10.0) * 4.5;
	float both = (test / 6.0) + sparkle;
	//float color3 = pow((layer1 + layer2) * 1.5, 4);
	//float color3 = layer1 + layer2;
	
	COLOR = vec4(both, both, both, 1.0);
}
