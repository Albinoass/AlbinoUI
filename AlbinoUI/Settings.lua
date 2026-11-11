local A, C = AlbinoUI, AlbinoUI.Compatibility
local S = { controls = {} }
A.Settings = S
local function get(path)
    local value = A.db
    for _, key in ipairs(path) do value = value[key] end
    return value
end
local function set(path, value)
    local target = A.db
    for i = 1, #path-1 do target = target[path[i]] end
    target[path[#path]] = value
end
function S:Field(label, path, kind, low, high)
    local index = #self.controls
    local column, row = index % 2, math.floor(index / 2)
    local x, y = 12 + column*285, -12 - row*49
    local control
    if kind == "boolean" then
        control = CreateFrame("CheckButton", nil, self.content, "UICheckButtonTemplate")
        control:SetSize(26, 26); control:SetPoint("TOPLEFT", x, y-12)
        local text = A.Layout:Text(control, 11, "LEFT", 30, 0); text:SetText(label)
    else
        local text = A.Layout:Text(self.content, 11, "TOPLEFT", x, y); text:SetText(label)
        control = CreateFrame("EditBox", nil, self.content, "InputBoxTemplate")
        control:SetAutoFocus(false); control:SetSize(235, 22); control:SetPoint("TOPLEFT", x+5, y-16)
        control:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        control:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    end
    self.controls[#self.controls+1] = {widget = control, path = path, kind = kind, low = low, high = high}
end
function S:Refresh()
    for _, control in ipairs(self.controls) do
        local value = get(control.path)
        if control.kind == "boolean" then control.widget:SetChecked(value)
        elseif control.kind == "spells" then
            local ids = {}; for _, id in ipairs(value) do ids[#ids+1] = tostring(id) end
            control.widget:SetText(table.concat(ids, ", "))
        else control.widget:SetText(tostring(value)) end
    end
end
function S:Save()
    -- Validate all fields before committing any settings.
    local values = {}
    for index, control in ipairs(self.controls) do
        local value
        if control.kind == "boolean" then value = control.widget:GetChecked() and true or false
        elseif control.kind == "spells" then
            value = {}
            local text = control.widget:GetText()
            if text:find("[^%d,%s]") then A:Print("Tracked spells must be comma-separated numeric spell IDs."); return false end
            for id in text:gmatch("%d+") do
                id = tonumber(id)
                if id < 1 or id >= 10000000 or #value >= 24 then A:Print("Use up to 24 positive spell IDs."); return false end
                value[#value+1] = id
            end
        else
            value = tonumber(control.widget:GetText())
            if not value or value ~= value or value < control.low or value > control.high then
                A:Print("Invalid value: use " .. control.low .. "–" .. control.high .. ". No settings changed."); return false
            end
        end
        values[index] = value
    end
    for index, control in ipairs(self.controls) do set(control.path, values[index]) end
    A.Persistence:Normalize(A.db)
    A:Apply()
    A:Print(A:InCombat() and "Settings saved; protected changes queued until combat ends." or "Settings saved.")
    self:Refresh()
    return true
end
function S:Init()
    local panel = CreateFrame("Frame", "AlbinoUISettingsPanel", UIParent)
    panel.name = "Albino UI"; self.panel = panel
    panel:Hide() -- The category owns presentation; never display controls over the HUD at login.
    local title = A.Layout:Text(panel, 18, "TOPLEFT", 16, -14); title:SetText("Albino UI")
    local status = A.Layout:Text(panel, 11, "TOPLEFT", 16, -40)
    status:SetText(C:Build() .. " | " .. tostring(_VERSION))
    local help = A.Layout:Text(panel, 11, "TOPLEFT", 16, -60)
    help:SetText("Apply saves settings. Layout changes wait for combat to end. Spell IDs: max 24.")
    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -86); scroll:SetPoint("BOTTOMRIGHT", -32, 52)
    self.content = CreateFrame("Frame", nil, scroll)
    self.content:SetSize(580, 1000); scroll:SetScrollChild(self.content)
    for index, name in ipairs({ "Main", "Secondary" }) do
        self:Field(name .. " buttons (1–12)", {"bars",index,"count"}, "number", 1, 12)
        self:Field(name .. " button size (18–64)", {"bars",index,"size"}, "number", 18, 64)
        self:Field(name .. " spacing (0–16)", {"bars",index,"spacing"}, "number", 0, 16)
        self:Field(name .. " visible", {"bars",index,"visible"}, "boolean")
        self:Field(name .. " mouseover fade", {"bars",index,"fade"}, "boolean")
    end
    self:Field("UI scale (0.5–2)", {"scale"}, "number", 0.5, 2)
    self:Field("Resource width (100–900)", {"resources","width"}, "number", 100, 900)
    self:Field("Health height (2–30)", {"resources","healthHeight"}, "number", 2, 30)
    self:Field("Energy height (2–30)", {"resources","energyHeight"}, "number", 2, 30)
    self:Field("Resource gap (0–16)", {"resources","gap"}, "number", 0, 16)
    self:Field("Health / energy numbers", {"resources","numbers"}, "boolean")
    self:Field("Combo height (2–24)", {"resources","comboHeight"}, "number", 2, 24)
    self:Field("Combo gap (0–16)", {"resources","comboGap"}, "number", 0, 16)
    self:Field("Combo segments (1–10)", {"resources","comboCount"}, "number", 1, 10)
    self:Field("Use client combo maximum", {"resources","autoCombo"}, "boolean")
    self:Field("Cooldown icon size (18–64)", {"cooldowns","size"}, "number", 18, 64)
    self:Field("Cooldown spacing (0–16)", {"cooldowns","spacing"}, "number", 0, 16)
    self:Field("Show ready cooldowns", {"cooldowns","showReady"}, "boolean")
    self:Field("Tracked spell IDs (comma-separated)", {"cooldowns","spells"}, "spells")
    self:Field("Swing timers visible", {"swing","visible"}, "boolean")
    self:Field("Swing width (100–900)", {"swing","width"}, "number", 100, 900)
    self:Field("Swing height (2–16)", {"swing","height"}, "number", 2, 16)
    self:Field("Swing gap (0–16)", {"swing","gap"}, "number", 0, 16)
    self.content:SetHeight(math.ceil(#self.controls/2)*49 + 20)
    local apply = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    apply:SetSize(120, 24); apply:SetPoint("BOTTOMLEFT", 16, 16); apply:SetText("Apply settings")
    apply:SetScript("OnClick", function() S:Save() end)
    local move = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    move:SetSize(130, 24); move:SetPoint("LEFT", apply, "RIGHT", 12, 0); move:SetText("Toggle layout lock")
    move:SetScript("OnClick", function() A:SetLocked(not A.db.locked) end)
    panel:SetScript("OnShow", function() S:Refresh() end)
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        self.category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(self.category)
    elseif InterfaceOptions_AddCategory then InterfaceOptions_AddCategory(panel)
    else A:Print("Settings registration API unavailable on this client.") end
    self:Refresh()
end
