extends MultiplayerSpawner


func _init() -> void:
	spawn_function = _spawn_function

func _spawn_function(data) -> Node:
	var player = load(get_spawnable_scene(0)).instantiate()
	player.name = "Player%s" % [data.id]
	player.player_id = data.id
	player.raft = $"../player_raft"
	player.position = Vector2(478, 288)
	
	#player.set_multiplayer_authority(multiplayer.get_unique_id())
	
	# z index?
	#player.game_world = get_parent()
	$"../player_raft".players.append(player)
	
	
	return player
