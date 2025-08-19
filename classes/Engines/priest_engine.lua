local TR = _G.TacoRot
if not TR then return end
local IDS = _G.TacoRot_IDS_Priest

local TOKEN = "PRIEST"
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
  if not HaveTarget() then return pad3(q, IDS.Ability.Wand or IDS.Ability.AutoAttack) end
  local main = IDS.Ability.Main
  if main and ReadySoon(main) then
    local usable = IsUsableSpell and select(1, IsUsableSpell(main))
    if usable then Push(q, main) end
  end
  if #q == 0 and IDS.Ability.Wand and not InMelee() then
    Push(q, IDS.Ability.Wand)
  end
  if #q == 0 then Push(q, IDS.Ability.AutoAttack) end
  return pad3(q, IDS.Ability.AutoAttack)
end

function TR:EngineTick_Priest()
  if IDS and IDS.UpdateRanks then IDS:UpdateRanks() end
  local q = BuildQueue()
  self._lastMainSpell = q[1]
  if self.UI and self.UI.Update then self.UI:Update(q[1], q[2], q[3]) end
end

function TR:StartEngine_Priest()
  self:StopEngine_Priest()
  self:EngineTick_Priest()
  self._engineTimer_PR = self:ScheduleRepeatingTimer("EngineTick_Priest", 0.2)
  self:Print("TacoRot Priest engine active (Classic Anniversary)")
end

function TR:StopEngine_Priest()
  if self._engineTimer_PR then
    self:CancelTimer(self._engineTimer_PR)
    self._engineTimer_PR = nil
  end
end

local _, class = UnitClass("player")
if class == "PRIEST" then
  local f = CreateFrame("Frame")
  f:RegisterEvent("PLAYER_LOGIN")
  f:SetScript("OnEvent", function()
    if TR and TR.StartEngine_Priest then
      TR:StartEngine_Priest()
    end
  end)
end
