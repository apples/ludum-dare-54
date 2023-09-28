extends CharacterBody2D

@export var move_speed: float = 50
@export var damage: int = 1

var target: Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if target == null:
		target = get_tree().get_first_node_in_group("player")
	
	if target != null:
		velocity = (target.global_position - global_position).normalized() * move_speed
	else:
		velocity = Vector2.ZERO

	var collision := move_and_collide(velocity * delta)
	while collision != null:
		var collider: Node2D = collision.get_collider()
		if collider.is_in_group("player"):
			collider.take_damage(damage)
		var proj := collision.get_remainder().project(collision.get_normal())
		var rem := collision.get_remainder() - proj
		collision = move_and_collide(rem)

func take_damage(amount):
	print("yikes! ya got me!")
	var expl = preload("res://objects/enemy_explosion/enemy_explosion.tscn").instantiate()
	get_parent().add_child(expl)
	expl.position = position
	var enemy_new = preload("res://objects/enemy/enemy.tscn").instantiate()
	randomize()
	enemy_new.position= Vector2(randf_range(10,950),randf_range(10,470))
	while (target.position.distance_to(enemy_new.position) < 50):
		enemy_new.position= Vector2(randf_range(10,950),randf_range(10,470))
		print("spawed too close")
	get_parent().add_child(enemy_new)
	print("spawed")
	replace_by(enemy_new)
	queue_free()
	
