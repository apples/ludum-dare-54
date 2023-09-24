extends Button


# Called when the node enters the scene tree for the first time.
func _ready():
	if not DisplayServer.is_touchscreen_available():
		hide()



func _on_button_down():
	Input.action_press("attack")


func _on_button_up():
	Input.action_release("attack")
