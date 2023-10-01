@tool
extends EditorScript

class Horse extends Node:
	var x
	var y

# Called when the script is executed (using File -> Run in Script Editor).
func _run():
	var h = Horse.new()
	print(h.get_child(0))
	h.queue_free()
