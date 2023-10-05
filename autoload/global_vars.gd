extends Node

enum {
	DIFF_EASY,
	DIFF_MED,
	DIFF_HARD,
}

var score = 0
var level = 1
var match3_paused = false
var difficulty = DIFF_HARD

var frame_params = [0, 0]
