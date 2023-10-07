extends StateMachineState

func _enter_state(_param):
	pass

func _process(delta):
	if this.raft and not this.connected_player and not this.held_by:
		this._process_unconnected(delta)
	else:
		this._process_connected(delta)

func _physics_process(_delta):
	pass

func _exit_state():
	pass

