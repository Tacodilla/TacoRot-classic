--------------------------------------------------------------------
-- priest_engine.lua — Enhanced Classic Anniversary Priest Engine
--------------------------------------------------------------------

local TR = _G.TacoRot
if not TR then return end
local IDS = _G.TacoRot_IDS_Priest

local TOKEN = "PRIEST"
local function Pad()
  local p = TR and TR.db and TR.db.profile and TR.db.profile.pad
  local v = p and p[TOKEN]
  if not v then return {enabled=true, gcd=1.5} end
  if v.enabled == nil then v.enabled = true end
  v.gcd = v.gcd or 1.5
  return v
end

-- Utility functions
local function Known(id) return id and IsSpellKnown and IsSpellKnown(id) end
local function ReadyNow(id)
  if not Known(id) then return false end
  local start, duration = GetSpellCooldown(id)
  if not start or duration == 0 then return true end
  return (GetTime() - start) >= duration
end

local function ReadySoon(id)
  local pad = Pad()
  if not pad.enabled then return ReadyNow(id) end
  if not Known(id) then return false end
  local start, duration = GetSpellCooldown(id)
  if not start or duration == 0 then return true end
  local remaining = (start + duration) - GetTime()
  return remaining <= (pad.gcd or 1.5)
end

local function HaveTarget()
  return UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target")
end

local function InMelee()
  return CheckInteractDistance("target", 3)
end

local function Mana()
  return UnitMana("player") or 0
end

local function MaxMana()
  return UnitManaMax("player") or 0
end

local function ManaPercent()
  local max = MaxMana()
  if max == 0 then return 0 end
  return (Mana() / max) * 100
end

local function BuffUp(unit, spellID)
  if not spellID then return false end
  local spellName = GetSpellInfo(spellID)
  if not spellName then return false end
  
  for i = 1, 32 do
    local buffName = UnitBuff(unit, i)
    if not buffName then break end
    if buffName == spellName then return true end
  end
  return false
end

local function DebuffUp(unit, spellID)
  if not spellID then return false end
  local spellName = GetSpellInfo(spellID)
  if not spellName then return false end
  
  for i = 1, 16 do
    local debuffName = UnitDebuff(unit, i)
    if not debuffName then break end
    if debuffName == spellName then return true end
  end
  return false
end

local function DebuffTimeLeft(unit, spellID)
  if not spellID then return 0 end
  local spellName = GetSpellInfo(spellID)
  if not spellName then return 0 end
  
  for i = 1, 16 do
    local name, _, _, _, _, duration, expires = UnitDebuff(unit, i)
    if not name then break end
    if name == spellName then
      if expires and duration then
        return expires - GetTime()
      end
    end
  end
  return 0
end

local function pad3(q, fb) 
  q[1] = q[1] or fb
  q[2] = q[2] or q[1]
  q[3] = q[3] or q[2]
  return q 
end

local function Push(q, id) 
  if id then q[#q+1] = id end 
end

-- Detect primary spec
local function GetPrimarySpec()
  local shadowPts = select(3, GetTalentTabInfo(3)) or 0
  local disciplinePts = select(3, GetTalentTabInfo(1)) or 0
  local holyPts = select(3, GetTalentTabInfo(2)) or 0
  
  if shadowPts >= disciplinePts and shadowPts >= holyPts then
    return "Shadow"
  elseif disciplinePts >= holyPts then
    return "Discipline"
  else
    return "Holy"
  end
end

-- Build buff queue for out of combat
local function BuildBuffQueue()
  local q = {}
  
  -- Power Word: Fortitude
  if not BuffUp("player", IDS.Ability.PowerWordFortitude) and ReadySoon(IDS.Ability.PowerWordFortitude) then
    Push(q, IDS.Ability.PowerWordFortitude)
  end
  
  -- Divine Spirit (if known)
  if Known(IDS.Ability.DivineSpirit) and not BuffUp("player", IDS.Ability.DivineSpirit) and ReadySoon(IDS.Ability.DivineSpirit) then
    Push(q, IDS.Ability.DivineSpirit)
  end
  
  -- Inner Fire
  if not BuffUp("player", IDS.Ability.InnerFire) and ReadySoon(IDS.Ability.InnerFire) then
    Push(q, IDS.Ability.InnerFire)
  end
  
  -- Shadow Form (for shadow priests)
  if GetPrimarySpec() == "Shadow" and Known(IDS.Ability.ShadowForm) then
    if not BuffUp("player", IDS.Ability.ShadowForm) and ReadySoon(IDS.Ability.ShadowForm) then
      Push(q, IDS.Ability.ShadowForm)
    end
  end
  
  return q
end

-- Main DPS rotation
local function BuildQueue()
  local q = {}
  local spec = GetPrimarySpec()
  
  if not HaveTarget() then 
    local buffQueue = BuildBuffQueue()
    if #buffQueue > 0 then
      return pad3(buffQueue, IDS.Ability.Wand or IDS.Ability.AutoAttack)
    end
    return pad3(q, IDS.Ability.Wand or IDS.Ability.AutoAttack)
  end
  
  local manaPercent = ManaPercent()
  
  -- Low mana fallback (use wand if not in melee range)
  if manaPercent < 10 then
    if IDS.Ability.Wand and not InMelee() then
      Push(q, IDS.Ability.Wand)
      return pad3(q, IDS.Ability.AutoAttack)
    else
      Push(q, IDS.Ability.AutoAttack)
      return pad3(q, IDS.Ability.AutoAttack)
    end
  end
  
  if spec == "Shadow" then
    -- Shadow Priest rotation
    
    -- Shadow Word: Pain (if not up or expiring soon)
    if Known(IDS.Ability.ShadowWordPain) then
      if not DebuffUp("target", IDS.Ability.ShadowWordPain) or DebuffTimeLeft("target", IDS.Ability.ShadowWordPain) < 3 then
        if ReadySoon(IDS.Ability.ShadowWordPain) then
          Push(q, IDS.Ability.ShadowWordPain)
        end
      end
    end
    
    -- Vampiric Touch (if known and not up)
    if Known(IDS.Ability.VampiricTouch) and not DebuffUp("target", IDS.Ability.VampiricTouch) then
      if ReadySoon(IDS.Ability.VampiricTouch) then
        Push(q, IDS.Ability.VampiricTouch)
      end
    end
    
    -- Devouring Plague (Undead racial, if known and not up)
    if Known(IDS.Ability.Devouring_Plague) and not DebuffUp("target", IDS.Ability.Devouring_Plague) then
      if ReadySoon(IDS.Ability.Devouring_Plague) then
        Push(q, IDS.Ability.Devouring_Plague)
      end
    end
    
    -- Mind Blast (main nuke when not channeling)
    if Known(IDS.Ability.MindBlast) and ReadySoon(IDS.Ability.MindBlast) then
      Push(q, IDS.Ability.MindBlast)
    end
    
    -- Mind Flay (channel filler)
    if Known(IDS.Ability.MindFlay) and ReadySoon(IDS.Ability.MindFlay) then
      Push(q, IDS.Ability.MindFlay)
    end
    
    -- Shadow Word: Death (if known and target is low)
    if Known(IDS.Ability.ShadowWordDeath) then
      local targetHealthPercent = (UnitHealth("target") or 0) / (UnitHealthMax("target") or 1)
      if targetHealthPercent <= 0.35 and ReadySoon(IDS.Ability.ShadowWordDeath) then
        Push(q, IDS.Ability.ShadowWordDeath)
      end
    end
    
  else
    -- Holy/Discipline rotation
    
    -- Holy Fire (best opener and when off cooldown)
    if Known(IDS.Ability.HolyFire) and ReadySoon(IDS.Ability.HolyFire) then
      Push(q, IDS.Ability.HolyFire)
    end
    
    -- Shadow Word: Pain (efficient DoT)
    if Known(IDS.Ability.ShadowWordPain) then
      if not DebuffUp("target", IDS.Ability.ShadowWordPain) or DebuffTimeLeft("target", IDS.Ability.ShadowWordPain) < 3 then
        if ReadySoon(IDS.Ability.ShadowWordPain) then
          Push(q, IDS.Ability.ShadowWordPain)
        end
      end
    end
    
    -- Mind Blast when available  
    if Known(IDS.Ability.MindBlast) and ReadySoon(IDS.Ability.MindBlast) then
      Push(q, IDS.Ability.MindBlast)
    end
    
    -- Smite spam
    if ReadySoon(IDS.Ability.Smite) then
      Push(q, IDS.Ability.Smite)
    end
  end
  
  -- Fallback based on range and mana
  if #q == 0 then
    if manaPercent > 20 and ReadySoon(IDS.Ability.Smite) then
      Push(q, IDS.Ability.Smite)
    elseif IDS.Ability.Wand and not InMelee() then
      Push(q, IDS.Ability.Wand)  
    else
      Push(q, IDS.Ability.AutoAttack)
    end
  end
  
  return pad3(q, IDS.Ability.AutoAttack)
end

function TR:EngineTick_Priest()
  if IDS and IDS.UpdateRanks then IDS:UpdateRanks() end
  
  local q = {}
  
  -- Out of combat buff management
  if not UnitAffectingCombat("player") then
    q = BuildBuffQueue()
    if #q == 0 then
      if HaveTarget() then
        q = BuildQueue()
      else
        q = {IDS.Ability.PowerWordFortitude, IDS.Ability.InnerFire, IDS.Ability.Wand or IDS.Ability.AutoAttack}
      end
    end
  else
    q = BuildQueue()
  end
  
  q = pad3(q, IDS.Ability.AutoAttack)
  self._lastMainSpell = q[1]
  
  if self.UI and self.UI.Update then 
    self.UI:Update(q[1], q[2], q[3]) 
  end
end

function TR:StartEngine_Priest()
  self:StopEngine_Priest()
  self:EngineTick_Priest()
  self._engineTimer_PR = self:ScheduleRepeatingTimer("EngineTick_Priest", 0.2)
  self:Print("TacoRot Enhanced Priest engine active (Classic Anniversary)")
end

function TR:StopEngine_Priest()
  if self._engineTimer_PR then
    self:CancelTimer(self._engineTimer_PR)
    self._engineTimer_PR = nil
  end
end

local _, class = UnitClass("player")
if class == "PRIEST" then
  local f = CreateFrame("Frame")
  f:RegisterEvent("PLAYER_LOGIN")
  f:SetScript("OnEvent", function()
    if TR and TR.StartEngine_Priest then
      TR:StartEngine_Priest()
    end
  end)
end
