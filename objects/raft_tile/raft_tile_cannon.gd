extends RaftTile


func interact(player: PlayerCharacter):
	player.input_disabled = true
	player._change_state(PlayerCharacter.STATE_SIT)
	print("Player interacted with CANNON LETS GOOOO at <%s, %s>." % [row_index, column_index])

