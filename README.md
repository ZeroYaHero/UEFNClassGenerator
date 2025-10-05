# UEFN Class Generator
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
__That is a lot work to do...have a computer do it.__

## Example configurations.json
These sets are configurations categories you define in the tool. In example, health. The elements of the configurations are all the different health options you desire which you can group together. So in example
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

## Goal
With the above `configurations.json` you can see the define configuration and its groups. Once the combinations are generated, you yourself don't need to select a specific class slot. Instead, you can change individual properties for the player with the `property_based_class_manager_component.verse` and its `ChangeClassDelatProperties(agent, map{"Health" => "LowQuick"})`
Be able to change behavior by individual properties, not by 

Doing this process manually is time consuming. Therefore automation is the answer!

## How to use UEFN Class Generator 
<ol>
<li>Importing / Editing Configuration Settings</li>
  <ul>
    <li>Import a previously exported & saved configurations json from the program</li>
    <li>Use the provided buttons to add configurations, their groups, and an array of property-value pairs.</li>
  </ul>
<li>Export</li>
  <ul>
    <li>After making or importing configurations, you can save the configurations to a JSON file</li>
    <li>You can also copy to the clipboard the configurations JSON string</li>
    <li>You can generate the class combinations</li>
  </ul>
<li>Generate Class Combinations</li>
   a.
</ol>
In the Fortnite UGC ecosystem using the Unreal Editor for Fortnite (UEFN), changing player or character properties is not trivial.
Logic can be done mostly with the scripting language, Verse, but mostly only interacts through the game via compiled Blueprints known as "Devices."
Devices are the what were used before Verse was around. They provide a lot of functionality to allow you to modify different things in your level/island/world.
Two (2) of those devices are for what is called "classes."
Classes, not in the programming sense, are really just strategies.
So you can change:
- Health
- Sprinting Speed
- Team behavior
But not just that, there are plenty of other devices that rely on class slots for specific functionality. Class slots are often used for conditional checks
```
# Pseudo code
if(isOnClass(player, 2)) { # Then ... }
```
The issue with these classes, is like the above provided pseudo code that they are identified by numerical slots, and players have to be exclusive to them.
This means, if you want to have multiple options for health, but then independently have multiple options for team behavior: you have to make the combinations for that.
