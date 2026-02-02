extends StateMachineState

var last_input_dir: Vector2i
var move_delay_time := 0.09 # really this should be configurable in the options
var push_delay_remaining := 0.0
var interact_disabled := false

func _enter_state(_param):
	pass

func _process_always(_delta):
	if not Input.is_action_pressed("interact"):
		interact_disabled = false

func _process(_delta):
	if !this.raft:
		return
	
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


func _physics_process(_delta):
	pass

func _exit_state():
	pass
