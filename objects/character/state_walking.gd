extends StateMachineState

var speed := 300.0

func _enter_state(param):
	assert(param is Vector2i)
	assert(param != Vector2i.ZERO)
	this.grid_pos += param

func _process(delta):
	var current_position: Vector2 = this.global_position
	var target_position: Vector2 = this.raft.grid_pos_to_global_position(this.grid_pos)
	this.global_position = current_position.move_toward(target_position, speed * delta)
	if this.global_position == target_position:
		goto("Idle")

func _exit_state():
	this.global_position = this.raft.grid_pos_to_global_position(this.grid_pos)
