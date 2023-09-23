extends Node2D

@onready var timerText = $Timer
@onready var timer = $SurvivalTimer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	timerText.text = str(timer.time_left)


func _on_survival_timer_timeout():
	get_tree().change_scene_to_file("res://scenes/WinScreen/Win.tscn")
