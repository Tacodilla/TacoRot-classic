local TR = _G.TacoRot
if not TR then return end

-- Config
local TOKEN = "HUNTER"
local function Pad() 
  local p = TR and TR.db and TR.db.profile and TR.db.profile.pad
  local v = p and p[TOKEN]
  if not v then return {enabled=true, gcd=1.5} end
  if v.enabled == nil then v.enabled = true end
  v.gcd = v.gcd or 1.5
  return v
end

local function BuffCfg()
  local p = TR and TR.db and TR.db.profile and TR.db.profile.buff
  return (p and p[TOKEN]) or {enabled=true}
end

local function PetCfg()
  local p = TR and TR.db and TR.db.profile and TR.db.profile.pet
  return (p and p[TOKEN]) or {enabled=true}
end

-- Helpers
local function Known(id) 
  return id and IsSpellKnown and IsSpellKnown(id)
end

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

local function DebuffUp(unit, spellID)
  if not spellID then return false end
  local name = GetSpellInfo(spellID)
  if not name then return false end
  for i = 1, 16 do
    local debuffName = UnitDebuff(unit, i)
    if not debuffName then break end
    if debuffName == name then return true end
  end
  return false
end

local function BuffUp(unit, spellID)
  if not spellID then return false end
  local name = GetSpellInfo(spellID)
  if not name then return false end
  for i = 1, 32 do
    local buffName = UnitBuff(unit, i)
    if not buffName then break end
    if buffName == name then return true end
  end
  return false
end

local function HaveTarget()
  return UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target")
end

local function InMelee()
  return CheckInteractDistance("target", 3)
end

local function InRange()
  -- Check if we're in ranged attack range
  if not HaveTarget() then return false end
  local name = GetSpellInfo(IDS.Ability.ArcaneShot)
  if name then
    return IsSpellInRange(name, "target") == 1
  end
  return not InMelee()
end

local function HasPet()
  return UnitExists("pet") and not UnitIsDead("pet")
end

local function PetHealth()
  if not HasPet() then return 1 end
  local hp = UnitHealth("pet") or 0
  local max = UnitHealthMax("pet") or 1
  if max == 0 then return 1 end
  return hp / max
end

local function AutoShotActive()
  -- Classic: Check if Auto Shot is active
  if not IsAutoRepeatAction then return false end
  -- Check all action bar slots for Auto Shot
  for i = 1, 120 do
    if IsAutoRepeatAction(i) then
      local actionType, id = GetActionInfo(i)
      if actionType == "spell" then
        local name = GetSpellInfo(id)
        if name == GetSpellInfo(75) then -- Auto Shot
          return true
        end
      end
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
  if id then q[#q + 1] = id end
end

-- OOC Buffs
local function BuildBuffQueue()
  local cfg = BuffCfg()
  if not cfg.enabled then return end
  
  local q = {}
  
  -- Aspect check
  if cfg.aspect ~= false then
    if not BuffUp("player", IDS.Ability.AspectOfTheHawk) and 
       not BuffUp("player", IDS.Ability.AspectOfTheMonkey) then
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
    if not cfg.enabled then return end

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
      if PetHealth() < 0.6 and ReadySoon(IDS.Ability.MendPet) then
        Push(q, IDS.Ability.MendPet)
        return q
      end
    end

    return q
  end

-- DPS Rotation
local function BuildQueue()
  local q = {}
  
  if not HaveTarget() then
    -- No target, suggest pet maintenance
    local pq = BuildPetQueue()
    if pq and pq[1] then 
      return pq
    else
      return {IDS.Ability.AutoShot, IDS.Ability.AutoShot, IDS.Ability.AutoShot}
    end
  end
  
  -- Out of combat setup
  if not UnitAffectingCombat("player") then
    -- Hunter's Mark
    if not DebuffUp("target", IDS.Ability.HuntersMark) and ReadyNow(IDS.Ability.HuntersMark) then
      Push(q, IDS.Ability.HuntersMark)
    end
    
    -- Start Auto Shot if in range
    if InRange() and not AutoShotActive() then
      Push(q, IDS.Ability.AutoShot)
    end
  end
  
  -- Combat rotation
  if InMelee() then
    -- Melee rotation
    if ReadyNow(IDS.Ability.RaptorStrike) then
      table.insert(q, 1, IDS.Ability.RaptorStrike)
    end
    if #q < 3 and ReadySoon(IDS.Ability.WingClip) then
      Push(q, IDS.Ability.WingClip)
    end
    -- Aspect of the Monkey for melee
    if not BuffUp("player", IDS.Ability.AspectOfTheMonkey) and ReadySoon(IDS.Ability.AspectOfTheMonkey) then
      Push(q, IDS.Ability.AspectOfTheMonkey)
    end
  else
    -- Ranged rotation
    -- Maintain Auto Shot
    if not AutoShotActive() then
      table.insert(q, 1, IDS.Ability.AutoShot)
    end
    
    -- Aimed Shot (highest priority)
    if ReadySoon(IDS.Ability.AimedShot) then
      Push(q, IDS.Ability.AimedShot)
    end
    
    -- Multi-Shot for AoE
    if TR and TR.db and TR.db.profile and TR.db.profile.aoe then
      if ReadySoon(IDS.Ability.MultiShot) then
        Push(q, IDS.Ability.MultiShot)
      end
    end
    
    -- Serpent Sting
    if not DebuffUp("target", IDS.Ability.SerpentSting) and ReadySoon(IDS.Ability.SerpentSting) then
      Push(q, IDS.Ability.SerpentSting)
    end
    
    -- Arcane Shot
    if ReadySoon(IDS.Ability.ArcaneShot) then
      Push(q, IDS.Ability.ArcaneShot)
    end
    
    -- Aspect of the Hawk for ranged
    if not BuffUp("player", IDS.Ability.AspectOfTheHawk) and ReadySoon(IDS.Ability.AspectOfTheHawk) then
      Push(q, IDS.Ability.AspectOfTheHawk)
    end
  end
  
  -- Pet queue if nothing else
  if #q == 0 and not UnitAffectingCombat("player") then
    local pq = BuildPetQueue()
    if pq and pq[1] then q = pq end
  end
  
  return pad3(q, IDS.Ability.AutoShot)
end

-- Engine tick
function TR:EngineTick_Hunter()
  IDS:UpdateRanks()
  
  local q = {}
  
  if not UnitAffectingCombat("player") then
    -- OOC: Priority is Pet > Buffs > Combat
    q = BuildPetQueue() or BuildBuffQueue() or {}
    if not q[1] then
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

-- Auto-start for hunters
local _, class = UnitClass("player")
if class == "HUNTER" then
  local f = CreateFrame("Frame")
  f:RegisterEvent("PLAYER_LOGIN")
  f:SetScript("OnEvent", function()
    if TR and TR.StartEngine_Hunter then
      TR:StartEngine_Hunter()
    end
  end)
end