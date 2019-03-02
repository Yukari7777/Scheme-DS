-- This file is to make this mod compatible for the non-DST version as some widget templates do not exist in DS.
-- Most of these contents are pure copy-pasted of DST.

local Widget = require "widgets/widget"
local NineSlice = require "widgets/nineslice"
local ImageButton = require "widgets/imagebutton"
local TrueScrollList = require "widgets/truescrolllist"

local CHATFONT = "bellefair"

function TEMPLATES.ScreenRoot(name)
    local root = Widget(name or "root")
    root:SetVAnchor(ANCHOR_MIDDLE)
    root:SetHAnchor(ANCHOR_MIDDLE)
    root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    return root
end

-- Common button.
-- icon_data allows a square button that's sized relative to label. Doesn't
-- behave well with changing button labels.
function TEMPLATES.StandardButton(onclick, txt, size, icon_data)
    local prefix = "button_carny_long"
    if size and #size == 2 then
        local ratio = size[1] / size[2]
        if ratio > 4 then
            -- Longer texture will look better at this aspect ratio.
            prefix = "button_carny_xlong"
        elseif ratio < 1.1 then
            -- The closest we have to a tall button.
            prefix = "button_carny_square"
        end
    end
    local btn = ImageButton("images/global_redux.xml",
        prefix.."_normal.tex",
        prefix.."_hover.tex",
        prefix.."_disabled.tex",
        prefix.."_down.tex")
    btn:SetOnClick(onclick)
    btn:SetText(txt)
    btn:SetFont(CHATFONT)
    btn:SetDisabledFont(CHATFONT)
    if size then
        btn:ForceImageSize(unpack(size))
        btn:SetTextSize(math.ceil(size[2]*.45))
    end
    if icon_data then
        local width = btn.text.size
        btn.icon = btn.text:AddChild(Image(unpack(icon_data)))
        btn.icon:ScaleToSize(width, width)
        local icon_x = 1
        if btn.text:GetString():len() > 0 then
            local offset = width/2
            local padding = 5
            icon_x = -btn.text:GetRegionSize()/2 - offset - padding
            btn.text:SetPosition(offset,0)
        else
            -- If there's no text, btn.text is probably hidden. Parent to button
            -- instead. Placing icon relative to text is much easier as a child
            -- of text, so only parent to button if there's no text to align
            -- against.
            btn.icon = btn:AddChild(btn.icon)
        end
        btn.icon:SetPosition(icon_x,0)
    end
    return btn
end

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
        row:UseFocusOverlay(prefix .."_hover.tex")
    else
        row:SetHelpTextMessage("") -- doesn't respond to clicks
    end
    return row
end

function TEMPLATES.ScrollingGrid(items, opts)
    local peek_height = opts.widget_height * 0.25 -- how much of row to see at the bottom.
    if opts.peek_percent then
        -- Caller can force a peek height if they will add items to the list or
        -- have hidden empty widgets.
        peek_height = opts.widget_height * opts.peek_percent
    elseif #items < opts.num_visible_rows * opts.num_columns then
        -- No peek if we won't scroll.
        -- This won't work if we later update the items in the grid. Would be
        -- nice if TrueScrollList could handle this but I think we'd need to
        -- update the scissor region or change the show widget threshold?
        peek_height = 0
    end
    local function ScrollWidgetsCtor(context, parent, scroll_list)
        local NUM_ROWS = opts.num_visible_rows + 2

        local widgets = {}
        for y = 1,NUM_ROWS do
            for x = 1,opts.num_columns do
                local index = ((y-1) * opts.num_columns) + x
                table.insert(widgets, parent:AddChild(opts.item_ctor_fn(context, index)))
            end
        end

        parent.grid = parent:AddChild(Grid())
        parent.grid:FillGrid(opts.num_columns, opts.widget_width, opts.widget_height, widgets)
        -- Centre grid position so scroll widget is more easily positioned and
        -- scissor automatically calculated.
        parent.grid:SetPosition(-opts.widget_width * (opts.num_columns-1)/2, opts.widget_height * (opts.num_visible_rows-1)/2 + peek_height/2)
        -- Give grid focus so it can pass on to contained widgets. It sets up
        -- focus movement directions.
        parent.focus_forward = parent.grid

        -- Higher up widgets are further to front so their hover text can
        -- appear over the widget beneath them.
        for i,w in ipairs(widgets) do
            w:MoveToBack()
        end

        -- end_offset helps ensure last item can scroll into view. It's a
        -- percent of a row height. 1 ensures that scrolling to the bottom puts
        -- a fully-displayed widget at the top. 0.75 prevents the next (empty)
        -- row from being visible.
        local end_offset = 0.75
        if opts.allow_bottom_empty_row then
            end_offset = 1
        end
        return widgets, opts.num_columns, opts.widget_height, opts.num_visible_rows, end_offset
    end

    local scissor_pad = opts.scissor_pad or 0
    local scissor_width  = opts.widget_width  * opts.num_columns      + scissor_pad
    local scissor_height = opts.widget_height * opts.num_visible_rows + peek_height
    local scissor_x = -scissor_width/2
    local scissor_y = -scissor_height/2
    local scroller = TrueScrollList(
        opts.scroll_context,
        ScrollWidgetsCtor,
        opts.apply_fn,
        scissor_x,
        scissor_y,
        scissor_width,
        scissor_height,
        opts.scrollbar_offset,
        opts.scrollbar_height_offset,
		opts.scroll_per_click
        )
    scroller:SetItemsData(items)
    scroller.GetScrollRegionSize = function(self)
        return scissor_width, scissor_height
    end
    return scroller
end

return TEMPLATES