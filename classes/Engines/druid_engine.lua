--------------------------------------------------------------------
-- druid_engine.lua — Enhanced Classic Anniversary Druid Engine
--------------------------------------------------------------------

local TR = _G.TacoRot
if not TR then return end
local IDS = _G.TacoRot_IDS_Druid

local TOKEN = "DRUID"
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

local function Energy()
  -- Energy for cat form
  if UnitManaType("player") == 3 then  -- SPELL_POWER_ENERGY
    return UnitMana("player") or 0
  end
  return 0
end

local function Rage()
  -- Rage for bear form
  if UnitManaType("player") == 1 then  -- SPELL_POWER_RAGE
    return UnitMana("player") or 0
  end
  return 0
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

local function ComboPoints()
  return GetComboPoints("player", "target") or 0
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
  local balancePts = select(3, GetTalentTabInfo(1)) or 0
  local feralPts = select(3, GetTalentTabInfo(2)) or 0
  local restorationPts = select(3, GetTalentTabInfo(3)) or 0
  
  if balancePts >= feralPts and balancePts >= restorationPts then
    return "Balance"
  elseif feralPts >= restorationPts then
    return "Feral"
  else
    return "Restoration"
  end
end

-- Build buff queue for out of combat
local function BuildBuffQueue()
  local q = {}
  
  -- Mark of the Wild (always beneficial)
  if not BuffUp("player", IDS.Ability.Mark_of_the_Wild) and ReadySoon(IDS.Ability.Mark_of_the_Wild) then
    Push(q, IDS.Ability.Mark_of_the_Wild)
  end
  
  -- Thorns (beneficial for most situations)
  if Known(IDS.Ability.Thorns) and not BuffUp("player", IDS.Ability.Thorns) and ReadySoon(IDS.Ability.Thorns) then
    Push(q, IDS.Ability.Thorns)
  end
  
  return q
end

-- Caster form rotation (Balance/Restoration)
local function BuildCasterQueue()
  local q = {}
  local spec = GetPrimarySpec()
  local manaPercent = ManaPercent()
  
  if not HaveTarget() then
    return {}
  end
  
  -- Low mana fallback
  if manaPercent < 15 then
    Push(q, IDS.Ability.AutoAttack)
    return q
  end
  
  if spec == "Balance" then
    -- Balance rotation - DoT heavy
    
    -- Faerie Fire (armor reduction debuff)
    if Known(IDS.Ability.Faerie_Fire) and not DebuffUp("target", IDS.Ability.Faerie_Fire) then
      if ReadySoon(IDS.Ability.Faerie_Fire) then
        Push(q, IDS.Ability.Faerie_Fire)
      end
    end
    
    -- Moonfire DoT (highest priority)
    if Known(IDS.Ability.Moonfire) then
      if not DebuffUp("target", IDS.Ability.Moonfire) or DebuffTimeLeft("target", IDS.Ability.Moonfire) < 3 then
        if ReadySoon(IDS.Ability.Moonfire) then
          Push(q, IDS.Ability.Moonfire)
        end
      end
    end
    
    -- Insect Swarm DoT (if known)
    if Known(IDS.Ability.Insect_Swarm) then
      if not DebuffUp("target", IDS.Ability.Insect_Swarm) or DebuffTimeLeft("target", IDS.Ability.Insect_Swarm) < 3 then
        if ReadySoon(IDS.Ability.Insect_Swarm) then
          Push(q, IDS.Ability.Insect_Swarm)
        end
      end
    end
    
    -- Starfire (high damage nuke)
    if Known(IDS.Ability.Starfire) and ReadySoon(IDS.Ability.Starfire) then
      Push(q, IDS.Ability.Starfire)
    end
    
    -- Wrath (faster cast, filler)
    if ReadySoon(IDS.Ability.Wrath) then
      Push(q, IDS.Ability.Wrath)
    end
    
  else
    -- Restoration or basic rotation
    
    -- Moonfire for damage over time
    if Known(IDS.Ability.Moonfire) then
      if not DebuffUp("target", IDS.Ability.Moonfire) or DebuffTimeLeft("target", IDS.Ability.Moonfire) < 3 then
        if ReadySoon(IDS.Ability.Moonfire) then
          Push(q, IDS.Ability.Moonfire)
        end
      end
    end
    
    -- Wrath (main nuke)
    if ReadySoon(IDS.Ability.Wrath) then
      Push(q, IDS.Ability.Wrath)
    end
  end
  
  return q
end

-- Cat form rotation (Feral DPS)
local function BuildCatQueue()
  local q = {}
  local energy = Energy()
  local comboPoints = ComboPoints()
  
  if not HaveTarget() then
    return {}
  end
  
  -- Finishing moves at 4-5 combo points
  if comboPoints >= 4 then
    -- Rip for longer fights
    if Known(IDS.Ability.Rip) and not DebuffUp("target", IDS.Ability.Rip) then
      if energy >= 30 and ReadySoon(IDS.Ability.Rip) then
        Push(q, IDS.Ability.Rip)
        return q
      end
    elseif Known(IDS.Ability.Ferocious_Bite) and energy >= 35 and ReadySoon(IDS.Ability.Ferocious_Bite) then
      -- Ferocious Bite for burst
      Push(q, IDS.Ability.Ferocious_Bite)
      return q
    end
  end

  -- Faerie Fire (Feral) for armor reduction
  if Known(IDS.Ability.Faerie_Fire) and not DebuffUp("target", IDS.Ability.Faerie_Fire) then
    if energy >= 35 and ReadySoon(IDS.Ability.Faerie_Fire) then
      Push(q, IDS.Ability.Faerie_Fire)
      return q
    end
  end

  -- Tiger's Fury for energy regen
  if Known(IDS.Ability.Tigers_Fury) and energy < 30 and ReadySoon(IDS.Ability.Tigers_Fury) then
    Push(q, IDS.Ability.Tigers_Fury)
    return q
  end

  -- Low energy - just auto attack if nothing else to do
  if energy < 40 then
    Push(q, IDS.Ability.AutoAttack)
    return q
  end

  -- Rake DoT (combo point generator)
  if Known(IDS.Ability.Rake) then
    if not DebuffUp("target", IDS.Ability.Rake) or DebuffTimeLeft("target", IDS.Ability.Rake) < 3 then
      if energy >= 40 and ReadySoon(IDS.Ability.Rake) then
        Push(q, IDS.Ability.Rake)
      end
    end
  end

  -- Claw (main combo point generator)
  if energy >= 45 and ReadySoon(IDS.Ability.Claw) then
    Push(q, IDS.Ability.Claw)
  end

  -- Auto attack if nothing else
  if #q == 0 then
    Push(q, IDS.Ability.AutoAttack)
  end
  
  return q
end

-- Bear form rotation (Feral Tank)
local function BuildBearQueue()
  local q = {}
  local rage = Rage()
  
  if not HaveTarget() then
    return {}
  end
  
  -- Growl for threat if not tanking
  if Known(IDS.Ability.Growl) and not UnitIsTapDenied("target") then
    if ReadySoon(IDS.Ability.Growl) then
      Push(q, IDS.Ability.Growl)
    end
  end
  
  -- Faerie Fire (Feral) for threat and armor reduction
  if Known(IDS.Ability.Faerie_Fire) and not DebuffUp("target", IDS.Ability.Faerie_Fire) then
    if ReadySoon(IDS.Ability.Faerie_Fire) then
      Push(q, IDS.Ability.Faerie_Fire)
    end
  end
  
  -- Demoralizing Roar for damage reduction
  if Known(IDS.Ability.Demoralizing_Roar) and not DebuffUp("target", IDS.Ability.Demoralizing_Roar) then
    if rage >= 10 and ReadySoon(IDS.Ability.Demoralizing_Roar) then
      Push(q, IDS.Ability.Demoralizing_Roar)
    end
  end
  
  -- Maul (main threat/damage ability)
  if rage >= 15 and ReadySoon(IDS.Ability.Maul) then
    Push(q, IDS.Ability.Maul)
  end
  
  -- Swipe for AoE threat
  if Known(IDS.Ability.Swipe) and rage >= 20 then
    if TR and TR.db and TR.db.profile and TR.db.profile.aoe then
      if ReadySoon(IDS.Ability.Swipe) then
        Push(q, IDS.Ability.Swipe)
      end
    end
  end
  
  -- Auto attack if low rage
  if #q == 0 then
    Push(q, IDS.Ability.AutoAttack)
  end
  
  return q
end

-- Main queue builder
local function BuildQueue()
  local q = {}
  local spec = GetPrimarySpec()
  
  if not HaveTarget() then 
    local buffQueue = BuildBuffQueue()
    if #buffQueue > 0 then
      return pad3(buffQueue, IDS.Ability.AutoAttack)
    end
    return pad3(q, IDS.Ability.AutoAttack)
  end
  
  -- Check current form and build appropriate rotation
  if IDS:IsInCatForm() then
    q = BuildCatQueue()
  elseif IDS:IsInBearForm() then
    q = BuildBearQueue()
  else
    -- Caster form
    q = BuildCasterQueue()
  end
  
  -- Form recommendations for feral druids
  if spec == "Feral" and IDS:IsInCasterForm() and UnitAffectingCombat("player") then
    if InMelee() then
      -- Suggest bear form for tanking or cat form for DPS
      if UnitThreatSituation("player", "target") == 3 or UnitIsTapDenied("target") then
        -- We have threat or target is tapped, go bear
        if Known(IDS.Ability.Bear_Form) and ReadySoon(IDS.Ability.Bear_Form) then
          q = {IDS.Ability.Bear_Form, IDS.Ability.Bear_Form, IDS.Ability.Bear_Form}
        elseif Known(IDS.Ability.Dire_Bear_Form) and ReadySoon(IDS.Ability.Dire_Bear_Form) then
          q = {IDS.Ability.Dire_Bear_Form, IDS.Ability.Dire_Bear_Form, IDS.Ability.Dire_Bear_Form}
        end
      else
        -- Go cat form for DPS
        if Known(IDS.Ability.Cat_Form) and ReadySoon(IDS.Ability.Cat_Form) then
          q = {IDS.Ability.Cat_Form, IDS.Ability.Cat_Form, IDS.Ability.Cat_Form}
        end
      end
    end
  end
  
  -- Fallback
  if #q == 0 then
    if ManaPercent() > 20 and ReadySoon(IDS.Ability.Wrath) then
      Push(q, IDS.Ability.Wrath)
    else
      Push(q, IDS.Ability.AutoAttack)
    end
  end
  
  return pad3(q, IDS.Ability.AutoAttack)
end

function TR:EngineTick_Druid()
  if IDS and IDS.UpdateRanks then IDS:UpdateRanks() end
  
  local q = {}
  
  -- Out of combat management
  if not UnitAffectingCombat("player") then
    q = BuildBuffQueue()
    if #q == 0 then
      if HaveTarget() then
        q = BuildQueue()
      else
        q = {IDS.Ability.Mark_of_the_Wild, IDS.Ability.Thorns, IDS.Ability.AutoAttack}
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

function TR:StartEngine_Druid()
  self:StopEngine_Druid()
  self:EngineTick_Druid()
  self._engineTimer_DR = self:ScheduleRepeatingTimer("EngineTick_Druid", 0.2)
  self:Print("TacoRot Enhanced Druid engine active (Classic Anniversary)")
end

function TR:StopEngine_Druid()
  if self._engineTimer_DR then
    self:CancelTimer(self._engineTimer_DR)
    self._engineTimer_DR = nil
  end
end

local _, class = UnitClass("player")
if class == "DRUID" then
  local f = CreateFrame("Frame")
  f:RegisterEvent("PLAYER_LOGIN")
  f:SetScript("OnEvent", function()
    if TR and TR.StartEngine_Druid then
      TR:StartEngine_Druid()
    end
  end)
end
