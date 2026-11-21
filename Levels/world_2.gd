extends Node2D

func _process(delta):
	change_scenes()

func _on_game_level_exit_body_entered(body):
	if body.has_method("player"):
		Global.transition_scene = true


func _on_game_level_exit_body_exited(body):
	if body.has_method("player"):
		Global.transition_scene = false

func change_scenes():
	if Global.transition_scene:
		print("from world 2")
		if Global.current_scene == "world2":
			get_tree().change_scene_to_file("res://Levels/game_level.tscn")
			Global.finish_changescenes()
