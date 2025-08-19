-- mage_engine.lua — Classic Anniversary Mage Engine
DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[TacoRot]|r Mage engine loaded")

local TR = _G.TacoRot
local IDS = _G.TacoRot_IDS_Mage

-- Helper functions
local function Mana()
  local mana = UnitMana("player")
  local maxMana = UnitManaMax("player")
  return maxMana > 0 and (mana / maxMana) or 0
end

local function BuffCfg()
  return (TR.db and TR.db.profile and TR.db.profile.buff and TR.db.profile.buff.MAGE) or {}
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

local function InRange()
  return IsSpellInRange(GetSpellInfo(IDS.Ability.Frostbolt), "target") == 1
end

local function pad3(q, fb)
  q[1] = q[1] or fb or IDS.Ability.Wand
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

-- OOC Buffs
local function BuildBuffQueue()
  local cfg = BuffCfg()
  if not cfg.enabled then return {} end
  
  local q = {}
  
  -- Arcane Intellect
  if cfg.intellect ~= false then
    if not BuffUp("player", IDS.Ability.ArcaneIntellect) and not BuffUp("player", IDS.Ability.ArcaneBrilliance) then
      if ReadySoon(IDS.Ability.ArcaneIntellect) then
        Push(q, IDS.Ability.ArcaneIntellect)
      end
    end
  end
  
  -- Armor (Mage Armor > Ice Armor > Frost Armor)
  if cfg.armor ~= false then
    if not BuffUp("player", IDS.Ability.MageArmor) and not BuffUp("player", IDS.Ability.IceArmor) 
       and not BuffUp("player", IDS.Ability.FrostArmor) then
      if IsSpellKnown(IDS.Ability.MageArmor) and ReadySoon(IDS.Ability.MageArmor) then
        Push(q, IDS.Ability.MageArmor)
      elseif IsSpellKnown(IDS.Ability.IceArmor) and ReadySoon(IDS.Ability.IceArmor) then
        Push(q, IDS.Ability.IceArmor)
      elseif ReadySoon(IDS.Ability.FrostArmor) then
        Push(q, IDS.Ability.FrostArmor)
      end
    end
  end
  
  return q
end

-- DPS Rotation
local function BuildQueue()
  local q = {}
  local tree = PrimaryTab() -- 1=Arcane, 2=Fire, 3=Frost
  local mana = Mana()
  
  if not HaveTarget() then
    return pad3({}, IDS.Ability.Wand)
  end
  
  -- Wand if OOM
  if mana < 0.1 then
    Push(q, IDS.Ability.Wand)
    return pad3(q, IDS.Ability.Wand)
  end
  
  -- Evocation if low mana
  if mana < 0.2 and ReadyNow(IDS.Ability.Evocation) then
    Push(q, IDS.Ability.Evocation)
    return pad3(q)
  end
  
  if tree == 2 then
    -- FIRE ROTATION
    -- Pyroblast opener
    if not UnitAffectingCombat("player") and ReadyNow(IDS.Ability.Pyroblast) then
      Push(q, IDS.Ability.Pyroblast)
    end
    
    -- Scorch for debuff
    if not DebuffUp("target", IDS.Ability.Scorch) and ReadySoon(IDS.Ability.Scorch) then
      Push(q, IDS.Ability.Scorch)
    end
    
    -- Fire Blast on cooldown
    if ReadySoon(IDS.Ability.FireBlast) then
      Push(q, IDS.Ability.FireBlast)
    end
    
    -- Fireball spam
    if ReadySoon(IDS.Ability.Fireball) then
      Push(q, IDS.Ability.Fireball)
    end
    
    -- AoE with Flamestrike/Blast Wave
    if TR and TR.db and TR.db.profile and TR.db.profile.aoe then
      if ReadySoon(IDS.Ability.BlastWave) then
        Push(q, IDS.Ability.BlastWave)
      end
      if ReadySoon(IDS.Ability.Flamestrike) then
        Push(q, IDS.Ability.Flamestrike)
      end
    end
    
  elseif tree == 3 then
    -- FROST ROTATION
    -- Frostbolt spam
    if ReadySoon(IDS.Ability.Frostbolt) then
      Push(q, IDS.Ability.Frostbolt)
    end
    
    -- Cone of Cold if in range
    if CheckInteractDistance("target", 2) and ReadySoon(IDS.Ability.ConeOfCold) then
      Push(q, IDS.Ability.ConeOfCold)
    end
    
    -- AoE with Blizzard
    if TR and TR.db and TR.db.profile and TR.db.profile.aoe then
      if ReadySoon(IDS.Ability.Blizzard) then
        Push(q, IDS.Ability.Blizzard)
      end
    end
    
  else
    -- ARCANE ROTATION
    -- Arcane Power burst
    if ReadyNow(IDS.Ability.ArcanePower) then
      Push(q, IDS.Ability.ArcanePower)
    end
    
    -- Presence of Mind for instant cast
    if ReadyNow(IDS.Ability.PresenceOfMind) then
      Push(q, IDS.Ability.PresenceOfMind)
    end
    
    -- Arcane Missiles if proc or clearcasting
    if ReadySoon(IDS.Ability.ArcaneMissiles) then
      Push(q, IDS.Ability.ArcaneMissiles)
    end
    
    -- Arcane Explosion for AoE
    if TR and TR.db and TR.db.profile and TR.db.profile.aoe then
      if CheckInteractDistance("target", 2) and ReadySoon(IDS.Ability.ArcaneExplosion) then
        Push(q, IDS.Ability.ArcaneExplosion)
      end
    end
    
    -- Frostbolt as filler
    if ReadySoon(IDS.Ability.Frostbolt) then
      Push(q, IDS.Ability.Frostbolt)
    end
  end
  
  return q
end

-- Engine tick
function TR:EngineTick_Mage()
  IDS:UpdateRanks()
  
  local q = {}
  
  if not UnitAffectingCombat("player") then
    q = BuildBuffQueue() or {}
    if #q == 0 then
      if HaveTarget() then
        q = BuildQueue()
      end
    end
  else
    q = BuildQueue()
  end
  
  q = pad3(q, IDS.Ability.Wand)
  self._lastMainSpell = q[1]
  
  if self.UI and self.UI.Update then
    self.UI:Update(q[1], q[2], q[3])
  end
end

function TR:StartEngine_Mage()
  self:StopEngine_Mage()
  self:EngineTick_Mage()
  self._engineTimer_MA = self:ScheduleRepeatingTimer("EngineTick_Mage", 0.2)
  self:Print("TacoRot Mage engine active (Classic Anniversary)")
end

function TR:StopEngine_Mage()
  if self._engineTimer_MA then
    self:CancelTimer(self._engineTimer_MA)
    self._engineTimer_MA = nil
  end
end
