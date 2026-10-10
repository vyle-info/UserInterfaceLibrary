# UserInterfaceLibrary

![preview](assets/preview.png)

## General Information:

This repository is a fork of [Obsidian](https://github.com/deividcomsono/Obsidian)
& maintained primarily for personal usage and modifications specified to other projects.

It is not maintained as a public facing library nor a stable third-party dependency / distribution.

## General Usage Disclaimer:

- Development is focused on the main team's personal projects and usage.
- Elements, components, implementations, and behavior may change or break without notice.
- No general user support, documentations, or compatibility notices are provided.
- This library may contain experimental & incomplete implementations which may break or cause issues.

## General Usage Credits:

This repository is a fork. Credit and applicable license notices for the original project and its contributors must be preserved in accordance with the original license (MIT)

---

# 2026-10-07

**Added Features:**
- `Library.KeybindMenu` with `SetCollapsed`, `ToggleCollapsed`, `SetVisibilityControl`, `SetSettingsOpen`, `ToggleSettings`, `RefreshSettings`
- Collapse support for the Keybind Menu
- Visibility settings panel for the Keybind Menu

**Fixed Features:**
- `AddImage` not having rounded corners
- Groupbox and tabbox scrollbars appearing incorrectly at DPI scales below 100%
- Position of other boxes and gaps under groupboxes and dependency boxes that start collapsed
- Window and loading titles truncating too early or leaving a huge gap before the icon

---

# 2026-10-03

**Changed Features:**
- Lucide icons now use a font
- Window and loading titles truncate with an ellipsis when too long

**Fixed Features:**
- Groupbox and tabbox icon accent colors not updating while popped out
- Window title icon not being positioned properly

---

# 2026-09-28

**Added Features:**
- `Icon` and `SetIcon` for Buttons and SubButtons
- `AddTabbox` for Tabbox tabs (`SubTab:AddTabbox`)

**Changed Features:**
- Tabbox tabs now have Type `"SubTab"`
- `Tabbox.ParentBox` can now be a Groupbox or a SubTab
- Button and SubButton text moved from `Base` to a new `Label` (`TextLabel`); `Base.Text` is now empty

**Fixed Features:**
- Window footer growing thicker with `CornerRadius`
- Tab buttons scrollbar being visible on higher DPI scales

---

# 2026-09-20

**Added Features:**
- `KeepDisabledValuePosition` for Dropdown (keeps `DisabledValues` in their `Values` order instead of moving them to the end)
- `SetMaxPopOutHeight(MaxHeight: number)` for popout groupboxes and tabboxes
- `SetPopOutWidth(Width: number)` for popout groupboxes and tabboxes
- `KeyPicker:SetMenuVisibility(Visible: boolean)`

**Fixed Features:**
- Text and UI elements sizing incorrectly at different DPI scales or screen resolutions
- Dropdown arrows overlapping the footer when scrolling

---

# 2026-09-04

**Added Features:**
- `TabButtonsStyle` for `CreateWindow` (`Gap`, `Padding`, `CornerRadius`, `Indicator`, `IndicatorWidth`, `IndicatorHeight`)
- `Library.Cursor` API:
  - `:ChangeCrossColor(Color)` / `:ResetCross()`
  - `:ChangeIcon(ImageId)` / `:ResetIcon()`
  - `:ChangeIconColor(Color)`
  - `:ChangeIconSize(Size)`
  - `:ResetCursor()`

**Deprecated Features:**
- `Library:ChangeCursorCrossColor`, `ResetCursorCross`, `ChangeCursorIcon`, `ChangeCursorIconColor`, `ChangeCursorIconSize` and `ResetCursorIcon` — use `Library.Cursor` instead

**Fixed Features:**
- KeyPickers not updating visually when toggled from the keybind menu

---

# 2026-08-31

**Added Features:**
- Tooltip support for tab buttons

**Changed Features:**
- ColorPickers use the smallest possible size on Mobile
- `SetValue` now sets the value but does not run callbacks when the element is disabled
- Search now switches to the tab with the most prominent match

**Fixed Features:**
- Notifications resizing incorrectly
- Toggle and Lock buttons being impossible to click on mobile
- KeyPickers and ColorPickers still being changeable in the UI while disabled
- KeyPickers and ColorPickers not updating visually when enabled/disabled

---

# 2026-08-25

**Added Features:**
- `Library:ApplyLucideIcon(ImageGui: ImageLabel | ImageButton, Icon: LucideIcon, Rotation: number?)`
- Groupbox/Tabbox pop-out into a draggable element (enabled by default)
- `:SetPoppedOut` and `:TogglePoppedOut` on Tabbox and Groupbox
- Fuzzy matching for sidebar and dropdown search
- Window snapping to screen edges/center (`Snapping`, `SnapAvoidCoreGui`, `SnapDistance`, `SnapMargin`)
- `Window:SetSnapping(Enabled, Distance?, Margin?)`
- Automatic WCAG contrast checking for themes

**Changed Features:**
- Dropdown search results are sorted by best match
- Matching a Tab/Groupbox name in search reveals all of its contents
- `ZIndex` changed to Siblings mode
- Increased the maximum width for Button KeyPickers
- Escape dismisses open menus/dialogs and releases text input focus (without toggling the window)
- `AccentColor` focus-border tween applied to all text inputs
- Hover feedback on KeyBox Execute and KeyPicker key display buttons

**Fixed Features:**
- `Tab:SetOrder()`
- `Dropdown:SetValueImages()`
- KeyPicker sliding animation sometimes causing errors
- Button KeyPickers not resizing properly to fit the text
- Mouse icon state not reverting properly
- Corner radiuses not changing properly on Dropdowns, KeyPickers, ColorPickers and certain Context Menus

---

# 2026-08-23

**Added Features:**
- Import/Export Theme and Configuration JSON through the UI

---

# 2026-08-20

**Added Features:**
- Groupbox Descriptions and `Groupbox:SetDescription()`

**Deprecated Features:**
- `:AddLeftGroupbox(...)` and `:AddRightGroupbox(...)` — use `:AddGroupbox({ ... })` instead

---

# 2026-08-17

**Added Features:**
- `ColorPicker.Resizable`
- `Window.AlwaysOnTop`, `Window:SetAlwaysOnTop`, `Loading.AlwaysOnTop`

**Changed Features:**
- TextBox focus now tweens the border between `OutlineColor` and `AccentColor`
- Hover highlights on Dropdown items, KeyPicker mode-select buttons and ColorPicker context menu items

**Fixed Features:**
- `MinContainerWidth` is now implemented properly

---

# 2026-08-12

**Added Features:**
- Virtualized large dropdown lists for faster opens and lower instance count
- Dropdowns no longer crash the game with over 10,000 values
- Dictionary `Values` support: key = selection identity, value = display label
- `Dropdown:SetValues` now prunes stale selections that are no longer in `Values`

**Changed Features:**
- `Dropdown.DisabledValues` and `Dropdown.ValueImages` now accept dictionary keys or labels
- `Dropdown:AddValues` on dictionary `Values` merges maps (or `key = label` for arrays)
- Sparse numeric tables are treated as arrays (value identity), not dictionaries

**Fixed Features:**
- Multi-dropdown dictionary keys being stripped to display labels ([Issue #109](#))

---

# 2026-07-11

**Changed Features:**
- Loading configs now triggers element callbacks even if their value hasn't changed

---

# 2026-07-09

**Changed Features:**
- Background Image now supports external URLs using `getcustomasset`

---

# 2026-07-07

**Added Features:**
- `Dropdown.DragSelect` and `Dropdown:SetDragSelect(Value: boolean)` (non-touch devices and Multi dropdowns only)
- `Animations.Groupbox`, `Animations.KeyPicker`

**Changed Features:**
- Notification appear and disappear animations are now smooth

**Fixed Features:**
- `Library.ToggleKeybind`

---

# 2026-07-05

**Added Features:**
- `Animations.ToggleWindow`
- `Animations.TabSwitch`, `TabTransitionTime`, `TabSwipeOffset`, `TabSwipeFrom` (`left` / `right` / `top` / `bottom`)
- `Animations.Dropdown`
- `Window:SetAnimations(Animations, TabTransitionTime, TabSwipeOffset, TabSwipeFrom)`
- `DisableCollapsing` for `AddLeftGroupbox` and `AddRightGroupbox`

**Changed Features:**
- KeyPickers now allow setting the bind to any modifier key if it was only pressed and not held down

**Fixed Features:**
- `Library.ToggleKeybind` not working properly with modifier keys
- KeyPickers firing while picking a bind for any KeyPicker

---

# 2026-07-02

**Changed Features:**
- Save Manager and Theme Manager refactored
- Save Manager now saves the keybind menu visibility and position
- Save Manager and Theme Manager now show the default theme and autoloaded config inside their dropdowns

**Fixed Features:**
- Dialog buttons breaking with Destructive buttons when `ThemeManager:SetDefaultTheme` was used

---

# 2026-07-01

**Added Features:**
- Confirmation dialogs for destructive actions in Save Manager and Theme Manager
- Groupbox collapsed state now saves in configuration files

---

# 2026-06-28

**Added Features:**
- `Groupbox:SetVisible(Visible: boolean)`, `Groupbox:Show()`, `Groupbox:Hide()`
- `Groupbox:AddTabbox()`
- Collapse arrow for Groupboxes (disable with the `DisableCollapsing` option)
- `TitleColor` and `DescriptionColor` options for `Library:Notify({ ... })`
- `Library.Scheme.BackgroundImage` and a "Background Image" option in Theme Manager
- `Library.Window`

**Changed Features:**
- `Tabbox:AddTab()` now returns `Tab` and `TabStoringIndex`
- Window `BackgroundImage` can now be set even when it wasn't set during creation

**Fixed Features:**
- Searching restoring hidden elements each time
- `attempt to index nil with 'Destroy'` errors in `Dropdown:BuildDropdownList()`
- Rounded corners on Tab buttons inside Tabbox
- Tab button spacing when a tab has no name

---

# 2026-06-26

**Added Features:**
- `:Destroy()` function for every element
- `Volume` option for `Library:Notify()`
- KeyPicker for buttons (only works with `Press` mode; the button's callback receives `FromKeyPicker`, which is `true` when activated by the key picker)
- `Icon` and `IconPosition` parameters for `Library:AddDraggableLabel()` and `Library:AddDraggableButton()`
- `Slider.AllowRightClickInput` (right-click / double-tap to type a specific value)
- `Library:AddDraggableImageButton()`

**Changed Features:**
- Individual rounded corners for certain elements (dropdowns, right-click context menus)
- Right-click context menus now connect visually to their buttons
- `Dropdown:GetActiveValues()` → `Dropdown:GetActiveValues(ReturnCountForMulti: boolean)` (`true` returns the value count)
- The dropdown menu now closes if its button is not visible on screen
- Other KeyPickers no longer trigger while you are selecting a keybind
- Mouse button KeyPickers no longer trigger while the UI is open
- Draggable labels, buttons, menus and image buttons now find a position where they won't overlap other draggable elements

**Fixed Features:**
- `AllowNull` not working properly with Multi dropdowns
- Dropdown context menu not matching button size on the X axis

**Optimized Features:**
- The Obsidian `Library` table is now properly garbage collected after calling `Library:Unload()`

---

# 2026-04-21

**Added Features:**
- `SaveManager:SetLoadingOrder(enabled: boolean, order: { })`

---

# 2026-04-05

**Added Features:**
- `Library.Scheme.DestructiveColor`
- `Library:CreateLoading(LoadingInfo)` — see the [loading documentation](http://docs.mspaint.cc/obsidian/core/library/loading)

---

# 2026-04-03

**Added Features:**
- `Tab:SetVisible()`

---

# 2026-03-28

**Added Features:**
- `Dropdown.FormatListValue(Value)`
  > Randomized formatting is not preserved, as the function is called every time the context menu is rebuilt.

---

# 2026-03-24

**Added Features:**
- `Input.VerifyValue(NewValue: string): boolean`
- `Input.ClearTextOnBlur`
- `KeyPicker.Blacklisted`, `KeyPicker.BlacklistedModifiers`
- `KeyPicker.Whitelisted`, `KeyPicker.WhitelistedModifiers`

**Changed Features:**
- `CornerRadius` now applies to more elements
- Slider height increased by 1px

---

# 2026-03-17

**Added Features:**
- `Window:SetCornerRadius(Radius: number)`

**Fixed Features:**
- `Window:SetFooter` not changing the label text
- Footer background not resizing properly
- Tab buttons not respecting corner radius

---

# 2026-01-16

**Added Features:**
- `Library:ResetCursorIcon()`
- `Library:ChangeCursorIcon(ImageId: string)`
- `Library:ChangeCursorIconSize(Size: UDim2)`

---

## 2025

# 2025-12-30

**Breaking changes**

| Old | New |
| --- | --- |
| `Library.Scheme.Red` | `Library.Scheme.RedColor` |
| `Library.Scheme.Dark` | `Library.Scheme.DarkColor` |
| `Library.Scheme.White` | `Library.Scheme.WhiteColor` |
| `WindowInfo.Compact` | `WindowInfo.SidebarCompacted` |
| `WindowInfo.SidebarMinWidth` | `WindowInfo.MinSidebarWidth` |
| `WindowInfo.MinContentWidth` | `WindowInfo.MinContainerWidth` |

**Removed Features:**
- `WindowInfo.SidebarCollapseThreshold`
- `WindowInfo.SidebarHighlightCallback` function
- `WindowInfo.InitialSidebarWidth`
- `WindowInfo.InitialSidebarScale`

**Added Features:**
- `WindowInfo.DisableCompactingSnap` → see `WindowInfo.CompactWidthActivation`

**Changed Features:**
- `WindowInfo.SidebarCompactWidth` default changed from `54` to `48`
- `Library:SetWatermark` is deprecated, since `Library:AddDraggableLabel` offers the same functionality

**Fixed Features:**
- DPI Scaling

---

# 2025-12-18

**Security**
- Patched static key bypass inside Key Box
  - `AddKeyBox` now only takes the callback function
  - The callback only returns the provided key; you must implement your own handler inside it

---

# 2025-11-09

**Added Features:**
- `Library.ImageManager` — see the [custom asset icons docs](https://docs.mspaint.cc/obsidian/core/library/utility#custom-asset-icons)

---

# 2025-11-02

**Changed Features:**
- Warning Box now follows the Obsidian UI style (rounded corners with outlines)
- Watermark now resizes correctly with new line characters

---

# 2025-11-01

**Changed Features:**
- Ignored indexes (`SaveManager.SetIgnoreIndexes`) are no longer applied when loading a configuration that contains them

---

# 2025-10-05

**Added Features:**
- Modifier key support in KeyPicker (e.g. `LCtrl + E`)

**Fixed Features:**
- `DoClick` not calling the correct callbacks

---

# 2025-09-17

**Added Features:**
- Custom icon support (`rbxasset`, `rbxassetid`, `rbxthumb`, `getcustomasset`) for Tabs and Groupboxes

---

# 2025-09-14

**Added Features:**
- `Press` mode for `KeyPicker`

---

# 2025-08-19

**Fixed Features:**
- `KeyPicker` in Toggle mode not working properly when Key is `nil`

---

# 2025-08-12

**Fixed Features:**
- `Tab:UpdateWarningBox()` not resizing properly

---

# 2025-08-10

**Added Features:**
- Optional `LockSize` option for `Tab:UpdateWarningBox()` to cap the warning box at 3.25× the Tab Container size
- Mouse button 3 (middle click) support

---

# 2025-07-17

**Added Features:**
- `Description` parameter for `Window:AddTab()` to set a tab description
- `DisableSearch` option in `Library:CreateWindow()`'s `WindowInfo` to disable the window search box

**Changed Features:**
- `Window:AddTab()` now accepts a table with `Name`, `Icon` (optional) and `Description` (optional)

---

# 2025-07-15

**Added Features:**
- Watermark support
- `Library:SetWatermarkVisibility()` to toggle watermark visibility
- `Library:SetWatermark()` to set the watermark text

---

# 2025-07-14

**Added Features:**
- `AddImage` component

---

# 2025-07-13

**Added Features:**
- `AddViewport` component

**Changed Features:**
- Updated Lucide icons to the latest version
- Lucide icons now use `getcustomasset` to bypass ContentProvider detections

---

# 2025-07-12

**Added Features:**
- `ThemeManager:SetDefaultTheme()` to set the default theme
- `BackgroundImage` parameter in the `Window` constructor

**Changed Features:**
- `Library:SafeCallback()` now handles errors correctly and returns all values (previously only the first)

---

# 2025-07-02

**Added Features:**
- Dropdown support for `AddDependencyBox` and `AddDependencyGroupBox`

---

# 2025-06-15

**Fixed Features:**
- `Library:Validate()` now ignores arrays (setting `Modes` on `AddKeyPicker` previously failed)

---

# 2025-06-04

**Added Features:**
- `Notify.Persist` and `Notify:Destroy()` for easier management of persistent notifications
- `Icon` parameter on the Groupbox constructor, matching the accent color

---

# 2025-05-17

**Added Features:**
- `AddDependencyBox` and `AddDependencyGroupBox` methods on the `Groupbox` class

---

## 2024

# 2024-01-18

> The original entry was dated `18.01.2024`; this may be a typo for 2025, but the date is kept as written.

**Added Features:**
- Hover animation for Buttons
- `Risky` option for Buttons

**Changed Features:**
- Toggle's Checkbox is now a Switch (Checkbox is still available via `AddCheckbox`)
- Dropdown disabled values moved to the bottom

**Fixed Features:**
- DPI scale issues (title wrapping, slider fill bar and dropdown menu size)
