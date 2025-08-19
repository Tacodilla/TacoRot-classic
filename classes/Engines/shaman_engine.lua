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
local function InMelee() return CheckInteractDistance("target",3) end
local function pad3(q, fb) q[1]=q[1] or fb; q[2]=q[2] or q[1]; q[3]=q[3] or q[2]; return q end
local function Push(q, id) if id then q[#q+1]=id end end

local function BuildQueue()
  local q = {}
  if not HaveTarget() then return pad3(q, IDS.Ability.AutoAttack) end
  local main = IDS.Ability.Main
  if main and ReadySoon(main) then
    local usable = IsUsableSpell and select(1, IsUsableSpell(main))
    if usable then Push(q, main) end
  end
  if #q == 0 then Push(q, IDS.Ability.AutoAttack) end
  return pad3(q, IDS.Ability.AutoAttack)
end

function TR:EngineTick_Shaman()
  if IDS and IDS.UpdateRanks then IDS:UpdateRanks() end
  local q = BuildQueue()
  self._lastMainSpell = q[1]
  if self.UI and self.UI.Update then self.UI:Update(q[1], q[2], q[3]) end
end

function TR:StartEngine_Shaman()
  self:StopEngine_Shaman()
  self:EngineTick_Shaman()
  self._engineTimer_SH = self:ScheduleRepeatingTimer("EngineTick_Shaman", 0.2)
  self:Print("TacoRot Shaman engine active (Classic Anniversary)")
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
