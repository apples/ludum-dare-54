extends StateMachineState

func _enter_state(_param):
	this.anim.pause()
	#this.current_speed = this.walk_speed

func _process(_delta):
	#this.update_facing()
	
	#var facing_pos = this.grid_pos + this.get_facing_dir()
	#var facing_tile = this.raft.get_tile(facing_pos.y, facing_pos.x)
	#var facing_obj = facing_tile.tile_object if facing_tile else null
	
	match this.grid_facing:
		this.FACING_LEFT:
			this.anim.play("hold_left")
		this.FACING_RIGHT:
			this.anim.play("hold_right")
		this.FACING_UP:
			this.anim.play("hold_up")
		this.FACING_DOWN:
			this.anim.play("hold_down")
	
	# swap-drop held object
	#if this.is_action_just_pressed("interact"):
		#if facing_tile and not facing_obj:
			#var current_tile = this._what_tile()
			#var obj = this.held_object
			#this.held_object = null
			#this.raft.place_object(current_tile.grid_pos, obj)
			#obj.position = Vector2.ZERO
			#goto("Walking", this.get_facing_dir())
			#return
	#
	## forward-drop held object
	#if this._player_input.direction_just_changed and this._player_input.direction != Vector2i.ZERO:
		#if facing_tile and not facing_obj:
			#var obj = this.held_object
			#this.held_object = null
			#this.raft.place_object(facing_tile.grid_pos, obj)
			#obj.position = Vector2.ZERO
			#goto("Idle")
			#return
	

func _physics_process(_delta):
	pass

func _exit_state():
	pass
