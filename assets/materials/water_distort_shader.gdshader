shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler3D noise_tex : repeat_enable, filter_linear;

uniform float scale = 3.0;
uniform float speed = 0.2;
uniform float strength : hint_range(0.0, 0.05) = 0.01;
uniform vec4 tint : source_color = vec4(1, 1, 1, 1); //vec4(0.1, 0.1, 1.0, 0.75); //231, 100, 48, 180 for ok

void fragment() {
	vec2 p = UV * scale;
	float z = TIME * speed;

	// Two samples with an offset so X and Y distortion aren't identical
	float nx = texture(noise_tex, vec3(p, z)).r;
	float ny = texture(noise_tex, vec3(p + vec2(5.2, 1.3), z)).r;

	vec2 offset = (vec2(nx, ny) - 0.5) * 2.0 * strength;

	vec3 col = texture(screen_tex, SCREEN_UV + offset).rgb;
	COLOR = vec4(mix(col, tint.rgb, tint.a), 1.0);
}
