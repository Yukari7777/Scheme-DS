local ActionHandler = GLOBAL.ActionHandler
local EventHandler = GLOBAL.EventHandler
local TimeEvent = GLOBAL.TimeEvent
local State = GLOBAL.State
local Action = GLOBAL.Action
local FRAMES = GLOBAL.FRAMES
local ACTIONS = GLOBAL.ACTIONS
local TIMEOUT = 2


local spawng = State({ -- copy-pasted of quicktele sg yet.
    name = "spawng",
    tags = {"doing", "busy", "canrotate"},

    onenter = function(inst)
        inst.AnimState:PlayAnimation("atk")
        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
    end,

    timeline = 
    {
        TimeEvent(8*FRAMES, function(inst) inst:PerformBufferedAction() end),
    },

    events = {
        EventHandler("animover", function(inst)
            inst.sg:GoToState("idle") 
        end ),
    },
})
	
AddStategraphState("wilson", spawng)
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SPAWNG, "spawng"))

---------------------------------------------------------------------------------------------

local configg = State({ -- copy-pasted of quicktele sg yet.
    name = "configg",
    tags = {"doing", "busy", "canrotate"},

    onenter = function(inst)
        inst.AnimState:PlayAnimation("atk")
        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
    end,

    timeline = 
    {
        TimeEvent(8*FRAMES, function(inst) inst:PerformBufferedAction() end),
    },

    events = {
        EventHandler("animover", function(inst)
            inst.sg:GoToState("idle") 
        end ),
    },
})
	
AddStategraphState("wilson", configg)
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.CONFIGG, "configg"))

-------------------------------------------------------------------------------------------------

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SELECTG, "doshortaction"))