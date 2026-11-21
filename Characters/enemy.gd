extends CharacterBody2D
#verfolgt player, wenn in detection_area

@export var move_speed = 50		#je größer desto langsamer
var player = null
var player_chase = false

@export var maxhealth = 100
@export var health = 100
var player_inattack_zone = false
var can_take_damage = true

func _init():
	health = maxhealth

func _physics_process(delta):
	deal_with_damage()
	update_health()
	
	if player_chase:
		position += (player.position - position)/move_speed
		
		$AnimatedSprite2D.play("walk")
		if(player.position.x - position.x < 0):
			$AnimatedSprite2D.flip_h = true
		if(player.position.x - position.x >= 0):
			$AnimatedSprite2D.flip_h = false
		
	else:
		$AnimatedSprite2D.play("idle")
	move_and_collide((Vector2(0,0)))		#enemy kollidiert mit wänden


func _on_detection_area_body_entered(body):
	player = body
	player_chase = true


func _on_detection_area_body_exited(body):
	player = null
	player_chase = false

func enemy():	#für detection von player
	pass


func _on_enemy_hitbox_body_entered(body):
	if body.has_method("player"):
		player_inattack_zone = true


func _on_enemy_hitbox_body_exited(body):
	if body.has_method("player"):
		player_inattack_zone = false

func deal_with_damage():
	if player_inattack_zone and Global.player_current_attack:
		if can_take_damage:
			health = health - 20
			$take_damage_cooldown.start()
			can_take_damage = false
			print("slime health = ", health)
			if health <= 0:
				#$AnimatedSprite2D.play("death")
				self.queue_free()

func update_health():
	var healthbar = $health_bar
	healthbar.value = health
	if health >= maxhealth:
		healthbar.visible = false
	else:
		healthbar.visible = true
	
	
func _on_take_damage_cooldown_timeout():
	can_take_damage = true
