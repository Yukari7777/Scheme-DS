local taggables = require "taggables"
local TagScreen = require "screens/tagscreen"

local DANGER_RADIUS = 10
local function IsInDangerFromShadowCreatures(inst)
	-- Danger if:
	-- insane and near shadowcreature.
	-- ignore when shadowdominance
	-- being targetted but not ShouldSubmitToTarget.
	local ignoreshadowcreature = inst.components.inventory:EquipHasTag("shadowdominance") or inst.components.sanity:IsSane()

	local isdanger = false
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, DANGER_RADIUS * 2, { "shadowcreature" })
	for k, v in ipairs(ents) do
		if ((not ignoreshadowcreature) or (v.components.combat ~= nil and v.components.combat.target == inst)) and not v.components.shadowsubmissive:ShouldSubmitToTarget(inst) then
			isdanger = true
			break
		end
	end

	return isdanger
end

local function IsNearDanger(inst)
	local isnearbosses = _G.SCHEME_IGNOREBOSS or FindEntity(inst, DANGER_RADIUS * 2, nil, { "epic" }, { "spiderqueen", "leif" }) ~= nil or false

	local isdanger = false
	if not _G.SCHEME_IGNOREDANGER then
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, DANGER_RADIUS, nil, { "shadowcreature" })

		if ents ~= nil then
			if inst:HasTag("realyoukai") then
				-- Danger if:
				-- being targetted
				-- OR near monster that is not player, spider, bat, 
				for k, v in ipairs(ents) do
					if v:HasTag("monster") and not (v:HasTag("player") or v:HasTag("spider") or v:HasTag("bat")) or (v.components.combat ~= nil and v.components.combat.target == inst) then
						isdanger = true
						break
					end
				end
			elseif inst:HasTag("youkai") then
				-- Danger if:
				-- being targetted
				-- OR near monster or pig or spider that is not player
				-- note that "pig" tag includes somewhat things like bunnymans.
				for k, v in ipairs(ents) do
					if (v:HasTag("monster") or v:HasTag("pig") or v:HasTag("spider")) and not v:HasTag("player") or (v.components.combat ~= nil and v.components.combat.target == inst) then
						isdanger = true
						break
					end
				end
			elseif inst:HasTag("spiderwhisperer") then
				-- Danger if:
				-- being targetted
				-- OR near monster or pig that is neither player nor spider
				for k, v in ipairs(ents) do
					if (v:HasTag("monster") or v:HasTag("pig")) and not (v:HasTag("player") or v:HasTag("spider")) or (v.components.combat ~= nil and v.components.combat.target == inst) then
						isdanger = true
						break
					end
				end
			else
				--Danger if:
				-- being targetted
				-- OR near monster that is not player
				for k, v in ipairs(ents) do
					if v:HasTag("monster") and not v:HasTag("player") or (v.components.combat ~= nil and v.components.combat.target == inst) then
						isdanger = true
						break
					end
				end
			end
		end

		local hounded = GetWorld().components.hounded
		if hounded ~= nil then
			isdanger = hounded.warning
		end

		local burnable = inst.components.burnable
		if burnable ~= nil and (burnable:IsBurning() or (burnable.IsSmoldering ~= nil and burnable:IsSmoldering())) then
			isdanger = true
		end

		isdanger = isdanger or IsInDangerFromShadowCreatures(inst)
	end
	
	return isdanger or isnearbosses
end

local Taggable = Class(function(self, inst)
    self.inst = inst
    self.text = nil
	
    self.inst:ListenForEvent("tag", self.BeginWriting)
    self.inst:ListenForEvent("select", self.SelectPopup)
end)

function Taggable:OnSave()
    local data = {}

    data.text = self.text

    return data
end

function Taggable:OnLoad(data)
    self.text = data.text
	if IsXB1() then
		self.netid = data.netid
	end
end

function Taggable:OnCloseWidget()
	self.inst.sg:GoToState("closing")
end

function Taggable:GetText(viewer)
	if IsXB1() then
		if self.text and self.netid then
			return "\1"..self.text.."\1"..self.netid
		end
	end
    return self.text
end

function Taggable:SetText(text)
    self.text = text
	_G.TUNNELNETWORK[self.inst.components.scheme.index].text = text
end

function Taggable:IsWritten()
    return self.text ~= nil
end

function Taggable:BeginWriting(doer)
    TheFrontEnd:PushScreen(TagScreen(self))
end

function Taggable:SelectPopup(doer)
	if IsNearDanger(doer) then 
		doer.components.talker:Say(GetString(doer.prefab, "NODANGERSCHEME"))
		return 
	end
	self.inst.sg:GoToState("opening")

	doer:DoTaskInTime(14 * FRAMES, function()
		--TheFrontEnd:PushScreen(TaggableWidget(self))
	end)
end

function Taggable:Write(doer, text)
	local text = text or self.text
	if text == nil or text == "" then --set default text
		local index = self.inst.components.scheme.index
		if index ~= nil then
			text = "#"..index
		end
	end

	self:SetText(text)
end

function Taggable:Teleport(doer, index)
	if index ~= nil then
		doer.sg:GoToState("jumpin", { teleporter = doer })
		doer:DoTaskInTime(0.8, function()
			self.inst.components.scheme:Activate(doer, index)
			self.inst.sg:GoToState("closing")
		end)
		doer:DoTaskInTime(3, function() -- Move entities outside of map border inside
			if not doer:IsOnValidGround() then
				local dest = FindNearbyLand(doer:GetPosition(), 8)
				if dest ~= nil then
					if doer.Physics ~= nil then
						doer.Physics:Teleport(dest:Get())
					elseif act.doer.Transform ~= nil then
						doer.Transform:SetPosition(dest:Get())
					end
				end
			end
		end)
	end
end

function Taggable:Remove(doer)
	local scheme = self.inst.components.scheme

	if scheme ~= nil then
		if doer ~= nil then
			doer.SoundEmitter:PlaySound("dontstarve/common/staff_dissassemble")
		end

		self.inst:Remove()
	end
end

function Taggable:OnRemoveFromEntity()
    self.inst:RemoveTag("writeable")
    self.inst:RemoveEventCallback("tag", onspawned)
	self.inst:RemoveEventCallback("select", onselected)
end

Taggable.OnRemoveEntity = Taggable.OnCloseWidget

return Taggable