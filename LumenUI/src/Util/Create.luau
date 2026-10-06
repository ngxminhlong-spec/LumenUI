-- Tiny helper so we don't have to write Instance.new + 8 property lines every time.
--
--   Create("Frame", { Size = UDim2.fromScale(1, 1) }, {
--       Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
--   })

local function Create(className: string, props: { [string]: any }?, children: { Instance }?): any
	local instance = Instance.new(className)
	local parent

	for key, value in props or {} do
		if key == "Parent" then
			-- set last, it's faster and avoids re-layout while we're still building
			parent = value
		else
			instance[key] = value
		end
	end

	for _, child in children or {} do
		child.Parent = instance
	end

	instance.Parent = parent
	return instance
end

return Create
