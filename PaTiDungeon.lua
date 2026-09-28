local DB
local testMode=false
local frame=CreateFrame("Frame","PaTiDungeonFrame",UIParent,"BackdropTemplate")
frame:SetSize(280,132); frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
frame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
local title=frame:CreateFontString(nil,"OVERLAY","GameFontNormal"); title:SetPoint("TOPLEFT",14,-12); title:SetText("PaTiDungeon")
local body=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); body:SetPoint("TOPLEFT",14,-38); body:SetPoint("BOTTOMRIGHT",-14,12); body:SetJustifyH("LEFT"); body:SetJustifyV("TOP")
local function update()
 if testMode then body:SetText("TESTINSTANZ\nGruppe: 5 Mitglieder\nKampf: nein\nLeitung: Du") return end
 local name,instanceType=GetInstanceInfo(); local inInstance=IsInInstance(); local members=GetNumGroupMembers() or 0
 local leader=UnitIsGroupLeader("player") and "Du" or "Andere Person"
 body:SetText((inInstance and (name or "Unbekannte Instanz") or "Nicht in einer Instanz").."\nTyp: "..(instanceType or "-").."\nGruppe: "..members.." Mitglieder\nKampf: "..(UnitAffectingCombat("player") and "ja" or "nein").."\nLeitung: "..leader)
end
frame:SetScript("OnDragStart",function(self) if not DB.locked then self:StartMoving() end end)
frame:SetScript("OnDragStop",function(self) self:StopMovingOrSizing(); local _,_,_,x,y=self:GetPoint(); DB.x=x; DB.y=y end)
local events=CreateFrame("Frame"); for _,event in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","GROUP_ROSTER_UPDATE","ZONE_CHANGED_NEW_AREA","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function(_,event) if event=="PLAYER_LOGIN" then PaTiDungeonDB=PaTiDungeonDB or {}; DB=PaTiDungeonDB; DB.x=DB.x or -330; DB.y=DB.y or 160; DB.locked=DB.locked or false; frame:ClearAllPoints(); frame:SetPoint("CENTER",UIParent,"CENTER",DB.x,DB.y) end; update() end)
SLASH_PATIDUNGEON1="/patidungeon"; SLASH_PATIDUNGEON2="/pd"; SlashCmdList.PATIDUNGEON=function(message) local c=(message or ""):match("^%s*(.-)%s*$"):lower(); if c=="test" then testMode=not testMode; update() elseif c=="show" then frame:Show() elseif c=="hide" then frame:Hide() elseif c=="lock" then DB.locked=true elseif c=="unlock" then DB.locked=false else print("|cff68caffPaTiDungeon:|r /pd test, show, hide, lock, unlock") end end
