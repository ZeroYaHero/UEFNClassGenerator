using { /Verse.org/Simulation/Tags }
using { /Fortnite.com/Playspaces }
using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }
using { /Verse.org/SceneGraph }
using { /Fortnite.com/Game }
using { /UnrealEngine.com }

<#
 /$$$$$$$$ /$$$$$$$$ /$$$$$$$   /$$$$$$  /$$     /$$ /$$$$$$  /$$   /$$ /$$$$$$$$ /$$$$$$$   /$$$$$$ 
|_____ $$ | $$_____/| $$__  $$ /$$__  $$|  $$   /$$//$$__  $$| $$  | $$| $$_____/| $$__  $$ /$$__  $$
     /$$/ | $$      | $$  \ $$| $$  \ $$ \  $$ /$$/| $$  \ $$| $$  | $$| $$      | $$  \ $$| $$  \ $$
    /$$/  | $$$$$   | $$$$$$$/| $$  | $$  \  $$$$/ | $$$$$$$$| $$$$$$$$| $$$$$   | $$$$$$$/| $$  | $$
   /$$/   | $$__/   | $$__  $$| $$  | $$   \  $$/  | $$__  $$| $$__  $$| $$__/   | $$__  $$| $$  | $$
  /$$/    | $$      | $$  \ $$| $$  | $$    | $$   | $$  | $$| $$  | $$| $$      | $$  \ $$| $$  | $$
 /$$$$$$$$| $$$$$$$$| $$  | $$|  $$$$$$/    | $$   | $$  | $$| $$  | $$| $$$$$$$$| $$  | $$|  $$$$$$/
|________/|________/|__/  |__/ \______/     |__/   |__/  |__/|__/  |__/|________/|__/  |__/ \______/ 
#>

# This component manages class swapping based on specific properties instead of numerical class slots. Abstracting away the need to make combinations.
property_based_class_manager_component := class<final_super>(component):
	# If true, some default prints will execute in edit session.
	@editable   UseDebugPrint:logic = false
	# Supplement as many property-value-pairs from your property set for a default that you can use for a player.
	@editable   DefaultClassPropertyValuePairs:[]editable_class_property = array{}
	var DefaultClassPropertyValueMap:[string]string = map{}
	var ClassWrappers:[]class_wrapper = array{}
	var AgentClassWrapperMap:[agent]class_wrapper = map{}

	# Initialize the default class property value map which is used to give players a default class.
	OnBeginSimulation<override>():void =
		for(PropertyValuePair:DefaultClassPropertyValuePairs):
			if { set DefaultClassPropertyValueMap[PropertyValuePair.Property] = PropertyValuePair.Value }

	# Retrieves all class swappers from a getter component.
	# Getter component is abstract to be inherited by yourself, or by using the UEFNClassGenerator.exe
	OnSimulate<override>()<suspends>:void =
		AwaitFortRoundStart()
		set ClassWrappers = for:
			ClassWrapperGetterComponent:Entity.FindDescendantComponents(class_getter_component)
			ClassWrapper:ClassWrapperGetterComponent.GetClassWrappers()
		do:
			ClassWrapper
		# ! If you do not want players to be assigned a default class on round start within this component, remove this block. !
		Sleep(1.0) # ! This sleep is necessary (unfortunately) due to the island settings default class assignment at the start of the game.
		for(Participant:Entity.GetPlayspaceForEntity[].GetParticipants()):
			ChangeToDefaultClass(Participant)
		# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	# Get the current class properties of the provided agent.
	GetCurrentClassProperties(InAgent:agent)<transacts>:[string]string =
		if(CurrentClassWrapper := AgentClassWrapperMap[InAgent]):
			CurrentClassWrapper.Properties
		else:
			map{}

	# Get the current class slot of the provided agent.
	GetCurrentClassSlot(InAgent:agent)<transacts>:int =
		if(CurrentClassWrapper := AgentClassWrapperMap[InAgent]):
			CurrentClassWrapper.Slot
		else:
			-1

	# Check if the provided agent is on a class with at the very least the provided properties.
	HasClassProperties(InAgent:agent, InProperties:[string]string)<transacts><decides>:void = _HasClassProperties(InAgent, InProperties)?
	_HasClassProperties<private>(InAgent:agent, InProperties:[string]string)<transacts>:logic =
		if(CurrentClassWrapper := AgentClassWrapperMap[InAgent]):
			for:
				Property->Value:InProperties
				not CurrentClassWrapper.Properties[Property] = Value
			do:
				return false
			true
		false

	# Check if the provided agent's class swapper is of class slot.
	IsOnClassSlot(InAgent:agent, InClassSlot:int)<transacts><decides>:void = 
		CurrentClassWrapper := AgentClassWrapperMap[InAgent]
		CurrentClassWrapper.Slot = InClassSlot

	# Change the provided agent to a class that matches the default class property values.
	ChangeToDefaultClass(InAgent:agent):void =
		ChangeClassAllProperties(InAgent, DefaultClassPropertyValueMap)

	# Change class via class slot instead of properties.
	ChangeClassBySlot(InAgent:agent, InClassSlot:int):void =
		for:
			ClassWrapper:ClassWrappers
			ClassWrapper.Slot = InClassSlot
		do: 
			if(UseDebugPrint?):
				Print("Changing agent to class swapper on slot {InClassSlot}:\n\t" + ToDiagnostic(ClassWrapper))
			ClassWrapper.Selector.ChangeClass(InAgent)
			if { set AgentClassWrapperMap[InAgent] = ClassWrapper }
			return
		if(UseDebugPrint?):
			Print("WARNING: No class swapper matched the provided class slot. No class change will occur.")

	# Given an agent and properties, change the agents class to one that satisifies all the provided properties.
	# If given a subset of properties, it is likely that multiple class swappers will satisfy the provided properties.
	# This function will choose the first matching, so if you want more control: know your set of properties and provide as many as possible.
	ChangeClassAllProperties(InAgent:agent, InProperties:[string]string):void =
		if(UseDebugPrint?):
			Print("InPropertiesLength: {InProperties.Length}\nAttempting to change agent's class properties to:\n\t" + ToDiagnostic(InProperties))
		Matching := for:
			ClassWrapper:ClassWrappers
			for(Property->Value:InProperties):
				Value = ClassWrapper.Properties[Property]
		do:
			ClassWrapper
		if(Match := Matching[0]):
			if(UseDebugPrint?):
				if(Matching.Length > 1):
					Print("WARNING: Multiple class swappers matched the provided properties. Only the first match will be used.")
				Print("Successfully found Class Swapper!:\n\t" + ToDiagnostic(Match))
			Match.Selector.ChangeClass(InAgent)
			Match.Selector.ChangeClass(InAgent)
			if { set AgentClassWrapperMap[InAgent] = Match }
		else if(UseDebugPrint?):
			Print("WARNING: No class swapper matched the provided properties. No class change will occur.")

	# Instead of needing to provide all of the properties, this method offers a delta approach.
	# Provide only the properties that you want to change from the agents current class, the rest will continue to be the same.
	ChangeClassDeltaProperties(InAgent:agent, InPropertiesDelta:[string]string):void =
		if(CurrentClassWrapper := AgentClassWrapperMap[InAgent]):
			var NewProperties:[string]string = CurrentClassWrapper.Properties
			for(Property->Value:InPropertiesDelta):
				if { set NewProperties[Property] = Value}     
			ChangeClassAllProperties(InAgent, NewProperties)
		else:
			if(UseDebugPrint?):
				Print("Provided agent does not have a current class swapper. They will be assigned a new one based on the delta properties.")
			ChangeClassAllProperties(InAgent, InPropertiesDelta)

# Component used to get/generate the class swappers.
# Implementation can be done manually by the user, or by using the UEFNClassGenerator.exe
class_getter_component := class<final_super><abstract>(component):

	# Called by the manager component to get all class wrapper objects.
	GetClassWrappers()<transacts>:[]class_wrapper

# Useful utility to get creative objects from tags.
# Generic implementation in-case the user wants it for other reasons.
(InComponent:component).GetCreativeObjectsFromTag(Tag:tag, cast_type:subtype(creative_object_interface))<transacts>:[]cast_type =
	for:
		CreativeObject:InComponent.Entity.FindCreativeObjectsWithTag(Tag)
		CastedCreativeObject := cast_type[CreativeObject]
	do:
		CastedCreativeObject

# Simple wrapper of `GetCreativeObjectsFromTag` for class designer when populating the class swapper array.
(InComponent:component).GetClassDesigner(Tag:tag)<transacts>:class_designer_device =
	if(ClassDesigner := InComponent.GetCreativeObjectsFromTag(Tag, class_designer_device)[0]):
		ClassDesigner
	else:
		Print("ERROR: Failed to get class designer for " + ToDiagnostic(Tag) + ". Initializing with empty device")
		class_designer_device{}

# Same as the function above, but for class selectors.
(InComponent:component).GetClassSelector(Tag:tag)<transacts>:class_and_team_selector_device =
	if(ClassSelector := InComponent.GetCreativeObjectsFromTag(Tag, class_and_team_selector_device)[0]):
		ClassSelector
	else:
		Print("ERROR: Failed to get class selector for " + ToDiagnostic(Tag) + ". Initializing with empty device")
		class_and_team_selector_device{}

# Use this to await the start of a fortnite round.
# This is necessary for querying Fortnite devices/props because they don't exist before round start.
(InComponent:component).AwaitFortRoundStart()<suspends>:void =
	if(FortRoundManager := InComponent.Entity.GetFortRoundManager[]):
		FortRoundEvent := fort_round_event{}
		FortRoundManager.SubscribeRoundStarted(FortRoundEvent._Signal)
		FortRoundEvent.Await()

# Use this to await the end of a fortnite round.
# Might be necessary to clean up some entities as they simulate during live-edit in UEFN.
(InComponent:component).AwaitFortRoundEnd()<suspends>:void =
	if(FortRoundManager := InComponent.Entity.GetFortRoundManager[]):
		FortRoundEvent := fort_round_event{}
		FortRoundManager.SubscribeRoundStarted(FortRoundEvent._Signal)
		FortRoundEvent.Await()

# Implementation details for the Fortnite round start and end. You can ignore this.
fort_round_event := class:
	RoundEvent<private>:event() = event(){}

	# This function is psuedo private, only to be used by `AwaitFortRoundStart` and `AwaitFortRoundEnd`
	_Signal():void =
		RoundEvent.Signal()

	# Await the RoundEvent to be signaled.
	Await()<suspends>:void =
		RoundEvent.Await()

# Simple editable struct to hold a property-value-pair.
editable_class_property := class<concrete>:
	@editable   Property:string = "Name"
	@editable   Value:string = "Value"

# Class swapper which contains the designer, selector, and the properties it contains.
class_wrapper := class:
	Slot:int
	Designer:class_designer_device
	Selector:class_and_team_selector_device
	Properties:[string]string