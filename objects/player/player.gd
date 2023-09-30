extends CharacterBody2D

const SPEED = 300.0

@export var idle_sprite: Texture2D
@export var sit_sprite: Texture2D

var nearby_interactions = []

var input_disabled := false

var is_sitting: bool:
	get:
		return is_sitting
	set(v):
		is_sitting = v
		if is_sitting:
			$Sprite.texture = sit_sprite
		else:
			$Sprite.texture = idle_sprite


func _process(delta):
	is_sitting = true


func _physics_process(delta):
	if input_disabled:
		velocity = Vector2.ZERO
		return
	
	var lr = Input.get_axis("left", "right")
	var ud = Input.get_axis("up", "down")
	var move_input = Vector2(lr, ud)
	if move_input:
		velocity = move_input.normalized() * SPEED
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

