extends Node2D

static var next_id = 1
var id = 0
var connected_player: Node
var raft: Node
var grid_pos: Vector2i

@export var is_interactable := false
@export var is_pushable := false
@export var is_holdable := false

var held_by: Node = null

var zoop: AudioStreamPlayer
var zeep: AudioStreamPlayer
var reticle_scene = preload("res://objects/alert/alert.tscn")
var reticle: AnimatedSprite2D

enum {
	IDLE,
	PUSHED,
	TOSSED,
}

var state := IDLE

var push_speed := 32.0 * 12.0
var toss_speed := 1.0
var toss_t := 0.0

var toss_path: PackedVector2Array

func get_kind() -> StringName:
	assert(false, "get_kind() not implemented")
	return ""

func _process_unconnected(_delta):
	pass

func _process_connected(_delta):
	pass

func _physics_process_connected(_delta):
	pass

func _on_player_connected():
	pass

func _on_player_disconnected():
	pass

func _init():
	id = next_id
	next_id += 1
	z_index = 5

func _ready():
	zoop = AudioStreamPlayer.new()
	zoop.stream = preload("res://assets/sfx/bomb_throw.ogg")
	zoop.bus = "Sound_effects"
	zoop.volume_db = -4
	add_child(zoop)
	
	zeep = AudioStreamPlayer.new()
	zeep.stream = preload("res://assets/sfx/new_item_pickup.ogg")
	zeep.bus = "Sound_effects"
	zeep.volume_db = 5
	add_child(zeep)

func _exit_tree():
	if connected_player:
		connected_player.call_deferred("release")
		_on_player_disconnected()

func _process(delta):
	match state:
		PUSHED:
			position = position.move_toward(Vector2.ZERO, push_speed * delta)
			if position == Vector2.ZERO:
				state = IDLE
		TOSSED:
			toss_t += delta * toss_speed
			
			if toss_t >= 1.0:
				state = IDLE
				position = Vector2.ZERO
				reticle.queue_free()
			else:
				var i = toss_t * float(toss_path.size()-1)
				var a = toss_path[int(i)]
				var b = toss_path[int(i)+1]
				var x = lerp(a, b, i-int(i))
				global_position = x
				reticle.global_position = raft.rc_to_pos(grid_pos)
		IDLE:
			if raft and not connected_player and not held_by:
				_process_unconnected(delta)
			else:
				_process_connected(delta)

func _physics_process(delta):
	if not connected_player:
		return
	
	_physics_process_connected(delta)

func interact(player):
	if not is_interactable:
		return
	
	connected_player = player
	connected_player.eat_inputs()
	
	_on_player_connected()

func push(player_grid_pos: Vector2i):
	if state != IDLE:
		return false
	var d := grid_pos - player_grid_pos
	var next_pos := grid_pos + d
	var next_tile = raft.get_tile(next_pos.y, next_pos.x)
	if next_tile and next_tile.tile_object == null:
		raft.move_object(next_tile.grid_pos, self)
		return true

func release_player():
	connected_player.call_deferred("release")
	connected_player = null
	_on_player_disconnected()

func find_neighboring_objects(of_kind: StringName):
	var nbors = []
	
	for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var nbor = raft.get_tile(grid_pos.y + d.y, grid_pos.x + d.x)
		if not nbor:
			continue
		if not nbor.tile_object:
			continue
		if nbor.tile_object.state != IDLE:
			continue
		if nbor.tile_object.get_kind() == of_kind:
			nbors.append(nbor.tile_object)
	
	return nbors

func match3() -> Array[Node]:
	if GLOBAL_VARS.match3_paused:
		return []
	
	if not raft:
		return []
	
	var region: RaftRegion = raft.get_region(grid_pos)
	
	if region.tile_list.size() < 3:
		return []
	
	if region.tile_list[0].tile_object.id != id:
		return []
	
	return region.tile_list

func replace_with_gem():
	raft.replace_object(grid_pos, preload("res://objects/raft_objects/gem.tscn").instantiate())

func moved():
	state = PUSHED

func boss_toss(toss_start: Vector2, reticle_animation: String = "bad_thing", buoy: bool = false):
	var start = toss_start
	var end = raft.rc_to_pos(grid_pos)
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
	
	state = TOSSED
	global_position = points[0]
	toss_path = points
	toss_t = 0.0
	if buoy:
		zeep.play()
	else:
		zoop.play()
	
	reticle = reticle_scene.instantiate()
	reticle.global_position = raft.rc_to_pos(grid_pos)
	reticle.play(reticle_animation)
	add_child(reticle)
