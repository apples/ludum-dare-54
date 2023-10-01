extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	$gem_sparkle_sprite.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func _on_timer_timeout():
	self.queue_free()
