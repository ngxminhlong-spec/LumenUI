local Create = require(script.Parent.Parent.Util.Create)
local Signal = require(script.Parent.Parent.Util.Signal)
local Tween = require(script.Parent.Parent.Util.Tween)
local Device = require(script.Parent.Parent.Util.Device)
local Interact = require(script.Parent.Parent.Util.Interact)

local WHITE = Color3.new(1, 1, 1)

local Button = {}
Button.__index = Button

-- options: Name, Callback, Style = "Default" | "Primary"
function Button.new(parent, theme, options)
	local self = setmetatable({}, Button)
	self.Clicked = Signal.new()

	local primary = options.Style == "Primary"

	local idle = primary and theme.Accent or theme.Surface
	local hover = primary and theme.Accent:Lerp(WHITE, 0.14) or theme.SurfaceHover
	local press = primary and theme.Accent:Lerp(Color3.new(0, 0, 0), 0.18) or theme.Surface:Lerp(theme.Accent, 0.35)

	local scale = Create("UIScale", { Scale = 1 })

	local children = {
		Create("UICorner", { CornerRadius = theme.Corner }),
		scale,
	}

	if primary then
		-- a soft top-to-bottom shade gives the flat colour a bit of depth
		table.insert(children, Create("UIGradient", {
			Color = ColorSequence.new(WHITE, Color3.fromRGB(205, 205, 218)),
			Rotation = 90,
		}))
	else
		table.insert(children, Create("UIStroke", {
			Color = theme.Stroke,
			Transparency = 0.5,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}))
	end

	local button = Create("TextButton", {
		Name = "Button",
		Size = UDim2.new(1, 0, 0, Device.rowHeight()),
		BackgroundColor3 = idle,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = options.Name or "Button",
		Font = primary and theme.FontBold or theme.Font,
		TextSize = theme.TextSize,
		TextColor3 = primary and WHITE or theme.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = parent,
	}, children)

	self.Instance = button

	Interact.bind(button, function(state)
		local color = if state == "Press" then press elseif state == "Hover" then hover else idle
		Tween.to(button, { BackgroundColor3 = color }, 0.12)
		Tween.to(scale, { Scale = state == "Press" and 0.98 or 1 }, 0.1)
	end)

	button.Activated:Connect(function()
		self.Clicked:Fire()
		if options.Callback then
			task.spawn(options.Callback)
		end
	end)

	return self
end

function Button:SetText(text: string)
	self.Instance.Text = text
end

function Button:Destroy()
	self.Clicked:Destroy()
	self.Instance:Destroy()
end

return Button
