# Lumen UI

A small modular UI library for Roblox, written in Luau.

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
    │   ├── Window.luau         ScreenGui, drag, toggle key, tabs
    │   ├── Tab.luau            Sidebar button + scrolling page
    │   ├── Section.luau        Titled group of components
    │   ├── Container.luau      Mixin that adds AddButton/AddToggle/... to Tab & Section
    │   └── Notification.luau   Toast notifications
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
        ├── Signal.luau         Tiny event class
        └── Tween.luau          TweenService wrapper
```

## Usage

```lua
local Lumen = require(game.ReplicatedStorage.LumenUI)

local window = Lumen.CreateWindow({ Title = "My Hub" })
local tab = window:AddTab("Main")

tab:AddToggle({ Name = "God mode", Default = false, Callback = function(on) print(on) end })
```

Every `Add*` method returns an object with `:Set()` / `:Get()` (where it makes sense),
a `.Changed` signal and `:Destroy()`.

## Adding your own component

1. Create `src/Components/MyThing.luau` with a `MyThing.new(parent, theme, options)` constructor.
2. Add `MyThing = require(script.MyThing)` to `src/Components/init.luau`.
3. `tab:AddMyThing({...})` and `section:AddMyThing({...})` now exist.

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
If you edit anything in `src/`, run `python3 tools/bundle.py` to regenerate the bundles.
The window parents itself to `gethui()` when it exists, otherwise `PlayerGui`.
