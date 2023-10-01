extends CharacterBody2D

@export var raft: Node

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

enum {
	STATE_IDLE,
	STATE_SIT,
	STATE_SWIM,
	STATE_FIX,
}

var nearby_tiles = []

var move_input_disabled := false

var state: int = STATE_IDLE

var walk_speed := 300
var swim_speed := 100

var current_speed := walk_speed

var is_grid_based := true

var grid_previous_position : Vector2i
var grid_current_position : Vector2i
var grid_lerp_t := 1.0
var grid_lerp_speed := 12.0
var grid_buffered_input: Vector2i = Vector2i.ZERO

enum {
	FACING_UP,
	FACING_DOWN,
	FACING_LEFT,
	FACING_RIGHT,
}

var grid_facing: int = FACING_DOWN

class InputState:
	var up: bool
	var down: bool
	var left: bool
	var right: bool
	var interact: bool
	var cancel: bool
	
	func _to_string():
		return "%s, %s, %s, %s, %s, %s" % [up, down, left, right, interact, cancel]

var _player_input: InputState = InputState.new()
var _player_input_pressed: InputState = InputState.new()
var _player_input_released: InputState = InputState.new()

func eat_inputs():
	for k in ["up", "down", "left", "right", "interact", "cancel"]:
		_player_input_pressed[k] = false
		_player_input_released[k] = false

func is_action_pressed(name: String) -> bool:
	return _player_input[name]

func is_action_released(name: String) -> bool:
	return not _player_input[name]

func is_action_just_pressed(name: String) -> bool:
	return _player_input_pressed[name]

func is_action_just_released(name: String) -> bool:
	return _player_input_released[name]

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
	
	if is_grid_based:
		var t = raft.get_tile_at(position)
		if t != null:
			grid_current_position = t.grid_pos
		else:
			grid_current_position = raft.get_closest_empty_tile(position).grid_pos
		
		position = raft.rc_to_pos(grid_current_position)

func _process(delta):
	var input = _get_player_input()
	for k in ["up", "down", "left", "right", "interact", "cancel"]:
		_player_input_pressed[k] = input[k] and not _player_input[k]
		_player_input_released[k] = not input[k] and _player_input[k]
		_player_input[k] = input[k]
	
	if is_grid_based:
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
		STATE_SWIM: _process_swim(delta)
		STATE_FIX: _process_fix(delta)

func _process_idle(delta):
	if move_input_disabled:
		return
	
	if not _what_tile():
		_change_state(STATE_SWIM)
		return
	
	if _player_input_pressed.interact:
		nearby_tiles.sort_custom(func (a, b):
			return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
		)
		var tile = raft.get_tile(grid_current_position.y, grid_current_position.x)
		if tile != null and tile.tile_object != null:
			tile.tile_object.interact(self)
	
	match grid_facing:
		FACING_LEFT:
			anim.play("left")
		FACING_RIGHT:
			anim.play("right")
		FACING_UP:
			anim.play("up")
		FACING_DOWN:
			anim.play("down")

func _process_sit(delta):
	pass

func _process_fix(delta):
	pass

func _process_swim(delta):
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

func _what_tile():
	var t = $RayCast2D.get_collider()
	return t

func _physics_process(delta):
	if move_input_disabled:
		velocity = Vector2.ZERO
		return
	
	if is_grid_based:
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
		
		if grid_lerp_t >= 1.0 and grid_buffered_input != Vector2i.ZERO:
			if grid_buffered_input.x < 0:
				grid_facing = FACING_LEFT
			if grid_buffered_input.x > 0:
				grid_facing = FACING_RIGHT
			if grid_buffered_input.y < 0:
				grid_facing = FACING_UP
			if grid_buffered_input.y > 0:
				grid_facing = FACING_DOWN
			var next_grid_position = grid_current_position + grid_buffered_input
			var next_tile = raft.get_tile(next_grid_position.y, next_grid_position.x)
			if next_tile and next_tile.tile_object:
				if next_tile.tile_object.is_pushable:
					if not next_tile.tile_object.push(grid_current_position):
						next_tile = null
			if next_tile != null:
				grid_previous_position = grid_current_position
				grid_current_position = next_grid_position
				grid_lerp_t = 0
			grid_buffered_input = Vector2i.ZERO
	else:
		var lr = (1.0 if _player_input.right else 0.0) - (1.0 if _player_input.left else 0.0)
		var ud = (1.0 if _player_input.down else 0.0) - (1.0 if _player_input.up else 0.0)
		var move_input = Vector2(lr, ud)
		if move_input:
			velocity = move_input.normalized() * current_speed
		else:
			velocity = Vector2.ZERO
		
		move_and_slide()

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
