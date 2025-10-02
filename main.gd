extends Node

@export var config_packed_scene:PackedScene = preload('res://configuration.tscn')
@export var save_method_popup_packed_scene:PackedScene = preload("res://save_method_popup.tscn")
@export var project_name:String = "TestingThings"
@export var ExportButton:Button

@onready var default_class_designer_template:String = FileAccess.open("res://DeviceTemplates/default_class_designer.txt", 1).get_as_text()
@onready var default_class_selector_template:String = FileAccess.open("res://DeviceTemplates/default_class_selector.txt", 1).get_as_text()

func _ready():
	$VBoxContainer/AddConfigurationButton.pressed.connect(_on_configuration_pressed)
	ExportButton.pressed.connect(_on_export_pressed)
	
func _on_configuration_pressed() -> void:
	print("Configuration added")
	var ConfigurationScene:Node = config_packed_scene.instantiate()
	$VBoxContainer/ScrollContainer/VBoxContainer.add_child(ConfigurationScene)

func _on_export_pressed() -> void:
	var json_string = JSON.stringify(_generate_config_array(), "\t")
	print(json_string)
	var save_method_popup:SaveMethodPopup = save_method_popup_packed_scene.instantiate()
	add_child(save_method_popup)
	var method = await save_method_popup.clicked
	save_method_popup.queue_free()
	match method:
		0:
			var file = FileAccess.open("test.json", FileAccess.WRITE_READ)
			file.store_string(json_string)
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
	var regex:RegEx = RegEx.new()
	var clipboard:String = ""
	DisplayServer.clipboard_set(clipboard)
	regex.compile("PROJECTNAME")
	var project_class_designer_template:String = regex.sub(default_class_designer_template, project_name)
	var project_class_selector_template:String = regex.sub(default_class_selector_template, project_name)
	for i in range(combos.size()):
		var class_slot:int = i + 1
		var tag:String = "class_slot_%d_tag" % class_slot
		var tag_definition:String = tag + " := class(tag){}\n"
		regex.compile("DEFAULTTAG")
		var class_designer:String = regex.sub(default_class_designer_template, tag)
		var class_selector:String = regex.sub(default_class_selector_template, tag)
		regex.compile('(PropertyName="ClassIdentifier")(,PropertyData="[^"]*")?')
		class_designer = regex.sub(class_designer, '(PropertyName="ClassIdentifier")(,PropertyData="%s")?' % class_slot)
		regex.compile('(PropertyName="ClassToSwitchTo")(,PropertyData="[^"]*")?')
		class_selector = regex.sub(class_selector, '(PropertyName="ClassToSwitchTo", PropertyData="%d")' % class_slot)
		var combo = combos[i]
		var designer_selector_name:String = ""
		for label_key in combo["CombinationLabels"]:
			designer_selector_name = designer_selector_name + label_key + combo["CombinationLabels"][label_key]
		regex.compile('(PropertyName="LabelOverride")(,PropertyData="[^"]*")?')
		class_designer = regex.sub(class_designer, 'PropertyName="LabelOverride",PropertyData="%s"' % designer_selector_name + "_Designer")
		class_selector = regex.sub(class_selector, 'PropertyName="LabelOverride",PropertyData="%s"' % designer_selector_name + "_Selector")
		for j in range(combo["CombinationData"].size()): # for each combination properties
			var property:Dictionary = combo["CombinationData"][j]
			regex.compile('(PropertyName="%s")(,PropertyData="[^"]*")?' % property["PropertyName"])
			class_designer = regex.sub(class_designer, '(PropertyName="%s",PropertyData="%s")' % [property["PropertyName"], property["PropertyData"]], true)
		clipboard = clipboard + class_designer + class_selector
	DisplayServer.clipboard_set(clipboard)
