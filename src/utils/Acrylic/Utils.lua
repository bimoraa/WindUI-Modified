-- Credits: Fluent - Dawid


local cloneref = (cloneref or clonereference or function(instance) return instance end)

-- Workspace is a singleton; cache it once instead of re-resolving the service on every
-- call (these run on the per-frame acrylic render path). .CurrentCamera is still read
-- fresh each call so a camera swap is picked up.
local Workspace = cloneref(game:GetService("Workspace"))


local function map(value, inMin, inMax, outMin, outMax)
	return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
end

local function viewportPointToWorld(location, distance)
	local unitRay = Workspace.CurrentCamera:ScreenPointToRay(location.X, location.Y)
	return unitRay.Origin + unitRay.Direction * distance
end

local function getOffset()
	local viewportSizeY = Workspace.CurrentCamera.ViewportSize.Y
	return map(viewportSizeY, 0, 2560, 8, 56)
end

return { viewportPointToWorld, getOffset }
