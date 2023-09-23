extends CharacterBody2D

@export var speed = 400
@onready var sprite = $AnimatedSprite2D


func _process(delta):
	if(Input.is_action_just_pressed("attack")):
		sprite.play("heavy_assault")

func _physics_process(delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed
	move_and_slide()


func take_damage(amount: int):
	print("ouch! %s" % amount)


func _on_animated_sprite_2d_animation_finished():
	if(velocity.length() > 0):
		sprite.play("walk")
	else:
		sprite.play("idle")
