local Scheme = Class(function(self, inst)
    self.inst = inst
	
	self.index = nil
	self.pointer = nil
end)

function Scheme:OnActivate(other, doer) 
	other.sg:GoToState("open")
	other:DoTaskInTime(1.5, function()
		other.sg:GoToState("closing")
		self.inst.sg:GoToState("closing")
	end)
end

function Scheme:CheckConditionAndCost(doer, index)
	if not self:IsConnected(index) then return end
	local numalter, numstat = _G.GetGCost(doer, false)
	if doer:HasTag("yakumoyukari") and doer.components.power ~= nil and doer.components.talker ~= nil and doer.components.power.current < doer.components.upgrader.schemecost then 
		doer.components.talker:Say(GetString(doer.prefab, "DESCRIBE_LOWPOWER"))
		return
	elseif not doer:HasTag("yakumoyukari") and not doer.components.inventory:EquipHasTag("shadowdominance") and (doer.components.sanity ~= nil and doer.components.sanity.current < numstat) then
		doer.components.talker:Say(GetString(doer.prefab, "LOWUSEGSANITY")) 
		return 
	end

	if doer:HasTag("doer") then
		doer.SoundEmitter:KillSound("wormhole_travel")
		_G.ConsumeGateCost(doer, numalter, numstat, false)
	end
	return true
end

function Scheme:Activate(doer, index)
	local index = tonumber(index)
	if not self:CheckConditionAndCost(doer, index) then return end

	self:OnActivate(self:GetTarget(index), doer)
	self:Teleport(doer, index)

	if doer.components.leader ~= nil then
		for follower,v in pairs(doer.components.leader.followers) do
			self:Teleport(follower, index)
		end
	end

	local eyebone = nil

	--special case for the chester_eyebone: look for inventory items with followers
	if doer.components.inventory ~= nil then
		for k,item in pairs(doer.components.inventory.itemslots) do
			if item.components.leader then
				if item:HasTag("chester_eyebone") then
					eyebone = item
				end
				for follower,v in pairs(item.components.leader.followers) do
					self:Teleport(follower, index)
				end
			end
		end
		-- special special case, look inside equipped containers
		for k,equipped in pairs(doer.components.inventory.equipslots) do
			if equipped and equipped.components.container ~= nil then
				local container = equipped.components.container
				for j,item in pairs(container.slots) do
					if item.components.leader then
						if item:HasTag("chester_eyebone") then
							eyebone = item
						end
						for follower,v in pairs(item.components.leader.followers) do
							self:Teleport(follower, index)
						end
					end
				end
			end
		end
		-- special special special case: if we have an eyebone, then we have a container follower not actually in the inventory. Look for inventory items with followers there.
		if eyebone and eyebone.components.leader ~= nil then
			for follower,v in pairs(eyebone.components.leader.followers) do
				if follower and (not follower.components.health or (follower.components.health and not follower.components.health:IsDead())) and follower.components.container then
					for j,item in pairs(follower.components.container.slots) do
						if item.components.leader then
							for follower,v in pairs(item.components.leader.followers) do
								if follower and (not follower.components.health or (follower.components.health and not follower.components.health:IsDead())) then
									self:Teleport(follower, index)
								end
							end
						end
					end
				end
			end
		end
	end
end

function Scheme:Teleport(obj, index)
	local target = self:GetTarget(index)
	local offset = 2.0
	local angle = math.random() * 360
	local target_x, target_y, target_z = target.Transform:GetWorldPosition()
	
	target_x = target_x + math.sin(angle)*offset
	target_z = target_z + math.cos(angle)*offset
	if obj.Physics then
		obj.Physics:Teleport( target_x, target_y, target_z )
	elseif obj.Transform then
		obj.Transform:SetPosition( target_x, target_y, target_z )
	end
	if obj.components.talker ~= nil then
        obj.components.talker:ShutUp()
    end
end

function Scheme:GetTarget(index)
	return _G.TUNNELNETWORK[index] and _G.TUNNELNETWORK[index].inst
end

function Scheme:IsConnected(index)
	return self:GetTarget(index) ~= nil
end

function Scheme:FindIndex()
	local index = 1
	while _G.TUNNELNETWORK[index] ~= nil do
		index = index + 1
	end
	return index
end

function Scheme:AddToNetwork()
	local index = self.index ~= nil and self.index or self:FindIndex()

	_G.TUNNELNETWORK[index] = {
		inst = self.inst,
		index = index
	}
	_G.NUMTUNNEL = _G.NUMTUNNEL + 1
	self.index = index
	self.inst.components.taggable.index = index
end

function Scheme:Disconnect(index)
	if _G.TUNNELNETWORK[index] ~= nil then
		_G.TUNNELNETWORK[index] = nil
		_G.NUMTUNNEL = _G.NUMTUNNEL - 1
	end
end

function Scheme:SelectDest(doer)
	self.inst:PushEvent("select", {doer = doer})

	return true
end

function Scheme:InitGate()
	self:AddToNetwork()
end

function Scheme:CollectSceneActions(doer, actions, right)
	if self.inst:HasTag("teleporter") and _G.NUMTUNNEL > 1 then
		table.insert(actions, ACTIONS.SELECTG)
    end
end

return Scheme