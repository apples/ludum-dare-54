extends CharacterBody2D

@export var raft: Node

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hold_root = $HoldRoot
@onready var grab_area = $GrabArea
@onready var state_machine: StateMachine = $StateMachine

var nearby_tiles = []

var walk_speed := 300
var swim_speed := 100

var current_speed := walk_speed

var grid_previous_position : Vector2i
var grid_pos : Vector2i:
	set(v):
		var t = _what_tile()
		if t:
			t.player_obj = null
		grid_pos = v
		t = _what_tile()
		if t:
			t.player_obj = self

var base_tile_scene = preload("res://objects/raft_tile/raft_tile.tscn")

var temp_dir_locked := false

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
			var prev_held = hold_root.get_child(0)
			if v != prev_held:
				hold_root.remove_child(prev_held)
				prev_held.held_by = null
		if v != null:
			if v.get_parent():
				v.reparent(hold_root)
			else:
				hold_root.add_child(v)
			v.held_by = self


class InputState:
	var up: bool
	var down: bool
	var left: bool
	var right: bool
	var interact: bool
	var cancel: bool
	var mouse: bool
	
	var direction: Vector2i
	var direction_just_changed: bool
	
	func _to_string():
		return "%s, %s, %s, %s, %s, %s + (%s, %s)" % [up, down, left, right, interact, cancel, direction, direction_just_changed]

#var input : InputState

var _player_input: InputState = InputState.new()
var _player_input_pressed: InputState = InputState.new()
var _player_input_released: InputState = InputState.new()
var _last_player_input: InputState = InputState.new()

var mouse_start_pos: Vector2
var mouse_dist: Vector2 = Vector2(0, 0)
var mouse_down_timer: float = 0
var mouse_down_activation_time: float = 1 # pop in settings?
var mouse_move_activation_dist: float = 100 # pop in settings?

var player_id = 1

var target_pos: Vector2 = grid_pos
var move_delay_time_ticks := 6 # really this should be configurable in the options, 6 = 0.1 ms
var push_delay_ticks_remaining := 0

func is_standing() -> bool:
	return state_machine.current_state.name == "Idle"

func eat_inputs():
	for k in ["up", "down", "left", "right", "interact", "cancel"]:
		_player_input_pressed[k] = false
		_player_input_released[k] = false
	_player_input.direction_just_changed = false

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

#func _get_player_input() -> InputState:
	#var input := InputState.new()
	#input.left = Input.is_action_pressed("left")
	#input.right = Input.is_action_pressed("right")
	#input.up = Input.is_action_pressed("up")
	#input.down = Input.is_action_pressed("down")
	#input.interact = Input.is_action_pressed("interact")
	#input.cancel = Input.is_action_pressed("cancel")
	#input.mouse = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	#return input

func _get_local_input() -> Dictionary:
	var input := {}
	input["left"] = Input.is_action_pressed("left")
	input["right"] = Input.is_action_pressed("right")
	input["up"] = Input.is_action_pressed("up")
	input["down"] = Input.is_action_pressed("down")
	input["interact"] = Input.is_action_pressed("interact")
	input["cancel"] = Input.is_action_pressed("cancel")
	#input["mouse"] = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	return input

#func _predict_remote_input(previous_input: Dictionary, ticks_since_real_input: int) -> Dictionary:
	#var input = previous_input.duplicate()
	#input.erase("interact")
	##if ticks_since_real_input > 2:
		##input.erase("input_vector")
	#return input

func _player_special_process(_delta) -> void:
	pass

#func _ready():
	#if not raft:
		#push_error("Character has no raft :(")
		#queue_free()
		#return
#
	#var t = raft.get_tile_at(position)
	#if t != null:
		#grid_pos = t.grid_pos
	#else:
		#grid_pos = raft.get_closest_empty_tile(position).grid_pos
	#
	#position = raft.grid_pos_to_global_position(grid_pos)

func _network_process(input: Dictionary):
	#if !is_multiplayer_authority():
		#return
	
	# handle input before anything else
	#var input = _get_player_input()
	
	# mouse/touch overrides
	# need to move this to input method
	#if input["mouse"]:
		#mouse_down_timer += .017#delta
		#
		#if not _player_input.mouse:
			#mouse_start_pos = get_viewport().get_mouse_position()
		#else:
			#mouse_dist = get_viewport().get_mouse_position() - mouse_start_pos
			#if mouse_dist.length() > mouse_move_activation_dist:
				#if abs(mouse_dist.x) > abs(mouse_dist.y):
					#if mouse_dist.x > 0:
						#input["right"] = true
					#if mouse_dist.x < 0:
						#input["left"] = true
				#else:
					#if mouse_dist.y < 0:
						#input["up"] = true
					#if mouse_dist.y > 0:
						#input["down"] = true
			#else:
				#GLOBAL_VARS.mouse_held = mouse_down_timer > mouse_down_activation_time
	#else:
		#mouse_down_timer = 0
		#GLOBAL_VARS.mouse_held = false
		#if is_action_just_released("mouse"):
			#if mouse_dist.length() < mouse_move_activation_dist:
				#input["interact"] = true
			#else:
				#mouse_dist = Vector2(0, 0)
	
	for k in ["up", "down", "left", "right", "interact", "cancel"]:
		_player_input_pressed[k] = input[k] and not _player_input[k]
		_player_input_released[k] = not input[k] and _player_input[k]
		_player_input[k] = input[k]
	
	# directional input - cardinal directions only
	var lr: int = (1 if _player_input.right else 0) - (1 if _player_input.left else 0)
	var ud: int = (1 if _player_input.down else 0) - (1 if _player_input.up else 0)
	var dir := Vector2i(lr, ud)
	if _player_input.direction.x != 0 and dir.x == _player_input.direction.x:
		dir = _player_input.direction
	if _player_input.direction.y != 0 and dir.y == _player_input.direction.y:
		dir = _player_input.direction
	if dir.x != 0 and dir.y != 0:
		dir.y = 0
	assert(dir.x == 0 or dir.y == 0)
	
	_player_input.direction_just_changed = dir != _player_input.direction
	_player_input.direction = dir
	
	update_facing()
	
	# special process (usually for debug)
	_player_special_process(.017)
	
	# failsafe in case player gets off the raft somehow
	if not _what_tile():
		var t = raft.get_random_empty_tile()
		if t:
			grid_pos = t.grid_pos
			grid_previous_position = t.grid_pos
			global_position = t.global_position
			state_machine.goto("Idle")
		return
	
	#################################
	#START OF MOVED STATEMACHINE LOGIC
	#################################
	
	var facing_pos = grid_pos + get_facing_dir()
	var facing_tile = raft.get_tile(facing_pos.y, facing_pos.x)
	var facing_obj = facing_tile.tile_object if facing_tile else null
	
	#if this._player_input.direction == Vector2i.ZERO: # gotta check what _player_input is again
		#push_delay_remaining = move_delay_time
	#else:
		#if facing_obj: # start pushing
			#push_delay_remaining -= delta
			#if push_delay_remaining <= 0:
				#push_delay_remaining = 0.0
				#if facing_obj.push(this.grid_pos):
					#goto("Walking", this._player_input.direction)
					#return
		#elif facing_tile: # simply walk
			#goto("Walking", this._player_input.direction)
			#return
	if _player_input.direction == Vector2i.ZERO:
		push_delay_ticks_remaining = move_delay_time_ticks
	else:
		if facing_obj: # start pushing
			push_delay_ticks_remaining -= 1
			if push_delay_ticks_remaining <= 0:
				facing_obj.push(grid_pos)
				if global_position == target_pos:
					grid_pos += _player_input.direction
					target_pos = raft.grid_pos_to_global_position(grid_pos)
		elif facing_tile: # simply walk
			if global_position == target_pos:
				grid_pos += _player_input.direction
				target_pos = raft.grid_pos_to_global_position(grid_pos)
	
	
	global_position = global_position.move_toward(target_pos, 300 * (1.0/60.0))

func _save_state() -> Dictionary:
	return {
		grid_pos = grid_pos,
		#position = position,
		#grid_facing = grid_facing
		last = _player_input
	}

func _load_state(state: Dictionary) -> void:
	#position = state['position']
	grid_pos = state['grid_pos']
	#grid_facing = state['grid_facing']
	_player_input = state['last']

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

func update_facing():
	if _player_input.direction.x < 0:
		grid_facing = FACING_LEFT
	if _player_input.direction.x > 0:
		grid_facing = FACING_RIGHT
	if _player_input.direction.y < 0:
		grid_facing = FACING_UP
	if _player_input.direction.y > 0:
		grid_facing = FACING_DOWN

func get_facing_object():
	var f = grid_pos + get_facing_dir()
	var tile = raft.get_tile(f.y, f.x)
	if tile == null:
		return null
	if tile.tile_object and tile.tile_object.state != 0:
		return null
	return tile.tile_object

func _what_tile():
	return raft.get_tile(grid_pos.y, grid_pos.x)

func disable():
	state_machine.goto("Disabled")

func release():
	state_machine.goto("Idle")

func add_tile(tile: Node):
	nearby_tiles.append(tile)

func remove_tile(tile: Node):
	nearby_tiles.erase(tile)

func _enter_tree() -> void:
	set_multiplayer_authority(player_id)

func _network_spawn(data: Dictionary) -> void:
	player_id = data["id"]
	raft = $"../../player_raft"
	position = Vector2(0, 0)
	
	if not raft:
		push_error("Character has no raft :(")
		queue_free()
		return
	
	var t = raft.get_tile_at(position)
	if t != null:
		grid_pos = t.grid_pos
	else:
		grid_pos = raft.get_closest_empty_tile(position).grid_pos
	
	position = raft.grid_pos_to_global_position(grid_pos)
	target_pos = position
