extends StateMachineState

var toss_speed := 1.0
var toss_t := 0.0

var toss_path: PackedVector2Array

var reticle_scene = preload("res://objects/alert/alert.tscn")
var reticle: AnimatedSprite2D

func _enter_state(param):
	var toss_start: Vector2 = param.toss_start
	var reticle_animation: StringName = param.reticle_animation
	
	var start = toss_start
	var end = this.raft.grid_pos_to_global_position(this.grid_pos)
	var initial_y_vel: float = -2.0
	var offset_y: float = 0.0
	
	toss_path.clear()
	
	var n = 100
	for i in range(0,n+1):
		var tx = float(i) / float(n+1)
		var ty = float(i) / float(n)
		var x = lerp(start.x, end.x, tx)
		var y = lerp(start.y, end.y, ty)
		var y_vel = lerp(initial_y_vel, -initial_y_vel, ty)
		toss_path.append(Vector2(x, y+offset_y))
		offset_y += y_vel
	
	toss_path.append(end)
	
	this.global_position = toss_path[0]
	toss_t = 0.0
	
	reticle = reticle_scene.instantiate()
	reticle.global_position = this.raft.grid_pos_to_global_position(this.grid_pos)
	reticle.play(reticle_animation)
	this.add_child(reticle)
	

func _process(delta):
	toss_t += delta * toss_speed
	
	if toss_t >= 1.0:
		goto("Idle")
	else:
		var i = toss_t * float(toss_path.size()-1)
		var a = toss_path[int(i)]
		var b = toss_path[int(i)+1]
		var x = lerp(a, b, i-int(i))
		this.global_position = x
		reticle.global_position = this.raft.grid_pos_to_global_position(this.grid_pos)

func _exit_state():
	this.position = Vector2.ZERO
	toss_path.clear()
	
	if reticle:
		reticle.queue_free()

