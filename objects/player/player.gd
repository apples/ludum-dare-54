extends CharacterBody2D


const SPEED = 300.0

var nearby_interactions = []

func _process(delta):
	pass


func _physics_process(delta):
	var lr = Input.get_axis("left", "right")
	var ud = Input.get_axis("up", "down")
	var move_input = Vector2(lr, ud)
	if move_input:
		velocity = move_input.normalized() * SPEED
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
