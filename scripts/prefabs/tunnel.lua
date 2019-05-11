local assets =
{
	Asset("ANIM", "anim/tunnel.zip" ),
	Asset("ANIM", "anim/ui_board_5x1.zip"),
}

local important_prefabs = {
	"abigail_flower", "lighter", "lucy", "yukarihat", "yukariumbre", "scheme", "schemetool"
}

local function onsave(inst, data)
	data.index = inst.components.scheme.index
end

local function onload(inst, data)
	if data ~= nil then
		inst.components.scheme.index = data.index
		inst.components.scheme:InitGate()
	end
end

local function onremove(inst)
	local scheme = inst.components.scheme
	if scheme ~= nil then
		scheme:Disconnect(scheme.index)
	end
end

local function GetDesc(inst, viewer)
	local index = inst.components.scheme.index or -1
	local text = inst.components.taggable:GetText() or "#"..index

	if _G.NUMTUNNEL == 1 then
		return string.format(text).."\n"..GetDescription(viewer.prefab, inst)
	end

	return string.format(text)
end

local function IsImportantItem(item)
	if item:HasTag("irreplaceable") or item:HasTag("nonpotatable") then 
		return true 
	end

	for k, v in pairs(important_prefabs) do
		if item.prefab == v then
			return true
		end
	end

	for k, v in pairs(item.components) do
		if string.find(k, "specific") ~= nil then-- In case some mod item have thier own components 
			return true
		end
	end

	if item.prefab == _G.SCHEME_ALTERPREFAB then
		return true
	end

	return false
end

local function onaccept(inst, giver, item)
	if IsImportantItem(item) then
		inst.components.inventory:DropItem(item)
	else
		item:Remove()
		giver:PushEvent("makefriend")
	end
end

local function fn()
	local inst = CreateEntity()    
	
	inst.entity:AddTransform()    
	inst.entity:AddAnimState()    
	inst.entity:AddSoundEmitter()  
	inst.entity:AddMiniMapEntity()
    
    inst.MiniMapEntity:SetIcon("minimap_tunnel.tex")
   
    inst.AnimState:SetBank("tunnel")
    inst.AnimState:SetBuild("tunnel")
	inst.AnimState:SetLayer( LAYER_BACKGROUND )
	inst.AnimState:SetSortOrder( 3 )
	inst.AnimState:SetRayTestOnBB(true)

	inst:AddTag("tunnel") 
	inst:AddTag("teleporter")
	inst.islinked = false

	inst:SetStateGraph("SGtunnel")
    inst:AddComponent("inspectable")
	inst.components.inspectable.description = GetDesc

	inst:AddComponent("taggable")

	inst:AddComponent("scheme")

	inst:AddComponent("inventory")

	inst:AddComponent("trader")
    inst.components.trader.AcceptGift = onaccept

	inst.OnSave = onsave
	inst.OnLoad = onload
	inst.Important = important_prefabs
	inst.OnRemoveEntity = onremove

    return inst
end

return Prefab( "common/objects/tunnel", fn, assets)