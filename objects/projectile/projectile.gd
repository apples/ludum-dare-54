extends CharacterBody2D

var trajectory: PackedVector2Array
var travel_time = 1.0
var reticle: Node2D

var _t := 0.0

func _process(delta):
	_t += delta
	var t = _t / travel_time
	
	if t >= 1.0:
		_sploosh()
		return
	
	var i = t * float(trajectory.size()-1)
	var a = trajectory[int(i)]
	var b = trajectory[int(i)+1]
	var x = lerp(a, b, i-int(i))
	global_position = x


func _sploosh():
	reticle.queue_free() 
	queue_free()
	
	var hit = $RayCast2D.get_collider()
	if hit != null:
		hit.damage(1)
		get_parent().get_node("player_raft").play_raft_hit_cannoball()
