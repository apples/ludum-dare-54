extends Node2D

@onready var fade_in = $Fade_in
@onready var fade_out = $Fade_out

func _ready():
	fade_out.visible = false

func change_to_scene(scene_filename: String):
	fade_out.visible = true
	fade_out.play()
	await fade_out.animation_finished
	get_tree().change_scene_to_file(scene_filename)
	fade_in.play()
	fade_out.visible = false

