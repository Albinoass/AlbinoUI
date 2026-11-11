-- No external libraries. Files share this namespace; initialization waits for login.
AlbinoUI = { modules = {}, events = {}, pending = {}, version = "0.1.0" }
local A = AlbinoUI
local frame = CreateFrame("Frame")
A.frame = frame

function A:Print(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff8cde83Albino UI:|r " .. message) end
end

function A:On(event, callback)
    if not self.events[event] then
        -- Some Forever builds remove events. Unsupported events must not break login.
        local ok = pcall(frame.RegisterEvent, frame, event)
        if not ok then return false end
        self.events[event] = {}
    end
    table.insert(self.events[event], callback)
    return true
end

function A:InCombat()
    return InCombatLockdown and InCombatLockdown()
end

function A:Defer(key, callback)
    if self:InCombat() then self.pending[key] = callback; return false end
    callback()
    return true
end

function A:Flush()
    if self:InCombat() then return end
    -- Callbacks may enqueue more work; don't mutate the iterated table.
    local pending = self.pending
    self.pending = {}
    for _, callback in pairs(pending) do callback() end
end

function A:Apply()
    self:Defer("configuration", function()
        A.Layout:Apply()
        A.ActionBars:Apply()
        A.Resources:Apply()
        A.Cooldowns:Apply()
        A.SwingTimers:Apply()
        A.Layout:SetLocked(A.db.locked)
    end)
end

function A:SetLocked(locked)
    if not self.db then return end
    self.db.locked = locked
    if not self:Defer("lock", function() A.Layout:SetLocked(A.db.locked) end) then
        self:Print("Layout change queued until combat ends.")
    end
end

SLASH_ALBINOUI1 = "/albino"
SlashCmdList.ALBINOUI = function(message)
    message = string.lower((message or ""):match("^%s*(.-)%s*$"))
    if message == "lock" then A:SetLocked(true)
    elseif message == "unlock" then A:SetLocked(false)
    else A:Print("Use /albino lock or /albino unlock. Settings: Game Menu > Options > AddOns > Albino UI.") end
end

frame:SetScript("OnEvent", function(_, event, ...)
    local handlers = A.events[event]
    if handlers then for _, callback in ipairs(handlers) do callback(event, ...) end end
end)
A:On("PLAYER_REGEN_ENABLED", function() A:Flush() end)
A:On("PLAYER_LOGIN", function()
    if A.initialized then return end
    -- Loading during combat is unusual but possible; all protected work waits.
    A:Defer("initialize", function()
        if A.initialized then return end
        A.Persistence:Load()
        for _, name in ipairs({ "Layout", "ActionBars", "Resources", "Cooldowns", "SwingTimers", "Settings" }) do
            A[name]:Init()
        end
        A.initialized = true
        A:Apply()
        A:Print("Loaded. /albino unlock to move; configure in AddOns settings.")
    end)
end)

BINDING_HEADER_ALBINOUI = "Albino UI"
for bar = 1, 2 do
    for index = 1, 12 do
        _G["BINDING_NAME_CLICK AlbinoUIBar" .. bar .. "Button" .. index .. ":LeftButton"] =
            (bar == 1 and "Main " or "Secondary ") .. index
    end
end
