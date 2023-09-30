extends "res://objects/character/character.gd"

@export var idle_sprite: Texture2D
@export var sit_sprite: Texture2D
@export var swim_sprite: Texture2D
@export var fix_sprite: Texture2D

@export var raft: Node

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
var grid_lerp_speed := 8.0
var grid_buffered_input: Vector2i = Vector2i.ZERO

func _ready():
	if is_grid_based:
		var t = raft.get_tile_at(position)
		if t != null:
			grid_current_position = t.grid_pos
		else:
			grid_current_position = raft.get_closest_empty_tile(position).grid_pos
		
		position = raft.rc_to_pos(grid_current_position)

func _process(delta):
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
	
	if Input.is_action_just_pressed("interact"):
		nearby_tiles.sort_custom(func (a, b):
			return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
		)
		if nearby_tiles.size() > 0:
			nearby_tiles[0].interact(self)

func _process_sit(delta):
	pass

func _process_fix(delta):
	pass

func _process_swim(delta):
	if _what_tile() != null:
		_change_state(STATE_IDLE)

func _change_state(s):
	print(s)
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
			$Sprite.texture = idle_sprite
			current_speed = walk_speed
		STATE_FIX:
			$Sprite.texture = fix_sprite
			current_speed = walk_speed
			move_input_disabled = true
			current_speed = 0
		STATE_SIT:
			$Sprite.texture = sit_sprite
			move_input_disabled = true
			current_speed = 0
		STATE_SWIM:
			$Sprite.texture = swim_sprite
			current_speed = swim_speed

func _what_tile():
	var t = $RayCast2D.get_collider()
	return t

func _physics_process(delta):
	if move_input_disabled:
		velocity = Vector2.ZERO
		return
	
	var lr = Input.get_axis("left", "right")
	var ud = Input.get_axis("up", "down")
	var move_input = Vector2(lr, ud)
	
	if is_grid_based:
		if move_input and grid_lerp_t >= 1.0:
			var dir := Vector2i()
			if lr < 0:
				dir = Vector2i(-1,0)
			if lr > 0:
				dir = Vector2i(1,0)
			if ud < 0:
				dir = Vector2i(0,-1)
			if ud > 0:
				dir = Vector2i(0,1)
			assert(dir)
			grid_buffered_input = dir
		
		if grid_lerp_t < 1.0:
			var dir := Vector2i()
			if Input.is_action_just_pressed("left"):
				dir = Vector2i(-1,0)
			if Input.is_action_just_pressed("right"):
				dir = Vector2i(1,0)
			if Input.is_action_just_pressed("up"):
				dir = Vector2i(0,-1)
			if Input.is_action_just_pressed("down"):
				dir = Vector2i(0,1)
			if dir:
				grid_buffered_input = dir
		
		if grid_lerp_t >= 1.0 and grid_buffered_input != Vector2i.ZERO:
			var next_grid_position = grid_current_position + grid_buffered_input
			var next_tile = raft.get_tile(next_grid_position.y, next_grid_position.x)
			if next_tile != null:
				grid_previous_position = grid_current_position
				grid_current_position = next_grid_position
				grid_lerp_t = 0
			grid_buffered_input = Vector2i.ZERO
	else:
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
