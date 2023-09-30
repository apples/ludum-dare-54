extends Control
#var player_ref: PlayerCharacter # may not need

var options = []
var select_index = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	options = [
		$option_1,
		$option_2,
		$option_3
	]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("up"):
		if select_index > 0:
			select_index -= 1
			print(select_index)
			$selected_option.position = options[select_index].position
			$selected_option.position.y -= 5
			$selected_option.position.x -= 5
			print("up yo")
	
	if Input.is_action_just_pressed("down"):
		if select_index < 2:
			select_index += 1
			print(select_index)
#			print($selected_option.position)
			$selected_option.position = options[select_index].position
			$selected_option.position.y -= 5
			$selected_option.position.x -= 5
			print("down yo")
