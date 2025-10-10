extends Node

enum FileState {IMPORTING, EXPORTING}

@export var import_button:Button
@export var export_button:Button
@export var import_export_file_dialog:FileDialog
@export var project_name_line_edit:LineEdit
@export var level_path_line_edit:LineEdit

@onready var default_class_designer_template:String = FileAccess.open("res://Templates/default_class_designer.txt", FileAccess.ModeFlags.READ).get_as_text()
@onready var default_class_selector_template:String = FileAccess.open("res://Templates/default_class_selector.txt", FileAccess.ModeFlags.READ).get_as_text()
@onready var tag_and_getter_template:String = FileAccess.open("res://Templates/tag_and_getter_verse.txt", FileAccess.ModeFlags.READ).get_as_text()
@onready var class_swapper_construction_template:String = FileAccess.open("res://Templates/class_wrapper.txt", FileAccess.ModeFlags.READ).get_as_text()

var file_state:FileState = FileState.IMPORTING

func _ready():
	print("Tag Getter Template Size: " + str(tag_and_getter_template.length()))
	print("Designer & Selector Length %d %d" % [default_class_designer_template.length(), default_class_selector_template.length()])
	import_export_file_dialog.hide()
	import_export_file_dialog.file_selected.connect(_on_export_path_selected)
	import_export_file_dialog.canceled.connect(_on_close_export_import)
	$VBoxContainer/AddConfigurationButton.pressed.connect(_on_configuration_pressed)
	import_button.pressed.connect(_on_import_pressed)
	export_button.pressed.connect(_on_export_pressed)
	
func _on_configuration_pressed() -> Configuration:
	print("Configuration added")
	var configuration_scene:Configuration = load("res://Scenes/configuration.tscn").instantiate()
	$VBoxContainer/ScrollContainer/VBoxContainer.add_child(configuration_scene)
	return configuration_scene
	
func _on_close_export_import() -> void:
	import_export_file_dialog.hide()
	
func _on_import_pressed() -> void:
	import_export_file_dialog.set_file_mode(FileDialog.FileMode.FILE_MODE_OPEN_FILE)
	import_export_file_dialog.show()
	
func _on_export_path_selected(path:String) -> void:
	import_export_file_dialog.hide()
	if file_state == FileState.IMPORTING:
		var file = FileAccess.open(path, FileAccess.ModeFlags.READ)
		var json:JSON = JSON.new()
		json.parse(file.get_as_text())
		file.close()
		for configuration in json.data:
			var configuration_scene:Configuration = _on_configuration_pressed()
			configuration_scene._on_config_id_changed(configuration["ConfigurationName"])
			configuration_scene.config_id_line_edit.set_text(configuration["ConfigurationName"])
			for configuration_group in configuration["ConfigurationGroups"]:
				var group_scene:GroupProperties = configuration_scene._on_add_group_pressed()
				group_scene.on_config_renamed(configuration["ConfigurationName"])
				group_scene._on_group_id_changed(configuration_group["GroupName"])
				group_scene.group_id_line_edit.set_text(configuration_group["GroupName"])
				for property in configuration_group["GroupProperties"]:
					var property_value_scene:PropertyValuePair = group_scene._on_add_property_pair()
					property_value_scene.set_property_name(property["PropertyName"])
					property_value_scene.set_property_value(property["PropertyData"])

func _on_export_pressed() -> void:
	var json_string = JSON.stringify(_generate_config_array(), "\t")
	print(json_string)
	var save_method_popup:SaveMethodPopup = load("res://Scenes/save_method_popup.tscn").instantiate()
	add_child(save_method_popup)
	var method = await save_method_popup.clicked
	save_method_popup.queue_free()
	match method:
		0:
			#var file = FileAccess.open("uefn_class_configs.json", FileAccess.WRITE_READ)
			import_export_file_dialog.set_file_mode(FileDialog.FileMode.FILE_MODE_SAVE_FILE)
			file_state = FileState.EXPORTING
			import_export_file_dialog.show()
			var file_path:String = await import_export_file_dialog.file_selected
			print("Export file path: %s" % file_path)
			import_export_file_dialog.hide()
			var file = FileAccess.open(file_path, FileAccess.WRITE_READ)
			file.store_string(json_string)
			file.close()
		1:
			DisplayServer.clipboard_set(json_string)
		2:
			_generate_combos(json_string)
			
func _generate_config_array() -> Array:
	var configurations_array = []
	for maybe_config in $VBoxContainer/ScrollContainer/VBoxContainer.get_children():
		if maybe_config is Configuration:
			var config:Configuration  = maybe_config as Configuration
			configurations_array.append({"ConfigurationName": config.config_id, "ConfigurationGroups": config.get_group_properties() })
	return configurations_array
			
func _generate_combos(json:Variant) -> void:
	if json is String:
		var json_parser = JSON.new()
		json_parser.parse(json)
		json = json_parser.data as Array
	var combos:Array = []
	var config_group_pointers:Array = Array()
	if not json.size() > 0:
		return
	config_group_pointers.resize(json.size())
	config_group_pointers.fill(0)
	var done:bool = false
	while not done:
		var i:int = 0
		var combo_labels:Dictionary = {}
		var combo_properties:Array = []
		for j in range(json.size()):
			var groups:Array = json[j]["ConfigurationGroups"]
			if not config_group_pointers[j]:
				config_group_pointers[j] = 0
			var selected_group = groups[config_group_pointers[j]]
			combo_labels[json[j]["ConfigurationName"]] = selected_group["GroupName"]
			combo_properties = combo_properties + selected_group["GroupProperties"]
		combos.append({"CombinationLabels": combo_labels, "CombinationData": combo_properties})
		config_group_pointers[i] = config_group_pointers[i] + 1
		while config_group_pointers[i] >= json[i]["ConfigurationGroups"].size():
			config_group_pointers[i] = 0
			i += 1
			if i >= config_group_pointers.size():
				done = true
				break
			config_group_pointers[i] = config_group_pointers[i] + 1
	_generate_designer_selector_and_component(combos)
	
# check for defaults and replace those as well
func _generate_designer_selector_and_component(combos:Array) -> void:
	var verse_path_popup:AcceptDialog = load("res://Scenes/verse_path_dialog.tscn").instantiate()
	add_child(verse_path_popup)
	await verse_path_popup.confirmed
	var verse_path:String = verse_path_popup.get_node(NodePath("VBoxContainer/LineEdit")).get_text()
	verse_path_popup.queue_free()
	var tag_path_array:PackedStringArray = verse_path.split("/", false)
	
	var regex:RegEx = RegEx.new()
	var device_clipboard:String = ""
	var verse_clipboard:String = tag_and_getter_template
	var tag_definitions:Array[String] = []
	regex.compile("PROJECTNAME")
	var project_class_designer_template:String = regex.sub(default_class_designer_template, project_name_line_edit.get_text(), true)
	var project_class_selector_template:String = regex.sub(default_class_selector_template, project_name_line_edit.get_text(), true)
	regex.compile("LEVELPATH")
	project_class_designer_template = regex.sub(project_class_designer_template, level_path_line_edit.get_text(), true)
	project_class_selector_template = regex.sub(project_class_selector_template, level_path_line_edit.get_text(), true)
	regex.compile("LEVELNAME")
	var level_path_dirs:PackedStringArray = level_path_line_edit.get_text().split("/")
	var level_name:String = level_path_dirs[level_path_dirs.size() - 1]
	project_class_designer_template = regex.sub(project_class_designer_template, level_name, true)
	project_class_selector_template = regex.sub(project_class_selector_template, level_name, true)
	for i in range(combos.size()):
		var class_slot:int = i + 1
		
		var designer_modified_properties:Array[String] = []
		var designer_overridden_properties:Array[String] = []
		var selector_modified_properties:Array[String] = []
		var selector_overridden_properties:Array[String] = []
		
		var tag:String = "class_slot_%d_tag" % class_slot
		var tag_definition:String = tag + " := class(tag){}"
		var verse_tag_path_array:PackedStringArray = tag_path_array.duplicate()
		verse_tag_path_array.append(tag)
		var tag_path:String = "-".join(verse_tag_path_array)
		tag_definitions.append(tag_definition)
		
		regex.compile("TAG")
		var class_designer:String = regex.sub(project_class_designer_template, tag_path, true)
		print("replacing TAG with %s" % tag_path)
		var class_selector:String = regex.sub(project_class_selector_template, tag_path, true)
		var class_swapper_construction:String = regex.sub(class_swapper_construction_template % class_slot, tag, true)
		
		regex.compile('PropertyName="(ClassIdentifier|ClassToSwitchTo)"((,PropertyData=")[^"]*(?="))?')
		class_designer = regex.sub(class_designer, 'PropertyName="ClassIdentifier",PropertyData="(ClassType=ClassSlot, ClassSlot=%d)"' % class_slot, true)
		class_selector = regex.sub(class_selector, 'PropertyName="ClassToSwitchTo",PropertyData="(ClassType=ClassSlot,ClassSlot=%d)"' % class_slot, true)
		
		var combo = combos[i]
		var class_swapper_name:String = ""
		
		for label_key in combo["CombinationLabels"]:
			var label_value:String = combo["CombinationLabels"][label_key]
			class_swapper_name = class_swapper_name + label_key + label_value
			class_swapper_construction = class_swapper_construction + "\t\t\t\t\t\"" + label_key + "\" => \"" + label_value + "\"\n"
			
		verse_clipboard = verse_clipboard + class_swapper_construction
		
		regex.compile('(PropertyName="LabelOverride")(,PropertyData="[^"]*")?')
		class_designer = regex.sub(class_designer, 'PropertyName="LabelOverride",PropertyData="%s"' % (class_swapper_name + "_Designer"))
		class_selector = regex.sub(class_selector, 'PropertyName="LabelOverride",PropertyData="%s"' % (class_swapper_name + "_Selector"))
		
		regex.compile('(?<=(ActorLabel|LabelOverride)=")[^"]*(?=")')
		class_designer = regex.sub(class_designer, (class_swapper_name + "_Designer"), true)
		class_selector = regex.sub(class_selector, (class_swapper_name + "_Selector"), true)
		
		for j in range(combo["CombinationData"].size()): # for each combination properties
			var property:Dictionary = combo["CombinationData"][j]
			regex.compile('(PropertyName="%s")(,PropertyData="[^"]*")?' % property["PropertyName"])
			class_designer = regex.sub(class_designer, 'PropertyName="%s",PropertyData="%s"' % [property["PropertyName"], property["PropertyData"]], true)
			designer_modified_properties.append(property["PropertyName"] + "=" + property["PropertyData"])
			designer_overridden_properties.append(property["PropertyName"] + "_Override=" + "True")
		
		designer_modified_properties.append("ClassIdentifier=(ClassType=ClassSlot, ClassSlot=%d)" % class_slot)
		designer_overridden_properties.append("ClassIdentifier_Override=True")
		selector_modified_properties.append("ClassToSwitchTo=(ClassType=ClassSlot, ClassSlot=%d)" % class_slot)
		selector_overridden_properties.append("ClassToSwitchTo_Override=True")
		
		regex.compile(r"(     |	  )End Actor")
		class_designer = regex.sub(class_designer, r"         "  + ("\n" + r"         ").join(designer_modified_properties + designer_overridden_properties) + "\n      End Actor")
		class_selector = regex.sub(class_selector, r"         "  + ("\n" + r"         ").join(selector_modified_properties + selector_overridden_properties) + "\n      End Actor")
		device_clipboard = device_clipboard + class_designer + class_selector
	regex.compile("TAGS")
	verse_clipboard = regex.sub(verse_clipboard, "\n".join(tag_definitions))
	var clipboard_scene = load("res://Scenes/clipboard.tscn").instantiate()
	clipboard_scene.set_devices_verse_clipboard(device_clipboard, verse_clipboard)
	add_child(clipboard_scene)
