extends Node


var current: Node

func _ready():
	play("MainMenu")

func play(track: String):
	if current != null:
		if current.name == track:
			return
		current.stop()
	current = get_node(track)
	current.play()
