-- core.lua — Ace3 core for TacoRot (Classic Anniversary 1.15.5)
local AceAddon = LibStub and LibStub("AceAddon-3.0")
if not AceAddon then return end

local AceDB           = LibStub("AceDB-3.0")
local AceConfig       = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions    = LibStub("AceDBOptions-3.0")

local TR = AceAddon:NewAddon("TacoRot", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
_G.TacoRot = TR

-- ================= Defaults =================
local defaults = {
  profile = {
    unlock      = true,
    nextWindows = true,
    iconSize    = 52,
    nextScale   = 0.82,
    castFlash   = true,
    aoe         = false,
    anchor      = {"CENTER", UIParent, "CENTER", -200, 120},
    spells      = {},
    -- Config sections
    pad         = {},
    buff        = {},
    pet         = {},
  },
}

-- ================= Options (root) =================
local function RegisterOptions(self)
  local opts = {
    type = "group",
    name = "TacoRot",
    args = {
      unlock = {
        type="toggle", order=1, name="Unlock",
        get=function() return self.db.profile.unlock end,
        set=function(_,v) self.db.profile.unlock=v; self:UpdateLock() end,
      },
      next = {
        type="toggle", order=2, name="Show Next Windows",
        get=function() return self.db.profile.nextWindows end,
        set=function(_,v) self.db.profile.nextWindows=v; self:UpdateVisibility() end,
      },
      size = {
        type="range", order=3, name="Main Icon Size", min=24, max=96, step=1,
        get=function() return self.db.profile.iconSize end,
        set=function(_,v) self.db.profile.iconSize=v; if self.UI and self.UI.ApplySettings then self.UI:ApplySettings() end end,
      },
      nscale = {
        type="range", order=4, name="Next Icon Scale", min=0.5, max=1.2, step=0.01,
        get=function() return self.db.profile.nextScale end,
        set=function(_,v) self.db.profile.nextScale=v; if self.UI and self.UI.ApplySettings then self.UI:ApplySettings() end end,
      },
      castflash = {
        type="toggle", order=5, name="Flash while casting",
        get=function() return self.db.profile.castFlash end,
        set=function(_,v) self.db.profile.castFlash=v end,
      },
      aoe = {
        type="toggle", order=6, name="AoE Mode (ALT = momentary)",
        get=function() return self.db.profile.aoe end,
        set=function(_,v) self.db.profile.aoe=v end,
      },
      open = {
        type="execute", order=99, name="Open in Interface Options",
        func=function()
          -- Classic Anniversary compatible
          InterfaceOptionsFrame_OpenToCategory("TacoRot")
          InterfaceOptionsFrame_OpenToCategory("TacoRot")
        end,
      },
    },
  }
  AceConfig:RegisterOptionsTable("TacoRot", opts)
  self.OptionsRoot  = opts
  self.optionsFrame = AceConfigDialog:AddToBlizOptions("TacoRot", "TacoRot")

  local prof = AceDBOptions:GetOptionsTable(self.db)
  AceConfig:RegisterOptionsTable("TacoRot-Profiles", prof)
  AceConfigDialog:AddToBlizOptions("TacoRot-Profiles", "Profiles", "TacoRot")
end

-- ================= Lifecycle =================
function TR:OnInitialize()
  self.db = AceDB:New("TacoRotDB", defaults, true)
  RegisterOptions(self)
  self:RegisterChatCommand("tacorot", "Slash")
  self:RegisterChatCommand("tr", "Slash")
  
  -- Initialize spell cooldown tracking
  self.spellCooldowns = {}
  self.lastCastTime = 0
  self.isChanneling = false
  
  if self.UI and self.UI.Init then
    self.UI:Init()
    if self.UI.ApplySettings then self.UI:ApplySettings() end
  end
end

function TR:OnEnable()
  self:RegisterEvent("PLAYER_ENTERING_WORLD", "HandleWorldEnter")
  self:RegisterEvent("UNIT_SPELLCAST_START")
  self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
  self:RegisterEvent("UNIT_SPELLCAST_STOP")
  self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
  self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
  self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
  self:RegisterEvent("SPELL_UPDATE_COOLDOWN", "SpellCooldownUpdate")
  self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN", "ActionCooldownUpdate")
end

function TR:OnDisable()
  local engines = {"Warlock", "Rogue", "Hunter", "Druid", "Mage", "Paladin", "Priest", "Shaman", "Warrior"}
  for _, class in ipairs(engines) do
    local stopMethod = "StopEngine_" .. class
    if self[stopMethod] then 
      self[stopMethod](self) 
    end
  end
  -- Clear engine flags
  self._engineStates = {}
end

function TR:HandleWorldEnter()
  local _, class = UnitClass("player")
  if not class then return end
  
  self._engineStates = self._engineStates or {}
  
  local startMethod = "StartEngine_" .. class
  if self[startMethod] and not self._engineStates[class] then
    self[startMethod](self)
    self._engineStates[class] = true
  end
  
  if self.SendMessage then 
    self:SendMessage("TACOROT_ENABLE_CLASS_MODULE") 
  end
  
  self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

-- ================= Spell Tracking =================
function TR:SpellCooldownUpdate()
  -- Update internal cooldown tracking
  self:ScheduleTimer("UpdateRotationDisplay", 0.1)
end

function TR:ActionCooldownUpdate()
  -- Update internal cooldown tracking
  self:ScheduleTimer("UpdateRotationDisplay", 0.1)
end

function TR:UpdateRotationDisplay()
  -- Trigger current engine tick if available
  local _, class = UnitClass("player")
  if class then
    local tickMethod = "EngineTick_" .. class
    if self[tickMethod] then
      self[tickMethod](self)
    end
  end
end

-- ================= Cast Event Handlers =================
TR._lastMainSpell = TR._lastMainSpell or nil

local function _matchSpell(recID, evtName, evtID)
  if evtID and recID and evtID == recID then return true end
  local recName = recID and GetSpellInfo(recID)
  if not recName or not evtName then return false end
  return recName:lower() == tostring(evtName):lower()
end

-- Classic Anniversary event signatures are different from Wrath
function TR:UNIT_SPELLCAST_START(event, unit, spell)
  if unit ~= "player" then return end
  
  self.isChanneling = false
  self.lastCastTime = GetTime()
  
  local rec = self._lastMainSpell
  if rec and self.SetMainCastFlash and self.db.profile.castFlash then
    local spellName = GetSpellInfo(rec)
    if spellName and spell == spellName then
      self:SetMainCastFlash(true)
    end
  end
end

function TR:UNIT_SPELLCAST_CHANNEL_START(event, unit, spell)
  if unit ~= "player" then return end
  
  self.isChanneling = true
  self.lastCastTime = GetTime()
  
  local rec = self._lastMainSpell
  if rec and self.SetMainCastFlash and self.db.profile.castFlash then
    local spellName = GetSpellInfo(rec)
    if spellName and spell == spellName then
      self:SetMainCastFlash(true)
    end
  end
end

function TR:UNIT_SPELLCAST_SUCCEEDED(event, unit, spell)
  if unit ~= "player" then return end
  
  self.lastCastTime = GetTime()
  
  local rec = self._lastMainSpell
  if rec and self.SetMainCastFlash and self.db.profile.castFlash then
    local spellName = GetSpellInfo(rec)
    if spellName and spell == spellName then
      self:SetMainCastFlash(true)
      self:ScheduleTimer(function() 
        if self.SetMainCastFlash then 
          self:SetMainCastFlash(false) 
        end 
      end, 0.5)
    end
  end
  
  -- Trigger immediate rotation update after spell cast
  self:ScheduleTimer("UpdateRotationDisplay", 0.2)
end

function TR:UNIT_SPELLCAST_STOP(event, unit)
  if unit ~= "player" then return end
  
  self.isChanneling = false
  
  if self.SetMainCastFlash then 
    self:SetMainCastFlash(false) 
  end
  
  -- Update rotation after cast stops
  self:ScheduleTimer("UpdateRotationDisplay", 0.1)
end

function TR:UNIT_SPELLCAST_CHANNEL_STOP(event, unit)
  if unit ~= "player" then return end
  
  self.isChanneling = false
  
  if self.SetMainCastFlash then 
    self:SetMainCastFlash(false) 
  end
  
  self:ScheduleTimer("UpdateRotationDisplay", 0.1)
end

function TR:UNIT_SPELLCAST_INTERRUPTED(event, unit)
  if unit ~= "player" then return end
  
  self.isChanneling = false
  
  if self.SetMainCastFlash then 
    self:SetMainCastFlash(false) 
  end
  
  self:ScheduleTimer("UpdateRotationDisplay", 0.1)
end

-- ================= Helpers used by UI/options =================
function TR:UpdateLock()
  local unlocked = self.db.profile.unlock
  
  -- Handle both new UI structure and legacy frames
  if self.UI and self.UI.frames then
    for _, f in pairs(self.UI.frames) do 
      if f and f.EnableMouse then 
        f:EnableMouse(unlocked) 
      end 
    end
  end
  
  -- Legacy frame support
  local frames = {TacoRotWindow, TacoRotWindow2, TacoRotWindow3}
  for _, frame in ipairs(frames) do
    if frame and frame.EnableMouse then
      frame:EnableMouse(unlocked)
    end
  end
end

function TR:UpdateVisibility()
  local showNext = self.db.profile.nextWindows
  
  if self.UI and self.UI.f2 and self.UI.f3 then
    if showNext then 
      self.UI.f2:Show()
      self.UI.f3:Show() 
    else 
      self.UI.f2:Hide()
      self.UI.f3:Hide() 
    end
  end
  
  -- Legacy frame support
  if TacoRotWindow2 and TacoRotWindow3 then
    if showNext then 
      TacoRotWindow2:Show()
      TacoRotWindow3:Show() 
    else 
      TacoRotWindow2:Hide()
      TacoRotWindow3:Hide() 
    end
  end
end

function TR:Slash(input)
  input = (input or ""):lower()
  if input == "" then
    InterfaceOptionsFrame_OpenToCategory("TacoRot")
    InterfaceOptionsFrame_OpenToCategory("TacoRot")
    return
  end
  if input == "ul" or input == "unlock" then
    self.db.profile.unlock = not self.db.profile.unlock
    self:UpdateLock()
    self:Print("UI " .. (self.db.profile.unlock and "unlocked" or "locked"))
    return
  end
  if input == "aoe" then
    self.db.profile.aoe = not self.db.profile.aoe
    self:Print("AoE mode " .. (self.db.profile.aoe and "enabled" or "disabled"))
    return
  end
  if input == "config" then
    InterfaceOptionsFrame_OpenToCategory("TacoRot")
    InterfaceOptionsFrame_OpenToCategory("TacoRot")
    return
  end
  
  -- Help text
  self:Print("Commands: /tr config, /tr unlock, /tr aoe")
end