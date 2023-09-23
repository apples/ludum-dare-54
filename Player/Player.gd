extends CharacterBody2D

@export var speed = 400
@onready var sprite = $AnimatedSprite2D

@export var health_max: int = 5
var health: int = health_max
signal health_changed

var invinicble: bool = false

func _enter_tree():
	GameState.player_node = self

func _exit_tree():
	GameState.player_node = null


func _process(delta):
	if(Input.is_action_just_pressed("attack")):
		sprite.play("heavy_assault")

func _physics_process(delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed
	move_and_slide()


func take_damage(amount: int):
	if invinicble:
		return

	print("ouch! %s" % amount)
	health -= amount
	if health < 0:
		health = 0
	health_changed.emit()
	invinicble = true
	$IFrameTimer.start()

func _on_i_frame_timer_timeout():
	invinicble = false

func _on_animated_sprite_2d_animation_finished():
	if(velocity.length() > 0):
		sprite.play("walk")
	else:
		sprite.play("idle")
