local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lumen = require(ReplicatedStorage:WaitForChild("LumenUI"))

local window = Lumen.CreateWindow({
	Title = "Lumen Demo",
	Subtitle = "v" .. Lumen.Version,
	ToggleKey = Enum.KeyCode.RightShift,
	-- Launcher = true, -- force the round show/hide button (it is automatic on phones and tablets)
	-- Preset = "Light",
	-- Theme = { Accent = Color3.fromRGB(235, 90, 120) }, -- try overriding anything from Theme.luau
})

---- Main tab
local main = window:AddTab("Main")

main:AddLabel({ Text = "Drag the title bar to move. RightShift or the round button toggles the window." })

main:AddButton({
	Name = "Say hello",
	Style = "Primary",
	Callback = function()
		window:Notify({
			Title = "Hello!",
			Content = "Tap a notification to dismiss it early.",
			Duration = 4,
		})
	end,
})

local sound = main:AddSection("Audio")

sound:AddToggle({
	Name = "Enable music",
	Description = "Background tracks in menus",
	Default = true,
	Callback = function(on)
		print("Music:", on)
	end,
})

sound:AddSlider({
	Name = "Volume",
	Min = 0,
	Max = 100,
	Default = 60,
	Increment = 5,
	Suffix = "%",
	Callback = function(value)
		print("Volume:", value)
	end,
})

---- Settings tab
local settings = window:AddTab("Settings")

local profile = settings:AddSection("Profile")

profile:AddTextBox({
	Name = "Nickname",
	Placeholder = "Enter a name",
	Callback = function(text, enterPressed)
		print("Nickname:", text, "enter:", enterPressed)
	end,
})

local quality = profile:AddDropdown({
	Name = "Quality",
	Options = { "Low", "Medium", "High", "Ultra" },
	Default = "Medium",
	Callback = function(choice)
		print("Quality:", choice)
	end,
})

-- components return objects, so you can read or change them later
quality.Changed:Connect(function(choice)
	print("Changed signal got:", choice)
end)

local advanced = settings:AddSection("Advanced", { Collapsible = true, Collapsed = true })

advanced:AddSlider({ Name = "Smoothing", Min = 0, Max = 1, Default = 0.5, Increment = 0.05 })
advanced:AddDropdown({
	Name = "Region",
	Options = { "Auto", "Europe", "North America", "South America", "Asia", "Oceania", "Africa" },
	Default = "Auto",
})

---- Alerts tab
local alerts = window:AddTab("Alerts")
local types = alerts:AddSection("Notification types")

for _, kind in { "Info", "Success", "Warning", "Error" } do
	types:AddButton({
		Name = kind,
		Callback = function()
			window:Notify({ Title = kind, Content = "This is a " .. string.lower(kind) .. " notification.", Type = kind })
		end,
	})
end
