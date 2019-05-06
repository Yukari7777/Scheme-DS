local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local TextEdit = require "widgets/textedit"
local Menu = require "widgets/menu"
local UIAnim = require "widgets/uianim"
local ImageButton = require "widgets/imagebutton"

local VALID_CHARS = [[ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,:;[]\@!#$%&()'*+-/=?^_{|}~"]]

local TagScreen = Class(Screen, function(self, attach)
    Screen._ctor(self, "TagWriter")
	
	local MAX_LENGTH = 64

    self.owner = GetPlayer()
    self.taggable = attach.components.taggable

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

    self.bganim = self.root:AddChild(UIAnim())
    self.bganim:SetScale(1, 0.8, 1)
	self.bganim:SetPosition(0, -30, 0)
	self.bganim:GetAnimState():SetBank("ui_board_5x1")
	self.bganim:GetAnimState():SetBuild("ui_board_5x1")

    self.bgimage = self.root:AddChild(Image())
    self.bgimage:SetScale(1, 1, 1)
	--self.bgimage:SetTexture(bgatlas, bgimage)

    self.edit_text = self.root:AddChild(TextEdit(BUTTONFONT, 50, ""))
    self.edit_text:SetColour(0, 0, 0, 1)
    self.edit_text:SetCharacterFilter( VALID_CHARS )
    self.edit_text:SetPosition(0, 50, 0)
    self.edit_text:SetRegionSize(430, 160)
    self.edit_text:SetHAlign(ANCHOR_LEFT)
    self.edit_text:SetTextLengthLimit(MAX_LENGTH)
    self.edit_text:SetAllowClipboardPaste(true)
	self.edit_text:OnControl(CONTROL_ACCEPT, false)
    self.edit_text.OnTextEntered = function() self:OnControl(CONTROL_ACCEPT, false) end
    
	self.cancel_button = self.root:AddChild(ImageButton())
    self.cancel_button.image:SetScale(0.7)
    self.cancel_button:SetText(STRINGS.SIGNS.MENU.CANCEL)
    self.cancel_button:SetFont(BUTTONFONT)
    self.cancel_button:SetPosition(-150, -30, 0)
    self.cancel_button:SetOnClick(function() self:OnCancel() end)

	self.remove_buton = self.root:AddChild(ImageButton())
    self.remove_buton.image:SetScale(0.7)
    self.remove_buton:SetText(STRINGS.SIGNS.MENU.REMOVE)
    self.remove_buton:SetFont(BUTTONFONT)
    self.remove_buton:SetPosition(0, -30, 0)
    self.remove_buton:SetOnClick(function() self:OnRemove() end)

	self.accept_button = self.root:AddChild(ImageButton())
    self.accept_button.image:SetScale(0.7)
    self.accept_button:SetText(STRINGS.SIGNS.MENU.ACCEPT)
    self.accept_button:SetFont(BUTTONFONT)
    self.accept_button:SetPosition(150, -30, 0)
    self.accept_button:SetOnClick(function() self:OnAccept() end)

    self:Show()

    if self.bgimage.texture then
        self.bgimage:Show()
    else
        self.bganim:GetAnimState():PlayAnimation("open")
    end
end)

function TagScreen:OnBecomeActive()
    TagScreen._base.OnBecomeActive(self)
	self.owner:DoTaskInTime(4 * FRAMES, function()
		SetPause(true, "tagwidget")
		TheInput:EnableDebugToggle(false)
		self.edit_text:SetFocus()
		self.edit_text:SetEditing(true)
		self:SetDefaultString()
	end)
end

function TagScreen:SetDefaultString()
	self.edit_text:SetString(self.taggable.text or "")
end

function TagScreen:GetText()
    return self.edit_text:GetString()
end

function TagScreen:OnCancel()
    self:Close()
end

function TagScreen:OnRemove()
    self.taggable:Remove(self.owner)
    self:Close()
end

function TagScreen:OnAccept()
    --strip leading/trailing whitespace
    local text = self:GetText()
    local processed_msg = text:match("^%s*(.-%S)%s*$") or ""
    if text ~= processed_msg or #text <= 0 then
        self.edit_text:SetString(processed_msg)
        self.edit_text:SetEditing(true)
        return
    end

    self.taggable:Write(self.owner, text)
    self:Close()
end

function TagScreen:Close()
	SetPause(false)
	TheInput:EnableDebugToggle(true)

	self.taggable:OnCloseWidget()
    TheFrontEnd:PopScreen(self)
end

function TagScreen:OnControl(control, down)
    if TagScreen._base.OnControl(self, control, down) then return true end

	if not down and (control == CONTROL_CANCEL) then 
		self:OnCancel()
		return true
	end

end

return TagScreen
