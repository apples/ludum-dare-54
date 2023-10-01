extends Node2D

var y_dir = 0
var x_dir = 0
var tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready():
#	$number_label.modulate = number_color
	tween = create_tween()
	tween.tween_property($Sprite2D, "modulate:a", 0, 1)
	tween.play
	y_dir = randf_range(-0.5, -0.2)
	x_dir = randf_range(-0.25, 0.25)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.position.y += y_dir
	self.position.x += x_dir


func _on_smoke_expires_timeout():
	self.queue_free()
