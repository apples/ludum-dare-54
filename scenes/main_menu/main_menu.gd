extends Node
var gameplay_scene_file = "res://scenes/gameplay/gameplay.tscn"
var options_scene_file = "res://scenes/options_menu/options_menu.tscn"
var spawn_rate_min = 5.0
var spawn_rate_max = 7.0

# Called when the node enters the scene tree for the first time.
func _ready():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound_effects"), linear_to_db(DATA_STORE.current.sfx_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(DATA_STORE.current.music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(DATA_STORE.current.master_volume))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_start_game_pressed():
	UTILS.change_to_scene(gameplay_scene_file)


func _on_options_pressed():
	UTILS.change_to_scene(options_scene_file)
