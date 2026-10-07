local Create = require(script.Parent.Parent.Util.Create)
local Signal = require(script.Parent.Parent.Util.Signal)
local Tween = require(script.Parent.Parent.Util.Tween)
local Device = require(script.Parent.Parent.Util.Device)

local TextBox = {}
TextBox.__index = TextBox

-- options: Name, Default, Placeholder, ClearOnFocus, Callback(text, enterPressed)
function TextBox.new(parent, theme, options)
	local self = setmetatable({}, TextBox)
	self.Changed = Signal.new()
	self._callback = options.Callback

	local height = Device.rowHeight()

	local row = Create("Frame", {
		Name = "TextBox",
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		Parent = parent,
	}, {
		Create("UICorner", { CornerRadius = theme.Corner }),
		Create("UIStroke", {
			Color = theme.Stroke,
			Transparency = 0.5,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 6),
		}),
		Create("TextLabel", {
			Name = "Title",
			Size = UDim2.new(0.42, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = options.Name or "TextBox",
			Font = theme.Font,
			TextSize = theme.TextSize,
			TextColor3 = theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),
	})

	local stroke = Create("UIStroke", {
		Color = theme.Stroke,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})

	self._box = Create("TextBox", {
		Name = "Input",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.new(0.56, 0, 0, height - 12),
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		Text = options.Default or "",
		PlaceholderText = options.Placeholder or "Type here...",
		PlaceholderColor3 = theme.TextDim,
		ClearTextOnFocus = options.ClearOnFocus == true,
		Font = theme.Font,
		TextSize = theme.TextSize - 1,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		-- Not TextTruncate: while the text is being edited the box has to scroll with the cursor.
		ClipsDescendants = true,
		Parent = row,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),
		stroke,
	})

	self.Instance = row

	self._box.Focused:Connect(function()
		Tween.to(stroke, { Color = theme.Accent }, 0.12)
	end)

	self._box.FocusLost:Connect(function(enterPressed)
		Tween.to(stroke, { Color = theme.Stroke }, 0.12)

		local text = self._box.Text
		self.Changed:Fire(text, enterPressed)
		if self._callback then
			task.spawn(self._callback, text, enterPressed)
		end
	end)

	return self
end

function TextBox:Set(text: string)
	self._box.Text = text
end

function TextBox:Get(): string
	return self._box.Text
end

function TextBox:Destroy()
	self.Changed:Destroy()
	self.Instance:Destroy()
end

return TextBox
