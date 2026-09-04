extends Node2D

var progress_ticks = 0
const max_ticks = 60
var damage = 1
var target := Vector2.ZERO
var start_pos := Vector2.ZERO

var ball_path: PackedVector2Array

#var raft_ref : CoopRaft
var boss_ref : CoopBoss

@export var simple_curve : Curve

func _network_process(input: Dictionary):
	progress_ticks += 1
	var progress = progress_ticks / float(max_ticks)
	global_position = start_pos.lerp(target, progress)
	global_position.y += simple_curve.sample(progress)
	
	if progress_ticks == max_ticks:
		boss_ref.health -= 1
		queue_free()
		#TODO explosion

func _save_state() -> Dictionary:
	return {
		progress_ticks = progress_ticks,
	}

func _load_state(state: Dictionary) -> void:
	progress_ticks = state['progress_ticks']

func _network_spawn(data: Dictionary) -> void:
	#raft_ref = $"/root/CoopGameplay/Raft"
	boss_ref = $"/root/CoopGameplay/Boss"
	global_position = data.pos
	start_pos = global_position
	
	progress_ticks = 0
	target = boss_ref.find_child("CannonSource", false).global_position
	target += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 32.0
	
	
