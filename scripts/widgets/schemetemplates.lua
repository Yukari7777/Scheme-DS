-- This file is to make this mod compatible for the non-DST version as some widget templates do not exist in DS.
-- Most of these contents are purely copy-pasted of DST.

local Widget = require "widgets/widget"
local Image = require "widgets/image"
local NineSlice = require "widgets/nineslice"
local ImageButton = require "widgets/imagebutton_redux"

local CHATFONT = "bellefair"

local function RGB(r, g, b)
    return { r / 255, g / 255, b / 255, 1 }
end

local GOLD = {202/255, 174/255, 118/255, 255/255}
local GREY = {.57, .57, .57, 1}
local BLACK = {.1, .1, .1, 1}
local WHITE = {1, 1, 1, 1}
local BROWN = {97/255, 73/255, 46/255, 255/255}
local RED = {.7, .1, .1, 1}
local DARKGREY = {.12, .12, .12, 1}

local UICOLOURS = {
    GOLD_CLICKABLE = RGB(215, 210, 157, 255), -- interactive text & menu
    GOLD_FOCUS = RGB(251, 193, 92, 255), -- menu active item
    GOLD_SELECTED = RGB(245, 243, 222, 255), -- titles and non-interactive important text
    GOLD_UNIMPORTANT = RGB(213, 213, 203, 255), -- non-interactive non-important text
    HIGHLIGHT_GOLD = RGB(243, 217, 161, 255),
    GOLD = GOLD,
    BROWN_MEDIUM = RGB(107, 84, 58),
    BROWN_DARK = RGB(80, 61, 39),
    BLUE = RGB(80, 143, 244, 255),
    GREY = GREY,
    BLACK = BLACK,
    WHITE = WHITE,
    BRONZE = RGB(180, 116, 36, 1),
    EGGSHELL = RGB(252, 230, 201),
    IVORY = RGB(236, 232, 223, 1),
    IVORY_70 = RGB(165, 162, 156, 1),
    PURPLE = RGB(152, 86, 232, 1),
    RED = RGB(207, 61, 61, 1),
    SLATE = RGB(155, 170, 177, 1),
	SILVER = RGB(192, 192, 192, 1),
}

TEMPLATES = {}
-- Grey-bounded dialog with grey border (nine-slice)
-- title (optional) is anchored to top.
-- buttons (optional) are anchored to bottom.
-- Almost exact copy of CurlyWindow.
function TEMPLATES.RectangleWindow(sizeX, sizeY, title_text, bottom_buttons, button_spacing, body_text)
    local w = NineSlice("images/dialogrect_9slice.xml")
    w.top = w:AddCrown("crown_top_fg.tex", ANCHOR_MIDDLE, ANCHOR_TOP, 0, 4)

    -- Background overlaps behind and foreground overlaps in front.
    w.bottom = w:AddCrown("crown_bottom_fg.tex", ANCHOR_MIDDLE, ANCHOR_BOTTOM, 0, -4)
    w.bottom:MoveToFront()

    -- Ensure we're within the bounds of looking good and fitting on screen.
    sizeX = math.clamp(sizeX or 200, 90, 1190)
    sizeY = math.clamp(sizeY or 200, 50, 620)
    w:SetSize(sizeX, sizeY)
    w:SetScale(0.7, 0.7)

    if title_text then
        w.title = w.top:AddChild(Text(HEADERFONT, 40, title_text, UICOLOURS.GOLD_SELECTED))
        w.title:SetPosition(0, -50)
        w.title:SetRegionSize(600, 50)
        w.title:SetHAlign(ANCHOR_MIDDLE)
        if JapaneseOnPS4() then
            w.title:SetSize(40)
        end
    end

    if bottom_buttons then
        -- If plain text widgets are passed in, then Menu will use this style.
        -- Otherwise, the style is ignored. Use appropriate style for the
        -- amount of space for buttons. Different styles require different
        -- spacing.
        local style = "carny_long"
        if button_spacing == nil then
            -- 1,2,3,4 buttons can be big at 210,420,630,840 widths.
            local space_per_button = sizeX / #bottom_buttons
            local has_space_for_big_buttons = space_per_button > 209
            if has_space_for_big_buttons then
                style = "carny_xlong"
                button_spacing = 320
            else
                button_spacing = 230
            end
        end
        local button_height = -30 -- cover bottom crown

        -- Does text need to be smaller than 30 for JapaneseOnPS4()?
        w.actions = w.bottom:AddChild(Menu(bottom_buttons, button_spacing, true, style, nil, 30))
        w.actions:SetPosition(-(button_spacing*(#bottom_buttons-1))/2, button_height) 

        w.focus_forward = w.actions
    end

    if body_text then
        w.body = w:AddChild(Text(CHATFONT, 28, body_text, UICOLOURS.WHITE))
        w.body:EnableWordWrap(true)
        w.body:SetPosition(0, -20)
        local height_reduction = 0
        if bottom_buttons then
            height_reduction = 30
        end
        w.body:SetRegionSize(sizeX, sizeY - height_reduction)
        w.body:SetVAlign(ANCHOR_MIDDLE)
    end

    w.SetBackgroundTint = function(self, r,g,b,a)
        for i=4,5 do
            self.elements[i]:SetTint(r,g,b,a)
        end
        self.mid_center:SetTint(r,g,b,a)
    end

    w.HideBackground = function(self)
        for i=4,5 do
            self.elements[i]:Hide()
        end
        self.mid_center:Hide()
    end

    w.InsertWidget = function(self, widget)
		w:AddChild(widget)
		for i=1,3 do
            self.elements[i]:MoveToFront()
        end
        for i=6,8 do
            self.elements[i]:MoveToFront()
        end
        w.bottom:MoveToFront()
		return widget
    end

    -- Default to our standard brown.
    local r,g,b = unpack(UICOLOURS.BROWN_DARK)
    w:SetBackgroundTint(r,g,b,0.6)

    return w
end

local function GetListItemPrefix(row_width, row_height)
    local prefix = "listitem_thick" -- 320 / 90 = 3.6
    local ratio = row_width / row_height
    if ratio > 6 then
        -- Longer texture will look better at this aspect ratio.
        prefix = "serverlist_listitem" -- 1220.0 / 50 = 24.4
    end
    return prefix
end

-- A list item backing that shows focus.
--
-- May want to call OnWidgetFocus if using with TrueScrollList or
-- ScrollingGrid:
--   row:SetOnGainFocus(function() self.scroll_list:OnWidgetFocus(row) end)
function TEMPLATES.ListItemBackground(row_width, row_height, onclick_fn)
    local prefix = GetListItemPrefix(row_width, row_height)
	local normal_list_item_bg_tint = { 1,1,1,0.5 }
    local focus_list_item_bg_tint  = { 1,1,1,0.7 }

    local row = ImageButton("images/frontend_redux.xml",
        prefix .."_normal.tex", -- normal
        nil, -- focus
        nil,
        nil,
        prefix .."_selected.tex" -- selected
        )
    row:ForceImageSize(row_width,row_height)
    row:SetImageNormalColour(  unpack(normal_list_item_bg_tint))
    row:SetImageFocusColour(   unpack(focus_list_item_bg_tint))
    row:SetImageSelectedColour(unpack(normal_list_item_bg_tint))
    row:SetImageDisabledColour(unpack(normal_list_item_bg_tint))
    row.scale_on_focus = false
    row.move_on_click = false

    if onclick_fn then
        row:SetOnClick(onclick_fn)
        -- FocusOverlay caused incorrect scaling on morgue screen, but it
        -- wasn't clickable. Related?
        --row:UseFocusOverlay(prefix .."_hover.tex")
    else
        row:SetHelpTextMessage("") -- doesn't respond to clicks
    end
    return row
end

return TEMPLATES