-- Deliberately bounded WoW API test double; this does not emulate taint or the secure executor.
Mock = { combat = false, now = 100, frames = {}, slots = {}, cursor = nil, calls = {},
    bindings = {ACTIONBUTTON1 = {"1", "SHIFT-1"}, MULTIACTIONBAR1BUTTON1 = {"F1"}}, overrides = {},
    health = 800, maxHealth = 1000, energy = 60, maxEnergy = 100, combo = 3, maxCombo = 5,
    mh = 2, oh = 1.5, secret = {}, modern = true }
local M = Mock
local methods = {}
local function protected(self)
    if M.combat and self.protected and self ~= UIParent then error("protected mutation in combat: " .. (self.name or self.kind)) end
end
local function updateProtection(parent)
    while parent and parent ~= UIParent do parent.protected = true; parent = parent.parent end
end
local function object(kind, name, parent, template)
    local self = setmetatable({ kind=kind, name=name, parent=parent, template=template, scripts={}, attributes={},
        shown=true, scale=1, width=1, height=1, level=1, text="" }, {__index=methods})
    if template and template:find("Secure") then self.protected = true; updateProtection(parent) end
    if template and template:find("SecureHandlerStateTemplate") then
        self.scripts.OnAttributeChanged=function(frame,key,value)
            local state=key:match("^state%-(.+)$")
            if not state then return end
            local body=frame.attributes["_onstate-"..state]
            if body then
                local code=assert(loadstring(body))
                setfenv(code,{self=frame,newstate=tostring(value),tonumber=tonumber})
                code()
            end
        end
        self.inheritedAttributeHandler = self.scripts.OnAttributeChanged
    end
    if name then _G[name] = self end
    M.frames[#M.frames+1] = self
    return self
end
function CreateFrame(...) return object(...) end
function methods:SetScript(key, callback) self.scripts[key] = callback end
function methods:GetScript(key) return self.scripts[key] end
function methods:HookScript(key, callback)
    local previous=self.scripts[key]
    self.scripts[key]=function(...)
        if previous then previous(...) end
        callback(...)
    end
end
function methods:RegisterEvent(event) self.events = self.events or {}; self.events[event] = true end
function methods:SetAttribute(key, value)
    protected(self); self.attributes[key] = value
    if self.scripts.OnAttributeChanged then self.scripts.OnAttributeChanged(self, key, value) end
end
function methods:GetAttribute(key) return self.attributes[key] end
function methods:GetName() return self.name end
function methods:SetID(id) self.id = id end
function methods:GetID() return self.id or 0 end
function methods:SetSize(w,h) protected(self); self.width,self.height=w,h end
function methods:SetWidth(w) protected(self); self.width=w end
function methods:SetHeight(h) protected(self); self.height=h end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetScale(scale) protected(self); self.scale=scale end
function methods:GetEffectiveScale() return self.scale*(self.parent and self.parent:GetEffectiveScale() or 1) end
function methods:SetPoint(...) protected(self); self.point={...} end
function methods:ClearAllPoints() protected(self); self.point=nil end
function methods:SetAllPoints() end
function methods:GetCenter()
    if self == UIParent then return self.width/2,self.height/2 end
    if self.center then return self.center[1],self.center[2] end
    local p = self.point
    if p and p[1] == "CENTER" then return UIParent.width/(2*self.scale)+(p[4] or 0), UIParent.height/(2*self.scale)+(p[5] or 0) end
    return 0,0
end
function methods:Show()
    protected(self); local old=self.shown; self.shown=true
    if not old and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Hide() protected(self); self.shown=false end
function methods:SetShown(value) if value then self:Show() else self:Hide() end end
function methods:IsShown() return self.shown end
function methods:SetAlpha(value) self.alpha=value end
function methods:SetMovable() end
function methods:SetClampedToScreen() end
function methods:StartMoving() protected(self); self.moving=true end
function methods:StopMovingOrSizing() protected(self); self.moving=false end
function methods:RegisterForDrag(...) self.dragButtons={...} end
function methods:RegisterForClicks(...) self.clickButtons={...} end
function methods:EnableMouse() end
function methods:CreateTexture() return object("Texture", nil, self) end
function methods:CreateFontString() return object("FontString", nil, self) end
function methods:SetTexture(texture) self.texture=texture end
function methods:SetVertexColor(...) self.color={...} end
function methods:SetTexCoord(...) self.texCoord={...} end
function methods:SetDrawLayer() end
function methods:SetFont() end
function methods:SetText(text) self.text=text end
function methods:GetText() return self.text end
function methods:SetHighlightTexture() end
function methods:SetCheckedTexture() end
function methods:SetChecked(value) self.checked=value end
function methods:GetChecked() return self.checked end
function methods:SetFrameStrata() end
function methods:SetFrameLevel(level) self.level=level end
function methods:GetFrameLevel() return self.level end
function methods:SetMinMaxValues(low, high) self.low,self.high=low,high end
function methods:SetValue(value) self.value=value end
function methods:SetStatusBarTexture() end
function methods:SetStatusBarColor(...) self.color={...} end
function methods:SetCooldown(start,duration,rate) self.cooldown={start,duration,rate} end
function methods:SetHideCountdownNumbers() end
function methods:SetAutoFocus() end
function methods:ClearFocus() end
function methods:SetScrollChild(child) self.child=child end
function methods:AddMessage(message) self.lastMessage=message end
function methods:SetOwner() end
function methods:SetAction(slot) self.slot=slot end
function methods:SetSpellByID(id) self.spell=id end
function methods:AddLine() end
UIParent = object("Frame", "UIParent"); UIParent:SetSize(1920,1080)
DEFAULT_CHAT_FRAME = object("Frame"); GameTooltip = object("Tooltip")
SlashCmdList = {}
Settings = {
    RegisterCanvasLayoutCategory=function(panel) return panel end,
    RegisterAddOnCategory=function(category) M.category=category end,
}
function InCombatLockdown() return M.combat end
function GetTime() return M.now end
function GetBuildInfo() return "1.60.1", "unknown", "", 16001 end
function issecretvalue(value) return value == M.secret end
function GetBindingKey(command) return unpack(M.bindings[command] or {}) end
function SetOverrideBindingClick(_, _, key, name, button)
    assert(not M.combat); M.overrides[key]={name,button}
end
function ClearOverrideBindings() assert(not M.combat); M.overrides={} end
function RegisterStateDriver(frame,state,condition)
    assert(not M.combat); frame.driver = {state,condition}
end
function PickupAction(slot)
    assert(not M.combat); M.cursor, M.slots[slot] = M.slots[slot], M.cursor
    M.calls[#M.calls+1]={"pickup",slot}
end
function PlaceAction(slot)
    assert(not M.combat); M.cursor, M.slots[slot] = M.slots[slot], M.cursor
    M.calls[#M.calls+1]={"place",slot}
end
function GetActionTexture(slot) return M.slots[slot] and ("native-" .. M.slots[slot]) end
function GetActionCooldown(slot)
    local cd=M.actionCD and M.actionCD[slot] or {0,0,1,1}; return unpack(cd)
end
function IsUsableAction() return M.usable ~= false,M.noPower end
function IsActionInRange() return M.range end
function GetActionCount() return 0 end
function IsCurrentAction() return false end
function MouseIsOver() return M.hover end
function UnitHealth() return M.health end
function UnitHealthMax() return M.maxHealth end
function UnitPower(_, power) if power == 4 then return M.combo else return M.energy end end
function UnitPowerMax(_, power) if power == 4 then return M.maxCombo else return M.maxEnergy end end
function GetComboPoints() return M.combo end
function UnitAttackSpeed() return M.mh,M.oh end
function UnitGUID() return "Player-1" end
function IsPlayerSpell(id) return id ~= 999 end
function GetSpellInfo(id)
    if type(id)=="string" then id=tonumber(id:match("^Spell (%d+)$")) end
    if not id or id == 9999 then return end; return "Spell "..id, nil, "icon-"..id,nil,nil,nil,id end
function GetSpellCooldown(id) return unpack(M.spellCD and M.spellCD[id] or {0,0,1,1}) end
C_Spell = {
    GetSpellInfo=function(id)
        local name,_,icon,_,_,_,resolved=GetSpellInfo(id)
        if name then return {name=name,iconID=icon,spellID=resolved} end
    end,
    GetSpellCooldown=function(id)
        local start,duration,enabled,rate=GetSpellCooldown(id)
        return {startTime=start,duration=duration,isEnabled=enabled,modRate=rate}
    end,
}
function M.event(event, ...)
    for _, frame in ipairs(M.frames) do
        if frame.events and frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame,event,...) end
    end
end
function M.state(button,page)
    -- Models attribute dispatch, not secure execution/taint. Attribute hooks must preserve it.
    local combat=M.combat; M.combat=false
    button:SetAttribute("state-page",tostring(page))
    M.combat=combat
end
return M
