extends CharacterBody2D

@export var move_speed: float = 10

var target: Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if target != null:
		velocity = (target.global_position - global_position).normalized() * move_speed
	else:
		velocity = Vector2.ZERO

	var collision := move_and_collide(velocity * delta)
	while collision != null:
		print(collision.get_collider())
		var proj := collision.get_remainder().project(collision.get_normal())
		var rem := collision.get_remainder() - proj
		collision = move_and_collide(rem)
