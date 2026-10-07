local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Create = require(script.Parent.Parent.Util.Create)
local Tween = require(script.Parent.Parent.Util.Tween)
local Signal = require(script.Parent.Parent.Util.Signal)
local Drag = require(script.Parent.Parent.Util.Drag)
local Device = require(script.Parent.Parent.Util.Device)
local Interact = require(script.Parent.Parent.Util.Interact)
local Theme = require(script.Parent.Parent.Theme)
local Tab = require(script.Parent.Tab)
local Notification = require(script.Parent.Notification)

local Window = {}
Window.__index = Window

local WHITE = Color3.new(1, 1, 1)

local SIDEBAR_WIDTH = 150
local TAB_STRIP_HEIGHT = 44 -- the horizontal tab bar used on narrow screens
local COMPACT_WIDTH = 520 -- windows narrower than this switch to the tab strip
local SCREEN_MARGIN = 10 -- minimum gap between the window and the screen edge
local HIDDEN_SCALE = 0.94 -- the window grows from / shrinks to this size when toggled

-- In Studio / normal games this is just PlayerGui. If the environment offers gethui()
-- (most executors do) we use that instead, since PlayerGui can get wiped on respawn
-- or inspected by the game.
local function getDefaultParent()
	local ok, hidden = pcall(function()
		return gethui and gethui()
	end)
	if ok and hidden then
		return hidden
	end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- Running a script twice would otherwise leave two windows stacked on top of each other.
local function removeExisting(parent: Instance, key: string)
	for _, child in parent:GetChildren() do
		if child:IsA("ScreenGui") and child:GetAttribute("LumenKey") == key then
			child:Destroy()
		end
	end
end

-- Round-ish button for the title bar. `bars` are the rotations of the line(s) that draw the
-- icon: { 0 } is a dash (minimise), { 45, -45 } is a cross (close).
local function makeIconButton(parent: Instance, theme, name: string, rightOffset: number, hoverColor: Color3, bars: { number })
	local size = Device.isTouch() and 36 or 28

	local button = Create("TextButton", {
		Name = name,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, rightOffset, 0.5, 0),
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = hoverColor,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Parent = parent,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
	})

	local lines = {}
	for _, rotation in bars do
		table.insert(lines, Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(12, 2),
			Rotation = rotation,
			BackgroundColor3 = theme.TextDim,
			BorderSizePixel = 0,
			Parent = button,
		}, {
			Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		}))
	end

	Interact.bind(button, function(state)
		local transparency = if state == "Press" then 0.6 elseif state == "Hover" then 0.8 else 1
		local color = state == "Idle" and theme.TextDim or hoverColor

		Tween.to(button, { BackgroundTransparency = transparency }, 0.12)
		for _, line in lines do
			Tween.to(line, { BackgroundColor3 = color }, 0.12)
		end
	end)

	return button
end

-- options:
--   Title, Subtitle        text in the title bar
--   Size                   UDim2 (offset = wanted size). Shrinks automatically to fit small screens.
--   ToggleKey              Enum.KeyCode that shows/hides the window (false = no key)
--   Launcher               true/false: draggable round button that shows/hides the window.
--                          Default: on for phones and tablets, off elsewhere.
--   Preset                 "Dark" (default) | "Light"
--   Theme                  table of colour overrides, see Theme.luau
--   Id                     windows with the same Id (default: the Title) replace each other
--   Parent                 where the ScreenGui goes
function Window.new(options)
	options = options or {}

	local self = setmetatable({}, Window)
	self.Theme = Theme.extend(Theme.Presets[options.Preset] or Theme.Dark, options.Theme)
	self.Tabs = {}
	self.Destroyed = Signal.new()

	self._connections = {}
	self._activeTab = nil
	self._visible = true
	self._compact = false
	self._destroyed = false
	self._size = Vector2.new(580, 400)
	self._sizeOption = options.Size or UDim2.fromOffset(580, 400)
	self._topbarHeight = Device.isTouch() and 48 or 44

	self._toggleKey = options.ToggleKey
	if self._toggleKey == nil then
		self._toggleKey = Enum.KeyCode.RightShift
	end

	local theme = self.Theme
	local parent = options.Parent or getDefaultParent()
	local key = options.Id or options.Title or "LumenUI"

	removeExisting(parent, key)

	self.Gui = Create("ScreenGui", {
		Name = "LumenUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 100,
		Parent = parent,
	})
	self.Gui:SetAttribute("LumenKey", key)

	Interact.retain()

	-- If something else destroys the ScreenGui (the next run of the script, say), still clean up
	-- the connections we made on UserInputService.
	self.Gui.Destroying:Connect(function()
		self:Destroy(true)
	end)

	---- window frame --------------------------------------------------------------------

	-- Main is the thing that moves and scales. The shadows and the body are children of it.
	self._scale = Create("UIScale", { Scale = HIDDEN_SCALE })

	self.Main = Create("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(580, 400),
		BackgroundTransparency = 1,
		Parent = self.Gui,
	}, {
		self._scale,
		-- two translucent layers fake a soft drop shadow without any image assets
		Create("Frame", {
			Name = "ShadowFar",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 10),
			Size = UDim2.new(1, 44, 1, 44),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.94,
			BorderSizePixel = 0,
			ZIndex = 0,
		}, { Create("UICorner", { CornerRadius = UDim.new(0, 32) }) }),
		Create("Frame", {
			Name = "ShadowNear",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 5),
			Size = UDim2.new(1, 20, 1, 20),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.86,
			BorderSizePixel = 0,
			ZIndex = 0,
		}, { Create("UICorner", { CornerRadius = UDim.new(0, 24) }) }),
	})

	self.Body = Create("Frame", {
		Name = "Body",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 1,
		Parent = self.Main,
	}, {
		Create("UICorner", { CornerRadius = theme.WindowCorner }),
		Create("UIStroke", { Color = theme.Stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		-- very light top-to-bottom shade
		Create("UIGradient", { Color = ColorSequence.new(WHITE, Color3.fromRGB(230, 230, 238)), Rotation = 90 }),
	})

	---- title bar (also the drag handle) -----------------------------------------------

	local topHeight = self._topbarHeight
	local hasSubtitle = options.Subtitle ~= nil

	local topBar = Create("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, topHeight),
		BackgroundTransparency = 1,
		Parent = self.Body,
	}, {
		-- logo: gradient tile with a white diamond
		Create("Frame", {
			Name = "Logo",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 14, 0.5, 0),
			Size = UDim2.fromOffset(24, 24),
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
		}, {
			Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
			Create("UIGradient", { Color = ColorSequence.new(theme.Accent, theme.Accent2), Rotation = 45 }),
			Create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(9, 9),
				Rotation = 45,
				BackgroundColor3 = WHITE,
				BorderSizePixel = 0,
			}, { Create("UICorner", { CornerRadius = UDim.new(0, 2) }) }),
		}),
	})

	-- room the title must leave free on the right for the two buttons
	local buttonSize = Device.isTouch() and 36 or 28
	local titleReserve = 48 + 22 + buttonSize * 2

	self._titleLabel = Create("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(48, hasSubtitle and 6 or 0),
		Size = UDim2.new(1, -titleReserve, hasSubtitle and 0 or 1, hasSubtitle and 18 or 0),
		BackgroundTransparency = 1,
		Text = options.Title or "Lumen UI",
		Font = theme.FontBold,
		TextSize = theme.TextSize + 2,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = topBar,
	})

	if hasSubtitle then
		Create("TextLabel", {
			Name = "Subtitle",
			Position = UDim2.fromOffset(48, 25),
			Size = UDim2.new(1, -titleReserve, 0, 14),
			BackgroundTransparency = 1,
			Text = options.Subtitle,
			Font = theme.Font,
			TextSize = theme.TextSize - 2,
			TextColor3 = theme.TextDim,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = topBar,
		})
	end

	local closeButton = makeIconButton(topBar, theme, "Close", -10, theme.Error, { 45, -45 })
	local minimizeButton = makeIconButton(topBar, theme, "Minimize", -(10 + buttonSize + 4), theme.Accent, { 0 })

	closeButton.Activated:Connect(function()
		self:Destroy()
	end)

	minimizeButton.Activated:Connect(function()
		self:SetVisible(false)

		-- without a launcher button there would be no obvious way back
		if not self._launcher and self._toggleKey then
			self:Notify({
				Title = "Window hidden",
				Content = "Press " .. self._toggleKey.Name .. " to show it again.",
				Duration = 3,
			})
		end
	end)

	---- navigation (sidebar or tab strip) and pages -------------------------------------

	self._topDivider = Create("Frame", {
		Name = "TopDivider",
		Position = UDim2.fromOffset(0, topHeight),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = theme.Stroke,
		BorderSizePixel = 0,
		Parent = self.Body,
	})

	self._navDivider = Create("Frame", {
		Name = "NavDivider",
		BackgroundColor3 = theme.Stroke,
		BorderSizePixel = 0,
		Parent = self.Body,
	})

	self._tabPadding = Create("UIPadding", {})
	self._tabLayout = Create("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	-- a ScrollingFrame, so any number of tabs still fits
	self.TabList = Create("ScrollingFrame", {
		Name = "TabList",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		Parent = self.Body,
	}, {
		self._tabPadding,
		self._tabLayout,
	})

	self.Pages = Create("Frame", {
		Name = "Pages",
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = self.Body,
	})

	self._notifications = Notification.new(self.Gui, theme)

	---- behaviour ----------------------------------------------------------------------

	table.insert(self._connections, Drag.attach(topBar, self.Main, {
		Clamp = function(position: UDim2)
			return self:_clampPosition(position)
		end,
	}))

	table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return -- they're typing in chat or a textbox
		end
		if self._toggleKey and input.KeyCode == self._toggleKey then
			self:Toggle()
		end
	end))

	-- phone rotated, window resized, device emulator changed, ...
	table.insert(self._connections, self.Gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:_layout()
	end))

	local wantLauncher = options.Launcher
	if wantLauncher == nil then
		wantLauncher = Device.isMobile()
	end
	if wantLauncher then
		self:_buildLauncher()
	end

	self:_layout()

	-- pop-in
	Tween.to(self._scale, { Scale = 1 }, 0.3, Enum.EasingStyle.Quint)

	return self
end

---- layout -------------------------------------------------------------------------------

-- Works out how big the window may be on this screen and switches between the sidebar layout
-- (wide) and the tab strip layout (narrow). Runs on creation and whenever the screen size changes.
function Window:_layout()
	local viewport = self.Gui.AbsoluteSize
	if viewport.X <= 0 or viewport.Y <= 0 then
		return
	end

	local wanted = self._sizeOption
	local width = wanted.X.Scale * viewport.X + wanted.X.Offset
	local height = wanted.Y.Scale * viewport.Y + wanted.Y.Offset

	width = math.max(math.min(width, viewport.X - SCREEN_MARGIN * 2), 240)
	local compact = width < COMPACT_WIDTH

	if compact then
		-- a phone in portrait is much taller than wide, so use that room
		height = math.max(height, 460)
	end
	height = math.max(math.min(height, viewport.Y - SCREEN_MARGIN * 2), 200)

	self._size = Vector2.new(width, height)
	self._compact = compact
	self.Main.Size = UDim2.fromOffset(width, height)

	local top = self._topbarHeight + 1

	if compact then
		self.TabList.Position = UDim2.fromOffset(0, top)
		self.TabList.Size = UDim2.new(1, 0, 0, TAB_STRIP_HEIGHT)
		self.TabList.CanvasSize = UDim2.new()
		self.TabList.AutomaticCanvasSize = Enum.AutomaticSize.X
		self.TabList.ScrollingDirection = Enum.ScrollingDirection.X

		self._tabLayout.FillDirection = Enum.FillDirection.Horizontal
		self._tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		self._tabPadding.PaddingTop = UDim.new(0, 0)
		self._tabPadding.PaddingLeft = UDim.new(0, 8)
		self._tabPadding.PaddingRight = UDim.new(0, 8)

		self._navDivider.Position = UDim2.fromOffset(0, top + TAB_STRIP_HEIGHT)
		self._navDivider.Size = UDim2.new(1, 0, 0, 1)

		self.Pages.Position = UDim2.fromOffset(0, top + TAB_STRIP_HEIGHT + 1)
		self.Pages.Size = UDim2.new(1, 0, 1, -(top + TAB_STRIP_HEIGHT + 1))
	else
		self.TabList.Position = UDim2.fromOffset(0, top)
		self.TabList.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -top)
		self.TabList.CanvasSize = UDim2.new()
		self.TabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
		self.TabList.ScrollingDirection = Enum.ScrollingDirection.Y

		self._tabLayout.FillDirection = Enum.FillDirection.Vertical
		self._tabLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		self._tabPadding.PaddingTop = UDim.new(0, 10)
		self._tabPadding.PaddingLeft = UDim.new(0, 8)
		self._tabPadding.PaddingRight = UDim.new(0, 8)

		self._navDivider.Position = UDim2.fromOffset(SIDEBAR_WIDTH, top)
		self._navDivider.Size = UDim2.new(0, 1, 1, -top)

		self.Pages.Position = UDim2.fromOffset(SIDEBAR_WIDTH + 1, top)
		self.Pages.Size = UDim2.new(1, -(SIDEBAR_WIDTH + 1), 1, -top)
	end

	for _, tab in self.Tabs do
		tab:_setCompact(compact)
	end

	self._notifications:SetLayout(compact, viewport)
	self.Main.Position = self:_clampPosition(self.Main.Position)
end

-- Keeps the title bar on screen so the window can never be dragged somewhere it can't be
-- picked up again.
function Window:_clampPosition(position: UDim2): UDim2
	local viewport = self.Gui.AbsoluteSize
	local size = self._size
	local keep = 60 -- pixels of window that must stay visible horizontally

	local x = viewport.X * position.X.Scale + position.X.Offset
	local y = viewport.Y * position.Y.Scale + position.Y.Offset

	x = math.clamp(x, keep - size.X / 2, viewport.X - keep + size.X / 2)
	y = math.clamp(y, size.Y / 2, viewport.Y - 40 + size.Y / 2)

	return UDim2.new(
		position.X.Scale,
		x - viewport.X * position.X.Scale,
		position.Y.Scale,
		y - viewport.Y * position.Y.Scale
	)
end

-- The round button that shows/hides the window on devices without a toggle key.
function Window:_buildLauncher()
	local theme = self.Theme
	local size = 50

	local scale = Create("UIScale", { Scale = 1 })

	self._launcher = Create("Frame", {
		Name = "Launcher",
		Position = UDim2.new(0, 14, 0.4, 0),
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 5,
		Parent = self.Gui,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Create("UIGradient", { Color = ColorSequence.new(theme.Accent, theme.Accent2), Rotation = 45 }),
		Create("UIStroke", { Color = WHITE, Transparency = 0.7, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		scale,
		Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(18, 18),
			Rotation = 45,
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			ZIndex = 6,
		}, { Create("UICorner", { CornerRadius = UDim.new(0, 5) }) }),
	})

	Interact.bind(self._launcher, function(state)
		Tween.to(scale, { Scale = state == "Press" and 0.9 or 1 }, 0.1)
	end)

	table.insert(self._connections, Drag.attach(self._launcher, self._launcher, {
		OnTap = function()
			self:Toggle()
		end,
		Clamp = function(position: UDim2)
			local viewport = self.Gui.AbsoluteSize
			local x = viewport.X * position.X.Scale + position.X.Offset
			local y = viewport.Y * position.Y.Scale + position.Y.Offset

			return UDim2.fromOffset(
				math.clamp(x, 0, math.max(0, viewport.X - size)),
				math.clamp(y, 0, math.max(0, viewport.Y - size))
			)
		end,
	}))
end

---- tabs ---------------------------------------------------------------------------------

function Window:_selectTab(tab)
	if self._activeTab == tab then
		return
	end
	if self._activeTab then
		self._activeTab:_setActive(false)
	end

	self._activeTab = tab
	tab:_setActive(true)
end

function Window:AddTab(name: string)
	local tab = Tab.new(self, name)
	table.insert(self.Tabs, tab)

	-- first tab opens automatically so the window isn't empty
	if #self.Tabs == 1 then
		tab:Select()
	end

	return tab
end

---- public API ---------------------------------------------------------------------------

-- options: Title, Content, Duration (seconds, 0 = until tapped), Type = "Info" | "Success" | "Warning" | "Error"
function Window:Notify(options)
	self._notifications:Push(options or {})
end

function Window:SetTitle(title: string)
	self._titleLabel.Text = title
end

function Window:IsVisible(): boolean
	return self._visible
end

function Window:SetVisible(visible: boolean)
	if self._destroyed or visible == self._visible then
		return
	end
	self._visible = visible

	if visible then
		self._scale.Scale = HIDDEN_SCALE
		self.Main.Visible = true
		Tween.to(self._scale, { Scale = 1 }, 0.25, Enum.EasingStyle.Quint)
	else
		Tween.to(self._scale, { Scale = HIDDEN_SCALE }, 0.15).Completed:Connect(function()
			if not self._visible and not self._destroyed then
				self.Main.Visible = false
			end
		end)
	end
end

function Window:Toggle()
	self:SetVisible(not self._visible)
end

function Window:Destroy(fromGui: boolean?)
	if self._destroyed then
		return
	end
	self._destroyed = true

	self.Destroyed:Fire()
	self.Destroyed:Destroy()

	for _, connection in self._connections do
		connection:Disconnect()
	end
	table.clear(self._connections)

	Interact.release()

	-- when the ScreenGui is what started this, it is already on its way out
	if not fromGui then
		self.Gui:Destroy()
	end
end

return Window
