class_name PropertyValuePair extends HBoxContainer

func _ready() -> void:
	await $RemoveProperty.pressed
	self.queue_free()

func get_property_name() -> String:
	return $PropertyNameLineEdit.get_text()
	
func get_property_value() -> String:
	return $PropertyValueLineEdit.get_text()
