-- All colours and fonts live here so a custom theme is one table away.
--
--   Lumen.CreateWindow({ Preset = "Light" })
--   Lumen.CreateWindow({ Theme = { Accent = Color3.fromRGB(235, 90, 120) } })

local Theme = {}

Theme.Dark = {
	Background = Color3.fromRGB(17, 17, 23),
	Section = Color3.fromRGB(23, 23, 31),
	Surface = Color3.fromRGB(33, 33, 44),
	SurfaceHover = Color3.fromRGB(45, 45, 60),
	Stroke = Color3.fromRGB(54, 54, 71),

	-- Accent is used flat, Accent2 is the other end of the gradients
	Accent = Color3.fromRGB(104, 126, 255),
	Accent2 = Color3.fromRGB(168, 108, 255),

	Success = Color3.fromRGB(70, 206, 142),
	Warning = Color3.fromRGB(255, 187, 77),
	Error = Color3.fromRGB(255, 98, 116),

	Text = Color3.fromRGB(240, 240, 248),
	TextDim = Color3.fromRGB(144, 146, 170),

	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	TextSize = 14,

	Corner = UDim.new(0, 8),
	WindowCorner = UDim.new(0, 14),
}

Theme.Light = {
	Background = Color3.fromRGB(246, 246, 250),
	Section = Color3.fromRGB(237, 237, 244),
	Surface = Color3.fromRGB(255, 255, 255),
	SurfaceHover = Color3.fromRGB(233, 233, 242),
	Stroke = Color3.fromRGB(208, 208, 222),

	Accent = Color3.fromRGB(78, 104, 240),
	Accent2 = Color3.fromRGB(148, 90, 240),

	Success = Color3.fromRGB(34, 170, 108),
	Warning = Color3.fromRGB(230, 150, 30),
	Error = Color3.fromRGB(226, 70, 90),

	Text = Color3.fromRGB(28, 28, 40),
	TextDim = Color3.fromRGB(104, 106, 128),

	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	TextSize = 14,

	Corner = UDim.new(0, 8),
	WindowCorner = UDim.new(0, 14),
}

Theme.Presets = {
	Dark = Theme.Dark,
	Light = Theme.Light,
}

-- Copy a base theme and overwrite whatever the user passed in.
function Theme.extend(base, overrides)
	local result = table.clone(base)
	for key, value in overrides or {} do
		result[key] = value
	end
	return result
end

return Theme
