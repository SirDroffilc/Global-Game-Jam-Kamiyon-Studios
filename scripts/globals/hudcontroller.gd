extends CanvasLayer

# --- UI References ---
@onready var mask_hud: TextureRect = $MaskHUD
@onready var health_bar: ProgressBar = $HealthBar # Ensure this name matches your scene node

# --- Textures ---
@export var unmasked_hud_tex: Texture = preload("res://assets/User Interface/Game HUD (Masked).png")
@export var masked_hud_tex: Texture = preload("res://assets/User Interface/Game HUD (Unmasked).png")

# Variable to track the animation so we can interrupt it if hit again quickly
var health_tween: Tween

func _ready() -> void:
	# 1. Initialize Health Bar to match PlayerManager data immediately
	if health_bar:
		health_bar.max_value = PlayerManager.base_health
		health_bar.value = PlayerManager.current_health
	
	# 2. Connect to the Player's state signals
	var player = get_tree().get_first_node_in_group("Player")
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
	
	print(">>> HUD: Health animated to: ", new_health)
