class_name CreditsUI
extends Control

@export_category("Configuration")
@export var credits_data: CreditsData
@export var scroll_speed: float = 50.0
@export var json_file: JSON # Optional: If they prefer JSON

@export_category("References")
@export var credits_panel: Control
@export var content_parent: Control # The node that moves
@export var back_button: Button
@export var close_panel_button: Button

@export_category("Prefabs")
@export var header_scene: PackedScene
@export var item_scene: PackedScene
@export var static_header_scene: PackedScene # The main team credits or logo

var _is_scrolling: bool = false
var _initial_y: float = 0.0

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_close_credits)
	if close_panel_button:
		close_panel_button.pressed.connect(_close_credits)
		
	if content_parent:
		_initial_y = content_parent.position.y
		
	_parse_and_generate_credits()
	
	# Start scrolling immediately for now, or wait for toggle
	toggle_credits_ui(true)

func _process(delta: float) -> void:
	if not _is_scrolling or not content_parent:
		return
		
	# Scroll "Up" means the content moves "Up" (Negative Y)
	# C# implementation: contentParent.anchoredPosition += Vector2.up * scrollSpeed
	# In Unity UI, +Y is UP.
	# In Godot Control, +Y is DOWN.
	# So to move content UP, we *subtract* Y.
	content_parent.position.y -= scroll_speed * delta
	
	# Dynamic threshold
	# Calculate total height
	var content_height: float = content_parent.size.y
	# If we use VBoxContainer, size.y should be accurate if updated
	
	# Reset if we go too high (content moves up, so y becomes very negative)
	# We want to reset when the BOTTOM of the content leaves the TOP of the screen?
	# Or when the TOP of the content leaves the TOP of the screen?
	# C#: if (anchoredPosition.y > dynamicThreshold) (Positive is UP) -> Reset to negative.
	
	# Godot: We are moving negative.
	# If position.y < -content_height - screen_buffer
	var threshold: float = -content_height - get_viewport_rect().size.y
	
	if content_parent.position.y < threshold:
		# Reset to below the screen
		content_parent.position.y = get_viewport_rect().size.y

func _input(event: InputEvent) -> void:
	if not content_parent: return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			content_parent.position.y += scroll_speed * 10 * get_process_delta_time() # Scroll down (content moves down)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			content_parent.position.y -= scroll_speed * 10 * get_process_delta_time() # Scroll up (content moves up)
	
	# Optional: Touch drag or mouse drag could be added here if needed,
	# but scroll wheel is the primary interaction for PC.


func toggle_credits_ui(value: bool) -> void:
	if credits_panel:
		credits_panel.visible = value
	_is_scrolling = value
	
	if value and content_parent:
		# Reset position
		# Start from bottom of screen (viewport height) and scroll up (negative Y)
		content_parent.position.y = get_viewport_rect().size.y

func _close_credits() -> void:
	# Toggle off
	toggle_credits_ui(false)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _parse_and_generate_credits() -> void:
	_clear_existing()
	
	# Support JSON file if provided (porting C# logic)
	if json_file:
		pass
		
	if not credits_data:
		print("[CreditsUI] No CreditsData assigned.")
		return
		
	if not content_parent:
		return
	
	# 0. Static Team Header (if assigned)
	if static_header_scene:
		var obj = static_header_scene.instantiate()
		content_parent.add_child(obj)
		
	# 1. 3D Models
	if not credits_data.models_3d.is_empty():
		_create_header("3D Models")
		for item in credits_data.models_3d:
			if not item: continue
			_create_item(item)
			
	# 2. SFX
	if not credits_data.sound_effects.is_empty():
		_add_spacer()
		_create_header("Sound Effects")
		for item in credits_data.sound_effects:
			if not item: continue
			_create_item(item)
			
	# 3. Music
	if not credits_data.music.is_empty():
		_add_spacer()
		_create_header("Music")
		for item in credits_data.music:
			if not item: continue
			_create_item(item)
			
	# Force Layout update?
	# In Godot, Container updates automatically usually.

func _clear_existing() -> void:
	if not content_parent: return
	for child in content_parent.get_children():
		child.queue_free()

func _create_header(title: String) -> void:
	if not header_scene: return
	var obj = header_scene.instantiate()
	content_parent.add_child(obj)
	
	# Attempt to find a Label or RichTextLabel
	if obj is Label or obj is RichTextLabel:
		obj.text = title
	elif obj.has_method("set_text"):
		obj.call("set_text", title)
	else:
		# Check children
		var lbl = obj.find_child("Label", true, false)
		if not lbl: lbl = obj.find_child("RichTextLabel", true, false)
		if lbl: lbl.text = title

func _create_item(data: CreditEntry) -> void:
	if not item_scene: return
	var obj = item_scene.instantiate()
	content_parent.add_child(obj)
	
	if obj.has_method("setup"):
		obj.setup(data)

func _add_spacer(min_height: float = 100.0) -> void:
	if not content_parent: return
	var spacer = Control.new()
	spacer.custom_minimum_size.y = min_height
	content_parent.add_child(spacer)
