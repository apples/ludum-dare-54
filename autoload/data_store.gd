extends Node

# Save location:
# C:\Users\cubbi\AppData\Roaming\Godot\app_userdata\GMTK-2023
const filename = "user://raft_blaster_save.json"

var current: Dictionary

var _default_values := {
	highscore = 0,
	max_level_reached = 0,
	master_volume = 1,
	sfx_volume = 1,
	music_volume = 1
}

func _ready():
	reload()

func save():
	var data = JSON.stringify(current)
	var file = FileAccess.open(filename, FileAccess.WRITE)
	file.store_string(data)
	file.close()
	print("Game saved")

func reload():
	var file = FileAccess.open(filename, FileAccess.READ)
	if not file:
		current = _default_values.duplicate(true)
		print("No save game found")
		return
	var data = file.get_as_text()
	current = JSON.parse_string(data)
	
	print("Loaded found save game")

func delete_data():
	current = _default_values.duplicate(true)
	save()
