extends Node2D

@onready var level_label = $LevelLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	level_label.text = "You Got a Score of %s!\n\n" % GLOBAL_VARS.score
	if _check_and_set_highscore():
		level_label.text += "You set a new high score!"
	else:
		level_label.text += (
			"Too bad it doesn't beat the high score of %s" % DATA_STORE.current.highscore
		)
	unlock_hard_mode()

func unlock_hard_mode():
	if DATA_STORE.current.has('hard_mode_unlocked'):	
		if not DATA_STORE.current.hard_mode_unlocked:
			DATA_STORE.current.hard_mode_unlocked = true
			DATA_STORE.save()
	else:
		DATA_STORE.current['hard_mode_unlocked'] = true
		DATA_STORE.save()

func _check_and_set_highscore():
	if DATA_STORE.current.highscore < GLOBAL_VARS.score:
		DATA_STORE.current.highscore = GLOBAL_VARS.score
		DATA_STORE.save()
		return true
	return false


func _on_start_game_pressed():
	GLOBAL_VARS.score=0
	GLOBAL_VARS.level=0
	GLOBAL_VARS.match3_paused = false
	UTILS.change_to_scene("res://scenes/gameplay/gameplay.tscn")


func _on_main_menu_button_pressed():
	GLOBAL_VARS.score = 0
	GLOBAL_VARS.level = 0
	GLOBAL_VARS.match3_paused = false
	UTILS.change_to_scene("res://scenes/main_menu/main_menu.tscn")


