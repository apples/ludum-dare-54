extends Node2D

var target := Vector2()
var ball_path: PackedVector2Array
var ball_t := 0.0
@onready var ball = $Ball
@onready var explode_fx = $ExplodeFX
@onready var blast_fx = $BlastFX

var ball_flying := false
var ball_speed := 1.0

var damage = 1

var extra_shot := false

func _ready():
	ball.visible = false
	ball_speed *= randf_range(0.9,1.1)
	
	if extra_shot:
		self_modulate = Color.TRANSPARENT
	
	target = get_node('/root/gameplay/Boss/CannonTarget').global_position
	target += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 32.0
	var start = global_position
	var end = target
	var initial_y_vel: float = -2.0
	var offset_y: float = 0.0
	
	var points = PackedVector2Array()
	
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
	
	ball_path = points


func _process(delta):
	if not ball_flying:
		return
	
	ball_t += delta * ball_speed
	
	if ball_t >= 1.0:
		ball.visible = false
		ball_flying = false
		explode_fx.global_position = target
		explode_fx.emitting = true
		$Timer.start(1.0)
		get_node('/root/gameplay/Boss').health -= damage
	else:
		var i = ball_t * float(ball_path.size()-1)
		var a = ball_path[int(i)]
		var b = ball_path[int(i)+1]
		var x = lerp(a, b, i-int(i))
		ball.global_position = x

func blast():
	blast_fx.emitting = true
	ball_flying = true
	ball.visible = true



func _on_timer_timeout():
	queue_free()
