shader_type canvas_item;

uniform float pixelSize = 4.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment()
{
	ivec2 size = textureSize(SCREEN_TEXTURE, 0);

	float xRes = float(size.x);
	float yRes = float(size.y);
//
//	float xFactor = float(xRes) / float(pixelSize);
//	float yFactor = float(yRes) / float(pixelSize);
//
//	float grid_uv_x = round(SCREEN_UV.x * xFactor) / xFactor;
//	float grid_uv_y = round(SCREEN_UV.y * yFactor) / yFactor;

	float grid_uv_x = round((SCREEN_UV.x * xRes) / pixelSize);
	float grid_uv_y = round((SCREEN_UV.y * yRes) / pixelSize);

	vec4 text = textureLod(
		screen_texture,
		vec2((grid_uv_x * pixelSize) / xRes,
		(grid_uv_y * pixelSize) / yRes),
		0.0);

	COLOR = text;
}