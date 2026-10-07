local Create = require(script.Parent.Parent.Util.Create)

local Label = {}
Label.__index = Label

function Label.new(parent, theme, options)
	local self = setmetatable({}, Label)

	self.Instance = Create("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, 0, 0, 20),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = options.Text or options.Name or "Label",
		Font = theme.Font,
		TextSize = theme.TextSize - 1,
		TextColor3 = theme.TextDim,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = parent,
	}, {
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 2),
			PaddingRight = UDim.new(0, 2),
			PaddingTop = UDim.new(0, 2),
			PaddingBottom = UDim.new(0, 2),
		}),
	})

	return self
end

function Label:SetText(text: string)
	self.Instance.Text = text
end

function Label:Destroy()
	self.Instance:Destroy()
end

return Label
