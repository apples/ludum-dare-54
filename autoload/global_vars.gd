extends Node

enum {
	DIFF_EASY,
	DIFF_MED,
	DIFF_HARD,
}

var score = 0
var level = 1
var upgradeCharges = 0
var match3_paused = false # no longer pause on raft upgrade
var difficulty = DIFF_MED

var frame_params = [0, 0]

var mouse_held = false # does this belong here? No. Is it here anyway? Yes
