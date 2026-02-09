extends CanvasLayer

# --- UI References ---
@onready var mask_hud: TextureRect = $MaskHUD
@onready var health_bar: ProgressBar = $HealthBar # Ensure this name matches your scene node
@onready var masked_state_cooldown: TextureProgressBar = $MaskedStateCooldown
@onready var player: Player = %Player
var shards_count: Label

# --- Textures ---
@export var unmasked_hud_tex: Texture = preload("res://assets/User Interface/Game HUD (Masked).png")
@export var masked_hud_tex: Texture = preload("res://assets/User Interface/Game HUD (Unmasked).png")

# Variable to track the animation so we can interrupt it if hit again quickly
var health_tween: Tween

func _ready() -> void:
	shards_count = get_node_or_null("ShardsCount")

	# 1. Initialize Health Bar to match PlayerManager data immediately
	if health_bar:
		health_bar.max_value = PlayerManager.base_health
		health_bar.value = PlayerManager.current_health
	
	# 2. Connect to the Player's state signals
	if player:
		# If the signal is already connected (re-loading), disconnect first to avoid duplicates
		if player.element_toggled.is_connected(_on_player_element_toggled):
			player.element_toggled.disconnect(_on_player_element_toggled)
		player.element_toggled.connect(_on_player_element_toggled)
		
		# Set initial visual state based on player's current element
		_on_player_element_toggled(player.is_light)
	
	# 3. Connect to PlayerManager for health updates
	if PlayerManager.health_changed.is_connected(_on_player_health_changed):
		PlayerManager.health_changed.disconnect(_on_player_health_changed)
	PlayerManager.health_changed.connect(_on_player_health_changed)
	
	if PlayerManager.shards_count_changed.is_connected(_on_shards_count_changed):
		PlayerManager.shards_count_changed.disconnect(_on_shards_count_changed)
	PlayerManager.shards_count_changed.connect(_on_shards_count_changed)
	
	if player and masked_state_cooldown:
		masked_state_cooldown.max_value = player.max_light_time
		masked_state_cooldown.value = player.light_timer

func _process(_delta: float) -> void:
	if not player or not masked_state_cooldown: return

	# 1. Update the bar value first for smoothness
	masked_state_cooldown.value = player.light_timer

	if player.is_light:
		# --- Blinking Logic ---
		if player.light_timer <= 2.5:
			# Calculate blink speed: increases as time gets lower
			# Use a sine wave: (sin(time * speed) + 1) / 2 maps -1,1 to 0,1
			var speed = 15.0 # Higher is faster
			var blink = (sin(Time.get_ticks_msec() * 0.001 * speed) + 1.0) / 2.0
			
			# Modulate between faint (0.2) and bright (1.0)
			var alpha = lerp(0.2, 0.8, blink)
			masked_state_cooldown.modulate = Color(1.0, 1.0, 1.0, alpha)
		else:
			# Steady state when plenty of time remains
			masked_state_cooldown.modulate = Color(1.0, 1.0, 1.0, 0.2)
			
	else:
		# --- Dark State Logic ---
		if player.light_timer < player.min_light_time:
			# Dimmed Red or Black to indicate "Not ready yet"
			masked_state_cooldown.modulate = Color(0.0, 0.0, 0.0, 0.8) 
		else:
			# Default Dark state
			masked_state_cooldown.modulate = Color(0.0, 0.0, 0.0, 0.3)
		
func _on_shards_count_changed():
	if shards_count:
		shards_count.text = str(PlayerManager.shards_count)

func _on_player_element_toggled(is_light: bool) -> void:
	if mask_hud:
		# is_light usually corresponds to the 'Unmasked' default state
		mask_hud.texture = unmasked_hud_tex if is_light else masked_hud_tex

# --- Meticulous Health Update Logic ---
func _on_player_health_changed(new_health: int) -> void:
	if not health_bar: return
	
	# 1. Kill any existing animation to prevent "jitter" if hit rapidly
	if health_tween:
		health_tween.kill()
	
	# 2. Create a new Tween for smooth interpolation
	health_tween = create_tween()
	
	# 3. Animate 'value' from current to 'new_health' over 0.4 seconds
	# .set_trans(Tween.TRANS_SINE) provides a professional, non-linear feel
	health_tween.tween_property(health_bar, "value", new_health, 0.4)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
