class_name Configuration extends PanelContainer

@export var group_packed_scene:PackedScene = preload("res://group_properties.tscn")
@export var add_group_button:Button
@export var group_vbox:VBoxContainer
@export var remove_configuration_button:Button
@export var config_id_line_edit:LineEdit
@export var foldable_container:FoldableContainer

var config_id:String

func _ready() -> void:
	add_group_button.pressed.connect(_on_add_group_pressed)
	config_id_line_edit.text_changed.connect(_on_config_id_changed)
	foldable_container.folding_changed.connect(_on_groups_folder_change)
	await remove_configuration_button.pressed
	self.queue_free()
	
func _on_add_group_pressed() -> void:
	var group_scene = group_packed_scene.instantiate()
	group_scene._current_config_id = config_id_line_edit.get_text()
	group_vbox.add_child(group_scene)
	group_vbox.move_child(add_group_button, group_vbox.get_children().size() - 1)
	
func _on_config_id_changed(new_text:String) -> void:
	config_id = new_text
	for child in group_vbox.get_children():
		if child is GroupProperties:
			child.on_config_renamed(new_text)
	if foldable_container.is_folded():
		foldable_container.set_title(config_id_line_edit.get_text() + " Groups")
			
func _on_groups_folder_change(is_folded:bool) -> void:
	if is_folded:
		foldable_container.set_title(config_id_line_edit.get_text() + " Groups")
	else:
		foldable_container.set_title(" ")
		
func get_group_properties() -> Array[Dictionary]:
	var group_properties_array:Array[Dictionary] = []
	for child in group_vbox.get_children():
		if child is GroupProperties:
			var group_properties = child as GroupProperties
			if group_properties._current_group_id:
				group_properties_array.append({"GroupName": group_properties._current_group_id, "GroupProperties": group_properties.get_property_values()})
	return group_properties_array
	
