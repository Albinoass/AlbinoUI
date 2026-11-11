local mode = arg[1] or "legacy"
local M = dofile("tests/wow_mock.lua")
if mode == "legacy" then
    C_Spell = nil; Settings=nil
    function InterfaceOptions_AddCategory(panel) M.category=panel end
elseif mode == "unsupported" then
    RegisterStateDriver=nil; PlaceAction=nil
    local create=CreateFrame
    function CreateFrame(...)
        local frame=create(...)
        local register=frame.RegisterEvent
        function frame:RegisterEvent(event)
            if event=="COMBAT_LOG_EVENT_UNFILTERED" then error("Unknown event") end
            return register(self,event)
        end
        return frame
    end
elseif mode == "combat-login" then M.combat=true
elseif mode == "namespaced-actions" then
    C_ActionBar = {
        GetActionTexture=GetActionTexture,
        GetActionCooldown=function(slot)
            local start,duration,enabled,rate=GetActionCooldown(slot)
            return {startTime=start,duration=duration,isEnabled=enabled,modRate=rate}
        end,
        IsUsableAction=IsUsableAction,
        IsActionInRange=IsActionInRange,
    }
    GetActionTexture=nil; IsUsableAction=nil; IsActionInRange=nil
    -- Capture function above before removing the legacy global.
    local legacy=GetActionCooldown
    C_ActionBar.GetActionCooldown=function(slot)
        local s,d,e,r=legacy(slot); return {startTime=s,duration=d,isEnabled=e,modRate=r}
    end
    GetActionCooldown=nil
else error("unknown mode") end
for line in io.lines("AlbinoUI/AlbinoUI.toc") do
    if line:match("%.lua$") then assert(loadfile("AlbinoUI/"..line))() end
end
M.event("PLAYER_LOGIN")
local A=AlbinoUI
if mode=="combat-login" then
    assert(not A.initialized); M.combat=false; M.event("PLAYER_REGEN_ENABLED")
end
assert(A.initialized and A.Resources and M.category)
if mode=="unsupported" then
    assert(not A.ActionBars.available); assert(A.events.COMBAT_LOG_EVENT_UNFILTERED==nil)
else assert(A.ActionBars.available and #A.ActionBars.bars==2) end
if mode=="namespaced-actions" then
    M.slots[1]="Kick"; A.ActionBars:RefreshAll(); assert(A.ActionBars.bars[1].buttons[1].icon.texture=="native-Kick")
end
M.event("UNIT_POWER_UPDATE","player")
assert(A.Resources.energy.value==60)
print("PASS compatibility profile: "..mode)
