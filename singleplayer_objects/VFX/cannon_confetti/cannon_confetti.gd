extends Node2D

@onready var blast_fx = $BlastFX

var extra_shot := false

func _ready():
	if extra_shot:
		self_modulate = Color.TRANSPARENT


func blast():
	blast_fx.emitting = true


func _on_timer_timeout():
	queue_free()

