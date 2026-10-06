-- demo (Lumen is already defined above this line)

local window = Lumen.CreateWindow({
	Title = "Lumen Demo",
	ToggleKey = Enum.KeyCode.RightShift,
})

local main = window:AddTab("Main")

main:AddLabel({ Text = "Tap the X to close. RightShift toggles on keyboards." })

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

local audio = main:AddSection("Audio")

audio:AddToggle({
	Name = "Enable music",
	Default = true,
	Callback = function(on)
		print("Music:", on)
	end,
})

audio:AddSlider({
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

local settings = window:AddTab("Settings")
local profile = settings:AddSection("Profile")

profile:AddTextBox({
	Name = "Nickname",
	Placeholder = "Enter a name",
	Callback = function(text)
		print("Nickname:", text)
	end,
})

profile:AddDropdown({
	Name = "Quality",
	Options = { "Low", "Medium", "High", "Ultra" },
	Default = "Medium",
	Callback = function(choice)
		print("Quality:", choice)
	end,
})
