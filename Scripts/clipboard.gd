class_name Clipboard extends Window

func _ready() -> void:
	self.popup()
	close_requested.connect(_on_close)
	
func _on_close() -> void:
	self.queue_free()

func set_devices_verse_clipboard(devices:String, verse:String) -> void:
	print(devices.length())
	print(verse.length())
	$HBoxContainer/Devices.text = devices
	$HBoxContainer/Verse.text = verse
