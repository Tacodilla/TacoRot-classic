--------------------------------------------------------------------
-- warlock_engine.lua — Enhanced Classic Anniversary Warlock Engine
--------------------------------------------------------------------

local TR = _G.TacoRot
if not TR then return end
local IDS = _G.TacoRot_IDS_Warlock

local TOKEN = "WARLOCK"
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

local function Health()
  return UnitHealth("player") or 0
end

local function MaxHealth()
  return UnitHealthMax("player") or 0
end

local function HealthPercent()
  local max = MaxHealth()
  if max == 0 then return 0 end
  return (Health() / max) * 100
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

local function HavePet()
  return UnitExists("pet") and not UnitIsDead("pet")
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
  local afflictionPts = select(3, GetTalentTabInfo(1)) or 0
  local demonologyPts = select(3, GetTalentTabInfo(2)) or 0
  local destructionPts = select(3, GetTalentTabInfo(3)) or 0
  
  if afflictionPts >= demonologyPts and afflictionPts >= destructionPts then
    return "Affliction"
  elseif destructionPts >= demonologyPts then
    return "Destruction"
  else
    return "Demonology"
  end
end

-- Build buff queue for out of combat
local function BuildBuffQueue()
  local q = {}
  
  -- Demon Armor/Fel Armor
  local armorBuff = IDS.Ability.FelArmor
  if not Known(armorBuff) then
    armorBuff = IDS.Ability.DemonArmor
  end
  
  if not BuffUp("player", armorBuff) and ReadySoon(armorBuff) then
    Push(q, armorBuff)
  end
  
  return q
end

-- Pet management
local function BuildPetQueue()
  local q = {}
  
  if not HavePet() then
    -- Summon pet based on spec/situation
    local spec = GetPrimarySpec()
    
    if spec == "Affliction" then
      -- Felhunter for pvp/dispel utility, or imp for leveling
      if Known(IDS.Ability.SummonFelhunter) and UnitLevel("player") >= 30 then
        Push(q, IDS.Ability.SummonFelhunter)
      else
        Push(q, IDS.Ability.SummonImp)
      end
    elseif spec == "Destruction" then
      -- Imp for damage boost
      Push(q, IDS.Ability.SummonImp)
    else -- Demonology
      -- Succubus for damage, Voidwalker for tanking
      if UnitLevel("player") >= 20 then
        Push(q, IDS.Ability.SummonSuccubus)
      else
        Push(q, IDS.Ability.SummonVoidwalker)
      end
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
    
    local petQueue = BuildPetQueue()
    if #petQueue > 0 then
      return pad3(petQueue, IDS.Ability.Wand or IDS.Ability.AutoAttack)
    end
    
    return pad3(q, IDS.Ability.Wand or IDS.Ability.AutoAttack)
  end
  
  local manaPercent = ManaPercent()
  local healthPercent = HealthPercent()
  
  -- Life Tap if low mana but good health
  if manaPercent < 20 and healthPercent > 60 and ReadySoon(IDS.Ability.LifeTap) then
    Push(q, IDS.Ability.LifeTap)
    return pad3(q, IDS.Ability.AutoAttack)
  end
  
  -- Low mana fallback
  if manaPercent < 10 then
    if IDS.Ability.Wand and not InMelee() then
      Push(q, IDS.Ability.Wand)
      return pad3(q, IDS.Ability.AutoAttack)
    else
      Push(q, IDS.Ability.AutoAttack)
      return pad3(q, IDS.Ability.AutoAttack)
    end
  end
  
  if spec == "Affliction" then
    -- Affliction rotation - DoT heavy
    
    -- Corruption (highest priority DoT)
    if Known(IDS.Ability.Corruption) then
      if not DebuffUp("target", IDS.Ability.Corruption) or DebuffTimeLeft("target", IDS.Ability.Corruption) < 3 then
        if ReadySoon(IDS.Ability.Corruption) then
          Push(q, IDS.Ability.Corruption)
        end
      end
    end
    
    -- Curse of Agony (efficient DoT)
    if Known(IDS.Ability.CurseOfAgony) then
      if not DebuffUp("target", IDS.Ability.CurseOfAgony) or DebuffTimeLeft("target", IDS.Ability.CurseOfAgony) < 3 then
        if ReadySoon(IDS.Ability.CurseOfAgony) then
          Push(q, IDS.Ability.CurseOfAgony)
        end
      end
    end
    
    -- Unstable Affliction (if known)
    if Known(IDS.Ability.UnstableAffliction) then
      if not DebuffUp("target", IDS.Ability.UnstableAffliction) or DebuffTimeLeft("target", IDS.Ability.UnstableAffliction) < 3 then
        if ReadySoon(IDS.Ability.UnstableAffliction) then
          Push(q, IDS.Ability.UnstableAffliction)
        end
      end
    end
    
    -- Immolate (fire DoT)
    if Known(IDS.Ability.Immolate) then
      if not DebuffUp("target", IDS.Ability.Immolate) or DebuffTimeLeft("target", IDS.Ability.Immolate) < 3 then
        if ReadySoon(IDS.Ability.Immolate) then
          Push(q, IDS.Ability.Immolate)
        end
      end
    end
    
    -- Drain Soul for execute phase
    if Known(IDS.Ability.DrainSoul) then
      local targetHealthPercent = (UnitHealth("target") or 0) / (UnitHealthMax("target") or 1)
      if targetHealthPercent <= 0.25 and ReadySoon(IDS.Ability.DrainSoul) then
        Push(q, IDS.Ability.DrainSoul)
      end
    end
    
    -- Shadow Bolt filler
    if ReadySoon(IDS.Ability.ShadowBolt) then
      Push(q, IDS.Ability.ShadowBolt)
    end
    
  elseif spec == "Destruction" then
    -- Destruction rotation - direct damage focus
    
    -- Immolate for improved fire damage
    if Known(IDS.Ability.Immolate) then
      if not DebuffUp("target", IDS.Ability.Immolate) or DebuffTimeLeft("target", IDS.Ability.Immolate) < 3 then
        if ReadySoon(IDS.Ability.Immolate) then
          Push(q, IDS.Ability.Immolate)
        end
      end
    end
    
    -- Conflagrate (requires immolate)
    if Known(IDS.Ability.Conflagrate) and DebuffUp("target", IDS.Ability.Immolate) then
      if ReadySoon(IDS.Ability.Conflagrate) then
        Push(q, IDS.Ability.Conflagrate)
      end
    end
    
    -- Incinerate (if known, better than Shadow Bolt for destruction)
    if Known(IDS.Ability.Incinerate) and ReadySoon(IDS.Ability.Incinerate) then
      Push(q, IDS.Ability.Incinerate)
    end
    
    -- Shadow Bolt (main nuke)
    if ReadySoon(IDS.Ability.ShadowBolt) then
      Push(q, IDS.Ability.ShadowBolt)
    end
    
  else
    -- Demonology rotation - balanced approach
    
    -- Corruption (efficient DoT)
    if Known(IDS.Ability.Corruption) then
      if not DebuffUp("target", IDS.Ability.Corruption) or DebuffTimeLeft("target", IDS.Ability.Corruption) < 3 then
        if ReadySoon(IDS.Ability.Corruption) then
          Push(q, IDS.Ability.Corruption)
        end
      end
    end
    
    -- Immolate
    if Known(IDS.Ability.Immolate) then
      if not DebuffUp("target", IDS.Ability.Immolate) or DebuffTimeLeft("target", IDS.Ability.Immolate) < 3 then
        if ReadySoon(IDS.Ability.Immolate) then
          Push(q, IDS.Ability.Immolate)
        end
      end
    end
    
    -- Shadow Bolt spam
    if ReadySoon(IDS.Ability.ShadowBolt) then
      Push(q, IDS.Ability.ShadowBolt)
    end
  end
  
  -- Universal curse (Curse of Elements for caster groups)
  if Known(IDS.Ability.CurseOfElements) and not DebuffUp("target", IDS.Ability.CurseOfElements) then
    -- Only apply if we don't have Curse of Agony up (don't overwrite)
    if not DebuffUp("target", IDS.Ability.CurseOfAgony) and ReadySoon(IDS.Ability.CurseOfElements) then
      Push(q, IDS.Ability.CurseOfElements)
    end
  end
  
  -- Fallback based on range and mana
  if #q == 0 then
    if manaPercent > 15 and ReadySoon(IDS.Ability.ShadowBolt) then
      Push(q, IDS.Ability.ShadowBolt)
    elseif IDS.Ability.Wand and not InMelee() then
      Push(q, IDS.Ability.Wand)  
    else
      Push(q, IDS.Ability.AutoAttack)
    end
  end
  
  return pad3(q, IDS.Ability.AutoAttack)
end

function TR:EngineTick_Warlock()
  if IDS and IDS.UpdateRanks then IDS:UpdateRanks() end
  
  local q = {}
  
  -- Out of combat management
  if not UnitAffectingCombat("player") then
    q = BuildBuffQueue()
    if #q == 0 then
      local petQueue = BuildPetQueue()
      if #petQueue > 0 then
        q = petQueue
      end
    end
    if #q == 0 then
      if HaveTarget() then
        q = BuildQueue()
      else
        q = {IDS.Ability.DemonArmor, IDS.Ability.SummonImp, IDS.Ability.Wand or IDS.Ability.AutoAttack}
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

function TR:StartEngine_Warlock()
  self:StopEngine_Warlock()
  self:EngineTick_Warlock()
  self._engineTimer_WL = self:ScheduleRepeatingTimer("EngineTick_Warlock", 0.2)
  self:Print("TacoRot Enhanced Warlock engine active (Classic Anniversary)")
end

function TR:StopEngine_Warlock()
  if self._engineTimer_WL then
    self:CancelTimer(self._engineTimer_WL)
    self._engineTimer_WL = nil
  end
end

local _, class = UnitClass("player")
if class == "WARLOCK" then
  local f = CreateFrame("Frame")
  f:RegisterEvent("PLAYER_LOGIN")
  f:SetScript("OnEvent", function()
    if TR and TR.StartEngine_Warlock then
      TR:StartEngine_Warlock()
    end
  end)
end
