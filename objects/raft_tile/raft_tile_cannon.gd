extends RaftTile

@export var target_starting_pos = Vector2(400, 0)
@export var reticle_speed = 5

var connected_player
var reticle
var target = target_starting_pos

func _process(delta):
	if not connected_player:
		return
	elif Input.is_action_just_pressed("interact"):
		connected_player.call_deferred("_change_state", PlayerCharacter.STATE_IDLE)
		reticle.queue_free()
		reticle = null
		connected_player = null
		
	
func _physics_process(delta):
	if not connected_player:
		return
	
	var velocity = Vector2.ZERO
	var lr = Input.get_axis("left", "right")
	var ud = Input.get_axis("up", "down")
	var move_input = Vector2(lr, ud)
	if move_input:
		target += move_input.normalized() * reticle_speed
	reticle.position = target
	

func interact(player: PlayerCharacter):
	connected_player = player
	player._change_state(PlayerCharacter.STATE_SIT)
	reticle = Sprite2D.new()
	reticle.texture = preload("res://assets/textures/reticle.png")
	reticle.position = target
	add_child(reticle)
	print("Player interacted with CANNON LETS GOOOO at <%s, %s>." % [row_index, column_index])

