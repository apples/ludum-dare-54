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

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
