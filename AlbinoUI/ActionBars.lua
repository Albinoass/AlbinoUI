local A, C = AlbinoUI, AlbinoUI.Compatibility
local B = { bars = {}, available = false }
A.ActionBars = B

function B:Slot(bar, index, page)
    if bar == 1 then return ((page or 1) - 1) * 12 + index end
    return 60 + index -- Native bottom-left bar (page 6); never shares primary or stealth slots.
end
function B:Binding(bar, index)
    return (bar == 1 and "ACTIONBUTTON" or "MULTIACTIONBAR1BUTTON") .. index
end
function B:Drag(button, receive)
    if A:InCombat() then return end
    local slot = C:Number(button:GetAttribute("action"))
    if not slot then return end
    -- Native cursor operations perform swap/replace/remove; placements stay in WoW's storage.
    if receive then PlaceAction(slot) else PickupAction(slot) end
    self:Refresh(button)
end
function B:Refresh(button)
    local slot = C:Number(button:GetAttribute("action"))
    if not slot then return end
    button.slot = slot
    local texture = C:ActionTexture(slot)
    if not C:Public(texture) then texture = nil end
    button.icon:SetTexture(texture)
    local start, duration, enabled, rate = C:ActionCooldown(slot)
    button.start, button.duration, button.rate = C:Cooldown(button.cooldown, start, duration, enabled, rate)
    self:UpdateRange(button)
    local count = GetActionCount and C:Number(GetActionCount(slot), 0) or 0
    button.count:SetText(count > 1 and tostring(count) or "")
    if IsCurrentAction then button:SetChecked(C:Flag(IsCurrentAction(slot))) end
    self:UpdateTimer(button)
end
function B:UpdateRange(button)
    local slot = button.slot
    if not slot then return end
    local usable, noPower = C:ActionUsable(slot)
    local range = C:ActionRange(slot)
    if C:Public(range) and (range == 0 or range == false) then
        button.icon:SetVertexColor(1, 0.25, 0.25)
    elseif C:Flag(noPower) then button.icon:SetVertexColor(0.3, 0.45, 1)
    elseif not C:Flag(usable) then button.icon:SetVertexColor(0.4, 0.4, 0.4)
    else button.icon:SetVertexColor(1, 1, 1) end
end
function B:UpdateTimer(button)
    button.timer:SetText(C:TimeText(C:Remaining(button.start, button.duration, GetTime(), button.rate)))
end
function B:RefreshAll()
    for _, bar in ipairs(self.bars) do for _, button in ipairs(bar.buttons) do self:Refresh(button) end end
end
function B:Bindings()
    if not self.available or A:InCombat() then return end
    ClearOverrideBindings(self.bindingOwner)
    for barIndex, bar in ipairs(self.bars) do
        for index, button in ipairs(bar.buttons) do
            local key1, key2 = GetBindingKey(self:Binding(barIndex, index))
            local custom = GetBindingKey("CLICK " .. button:GetName() .. ":LeftButton")
            button.hotkey:SetText(custom or key1 or "")
            if A.db.bars[barIndex].visible and index <= A.db.bars[barIndex].count then
                for _, key in pairs({key1, key2}) do
                    SetOverrideBindingClick(self.bindingOwner, false, key, button:GetName(), "LeftButton")
                end
            end
        end
    end
end
function B:NewButton(bar, barIndex, index)
    local name = "AlbinoUIBar" .. barIndex .. "Button" .. index
    local button = CreateFrame("CheckButton", name, bar, "SecureActionButtonTemplate,SecureHandlerStateTemplate")
    button:SetID(0) -- Secure action resolver must use the explicit slot attribute, not a paged ID.
    button:SetAttribute("type", "action")
    button:SetAttribute("action", self:Slot(barIndex, index))
    button:SetAttribute("checkselfcast", true)
    button:SetAttribute("checkfocuscast", true)
    button:RegisterForClicks("AnyUp")
    if barIndex == 1 then
        -- The secure driver, not an insecure combat event, selects Rogue's native stealth page.
        button:SetAttribute("_onstate-page", "self:SetAttribute('action', (tonumber(newstate)-1)*12+" .. index .. ")")
        RegisterStateDriver(button, "page", "[bonusbar:1] 7; 1")
    end
    A.Layout:Background(button)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(); button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight", "ADD")
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints()
    if button.cooldown.SetHideCountdownNumbers then button.cooldown:SetHideCountdownNumbers(true) end
    local overlay = CreateFrame("Frame", nil, button)
    overlay:SetAllPoints(); overlay:SetFrameLevel(button.cooldown:GetFrameLevel() + 2)
    button.timer = A.Layout:Text(overlay, 13)
    button.count = A.Layout:Text(overlay, 10, "BOTTOMRIGHT", -1, 1)
    button.hotkey = A.Layout:Text(overlay, 9, "TOPRIGHT", -1, -1)
    button:RegisterForDrag("LeftButton", "RightButton")
    button:SetScript("OnDragStart", function(self) B:Drag(self, false) end)
    button:SetScript("OnReceiveDrag", function(self) B:Drag(self, true) end)
    button:SetScript("OnEnter", function(self)
        if GameTooltip and self.slot then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetAction(self.slot); GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    -- Never replace the secure template's OnClick or call UseAction from Lua.
    button:HookScript("OnAttributeChanged", function(self, key)
        if key == "action" and self.icon then B:Refresh(self) end
    end)
    return button
end
function B:Apply()
    if not self.available or A:InCombat() then return end
    for barIndex, bar in ipairs(self.bars) do
        local settings = A.db.bars[barIndex]
        bar:SetSize(settings.count * (settings.size + settings.spacing) - settings.spacing, settings.size)
        for index, button in ipairs(bar.buttons) do
            button:ClearAllPoints(); button:SetPoint("LEFT", bar, "LEFT", (index-1)*(settings.size+settings.spacing), 0)
            button:SetSize(settings.size, settings.size); button:SetShown(index <= settings.count)
        end
        bar:SetShown(settings.visible)
    end
    self:Bindings(); self:RefreshAll()
end
function B:Init()
    self.available = C:SecureAvailable()
    if not self.available then
        A:Print("Required secure/native action APIs unavailable; action bars disabled. See compatibility report.")
        return
    end
    self.bindingOwner = CreateFrame("Frame", nil, UIParent)
    for index, key in ipairs({ "primary", "secondary" }) do
        local bar = A.Layout:New(key, index == 1 and "Main action bar" or "Secondary action bar")
        self.bars[index] = bar; bar.buttons = {}
        for i = 1, 12 do bar.buttons[i] = self:NewButton(bar, index, i) end
    end
    for _, event in ipairs({"ACTIONBAR_SLOT_CHANGED", "ACTIONBAR_UPDATE_COOLDOWN", "ACTIONBAR_UPDATE_USABLE",
        "ACTIONBAR_UPDATE_STATE", "SPELL_UPDATE_CHARGES", "PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED"}) do
        A:On(event, function() B:RefreshAll() end)
    end
    A:On("UPDATE_BINDINGS", function() A:Defer("bindings", function() B:Bindings() end) end)
    local elapsed = 0
    self.bindingOwner:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        if elapsed < 0.1 then return end
        elapsed = 0
        for index, bar in ipairs(B.bars) do
            local settings = A.db.bars[index]
            local hover = MouseIsOver and (MouseIsOver(bar) or MouseIsOver(bar.handle))
            -- Alpha only: fading never hides/disables a protected frame during combat.
            bar:SetAlpha((not settings.fade or hover or not A.db.locked) and 1 or 0.12)
        end
        for index, bar in ipairs(B.bars) do
            if A.db.bars[index].visible then
                for i = 1, A.db.bars[index].count do
                    B:UpdateRange(bar.buttons[i]); B:UpdateTimer(bar.buttons[i])
                end
            end
        end
    end)
end
