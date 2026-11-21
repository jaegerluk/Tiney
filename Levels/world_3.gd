extends Node2D

func _process(delta):
	change_scenes()

func _ready():
	pass

func _on_area_2d_body_entered(body):
	if body.has_method("player"):
		Global.transition_scene = true
		Global.world1toworld3warp = true


func _on_area_2d_body_exited(body):
	if body.has_method("player"):
		Global.transition_scene = false

func change_scenes():
	if Global.transition_scene:
		print("from world 3")
		print(Global.current_scene)
		if Global.current_scene == "world3":
			get_tree().change_scene_to_file("res://Levels/game_level.tscn")
			$Player.position.x = -138
			$Player.position.y = -60
			Global.finish_changescenes()
