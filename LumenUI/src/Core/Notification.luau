local Create = require(script.Parent.Parent.Util.Create)
local Tween = require(script.Parent.Parent.Util.Tween)

local Notification = {}
Notification.__index = Notification

-- which theme colour each notification type uses
local TYPE_COLORS = {
	Info = "Accent",
	Success = "Success",
	Warning = "Warning",
	Error = "Error",
}

function Notification.new(gui: ScreenGui, theme)
	local self = setmetatable({}, Notification)
	self._theme = theme
	self._compact = false

	self._holder = Create("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		ZIndex = 50,
		Parent = gui,
	})

	self._list = Create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self._holder,
	})

	self:SetLayout(false, gui.AbsoluteSize)
	return self
end

-- Desktop: stacked in the bottom-right corner.
-- Phones / narrow windows: full-width cards dropping in from the top, away from the thumbs.
function Notification:SetLayout(compact: boolean, viewport: Vector2)
	self._compact = compact

	local width = math.clamp(viewport.X - 24, 200, 330)
	local holder = self._holder
	local list = self._list

	if compact then
		holder.AnchorPoint = Vector2.new(0.5, 0)
		holder.Position = UDim2.new(0.5, 0, 0, 12)
		holder.Size = UDim2.new(0, width, 1, -24)
		list.VerticalAlignment = Enum.VerticalAlignment.Top
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	else
		holder.AnchorPoint = Vector2.new(1, 1)
		holder.Position = UDim2.new(1, -16, 1, -16)
		holder.Size = UDim2.new(0, width, 1, -32)
		list.VerticalAlignment = Enum.VerticalAlignment.Bottom
		list.HorizontalAlignment = Enum.HorizontalAlignment.Right
	end
end

-- options: Title, Content, Duration (seconds, 0 = stays until tapped), Type = "Info" | "Success" | "Warning" | "Error"
function Notification:Push(options)
	local theme = self._theme
	local duration = options.Duration or 4
	local timed = duration > 0 and duration < math.huge
	local accent = theme[TYPE_COLORS[options.Type or "Info"] or "Accent"] or theme.Accent

	local slideOffset = self._compact and UDim2.fromOffset(0, -24) or UDim2.fromOffset(32, 0)

	-- The list layout owns the slot's position, so the card slides around inside the slot.
	local slot = Create("Frame", {
		Name = "NotificationSlot",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = self._holder,
	})

	-- CanvasGroup lets us fade the whole card (text, stroke and all) with one property
	local card = Create("CanvasGroup", {
		Name = "Notification",
		Position = slideOffset,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Active = true, -- so a tap on the card doesn't also hit the game behind it
		Parent = slot,
	}, {
		Create("UICorner", { CornerRadius = theme.Corner }),
		Create("UIStroke", { Color = theme.Stroke, Thickness = 1 }),
		Create("Frame", {
			Name = "Bar",
			Size = UDim2.new(0, 3, 1, 0),
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
		}),
		Create("Frame", {
			Name = "Content",
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
		}, {
			Create("UIPadding", {
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 12),
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 12),
			}),
			Create("UIListLayout", {
				Padding = UDim.new(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Create("TextLabel", {
				Name = "Title",
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				Text = options.Title or "Notice",
				Font = theme.FontBold,
				TextSize = theme.TextSize,
				TextColor3 = theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
			Create("TextLabel", {
				Name = "Body",
				LayoutOrder = 2,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Text = options.Content or "",
				Font = theme.Font,
				TextSize = theme.TextSize - 1,
				TextColor3 = theme.TextDim,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			}),
		}),
	})

	local progress
	if timed then
		-- thin bar along the bottom edge that runs out when the card is about to leave
		progress = Create("Frame", {
			Name = "Progress",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 2),
			BackgroundColor3 = accent,
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
			Parent = card,
		})
	end

	Tween.to(card, { GroupTransparency = 0, Position = UDim2.new() }, 0.3, Enum.EasingStyle.Quint)
	if progress then
		Tween.to(progress, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)
	end

	local closing = false
	local function dismiss()
		if closing or not card.Parent then
			return -- already leaving, or the window was destroyed in the meantime
		end
		closing = true

		local tween = Tween.to(card, { GroupTransparency = 1, Position = slideOffset }, 0.25)
		tween.Completed:Connect(function()
			slot:Destroy()
		end)
	end

	-- tap / click a card to get rid of it early
	card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dismiss()
		end
	end)

	if timed then
		task.delay(duration, dismiss)
	end
end

return Notification
