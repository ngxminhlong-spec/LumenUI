local Create = require(script.Parent.Parent.Util.Create)
local Signal = require(script.Parent.Parent.Util.Signal)
local Tween = require(script.Parent.Parent.Util.Tween)

local Button = {}
Button.__index = Button

function Button.new(parent, theme, options)
	local self = setmetatable({}, Button)
	self.Clicked = Signal.new()

	local button = Create("TextButton", {
		Name = "Button",
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = options.Name or "Button",
		Font = theme.Font,
		TextSize = theme.TextSize,
		TextColor3 = theme.Text,
		Parent = parent,
	}, {
		Create("UICorner", { CornerRadius = theme.Corner }),
	})

	self.Instance = button

	button.MouseEnter:Connect(function()
		Tween.to(button, { BackgroundColor3 = theme.SurfaceHover }, 0.12)
	end)

	button.MouseLeave:Connect(function()
		Tween.to(button, { BackgroundColor3 = theme.Surface }, 0.12)
	end)

	button.MouseButton1Down:Connect(function()
		Tween.to(button, { BackgroundColor3 = theme.Accent }, 0.08)
	end)

	button.MouseButton1Up:Connect(function()
		Tween.to(button, { BackgroundColor3 = theme.SurfaceHover }, 0.12)
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
