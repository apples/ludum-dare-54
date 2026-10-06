shader_type canvas_item;

//uniform float transparency : hint_range(0.0, 1.0) = 1.0;
uniform vec4 tint : source_color = vec4(0.1, 0.1, 1.0, 0.75);

void fragment() {
	// Called for every pixel the material is visible on.
	COLOR = tint;
}
