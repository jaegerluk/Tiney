extends Node

var player_current_attack = false #is player currently attacking?

var current_scene = "game_level"
var transition_scene = false

var player_exit_cliffside_pos_x = -59
var player_exit_cliffside_pos_y = -230
var player_start_pos_x = 0
var player_start_pos_y = 0
var player_world3_start_pos_x = -138
var player_woröd3_start_pos_y = -60

var game_first_loadin = true

var world1toworld3warp = false
var world3toworld1warp = false

func finish_changescenes():
	print(1)
	#if transition_scene:
	print(current_scene)
	transition_scene = false
	if current_scene == "game_level":
		print(Global.world1toworld3warp)
		if world1toworld3warp:
			current_scene = "world3"
			world1toworld3warp = false
		else:
			current_scene = "world2"
		print(current_scene)
	else:	#für 2 scenen so
		print("ass")
		current_scene = "game_level"
