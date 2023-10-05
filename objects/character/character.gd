extends CharacterBody2D

@export var raft: Node

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hold_root = $HoldRoot
@onready var grab_area = $GrabArea

enum {
	STATE_IDLE,
	STATE_SIT,
	STATE_SWIM,
	STATE_FIX,
	STATE_EXTINGUISH,
}

var nearby_tiles = []

var move_input_disabled := false

var state: int = STATE_IDLE

var walk_speed := 300
var swim_speed := 100

var current_speed := walk_speed

var grid_pos: Vector2i:
	get:
		return grid_current_position

var grid_previous_position : Vector2i
var grid_current_position : Vector2i:
	set(v):
		var t = _what_tile()
		if t:
			t.player_obj = null
		grid_current_position = v
		t = _what_tile()
		if t:
			t.player_obj = self

var grid_lerp_t := 1.0
var grid_lerp_speed := 12.0
var grid_buffered_input: Vector2i = Vector2i.ZERO

var base_tile_scene = preload("res://objects/raft_tile/raft_tile.tscn")

var temp_dir_locked := false
var just_picked_up := false

enum {
	FACING_UP,
	FACING_DOWN,
	FACING_LEFT,
	FACING_RIGHT,
}

var grid_facing: int = FACING_DOWN

var push_delay: float = 0.0

var swap_possible := false
var held_object:
	get:
		if hold_root.get_child_count() > 0:
			return hold_root.get_child(0)
		else:
			return null
	set(v):
		if hold_root.get_child_count() > 0:
			if v != hold_root.get_child(0):
				hold_root.remove_child(hold_root.get_child(0))
		if v != null:
			v.reparent(hold_root)
			v.held_by = self


class InputState:
	var up: bool
	var down: bool
	var left: bool
	var right: bool
	var interact: bool
	var cancel: bool
	var one: bool
	var two: bool
	var three: bool
	var four: bool
	var five: bool
	var six: bool
	
	func _to_string():
		return "%s, %s, %s, %s, %s, %s,%s, %s, %s, %s, %s, %s" % [up, down, left, right, interact, cancel,one,two,three,four,five,six]

var _player_input: InputState = InputState.new()
var _player_input_pressed: InputState = InputState.new()
var _player_input_released: InputState = InputState.new()

func is_standing() -> bool:
	return state == STATE_IDLE and grid_lerp_t >= 1.0

func eat_inputs():
	for k in ["up", "down", "left", "right", "interact", "cancel","one","two","three","four","five","six"]:
		_player_input_pressed[k] = false
		_player_input_released[k] = false

func is_action_pressed(action_name: String) -> bool:
	return _player_input[action_name]

func is_action_released(action_name: String) -> bool:
	return not _player_input[action_name]

func is_action_just_pressed(action_name: String) -> bool:
	return _player_input_pressed[action_name]

func is_action_just_released(action_name: String) -> bool:
	return _player_input_released[action_name]

func get_axis(neg: String, pos: String) -> float:
	return (1.0 if _player_input[pos] else 0.0) - (1.0 if _player_input[neg] else 0.0)

func _get_player_input() -> InputState:
	push_error("Not implemented")
	return InputState.new()

func _ready():
	if not raft:
		push_error("Character has no raft :(")
		queue_free()
		return

	var t = raft.get_tile_at(position)
	if t != null:
		grid_current_position = t.grid_pos
	else:
		grid_current_position = raft.get_closest_empty_tile(position).grid_pos
	
	position = raft.rc_to_pos(grid_current_position)

func _process(delta):
	var input = _get_player_input()
	for k in ["up", "down", "left", "right", "interact", "cancel","one","two","three","four","five","six"]:
		_player_input_pressed[k] = input[k] and not _player_input[k]
		_player_input_released[k] = not input[k] and _player_input[k]
		_player_input[k] = input[k]
	
	grid_lerp_t += delta * grid_lerp_speed
	if grid_lerp_t < 1.0:
		var a = raft.rc_to_pos(grid_previous_position)
		var b = raft.rc_to_pos(grid_current_position)
		position = lerp(a, b, grid_lerp_t)
	else:
		position = raft.rc_to_pos(grid_current_position)
	
	match state:
		STATE_IDLE: _process_idle(delta)
		STATE_SIT: _process_sit(delta)
		STATE_FIX: _process_fix(delta)

func _process_idle(_delta):
	if Input.is_key_pressed(KEY_KP_7):
		Engine.time_scale = 10.0
	else:
		Engine.time_scale = 1.0
	if Input.is_key_pressed((KEY_8)) or Input.is_key_pressed((KEY_KP_8)):
		get_tree().get_root().get_node("gameplay").overlay_upgrade_scene(1)
	
	if move_input_disabled:
		return
	
	if not _what_tile():
		var t = raft.get_random_empty_tile()
		grid_current_position = t.grid_pos
		grid_previous_position = t.grid_pos
		global_position = t.global_position
		_change_state(STATE_IDLE)
		return
	
	var god_mode_action = god_mode_process()
	
	if god_mode_action:
		print("I have the power")
	elif _player_input_pressed.interact:
		var tile = raft.get_tile(grid_current_position.y, grid_current_position.x)
		if tile != null and tile.tile_object != null:
			tile.tile_object.interact(self)
		else:
			if not held_object:
				var facing_obj = get_facing_object()
				if facing_obj != null and facing_obj.is_holdable:
					facing_obj.detach_raft()
					held_object = facing_obj
					facing_obj.position = Vector2.ZERO
					swap_possible = true
					just_picked_up = true
				elif facing_obj == null:
					grab_area.global_position = self.global_position + ((get_facing_dir() * 32) as Vector2)
					if grab_area.has_overlapping_areas():
						held_object = grab_area.get_overlapping_areas()[0].item
						held_object.raft = raft
						grab_area.get_overlapping_areas()[0].queue_free()
						held_object.position = Vector2.ZERO
					
			else:
				var f = grid_current_position + get_facing_dir()
				var t = raft.get_tile(f.y, f.x)
				if t != null and t.tile_object == null:
					if swap_possible:
						t = raft.get_tile(grid_current_position.y, grid_current_position.x)
						swap_possible = false
						grid_buffered_input = get_facing_dir()
					var o = held_object
					o.reparent(t)
					t.tile_object = o
					o.grid_pos = t.grid_pos
					o.position = Vector2.ZERO
					o.held_by = null
				just_picked_up = false
	
	match grid_facing:
		FACING_LEFT:
			anim.play("left")
		FACING_RIGHT:
			anim.play("right")
		FACING_UP:
			anim.play("up")
		FACING_DOWN:
			anim.play("down")

func _process_sit(_delta):
	pass

func _process_fix(_delta):
	pass

func _process_swim(_delta):
	if _what_tile() != null:
		_change_state(STATE_IDLE)

func _change_state(s):
	# Previous state exit hook
	match state:
		STATE_IDLE:
			pass
		STATE_FIX:
			move_input_disabled = false
		STATE_SIT:
			move_input_disabled = false
		STATE_SWIM:
			pass
	state = s
	# New state entrance hook
	match state:
		STATE_IDLE:
			anim.pause()
			current_speed = walk_speed
		STATE_FIX:
			anim.play("fix")
			current_speed = walk_speed
			move_input_disabled = true
			current_speed = 0
		STATE_SIT:
			anim.play("sit")
			move_input_disabled = true
			current_speed = 0
		STATE_SWIM:
			anim.play("down")
			current_speed = swim_speed

func get_facing_dir() -> Vector2i:
	match grid_facing:
		FACING_LEFT:
			return Vector2i(-1, 0)
		FACING_RIGHT:
			return Vector2i(1, 0)
		FACING_UP:
			return Vector2i(0, -1)
		FACING_DOWN:
			return Vector2i(0, 1)
		_:
			assert(false)
			return Vector2i()
	

func get_facing_object():
	var f = grid_current_position + get_facing_dir()
	var tile = raft.get_tile(f.y, f.x)
	if tile == null:
		return null
	if tile.tile_object and tile.tile_object.state != 0:
		return null
	return tile.tile_object

func _what_tile():
	return raft.get_tile(grid_current_position.y, grid_current_position.x)

func _physics_process(delta):
	if move_input_disabled:
		velocity = Vector2.ZERO
		return
	
	if !_player_input.right and !_player_input.left and !_player_input.down and !_player_input.up:
		temp_dir_locked = false
		just_picked_up = false
	if temp_dir_locked:
		return
	
	var has_input := _player_input.right or _player_input.left or _player_input.down or _player_input.up
	if has_input and grid_lerp_t >= 1.0:
		var lr = (1.0 if _player_input.right else 0.0) - (1.0 if _player_input.left else 0.0)
		var ud = (1.0 if _player_input.down else 0.0) - (1.0 if _player_input.up else 0.0)
		var dir := Vector2i()
		if lr < 0:
			dir = Vector2i(-1,0)
		if lr > 0:
			dir = Vector2i(1,0)
		if ud < 0:
			dir = Vector2i(0,-1)
		if ud > 0:
			dir = Vector2i(0,1)
		grid_buffered_input = dir
	
	if grid_lerp_t < 1.0:
		var dir := Vector2i()
		if _player_input_pressed.left:
			dir = Vector2i(-1,0)
		if _player_input_pressed.right:
			dir = Vector2i(1,0)
		if _player_input_pressed.up:
			dir = Vector2i(0,-1)
		if _player_input_pressed.down:
			dir = Vector2i(0,1)
		if dir:
			grid_buffered_input = dir
		push_delay = 0.1
	
	if grid_lerp_t >= 1.0:
		var p = grid_facing
		if grid_buffered_input.x < 0:
			grid_facing = FACING_LEFT
		if grid_buffered_input.x > 0:
			grid_facing = FACING_RIGHT
		if grid_buffered_input.y < 0:
			grid_facing = FACING_UP
		if grid_buffered_input.y > 0:
			grid_facing = FACING_DOWN
		if p != grid_facing:
			push_delay = 0.1
	
	if push_delay > 0.0:
		push_delay -= delta
	
#
#		if temp_locked_dir == grid_buffered_input:
#			return
#		else:
#			temp_locked_dir = Vector2i.ZERO
	
	if held_object != null:
		if grid_buffered_input != Vector2i.ZERO && !just_picked_up:
			var f = grid_current_position + get_facing_dir()
			var t = raft.get_tile(f.y, f.x)
			if t != null and t.tile_object == null:
				var o = held_object
				o.reparent(t)
				t.tile_object = o
				o.grid_pos = t.grid_pos
				o.position = Vector2.ZERO
				o.held_by = null
#				temp_locked_dir = grid_buffered_input
			temp_dir_locked = true
		grid_buffered_input = Vector2i.ZERO
	
	if grid_lerp_t >= 1.0 and grid_buffered_input != Vector2i.ZERO:
		var next_grid_position = grid_current_position + grid_buffered_input
		var next_tile = raft.get_tile(next_grid_position.y, next_grid_position.x)
		if next_tile and next_tile.tile_object:
			if next_tile.tile_object.is_pushable:
				if push_delay > 0.0:
					next_tile = null
				elif not next_tile.tile_object.push(grid_current_position):
					next_tile = null
		if next_tile != null:
			grid_previous_position = grid_current_position
			grid_current_position = next_grid_position
			grid_lerp_t = 0
		grid_buffered_input = Vector2i.ZERO
	

func release():
	_change_state(STATE_IDLE)

func sit():
	_change_state(STATE_SIT)

func fix():
	_change_state(STATE_FIX)

func add_tile(tile: Node):
	nearby_tiles.append(tile)

func remove_tile(tile: Node):
	nearby_tiles.erase(tile)

func god_mode_process():
	#todo  remove god_mode before publishing
	#return false
	if  _player_input_pressed.one:
		var raft_object_instance =  preload("res://objects/raft_objects/water_bucket.tscn").instantiate()
		var tile = raft.get_tile(grid_current_position.y, grid_current_position.x)
		raft_object_instance.grid_pos = tile.grid_pos
		raft_object_instance.raft = raft
		tile.add_child(raft_object_instance)
		held_object = raft_object_instance
		return true
	elif _player_input_pressed.two:
		var raft_object_instance =  preload("res://objects/raft_objects/driftwood.tscn").instantiate()
		var tile = raft.get_tile(grid_current_position.y, grid_current_position.x)
		raft_object_instance.grid_pos = tile.grid_pos
		raft_object_instance.raft = raft
		tile.add_child(raft_object_instance)
		held_object = raft_object_instance
		return true
	
	elif  _player_input_pressed.three:
		var raft_object_instance =  preload("res://objects/raft_objects/bomb.tscn").instantiate()
		var tile = raft.get_tile(grid_current_position.y, grid_current_position.x)
		raft_object_instance.grid_pos = tile.grid_pos
		raft_object_instance.raft = raft
		tile.add_child(raft_object_instance)
		held_object = raft_object_instance
		return true
	
	elif _player_input_pressed.four:
		var raft_object_instance =  preload("res://objects/raft_objects/gem.tscn").instantiate()
		var tile = raft.get_tile(grid_current_position.y, grid_current_position.x)
		raft_object_instance.grid_pos = tile.grid_pos
		raft_object_instance.raft = raft
		tile.add_child(raft_object_instance)
		held_object = raft_object_instance
		return true
	
	elif _player_input_pressed.five:
		var raft_object_instance =  preload("res://objects/raft_objects/cannon.tscn").instantiate()
		var tile = raft.get_tile(grid_current_position.y, grid_current_position.x)
		raft_object_instance.grid_pos = tile.grid_pos
		raft_object_instance.raft = raft
		tile.add_child(raft_object_instance)
		held_object = raft_object_instance
		return true
	elif _player_input_pressed.six:
		for tile in raft.find_all_tiles("water_bucket"):
			raft.set_tile(base_tile_scene, tile.grid_pos.y, tile.grid_pos.x)
		for tile in raft.find_all_tiles("fire"):
			raft.set_tile(base_tile_scene, tile.grid_pos.y, tile.grid_pos.x)
		for tile in raft.find_all_tiles("hammer"):
			raft.set_tile(base_tile_scene, tile.grid_pos.y, tile.grid_pos.x)
		for tile in raft.find_all_tiles("cannon"):
			raft.set_tile(base_tile_scene, tile.grid_pos.y, tile.grid_pos.x)
		for tile in raft.find_all_tiles("gem"):
			raft.set_tile(base_tile_scene, tile.grid_pos.y, tile.grid_pos.x)
		for tile in raft.find_all_tiles("driftwood"):
			raft.set_tile(base_tile_scene, tile.grid_pos.y, tile.grid_pos.x)
		for tile in raft.find_all_tiles("cannon_ball"):
			raft.set_tile(base_tile_scene, tile.grid_pos.y, tile.grid_pos.x)
		for tile in raft.find_all_tiles("bomb"):
			raft.set_tile(base_tile_scene, tile.grid_pos.y, tile.grid_pos.x)
	
			
		return true
