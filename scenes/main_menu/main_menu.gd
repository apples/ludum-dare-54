extends Node
var gameplay_scene_file = "res://scenes/gameplay/gameplay.tscn"
var difficulty_select_scene = "res://scenes/difficulty_select/difficulty_select.tscn"
var options_scene_file = "res://scenes/options_menu/options_menu.tscn"
var help_screen_scene_file = "res://scenes/help_screen/help_screen.tscn"
var spawn_rate_min = 5.0
var spawn_rate_max = 7.0

var scene_goto := ""

# Called when the node enters the scene tree for the first time.
func _ready():
	MusicManager.play("MainMenu")
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound_effects"), linear_to_db(DATA_STORE.current.sfx_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(DATA_STORE.current.music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(DATA_STORE.current.master_volume))
	$highscore.text = "Highscore: %s" % DATA_STORE.current.highscore

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_start_game_pressed():
	$Fade_out.play()
	scene_goto = "gameplay"


func _on_options_pressed():
$Fade_out.play()
	scene_goto = "options"


func _on_fade_out_animation_finished():
	$Fade_out.frame = 0
	if scene_goto == "gameplay":
		UTILS.change_to_scene(difficulty_select_scene)
	else:
	UTILS.change_to_scene(options_scene_file)


func _on_help_pressed():
	UTILS.change_to_scene(help_screen_scene_file)
