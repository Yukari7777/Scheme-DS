local STRINGS = GLOBAL.STRINGS
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS
local Action = GLOBAL.Action

local SPAWNG = Action({}, 7, nil, true, 2)
SPAWNG.id = "SPAWNG"
SPAWNG.str = STRINGS.ACTION_SPAWNG
SPAWNG.fn = function(act)
	if act.invobject and act.invobject.components.makegate then
        return act.invobject.components.makegate:Create(act.pos, act.doer)
    end
end
AddAction(SPAWNG)

local CONFIGG = Action({}, 8, nil, true, 2)
CONFIGG.id = "CONFIGG"
CONFIGG.str = STRINGS.ACTION_CONFIGG
CONFIGG.fn = function(act)
	local staff = act.invobject or act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	if staff and staff.components.makegate then
		return staff.components.makegate:Configurate(act.target, act.doer)
	end
end
AddAction(CONFIGG)

local SELECTG = Action({}, 8)
SELECTG.id = "SELECTG"
SELECTG.str = STRINGS.ACTION_SELECTG
SELECTG.fn = function(act)
	if act.target ~= nil and act.target.components.scheme ~= nil then
		return act.target.components.scheme:SelectDest(act.doer)
	end
end
AddAction(SELECTG)