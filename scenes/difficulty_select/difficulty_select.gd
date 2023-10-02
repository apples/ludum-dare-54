extends Node2D

var gameplay_scene = "res://scenes/gameplay/gameplay.tscn"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_easy_start_pressed():
	GLOBAL_VARS.difficulty = GLOBAL_VARS.DIFF_EASY
	UTILS.change_to_scene(gameplay_scene)


func _on_med_start_pressed():
	GLOBAL_VARS.difficulty = GLOBAL_VARS.DIFF_MED
	UTILS.change_to_scene(gameplay_scene)


func _on_hard_start_pressed():
	GLOBAL_VARS.difficulty = GLOBAL_VARS.DIFF_HARD
	UTILS.change_to_scene(gameplay_scene)
	
