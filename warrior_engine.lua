local TR = _G.TacoRot
if not TR then return end

-- Config
local TOKEN = "WARRIOR"
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

local function Rage()
  return UnitMana("player") or 0
end

local function GetStance()
  -- Returns current stance: 1=Battle, 2=Defensive, 3=Berserker
  for i = 1, 3 do
    local _, _, active = GetShapeshiftFormInfo(i)
    if active then return i end
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
  if id then q[#q + 1] = id end
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
  if not cfg.enabled then return end
  
  local q = {}
  
  -- Battle Shout
  if cfg.battleShout ~= false then
    if not BuffUp("player", IDS.Ability.BattleShout) and ReadySoon(IDS.Ability.BattleShout) then
      Push(q, IDS.Ability.BattleShout)
    end
  end
  
  return q
end

-- DPS Rotation
local function BuildQueue()
  local q = {}
  local tree = PrimaryTab() -- 1=Arms, 2=Fury, 3=Prot
  local stance = GetStance()
  
  if not HaveTarget() then
    return {IDS.Ability.BattleShout, IDS.Ability.BattleShout, IDS.Ability.BattleShout}
  end
  
  -- Charge opener (Battle Stance only)
  if not UnitAffectingCombat("player") and stance == 1 then
    if not InMelee() and ReadyNow(IDS.Ability.Charge) then
      Push(q, IDS.Ability.Charge)
      return pad3(q, IDS.Ability.HeroicStrike)
    end
  end
  
  -- Execute phase
  local targetHealth = UnitHealth("target") / UnitHealthMax("target")
  if targetHealth <= 0.2 and ReadySoon(IDS.Ability.Execute) then
    Push(q, IDS.Ability.Execute)
  end
  
  if tree == 1 then
    -- Arms rotation
    -- Rend
    if not DebuffUp("target", IDS.Ability.Rend) and ReadySoon(IDS.Ability.Rend) then
      Push(q, IDS.Ability.Rend)
    end
    
    -- Overpower (Battle Stance)
    if stance == 1 and ReadySoon(IDS.Ability.Overpower) then
      Push(q, IDS.Ability.Overpower)
    end
    
    -- Mortal Strike
    if ReadySoon(IDS.Ability.MortalStrike) then
      Push(q, IDS.Ability.MortalStrike)
    end
    
    -- Sweeping Strikes for AoE
    if TR and TR.db and TR.db.profile and TR.db.profile.aoe then
      if ReadySoon(IDS.Ability.SweepingStrikes) then
        Push(q, IDS.Ability.SweepingStrikes)
      end
    end
    
  elseif tree == 2 then
    -- Fury rotation
    -- Bloodthirst
    if ReadySoon(IDS.Ability.Bloodthirst) then
      Push(q, IDS.Ability.Bloodthirst)
    end
    
    -- Whirlwind
    if ReadySoon(IDS.Ability.Whirlwind) then
      Push(q, IDS.Ability.Whirlwind)
    end
    
    -- Rampage
    if ReadySoon(IDS.Ability.Rampage) then
      Push(q, IDS.Ability.Rampage)
    end
    
  else
    -- Protection rotation
    -- Shield Slam
    if ReadySoon(IDS.Ability.ShieldSlam) then
      Push(q, IDS.Ability.ShieldSlam)
    end
    
    -- Revenge
    if ReadySoon(IDS.Ability.Revenge) then
      Push(q, IDS.Ability.Revenge)
    end
    
    -- Sunder Armor
    local sunderStacks = 0
    for i = 1, 16 do
      local name, _, stack = UnitDebuff("target", i)
      if name == GetSpellInfo(IDS.Ability.SunderArmor) then
        sunderStacks = stack or 1
        break
      end
    end
    if sunderStacks < 5 and ReadySoon(IDS.Ability.SunderArmor) then
      Push(q, IDS.Ability.SunderArmor)
    end
  end
  
  -- Rage dump with Heroic Strike or Cleave
  if Rage() > 50 then
    if TR and TR.db and TR.db.profile and TR.db.profile.aoe then
      if ReadySoon(IDS.Ability.Cleave) then
        Push(q, IDS.Ability.Cleave)
      end
    else
      if ReadySoon(IDS.Ability.HeroicStrike) then
        Push(q, IDS.Ability.HeroicStrike)
      end
    end
  end
  
  return q
end

-- Engine tick
function TR:EngineTick_Warrior()
  IDS:UpdateRanks()
  
  local q = {}
  
  if not UnitAffectingCombat("player") then
    q = BuildBuffQueue() or {}
    if not q[1] then
      if HaveTarget() then
        q = BuildQueue()
      else
        q = {IDS.Ability.BattleShout, IDS.Ability.BattleShout, IDS.Ability.BattleShout}
      end
    end
  else
    q = BuildQueue()
  end
  
  q = pad3(q, IDS.Ability.HeroicStrike)
  self._lastMainSpell = q[1]
  
  if self.UI and self.UI.Update then
    self.UI:Update(q[1], q[2], q[3])
  end
end

function TR:StartEngine_Warrior()
  self:StopEngine_Warrior()
  self:EngineTick_Warrior()
  self._engineTimer_WA = self:ScheduleRepeatingTimer("EngineTick_Warrior", 0.2)
  self:Print("TacoRot Warrior engine active (Classic Anniversary)")
end

function TR:StopEngine_Warrior()
  if self._engineTimer_WA then
    self:CancelTimer(self._engineTimer_WA)
    self._engineTimer_WA = nil
  end
end

-- Auto-start for warriors
local _, class = UnitClass("player")
if class == "WARRIOR" then
  local f = CreateFrame("Frame")
  f:RegisterEvent("PLAYER_LOGIN")
  f:SetScript("OnEvent", function()
    if TR and TR.StartEngine_Warrior then
      TR:StartEngine_Warrior()
    end
  end)
end