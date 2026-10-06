local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lumen = require(ReplicatedStorage:WaitForChild("LumenUI"))

local window = Lumen.CreateWindow({
	Title = "Lumen Demo",
	ToggleKey = Enum.KeyCode.RightShift,
	-- Theme = { Accent = Color3.fromRGB(235, 90, 120) }, -- try overriding anything from Theme.luau
})

---- Main tab
local main = window:AddTab("Main")

main:AddLabel({ Text = "Press RightShift to hide or show this window." })

main:AddButton({
	Name = "Say hello",
	Callback = function()
		window:Notify({
			Title = "Hello!",
			Content = "This notification fades out on its own.",
			Duration = 3,
		})
	end,
})

local sound = main:AddSection("Audio")

sound:AddToggle({
	Name = "Enable music",
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
