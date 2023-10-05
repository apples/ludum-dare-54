extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
#	module_selected(false)

func module_selected(selected: bool):
	if selected:
		$AnimatedSprite2D.play("selected")
	else:
		$AnimatedSprite2D.play("unselected")
