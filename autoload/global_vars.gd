extends Node

enum {
	DIFF_EASY,
	DIFF_MED,
	DIFF_HARD,
}

enum object_type{
	WOOD,
	WATER,
	HAMMER,
	CANNON,
	BOMB,
	GEM
}

var score = 0
var level = 1
var upgradeCharges = 0
var match3_paused = false # no longer pause on raft upgrade
var difficulty = DIFF_HARD

var frame_params = [0, 0]

var mouse_held = false # does this belong here? No. Is it here anyway? Yes
