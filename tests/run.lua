local M = dofile("tests/wow_mock.lua")
local files = {}
for line in io.lines("AlbinoUI/AlbinoUI.toc") do if line:match("%.lua$") then files[#files+1]=line end end
for _, file in ipairs(files) do assert(loadfile("AlbinoUI/"..file))("AlbinoUI") end
local A, C, count = AlbinoUI, AlbinoUI.Compatibility, 0
local function eq(actual, expected)
    assert(actual == expected, "expected "..tostring(expected)..", got "..tostring(actual))
end
local function test(name, callback)
    local ok, err = pcall(callback)
    if not ok then io.stderr:write("FAIL "..name..": "..err.."\n"); os.exit(1) end
    count=count+1; print("PASS "..name)
end
local function click(widget, script, ...) return widget.scripts[script](widget, ...) end

test("TOC-order login creates all modules and settings",function()
    M.event("PLAYER_LOGIN"); assert(A.initialized); eq(#A.ActionBars.bars,2); eq(#A.Settings.controls,28)
    eq(M.category,A.Settings.panel); eq(A.db,AlbinoUIDB); eq(A.Settings.panel.shown,false)
end)
test("login idempotent",function() local n=#M.frames; M.event("PLAYER_LOGIN"); eq(#M.frames,n) end)
test("secure template and explicit slot attributes",function()
    for b,bar in ipairs(A.ActionBars.bars) do for i,button in ipairs(bar.buttons) do
        assert(button.template:find("SecureActionButtonTemplate")); eq(button:GetID(),0)
        eq(button:GetAttribute("type"),"action"); eq(button:GetAttribute("action"),b==1 and i or 60+i)
        eq(button.scripts.OnClick,nil); eq(button.clickButtons[1],"AnyUp")
    end end
end)
test("native keybindings preserve both keys and secondary mappings",function()
    eq(M.overrides['1'][1],"AlbinoUIBar1Button1"); eq(M.overrides['SHIFT-1'][1],"AlbinoUIBar1Button1")
    eq(M.overrides.F1[1],"AlbinoUIBar2Button1")
end)
test("bar and stealth slots never overlap",function()
    local slots={}
    for _,page in ipairs({1,7}) do for i=1,12 do slots[A.ActionBars:Slot(1,i,page)]=true end end
    for i=1,12 do assert(not slots[A.ActionBars:Slot(2,i)]) end
end)
test("secure snippet selects stealth page during combat",function()
    local button=A.ActionBars.bars[1].buttons[1]; M.combat=true; M.state(button,7)
    eq(button:GetAttribute("action"),73); M.state(button,1); M.combat=false
end)
test("spellbook drop and replacement use native slots",function()
    local button=A.ActionBars.bars[1].buttons[1]
    M.cursor="Sinister Strike"; click(button,"OnReceiveDrag"); eq(M.slots[1],"Sinister Strike"); eq(M.cursor,nil)
    M.cursor="Eviscerate"; click(button,"OnReceiveDrag"); eq(M.slots[1],"Eviscerate"); eq(M.cursor,"Sinister Strike")
end)
test("move swap and remove retain native cursor behavior",function()
    local first=A.ActionBars.bars[1].buttons[1]; local second=A.ActionBars.bars[2].buttons[1]
    M.cursor=nil; click(first,"OnDragStart"); eq(M.slots[1],nil); eq(M.cursor,"Eviscerate")
    M.slots[61]="Kick"; click(second,"OnReceiveDrag"); eq(M.slots[61],"Eviscerate"); eq(M.cursor,"Kick")
    click(first,"OnReceiveDrag"); eq(M.slots[1],"Kick"); eq(M.cursor,nil)
    click(first,"OnDragStart"); M.cursor=nil; eq(M.slots[1],nil)
end)
test("locking layout never disables spell dragging",function()
    A:SetLocked(true); M.cursor="Kick"; click(A.ActionBars.bars[1].buttons[1],"OnReceiveDrag"); eq(M.slots[1],"Kick")
end)
test("drag in combat cannot mutate native placements",function()
    local n=#M.calls; M.combat=true
    click(A.ActionBars.bars[1].buttons[1],"OnDragStart"); click(A.ActionBars.bars[1].buttons[1],"OnReceiveDrag")
    M.combat=false; eq(#M.calls,n)
end)
test("count size spacing visibility changes defer across combat",function()
    local bar=A.ActionBars.bars[1]; local oldWidth=bar:GetWidth()
    M.combat=true; A.db.bars[1].count=6; A.db.bars[1].size=40; A.db.bars[1].spacing=4
    A:Apply(); eq(bar:GetWidth(),oldWidth); assert(A.pending.configuration)
    M.combat=false; M.event("PLAYER_REGEN_ENABLED"); eq(bar:GetWidth(),260); eq(bar.buttons[7].shown,false)
    A.db.bars[1].count=12; A:Apply()
end)
test("binding updates deferred in combat",function()
    M.combat=true; M.bindings.ACTIONBUTTON1={"2"}; M.event("UPDATE_BINDINGS"); assert(M.overrides['1'])
    M.combat=false; M.event("PLAYER_REGEN_ENABLED"); assert(M.overrides['2']); eq(M.overrides['1'],nil)
end)
test("exactly two accepted slash actions queue lock",function()
    M.combat=true; SlashCmdList.ALBINOUI("unlock"); eq(A.db.locked,false)
    M.combat=false; M.event("PLAYER_REGEN_ENABLED"); eq(A.Layout.frames.primary.handle.shown,true)
    SlashCmdList.ALBINOUI("lock"); eq(A.Layout.frames.primary.handle.shown,false)
    SlashCmdList.ALBINOUI("reset"); eq(A.db.locked,true)
end)
test("all five elements move independently",function()
    A:SetLocked(false)
    local i=0
    for key,frame in pairs(A.Layout.frames) do
        i=i+1; frame.center={960+i*10,540+i*10}; click(frame.handle,"OnDragStart"); assert(frame.moving)
        click(frame.handle,"OnDragStop"); eq(A.db.positions[key].x,i*10); eq(A.db.positions[key].y,i*10)
        frame.center=nil
    end
    eq(i,5); A:SetLocked(true)
end)
test("scale saves positions in UIParent units",function()
    local f=A.Layout.frames.primary; A.db.scale=1.5; A.Layout:Apply(); A.Layout:Save("primary")
    local pos=A.db.positions.primary; local x,y=pos.x,pos.y
    A.Layout:Apply(); A.Layout:Save("primary"); eq(pos.x,x); eq(A.db.positions.primary.y,y)
    A.db.scale=1; A.Layout:Apply()
end)
test("health energy combo events update actual values",function()
    M.health=777; M.energy=22; M.combo=4; M.event("UNIT_POWER_FREQUENT","player")
    eq(A.Resources.health.value,777); eq(A.Resources.energy.value,22)
    eq(A.Resources.segments[4].fill.shown,true); eq(A.Resources.segments[5].fill.shown,false)
end)
test("target change clears legacy combo and modern uses power",function()
    M.combo=0; M.event("PLAYER_TARGET_CHANGED"); eq(A.Resources.segments[1].fill.shown,false)
    local modern=C_Spell; C_Spell=nil; M.combo=2; eq(C:Combo(),2); C_Spell=modern
end)
test("client resource max adapts to additional segments",function()
    M.maxCombo=7; M.event("UNIT_MAXPOWER","player"); eq(A.Resources.maximum,7); eq(A.Resources.segments[7].shown,true)
    M.maxCombo=5; M.event("UNIT_MAXPOWER","player")
end)
test("secret resources degrade safely",function()
    M.health=M.secret; M.energy=M.secret; M.combo=M.secret; A.Resources:Update()
    eq(A.Resources.health.value,0); eq(A.Resources.energy.value,0)
    M.health=800; M.energy=60; M.combo=3; A.Resources:Update()
end)
test("cooldown math expiry rate disabled and minute text",function()
    eq(C:Remaining(90,30,100,1),20); eq(C:Remaining(90,30,100,2),5)
    eq(C:Remaining(0,30,10,1),0); eq(C:Remaining(10,1,100,1),0)
    eq(C:TimeText(61),"2m"); eq(C:TimeText(0.1),"1"); eq(C:TimeText(0),"")
    local w=A.ActionBars.bars[1].buttons[1].cooldown
    eq(C:Cooldown(w,100,30,0,1),0); eq(w.shown,false)
    eq(C:Cooldown(w,M.secret,30,1,1),0)
end)
test("tracker uses native textures and configurable ready visibility",function()
    A.db.cooldowns.spells={1766,999,9999}; M.spellCD={[1766]={90,30,1,1}}
    A.Cooldowns:Update(); eq(A.Cooldowns.icons[1].texture.texture,"icon-1766"); eq(A.Cooldowns.icons[1].text.text,"20")
    eq(A.Cooldowns.icons[2].shown,false); eq(A.Cooldowns.icons[3].shown,false)
    A.db.cooldowns.showReady=false; M.now=121; A.Cooldowns:Update(); eq(A.Cooldowns.icons[1].shown,false)
    M.now=100; A.db.cooldowns.showReady=true
end)
test("tracker ignores global cooldown only",function()
    M.spellCD={[1766]={100,1.5,1,1}}; A.db.cooldowns.showReady=false; A.Cooldowns:Update()
    eq(A.Cooldowns.icons[1].shown,false); A.db.cooldowns.showReady=true
end)
test("action states range power and unusable",function()
    local button=A.ActionBars.bars[1].buttons[1]
    M.range=0; A.ActionBars:Refresh(button); eq(button.icon.color[2],0.25)
    M.range=nil; M.noPower=true; A.ActionBars:Refresh(button); eq(button.icon.color[3],1)
    M.noPower=false; M.usable=false; A.ActionBars:Refresh(button); eq(button.icon.color[1],0.4)
    M.usable=true
end)
test("swing doesn't start at login or invent repeats",function()
    local S=A.SwingTimers; S:Reset(); S:Update(100); eq(S.hands[1].ends,nil)
    S:Observe(false,100); S:Update(101); eq(S.hands[1].bar.value,0.5)
    S:Update(103); eq(S.hands[1].ends,nil); eq(S.hands[1].bar.value,0)
end)
test("combat log identifies modern offhand damage and misses",function()
    local S=A.SwingTimers; S:Reset()
    S:CombatLog(100,"SWING_DAMAGE",false,"Player-1","Rogue",0,0,"Target-1","Enemy",0,0,20,0,1,0,0,0,false,false,false,true)
    assert(S.hands[2].ends); eq(S.hands[1].ends,nil)
    S:CombatLog(100,"SWING_MISSED",false,"Player-1","Rogue",0,0,"Target-1","Enemy",0,0,"MISS",false)
    assert(S.hands[1].ends)
end)
test("combat log ignores other units missing flags and secret source",function()
    local S=A.SwingTimers; S:Reset()
    S:CombatLog(100,"SWING_MISSED",false,"Other","Rogue",0,0,"Target-1","Enemy",0,0,"MISS",false)
    eq(S.hands[1].ends,nil)
    S:CombatLog(100,"SWING_DAMAGE",false,M.secret); eq(S.hands[1].ends,nil)
    S:CombatLog(100,"SWING_DAMAGE",false,"Player-1"); eq(S.hands[1].ends,nil)
end)
test("speed change preserves fractional progress",function()
    local S=A.SwingTimers; S:Reset(); S:Speeds(100); S:Observe(false,100)
    M.mh=1; S:Speeds(101); eq(S.hands[1].ends,101.5); M.mh=2; S:Reset(); S:Speeds(100)
end)
test("equipment cast death combat exit invalidate swing estimates",function()
    for _,event in ipairs({"PLAYER_EQUIPMENT_CHANGED","UNIT_SPELLCAST_SUCCEEDED","PLAYER_DEAD","PLAYER_REGEN_ENABLED"}) do
        A.SwingTimers:Observe(false,100); M.event(event,"player"); eq(A.SwingTimers.hands[1].ends,nil)
    end
end)
test("mouseover fade uses alpha without protected visibility changes",function()
    A.db.bars[2].fade=true; M.hover=false; M.combat=true
    A.ActionBars.bindingOwner.scripts.OnUpdate(nil,0.1); eq(A.ActionBars.bars[2].alpha,0.12)
    M.hover=true; A.ActionBars.bindingOwner.scripts.OnUpdate(nil,0.1); eq(A.ActionBars.bars[2].alpha,1)
    M.combat=false; M.hover=false
end)
test("SavedVariables preserve empty trackers and reject corrupt settings",function()
    local db=A.Persistence:Normalize({scale=0/0,bars={{count=99}},cooldowns={spells={}}})
    eq(db.scale,1); eq(db.bars[1].count,12); eq(#db.cooldowns.spells,0)
    eq(db.bars[2].count,12); eq(db.locked,true)
end)
test("normalization preserves user spell IDs without appending defaults",function()
    local db=A.Persistence:Normalize({cooldowns={spells={2983}}}); eq(#db.cooldowns.spells,1); eq(db.cooldowns.spells[1],2983)
end)
test("settings transaction rejects invalid fields without partial writes",function()
    A.Settings:Refresh(); local first=A.Settings.controls[1]; local old=A.db.bars[1].count
    first.widget:SetText("0"); eq(A.Settings:Save(),false); eq(A.db.bars[1].count,old); A.Settings:Refresh()
end)
test("settings persist booleans spells and dimensions across reload",function()
    A.Settings:Refresh()
    for _,control in ipairs(A.Settings.controls) do
        if control.kind=="spells" then control.widget:SetText("1766, 2983") end
        if control.path[#control.path]=="width" then control.widget:SetText("350") end
    end
    assert(A.Settings:Save()); A.Persistence:Load(); eq(A.db.resources.width,350); eq(#A.db.cooldowns.spells,2)
end)
test("legacy spell API fallback",function()
    local modern=C_Spell; C_Spell=nil; local name,icon,id=C:SpellInfo(1766)
    eq(name,"Spell 1766"); eq(icon,"icon-1766"); eq(id,1766); C_Spell=modern
end)
test("timer ticks do not poll textures or spell cooldown APIs",function()
    local texture,spell=GetActionTexture,C_Spell.GetSpellCooldown
    GetActionTexture=function() error("texture polling") end
    C_Spell.GetSpellCooldown=function() error("spell cooldown polling") end
    A.ActionBars.bindingOwner.scripts.OnUpdate(nil,0.1)
    A.Cooldowns.frame.scripts.OnUpdate(nil,0.1)
    GetActionTexture=texture; C_Spell.GetSpellCooldown=spell
end)
test("tracker disabled cooldown never shows an active countdown",function()
    A.db.cooldowns.spells={1766}; A.db.cooldowns.showReady=false
    M.spellCD={[1766]={100,30,0,1}}; A.Cooldowns:Update(); eq(A.Cooldowns.icons[1].shown,false)
    A.db.cooldowns.showReady=true
end)
test("stealth drag writes the stealth slot only",function()
    local button=A.ActionBars.bars[1].buttons[2]
    M.state(button,7); M.cursor="Ambush"; click(button,"OnReceiveDrag")
    eq(M.slots[74],"Ambush"); eq(M.slots[62],nil); M.state(button,1)
end)
test("attribute observer preserves inherited secure state handler",function()
    local button=A.ActionBars.bars[1].buttons[3]
    assert(button.inheritedAttributeHandler)
    button:SetAttribute("state-page","7"); eq(button:GetAttribute("action"),75)
    button:SetAttribute("state-page","1"); eq(button:GetAttribute("action"),3)
end)
test("absent player combo power uses target combo API",function()
    local power,legacy=UnitPower,GetComboPoints
    M.maxCombo=0
    GetComboPoints=function(player,target) eq(player,"player"); eq(target,"target"); return 4 end
    UnitPower=function() error("no combo player power capability") end
    local count,max=C:Combo(); eq(count,4); eq(max,5)
    UnitPower=power; GetComboPoints=legacy; M.maxCombo=5
end)
print(string.format("RESULT %d tests passed; mocked APIs, no live-client validation",count))
