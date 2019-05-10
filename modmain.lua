PrefabFiles = {
	"tunnel",
	"schemetool",
}

Assets = {
	Asset( "IMAGE", "images/map_icons/minimap_tunnel.tex"),
	Asset( "ATLAS", "images/map_icons/minimap_tunnel.xml"),
	Asset( "IMAGE", "images/map_icons/schemetool.tex" ),
	Asset( "ATLAS", "images/map_icons/schemetool.xml" ),

	Asset( "IMAGE", "images/inventoryimages/schemetool.tex" ),
	Asset( "ATLAS", "images/inventoryimages/schemetool.xml" ),
	Asset( "IMAGE", "images/inventoryimages/sanitypanel.tex" ),
	Asset( "ATLAS", "images/inventoryimages/sanitypanel.xml" ),
	Asset( "IMAGE", "images/inventoryimages/powerpanel.tex" ),
	Asset( "ATLAS", "images/inventoryimages/powerpanel.xml" ),

	Asset( "IMAGE", "images/dialogcurly_9slice.tex" ),
	Asset( "ATLAS", "images/dialogcurly_9slice.xml" ),
	Asset( "IMAGE", "images/dialogrect_9slice.tex" ),
	Asset( "ATLAS", "images/dialogrect_9slice.xml" ),
	Asset( "IMAGE", "images/global_redux.tex" ),
	Asset( "ATLAS", "images/global_redux.xml" ),
	Asset( "IMAGE", "images/frontend_redux.tex" ),
	Asset( "ATLAS", "images/frontend_redux.xml" ),
	Asset( "IMAGE", "images/ui_redux.tex" ),
	Asset( "ATLAS", "images/ui_redux.xml" ),

	Asset( "ANIM" , "anim/ui_board_5x1.zip"),
	Asset( "ANIM" , "anim/swap_schemetool.zip"),
	Asset( "ANIM" , "anim/schemetool.zip"),
}

----- GLOBAL & require list -----
local require = GLOBAL.require
local TECH = GLOBAL.TECH
local RECIPETABS = GLOBAL.RECIPETABS
local TheFrontEnd = GLOBAL.TheFrontEnd
local TagScreen = require "screens/tagscreen"
local SchemeUI = require "screens/schemeui"
GLOBAL.SCHEME_MODNAME = GLOBAL.KnownModIndex:GetModActualName("Scheme")
GLOBAL.SCHEME_IGNOREDANGER = GetModConfigData("ignoredanger")
GLOBAL.SCHEME_IGNOREBOSS = GetModConfigData("ignoreboss")
GLOBAL.SCHEME_ALTERPREFAB = GetModConfigData("alter")

require "class"

AddMinimapAtlas("images/map_icons/minimap_tunnel.xml")
AddMinimapAtlas("images/map_icons/schemetool.xml")
------ Functions ------

local Language =  GetModConfigData("language")
GLOBAL.SCHEME_LANGUAGE = "en"
if Language == "AUTO" then
	local KnownModIndex = GLOBAL.KnownModIndex
	for _, moddir in ipairs(KnownModIndex:GetModsToLoad()) do
		local modname = KnownModIndex:GetModInfo(moddir).name
		if modname == "한글 모드 서버 버전" or modname == "한글 모드 클라이언트 버전" then 
			GLOBAL.SCHEME_LANGUAGE = "kr"
--		elseif modname == "Chinese modname Pack" or modname == "Chinese Plus" then
--			GLOBAL.SCHEME_LANGUAGE = "ch"
--		elseif modname == "Russian modname Pack" or modname == "Russification Pack for DST" or modname == "Russian For Mods (Client)" then
--			GLOBAL.SCHEME_LANGUAGE = "ru"
		end 
	end 
else
	GLOBAL.SCHEME_LANGUAGE = Language
end

AddClassPostConstruct("widgets/button", function(self) 
	local Button = self

	function Button:SetOnDown( fn )
		self.ondown = fn
	end

	function Button:SetWhileDown( fn )
		self.whiledown = fn
	end

	function Button:OnControl(control, down)
		if Button._base.OnControl(self, control, down) then return true end

		if not self:IsEnabled() or not self.focus then return false end
	
		--if self:IsSelected() and not self.AllowOnControlWhenSelected then return false end
	
		if control == self.control then

			if down then
				if not self.down then
					GLOBAL.TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
					self.o_pos = self:GetLocalPosition()
					self:SetPosition(self.o_pos + self.clickoffset)
					self.down = true
					if self.whiledown then
						self:StartUpdating()
					end
					if self.ondown then
						self.ondown()
					end
				end
			else
				if self.down then
					self.down = false
					self:ResetPreClickPosition()
					if self.onclick then
						self.onclick()
					end
					self:StopUpdating()
				end
			end
		
			return true
		end
	end
end)

TUNING.SCHEMETOOL_USES = 36
local recipe = GLOBAL.Recipe("schemetool", {Ingredient("telestaff", 1), Ingredient("marble", 12), Ingredient("orangegem", 6)}, RECIPETABS.MAGIC, TECH.MAGIC_TWO)
recipe.atlas = "images/inventoryimages/schemetool.xml"

modimport "scripts/strings_scheme.lua"
modimport "scripts/schememanager.lua"
modimport "scripts/actions_scheme.lua" -- actions must be loaded before stategraph loads
modimport "scripts/stategraph_scheme.lua"