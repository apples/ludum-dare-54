extends Control

@onready var dpad = $DPad

func _ready():
	if not DisplayServer.is_touchscreen_available():
		visible = false
		queue_free()

func _on_d_pad_gui_input(event):
	if event is InputEventScreenTouch:
		var action
		var mp = dpad.size / 2.0
		var rel_pos = event.position - mp
		if abs(rel_pos.x) > abs(rel_pos.y):
			if rel_pos.x > 0:
				action = "right"
			else:
				action = "left"
		else:
			if rel_pos.y > 0:
				action = "down"
			else:
				action = "up"
		if event.pressed:
			Input.action_press(action)
		else:
			Input.action_release(action)


func _on_button_gui_input(event):
	if event is InputEventScreenTouch:
		var action = "interact"
		if event.pressed:
			Input.action_press(action)
		else:
			Input.action_release(action)
