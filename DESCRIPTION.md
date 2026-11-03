# Photon

Photon is an action bar addon where every button holds a macro instead of a fixed action. You can type the macro yourself, or drag a spell, item, mount, pet ability or Blizzard macro onto the button and Photon writes the macro for you. You can have any number of bars, each with any number of buttons and a choice of shapes, and place them anywhere on the screen.

Photon is based on **Neuron** by Britt W. Yazel and **Ion** by Connor H. Chenoweth.

## Bars

- Make as many action bars as you need. Each bar has its own number of buttons, columns, scale, padding, alpha and more visual options.
- Bars can be laid out as **Linear**, **Rectangle**, **Circle** or **Arc**. All of the shapes can be manipulated in various ways to change their geometry.
- In bar edit mode, bars are moved by dragging, and padding can be changed by dragging the handles on the bar's corners and edges. Bars can also be anchored to each other to make it easy to move several bars at once.
- Visibility can follow game conditions: combat, group, stealth, resting, target, pet, vehicle and others. Bars can also auto-hide until moused over, fade in at a set speed, or fade while their buttons are on cooldown.
- Per-bar visual options include keybind and macro name text, stack and charge counts, out-of-range colouring, cooldown counters, spell alert glows, tooltips and more.

## States

- A state is a condition the bar reacts to, like Shift being held, being in Bear Form or being stealthed. When it's active, the bar's buttons switch to the macros set for that state, the same way the default bar changes for stance or stealth. In the button editor, each state the bar has turned on gets its own macro.
- States are available for stance or form, stealth, Shift / Ctrl / Alt, combat, target, pet, vehicle and more.
- A bar can also follow Blizzard's action bar pages 1–6.
- With **Multi Spec**, a bar keeps a separate set of buttons for each specialization.
- Holding Shift, Ctrl or Alt while dropping something on a button puts it in that modifier's state.

## Buttons and macros

- The button editor shows a button's macro, icon, name and notes, along with its states and the macro for each.
- Icons follow macro conditions, and range checks follow the macro's target, such as `[@focus]`.
- A macro uses the icon of its current spell or item unless an icon has been set manually.
- Blizzard's spell flyouts, like Teleports or pet summons, open from Photon buttons.
- Pet abilities and pet commands can be dragged from the spellbook or the pet bar onto the pet bar or any other action bar.

## Other bars

Photon also has its own versions of most of the other default bars: pet, bag, menu, XP, reputation, cast, mirror, extra action, zone ability and vehicle exit. Each one can replace its Blizzard counterpart, or Blizzard's can be kept. In Forever, shamans also get a totem bar with Call of the Elements, the four totem slots and Totemic Recall.

## Keybinds

- In binding mode, hover over a button and press a key to bind it. Escape clears the binding.
- Photon tells you, on screen and in chat, when the key is also bound in Blizzard's keybinds.
- Bars with Shift, Ctrl or Alt states also bind those combinations. For example, if a bar has a Ctrl state and you bind F1 to one of its buttons, Ctrl-F1 runs that button's Ctrl macro. The combination is only taken over while that state has a macro.

## Profiles

- Profiles can be switched, created, copied, reset and deleted.
- **Copy Layout** brings over another profile's bars, settings and keybinds, but leaves the buttons empty. It's useful for setting up a new character with the same layout as you've built for another one.
- Copying a profile made by another class leaves out its stance and form states.

## Skins

Buttons can be skinned with [Masque](https://www.curseforge.com/wow/addons/masque). Each bar is its own Masque group.

## Commands

- `/photon`: open Photon's settings
- `/photon bar`: bar edit mode
- `/photon button`: button edit mode and the button editor
- `/photon bind`: binding mode
- `/photon changelog`: show the release notes

The minimap icon opens the same editors. Settings are also under Options → AddOns → Photon.

## Supported versions

Retail, Mists of Pandaria Classic, Burning Crusade Anniversary, Classic Era and Forever. Each version only has the bars and options its game supports. The Classic versions are tested less thoroughly than Retail and Forever, so please report any bugs you find.

## Feedback

Please report bugs and suggestions in the comments here, or on GitHub: [github.com/rhean/Photon](https://github.com/rhean/Photon/issues).
