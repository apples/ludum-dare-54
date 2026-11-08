extends Node2D

@onready var sliding_frame1 := $SlidingFrame1
@onready var sliding_frame2 := $SlidingFrame2
#@onready var clouds := $Clouds
#@onready var clouds2 := $Clouds2

var raft1 = null
var raft2 = null

var overlay_speed := 10.0
const overlay_h_len := 512

func _ready():
	#sliding_frame1.position.y = GLOBAL_VARS.frame_params[1]
	raft1 = get_node_or_null(^"/root/VersusGameplay/Raft1")
	raft2 = get_node_or_null(^"/root/VersusGameplay/Raft2")

func _process(delta):
	if raft1:
		sliding_frame1.position.y += overlay_speed * delta * raft1.boost_mult
		sliding_frame2.position.y += overlay_speed * delta * raft2.boost_mult
	else:
		sliding_frame1.position.y += overlay_speed * delta
		sliding_frame2.position.y += overlay_speed * delta
	
	while sliding_frame1.position.y >= overlay_h_len:
		sliding_frame1.position.y -= overlay_h_len
	while sliding_frame2.position.y >= overlay_h_len:
		sliding_frame2.position.y -= overlay_h_len
	
	#for keeping the sliding frame consistent between screens
	#GLOBAL_VARS.frame_params[1] = sliding_frame.position.y
	
	#clouds.position.x += delta * 10
	#clouds2.position.x += delta * 10
	#if clouds.position.x > 1344:
		#clouds.position.x -= 1152
	#if clouds2.position.x > 1344:
		#clouds2.position.x -= 1152
