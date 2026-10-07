-- Tiny helpers for "am I on a phone?" decisions, so components can size themselves
-- for fingers instead of mouse cursors.

local UserInputService = game:GetService("UserInputService")

local Device = {}

-- Any touch screen (phones, tablets, touch laptops).
function Device.isTouch(): boolean
	return UserInputService.TouchEnabled
end

-- Touch screen and no physical keyboard: that's a phone or a tablet.
function Device.isMobile(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- Height of a normal row (button, toggle, ...). Fingers need about 44px, a mouse is fine with 36.
function Device.rowHeight(): number
	return UserInputService.TouchEnabled and 44 or 36
end

return Device
