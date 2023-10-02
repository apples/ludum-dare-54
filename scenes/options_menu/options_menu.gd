extends Node

var main_menu_scene_file = "res://scenes/main_menu/main_menu.tscn"

# Called when the node enters the scene tree for the first time.
func _ready():
	$master_slider.value = DATA_STORE.current.master_volume
	$music_slider.value = DATA_STORE.current.music_volume
	$sound_effects_slider.value = DATA_STORE.current.sfx_volume

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_main_menu_button_pressed():
	UTILS.change_to_scene(main_menu_scene_file)



func _on_mute_pressed():
	$master_slider.value = 0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),linear_to_db(0))
	DATA_STORE.current.music_volume = 0
	DATA_STORE.save()



func _on_master_slider_drag_ended(value_changed):
	print($master_slider.value)
	DATA_STORE.current.master_volume = $master_slider.value
	DATA_STORE.save()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),linear_to_db($master_slider.value))


func _on_music_slider_drag_ended(value_changed):
	print($music_slider.value)
	DATA_STORE.current.music_volume = $music_slider.value
	DATA_STORE.save()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),linear_to_db($music_slider.value))


func _on_sound_effects_slider_drag_ended(value_changed):
	print($sound_effects_slider.value)
	DATA_STORE.current.sfx_volume = $sound_effects_slider.value
	DATA_STORE.save()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound_effects"),linear_to_db($sound_effects_slider.value))
