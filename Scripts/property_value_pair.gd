class_name PropertyValuePair extends HBoxContainer

func _ready() -> void:
	await $RemoveProperty.pressed
	self.queue_free()
	
func set_property_name(in_name:String) -> void:
	$PropertyNameLineEdit.set_text(in_name)
	
func set_property_value(in_value:String) -> void:
	$PropertyValueLineEdit.set_text(in_value)

func get_property_name() -> String:
	return $PropertyNameLineEdit.get_text()
	
func get_property_value() -> String:
	return $PropertyValueLineEdit.get_text()
