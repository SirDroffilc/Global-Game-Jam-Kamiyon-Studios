extends Node2D

# --- References ---
@onready var spawn_point: Marker2D = $SpawnPoint 
@onready var player: Player = $Player

# --- Survival Timer Logic ---
var survival_time: float = 0.0
var time_label: Label
var ui_layer: CanvasLayer # Reference needed for the bounce

# --- New Feature: Pause Menu ---
@export var pause_menu_scene: PackedScene = preload("res://scenes/pause.tscn")

func _ready() -> void:
	# --- Survival Clock Setup ---
	setup_survival_ui()
	
	# --- Fade In Feature ---
	fade_out_black()
	
	# Initial safety check
	if not is_instance_valid(player) or not is_instance_valid(spawn_point):
		push_error(">>> LEVEL ERROR: Missing Player or SpawnPoint reference!")
		return

	# Set player to starting position on start
	respawn_player()

	# Connect to the global death signal
	if PlayerManager.has_signal("player_died"):
		PlayerManager.player_died.connect(_on_global_player_died)

# --- Updated Timer Helper ---

func setup_survival_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	time_label = Label.new()
	
	# 1. Create LabelSettings
	var settings = LabelSettings.new()
	
	# 2. LOAD YOUR CUSTOM FONT HERE
	# Make sure the path matches your folder structure exactly!
	var ferrum_font = load("res://assets/Font/ferrum.otf")
	if ferrum_font:
		settings.font = ferrum_font
	else:
		push_error("SPAWNER: Could not find ferrum.otf in assets folder!")

	# 3. Apply the Styling you requested
	settings.font_size = 80             # Increased size for Ferrum
	settings.outline_size = 10          # Thick 5px+ outline
	settings.outline_color =Color.BLACK
	settings.font_color = Color.WHITE   # Pure white text
	
	# 4. Apply settings to label
	time_label.label_settings = settings
	
	# 5. Positioning and centering
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	time_label.offset_top = 80          # Lowered even more for the bigger font
	time_label.grow_horizontal = Control.GROW_DIRECTION_BOTH 
	
	ui_layer.add_child(time_label)

func _process(delta: float) -> void:
	survival_time += delta
	update_timer_display()
	
	# Smooth Bounce Logic
	# 0.003 controls speed, 15.0 controls height
	if is_instance_valid(time_label):
		var bounce = sin(Time.get_ticks_msec() * 0.003) * 15.0
		time_label.position.y = 80 + bounce

func update_timer_display() -> void:
	var minutes: int = int(survival_time / 60)
	var seconds: int = int(survival_time) % 60
	time_label.text = str(minutes) + ":" + "%02d" % seconds

# --- Visual Effects ---

func fade_out_black() -> void:
	var fade_layer = CanvasLayer.new()
	fade_layer.layer = 100 
	add_child(fade_layer)
	
	var black_rect = ColorRect.new()
	black_rect.color = Color.BLACK
	black_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(black_rect)
	
	var tween = create_tween()
	tween.tween_property(black_rect, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(fade_layer.queue_free)

# --- Input Handling for Pause ---
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): 
		toggle_pause()

func toggle_pause() -> void:
	if get_tree().paused: 
		return
		
	var pause_menu = pause_menu_scene.instantiate()
	get_tree().root.add_child(pause_menu) 
	get_tree().paused = true

func _on_global_player_died() -> void:
	await get_tree().create_timer(1.5).timeout
	respawn_player()

func respawn_player() -> void:
	survival_time = 0.0
	PlayerManager.reset_health()
	player.global_position = spawn_point.global_position
	
	if player.state_machine:
		player.state_machine.change_state(player.get_node("StateMachine/IdleState"))
	
	player.velocity = Vector2.ZERO
	player.animated_sprite.modulate = Color.WHITE
