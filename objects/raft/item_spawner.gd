extends Node2D

@export var raft: Node
var lose_screen_scene_file = "res://scenes/lose_screen/lose_scene.tscn"
var buoy_scene = preload("res://objects/item_buoy/item_buoy.tscn")
var spawn_rate_min = 2.0
var spawn_rate_max = 3.5
var spawn_acceleration := 60 # lower is faster acceleration

func _spawn_a_buoy():
	var buoy = buoy_scene.instantiate()
	if(raft):
		buoy.global_position = raft.global_position + Vector2(randi_range(1,17) * 32, 0)
	else:
		buoy.global_position =  Vector2(randi_range(8,22) * 32, 0)
	get_parent().add_child(buoy)

func _on_timer_timeout():
	_spawn_a_buoy()
	spawn_rate_min -= (spawn_rate_min - 1) / spawn_acceleration
	spawn_rate_max -= (spawn_rate_max - 1) / spawn_acceleration
	$Timer.start(randf_range(spawn_rate_min, spawn_rate_max))

