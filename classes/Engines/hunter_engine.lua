-- hunter_engine.lua — Classic Anniversary Hunter Engine
DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[TacoRot]|r Hunter engine loaded")

local TR = _G.TacoRot
local IDS = _G.TacoRot_IDS_Hunter

-- Helper functions
local function BuffCfg()
  return (TR.db and TR.db.profile and TR.db.profile.buff and TR.db.profile.buff.HUNTER) or {}
end

local function PetCfg()
  return (TR.db and TR.db.profile and TR.db.profile.pet and TR.db.profile.pet.HUNTER) or {}
end

local function HasPet()
  return UnitExists("pet") and not UnitIsDead("pet")
end

local function PetHealth()
  local hp = UnitHealth("pet")
  local max = UnitHealthMax("pet")
  return max > 0 and (hp / max) or 1
end

local function AutoShotActive()
  -- Check if auto shot is active
  return IsAutoRepeatSpell(GetSpellInfo(IDS.Ability.AutoShot))
end

local function Mana()
  local mana = UnitMana("player")
  local maxMana = UnitManaMax("player")
  return maxMana > 0 and (mana / maxMana) or 0
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

local function InRange()
  return IsSpellInRange(GetSpellInfo(IDS.Ability.ArcaneShot), "target") == 1
end

local function pad3(q, fb)
  q[1] = q[1] or fb or IDS.Ability.AutoShot
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
  
  -- Aspect of the Hawk for damage
  if cfg.aspect ~= false then
    if not BuffUp("player", IDS.Ability.AspectOfTheHawk) and not BuffUp("player", IDS.Ability.AspectOfTheMonkey) then
      if ReadySoon(IDS.Ability.AspectOfTheHawk) then
        Push(q, IDS.Ability.AspectOfTheHawk)
      end
    end
  end
  
  -- Trueshot Aura
  if cfg.trueshot ~= false then
    if not BuffUp("player", IDS.Ability.TrueshotAura) and ReadySoon(IDS.Ability.TrueshotAura) then
      Push(q, IDS.Ability.TrueshotAura)
    end
  end
  
  return q
end

-- Pet Management
local function BuildPetQueue()
  local cfg = PetCfg()
  if not cfg.enabled then return {} end
  
  local q = {}
  
  -- Revive Pet if dead
  if UnitExists("pet") and UnitIsDead("pet") and cfg.revive ~= false then
    if ReadySoon(IDS.Ability.RevivePet) then
      Push(q, IDS.Ability.RevivePet)
      return q
    end
  end
  
  -- Call Pet if no pet
  if not UnitExists("pet") and cfg.summon ~= false then
    if ReadySoon(IDS.Ability.CallPet) then
      Push(q, IDS.Ability.CallPet)
      return q
    end
  end
  
  -- Mend Pet if hurt
  if HasPet() and cfg.mend ~= false then
    if PetHealth() < 0.7 and ReadySoon(IDS.Ability.MendPet) then
      Push(q, IDS.Ability.MendPet)
      return q
    end
  end
  
  return q
end

-- DPS Rotation
local function BuildQueue()
  local q = {}
  local tree = PrimaryTab() -- 1=Beast Mastery, 2=Marksmanship, 3=Survival
  local mana = Mana()
  
  if not HaveTarget() then
    -- Pet management when idle
    local pq = BuildPetQueue()
    if pq and pq[1] then
      return pad3(pq)
    end
    return pad3({}, IDS.Ability.AutoShot)
  end
  
  -- Hunter's Mark
  if not DebuffUp("target", IDS.Ability.HuntersMark) and ReadySoon(IDS.Ability.HuntersMark) then
    Push(q, IDS.Ability.HuntersMark)
  end
  
  if InMelee() then
    -- MELEE ROTATION
    -- Aspect of the Monkey in melee
    if not BuffUp("player", IDS.Ability.AspectOfTheMonkey) and ReadySoon(IDS.Ability.AspectOfTheMonkey) then
      Push(q, IDS.Ability.AspectOfTheMonkey)
    end
    
    -- Raptor Strike
    if ReadySoon(IDS.Ability.RaptorStrike) then
      Push(q, IDS.Ability.RaptorStrike)
    end
    
    -- Mongoose Bite
    if ReadySoon(IDS.Ability.MongooseBite) then
      Push(q, IDS.Ability.MongooseBite)
    end
    
    -- Wing Clip for kiting
    if ReadySoon(IDS.Ability.WingClip) then
      Push(q, IDS.Ability.WingClip)
    end
    
  else
    -- RANGED ROTATION
    -- Aspect of the Hawk for ranged
    if not BuffUp("player", IDS.Ability.AspectOfTheHawk) and ReadySoon(IDS.Ability.AspectOfTheHawk) then
      Push(q, IDS.Ability.AspectOfTheHawk)
    end
    
    -- Start Auto Shot
    if not AutoShotActive() then
      Push(q, IDS.Ability.AutoShot)
    end
    
    -- Aimed Shot (highest priority)
    if mana > 0.3 and ReadySoon(IDS.Ability.AimedShot) then
      Push(q, IDS.Ability.AimedShot)
    end
    
    -- Multi-Shot for AoE
    if TR and TR.db and TR.db.profile and TR.db.profile.aoe then
      if mana > 0.3 and ReadySoon(IDS.Ability.MultiShot) then
        Push(q, IDS.Ability.MultiShot)
      end
    end
    
    -- Serpent Sting
    if not DebuffUp("target", IDS.Ability.SerpentSting) and mana > 0.2 and ReadySoon(IDS.Ability.SerpentSting) then
      Push(q, IDS.Ability.SerpentSting)
    end
    
    -- Arcane Shot
    if mana > 0.3 and ReadySoon(IDS.Ability.ArcaneShot) then
      Push(q, IDS.Ability.ArcaneShot)
    end
    
    -- Bestial Wrath for pet burst
    if tree == 1 and HasPet() and ReadySoon(IDS.Ability.BestialWrath) then
      Push(q, IDS.Ability.BestialWrath)
    end
    
    -- Rapid Fire for burst
    if tree == 2 and ReadySoon(IDS.Ability.RapidFire) then
      Push(q, IDS.Ability.RapidFire)
    end
  end
  
  return q
end

-- Engine tick
function TR:EngineTick_Hunter()
  IDS:UpdateRanks()
  
  local q = {}
  
  if not UnitAffectingCombat("player") then
    -- OOC: Priority is Pet > Buffs > Combat
    local pq = BuildPetQueue()
    local bq = BuildBuffQueue()
    
    if pq and pq[1] then
      q = pq
    elseif bq and bq[1] then
      q = bq
    else
      q = BuildQueue()
    end
  else
    q = BuildQueue()
  end
  
  q = pad3(q, IDS.Ability.AutoShot)
  self._lastMainSpell = q[1]
  
  if self.UI and self.UI.Update then
    self.UI:Update(q[1], q[2], q[3])
  end
end

function TR:StartEngine_Hunter()
  self:StopEngine_Hunter()
  self:EngineTick_Hunter()
  self._engineTimer_HU = self:ScheduleRepeatingTimer("EngineTick_Hunter", 0.2)
  self:Print("TacoRot Hunter engine active (Classic Anniversary)")
end

function TR:StopEngine_Hunter()
  if self._engineTimer_HU then
    self:CancelTimer(self._engineTimer_HU)
    self._engineTimer_HU = nil
  end
end
