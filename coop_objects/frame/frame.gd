extends Node2D

@onready var sliding_frame := $SlidingFrame
@onready var clouds := $Clouds
@onready var clouds2 := $Clouds2

var overlay_speed := 10.0
var overlay_h_len := 512

func _ready():
	sliding_frame.position.y = GLOBAL_VARS.frame_params[1]

func _process(delta):
	sliding_frame.position.y += overlay_speed * delta
	while sliding_frame.position.y >= overlay_h_len:
		sliding_frame.position.y -= overlay_h_len
	
	#for keeping the sliding frame consistent between screens
	GLOBAL_VARS.frame_params[1] = sliding_frame.position.y
	
	clouds.position.x += delta * 10
	clouds2.position.x += delta * 10
	if clouds.position.x > 1344:
		clouds.position.x -= 1152
	if clouds2.position.x > 1344:
		clouds2.position.x -= 1152
