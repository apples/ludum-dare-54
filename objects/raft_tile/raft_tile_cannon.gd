extends RaftTile


func interact(player):
	player.sit()
	print("Player interacted with CANNON LETS GOOOO at <%s, %s>." % [row_index, column_index])

