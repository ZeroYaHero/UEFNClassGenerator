# UEFN Class Generator
![hippo](Examples/demonstration.gif)

*As of date (October 4th, 2025) and Fortnite/UEFN version (37.40) this tool is functional and there is no native scripting or editor alternative.*

This is a GUI created in Godot to generate Fortnite/UEFN "Class Slots" given configurations containing property groups. The cartesian product of the configurations (sets) and their property groups (elements) results in new "Class Slots," which simply represent a combination of the provided configurations and their properties.

**...Why do this?**

## Motivation
In Fortnite/UEFN...
- A player can only be of one (1) class at a time.
- Class slots are just indexes which are referenced by  `class_designer_device` (Class Designer) and `class_and_team_selector_device` (Class Selector) which are read-only Blueprints known as Devices. Their roles are somewhat self explanatory, but I will elaborate further in a moment.
- Both the Class Designer and Selector cannot be modified or instantiated at runtime.

*Thus...*
For every combination of settings you can think of, a new Class (Slot/Index) is necessary. Therefore, for each class slot, a new Class Designer and Selector are needed.
__That is a lot work to do...Have a computer do it!__

## Generating the Classes and Placing in Editor
<ol>
<li>Importing / Editing Configuration Settings</li>
  <ul>
    <li>Import a previously exported & saved configurations json from the program</li>
    <li>With the two text boxes in the top right, type your project name and the path to the level you desire to paste the devices in.</li>
    <li>Use the provided buttons to add configurations, their groups, and an array of property-value pairs.</li>
  </ul>
<li>Export</li>
  <ul>
    <li>After making or importing configurations, you can save the configurations to a JSON file...</li>
    <li>Or you can copy to the clipboard the configurations JSON string...</li>
    <li>Or you can generate the class combinations (seen in the next numbered step).</li>
  </ul>
<li>Generate Class Combinations</li>
   <ul>
    <li>A popup will ask you if you desire a Verse path other than the root content folder. If so, type that path in and press ok when done.</li>
    <li>After the generation takes place, a window will pop up with two text blobs. Copy the right hand side which contains the Verse tag definitions and the `my_class_wrapper_getter`</li>
    <li>Paste the provided code into a new Verse file which is in the root level (content folder) of your UEFN project.</li>
    <li>**Build Verse code. Missing this step risks the pasting of the actors not working at all.**</li>
    <li>Copy the left hand side. This contains the UProperty clipboard for all the generated class designer and selector device/actors.</li>
    <li>Paste the clipboard into your level.</li>
  </ul>
</ol>

## Using the Generated Classes
Once the combinations are generated, the getter code has been pasted, and Verse has been built... you are ready to go!

With the provided `property_based_class_manager_component.verse` you don't need to memorize or manually input the classes properties in your system. It is abstracted away from you. All it takes is a simple call:

`ChangeClassDeltaProperties(agent, map{"ConfigurationName" => "GroupName"}):void`

You of course can provide the entire configuration/property set if you'd like:

`ChangeClassAllProperties(agent, map{ConfigurationOne => GroupX, ConfigurationTwo => GroupY, ... ConfigurationN => GroupZ}):void`

Sometimes its also convienient to still use the class slots for very straightforward logic:

`ChangeClassByClassSlot(agent, x):void`

And of course, with this manager you can now easily see what exactly is the behavior/properties of the current class that the player is on:

`GetCurrentClassProperties(agent):[string]string`

## Example configurations.json
These sets are configurations categories you define in the tool. In example, health. The elements of the configurations are all the different health options you desire which you can group together.
```
"ConfigurationName": "Health",
"ConfigurationGroups": [
  {
    "GroupName": "LowQuick",
    "GroupProperties": [
      {
        "PropertyData": "50",
        "PropertyName": "HealthMax"
      },
      {
        "PropertyData": "2.5",
        "PropertyName": "RegenMultiplier"
      }
    ]
  },
  {
    "GroupName": "HighSlow",
    "GroupProperties": [
      {
        "PropertyData": "150",
        "PropertyName": "HealthMax"
      },
      {
        "PropertyData": "0.75",
        "PropertyName": "RegenMultiplier"
      }
    ]
  }
]
```

## How it Works
- `default_class_designer.txt` and `default_class_selector` are clipboards copied and edited from the UEFN editor.
- These clipboards represent the UProperties of the respective devices.
- I use Godot's RegEx implementation and format strings to simply replace values with the provided ones in the configurations.
- Most of the properties are in the designer in the form of `(PropertyName="Name",PropertyValue="Value")` within a long list `PlayerOptionData` within the `ToyOptionsComponent`
- Additionally, towards the end of both files the properties are repeated in seperate lines, like so: `Name=Value`
- The replaced values have no effect unless a theres a `Name_Override=True` as well.
- The same is done for the Verse tag markups which are thankfully copy-and-pastable in editor considering there is no multi-edit option at the moment.
- GODOT in hindsight is a little bloated for this project, but iterating with it is quick and I needed a solution fast and considering I have learned GODOT recently I thought why not.
