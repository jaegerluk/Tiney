extends Node2D



func _process(delta):
	change_scenes()

func _ready():
	if Global.game_first_loadin:
		$"Player Cat".position.x = Global.player_start_pos_x
		$"Player Cat".position.y = Global.player_start_pos_y
	elif Global.world1toworld3warp:
		$"Player Cat".position.x = Global.player_world3_start_pos_x
		$"Player Cat".position.y = Global.player_woröd3_start_pos_y
		Global.world3toworld1warp = false
	else:
		$"Player Cat".position.x = Global.player_exit_cliffside_pos_x
		$"Player Cat".position.y = Global.player_exit_cliffside_pos_y

func _on_world_2_transition_body_entered(body):
	print("lol")
	if body.has_method("player"):
		Global.transition_scene = true
		print(Global.current_scene)


func _on_world_2_transition_body_exited(body):
	print("uiu")
	if body.has_method("player"):
		Global.transition_scene = false
		print(Global.current_scene)

func change_scenes():
	if Global.transition_scene:
		#print("change")
		if Global.current_scene == "game_level":
			print("before")
			if Global.world1toworld3warp:
				get_tree().change_scene_to_file("res://Levels/world_3.tscn")
			else:
				get_tree().change_scene_to_file("res://Levels/world_2.tscn")
			Global.game_first_loadin = false
			print("after")
			Global.finish_changescenes() 
			


func _on_world_3_warp_body_entered(body):
	if body.has_method("player"):
		Global.transition_scene = true
		Global.world1toworld3warp = true


func _on_world_3_warp_body_exited(body):
	if body.has_method("player"):
		Global.transition_scene = false
