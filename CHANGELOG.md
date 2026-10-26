## 0.5.2

### New Shape
- A new shape has been added: Rectangle

### Profiles
- Copy Profile and Copy Layout can both copy into the current profile or into a new one.
- Copying a profile made by another class empties its stance and form pages.

### Fixes and Tweaks
- Flyout shows above unit frames and other action bars.
- Fixed an error when opening the button editor after the selected button was removed from its bar.

## 0.5.1

### Fixes and Tweaks
- Skyriding abilities can be rearranged on Photon bars by dragging them.
- Skyriding, Vehicle, Possess and Override now always take over the bar, even when another condition is on at the same time.

## 0.5

### New Shapes and configuration
- A new shape has been added: Arc
- In bar edit mode you can drag the handles on the selected bar's corners and edges to change its padding.
- Circles have a new Flatten option that squeezes the circle towards a corner-to-corner line.

### Profiles
- The profile page has been redesigned. A new profile can copy just the layout of another profile: its bars, settings and keybinds, with empty buttons.
- Clearer warnings when copying over a profile or making one with a name that is already taken.

### Pet changes
- Pet abilities and pet commands (Attack, Follow, Passive and so on) can be dragged onto regular bars from the pet spellbook or the pet bar.

### Fixes and Tweaks
- Holding Shift, Ctrl or Alt while dropping something on a button puts it on that modifier's page, also when the page is empty.
- A macro dropped on the pet bar goes back to the button it came from.
- Passive abilities can no longer be put on buttons.
- Turning off True Circle keeps the circle's current shape.
- Fixed a login error on Mists of Pandaria Classic.
- Changing profile always reloads the UI.
- Macros that cast a pet spell, like /cast Growl, show the pet's spell.

### Removed
- Profile switching by specialization. Your profiles are all still there, and characters that used it are told once which profiles they had. To keep different buttons for each specialization, turn on Multi Spec in a bar's settings.

## 0.4.5

### New
- True Circle option for circle shapes, which locks the vertical and horizontal padding together.

### Fixes and Tweaks
- Macros with conditions like [mounted], [flyable] or [outdoors] change the icon more reliably.
- Macros with a target condition, like [@focus], check range against the right target when it changes.
- Fixed an error when changing profiles.
- Fixed an error when changing the number of buttons on a menu bar.
- A new pet bar gets all its buttons and the other settings of the default pet bar when created.
- Fixed a potential issue where removing multiple bars in a row could remove the wrong one.

## 0.4.4

### Fixes and Tweaks
- Keybinds with Shift, Control or Alt pages will only grab the input if the macro exists.
- Button edit mode outlines each button instead of covering it with "Edit".
- Button edit mode always shows the keybinds, even on bars that hide the bind text.

## 0.4.3

### New
- Binding a key that is also bound in Blizzard's keybinds now tells you so, on screen and in the chat.
- Bars that have pages for Shift, Control or Alt active will now bind those as well. So a button bound to 5 with Shift active as a page will override Shift+5 from Blizzard's config.
- The What's New window has a button to show older releases and can be opened with /photon changelog.

### Fixes and Tweaks
- The pet bar updates when your pet learns a new ability.
- The bar config has been edited to clarify some options.
- New tooltips added and some have been changed.
- Buttons in the bar config now show their tooltips.
- The Stance hide condition only shows for classes with stances.

## 0.4.2

### New
- Totem Bar for shamans on Forever: It's added as its own type of bar and covers all the totems and Call of the Elements. You can right-click the buttons to select your totem and use the Call buttons as you usually would.

### Fixes and Tweaks
- Bars keep their buttons when you shrink them, so a button comes back with its macro and keybind if you grow the bar again.
- Bar scale now changes in steps of 1% instead of 5%.
- Spells whose name changes in the spellbook, like Call Pet, now get the correct macro.
- Macros made by dragging spells, mounts and pets no longer start with a "#autowrite" line.

## 0.4.1

### Fixes and Tweaks
- The greyed-out text in the button editor now updates while you type.
- Buttons with only an icon and no macro can now be interacted with.
- The Anchor To list shows every bar again. Bars that would anchor in a circle are greyed out.
- The top of the button editor has been cleaned up: only the relevant elements show for each class, and they should no longer overflow.
- The "?" help in the button editor only shows for classes with stances or forms.
- The Stance option no longer shows for classes without stances.
- More contrast in the button editor, so the info boxes should be clearer.

## 0.4

### New
- The Button Backdrop colour can now be changed, to tint the border around action bar buttons.
- The Icon Tint can now be changed, to change the overlay colour on action bar buttons.
- It's now possible to override the visuals of individual buttons. The bar config has a button to reset all the buttons on its bar.

### Fixes and Tweaks
- The default cast bar and mirror timers (breath, fatigue) are now hidden the same way as the other default bars.
- The bar editor now always has a bar selected when it opens.
- The editors have lighter backgrounds, grey buttons, a brighter selection highlight on bars and easier-to-read checkboxes.

## 0.3

### New
- "Lock All" and "Unlock All" buttons in the bar options, to lock or unlock every bar at once.
- Button editor: new Expand option that shows every stance or form side by side instead of in tabs, giving you a full overview of what a button does.
- The replacement bars (vehicle, possess, override and dragonriding) now have their own Replacements category in Bar Conditions, to make it clear which bars have special functions.
- Vehicle bars are back on Forever. The game has keybinds for them, so we can assume vehicles will be used in some form.

### Fixes
- Fixed the default action bars sometimes becoming visible after a cinematic.
- Bars with more than one column no longer squash their buttons together when placed at the edge of the screen.

## 0.2.5

### New
- Button fallback order option: choose whether an empty modifier state in a stance or form uses the modifier's macro or the stance's (classes with more than one stance or form).
- The options panel is slightly redesigned.

### Fixes
- Fix for failure when dragging a single spell out of a flyout, like one portal from Teleports.
- Fixed an error when using a flyout in combat.
- Fixed a potential error message caused by Edit Mode in combat when the default action bars are hidden.
- Fixed an error when moving a keybind with a few special characters to another button.
