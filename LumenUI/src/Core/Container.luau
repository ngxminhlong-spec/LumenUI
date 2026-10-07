-- Both Tabs and Sections can hold components. Instead of copy/pasting the same
-- AddButton/AddToggle/... methods into each one, we bolt them on with this mixin.
--
-- The class needs to have two fields:
--   self._content  -> the Instance that components get parented to
--   self._theme    -> the theme table

local Components = require(script.Parent.Parent.Components)

local Container = {}

function Container.mixin(class)
	for name, constructor in Components do
		class["Add" .. name] = function(self, options)
			return constructor.new(self._content, self._theme, options or {})
		end
	end
end

return Container
