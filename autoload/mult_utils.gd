extends Node

var current_rand = 10: # will be off if sync does not occur before first call
	get:
		var r = current_rand
		current_rand = rand_from_seed(current_rand)[0]
		return r

var is_hosting := false

var mult_name := ""

var ip_target := "127.0.0.1"
