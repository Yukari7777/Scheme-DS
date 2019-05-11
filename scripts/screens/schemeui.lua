local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local TEMPLATES = require "widgets/schemetemplates"
local ScrollableList = require "widgets/scrolllablelist"

local SchemeUI = Class(Screen, function(self, attach)
    Screen._ctor(self, "SchemeUI")

    self.owner = GetPlayer()
    self.attach = attach

	self.destdata = {}
	self.destitems = {}

	self.numalter = 0
	self.numstat = 0

    self.root = self:AddChild(Widget("ROOT"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetPosition(0, 0, 0)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.black = self.root:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black:SetTint(0, 0, 0, 0.5)
    self.black.OnMouseButton = function() self:OnCancel() end

    self.destspanel = self.root:AddChild(TEMPLATES.RectangleWindow(240, 360))
    self.destspanel:SetPosition(0, 25)
	
	self.title = self.destspanel:AddChild(Text(BODYTEXTFONT, 32))
	self.title:SetString(STRINGS.TAGGABLE_SELECT_DESTINATION)
	self.title:SetPosition(0, 155)
	
	self.cancelbutton = self.root:AddChild(ImageButton())
    self.cancelbutton.image:SetScale(0.7)
    self.cancelbutton:SetText(STRINGS.SIGNS.MENU.CANCEL)
    self.cancelbutton:SetFont(BUTTONFONT)
    self.cancelbutton:SetPosition(0, -160, 0)
    self.cancelbutton:SetOnClick(function() self:OnCancel() end)
	
	local alter = _G.SCHEME_ALTERPREFAB
	if alter ~= "noalter" then
		self.altericon = self.destspanel:AddChild(Image("images/inventoryimages.xml", alter..".tex"))
		self.altericon:SetPosition(-110, -142)
		self.altericon:SetSize(40, 40)
		self.altericon:Hide()

		self.alternum = self.destspanel:AddChild(Text(BODYTEXTFONT, 20))
		self.alternum:SetPosition(-75, -145)
		self.alternum:Hide()
	end

	self.staticon = self.destspanel:AddChild(Image("images/inventoryimages/sanitypanel.xml", "sanitypanel.tex"))
	self.staticon:SetPosition(-40, -145)
	self.staticon:SetSize(35, 35)
	self.staticon:Hide()

	self.sanitynum = self.destspanel:AddChild(Text(BODYTEXTFONT, 20))
	self.sanitynum:SetPosition(-3, -145)
	self.sanitynum:Hide()
	
	self:Initialize()
    self:Show()
end)

function SchemeUI:OnBecomeActive()
    SchemeUI._base.OnBecomeActive(self)
	SetPause(true, "SchemeUI")
end

function SchemeUI:Initialize()
	local destdata = deepcopy(_G.TUNNELNETWORK)
	local taggable = self.attach and self.attach.components.taggable

	if taggable ~= nil then
		for k, v in ipairs(destdata) do
			if tonumber(destdata[k].index) == taggable.index then	
				table.remove(destdata, k) -- delete destination towards itself.	
			end
		end

		if GetPlayer():HasTag("yakumoyukari") then
			self.staticon:SetTexture("images/inventoryimages/powerpanel.xml", "powerpanel.tex")
			self.staticon:SetSize(35, 35)
		end
	end
	
	for i = 1, #destdata do 
		local item = Widget("item"..i)

		item.button = item:AddChild(TEMPLATES.ListItemBackground(280, 30, function() end))
		item.button.move_on_click = true
		item.button:SetOnClick(function() self:OnSelected(destdata[i].index) end)

		item.text = item:AddChild(Text(BODYTEXTFONT, 20))
		item.text:SetVAlign(ANCHOR_MIDDLE)
		item.text:SetHAlign(ANCHOR_LEFT)
		item.text:SetPosition(0, 0, 5)
		item.text:SetRegionSize(220, 30)
		item.text:SetString(destdata[i].inst.components.taggable.text or "#"..destdata[i].index)
		item.text:SetColour(1, 1, 1, 1)

		item.focus_forward = item.button

		table.insert(self.destitems, item)
	end
	
	self.scroll_list = self.destspanel:AddChild(ScrollableList(self.destitems, 200, 240, 25, nil, nil, nil))
	self.scroll_list:SetPosition(95, 13)
    self.scroll_list:SetFocusChangeDir(MOVE_DOWN, self.cancelbutton)
	self.scroll_list.scroll_bar_container:SetPosition(-50, 0)
	
	self.numalter, self.numstat = _G.GetGCost(self.owner)
	if self.numalter ~= 0 then
		self.alternum:SetString(": "..self.numalter)
		self.alternum:Show()
		self.altericon:Show()
	else
		self.staticon:SetPosition(-110, -142)
		self.sanitynum:SetPosition(-73, -142)
	end
	self.sanitynum:SetString(": "..self.numstat)
	self.sanitynum:Show()
	self.staticon:Show()

	self.default_focus = self.scroll_list
end

function SchemeUI:OnSelected(index)
	local taggable = self.attach.components.taggable
    if taggable ~= nil then
        taggable:Teleport(self.owner, index)
    end

    self:Close()
end

function SchemeUI:OnCancel()
	local taggable = self.attach.components.taggable
    if taggable ~= nil then
        taggable:OnCloseWidget()
    end

    self:Close()
end

function SchemeUI:OnControl(control, down)
    if SchemeUI._base.OnControl(self, control, down) then
        return true
    end

    if not down then
        if control == CONTROL_OPEN_DEBUG_CONSOLE then
            return true
        elseif control == CONTROL_CANCEL then
            self:OnCancel()
        end
    end
end

function SchemeUI:Close()
    SetPause(false)
    TheFrontEnd:PopScreen(self)
end

return SchemeUI