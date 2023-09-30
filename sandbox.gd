@tool
extends EditorScript

class Horse:
	var x
	var y

# Called when the script is executed (using File -> Run in Script Editor).
func _run():
	var h = Horse.new()
