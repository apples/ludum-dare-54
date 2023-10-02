extends Node2D
var main_menu_scene_file = "res://scenes/main_menu/main_menu.tscn"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_main_menu_button_pressed():
	$Fade_out.play()

func _on_fade_out_animation_finished():
	$Fade_out.frame = 0
	UTILS.change_to_scene(main_menu_scene_file)
