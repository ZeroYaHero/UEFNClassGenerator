class_name GroupProperties extends VBoxContainer

@export var group_id_line_edit:LineEdit
@export var properties_foldable:FoldableContainer
@export var properties_vbox:VBoxContainer
@export var add_property_pair_button:Button
@export var foldable_container:FoldableContainer

var _current_config_id:String
var _current_group_id:String

func _ready() -> void:
	add_property_pair_button.pressed.connect(_on_add_property_pair)
	group_id_line_edit.text_changed.connect(_on_group_id_changed)
	foldable_container.folding_changed.connect(_on_properties_folding_changed)
	await $IDRemoveHBox/RemoveGroupButton.pressed
	self.queue_free()
	
func _on_add_property_pair() -> void:
	var property_value_scene = load("res://property_value_pair.tscn").instantiate()
	properties_vbox.add_child(property_value_scene)
	properties_vbox.move_child(add_property_pair_button, properties_vbox.get_children().size() - 1)
	
func _on_group_id_changed(new_text:String) -> void:
	if foldable_container.is_folded():
		properties_foldable.set_title(_current_config_id + " " + new_text + " Properties")
	_current_group_id = new_text
	
func on_config_renamed(new_text:String) -> void:
	group_id_line_edit.placeholder_text = new_text + " Group ID"
	_current_config_id = new_text
	if foldable_container.is_folded():
		foldable_container.set_title(_current_config_id + " " + _current_group_id + " Properties")
	
func _on_properties_folding_changed(is_folded:bool) -> void:
	if is_folded:
		foldable_container.set_title(_current_config_id + " " + _current_group_id + " Properties")
	else:
		foldable_container.set_title(" ")
		
func get_property_values() -> Array[Dictionary]:
	var property_value_array:Array[Dictionary] = []
	for child in properties_vbox.get_children():
		if child is PropertyValuePair:
			var property_value_pair = child as PropertyValuePair
			var property_name = property_value_pair.get_property_name()
			var property_value = property_value_pair.get_property_value()
			if property_name and property_value:
				property_value_array.append({'PropertyName': property_name, 'PropertyData': property_value})
	return property_value_array
