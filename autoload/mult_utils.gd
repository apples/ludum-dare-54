extends Node

@onready var mult_rng : NetworkRandomNumberGenerator = $NetworkRandomNumberGenerator

var is_hosting := false
var is_coop := true

var is_public := false

var mult_name := ""

var ip_target := "127.0.0.1"
const port := 12702
const max_connections = 8


@rpc("authority", "call_remote")
func sync_rng(new_seed):
	mult_rng.set_seed(new_seed)
