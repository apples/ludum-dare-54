extends Node

@onready var mult_rng : NetworkRandomNumberGenerator = $NetworkRandomNumberGenerator

var is_hosting := false

var mult_name := ""

var ip_target := "127.0.0.1"
