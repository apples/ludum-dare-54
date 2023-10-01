extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func on_module_valid_connection_updated(valid: bool):
	if valid:
		$AnimatedSprite2D.frame = 0
	else:
		$AnimatedSprite2D.frame = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
