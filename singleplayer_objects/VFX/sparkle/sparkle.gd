extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	$sparkle_sprite.play()


func _on_timer_timeout():
	self.queue_free()

func init( colour):
	$sparkle_sprite.modulate = colour 

func play_gem():
	$gem_sound_effect.play()

func play_hammer():
	$hammer_sound_effect.play()
	
func play_cannon():
	$cannon_sound_effect.play()
