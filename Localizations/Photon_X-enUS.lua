-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2026- Linus Olsson
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- This code is licensed under the MIT license (see LICENSE for details)

local L = LibStub("AceLocale-3.0"):NewLocale("Photon", "enUS", true)

if not L then return end

L["General Options"] = true
L["Size and Shape"] = true
L["Visuals"] = true


L["Create"] = true
L["Edit"] = true
L["Bind"] = true
L["Scale"] = true
L["Shape"] = true
L["Name"] = true
L["Columns"] = true
L["X"] = true
L["Y"] = true



-----------------------------------------------
------------------General----------------------
-----------------------------------------------

L["How to use"] = true
L["Option"] = true

L["Custom_Option"] = "For custom states, add a desired state string (/photon state custom <state string>) where <state string> is a semicolon separated list of state conditions"



L["Low"] = true
L["Medium"] = true
L["High"] = true
L["Dialog"] = true
L["Tooltip"] = true

L["Valid States"]=true
L["Invalid index"] = true


L["Hide"] = true
L["Show"] = true

L["Home State"] = true
L["Last State"] = true

L["Auto-Hide"] = true


L["Paged"] = true
L["Stance"] = true
L["Pet"] = true
L["Alt"] = true
L["Ctrl"] = true
L["Shift"] = true
L["Stealth"] = true
L["Reaction"] = true
L["Combat"]  = true
L["Group"] = true
L["Fishing"] = true
L["Vehicle"] = true
L["Custom"] = true
L["Possess"] = true
L["Override"] = true
L["Extrabar"] = true


L["Page 1"] = true
L["Page 2"] = true
L["Page 3"] = true
L["Page 4"] = true
L["Page 5"] = true
L["Page 6"] = true


L["No Pet"] = true
L["Pet Exists"] = true

L["Alt Released"] = true
L["Control Released"] = true
L["Shift Released"] = true
L["Alt Pressed"] = true
L["Control Pressed"] = true
L["Shift Pressed"] = true
L["Friendly Target"] = true
L["Hostile Target"] = true
L["Raid"] = true
L["Party"] = true

L["Vanish"] = true
L["Shapeshift"] = true
L["No Stealth"] = true
L["Friendly"] = true
L["Hostile"] = true
L["Out of Combat"] = true
L["In Combat"] = true

L["No Group"] = true
L["Group: Raid"] = true
L["Group: Party"] = true
L["No Fishing Pole"] = true
L["Fishing Pole"] = true

L["No Skyriding"] = true
L["Skyriding"] = true
L["No Vehicle"] = true
L["Vehicle"] = true
L["No Possess"] = true
L["Possess"] = true
L["No Override Bar"] = true
L["Override Bar"] = true
L["No Extra Bar"] = true
L["Extra Bar"] = true

L["Vehicle Exit Bar"] = true

L["Custom States"] = true


---class specific state names
L["Caster Form"] = true
L["No Form"] = true
L["No Stance"] = true
L["Healer Form"] = true
L["Melee"] = true
L["Shadow Dance"] = true


L["Left-Click"] = true
L["Right-Click"] = true

L["Configure Bars"] = true
L["Configure Buttons"] = true
L["Configure Buttons"] = true
L["Configure Appearance"] = true

---button editor window
L["Bar Config"] = true
L["Button Editor"] = true
L["Specialization"] = true
L["Condition"] = true
L["Modifiers"] = true
L["ButtonEditor_Location"] = "Button %d - Row %d"
L["ButtonEditor_Button"] = "Button %d"
L["Add page for condition"] = true
L["Remove page"] = true
L["ButtonEditor_DefaultDesc"] = "Default state when no other condition is true."
-- the button editor: action bar pages (1-6) and {form} tabs at the top, each with a Default page and condition pages
L["ButtonEditor_DefaultHelp"] = "Default shows when no condition is active.\n"..
	"Each {form} tab and each action bar page has its own Default and condition pages, so holding Shift in a {form} shows that {form} tab's Shift page.\n"..
	"When a page has no macro, it uses the first page that has one: the same condition on the Default tab -> the {form} tab's Default -> this action bar page's Default -> action bar page 1's Default."
L["ButtonEditor_RemoveModifier"] = "Remove the %s page from %s? Its macros are deleted from every button in that row, on every tab and action bar page."
L["ButtonEditor_RowOfSpec"] = "row %d of %s"
L["ButtonEditor_Status"] = "|cffffd200%s|r|cFFFFFFFF button %d is selected. Click another button to edit it."
L["ButtonEditor_SelectButton"] = "Click an action button to edit it."
L["Override Visuals"] = true
L["OverrideVisuals_Desc"] = "Gives this button its own visuals in place of its bar configuration. Untick to have it follow the bar again."
L["Button Visuals"] = true
L["VisualOverride_Own"] = "|cffffd200%s|r|cFFFFFFFF button %d has its own visuals."
L["Reset Changed Buttons"] = true
L["ClearButtonOverrides_Confirm"] = "Clear the visuals of every button on this bar that has its own."
L["BarDesc_clearButtonOverrides"] = "Reset any changes done on individual buttons and bring them back to following these settings"
L["ButtonEditor_Inherits"] = "No macro of its own, this page uses %s. Type a macro to give it one."
L["ButtonEditor_Empty"] = "No macro yet. Type one below."
L["ButtonEditor_InheritsBlank"] = "No macro of its own, this page uses %s, which is forced blank."
L["Force Blank"] = true
L["ButtonEditor_ForceBlankDesc"] = "Makes this page empty instead of using another page's macro. Pages that would use this one are empty too."
L["Icon"] = true
L["Edit Label"] = true
L["Reset Icon"] = true
L["ButtonEditor_IconDesc"] = "Click to choose an icon for this page."
L["ButtonEditor_LabelDesc"] = "Text shown on the button when the bar's Button Label option is on."
L["ButtonEditor_ResetIconDesc"] = "Goes back to the macro's own icon instead of the one you picked."
L["ButtonEditor_RemovePageDesc"] = "Removes the selected condition page from this row of buttons."
L["ButtonEditor_AllForms"] = "Expand"
L["ButtonEditor_AllFormsDesc"] = "Shows Default and every {form} next to each other instead of in tabs."

L["Toggle Keybind Mode"] = true
L["Open the Interface Menu"] = true


L["Keybind_Tooltip_1"] = "Press a key to bind it to"
L["Keybind_Tooltip_2"] = "Current Binding(s)"
L["Keybind_Tooltip_3"] = "Left-Click to lock the current binding(s)"
L["Keybind_Tooltip_4"] = "Right-Click to give these bindings maximum priority"
L["Keybind_Tooltip_5"] = "Hit ESC to clear the current binding(s)"

L["Empty Button"] = true
L["Edit Bindings"] = true
L["None"] = true

L["Locked"] = true
L["Priority"] = true
L["Bindings_Locked_Notice"]	= "This button's bindings are locked.\nLeft-Click button to unlock."
L["Bindings_Blizzard_Conflict"] = "Button %s is bound in Blizzard's keybinds.\nPhoton will override it while the button is active."
L["and"] = true

L["Off"] = true
L["Combat"] = true
L["Mouseover"] = true
L["Combat + Mouseover"] = true

L["Linear"] = true
L["Circle"] = true
L["Circle + One"] = true
L["Arc"] = true
L["Arc Length"] = true
L["Square"] = true
L["Diamond"] = true
L["Rectangle"] = true
L["Bar_Strata_List"] = "\n1=BACKGROUND\n2=LOW\n3=MEDIUM\n4=HIGH\n5=DIALOG"
L["Bar_Alpha_Instructions"] = "Alpha value must be between zero(0) and one(1)"
L["Bar_ArcStart_Instructions"] = "Arc start must be between 0 and 359"
L["Bar_ArcLength_Instructions"] = "Arc length must be between 0 and 359"
L["Bar_Column_Instructions"] = "Enter a number of desired columns for the bar higher than zero(0)\nOmit number to turn off columns"
L["Horozontal_Padding_Instructions"] = "Enter a valid number for desired horizontal button padding"
L["Vertical_Padding_Instructions"] = "Enter a valid number for desired vertical button padding"
L["Horozontal_and_Vertical_Padding_Instructions"] = "Enter a valid number to increase/decrease both the horizontal and vertical button padding"
L["X_Position_Instructions"] = "Enter a valid number for desired x position offset"
L["Y_Position_Instructions"] = "Enter a valid number for desired y position offset"

L["Bar_Lock_Modifier_Instructions"] = "Valid mod keys:\n\nalt: unlock bar when the <alt> key is down\nctrl: unlock bar when the <ctrl> key is down\nshift: unlock bar when the <shift> key is down"
L["Tooltip_Instructions"] = "Valid options:\n\nenhanced: display additional ability info\ncombat: hide/show tooltips while in combat"
L["Spellglow_Instructions"] = "Valid options:\n\ndefault: use Blizzard default spell glow animation\nalt: use alternate subdued spell glow animation"

L["Timer_Limit_Set_Message"] = "Timer limit set to %d seconds"
L["Timer_Limit_Invalid_Message"] = "Invalid timer limit"

L["DragDrop_Error_Message"] = "Sorry, we were unable to place that ability or item."
L["DragDrop_Passive_Message"] = "Passive abilities can't be cast, so they can't go on a button."
L["DragDrop_PetBar_Message"] = "Pet abilities can only be dragged onto it directly from the pet spellbook."
L["DragDrop_Inherited_Message"] = "This button inherits its ability from another page. You can override it in the button editor"


L["Attack"] = true
L["Follow"] = true
L["Move To"] = true
L["Assist"] = true
L["Defensive"] = true
L["Passive"] = true


L["Apply"] = true
L["Cancel"] = true
L["Done"] = true
L["Create New Bar"] = true
L["Delete Current Bar"] = true
L["Select Bar Type"] = true
L["Confirm"] = true
L["Yes"] = true
L["No"] = true
L["General Options"] = true
L["Bar States"] = true
L["Object Editor"] = true
L["Macro Data"] = true
L["Action Data"] = true
L["Options"] = true
L["Revert"] = true
L["ReloadUI"] = "This action will cause the UI to reload."
L["DualSpec_Removed_Message"] = "Photon no longer changes profile when you change specialization. This character used:\n\n%s\n\nAll your profiles are still there, you can switch between them in the profile options. To keep different buttons for each specialization on one profile, turn on %s in a bar's settings."
L["Copy \"%s\" into the current profile? The current profile will be overwritten, and the UI will reload."] = true
L["Current Profile"] = true
L["New Profile"] = true
L["Create a new profile with default settings."] = true
L["Copy Profile"] = true
L["Copy Layout"] = true
L["Delete Profile"] = true
L["Reset Profile"] = true
L["Reset the current profile to its default values."] = true
L["Delete existing and unused profiles from the database to save space, and clean up the SavedVariables file."] = true
L["Copy an existing profile into the current profile, or into a new profile."] = true
L["Copy the bars, settings and keybinds of an existing profile into the current profile, or into a new profile. The buttons are left empty."] = true
L["Copy the layout of \"%s\" into the current profile? The current profile will be overwritten with empty buttons, and the UI will reload."] = true
L["Copy to Current"] = true
L["Layout From"] = true
L["New Profile Name"] = true
L["Pick a new name, at most 50 characters."] = true
L["That profile name is already taken."] = true

L["Click here to edit macro note"] = true
L["Use macro note as button tooltip"] = true

L["Count"] = true
L["Search"] = true
L["Custom Icon"] = true
L["Path"] = true

L["Show Grid"] = true
L["Hidden"] = true
L["Click Mode"] = true
L["On Click"] = true
L["On Release"] = true
L["Multi Spec"] = true
L["Dual Spec"] = true

-- New for the updated GUI
L["Color"] = true
L["Delete Bar"] = true
L["DeleteBar_Confirm"] = "Warning: this will permanently delete the bar and all of its stored data."
L["General Configuration"] = true
L["Condition and Visibility"] = true
L["Secondary States"] = true
L["Text"] = true
L["Dangerous"] = true

L["Spec 1"] = true
L["Spec 2"] = true
L["No Spec"] = true
L["Spell Alerts"] = true
L["Default Alert"] = true
L["Subdued Alert"] = true
L["Lock Actions"] = true
L["Unlock on SHIFT"] = true
L["Unlock on CTRL"] = true
L["Unlock on ALT"] = true
L["Enable Tooltips"] = true
L["Normal"] = true
L["Minimal"] = true
L["Tooltips in Combat"] = true
L["Show Border Style"] = true

-- bar editor labels, apart from the console command names above
L["On Press"] = true
L["Opacity"] = true
L["Force Full Opacity"] = true
L["Fade Speed"] = true
L["Layer"] = true
L["Fade While on Cooldown"] = true
L["Button Label"] = true
L["Action Bar Pages"] = true
L["Last 5s"] = true
L["Reload UI"] = true
L["Rotation"] = true
L["Flatten"] = true
L["True Circle"] = true

-- the position box, on the General Configuration tab
L["Position"] = true
L["Anchored To"] = true
L["AnchorTo_Loop"] = "%s is already positioned from %s. Anchoring to it would make a circular dependency."
L["Screen"] = true
L["Bar Point"] = true
L["Target Point"] = true
L["Bar Locked"] = true
L["Lock All"] = true
L["Unlock All"] = true
L["Clear"] = true

L["Preset Action States"] = true
L["Custom Action States"] = true


L["Select a stance to remap:"] = true
L["Remap selected stance to:"] = true


L["Scale"] = true
L["Alpha"] = true
L["AlphaUp Speed"] = true
L["Strata"] = true
L["Shape"] = true
L["Horizontal Padding"] = true
L["Vertical Padding"] = true
L["Columns"] = true
L["Arc Start"] = true
L["Arc Length"] = true

L["Keybind"] = true
L["Keybind Label Color"] = true
L["Button Name"] = true
L["Stack/Charge"] = true
L["Out-of-Range"] = true
L["CD Counter"] = true
L["Cooldown Alpha"] = true

L["Point"] = true
L["X Position"] = true
L["Y Position"] = true

L["Display the Blizzard UI"] = true
L["Shows / Hides the Default Blizzard UI"] = true

L["Display Minimap Button"] = true
L["Toggles the minimap button."] = true

L["Editors"] = true
L["Fallback Order"] = true
L["State (Modifier)"] = true
L["FallbackOrder_Desc"] = "What an empty state in a stance (like Shift in Bear Form) shows first. State (Modifier): the state's own macro on the default page (like Shift). Stance: the stance's default macro (Bear Form default)."

L["Bar Visibility Toggles"] = true
L["Target"] = true
L["Has Target"] = true
L["No Target"] = true
L["Indoors"] = true
L["Outdoors"] = true
L["Mounted"] = true
L["Flying"] = true
L["Resting"] = true
L["Swimming"] = true
L["Harm"] = true
L["Help"] = true
L["Not Mounted"] = true
L["Not Resting"] = true
L["Not Swimming"] = true
L["Display button for specialization 1"] = true
L["Display button for specialization 2"] = true
L["Display button for specialization 3"] = true
L["Display button for specialization 4"] = true


L["Spell Target Options"] = true

L["Self-Cast by modifier"] = true
L["Toggle the use of the modifier-based self-cast functionality."] = true
L["Select the Self-Cast Modifier"] = true

L["Focus-Cast by modifier"] = true
L["Toggle the use of the modifier-based focus-cast functionality."] = true
L["Select the Focus-Cast Modifier"] = true

L["Right-click Self-Cast"] = true
L["Toggle the use of the right-click self-cast functionality."] = true

L["Mouse-Over Casting"] = true
L["Toggle the use of the modifier-based mouse-over cast functionality."] = true
L["Select a modifier for Mouse-Over Casting"] = true
L["Mouse-Over Casting Modifier"] = true

L["Select the Self-Cast Modifier"] = true

L["Spell_Targeting_Modifier_None_Reminder"] = "\"None\" as modifier for Self & Focus Casting means its disabled. \nFor Mouse-Over Casting it means its always active, and no modifier is required."

L["Action Bar"] = true
L["Zone Action Bar"] = true
L["Stance Bar"] = true
L["Extra Action Bar"] = true
L["Bag Bar"] = true
L["Pet Bar"] = true
L["Totem Bar"] = true
L["Fire Totem"] = true
L["Earth Totem"] = true
L["Water Totem"] = true
L["Air Totem"] = true
L["Menu Bar"] = true
L["XP Bar"] = true
L["Rep Bar"] = true
L["Cast Bar"] = true
L["Mirror Bar"] = true

L["Track Character XP"] = true
L["Track Covenant Renown"] = true
L["Track Azerite Power"] = true
L["Track Honor Points"] = true

L["Width"] = true
L["Height"] = true
L["Bar Fill"] = true
L["Border"] = true
L["Orientation"] = true

L["Center Text"] = true
L["Left Text"] = true
L["Right Text"] = true
L["Mouseover Text"] = true
L["Tooltip Text"] = true

L["Unit"] = true
L["Cast Icon"] = true

L["Spell"] = true
L["Timer"] = true
L["Current/Next"] = true
L["Rested Levels"] = true
L["Percent"] = true
L["Bubbles"] = true
L["Faction"] = true
L["Current Level/Rank"] = true
L["Type"] = true
L["Levels"] = true
L["Level"] = true
L["Points"] = true
L["Prestige"] = true


L["Auto Select"] = true

L["Default"] = true
L["Contrast"] = true
L["Carpaint"] = true
L["Gel"] = true
L["Glassed"] = true
L["Soft"] = true
L["Velvet"] = true

L["Tooltip"] = true
L["Slider"] = true
L["Dialog"] = true

L["Horizontal"] = true
L["Vertical"] = true

L["Buttons"] = true

L["Reward"] = true
L["Close"] = true
L["Select an Option"] = true

L["Item"] = true
L["Spell"] = true
L["Mount"] = true
L["Companion"] = true
L["Profession"] = true
L["Fun"] = true
L["Favorite"] = true
L["Keys"] = true
L["Attach Point"] = true
L["Relative To"] = true
L["Radius"] = true
L["Show On"] = true
L["Save"] = true
L["Output"] = true
L["Flyout Options"] = true

L["Left"] = true
L["Right"] = true
L["Top"] = true
L["Bottom"] = true
L["Top-Left"] = true
L["Top-Right"] = true
L["Bottom-Left"] = true
L["Bottom-Right"] = true
L["Center"] = true

L["Click"] = true
L["Generate Macro"] = true
L["Copy and Paste the text below"] = true

L["Pet Actions can not be added to Photon bars at this time."] = true


-----------------------------------------------
---------------Bar Settings Tooltips-----------
-----------------------------------------------
-- the hover text for each setting in the bar editor, keyed BarDesc_<setting id> (see GUI/Options.lua)
-- {form} becomes the class's word for what is on its stance bar, stance for the classes not listed
L["BarDesc_FormWord"] = "form" --druid, priest
L["BarDesc_AuraWord"] = "aura" --paladin
L["BarDesc_StealthWord"] = "stealth" --rogue
L["BarDesc_PresenceWord"] = "presence" --death knight
L["BarDesc_StanceWord"] = "stance" --warrior, monk and the rest

-- General Configuration
L["BarDesc_deleteBar"] = "Permanently deletes this bar and all the buttons on it."
L["BarDesc_lockAllBars"] = "Lock mouse dragging for every bar."
L["BarDesc_unlockAllBars"] = "Unlock mouse dragging for every bar."

-- Enabled Functions
L["BarDesc_multiSpec"] = "Gives each specialization its own set of buttons."
L["BarDesc_pages"] = "Gives each of the game's action bar pages (1-6) its own set of buttons."
L["BarDesc_state_stance"] = "Gives each {form} its own set of buttons."
L["BarDesc_state_pet"] = "Gives the bar its own set of buttons for when you have a pet out."

-- General Options
L["BarDesc_autoHide"] = "Fades the bar out until you move the mouse over it."
L["BarDesc_hidden"] = "Hides the bar completely. It still shows while editing bars."
L["BarDesc_showGrid"] = "Shows the outline of empty buttons."
L["BarDesc_lockActions"] = "Locks the buttons so abilities can only be dragged on or off them while the chosen key is held. Off leaves them unlocked."
L["BarDesc_clickMode"] = "Whether a button fires when the mouse button is pressed or when it is released."
L["BarDesc_applyReload"] = "Reloads the UI so every change takes full effect."

-- Size and Shape
L["BarDesc_numButtons"] = "How many buttons the bar has."
L["BarDesc_columns"] = "How many buttons per row. 0 puts them all in one row. Only for the linear and rectangle shapes."
L["BarDesc_columns_rectangle"] = "How many buttons across the top and bottom of the rectangle, the sides take the rest. 0 puts them all in one row."
L["BarDesc_scale"] = "The size of the bar and its buttons."
L["BarDesc_horizontalPadding"] = "The space between buttons side by side."
L["BarDesc_verticalPadding"] = "The space between rows of buttons."
L["BarDesc_shape"] = "How the buttons are laid out."
L["BarDesc_rotation"] = "In degrees. On a circle it moves where the buttons start around it, on an arc, square, diamond or rectangle it turns the whole shape."
L["BarDesc_circleLocked"] = "Keeps a circle round: the vertical padding follows the horizontal padding."
L["BarDesc_arcSpan"] = "How far around a circle the arc goes, in degrees: 180 is a half circle. It bulges up, the rotation turns it."
L["BarDesc_flatten"] = "Squeezes the circle towards a corner-to-corner line of the bar, keeping it inside the bar. Above 0 it leans from bottom left to top right, below 0 the other way."
L["BarDesc_alpha"] = "How visible the bar normally is. Lower is more transparent."
L["BarDesc_alphaUp"] = "When the bar becomes fully visible: on mouseover, in combat, or both."
L["BarDesc_alphaUpSpeed"] = "How fast the bar fades in and out."
L["BarDesc_strata"] = "Which layer the bar is drawn on."

-- Position
L["BarDesc_anchorTo"] = "What the bar is attached to: the screen, or another bar it then moves with."
L["BarDesc_anchorPoint"] = "The side or corner of this bar that is attached."
L["BarDesc_anchorRelativePoint"] = "The side or corner of the screen or the other bar it is attached to."
L["BarDesc_positionLocked"] = "Stops the bar from being dragged with the mouse. It can still be moved here."
L["BarDesc_offsetX"] = "How far the bar is from its anchor, left or right. The arrows either side, and the left and right arrow keys while General Configuration is open, move it 1 pixel."
L["BarDesc_offsetY"] = "How far the bar is from its anchor, up or down. The arrows either side, and the up and down arrow keys while General Configuration is open, move it 1 pixel."

-- Visuals
L["BarDesc_keybindLabel"] = "Shows the key bound to each button."
L["BarDesc_buttonName"] = "Shows each button's label, set in the button editor."
L["BarDesc_stackCharge"] = "Shows item stack counts and ability charges on each button."
L["BarDesc_outOfRange"] = "Tints the button when your target is out of range."
L["BarDesc_cooldownCounter"] = "Shows the time left on cooldowns as numbers on the button."
L["BarDesc_cooldownColor1"] = "The color of the cooldown counter."
L["BarDesc_cooldownColor2"] = "The color of the cooldown counter in the last 5 seconds."
L["BarDesc_cooldownAlpha"] = "Fades the button while its ability is on cooldown."
L["BarDesc_slotColor"] = "Tints the border around each button, the Masque skin's border too. Clear sets it back to white."
L["BarDesc_iconTint"] = "Tints each button's icon. Darker colours make the icon darker, white leaves it as it is. Clear sets it back to white."
L["BarDesc_tooltips"] = "Which tooltip to show when hovering a button: Off, Minimal (short) or Normal (the full tooltip)."
L["BarDesc_tooltipsInCombat"] = "Also shows button tooltips while you are in combat."
L["BarDesc_spellAlerts"] = "The glow shown on a button when its ability procs or is highlighted by the game."
L["BarDesc_borderStyle"] = "Shows the game's decorative border art around the button (extra action and zone ability buttons)."

-- Configure Appearance (status bars)
L["BarDesc_mouseoverText"] = "Text shown in place of the other texts while you hover the bar."
L["BarDesc_tooltipText"] = "Text shown in a tooltip when you hover the bar. Uses the bar's tooltip settings."
L["BarDesc_castUnit"] = "Whose casts this bar shows."
L["BarDesc_castIcon"] = "Shows the icon of the spell being cast."

-- Activate a page for these conditions: the bar gets a page for the state, set its abilities in the button editor
L["BarDesc_state_shift"] = "Gives the bar a page for when Shift is held."
L["BarDesc_state_ctrl"] = "Gives the bar a page for when Control is held."
L["BarDesc_state_alt"] = "Gives the bar a page for when Alt is held."
L["BarDesc_state_target"] = "Gives the bar a page for when you have a target."
L["BarDesc_state_harm"] = "Gives the bar a page for when you can attack your target."
L["BarDesc_state_help"] = "Gives the bar a page for when you can help your target."
L["BarDesc_state_stealth"] = "Gives the bar a page for when you are stealthed."
L["BarDesc_state_combat"] = "Gives the bar a page for when you are in combat."
L["BarDesc_state_party"] = "Gives the bar a page for when you are in a party."
L["BarDesc_state_raid"] = "Gives the bar a page for when you are in a raid."
L["BarDesc_state_mounted"] = "Gives the bar a page for when you are mounted."
L["BarDesc_state_swimming"] = "Gives the bar a page for when you are swimming."
L["BarDesc_state_vehicle"] = "Shows the vehicle's abilities on the bar when you are in a vehicle."
L["BarDesc_state_possess"] = "Shows the possessed creature's abilities on the bar when you possess something."
L["BarDesc_state_override"] = "Shows the game's override abilities on the bar when it gives you some (special encounters and quests)."
L["BarDesc_state_dragonriding"] = "Shows your skyriding abilities on the bar while skyriding."
L["BarDesc_state_resting"] = "Gives the bar a page for when you are resting in a city or inn."
L["BarDesc_state_indoors"] = "Gives the bar a page for when you are indoors."
L["BarDesc_state_outdoors"] = "Gives the bar a page for when you are outdoors."
L["BarDesc_state_fishing"] = "Gives the bar a page for when you have a fishing pole equipped."

-- Hide bar for these conditions: checked hides the bar in that state
L["BarDesc_visibility_paged1"] = "Hides the bar on action bar page 1."
L["BarDesc_visibility_paged2"] = "Hides the bar on action bar page 2."
L["BarDesc_visibility_paged3"] = "Hides the bar on action bar page 3."
L["BarDesc_visibility_paged4"] = "Hides the bar on action bar page 4."
L["BarDesc_visibility_paged5"] = "Hides the bar on action bar page 5."
L["BarDesc_visibility_paged6"] = "Hides the bar on action bar page 6."
L["BarDesc_visibility_shift0"] = "Hides the bar while Shift is not held."
L["BarDesc_visibility_shift1"] = "Hides the bar while Shift is held."
L["BarDesc_visibility_ctrl0"] = "Hides the bar while Control is not held."
L["BarDesc_visibility_ctrl1"] = "Hides the bar while Control is held."
L["BarDesc_visibility_alt0"] = "Hides the bar while Alt is not held."
L["BarDesc_visibility_alt1"] = "Hides the bar while Alt is held."
L["BarDesc_visibility_target0"] = "Hides the bar when you have no target."
L["BarDesc_visibility_target1"] = "Hides the bar when you have a target."
L["BarDesc_visibility_harm1"] = "Hides the bar when you can attack your target."
L["BarDesc_visibility_help1"] = "Hides the bar when you can help your target."
L["BarDesc_visibility_reaction0"] = "Hides the bar when your target is friendly."
L["BarDesc_visibility_reaction1"] = "Hides the bar when your target is hostile."
L["BarDesc_visibility_stealth0"] = "Hides the bar when you are not stealthed."
L["BarDesc_visibility_stealth1"] = "Hides the bar when you are stealthed."
L["BarDesc_visibility_stance0"] = "Hides the bar when you are not in any {form}."
L["BarDesc_visibility_combat0"] = "Hides the bar when you are out of combat."
L["BarDesc_visibility_combat1"] = "Hides the bar when you are in combat."
L["BarDesc_visibility_group0"] = "Hides the bar when you are not in a group."
L["BarDesc_visibility_group2"] = "Hides the bar when you are in a party."
L["BarDesc_visibility_group1"] = "Hides the bar when you are in a raid."
L["BarDesc_visibility_pet0"] = "Hides the bar when you have no pet."
L["BarDesc_visibility_pet1"] = "Hides the bar when you have a pet."
L["BarDesc_visibility_mounted0"] = "Hides the bar when you are not mounted."
L["BarDesc_visibility_mounted1"] = "Hides the bar when you are mounted."
L["BarDesc_visibility_swimming0"] = "Hides the bar when you are not swimming."
L["BarDesc_visibility_swimming1"] = "Hides the bar when you are swimming."
L["BarDesc_visibility_vehicle0"] = "Hides the bar when you are not in a vehicle."
L["BarDesc_visibility_vehicle1"] = "Hides the bar when you are in a vehicle."
L["BarDesc_visibility_extrabar0"] = "Hides the bar when the game's extra action bar is not shown."
L["BarDesc_visibility_extrabar1"] = "Hides the bar when the game's extra action bar is shown."
L["BarDesc_visibility_possess0"] = "Hides the bar when you are not possessing anything."
L["BarDesc_visibility_possess1"] = "Hides the bar when you are possessing something."
L["BarDesc_visibility_override0"] = "Hides the bar when there is no override bar."
L["BarDesc_visibility_override1"] = "Hides the bar when the game shows an override bar."
L["BarDesc_visibility_dragonriding0"] = "Hides the bar when you are not skyriding."
L["BarDesc_visibility_dragonriding1"] = "Hides the bar while skyriding."
L["BarDesc_visibility_resting0"] = "Hides the bar when you are not resting."
L["BarDesc_visibility_resting1"] = "Hides the bar when you are resting in a city or inn."
L["BarDesc_visibility_indoors1"] = "Hides the bar when you are indoors."
L["BarDesc_visibility_outdoors1"] = "Hides the bar when you are outdoors."
L["BarDesc_visibility_fishing0"] = "Hides the bar when you have no fishing pole equipped."
L["BarDesc_visibility_fishing1"] = "Hides the bar when you have a fishing pole equipped."

-- the hide condition rows, on hover over their name
L["BarDesc_layer_paged"] = "The page Blizzard's main action bar is on, switched with its page arrows or the page keybinds."
L["BarDesc_layer_shift"] = "Whether the Shift key is held."
L["BarDesc_layer_ctrl"] = "Whether the Control key is held."
L["BarDesc_layer_alt"] = "Whether the Alt key is held."
L["BarDesc_layer_target"] = "Whether you have something targeted."
L["BarDesc_layer_targetType"] = "Whether your target is something you can attack or help."
L["BarDesc_layer_reaction"] = "Whether your target is friendly or hostile towards you."
L["BarDesc_layer_stealth"] = "Whether you are stealthed."
L["BarDesc_layer_stance"] = "Whether you are in a stance, form, aura or presence."
L["BarDesc_layer_combat"] = "Whether you are in combat."
L["BarDesc_layer_group"] = "Whether you are in a party or raid."
L["BarDesc_layer_pet"] = "Whether you have a pet out."
L["BarDesc_layer_mounted"] = "Whether you are mounted."
L["BarDesc_layer_swimming"] = "Whether you are swimming."
L["BarDesc_layer_vehicle"] = "Whether you are in a vehicle."
L["BarDesc_layer_extrabar"] = "Whether the game is showing its extra action button."
L["BarDesc_layer_possess"] = "Whether you are controlling another creature."
L["BarDesc_layer_override"] = "Whether the game has replaced your action bar, like in some quests."
L["BarDesc_layer_dragonriding"] = "Whether you are skyriding."
L["BarDesc_layer_resting"] = "Whether you are resting in a city or inn."
L["BarDesc_layer_location"] = "Whether you are indoors or outdoors."
L["BarDesc_layer_fishing"] = "Whether you have a fishing pole equipped."


-----------------------------------------------
---------------What's New----------------------
-----------------------------------------------
-- shown once per account when LATEST_VERSION_NUM in Photon.lua changes, see GUI/WhatsNewWindow.lua.
-- to show another text for a version, add it here under a new key and set WHATS_NEW_TEXT in Photon.lua to that key
L["WhatsNew_Title"] = "Photon %s"
L["WhatsNew_Text"] = [[
Welcome to the beta release of Photon!
Please help out by posting any bugs and suggestions on Curse or github.com/rhean/Photon

New in 0.5.1:
- Skyriding abilities can be rearranged on Photon bars by dragging them.
- Skyriding, Vehicle, Possess and Override now always take over the bar, even when another condition is on at the same time.
]]
L["WhatsNew_ShowOlder"] = "Show Older Changes"
L["WhatsNew_HideOlder"] = "Hide Older Changes"

L["WhatsNew_Older"] = [[
New in 0.5:
- A new shape has been added: Arc
- In bar edit mode you can drag the handles on the selected bar's corners and edges to change its padding.
- Circles have a new Flatten option that squeezes the circle towards a corner-to-corner line.
- The profile page has been redesigned. A new profile can copy just the layout of another profile: its bars, settings and keybinds, with empty buttons.
- Clearer warnings when copying over a profile or making one with a name that is already taken.
- Pet abilities and pet commands (Attack, Follow, Passive and so on) can be dragged onto regular bars from the pet spellbook or the pet bar.
- Holding Shift, Ctrl or Alt while dropping something on a button puts it on that modifier's page, also when the page is empty.
- A macro dropped on the pet bar goes back to the button it came from.
- Passive abilities can no longer be put on buttons.
- Turning off True Circle keeps the circle's current shape.
- Fixed a login error on Mists of Pandaria Classic.
- Changing profile always reloads the UI.
- Macros that cast a pet spell, like /cast Growl, show the pet's spell.
- Profile switching by specialization has been removed. Your profiles are all still there, and characters that used it are told once which profiles they had. To keep different buttons for each specialization, turn on Multi Spec in a bar's settings.

New in 0.4.5:
- True Circle option for circle shapes, which locks the vertical and horizontal padding together.
- Macros with conditions like [mounted], [flyable] or [outdoors] change the icon more reliably.
- Macros with a target condition, like [@focus], check range against the right target when it changes.
- Fixed an error when changing profiles.
- Fixed an error when changing the number of buttons on a menu bar.
- A new pet bar gets all its buttons and the other settings of the default pet bar when created.
- Fixed a potential issue where removing multiple bars in a row could remove the wrong one.

New in 0.4.4:
- Keybinds with Shift, Control or Alt pages will only grab the input if the macro exists.
- Button edit mode outlines each button instead of covering it with "Edit".
- Button edit mode always shows the keybinds, even on bars that hide the bind text.

New in 0.4.3:
- Binding a key that is also bound in Blizzard's keybinds now tells you so, on screen and in the chat.
- Bars that have pages for Shift, Control or Alt active will now bind those as well. So a button bound to 5 with Shift active as a page will override Shift+5 from Blizzard's config.
- The What's New window has a button to show older releases and can be opened with /photon changelog.
- The pet bar updates when your pet learns a new ability.
- The bar config has been edited to clarify some options.
- New tooltips added and some have been changed.
- Buttons in the bar config now show their tooltips.
- The Stance hide condition only shows for classes with stances.

New in 0.4.2:
- Totem Bar for shamans on Forever: your Call of the Elements, the four totem slots and Totemic Recall as Photon buttons, with keybinds, skins and the usual bar options. Right-click a slot to choose its totem, or the Call button to switch between Calls. Empty slots show their element, and spells you haven't learned yet are greyed out.
- Bars keep their buttons when you shrink them, so a button comes back with its macro and keybind if you grow the bar again.
- Bar scale now changes in steps of 1% instead of 5%.
- Dragging a spell whose name changes in the spellbook, like Call Pet, onto a button now makes a macro that works.
- Macros made by dragging spells, mounts and pets no longer start with a "#autowrite" line.

New in 0.4.1:
- The greyed-out text in the button editor now updates while you type.
- Buttons with only an icon and no macro can now be interacted with.
- The Anchor To list shows every bar again. Bars that would anchor in a circle are greyed out.
- The top of the button editor has been cleaned up: only the relevant elements show for each class, and they should no longer overflow.
- The "?" help in the button editor only shows for classes with stances or forms.
- The Stance option no longer shows for classes without stances.
- More contrast in the button editor, so the info boxes should be clearer.

New in 0.4:
- The Button Backdrop colour can now be changed, to tint the border around action bar buttons.
- The Icon Tint can now be changed, to change the overlay colour on action bar buttons.
- It's now possible to override the visuals of individual buttons. The bar config has a button to reset all the buttons on its bar.
- The default cast bar and mirror timers (breath, fatigue) are now hidden the same way as the other default bars.
- The bar editor now always has a bar selected when it opens.
- The editors have lighter backgrounds, grey buttons, a brighter selection highlight on bars and easier-to-read checkboxes.

New in 0.3:
- "Lock All" and "Unlock All" buttons in the bar options, to lock or unlock every bar at once.
- Button editor: new Expand option that shows every stance or form side by side instead of in tabs, giving you a full overview of what a button does.
- The replacement bars (vehicle, possess, override and dragonriding) now have their own Replacements category in Bar Conditions, to make it clear which bars have special functions.
- Vehicle bars are back on Forever. The game has keybinds for them, so we can assume vehicles will be used in some form.
- Fixed the default action bars sometimes becoming visible after a cinematic.
- Bars with more than one column no longer squash their buttons together when placed at the edge of the screen.

New in 0.2.5:
- Button fallback order option: choose whether an empty modifier state in a stance or form uses the modifier's macro or the stance's (classes with more than one stance or form).
- The options panel is slightly redesigned.
- Fix for failure when dragging a single spell out of a flyout, like one portal from Teleports.
- Fixed an error when using a flyout in combat.
- Fixed a potential error message caused by Edit Mode in combat when the default action bars are hidden.
- Fixed an error when moving a keybind with a few special characters to another button.
]]
