class_name CreditsItemUI
extends Control

@export var name_label: Label # Using RichTextLabel for bold support if needed
@export var owner_label: Label
@export var link_button: LinkButton

var _link_url: String

func setup(data: CreditEntry) -> void:
	if name_label:
		# Label doesn't support [b] tags like RichTextLabel. Just assign the name.
		name_label.text = data.name
	
	if owner_label:
		owner_label.text = data.owner
		
	_link_url = data.link
	
	if link_button:
		# Disconnect any previous connection to avoid duplicates if reused
		if link_button.pressed.is_connected(_on_clicked):
			link_button.pressed.disconnect(_on_clicked)
		link_button.pressed.connect(_on_clicked)

func _on_clicked() -> void:
	if not _link_url.is_empty():
		print("[CreditsItem] Opening URL: ", _link_url)
		OS.shell_open(_link_url)
