extends StateMachineState

var last_input_dir: Vector2i
var move_delay_time := 0.09 # really this should be configurable in the options
var push_delay_remaining := 0.0
var interact_disabled := false

func _enter_state(_param):
	this.current_speed = this.walk_speed

func _process_always(_delta):
	if not this.is_action_pressed("interact"):
		interact_disabled = false

func _process(delta):
	this.update_facing()
	
	var facing_pos = this.grid_pos + this.get_facing_dir()
	var facing_tile = this.raft.get_tile(facing_pos.y, facing_pos.x)
	var standing_tile = this.raft.get_tile(this.grid_pos.y, this.grid_pos.x)
	var facing_obj = facing_tile.tile_object if facing_tile else null
	
	match this.grid_facing:
		this.FACING_LEFT:
			this.anim.play("left")
		this.FACING_RIGHT:
			this.anim.play("right")
		this.FACING_UP:
			this.anim.play("up")
		this.FACING_DOWN:
			this.anim.play("down")
	#this.anim.pause()
	
	# try to walk or push
	if this._player_input.direction == Vector2i.ZERO:
		push_delay_remaining = move_delay_time
	else:
		if facing_obj: # start pushing
			push_delay_remaining -= delta
			if push_delay_remaining <= 0:
				push_delay_remaining = 0.0
				if facing_obj.push(this.grid_pos):
					goto("Walking", this._player_input.direction)
					return
		elif facing_tile: # simply walk
			goto("Walking", this._player_input.direction)
			return
	
	if standing_tile.is_on_fire:
		interact_disabled = true
	
	# try to pickup an object
	if not interact_disabled and not this.held_object and this.is_action_just_pressed("interact"):
		if facing_obj and facing_obj.is_holdable: # pick up item from raft
			this.raft.pickup_object(facing_obj.grid_pos)
			this.held_object = facing_obj
			facing_obj.position = Vector2.ZERO
			interact_disabled = true
			goto("Holding")
			return
		elif not facing_obj: # pick up item from buoy
			this.grab_area.global_position = this.raft.grid_pos_to_global_position(facing_pos)
			if this.grab_area.has_overlapping_areas():
				var buoy = this.grab_area.get_overlapping_areas()[0]
				this.held_object = buoy.item
				buoy.queue_free()
				this.held_object.position = Vector2.ZERO
				interact_disabled = true
				goto("Holding")
				return


func _physics_process(_delta):
	pass

func _exit_state():
	pass
