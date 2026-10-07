# Lumen UI

A small modular UI library for Roblox, written in Luau. Works with mouse, keyboard and **touch**.

- Responsive window: shrinks to fit any screen and switches from a sidebar to a swipeable tab strip on phones
- Round launcher button on phones / tablets (no keyboard needed to show or hide the window)
- Touch-sized rows, sliders that don't fight page scrolling, hover states that don't stick on touch
- Gradient accents, soft shadows, animated toggles / dropdowns / notifications
- Dark and Light presets, every colour overridable

## Project tree

```
LumenUI/
├── default.project.json        Rojo project file
├── README.md
├── examples/
│   └── Demo.client.luau        Example LocalScript (Studio)
├── executor/
│   ├── Loader.lua              Downloads every file from a URL and links them
│   ├── LumenUI.bundle.lua      Whole library in ONE file (generated)
│   ├── LumenUI.demo.lua        Bundle + demo window, paste-and-run (generated)
│   └── demo_body.lua           The demo code that gets appended to the bundle
├── tools/
│   └── bundle.py               Regenerates the two files above from src/
└── src/                        -> ReplicatedStorage.LumenUI
    ├── init.luau               Public API (Lumen.CreateWindow)
    ├── Theme.luau              Colours / fonts, Dark + Light presets
    ├── Core/
    │   ├── Window.luau         ScreenGui, responsive layout, drag, launcher, tabs
    │   ├── Tab.luau            Sidebar / tab-strip button + scrolling page
    │   ├── Section.luau        Titled (optionally collapsible) group of components
    │   ├── Container.luau      Mixin that adds AddButton/AddToggle/... to Tab & Section
    │   └── Notification.luau   Toast notifications (Info / Success / Warning / Error)
    ├── Components/
    │   ├── init.luau           Registry of all components
    │   ├── Label.luau
    │   ├── Button.luau
    │   ├── Toggle.luau
    │   ├── Slider.luau
    │   ├── TextBox.luau
    │   └── Dropdown.luau
    └── Util/
        ├── Create.luau         Instance builder
        ├── Signal.luau         Tiny event class (Connect / Once / Wait / Fire)
        ├── Tween.luau          TweenService wrapper
        ├── Device.luau         Touch / phone detection, row heights
        ├── Interact.luau       Hover + press states that work on mouse AND touch
        └── Drag.luau           Mouse / finger dragging with tap detection
```

## Usage

```lua
local Lumen = require(game.ReplicatedStorage.LumenUI)

local window = Lumen.CreateWindow({ Title = "My Hub", Subtitle = "v1.0" })
local tab = window:AddTab("Main")

tab:AddToggle({ Name = "God mode", Description = "You cannot die", Default = false, Callback = function(on) print(on) end })
```

Every `Add*` method returns an object with `:Set()` / `:Get()` (where it makes sense),
a `.Changed` signal and `:Destroy()`.

### Window options

| Option | Meaning |
| --- | --- |
| `Title`, `Subtitle` | Text in the title bar |
| `Size` | `UDim2` with the wanted size (default 580x400). It is shrunk automatically to fit the screen |
| `ToggleKey` | `Enum.KeyCode` that shows / hides the window (default `RightShift`, `false` = none) |
| `Launcher` | `true` / `false`: the draggable round show/hide button. Default: on for phones and tablets |
| `Preset` | `"Dark"` (default) or `"Light"` |
| `Theme` | Table of colour overrides, see `Theme.luau` (`Accent`, `Accent2`, `Background`, ...) |
| `Id` | Windows with the same `Id` (default: the title) replace each other, so re-running a script never stacks windows |
| `Parent` | Where the ScreenGui goes |

Window methods: `AddTab`, `Notify`, `SetTitle`, `SetVisible`, `Toggle`, `IsVisible`, `Destroy`, and a `.Destroyed` signal.

### Components

```lua
tab:AddLabel({ Text = "Hello" })
tab:AddButton({ Name = "Run", Style = "Primary", Callback = function() end })      -- Style: "Default" | "Primary"
tab:AddToggle({ Name = "ESP", Description = "optional second line", Default = true, Callback = function(on) end })
tab:AddSlider({ Name = "Speed", Min = 0, Max = 100, Default = 50, Increment = 5, Suffix = "%", Callback = function(v) end })
tab:AddTextBox({ Name = "Name", Placeholder = "...", Callback = function(text, enterPressed) end })
tab:AddDropdown({ Name = "Mode", Options = { "A", "B" }, Default = "A", Callback = function(choice) end })

local section = tab:AddSection("Advanced", { Collapsible = true, Collapsed = true })
section:AddToggle({ ... }) -- sections take the same Add* methods as tabs
```

### Notifications

```lua
window:Notify({ Title = "Saved", Content = "Settings stored.", Type = "Success", Duration = 4 })
-- Type: "Info" | "Success" | "Warning" | "Error".  Duration = 0 keeps it until tapped.
```

On desktop they stack in the bottom-right corner; on phones and narrow windows they drop in from the top.
Tap or click a notification to dismiss it.

## Mobile notes

- The window never gets bigger than the screen. Below ~520px wide the sidebar becomes a horizontally scrolling tab strip and the window gets taller.
- Rotating the device re-lays everything out live.
- The title bar can't be dragged off-screen, so the window can't get lost.
- The minimise button hides the window; the round launcher (or `ToggleKey`) brings it back. Without a launcher, minimising shows a hint about the key.
- Sliders freeze the page's scrolling while a finger is on them.

## Adding your own component

1. Create `src/Components/MyThing.luau` with a `MyThing.new(parent, theme, options)` constructor.
2. Add `MyThing = require(script.MyThing)` to `src/Components/init.luau`.
3. `tab:AddMyThing({...})` and `section:AddMyThing({...})` now exist.

Tip: use `Interact.bind(gui, function(state) ... end)` (`"Idle"`, `"Hover"`, `"Press"`) instead of `MouseEnter`/`MouseLeave`, and `Device.rowHeight()` for row heights, so your component behaves on touch screens too.

## Setup

Install [Rojo](https://rojo.space), then `rojo serve` and connect from Studio, or `rojo build -o Lumen.rbxl`.

## Executors

Executors can't read a folder of ModuleScripts, so there are two ways in:

**1. Paste and run (easiest, nothing to host).** Copy all of `executor/LumenUI.demo.lua` into your executor.

**2. Loader (files stay separate).** Upload `src/` and `executor/Loader.lua` to GitHub, then:

```lua
getgenv().LUMEN_BASE = "https://raw.githubusercontent.com/YOU/LumenUI/main/src/"
local Lumen = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOU/LumenUI/main/executor/Loader.lua"))()
```

Both fake `script` and `require` for each file, so the library source doesn't change at all.
If you edit anything in `src/`, run `python3 tools/bundle.py` to regenerate the bundles
(and add any new file to the `FILES` list in `executor/Loader.lua`).
The window parents itself to `gethui()` when it exists, otherwise `PlayerGui`.

## Changelog

### 0.2.0
- **Mobile:** responsive window + tab strip, launcher button, touch-sized controls, touch-safe hover states, scroll-locking sliders, top-anchored notifications
- **Look:** gradient accent, soft shadow, animated open/close, redesigned tabs / toggles / sliders / dropdowns / notifications, minimise button, notification types
- **Fixes:** Slider input connections leaked after the window was destroyed; Slider divided by zero when `Min == Max`; slider default wasn't snapped to `Increment`; re-running a script stacked duplicate windows; the window could be dragged off-screen; TextBox truncated text while editing; sticky hover on touch; dropdown lists grew without limit; too many tabs overflowed the sidebar; fixed 300px notifications overflowed small screens; notifications couldn't be dismissed
- **New:** `Button.Style`, `Toggle.Description`, collapsible sections, `Window.Destroyed`, `Window:SetTitle`, `Signal:Once` / `Signal:Wait`
