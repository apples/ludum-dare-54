extends "res://objects/raft_tile/raft_tile.gd"


func interact(player: PlayerCharacter):
	print("Player interacted with CANNON LETS GOOOO at <%s, %s>." % [row_index, column_index])
