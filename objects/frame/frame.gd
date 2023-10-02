extends Node2D

@onready var underwater = $Underwater
@onready var overlay_root = $OverlayRoot

var underwater_speed := 2.0
var overlay_speed := 10.0

var underwater_h_len := 544
var overlay_h_len := 512

func _ready():
	underwater.position.y = GLOBAL_VARS.frame_params[0]
	overlay_root.position.y = GLOBAL_VARS.frame_params[1]

func _process(delta):
	underwater.position.y += underwater_speed * delta
	while underwater.position.y >= underwater_h_len:
		underwater.position.y -= underwater_h_len
	
	overlay_root.position.y += overlay_speed * delta
	while overlay_root.position.y >= overlay_h_len:
		overlay_root.position.y -= overlay_h_len
	
	GLOBAL_VARS.frame_params[0] = underwater.position.y
	GLOBAL_VARS.frame_params[1] = overlay_root.position.y
