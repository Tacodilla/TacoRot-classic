local function setupEnvironment()
  -- Minimal LibStub stub to allow loading core.lua
  _G.LibStub = function(lib)
    if lib == "AceAddon-3.0" then
      return {
        NewAddon = function(_, ...)
          local addon = {}
          function addon:UnregisterEvent(...) end
          function addon:SendMessage(...) end
          return addon
        end,
      }
    end
    return {}
  end
  -- Load core.lua to populate _G.TacoRot
  dofile("core.lua")
  return _G.TacoRot
end

describe("HandleWorldEnter", function()
  local TR

  before_each(function()
    TR = setupEnvironment()
  end)

  after_each(function()
    _G.TacoRot = nil
    _G.UnitClass = nil
    _G.LibStub = nil
    TR = nil
  end)

  local classes = {
    Warrior = "WARRIOR",
    Hunter  = "HUNTER",
    Warlock = "WARLOCK",
    Rogue   = "ROGUE",
    Druid   = "DRUID",
    Mage    = "MAGE",
    Paladin = "PALADIN",
    Priest  = "PRIEST",
    Shaman  = "SHAMAN",
  }

  for camel, token in pairs(classes) do
    it("starts " .. camel .. " engine on world enter", function()
      _G.UnitClass = function() return nil, token end
      local called = 0
      TR["StartEngine_" .. camel] = function()
        called = called + 1
      end
      TR:HandleWorldEnter()
      assert.are.equal(1, called)
      assert.is_true(TR._engineStates[camel])
    end)
  end

  it("unregisters world enter event", function()
    _G.UnitClass = function() return nil, "WARRIOR" end
    TR.StartEngine_Warrior = function() end
    local unregistered
    TR.UnregisterEvent = function(_, evt) unregistered = evt end
    TR:HandleWorldEnter()
    assert.are.equal("PLAYER_ENTERING_WORLD", unregistered)
  end)

  it("sends enable class module message", function()
    _G.UnitClass = function() return nil, "WARRIOR" end
    TR.StartEngine_Warrior = function() end
    local msg
    TR.SendMessage = function(_, m) msg = m end
    TR:HandleWorldEnter()
    assert.are.equal("TACOROT_ENABLE_CLASS_MODULE", msg)
  end)

  it("does nothing when class unavailable", function()
    _G.UnitClass = function() return nil, nil end
    local called = false
    TR.StartEngine_Warrior = function() called = true end
    TR.UnregisterEvent = function() called = true end
    TR:HandleWorldEnter()
    assert.is_false(called)
  end)

  it("does not start engine twice", function()
    _G.UnitClass = function() return nil, "WARRIOR" end
    local count = 0
    TR.StartEngine_Warrior = function() count = count + 1 end
    TR:HandleWorldEnter()
    TR:HandleWorldEnter()
    assert.are.equal(1, count)
  end)
end)
