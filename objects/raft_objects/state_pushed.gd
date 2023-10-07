extends StateMachineState

var push_speed := 32.0 * 12.0

func _enter_state(_param):
	pass

func _process(delta):
	this.position = this.position.move_toward(Vector2.ZERO, push_speed * delta)
	if this.position == Vector2.ZERO:
		goto("Idle")

func _physics_process(_delta):
	pass

func _exit_state():
	pass

