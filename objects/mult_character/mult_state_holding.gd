extends StateMachineState

func _enter_state(_param):
	this.anim.pause()

func _process(_delta):
	
	match this.grid_facing:
		this.FACING_LEFT:
			this.anim.play("hold_left")
		this.FACING_RIGHT:
			this.anim.play("hold_right")
		this.FACING_UP:
			this.anim.play("hold_up")
		this.FACING_DOWN:
			this.anim.play("hold_down")
	

func _physics_process(_delta):
	pass

func _exit_state():
	pass
