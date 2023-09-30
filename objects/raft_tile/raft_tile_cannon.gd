extends RaftTile

@export var target_starting_pos = Vector2(400, 0)
@export var reticle_speed = 5
@export var refire_delay = 1
@export var projectile_scene = preload("res://objects/projectile/projectile.tscn")
@onready var cannon_hole = $CannonHole
@onready var trajectory = $Trajectory
@onready var reload_timer = $ReloadTimer

var connected_player
var reticle: Node2D
var target = target_starting_pos
var fire_allowed = true

func _process(delta):
	if not connected_player:
		trajectory.visible = false
		return
	
	trajectory.visible = true
	_calculate_trajectory()
	
	if Input.is_action_just_pressed("cancel"):
		connected_player.call_deferred("release")
		reticle.queue_free()
		reticle = null
		connected_player = null
	elif Input.is_action_just_pressed("interact") and fire_allowed:
		connected_player.call_deferred("release")
		connected_player = null
		reload_timer.start(refire_delay)
		fire_allowed = false
		print("Pew Pew")
		var ball = projectile_scene.instantiate()
		ball.global_position = global_position
		ball.trajectory = trajectory.points
		ball.travel_time = 1.0
		ball.reticle = reticle
		reticle = null
		raft_ref.get_parent().add_child(ball)

func _calculate_trajectory():
	var start = cannon_hole.global_position
	var end = reticle.global_position
	var initial_y_vel: float = -4.0
	var offset_y: float = 0.0
	
	var points = PackedVector2Array()
	
	#points.append(start)
	
	var n = 100
	for i in range(0,n+1):
		var tx = float(i) / float(n+1)
		var ty = float(i) / float(n)
		var x = lerp(start.x, end.x, tx)
		var y = lerp(start.y, end.y, ty)
		var y_vel = lerp(initial_y_vel, -initial_y_vel, ty)
		points.append(Vector2(x, y+offset_y))
		offset_y += y_vel
	
	points.append(end)
	
	trajectory.global_position = Vector2.ZERO
	trajectory.points = points

func _physics_process(delta):
	if not connected_player:
		return
	
	var velocity = Vector2.ZERO
	var lr = Input.get_axis("left", "right")
	var ud = Input.get_axis("up", "down")
	var move_input = Vector2(lr, ud)
	if move_input:
		target += move_input.normalized() * reticle_speed
	reticle.position = target


func interact(player):
	player.sit()
	connected_player = player
	reticle = Sprite2D.new()
	reticle.texture = preload("res://assets/textures/reticle.png")
	reticle.z_index = 10
	reticle.position = target
	add_child(reticle)
	print("Player interacted with CANNON LETS GOOOO at <%s, %s>." % [row_index, column_index])


func _on_refire_timer_timeout():
	fire_allowed = true
	print("Reloaded")

func _on_reload_timer_timeout():
	fire_allowed = true
