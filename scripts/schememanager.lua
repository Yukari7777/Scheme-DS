GLOBAL.TUNNELNETWORK = {}
GLOBAL.NUMTUNNEL = 0
local alterprefab = GetModConfigData("alter")
local altervalue = GetModConfigData("alterval")
local usecost = GetModConfigData("usecost")

local function FindItemInSlots(TheSlot, num)
	for k, v in pairs(TheSlot) do
		if v.prefab == alterprefab then
			num = num + (v.components.stackable ~= nil and v.components.stackable:StackSize() or 1)
		end
	end
	return num
end

local function ConsumeItemInSlots(TheSlot, num)
	for k, v in pairs(TheSlot) do
		if v.prefab == alterprefab then
			local stacksize = v.components.stackable ~= nil and v.components.stackable:StackSize() or 1
			local numtoremove = math.min(stacksize, num)
			if numtoremove > 0 then
				v.components.stackable:Get(numtoremove):Remove()
			end
			num = num - numtoremove
		end
	end
	return num
end

GLOBAL.GetGCost = function(player, isspawn)
	local _COST = isspawn and GetModConfigData("spawncost") or usecost
	local maxuse = math.floor(_COST / altervalue)
	local numalter = 0
	local numtouse = 0
	local leftover = _COST
	local isyukari = false

	if player:HasTag("yakumoyukari") then
		numalter = 0
		leftover = isspawn and TUNING.YUKARI.SPAWNG_POWER_COST or player.components.upgrader.schemecost or 75
		isyukari = true
	elseif alterprefab ~= "noalter" then
		numalter = FindItemInSlots(player.components.inventory:GetItems(), numalter)
		for k, v in pairs(player.components.inventory.itemslots) do
			if type(v) == "table" and v.components.container ~= nil then
				numalter = FindItemInSlots(player.components.inventory:GetEquippedItem(k).components.container.slots, numalter)
			end
		end
		numtouse = math.min(maxuse, numalter)
		leftover = leftover - numtouse * altervalue
	end

	return numtouse, leftover
end

GLOBAL.ConsumeGateCost = function(player, numitem, numstat, isspawn)
	local leftoveritem = numitem
	if leftoveritem ~= 0 then
		leftoveritem = ConsumeItemInSlots(player.components.inventory:GetItems(), leftoveritem)
		for k, v in pairs(player.components.inventory.itemslots) do
			if type(v) == "table" and v.components.container ~= nil then
				leftoveritem = ConsumeItemInSlots(player.components.inventory:GetEquippedItem(k).components.container.slots, leftoveritem)
			end
		end
	end

	if player.components.power ~= nil then
		player.components.power:DoDelta(-numstat)
	elseif player.components.sanity ~= nil then
		if alterprefab ~= "noalter" and not isspawn then
			for k, v in pairs(player.components.inventory.equipslots) do
				if v:HasTag("shadowdominance") or v:HasTag("schemetool") then
					if numstat == 0 then break end
					if v.components.finiteuses ~= nil then
						v.components.finiteuses:Use(math.ceil(numstat / usecost * 3))
						numstat = 0
					elseif v.components.armor ~= nil then
						v.components.armor:TakeDamage(numstat)
						numstat = 0
					end
				end
			end
		end
		if numstat ~= 0 then
			player.components.sanity:DoDelta(-numstat)
		end
	end
end

local function SetTaggableText(player, target, text)
    local taggable = target.components.taggable
	local scheme = target.components.scheme
    if taggable ~= nil then
		if target.classified.shouldUI:value() then
			taggable:OnCloseWidget()
		else
			taggable:Write(player, text)
		end
    end

	if scheme ~= nil then
		scheme:SetOwner(player)
	end
end

local function DoTeleportWithIndex(player, index, inst)
	local taggable = inst.components.taggable
	if taggable ~= nil then
		taggable:Write(player, index)
	end
end