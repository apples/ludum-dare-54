extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
#	module_selected(false)

func module_selected(selected: bool):
	if selected:
		$AnimatedSprite2D.frame = 1
	else:
		$AnimatedSprite2D.frame = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
