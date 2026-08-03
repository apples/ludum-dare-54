extends Node


func _on_timer_timeout():
	self.queue_free()
