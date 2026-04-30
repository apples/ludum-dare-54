extends CharacterBody2D

@export var raft: Node

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hold_root = $HoldRoot
@onready var grab_area = $GrabArea
@onready var state_machine: StateMachine = $StateMachine

@onready var gameplay_scene = $"../../"

var upgrade_select_scene = preload("res://scenes/upgrade_select/upgrade_select.tscn")

var grid_pos : Vector2i:
	set(v):
		var t = _what_tile()
		if t:
			t.player_obj = null
		grid_pos = v
		t = _what_tile()
		if t:
			t.player_obj = self

var last_direction := Vector2i()

enum {
	FACING_UP,
	FACING_DOWN,
	FACING_LEFT,
	FACING_RIGHT,
}

var grid_facing: int = FACING_DOWN

var push_delay: float = 0.0

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

#keep mouse tracking here, send actual mouse ACTIONS in mult input
var mouse_start_pos: Vector2
var mouse_dist: Vector2 = Vector2(0, 0)
var mouse_down_timer: float = 0
var mouse_down_activation_time: float = 1 # pop in settings?
var mouse_move_activation_dist: float = 100 # pop in settings?

var player_id = 1

var target_pos: Vector2 = grid_pos
var last_grid_pos: Vector2i = grid_pos
var move_delay_time_ticks := 6 # really this should be configurable in the options, 6 = 0.1 seconds
var push_delay_ticks_remaining := 0
var move_speed_ticks := 0
var move_speed_ticks_target := 32

var upgrading = false

func is_standing() -> bool:
	return state_machine.current_state.name == "Idle"

func _get_local_input() -> Dictionary:
	var input := {}
	input["left"] = Input.is_action_pressed("left")
	input["right"] = Input.is_action_pressed("right")
	input["up"] = Input.is_action_pressed("up")
	input["down"] = Input.is_action_pressed("down")
	input["interactPressed"] = Input.is_action_just_pressed("interact")
	input["cancelPressed"] = Input.is_action_just_pressed("cancel")
	input["executePressed"] = Input.is_action_just_pressed("execute")
	return input

#seems like this would be necessary, but also seems to work fine without
#func _predict_remote_input(previous_input: Dictionary, ticks_since_real_input: int) -> Dictionary:
	#var input = previous_input.duplicate()
	#input.erase("interactPressed")
	#input.erase("cancelPressed")
	#input.erase("executePressed")
	#return input

func _process(_delta):
	if Input.is_action_just_pressed("execute") and GLOBAL_VARS.upgradeCharges > 0 and is_multiplayer_authority(): #seems like a possible race condition
		var upgrade_select = upgrade_select_scene.instantiate()
		upgrade_select.upgrade_type = "base"
		upgrade_select.player = self
		upgrade_select.initiate_module_placement.connect(gameplay_scene.on_initiate_module_placement)
		gameplay_scene.add_child(upgrade_select)

func _player_special_process(_delta) -> void:
	pass

func _network_process(input: Dictionary):
	if not input:
		return
	
	if input["executePressed"] and GLOBAL_VARS.upgradeCharges > 0 and !upgrading:
		upgrading = true
		GLOBAL_VARS.upgradeCharges -= 1
	
	if upgrading:
		return # this might stop player mid tile transition
	
	# directional input - cardinal directions only
	var lr: int = (1 if input["right"] else 0) - (1 if input["left"] else 0)
	var ud: int = (1 if input["down"] else 0) - (1 if input["up"] else 0)
	var direction := Vector2i(lr, ud)
	
	if direction.x != 0 and direction.y != 0:
		direction.y = 0
	assert(direction.x == 0 or direction.y == 0)
	
	
	update_facing(direction)
	
	# special process (usually for debug)
	_player_special_process(.017)
	
	# failsafe in case player gets off the raft somehow
	if not _what_tile():
		var t = raft.get_random_empty_tile()
		if t:
			grid_pos = t.grid_pos
			global_position = t.global_position
			state_machine.goto("Idle")
		return
	
	
	# movement + placement
	var facing_pos = grid_pos + get_facing_dir()
	var facing_tile = raft.get_tile(facing_pos.y, facing_pos.x)
	var standing_tile = raft.get_tile(grid_pos.y, grid_pos.x)
	var facing_obj = facing_tile.tile_object if facing_tile else null
	var interact_disabled = false
	
	if direction == Vector2i.ZERO:
		push_delay_ticks_remaining = move_delay_time_ticks
	else:
		if facing_obj: # start pushing
			push_delay_ticks_remaining -= 1
			if push_delay_ticks_remaining <= 0:
				if facing_obj.push(grid_pos):
					if move_speed_ticks >= move_speed_ticks_target:
						last_grid_pos = grid_pos
						grid_pos += direction
						#target_pos = raft.grid_pos_to_global_position(grid_pos)
						move_speed_ticks = 0
		elif facing_tile and not held_object: # simply walk
			if move_speed_ticks >= move_speed_ticks_target:
				last_grid_pos = grid_pos
				grid_pos += direction
				#target_pos = raft.grid_pos_to_global_position(grid_pos)
				move_speed_ticks = 0
	
	if standing_tile.is_on_fire:
		interact_disabled = true
	
	
	if not held_object: # try to pickup an object
		if not interact_disabled and input["interactPressed"]:
			if facing_obj and facing_obj.is_holdable: # pick up item from raft
				raft.pickup_object(facing_obj.grid_pos)
				held_object = facing_obj
				facing_obj.position = Vector2.ZERO
				interact_disabled = true
				state_machine.goto("Holding")
			elif not facing_obj: # pick up item from buoy
				grab_area.global_position = raft.grid_pos_to_global_position(facing_pos)
				if grab_area.has_overlapping_areas():
					var buoy = grab_area.get_overlapping_areas()[0]
					held_object = buoy.item
					buoy.queue_free()
					held_object.position = Vector2.ZERO
					interact_disabled = true
					state_machine.goto("Holding")
	else: # try to place an object
		if input["interactPressed"]: # swap-drop held object
			if facing_tile and not facing_obj:
				var current_tile = _what_tile()
				var obj = held_object
				held_object = null
				raft.place_object(current_tile.grid_pos, obj)
				obj.position = Vector2.ZERO
				last_grid_pos = grid_pos
				grid_pos += get_facing_dir()
				#target_pos = raft.grid_pos_to_global_position(grid_pos)
				move_speed_ticks = 0
				state_machine.goto("Idle")
		if last_direction != direction and direction != Vector2i.ZERO: # forward-drop held object
			if facing_tile and not facing_obj:
				var obj = held_object
				held_object = null
				raft.place_object(facing_tile.grid_pos, obj)
				obj.position = Vector2.ZERO
				state_machine.goto("Idle")
	
	#global_position = global_position.move_toward(target_pos, 300 * (1.0/60.0))
	move_speed_ticks += 4
	global_position = lerp(
		raft.grid_pos_to_global_position(last_grid_pos),
		 raft.grid_pos_to_global_position(grid_pos),
		 clampf(float(move_speed_ticks) / float(move_speed_ticks_target), 0.0, 1.0))
	
	last_direction = direction

func _save_state() -> Dictionary:
	return {
		grid_pos = grid_pos,
		last_grid_pos = last_grid_pos,
		move_speed_ticks = move_speed_ticks,
		grid_facing = grid_facing,
		last_direction = last_direction,
		upgrading = upgrading, #does this need to be in state? who knows
	}

func _load_state(state: Dictionary) -> void:
	grid_pos = state['grid_pos']
	last_grid_pos = state['last_grid_pos']
	move_speed_ticks = state['move_speed_ticks']
	grid_facing = state['grid_facing']
	last_direction = state['last_direction']
	upgrading = state['upgrading']

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

func update_facing(dir):
	if dir.x < 0:
		grid_facing = FACING_LEFT
	if dir.x > 0:
		grid_facing = FACING_RIGHT
	if dir.y < 0:
		grid_facing = FACING_UP
	if dir.y > 0:
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

@rpc("any_peer", "call_local", "reliable")
func reset():
	upgrading = false

func _enter_tree() -> void:
	set_multiplayer_authority(player_id)

func _network_spawn(data: Dictionary) -> void:
	player_id = data["id"]
	raft = $"../../player_raft"
	position = Vector2(478, 288)
	raft.players.append(self)
	
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
	last_grid_pos = grid_pos
	#target_pos = position
