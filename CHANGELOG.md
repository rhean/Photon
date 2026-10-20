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
