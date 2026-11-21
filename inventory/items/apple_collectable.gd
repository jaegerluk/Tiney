extends StaticBody2D

@export var item: InvItem
var player = null


func playercollect():
	player.collect_item(item)		


func _on_iteractable_area_body_entered(body):
		if body.has_method("player"):
			player = body
			playercollect()
			await get_tree().create_timer(0.1).timeout
			self.queue_free()
