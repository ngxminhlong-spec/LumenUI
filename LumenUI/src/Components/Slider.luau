local UserInputService = game:GetService("UserInputService")

local Create = require(script.Parent.Parent.Util.Create)
local Signal = require(script.Parent.Parent.Util.Signal)
local Tween = require(script.Parent.Parent.Util.Tween)

local Slider = {}
Slider.__index = Slider

local function isPointer(input: InputObject)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

function Slider.new(parent, theme, options)
	local self = setmetatable({}, Slider)
	self.Changed = Signal.new()

	self._callback = options.Callback
	self._min = options.Min or 0
	self._max = options.Max or 100
	self._increment = options.Increment or 1
	self._suffix = options.Suffix or ""
	self._value = math.clamp(options.Default or self._min, self._min, self._max)
	self._connections = {}

	local row = Create("Frame", {
		Name = "Slider",
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		Parent = parent,
	}, {
		Create("UICorner", { CornerRadius = theme.Corner }),
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}),
		Create("TextLabel", {
			Name = "Title",
			Position = UDim2.fromOffset(0, 6),
			Size = UDim2.new(0.7, 0, 0, 20),
			BackgroundTransparency = 1,
			Text = options.Name or "Slider",
			Font = theme.Font,
			TextSize = theme.TextSize,
			TextColor3 = theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})

	self._valueLabel = Create("TextLabel", {
		Name = "Value",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 6),
		Size = UDim2.new(0.3, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = theme.Font,
		TextSize = theme.TextSize,
		TextColor3 = theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	})

	-- the hit box is taller than the visible bar so it's easy to grab on mobile
	local hitbox = Create("Frame", {
		Name = "Hitbox",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -4),
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Parent = row,
	})

	self._track = Create("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = theme.Stroke,
		BorderSizePixel = 0,
		Parent = hitbox,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	self._fill = Create("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Parent = self._track,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	self.Instance = row

	local dragging = false

	local function updateFromX(x: number)
		local width = self._track.AbsoluteSize.X
		if width <= 0 then
			return
		end
		local alpha = math.clamp((x - self._track.AbsolutePosition.X) / width, 0, 1)
		self:Set(self._min + (self._max - self._min) * alpha)
	end

	hitbox.InputBegan:Connect(function(input)
		if isPointer(input) then
			dragging = true
			updateFromX(input.Position.X)
		end
	end)

	table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			updateFromX(input.Position.X)
		end
	end))

	table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
		if isPointer(input) then
			dragging = false
		end
	end))

	self:_render(false)
	return self
end

function Slider:_render(animate: boolean)
	local alpha = (self._value - self._min) / (self._max - self._min)
	local size = UDim2.fromScale(alpha, 1)

	if animate then
		Tween.to(self._fill, { Size = size }, 0.06)
	else
		self._fill.Size = size
	end

	self._valueLabel.Text = tostring(self._value) .. self._suffix
end

function Slider:Set(value: number, silent: boolean?)
	-- snap to the increment, then clamp. The round() cleans up float noise like 0.30000000004
	value = math.floor((value - self._min) / self._increment + 0.5) * self._increment + self._min
	value = math.clamp(math.round(value * 10000) / 10000, self._min, self._max)

	if value == self._value then
		return
	end

	self._value = value
	self:_render(true)

	if not silent then
		self.Changed:Fire(value)
		if self._callback then
			task.spawn(self._callback, value)
		end
	end
end

function Slider:Get(): number
	return self._value
end

function Slider:Destroy()
	for _, connection in self._connections do
		connection:Disconnect()
	end
	self.Changed:Destroy()
	self.Instance:Destroy()
end

return Slider
