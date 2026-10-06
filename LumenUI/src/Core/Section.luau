local Create = require(script.Parent.Parent.Util.Create)
local Container = require(script.Parent.Container)

local Section = {}
Section.__index = Section

function Section.new(parent, theme, title: string)
	local self = setmetatable({}, Section)
	self._theme = theme

	self.Instance = Create("Frame", {
		Name = "Section",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = parent,
	}, {
		Create("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Create("TextLabel", {
			Name = "Title",
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			Text = string.upper(title or "Section"),
			Font = theme.FontBold,
			TextSize = theme.TextSize - 3,
			TextColor3 = theme.TextDim,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})

	self._content = Create("Frame", {
		Name = "Content",
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Section,
		BorderSizePixel = 0,
		Parent = self.Instance,
	}, {
		Create("UICorner", { CornerRadius = theme.Corner }),
		Create("UIStroke", { Color = theme.Stroke, Thickness = 1 }),
		Create("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),
		Create("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	return self
end

function Section:Destroy()
	self.Instance:Destroy()
end

Container.mixin(Section)

return Section
