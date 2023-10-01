extends Node

func change_to_scene(scene_filename: String):
	get_tree().change_scene_to_file(scene_filename)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
