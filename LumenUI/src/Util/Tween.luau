local TweenService = game:GetService("TweenService")

local Tween = {}

-- Fire and forget tween. Returns the tween in case you want to wait on it.
function Tween.to(instance: Instance, goal: { [string]: any }, duration: number?, style: Enum.EasingStyle?, direction: Enum.EasingDirection?)
	local info = TweenInfo.new(
		duration or 0.15,
		style or Enum.EasingStyle.Quad,
		direction or Enum.EasingDirection.Out
	)

	local tween = TweenService:Create(instance, info, goal)
	tween:Play()
	return tween
end

return Tween
