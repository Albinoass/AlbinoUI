local A, C = AlbinoUI, AlbinoUI.Compatibility
local S = { hands = {}, observed = false }
A.SwingTimers = S
-- A timer starts only at an observed player swing. No guessed start on attack/combat entry.
function S:Observe(offhand, now)
    local hand = self.hands[offhand and 2 or 1]
    if hand and hand.speed and hand.speed > 0 then
        hand.started = now; hand.ends = now + hand.speed; self.observed = true
    end
end
function S:Reset()
    for _, hand in ipairs(self.hands) do hand.started, hand.ends = nil, nil end
end
function S:Speeds(now)
    local mh, oh
    if UnitAttackSpeed then mh, oh = UnitAttackSpeed("player") end
    for index, speed in ipairs({ C:Number(mh, 0), C:Number(oh, 0) }) do
        local hand = self.hands[index]
        if hand.ends and hand.speed and hand.speed > 0 and speed > 0 then
            -- Preserve fractional progress, an estimate when haste/parry effects aren't exposed.
            local fraction = math.max(0, math.min(1, (hand.ends-now)/hand.speed))
            hand.ends = now + fraction*speed
        end
        hand.speed = speed
        if speed <= 0 then hand.started, hand.ends = nil, nil end
    end
end
function S:CombatLog(...)
    local args = {...}
    local event = args[2]
    if not C:Public(event) then return end
    -- Supported public layouts: 4.2+ (sourceGUID index 4) and Wrath (index 3).
    local modern = type(args[3]) == "boolean"
    local source = args[modern and 4 or 3]
    if not C:Public(source) or source ~= UnitGUID("player") then return end
    if event ~= "SWING_DAMAGE" and event ~= "SWING_MISSED" then return end
    local payload = modern and 12 or 9
    local offhand = args[payload + (event == "SWING_DAMAGE" and 9 or 1)]
    -- Older logs without an off-hand flag cannot distinguish hands; show neither.
    if not C:Public(offhand) or type(offhand) ~= "boolean" then return end
    self:Observe(offhand, GetTime())
end
function S:Update(now)
    for _, hand in ipairs(self.hands) do
        local active = hand.ends and now < hand.ends
        hand.bar:SetValue(active and math.max(0, math.min(1, (hand.ends-now)/hand.speed)) or 0)
        -- A quiet/blocked event stream must never turn into a repeating fabricated clock.
        if not active then hand.started, hand.ends = nil, nil end
    end
end
function S:Apply()
    local config = A.db.swing
    self.frame:SetSize(config.width, config.height*2 + config.gap)
    for i, hand in ipairs(self.hands) do
        hand.bar:SetSize(config.width, config.height)
        hand.bar:ClearAllPoints(); hand.bar:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -(i-1)*(config.height+config.gap))
    end
    self.frame:SetShown(config.visible)
end
function S:Init()
    self.frame = A.Layout:New("swing", "Swing estimates (observed events only)")
    for i = 1, 2 do self.hands[i] = { bar = A.Layout:Bar(self.frame, 0.65, 0.65, i == 1 and 0.65 or 0.95) } end
    self.frame:EnableMouse(true)
    self.frame:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Swing estimates: main hand / off hand")
        GameTooltip:AddLine("Only starts on public player swing events. Blank if unavailable.\nHaste progress is estimated; hidden parry/reset effects cannot be inferred.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    self.frame:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    self:Speeds(GetTime())
    A:On("UNIT_ATTACK_SPEED", function(_, unit) if unit == "player" then S:Speeds(GetTime()) end end)
    A:On("PLAYER_EQUIPMENT_CHANGED", function() S:Reset(); S:Speeds(GetTime()) end)
    for _, event in ipairs({"PLAYER_LEAVING_WORLD", "PLAYER_DEAD", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD"}) do
        A:On(event, function() S:Reset() end)
    end
    A:On("COMBAT_LOG_EVENT_UNFILTERED", function(_, ...)
        if CombatLogGetCurrentEventInfo then S:CombatLog(CombatLogGetCurrentEventInfo()) else S:CombatLog(...) end
    end)
    -- Successfully cast spells can reset swings, but reset rules differ by server.
    -- Discard timing rather than assert an unverified new swing time.
    A:On("UNIT_SPELLCAST_SUCCEEDED", function(_, unit) if unit == "player" then S:Reset() end end)
    local elapsed = 0
    self.frame:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt; if elapsed < 0.03 then return end
        elapsed = 0; S:Update(GetTime())
    end)
end
