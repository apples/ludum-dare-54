extends Node

var main_menu_scene_file = "res://scenes/main_menu/main_menu.tscn"

var current_scene = null
var last_master_volume = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_main_menu_button_pressed():
	UTILS.change_to_scene(main_menu_scene_file)



func _on_mute_pressed():
	var old_master_volume=db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),linear_to_db(last_master_volume))
	get_node("master_slider").value=last_master_volume
	last_master_volume=old_master_volume
	


func _on_music_slider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),linear_to_db(value))


func _on_sound_effects_slider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound_effects"),linear_to_db(value))


func _on_master_slider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),linear_to_db(value))


