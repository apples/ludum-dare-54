extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if MULT_UTILS.is_hosting:
		$Lobby.create_game()
		#$Lobby.player_loaded.rpc_id(1)
	else:
		$Lobby.join_game()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

func start_game() -> void:
	$MultItemSpawner/Timer.start()
