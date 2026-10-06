local Create = require(script.Parent.Parent.Util.Create)
local Signal = require(script.Parent.Parent.Util.Signal)
local Tween = require(script.Parent.Parent.Util.Tween)

local Dropdown = {}
Dropdown.__index = Dropdown

function Dropdown.new(parent, theme, options)
	local self = setmetatable({}, Dropdown)
	self.Changed = Signal.new()

	self._theme = theme
	self._callback = options.Callback
	self._options = options.Options or {}
	self._selected = options.Default
	self._open = false

	-- root grows when the list opens, which pushes everything below it down
	local root = Create("Frame", {
		Name = "Dropdown",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = parent,
	}, {
		Create("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local header = Create("TextButton", {
		Name = "Header",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = root,
	}, {
		Create("UICorner", { CornerRadius = theme.Corner }),
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}),
		Create("TextLabel", {
			Name = "Title",
			Size = UDim2.new(0.5, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = options.Name or "Dropdown",
			Font = theme.Font,
			TextSize = theme.TextSize,
			TextColor3 = theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})

	self._valueLabel = Create("TextLabel", {
		Name = "Value",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -20, 0, 0),
		Size = UDim2.new(0.5, -20, 1, 0),
		BackgroundTransparency = 1,
		Font = theme.Font,
		TextSize = theme.TextSize,
		TextColor3 = theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header,
	})

	-- a plain ">" rotated 90 degrees: points down when closed, up when open
	self._arrow = Create("TextLabel", {
		Name = "Arrow",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Text = ">",
		Font = theme.FontBold,
		TextSize = theme.TextSize,
		TextColor3 = theme.TextDim,
		Rotation = 90,
		Parent = header,
	})

	self._list = Create("Frame", {
		Name = "List",
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		Visible = false,
		Parent = root,
	}, {
		Create("UICorner", { CornerRadius = theme.Corner }),
		Create("UIPadding", {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
		}),
		Create("UIListLayout", {
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	self.Instance = root

	header.MouseEnter:Connect(function()
		Tween.to(header, { BackgroundColor3 = theme.SurfaceHover }, 0.12)
	end)
	header.MouseLeave:Connect(function()
		Tween.to(header, { BackgroundColor3 = theme.Surface }, 0.12)
	end)
	header.Activated:Connect(function()
		self:_setOpen(not self._open)
	end)

	self:_buildOptions()
	self:_updateLabel()
	return self
end

function Dropdown:_setOpen(open: boolean)
	self._open = open
	self._list.Visible = open
	Tween.to(self._arrow, { Rotation = open and -90 or 90 }, 0.15)
end

function Dropdown:_updateLabel()
	self._valueLabel.Text = self._selected ~= nil and tostring(self._selected) or "Select..."
end

function Dropdown:_buildOptions()
	local theme = self._theme

	-- wipe the old buttons, but keep the layout / padding / corner objects
	for _, child in self._list:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for index, option in self._options do
		local isSelected = option == self._selected

		local item = Create("TextButton", {
			Name = tostring(option),
			LayoutOrder = index,
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundColor3 = theme.SurfaceHover,
			BackgroundTransparency = isSelected and 0 or 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = tostring(option),
			Font = theme.Font,
			TextSize = theme.TextSize,
			TextColor3 = isSelected and theme.Accent or theme.Text,
			Parent = self._list,
		}, {
			Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
		})

		item.MouseEnter:Connect(function()
			if option ~= self._selected then
				Tween.to(item, { BackgroundTransparency = 0.5 }, 0.1)
			end
		end)
		item.MouseLeave:Connect(function()
			if option ~= self._selected then
				Tween.to(item, { BackgroundTransparency = 1 }, 0.1)
			end
		end)
		item.Activated:Connect(function()
			self:Set(option)
			self:_setOpen(false)
		end)
	end
end

function Dropdown:Set(option, silent: boolean?)
	if option == self._selected then
		return
	end

	self._selected = option
	self:_updateLabel()
	self:_buildOptions()

	if not silent then
		self.Changed:Fire(option)
		if self._callback then
			task.spawn(self._callback, option)
		end
	end
end

function Dropdown:Get()
	return self._selected
end

-- swap out the whole list, e.g. when the player list changes
function Dropdown:Refresh(newOptions: { any })
	self._options = newOptions

	if not table.find(newOptions, self._selected) then
		self._selected = nil
		self:_updateLabel()
	end

	self:_buildOptions()
end

function Dropdown:Destroy()
	self.Changed:Destroy()
	self.Instance:Destroy()
end

return Dropdown
