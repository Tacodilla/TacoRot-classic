--------------------------------------------------------------------
-- shaman_engine.lua — Enhanced Classic Anniversary Shaman Engine
--------------------------------------------------------------------

local TR = _G.TacoRot
if not TR then return end
local IDS = _G.TacoRot_IDS_Shaman

local TOKEN = "SHAMAN"
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

local function HasMainHandEnchant()
  local hasMainHandEnchant, _, _, hasOffHandEnchant = GetWeaponEnchantInfo()
  return hasMainHandEnchant
end

local function HasOffHandEnchant()
  local hasMainHandEnchant, _, _, hasOffHandEnchant = GetWeaponEnchantInfo()
  return hasOffHandEnchant
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
  local elementalPts = select(3, GetTalentTabInfo(1)) or 0
  local enhancementPts = select(3, GetTalentTabInfo(2)) or 0
  local restorationPts = select(3, GetTalentTabInfo(3)) or 0
  
  if elementalPts >= enhancementPts and elementalPts >= restorationPts then
    return "Elemental"
  elseif enhancementPts >= restorationPts then
    return "Enhancement"
  else
    return "Restoration"
  end
end

-- Build weapon enchant queue
local function BuildEnchantQueue()
  local q = {}
  local spec = GetPrimarySpec()
  
  -- Main hand weapon enchant
  if not HasMainHandEnchant() then
    if spec == "Enhancement" then
      -- Enhancement prioritizes Windfury or Flametongue
      if Known(IDS.Ability.WindfuryWeapon) and ReadySoon(IDS.Ability.WindfuryWeapon) then
        Push(q, IDS.Ability.WindfuryWeapon)
      elseif Known(IDS.Ability.FlametongueWeapon) and ReadySoon(IDS.Ability.FlametongueWeapon) then
        Push(q, IDS.Ability.FlametongueWeapon)
      elseif ReadySoon(IDS.Ability.RockbiterWeapon) then
        Push(q, IDS.Ability.RockbiterWeapon)
      end
    else
      -- Casters prefer Flametongue for spell damage
      if Known(IDS.Ability.FlametongueWeapon) and ReadySoon(IDS.Ability.FlametongueWeapon) then
        Push(q, IDS.Ability.FlametongueWeapon)
      elseif ReadySoon(IDS.Ability.RockbiterWeapon) then
        Push(q, IDS.Ability.RockbiterWeapon)
      end
    end
  end
  
  -- Off hand weapon enchant (if dual wielding)
  if not HasOffHandEnchant() then
    if spec == "Enhancement" then
      if Known(IDS.Ability.FrostbrandWeapon) and ReadySoon(IDS.Ability.FrostbrandWeapon) then
        Push(q, IDS.Ability.FrostbrandWeapon)  -- Slow for off-hand
      elseif Known(IDS.Ability.FlametongueWeapon) and ReadySoon(IDS.Ability.FlametongueWeapon) then
        Push(q, IDS.Ability.FlametongueWeapon)
      end
    end
  end
  
  return q
end

-- Build buff queue for out of combat
local function BuildBuffQueue()
  local q = {}
  
  -- Lightning Shield (always up)
  if not BuffUp("player", IDS.Ability.LightningShield) and ReadySoon(IDS.Ability.LightningShield) then
    Push(q, IDS.Ability.LightningShield)
  end
  
  -- Water Walking (out of combat utility)
  -- Only suggest if we're not in combat and near water
  if Known(IDS.Ability.WaterWalking) and not UnitAffectingCombat("player") then
    -- Could add water detection logic here
  end
  
  return q
end

-- Build totem queue
local function BuildTotemQueue()
  local q = {}
  local spec = GetPrimarySpec()
  
  -- Only suggest totems if we're in a group or fighting elites
  local inGroup = GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0
  local fightingElite = false
  
  if HaveTarget() then
    local classification = UnitClassification("target")
    fightingElite = classification == "elite" or classification == "rareelite" or classification == "worldboss"
  end
  
  if inGroup or fightingElite then
    -- Fire totems
    if not UnitExists("target") or not InMelee() then
      if Known(IDS.Ability.SearingTotem) and ReadySoon(IDS.Ability.SearingTotem) then
        Push(q, IDS.Ability.SearingTotem)
      end
    end
    
    -- Earth totems  
    if Known(IDS.Ability.StrengthOfEarthTotem) and ReadySoon(IDS.Ability.StrengthOfEarthTotem) then
      Push(q, IDS.Ability.StrengthOfEarthTotem)
    elseif Known(IDS.Ability.StoneskinTotem) and ReadySoon(IDS.Ability.StoneskinTotem) then
      Push(q, IDS.Ability.StoneskinTotem)
    end
    
    -- Water totems
    if Known(IDS.Ability.ManaSpringTotem) and ReadySoon(IDS.Ability.ManaSpringTotem) then
      Push(q, IDS.Ability.ManaSpringTotem)
    elseif Known(IDS.Ability.HealingStreamTotem) and ReadySoon(IDS.Ability.HealingStreamTotem) then
      Push(q, IDS.Ability.HealingStreamTotem)
    end
    
    -- Air totems
    if spec == "Enhancement" then
      if Known(IDS.Ability.WindfuryTotem) and ReadySoon(IDS.Ability.WindfuryTotem) then
        Push(q, IDS.Ability.WindfuryTotem)
      end
    else
      if Known(IDS.Ability.GraceOfAirTotem) and ReadySoon(IDS.Ability.GraceOfAirTotem) then
        Push(q, IDS.Ability.GraceOfAirTotem)
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
      return pad3(buffQueue, IDS.Ability.AutoAttack)
    end
    
    local enchantQueue = BuildEnchantQueue()
    if #enchantQueue > 0 then
      return pad3(enchantQueue, IDS.Ability.AutoAttack)
    end
    
    return pad3(q, IDS.Ability.AutoAttack)
  end
  
  local manaPercent = ManaPercent()
  local inMelee = InMelee()
  
  -- Low mana fallback
  if manaPercent < 15 then
    Push(q, IDS.Ability.AutoAttack)
    return pad3(q, IDS.Ability.AutoAttack)
  end
  
  if spec == "Enhancement" then
    -- Enhancement rotation - melee focused but casts at range
    
    if inMelee then
      -- Stormstrike (enhancement signature ability)
      if Known(IDS.Ability.Stormstrike) and ReadySoon(IDS.Ability.Stormstrike) then
        Push(q, IDS.Ability.Stormstrike)
      end
      
      -- Earth Shock for interrupt/damage in melee
      if Known(IDS.Ability.EarthShock) and ReadySoon(IDS.Ability.EarthShock) then
        Push(q, IDS.Ability.EarthShock)
      end
      
      -- Flame Shock DoT
      if Known(IDS.Ability.FlameShock) then
        if not DebuffUp("target", IDS.Ability.FlameShock) or DebuffTimeLeft("target", IDS.Ability.FlameShock) < 3 then
          if ReadySoon(IDS.Ability.FlameShock) then
            Push(q, IDS.Ability.FlameShock)
          end
        end
      end
      
      -- Auto attack in melee
      Push(q, IDS.Ability.AutoAttack)
      
    else
      -- Ranged rotation for enhancement
      
      -- Lightning Bolt when not in melee
      if ReadySoon(IDS.Ability.LightningBolt) then
        Push(q, IDS.Ability.LightningBolt)
      end
      
      -- Earth Shock for pulling
      if Known(IDS.Ability.EarthShock) and ReadySoon(IDS.Ability.EarthShock) then
        Push(q, IDS.Ability.EarthShock)
      end
    end
    
  elseif spec == "Elemental" then
    -- Elemental rotation - caster DPS
    
    -- Flame Shock DoT (highest priority)
    if Known(IDS.Ability.FlameShock) then
      if not DebuffUp("target", IDS.Ability.FlameShock) or DebuffTimeLeft("target", IDS.Ability.FlameShock) < 3 then
        if ReadySoon(IDS.Ability.FlameShock) then
          Push(q, IDS.Ability.FlameShock)
        end
      end
    end
    
    -- Earth Shock for instant damage when Lightning Bolt is on cooldown
    if Known(IDS.Ability.EarthShock) and ReadySoon(IDS.Ability.EarthShock) then
      -- Only use if Lightning Bolt is on cooldown or we need instant damage
      local lbCooldown = GetSpellCooldown(IDS.Ability.LightningBolt)
      if lbCooldown and lbCooldown > 0 then
        Push(q, IDS.Ability.EarthShock)
      end
    end
    
    -- Chain Lightning for AoE (if multiple targets)
    if Known(IDS.Ability.ChainLightning) and ReadySoon(IDS.Ability.ChainLightning) then
      -- Simple AoE detection - use Chain Lightning if we think there are multiple enemies
      -- This is a basic implementation; could be enhanced with enemy counting
      if TR and TR.db and TR.db.profile and TR.db.profile.aoe then
        Push(q, IDS.Ability.ChainLightning)
      end
    end
    
    -- Lightning Bolt (main nuke)
    if ReadySoon(IDS.Ability.LightningBolt) then
      Push(q, IDS.Ability.LightningBolt)
    end
    
  else
    -- Restoration rotation - basic damage when not healing
    
    -- Lightning Bolt as main damage spell
    if ReadySoon(IDS.Ability.LightningBolt) then
      Push(q, IDS.Ability.LightningBolt)
    end
    
    -- Earth Shock for instant damage
    if Known(IDS.Ability.EarthShock) and ReadySoon(IDS.Ability.EarthShock) then
      Push(q, IDS.Ability.EarthShock)
    end
  end
  
  -- Fallback
  if #q == 0 then
    if manaPercent > 20 and ReadySoon(IDS.Ability.LightningBolt) then
      Push(q, IDS.Ability.LightningBolt)
    else
      Push(q, IDS.Ability.AutoAttack)
    end
  end
  
  return pad3(q, IDS.Ability.AutoAttack)
end

function TR:EngineTick_Shaman()
  if IDS and IDS.UpdateRanks then IDS:UpdateRanks() end
  
  local q = {}
  
  -- Out of combat management
  if not UnitAffectingCombat("player") then
    q = BuildBuffQueue()
    if #q == 0 then
      local enchantQueue = BuildEnchantQueue()
      if #enchantQueue > 0 then
        q = enchantQueue
      end
    end
    if #q == 0 then
      if HaveTarget() then
        q = BuildQueue()
      else
        q = {IDS.Ability.LightningShield, IDS.Ability.RockbiterWeapon, IDS.Ability.AutoAttack}
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

function TR:StartEngine_Shaman()
  self:StopEngine_Shaman()
  self:EngineTick_Shaman()
  self._engineTimer_SH = self:ScheduleRepeatingTimer("EngineTick_Shaman", 0.2)
  self:Print("TacoRot Enhanced Shaman engine active (Classic Anniversary)")
end

function TR:StopEngine_Shaman()
  if self._engineTimer_SH then
    self:CancelTimer(self._engineTimer_SH)
    self._engineTimer_SH = nil
  end
end

local _, class = UnitClass("player")
if class == "SHAMAN" then
  local f = CreateFrame("Frame")
  f:RegisterEvent("PLAYER_LOGIN")
  f:SetScript("OnEvent", function()
    if TR and TR.StartEngine_Shaman then
      TR:StartEngine_Shaman()
    end
  end)
end
