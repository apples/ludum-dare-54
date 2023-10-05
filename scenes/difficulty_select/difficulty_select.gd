extends Node2D

var gameplay_scene = "res://scenes/gameplay/gameplay.tscn"

# Called when the node enters the scene tree for the first time.
func _ready():
	if DATA_STORE.current.has('hard_mode_unlocked'):
		if DATA_STORE.current.hard_mode_unlocked:
			$hard_start.disabled = false
		else:
			$hard_start.disabled = true
	else:
		$hard_start.disabled = true
		
	pass # Replace with function body.



func _on_easy_start_pressed():
	GLOBAL_VARS.difficulty = GLOBAL_VARS.DIFF_EASY
	UTILS.change_to_scene(gameplay_scene)


func _on_med_start_pressed():
	GLOBAL_VARS.difficulty = GLOBAL_VARS.DIFF_MED
	UTILS.change_to_scene(gameplay_scene)


func _on_hard_start_pressed():
	GLOBAL_VARS.difficulty = GLOBAL_VARS.DIFF_HARD
	UTILS.change_to_scene(gameplay_scene)
	
