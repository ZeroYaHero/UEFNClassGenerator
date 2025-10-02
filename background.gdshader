shader_type canvas_item;
#include "res://fbm.gdshaderinc"

uniform vec4 a:source_color;
uniform vec4 b:source_color;

void vertex() {
	UV.x = UV.x + (TIME * 0.02);
	UV.x = UV.x * 1.7;
	UV.y = UV.y - (TIME * 0.02);
	// Called for every vertex the material is visible on.
}

void fragment() {
	COLOR = mix(a, b, fbm(UV));
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
