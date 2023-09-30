extends CharacterBody2D


var trajectory: PackedVector2Array
var travel_time = 1.0


var _t := 0.0


func _process(delta):
	_t += delta
	var t = _t / travel_time
	
	if t >= 1.0:
		_sploosh()
		queue_free()
		return
	
	var i = t * float(trajectory.size()-1)
	var a = trajectory[int(i)]
	var b = trajectory[int(i)+1]
	var x = lerp(a, b, i-int(i))
	global_position = x


func _sploosh():
	var hit = $RayCast2D.get_collider()
	print(hit)
	if hit != null:
		hit.damage(1)
