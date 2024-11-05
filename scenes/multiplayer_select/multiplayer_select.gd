extends Node2D

var mult_scene_file = "res://scenes/multiplayer_test/multiplayer_test.tscn"

func _on_coop_host_pressed() -> void:
	MULT_UTILS.is_hosting = true
	MULT_UTILS.mult_name = $NameEdit.text if $NameEdit.text != "" else "Idiot"
	MULT_UTILS.ip_target = $IPEdit.text # not gonna try to error handle this
	UTILS.change_to_scene(mult_scene_file)


func _on_coop_join_pressed() -> void:
	MULT_UTILS.is_hosting = false
	MULT_UTILS.mult_name = $NameEdit.text if $NameEdit.text != "" else "Idiot"
	MULT_UTILS.ip_target = $IPEdit.text
	UTILS.change_to_scene(mult_scene_file)
