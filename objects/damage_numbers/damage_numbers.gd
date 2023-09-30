extends Node2D

var number_color = Color('ca0000')
var number_value = '-1'

# Called when the node enters the scene tree for the first time.
func _ready():
#	$number_label.modulate = number_color
	$number_label.text = number_value


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.position.y -= 0.25
	

func _on_number_expiration_timeout():
	self.queue_free()
