class_name Player
extends CharacterBody2D

var is_light: bool = true

@onready var state_machine: StateMachine = $StateMachine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var hitbox_shape: CollisionShape2D = $AnimatedSprite/MeleeWeaponHitbox/CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var arrow_start_position: Marker2D = $ArrowStartPosition

@export var arrow_scene: PackedScene = preload("res://scenes/players/light_arrow.tscn")

func _ready() -> void:
	state_machine.init(self)
	update_physics_layers()
	hitbox_shape.disabled = true
	
	if PlayerManager.has_signal("player_died"):
		PlayerManager.player_died.connect(_on_death)

func _physics_process(delta: float) -> void:
	state_machine.process_physics(delta)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("skill1"):
		toggle_element_state()
	
	state_machine.process_input(event)

func toggle_element_state() -> void:	
	is_light = !is_light
	update_physics_layers()
	if state_machine.current_state:
		play_animation(state_machine.current_state.animation_name)

func update_physics_layers() -> void:
	collision_layer = 0
	collision_mask = 0
	if is_light:
		set_collision_layer_value(2, true) 
		set_collision_mask_value(3, true)
		set_collision_mask_value(5, true)
	else:
		set_collision_layer_value(1, true)
		set_collision_mask_value(4, true)
		set_collision_mask_value(5, true)

func play_animation(anim_base_name: String) -> void:
	# If we are in Light state, 'attack' should be redirected to 'shoot'
	var final_base_name = anim_base_name
	if is_light and anim_base_name == "attack":
		final_base_name = "shoot"
		
	var suffix = "_light" if is_light else "_dark"
	var anim_to_play = final_base_name + suffix

	# Rest of your logic...
	if final_base_name == "attack" and not is_light:
		# Use AnimationPlayer for Dark Melee
		animation_player.play(anim_to_play)
	else:
		# Use AnimatedSprite for everything else
		animation_player.stop()
		animated_sprite.play(anim_to_play)

func _on_death() -> void:
	if has_node("StateMachine/death"):
		state_machine.change_state($StateMachine/death)

func get_speed() -> float:
	return PlayerManager.get_speed()

func get_jump_velocity() -> float:
	return PlayerManager.get_jump_velocity()

func _on_melee_weapon_hitbox_area_entered(area: Area2D) -> void:
	if area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(PlayerManager.get_damage())
		
func shoot_arrow() -> void:
	if arrow_scene:
		var arrow_instance = arrow_scene.instantiate()
		arrow_instance.global_position = arrow_start_position.global_position
		
		var mouse_pos = get_global_mouse_position()
		var shoot_dir = (mouse_pos - arrow_instance.global_position).normalized()
		
		arrow_instance.direction = shoot_dir
		arrow_instance.rotation = shoot_dir.angle()
		
		get_tree().current_scene.add_child(arrow_instance)
