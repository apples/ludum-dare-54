@tool
#extends EditorScript
extends Polygon2D

@export var point_count := 32:
	set(val):
		point_count = val
		_run()

# Called when the script is executed (using File -> Run in Script Editor).
func _run():
	var points = []
	var point_length = 32
	for i in range(point_count):
		points.append(Vector2(
			-sin((i / float(point_count)) * 2 * PI) * point_length, 
			-cos((i / float(point_count)) * 2 * PI) * point_length))
	polygon = points
