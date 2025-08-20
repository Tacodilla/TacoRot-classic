-- warrior_engine.lua — Classic Anniversary Warrior Engine
DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[TacoRot]|r Warrior engine loaded")

local TR = _G.TacoRot
local IDS = _G.TacoRot_IDS_Warrior

local TOKEN = "WARRIOR"

local function Pad()
  local p = TR and TR.db and TR.db.profile and TR.db.profile.pad
  local v = p and p[TOKEN]
  if not v then return {enabled = true, gcd = 1.5} end
  if v.enabled == nil then v.enabled = true end
  v.gcd = v.gcd or 1.5
  return v
end

local function Known(id)
  return id and IsSpellKnown and IsSpellKnown(id)
end

-- Helper functions
local function BuffCfg()
  return (TR.db and TR.db.profile and TR.db.profile.buff and TR.db.profile.buff.WARRIOR) or {}
end

local function ReadyNow(id)
  if not Known(id) then return false end
  local start, dur = GetSpellCooldown(id)
  return start == 0 or (start + dur - GetTime()) < 0.1
end

local function ReadySoon(id)
  local pad = Pad()
  if not pad.enabled then return ReadyNow(id) end
  if not Known(id) then return false end
  local start, dur = GetSpellCooldown(id)
  return start == 0 or (start + dur - GetTime()) < (pad.gcd or 1.5)
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

local function HaveTarget()
  return UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target")
end

local function InMelee()
  return CheckInteractDistance("target", 3)
end

local function Rage()
  return UnitMana("player") or 0
end

local function Health()
  local hp = UnitHealth("player")
  local max = UnitHealthMax("player")
  return max > 0 and (hp / max) or 1
end

local function TargetHealth()
  local hp = UnitHealth("target")
  local max = UnitHealthMax("target")
  return max > 0 and (hp / max) or 1
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

-- OOC Buffs
local function BuildBuffQueue()
  local cfg = BuffCfg()
  if not cfg.enabled then return {} end
  
  local q = {}
  
  -- Battle Shout
  if cfg.battleShout ~= false then
    if not BuffUp("player", IDS.Ability.BattleShout) and ReadySoon(IDS.Ability.BattleShout) then
      Push(q, IDS.Ability.BattleShout)
    end
  end
  
  -- Commanding Shout (if no Battle Shout)
  if #q == 0 and cfg.commandingShout ~= false then
    if not BuffUp("player", IDS.Ability.CommandingShout) and ReadySoon(IDS.Ability.CommandingShout) then
      Push(q, IDS.Ability.CommandingShout)
    end
  end
  
  return q
end

-- DPS Rotation
local function BuildQueue()
  local q = {}
  local tree = PrimaryTab() -- 1=Arms, 2=Fury, 3=Prot
  local stance = GetStance()
  local rage = Rage()
  local targetHp = TargetHealth()
  
  if not HaveTarget() then
    -- No target, show padding
    return pad3({}, IDS.Ability.AutoAttack)
  end
  
  -- Charge opener (Battle Stance only, out of combat, not in melee)
  if not UnitAffectingCombat("player") and stance == 1 and not InMelee() then
    if ReadyNow(IDS.Ability.Charge) then
      Push(q, IDS.Ability.Charge)
      return pad3(q, IDS.Ability.AutoAttack)
    end
  end
  
  -- Execute phase (20% or less health)
  if targetHp <= 0.2 and rage >= 15 and ReadySoon(IDS.Ability.Execute) then
    Push(q, IDS.Ability.Execute)
  end
  
  if tree == 1 then
    -- ARMS ROTATION
    
    -- Maintain Rend
    if not DebuffUp("target", IDS.Ability.Rend) and rage >= 10 and ReadySoon(IDS.Ability.Rend) then
      Push(q, IDS.Ability.Rend)
    end
    
    -- Mortal Strike on cooldown
    if rage >= 30 and ReadySoon(IDS.Ability.MortalStrike) then
      Push(q, IDS.Ability.MortalStrike)
    end
    
    -- Overpower when available (Battle Stance)
    if stance == 1 and rage >= 5 and ReadySoon(IDS.Ability.Overpower) then
      Push(q, IDS.Ability.Overpower)
    end
    
    -- Sweeping Strikes for cleave
    if TR and TR.db and TR.db.profile and TR.db.profile.aoe then
      if rage >= 30 and ReadySoon(IDS.Ability.SweepingStrikes) then
        Push(q, IDS.Ability.SweepingStrikes)
      end
      -- Cleave as rage dump in AoE
      if rage >= 20 and ReadySoon(IDS.Ability.Cleave) then
        Push(q, IDS.Ability.Cleave)
      end
    end
    
    -- Slam if available
    if rage >= 15 and ReadySoon(IDS.Ability.Slam) then
      Push(q, IDS.Ability.Slam)
    end
    
  elseif tree == 2 then
    -- FURY ROTATION
    
    -- Bloodthirst on cooldown
    if rage >= 30 and ReadySoon(IDS.Ability.Bloodthirst) then
      Push(q, IDS.Ability.Bloodthirst)
    end
    
    -- Whirlwind on cooldown
    if rage >= 25 and ReadySoon(IDS.Ability.Whirlwind) then
      Push(q, IDS.Ability.Whirlwind)
    end
    
    -- Rampage if available
    if rage >= 20 and ReadySoon(IDS.Ability.Rampage) then
      Push(q, IDS.Ability.Rampage)
    end
    
    -- Berserker Rage for rage generation
    if rage < 20 and stance == 3 and ReadySoon(IDS.Ability.BerserkerRage) then
      Push(q, IDS.Ability.BerserkerRage)
    end
    
  else
    -- PROTECTION ROTATION
    
    -- Shield Slam (highest priority)
    if rage >= 20 and ReadySoon(IDS.Ability.ShieldSlam) then
      Push(q, IDS.Ability.ShieldSlam)
    end
    
    -- Revenge when available
    if rage >= 5 and ReadySoon(IDS.Ability.Revenge) then
      Push(q, IDS.Ability.Revenge)
    end
    
    -- Maintain Sunder Armor stacks
    local sunderStacks = 0
    for i = 1, 40 do
      local name, _, stack = UnitDebuff("target", i)
      if name == GetSpellInfo(IDS.Ability.SunderArmor) then
        sunderStacks = stack or 1
        break
      end
    end
    if sunderStacks < 5 and rage >= 15 and ReadySoon(IDS.Ability.SunderArmor) then
      Push(q, IDS.Ability.SunderArmor)
    end
    
    -- Shield Block for mitigation
    if rage >= 10 and ReadySoon(IDS.Ability.ShieldBlock) then
      Push(q, IDS.Ability.ShieldBlock)
    end
  end
  
  -- Rage dump with Heroic Strike or Cleave
  if rage > 50 then
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
  
  -- Thunder Clap for AoE threat/slow
  if TR and TR.db and TR.db.profile and TR.db.profile.aoe then
    if rage >= 20 and ReadySoon(IDS.Ability.ThunderClap) then
      Push(q, IDS.Ability.ThunderClap)
    end
  end
  
  -- Hamstring for kiting/PvP
  if rage >= 10 and ReadySoon(IDS.Ability.Hamstring) then
    Push(q, IDS.Ability.Hamstring)
  end
  
  return q
end

-- Engine tick
function TR:EngineTick_Warrior()
  IDS:UpdateRanks()
  
  local q = {}
  
  if not UnitAffectingCombat("player") then
    q = BuildBuffQueue() or {}
    if #q == 0 then
      if HaveTarget() then
        q = BuildQueue()
      else
        -- Show default padding when idle
        q = {}
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
