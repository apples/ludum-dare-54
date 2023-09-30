class_name PlayerCharacter
extends CharacterBody2D

@export var idle_sprite: Texture2D
@export var sit_sprite: Texture2D
@export var swim_sprite: Texture2D
@export var fix_sprite: Texture2D

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

func _process(delta):
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
	if move_input:
		velocity = move_input.normalized() * current_speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func add_tile(tile: Node):
	nearby_tiles.append(tile)

func remove_tile(tile: Node):
	nearby_tiles.erase(tile)
