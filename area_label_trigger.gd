extends Area2D

# --- References ---
@onready var label_texture: TextureRect = $CanvasLayer/Zone1

# --- Configuration ---
@export var fade_duration: float = 0.8
@export var display_time: float = 2.0
@export var slide_distance: float = 30.0 # Pixels to move up

var has_triggered: bool = false # Add this at the top
var fade_tween: Tween
var original_pos_y: float

func _ready() -> void:
	# 1. Store the starting position so we can reset it perfectly later
	original_pos_y = label_texture.position.y
	
	# 2. Ensure it starts invisible
	label_texture.modulate.a = 0.0
	
	# 3. Connect the trigger signal
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not has_triggered:
		has_triggered = true # Lock it so it never plays again
		_pop_and_fade()

func _pop_and_fade() -> void:
	# 1. Safety: Kill existing tween and reset position immediately
	if fade_tween: 
		fade_tween.kill()
	
	label_texture.position.y = original_pos_y
	label_texture.modulate.a = 0.0
	
	# 2. Initialize Tween
	fade_tween = create_tween()
	
	# --- PHASE 1: Slide Up and Fade In (Parallel) ---
	# We use set_parallel() so both move and fade happen at once
	fade_tween.set_parallel(true)
	
	# Fade to fully visible
	fade_tween.tween_property(label_texture, "modulate:a", 1.0, fade_duration)
	
	# Slide up from original position
	fade_tween.tween_property(label_texture, "position:y", original_pos_y - slide_distance, fade_duration)\
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# --- PHASE 2: Wait (Sequential) ---
	# We turn parallel off so the interval acts as a pause
	fade_tween.set_parallel(false)
	fade_tween.tween_interval(display_time)
	
	# --- PHASE 3: Fade Out ---
	fade_tween.tween_property(label_texture, "modulate:a", 0.0, fade_duration)
	
	# --- PHASE 4: Callback (Cleanup) ---
	# Reset the position in the background so it's ready for the next trigger
	fade_tween.tween_callback(func(): label_texture.position.y = original_pos_y)
	
	print(">>> AREA HUD: Displaying location label.")
