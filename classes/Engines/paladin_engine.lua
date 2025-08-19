--------------------------------------------------------------------
-- paladin_engine.lua — Enhanced Classic Anniversary Paladin Engine
--------------------------------------------------------------------

local TR = _G.TacoRot
if not TR then return end
local IDS = _G.TacoRot_IDS_Paladin

local TOKEN = "PALADIN"
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

local function HasSeal()
  -- Check if player has any seal active
  local sealSpells = {
    IDS.Ability.SealOfRighteousness,
    IDS.Ability.SealOfTheCrusader,
    IDS.Ability.SealOfCommand,
    IDS.Ability.SealOfWisdom,
    IDS.Ability.SealOfLight,
    IDS.Ability.SealOfJustice
  }
  
  for _, sealID in ipairs(sealSpells) do
    if BuffUp("player", sealID) then
      return true
    end
  end
  return false
end

local function HasAura()
  -- Check if player has any aura active
  local auraSpells = {
    IDS.Ability.DevotionAura,
    IDS.Ability.RetributionAura,
    IDS.Ability.ConcentrationAura,
    IDS.Ability.ShadowResistanceAura,
    IDS.Ability.FrostResistanceAura,
    IDS.Ability.FireResistanceAura,
    IDS.Ability.SanctityAura
  }
  
  for _, auraID in ipairs(auraSpells) do
    if BuffUp("player", auraID) then
      return true
    end
  end
  return false
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
  local holyPts = select(3, GetTalentTabInfo(1)) or 0
  local protectionPts = select(3, GetTalentTabInfo(2)) or 0
  local retributionPts = select(3, GetTalentTabInfo(3)) or 0
  
  if retributionPts >= holyPts and retributionPts >= protectionPts then
    return "Retribution"
  elseif protectionPts >= holyPts then
    return "Protection"
  else
    return "Holy"
  end
end

-- Build buff queue for out of combat
local function BuildBuffQueue()
  local q = {}
  local spec = GetPrimarySpec()
  
  -- Auras (always up)
  if not HasAura() then
    if spec == "Retribution" then
      if Known(IDS.Ability.SanctityAura) and ReadySoon(IDS.Ability.SanctityAura) then
        Push(q, IDS.Ability.SanctityAura)
      elseif Known(IDS.Ability.RetributionAura) and ReadySoon(IDS.Ability.RetributionAura) then
        Push(q, IDS.Ability.RetributionAura)
      elseif ReadySoon(IDS.Ability.DevotionAura) then
        Push(q, IDS.Ability.DevotionAura)
      end
    elseif spec == "Protection" then
      if ReadySoon(IDS.Ability.DevotionAura) then
        Push(q, IDS.Ability.DevotionAura)
      end
    else -- Holy
      if Known(IDS.Ability.ConcentrationAura) and ReadySoon(IDS.Ability.ConcentrationAura) then
        Push(q, IDS.Ability.ConcentrationAura)
      elseif ReadySoon(IDS.Ability.DevotionAura) then
        Push(q, IDS.Ability.DevotionAura)
      end
    end
  end
  
  -- Blessings (self-buff when solo)
  if GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 then
    local blessingBuff = nil
    if spec == "Retribution" then
      blessingBuff = IDS.Ability.BlessingOfMight
    elseif spec == "Protection" then
      blessingBuff = IDS.Ability.BlessingOfSanctuary
    else
      blessingBuff = IDS.Ability.BlessingOfWisdom
    end
    
    if blessingBuff and not BuffUp("player", blessingBuff) and ReadySoon(blessingBuff) then
      Push(q, blessingBuff)
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
      return pad3(buffQueue, IDS.Ability.AutoAttack)
    end
    return pad3(q, IDS.Ability.AutoAttack)
  end
  
  local manaPercent = ManaPercent()
  local inMelee = InMelee()
  
  -- Low mana - just auto attack
  if manaPercent < 10 then
    Push(q, IDS.Ability.AutoAttack)
    return pad3(q, IDS.Ability.AutoAttack)
  end
  
  -- Paladin rotation is very seal/judgement focused
  
  if spec == "Retribution" then
    -- Retribution rotation - maximize DPS
    
    -- Ensure we have a seal up
    if not HasSeal() then
      if Known(IDS.Ability.SealOfCommand) and ReadySoon(IDS.Ability.SealOfCommand) then
        Push(q, IDS.Ability.SealOfCommand)
      elseif ReadySoon(IDS.Ability.SealOfRighteousness) then
        Push(q, IDS.Ability.SealOfRighteousness)
      end
    end
    
    -- Judgement when we have a seal and are in range
    if HasSeal() and inMelee and ReadySoon(IDS.Ability.Judgement) then
      Push(q, IDS.Ability.Judgement)
    end
    
    -- Hammer of Wrath for ranged pulling or execute
    if Known(IDS.Ability.HammerOfWrath) and not inMelee then
      local targetHealthPercent = (UnitHealth("target") or 0) / (UnitHealthMax("target") or 1)
      if targetHealthPercent <= 0.2 and ReadySoon(IDS.Ability.HammerOfWrath) then
        Push(q, IDS.Ability.HammerOfWrath)
      end
    end
    
    -- Consecration for AoE or when mana is good
    if Known(IDS.Ability.Consecration) and inMelee and manaPercent > 60 then
      if ReadySoon(IDS.Ability.Consecration) then
        Push(q, IDS.Ability.Consecration)
      end
    end
    
    -- Auto attack in melee
    if inMelee then
      Push(q, IDS.Ability.AutoAttack)
    end
    
  elseif spec == "Protection" then
    -- Protection rotation - tanking focus
    
    -- Ensure we have Seal of Righteousness for threat
    if not HasSeal() then
      if ReadySoon(IDS.Ability.SealOfRighteousness) then
        Push(q, IDS.Ability.SealOfRighteousness)
      end
    end
    
    -- Judgement for threat
    if HasSeal() and inMelee and ReadySoon(IDS.Ability.Judgement) then
      Push(q, IDS.Ability.Judgement)
    end
    
    -- Consecration for AoE threat
    if Known(IDS.Ability.Consecration) and inMelee and manaPercent > 40 then
      if ReadySoon(IDS.Ability.Consecration) then
        Push(q, IDS.Ability.Consecration)
      end
    end
    
    -- Holy Wrath against undead/demons
    if Known(IDS.Ability.HolyWrath) and ReadySoon(IDS.Ability.HolyWrath) then
      local creatureType = UnitCreatureType("target")
      if creatureType == "Undead" or creatureType == "Demon" then
        Push(q, IDS.Ability.HolyWrath)
      end
    end
    
    -- Auto attack
    Push(q, IDS.Ability.AutoAttack)
    
  else
    -- Holy rotation - basic damage when not healing
    
    -- Ensure we have a seal up (Seal of Light for mana return)
    if not HasSeal() then
      if Known(IDS.Ability.SealOfLight) and ReadySoon(IDS.Ability.SealOfLight) then
        Push(q, IDS.Ability.SealOfLight)
      elseif ReadySoon(IDS.Ability.SealOfRighteousness) then
        Push(q, IDS.Ability.SealOfRighteousness)
      end
    end
    
    -- Judgement
    if HasSeal() and inMelee and ReadySoon(IDS.Ability.Judgement) then
      Push(q, IDS.Ability.Judgement)
    end
    
    -- Exorcism against undead/demons
    if Known(IDS.Ability.Exorcism) and ReadySoon(IDS.Ability.Exorcism) then
      local creatureType = UnitCreatureType("target")
      if creatureType == "Undead" or creatureType == "Demon" then
        Push(q, IDS.Ability.Exorcism)
      end
    end
    
    -- Auto attack
    Push(q, IDS.Ability.AutoAttack)
  end
  
  -- Apply Seal of the Crusader for increased attack speed on weak enemies
  if not HasSeal() and UnitLevel("target") < UnitLevel("player") then
    if Known(IDS.Ability.SealOfTheCrusader) and ReadySoon(IDS.Ability.SealOfTheCrusader) then
      Push(q, IDS.Ability.SealOfTheCrusader)
    end
  end
  
  -- Fallback
  if #q == 0 then
    if not HasSeal() and manaPercent > 30 then
      Push(q, IDS.Ability.SealOfRighteousness)
    else
      Push(q, IDS.Ability.AutoAttack)
    end
  end
  
  return pad3(q, IDS.Ability.AutoAttack)
end

function TR:EngineTick_Paladin()
  if IDS and IDS.UpdateRanks then IDS:UpdateRanks() end
  
  local q = {}
  
  -- Out of combat management
  if not UnitAffectingCombat("player") then
    q = BuildBuffQueue()
    if #q == 0 then
      if HaveTarget() then
        q = BuildQueue()
      else
        q = {IDS.Ability.DevotionAura, IDS.Ability.BlessingOfMight, IDS.Ability.AutoAttack}
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

function TR:StartEngine_Paladin()
  self:StopEngine_Paladin()
  self:EngineTick_Paladin()
  self._engineTimer_PA = self:ScheduleRepeatingTimer("EngineTick_Paladin", 0.2)
  self:Print("TacoRot Enhanced Paladin engine active (Classic Anniversary)")
end

function TR:StopEngine_Paladin()
  if self._engineTimer_PA then
    self:CancelTimer(self._engineTimer_PA)
    self._engineTimer_PA = nil
  end
end

local _, class = UnitClass("player")
if class == "PALADIN" then
  local f = CreateFrame("Frame")
  f:RegisterEvent("PLAYER_LOGIN")
  f:SetScript("OnEvent", function()
    if TR and TR.StartEngine_Paladin then
      TR:StartEngine_Paladin()
    end
  end)
end
