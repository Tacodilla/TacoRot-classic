-- rogue_engine.lua — Classic Anniversary Rogue Engine
DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[TacoRot]|r Rogue engine loaded")

local TR = _G.TacoRot
local IDS = _G.TacoRot_IDS_Rogue

-- Helper functions
local function GetComboPoints()
  return GetComboPoints("player", "target") or 0
end

local function Energy()
  return UnitMana("player") or 0
end

local function IsStealthed()
  return BuffUp("player", IDS.Ability.Stealth) or BuffUp("player", IDS.Ability.Vanish)
end

local function BuffUp(unit, spellID)
  if not spellID then return false end
  local name = GetSpellInfo(spellID)
  if not name then return false end
  for i = 1, 40 do
    local buffName = UnitBuff(unit, i)
    if not buffName then break end
    if buffName == name then return true end
  end
  return false
end

local function DebuffUp(unit, spellID)
  if not spellID then return false end
  local name = GetSpellInfo(spellID)
  if not name then return false end
  for i = 1, 40 do
    local debuffName = UnitDebuff(unit, i)
    if not debuffName then break end
    if debuffName == name then return true end
  end
  return false
end

local function ReadyNow(id)
  if not id then return false end
  local start, dur = GetSpellCooldown(id)
  return start == 0 or (start + dur - GetTime()) < 0.1
end

local function ReadySoon(id)
  if not id then return false end
  local start, dur = GetSpellCooldown(id)
  return start == 0 or (start + dur - GetTime()) < 1.5
end

local function HaveTarget()
  return UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target")
end

local function InMelee()
  return CheckInteractDistance("target", 3)
end

local function TargetHealth()
  local hp = UnitHealth("target")
  local max = UnitHealthMax("target")
  return max > 0 and (hp / max) or 1
end

local function pad3(q, fb)
  q[1] = q[1] or fb or IDS.Ability.AutoAttack
  q[2] = q[2] or q[1]
  q[3] = q[3] or q[2]
  return q
end

local function Push(q, id)
  if id and #q < 3 then q[#q + 1] = id end
end

-- Talent detection
local function PrimaryTab()
  local best, pts = 1, -1
  for i = 1, 3 do
    local _, _, points = GetTalentTabInfo(i)
    if points and points > pts then
      best, pts = i, points
    end
  end
  return best
end

-- DPS Rotation
local function BuildQueue()
  local q = {}
  local tree = PrimaryTab() -- 1=Assassination, 2=Combat, 3=Subtlety
  local cp = GetComboPoints()
  local energy = Energy()
  
  if not HaveTarget() then
    return pad3({}, IDS.Ability.AutoAttack)
  end
  
  -- Stealth Opener
  if IsStealthed() and InMelee() then
    if tree == 1 or tree == 3 then
      -- Assassination/Sub: Cheap Shot or Garrote
      if energy >= 60 and ReadyNow(IDS.Ability.CheapShot) then
        Push(q, IDS.Ability.CheapShot)
        return pad3(q)
      end
      if energy >= 50 and ReadyNow(IDS.Ability.Garrote) then
        Push(q, IDS.Ability.Garrote)
        return pad3(q)
      end
    else
      -- Combat: Ambush for big damage
      if energy >= 60 and ReadyNow(IDS.Ability.Ambush) then
        Push(q, IDS.Ability.Ambush)
        return pad3(q)
      end
    end
  end
  
  -- Enter Stealth if out of combat
  if not UnitAffectingCombat("player") and not IsStealthed() then
    if ReadyNow(IDS.Ability.Stealth) then
      Push(q, IDS.Ability.Stealth)
      return pad3(q)
    end
  end
  
  -- FINISHERS (5 combo points or 4+ for Slice and Dice)
  if cp >= 4 then
    -- Maintain Slice and Dice
    if not BuffUp("player", IDS.Ability.SliceAndDice) and energy >= 25 then
      Push(q, IDS.Ability.SliceAndDice)
    end
    
    -- Rupture for long fights
    if cp == 5 and not DebuffUp("target", IDS.Ability.Rupture) and energy >= 25 then
      Push(q, IDS.Ability.Rupture)
    end
    
    -- Eviscerate for damage
    if cp == 5 and energy >= 35 then
      Push(q, IDS.Ability.Eviscerate)
    end
  end
  
  -- BUILDERS
  if tree == 1 then
    -- ASSASSINATION
    -- Mutilate if available
    if energy >= 60 and ReadySoon(IDS.Ability.Mutilate) then
      Push(q, IDS.Ability.Mutilate)
    end
    -- Backstab from behind
    if energy >= 60 and ReadySoon(IDS.Ability.Backstab) then
      Push(q, IDS.Ability.Backstab)
    end
    -- Sinister Strike as fallback
    if energy >= 45 and ReadySoon(IDS.Ability.SinisterStrike) then
      Push(q, IDS.Ability.SinisterStrike)
    end
    
  elseif tree == 2 then
    -- COMBAT
    -- Blade Flurry for AoE
    if TR and TR.db and TR.db.profile and TR.db.profile.aoe then
      if energy >= 25 and ReadySoon(IDS.Ability.BladeFlurry) then
        Push(q, IDS.Ability.BladeFlurry)
      end
    end
    -- Sinister Strike spam
    if energy >= 45 and ReadySoon(IDS.Ability.SinisterStrike) then
      Push(q, IDS.Ability.SinisterStrike)
    end
    -- Riposte after dodge
    if energy >= 10 and ReadySoon(IDS.Ability.Riposte) then
      Push(q, IDS.Ability.Riposte)
    end
    
  else
    -- SUBTLETY
    -- Hemorrhage
    if energy >= 35 and ReadySoon(IDS.Ability.Hemorrhage) then
      Push(q, IDS.Ability.Hemorrhage)
    end
    -- Backstab
    if energy >= 60 and ReadySoon(IDS.Ability.Backstab) then
      Push(q, IDS.Ability.Backstab)
    end
    -- Ghostly Strike
    if energy >= 40 and ReadySoon(IDS.Ability.Ghostly) then
      Push(q, IDS.Ability.Ghostly)
    end
  end
  
  -- Kick interrupts
  if energy >= 25 and ReadySoon(IDS.Ability.Kick) then
    Push(q, IDS.Ability.Kick)
  end
  
  return q
end

-- Engine tick
function TR:EngineTick_Rogue()
  IDS:UpdateRanks()
  
  local q = BuildQueue()
  q = pad3(q, IDS.Ability.AutoAttack)
  self._lastMainSpell = q[1]
  
  if self.UI and self.UI.Update then
    self.UI:Update(q[1], q[2], q[3])
  end
end

function TR:StartEngine_Rogue()
  self:StopEngine_Rogue()
  self:EngineTick_Rogue()
  self._engineTimer_RO = self:ScheduleRepeatingTimer("EngineTick_Rogue", 0.2)
  self:Print("TacoRot Rogue engine active (Classic Anniversary)")
end

function TR:StopEngine_Rogue()
  if self._engineTimer_RO then
    self:CancelTimer(self._engineTimer_RO)
    self._engineTimer_RO = nil
  end
end
