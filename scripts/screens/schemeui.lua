local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local TEMPLATES = require "widgets/schemetemplates"

local BODYTEXTFONT = "stint-ucr"

local SchemeUI = Class(Screen, function(self, owner, attach)
    Screen._ctor(self, "SchemeUI")

	SetPause(true, "SchemeUI")
	TheInput:EnableDebugToggle(false)

    self.owner = owner
    self.attach = attach

    self.isopen = false

    self._scrnw, self._scrnh = TheSim:GetScreenSize()

    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self:SetMaxPropUpscale(MAX_HUD_SCALE)
    self:SetPosition(0, 0, 0)
    self:SetVAnchor(ANCHOR_MIDDLE)
    self:SetHAnchor(ANCHOR_MIDDLE)

    self.scalingroot = self:AddChild(Widget("schemeuiscalingroot"))
    self.scalingroot:SetScale(TheFrontEnd:GetHUDScale())

	self.destdata = {}
	self.destitem = {}

	self.numalter = 0
	self.numstat = 0

    self.root = self.scalingroot:AddChild(TEMPLATES.ScreenRoot("root"))

    -- secretly this thing is a modal Screen, it just LOOKS like a widget
    self.black = self.root:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black:SetTint(0, 0, 0, 0)
    self.black.OnMouseButton = function() self:OnCancel() end

    self.destspanel = self.root:AddChild(TEMPLATES.RectangleWindow(240, 360))
    self.destspanel:SetPosition(0, 25)

	self.title = self.destspanel:AddChild(Text(BODYTEXTFONT, 32))
	self.title:SetString(STRINGS.TAGGABLE_SELECT_DESTINATION)
	self.title:SetPosition(0, 155)

	self.cancelbutton = self.destspanel:AddChild(TEMPLATES.StandardButton(function() self:OnCancel() end, STRINGS.SIGNS.MENU.CANCEL, {120, 40}))
    self.cancelbutton:SetPosition(0, -220)

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
    self.default_focus = self.scroll_list
    self.isopen = true
end)

function SchemeUI:Initialize()
	self:InitScroll()
	self:MakeItem()
	self.cancelbutton:SetFocusChangeDir(MOVE_UP, self.scroll_list)
end

function SchemeUI:InitScroll()
	local function ScrollWidgetsCtor(context, index)
        local item = Widget("item-"..index)

		item.button = item:AddChild(TEMPLATES.ListItemBackground(340, 30, function() end))
		item.button.move_on_click = true

		item.name = item:AddChild(Text(BODYTEXTFONT, 20))
		item.name:SetVAlign(ANCHOR_MIDDLE)
		item.name:SetHAlign(ANCHOR_LEFT)
		item.name:SetPosition(0, 0, 5)
		item.name:SetRegionSize(220, 30)

		item.focus_forward = item.button

        item:SetOnGainFocus(function() if self.scroll_list ~= nil then self.scroll_list:OnWidgetFocus(item) end end)

        return item
    end

	local function ApplyDataToWidget(context, item, data, index)
		if data ~= nil then
			item.name:SetString(data.text or "")
			item.name:SetColour(1, 1, 1, 1)
			item.button:SetOnClick(function() self:OnSelected(data.index) end)
		else
			item.button:SetOnClick(nil)
		end
    end

	self.scroll_list = self.destspanel:AddChild(TEMPLATES.ScrollingGrid(self.destdata, {
        context = {},
        widget_width = 250,
        widget_height = 30,
        num_visible_rows = 8,
        num_columns = 1,
        item_ctor_fn = ScrollWidgetsCtor,
        apply_fn = ApplyDataToWidget,
        scrollbar_offset = 10,
        scrollbar_height_offset = -60,
        peek_percent = 0,
        allow_bottom_empty_row = true
	}))
    self.scroll_list:SetPosition(-5, 5)
    self.scroll_list:SetFocusChangeDir(MOVE_DOWN, self.cancelbutton)
end

function SchemeUI:MakeItem()
	local list = _G.TUNNELNETWORK
	local taggable = self.attach and self.attach.components.taggable

	if taggable ~= nil then
		for k, v in ipairs(list) do
			if tonumber(list[k].index) == taggable.index then	
				table.remove(list, k) -- delete destination towards itself.	
			end
		end

		if GetPlayer():HasTag("yakumoyukari") then
			self.staticon:SetTexture("images/inventoryimages/powerpanel.xml", "powerpanel.tex")
			self.staticon:SetSize(35, 35)
		end
	end

	self.destdata = list
	if self.scroll_list ~= nil then
		self.scroll_list:SetItemsData(self.destdata)
	end

	self.numalter, self.numstat = _G.GetCost(self.owner)
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
end

function SchemeUI:OnSelected(index)
    if not self.isopen then
        return
    end

	local taggable = self.attach.components.taggable
    if taggable ~= nil then
        taggable:Teleport(self.owner, index)
    end

    self.owner.HUD:CloseSchemeUI()
end

function SchemeUI:OnCancel()
    if not self.isopen then
        return
    end

	local taggable = self.attach.components.taggable
    if taggable ~= nil then
        taggable:OnCloseWidget()
    end

    self.owner.HUD:CloseSchemeUI()
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
	if self.isopen then
        self.attach = nil
        self.black:Kill()
        self.isopen = false

        self.inst:DoTaskInTime(.3, function() TheFrontEnd:PopScreen(self) end)
    end
end

return SchemeUI