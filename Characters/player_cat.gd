extends CharacterBody2D

class_name Player

signal healthchanged

@export var move_speed : float = 100
@export var starting_direction : Vector2 = Vector2(0,1)
@export var inventory: Inv

# parameters/idle/blend_position

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var sprite = $Sprite2D 
#@onready var healthbar = $CanvasLayer/Health_Bar
#@onready var healthbar = $Health_Bar

var enemy_in_attack_range = false
var enemy_attack_cooldown = true
@export var maxhealth = 200
@export var health = 200
var player_alive = true
var attack_in_progress = false

var dir = 'none'


func _ready():
	update_animation_parameters(starting_direction)
	set_dir(starting_direction)
	#healthbar.max_value = maxhealth

func _physics_process(_delta):
	# get input direction
	var input_direction = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength('down') - Input.get_action_strength("up")
	)
	set_dir(input_direction)
	
	
	update_animation_parameters(input_direction)
	
	# update velocity
	velocity = input_direction * move_speed
	# move and slide function
	move_and_slide()
		

	attack(input_direction)
	pick_new_state()
	enemy_attack()
	#update_health_bar()
	
	if health <= 0:
		player_alive = false #endscreen
		health = 0
		print("Player died in pain")

func update_animation_parameters(move_input : Vector2):
	#don't change animation parameters if there is no move input
	if(move_input != Vector2.ZERO):
		if(move_input.x < 0):
			sprite.flip_h = true
		else:
			sprite.flip_h = false
		animation_tree.set("parameters/idle/blend_position", move_input)
		animation_tree.set("parameters/walk/blend_position", move_input)
		
# choose state based on what is happening with player
func pick_new_state():
	if(velocity != Vector2.ZERO):
		state_machine.travel("walk")
	else:
		state_machine.travel("idle")
	#if attack_in_progress:
	#	state_machine.travel("small_attack")
	
func set_dir(input_direction):
	if input_direction.x > 0:
		dir = "right"
	elif input_direction.x < 0:
		dir = "left"
	elif input_direction.y < 0:
		dir = 'up'
	elif input_direction.y > 0:
		dir = 'down'

func player():
	pass

func _on_player_hitbox_body_entered(body):
	if body.has_method("enemy"):
		enemy_in_attack_range = true


func _on_player_hitbox_body_exited(body):
	if body.has_method("enemy"):
		enemy_in_attack_range = false	#was bei mehreren enemys?

func enemy_attack():
	if enemy_in_attack_range and enemy_attack_cooldown:
		health = health - 20
		enemy_attack_cooldown = false
		$take_attack_cooldown.start()
		print(health)
		healthchanged.emit()


func _on_attack_cooldown_timeout():
	enemy_attack_cooldown = true
	
func attack(input_direction):
	if Input.get_action_raw_strength("attack"):
		Global.player_current_attack = true
		attack_in_progress = true
		#if input_direction.x > 0
		if dir == "right":
			sprite.flip_h = false
			$AnimationPlayer.play("attack_right")
			$deal_attack_timer.start()
		if dir == 'left':
			sprite.flip_h = true
			$AnimationPlayer.play("attack_right")
			$deal_attack_timer.start()
		if dir == 'down':
			$AnimationPlayer.play("attack_down")
			$deal_attack_timer.start()
		if dir == 'up':
			$AnimationPlayer.play("attack_up")
			$deal_attack_timer.start()
	
	#animation_tree.set("parameters/small_attack/blend_position", input_direction)


func _on_deal_attack_timer_timeout():
	$deal_attack_timer.stop()
	Global.player_current_attack = false
	attack_in_progress = false
	
#func update_health_bar():
#	healthbar.value = health
	
func collect_item(item):
	inventory.insert(item)


