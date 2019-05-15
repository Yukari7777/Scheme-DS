name = "Scheme"
version = "1.0.3"
description = "Suspicious, Creepy gaps linking space and space.\n\n\nVersion : "..version
author = "Yakumo Yukari"
forumthread = ""
api_version = 6
api_version_dst = 10
priority = 2

dont_starve_compatible = true
reign_of_giants_compatible = true
shipwrecked_compatible = true
porkland_compatible = true
dst_compatible = false

icon_atlas = "modicon.xml"
icon = "modicon.tex"

local spawncost = {}
for i = 0, 500 do spawncost[i + 1] = { description = ""..i.."", data = i } end
spawncost[1].description = "No cost"

local usecost = {}
for i = 0, 500 do usecost[i + 1] = { description = ""..i.."", data = i } end
usecost[1].description = "No cost"

local alterval = {}
for i = 1, 500 do alterval[i] = { description = ""..i.."", data = i } end

local GPL = {}
for i = 0, 4 do GPL[i + 1] = { description = ""..i.."", data = i } end

configuration_options = {
	{
		name = "language",
		label = "anguage",
		hover = "Set Language",
		options = {
			{ description = "Auto", data = "AUTO" },
			{ description = "한국어", data = "kr" },
			{ description = "English", data = "en" },
			--{ description = "中文", data = "ch" },
			--{ description = "русский", data = "ru" },
		},
		default = "AUTO",
	},
	{
		name = "spawncost",
		label = "Spawn cost",
		hover = "Set sanity cost on creating Scheme Gate.\n스키마 게이트를 소환할 때의 비용을 설정합니다.",
		options = spawncost,
		default = 100,
	},

	{
		name = "usecost",
		label = "Use cost",
		hover = "Set sanity cost of using Scheme Gate.\n스키마 게이트를 사용할 때의 비용을 설정합니다.",
		options = usecost,
		default = 50,
	},

	{
		name = "alter",
		label = "Cost alternatives",
		hover = "Set which item should be used for alternatives for the cost of sanity.\n정신력 대신 사용될 아이템을 정합니다.",
		options = {
			{ description = "No alter",			data = "noalter" },
			{ description = "Purple Gem",		data = "purplegem" },
			{ description = "Orange Gem",		data = "orangegem" },
			{ description = "Nightmare Fuel",	data = "nightmarefuel" },
		},
		default = "nightmarefuel",
	},

	{
		name = "alterval",
		label = "Alternatives value",
		hover = "Set alternative's value.\n대체템의 가치를 정합니다.",
		options = alterval,
		default = 15,
	},

	{
		name = "ignoredanger",
		label = "Ignore danger",
		hover = "Should ignore danger nearby on teleporting?\n순간이동 할 때 주변의 위험 요소들을 무시합니까?",
		options = {
			{ description = "no", data = false },
			{ description = "yes",	data = true },
		},
		default = false,
	},
	{
		name = "ignoreboss",
		label = "Ignore boss",
		hover = "Should teleport when a boss is nearby?\n보스가 있을때도 순간이동이 가능합니까?",
		options = {
			{ description = "no", data = false },
			{ description = "yes",	data = true },
		},
		default = false,
	},
}