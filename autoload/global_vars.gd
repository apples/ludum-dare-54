extends Node

enum {
	DIFF_EASY,
	DIFF_MED,
	DIFF_HARD,
}

var spawnables = {
	"water" : preload("res://objects/raft_objects/water_bucket.tscn"),
	"wood" : preload("res://objects/raft_objects/driftwood.tscn"),
	"bomb" : preload("res://objects/raft_objects/bomb.tscn"),
	"gem" : preload("res://objects/raft_objects/gem.tscn"),
	"hammer" : preload("res://objects/raft_objects/hammer.tscn"),
	"cannon" : preload("res://objects/raft_objects/cannon.tscn"),
}

var score = 0
var level = 1
var upgradeCharges = 1
var match3_paused = false # no longer pause on raft upgrade
var difficulty = DIFF_MED

var frame_params = [0, 0]

var mouse_held = false # does this belong here? No. Is it here anyway? Yes
