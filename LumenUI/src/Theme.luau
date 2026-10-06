-- All colours and fonts live here so a custom theme is one table away.

local Theme = {}

Theme.Dark = {
	Background = Color3.fromRGB(22, 22, 28),
	Section = Color3.fromRGB(28, 28, 36),
	Surface = Color3.fromRGB(38, 38, 48),
	SurfaceHover = Color3.fromRGB(49, 49, 62),
	Stroke = Color3.fromRGB(58, 58, 72),

	Accent = Color3.fromRGB(94, 129, 244),

	Text = Color3.fromRGB(235, 235, 242),
	TextDim = Color3.fromRGB(150, 150, 168),

	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	TextSize = 14,

	Corner = UDim.new(0, 6),
}

Theme.Light = {
	Background = Color3.fromRGB(244, 244, 248),
	Section = Color3.fromRGB(236, 236, 242),
	Surface = Color3.fromRGB(255, 255, 255),
	SurfaceHover = Color3.fromRGB(232, 232, 240),
	Stroke = Color3.fromRGB(205, 205, 218),

	Accent = Color3.fromRGB(70, 105, 235),

	Text = Color3.fromRGB(30, 30, 40),
	TextDim = Color3.fromRGB(105, 105, 125),

	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	TextSize = 14,

	Corner = UDim.new(0, 6),
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
