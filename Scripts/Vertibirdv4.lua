--------------------------------------------------------------------------------
 -- TorqueGenerator class
--------------------------------------------------------------------------------
local TorqueGenerator = {}
TorqueGenerator.__index = TorqueGenerator

setmetatable(TorqueGenerator, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function TorqueGenerator.new(c)
	local self = setmetatable({}, TorqueGenerator)
	self.c = c -- torque generator components
	self.longVal = 0
	self.latVal = 0

	function self.rotate(axis, speed)
		for i, v in pairs(axis) do
			besiege.setSliderValue(v, speed)
		end
	end

	return self
end

--need to refactor this next
function TorqueGenerator:update()
	self.longVal = besiege.getRoll(self.c[4][3], self.c[4][4])
	self.latVal = besiege.getPitch(self.c[4][1], self.c[4][2])

	if self.longVal > 5 then
		self.rotate(self.c[1], 2)
	elseif self.longVal < -5 then
		self.rotate(self.c[1], -2)
	else
		self.rotate(self.c[1], 0)
	end

	if self.latVal > 5 then
		self.rotate(self.c[2], 2)
	elseif self.latVal < -5 then
		self.rotate(self.c[2], -2)
	else
		self.rotate(self.c[2], 0)
	end
end

--------------------------------------------------------------------------------
 -- Engine class
--------------------------------------------------------------------------------
local Engine = {}
Engine.__index = Engine

setmetatable(Engine, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function Engine.new(c)
	local self = setmetatable({}, Engine)
	self.c = c -- engine components
	return self
end

function Engine:adjThrustTo(val)
	for i, v in pairs(self.c) do
		v[2] = v[3] / 100 * val
		besiege.setSliderValue(v[1], v[2])
	end
end

--------------------------------------------------------------------------------
 -- Flight control state machine
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Torque Gen Component IDs
--------------------------------------------------------------------------------
local tGenComponents = 
{
	{107, 108, 109, 110, 111, 116, 115, 114, 113, 112}, --long
	{122, 123, 124, 125, 126, 121, 120, 119, 118, 117}, --lat
	{104, 103, 102, 101, 100, 99, 165, 164}, --perp
	{106, 105, 97, 27, 127, 0} -- points - f, b, l, r, t, btm
}

--------------------------------------------------------------------------------
-- Left Engine Component IDs
--------------------------------------------------------------------------------
local lTSBlade = 54
local lBSBlade = 61
local lEngineComponents = 
{
	-- componentID, sliderVal, maxSliderVal
	{50, 0, 2},		
	{lTSBlade, 0, 0.85}, 	
	{52, 0, 2}, 		
	{56, 0, 2}, 		
	{lBSBlade, 0, 0.85}, 	
	{59, 0, 2} 		
}

--------------------------------------------------------------------------------
-- Right Engine Component IDs
--------------------------------------------------------------------------------
local rTSBlade = 53
local rBSBlade = 60
local rEngineComponents = 
{
	-- componentID, sliderVal, maxSliderVal
	{49, 0, 2}, 		
	{rTSBlade, 0, 0.85},	
	{51, 0, 2}, 		
	{57, 0, 2}, 		
	{rBSBlade, 0, 0.85}, 	
	{58, 0, 2} 		
}

--------------------------------------------------------------------------------
-- required because you cant set sawblade slider values to 0 directly in the .bsg file:(
besiege.setSliderValue(lTSBlade, 0) -- left top sawblade
besiege.setSliderValue(lBSBlade, 0) -- left bottom sawblade
besiege.setSliderValue(rTSBlade, 0) -- right top sawblade
besiege.setSliderValue(rBSBlade, 0) -- right bottom sawblade

--------------------------------------------------------------------------------

local tG = TorqueGenerator(tGenComponents)
local lEng = Engine(lEngineComponents)
local rEng = Engine(rEngineComponents)

local lEngThrustPercent = 0
local rEngThrustPercent = 0
local targetAlt = 0

local enginesActivateLog = false
local enginesDeactivateLog = false
local enginesIdleLog = false

function enginesInactive()
	besiege.log("Engines inactive")
end

function activateEngines()
	local idleThrustPercentage = 20
	enginesDeactivateLog = false

	if enginesActivateLog == false then
		enginesActivateLog = true
		besiege.log("Engines activated")	
	end

	if lEngThrustPercent < idleThrustPercentage then
		lEng:adjThrustTo(rEngThrustPercent + 0.2)
		lEngThrustPercent = lEngThrustPercent + 0.2
		if(lEngThrustPercent > idleThrustPercentage) then
			lEngThrustPercent = idleThrustPercentage
		end
	end

	if rEngThrustPercent < idleThrustPercentage then
		rEng:adjThrustTo(rEngThrustPercent + 0.2)
		rEngThrustPercent = rEngThrustPercent + 0.2
		if(rEngThrustPercent > idleThrustPercentage) then
			rEngThrustPercent = idleThrustPercentage
		end
	end

	-- if idling speed reached by both engines
	if(lEngThrustPercent == idleThrustPercentage and rEngThrustPercent == idleThrustPercentage) then
		changeState("activatingEngines", "engineActivationComplete")
		enginesActivateLog = false
	end
end

function idling()
	if enginesIdleLog == false then
		enginesIdleLog = true
		besiege.log("Engines Idling")	
	end
end

function deactivateEngines()
	enginesActivateLog = false
	enginesIdleLog = false
	if enginesDeactivateLog == false then
		enginesDeactivateLog = true
		besiege.log("Engines deactivating")	
	end
	
	if lEngThrustPercent > 0 then
		lEng:adjThrustTo(rEngThrustPercent - 0.2)
		lEngThrustPercent = lEngThrustPercent - 0.2
		if(lEngThrustPercent < 0) then
			lEngThrustPercent = 0
		end
	end
	
	if rEngThrustPercent > 0 then
		rEng:adjThrustTo(rEngThrustPercent - 0.2)
		rEngThrustPercent = rEngThrustPercent - 0.2
		if(rEngThrustPercent < 0) then
			rEngThrustPercent = 0
		end
	end
	
	if(lEngThrustPercent == 0 and rEngThrustPercent == 0) then
		changeState("inactive", "enginesDeactivated")
		enginesDeactivateLog = false
	end
end

function ascFromIdle()
	-- allows for retraction of landing gear once script lib allows for piston control 
	-- increase altitude directly from here

	if enginesIdleLog == false then
		enginesIdleLog = true
		besiege.log("Activating engines")	
	end
	--transitionAltTo(targetAlt)
end

function hover()
	besiege.log("Hovering")
end

function dscFromAsc()
	besiege.log("Descending from ascending")
end

function ascFromHover()
	besiege.log("Ascending after hover")
end

function dscFromHover()
	besiege.log("Descending after hover")
end

function ascFromDsc()
	besiege.log("Ascending from Descending")
end

function hoverFromDsc()
	besiege.log("Hovering after descent")
end

function land()
	besiege.log("Landing")
end

function idleFromLanding()
	besiege.log("Idling after landing")
end

function transitionAltTo(val)
	if besiege.getPositionY(0) < targetAlt then
		if lEngThrustPercent < 50 then
			lEng:adjThrustTo(lEngThrustPercent + 0.2)
			lEngThrustPercent = lEngThrustPercent + 0.2
		end
		if rEngThrustPercent < 50 then
			rEng:adjThrustTo(rEngThrustPercent + 0.2)
			rEngThrustPercent = rEngThrustPercent + 0.2
		end
	else -- besiege.getPositionY(0) > targetAlt implied
		if lEngThrustPercent > 20 then
			lEng:adjThrustTo(lEngThrustPercent - 0.2)
			lEngThrustPercent = lEngThrustPercent - 0.2
		end
		if rEngThrustPercent > 20 then
			rEng:adjThrustTo(rEngThrustPercent - 0.2)
			rEngThrustPercent = rEngThrustPercent - 0.2
		end
	end
end

function FSM(t)
	local a = {}
	for _,v in ipairs(t) do
		local old, event, new, action = v[1], v[2], v[3], v[4]
		if a[old] == nil then 
			a[old] = {} 
		end
		a[old][event] = {new = new, action = action}
	end
	return a
end


fsm = FSM
{
	{"inactive", "enginesDeactivated", "inactive", enginesInactive}, -- start state
	{"inactive", "enginesActivationBegin", "activatingEngines", activateEngines},
	{"activatingEngines", "enginesDeactivatedDuringActivation", "deactivatingEngines", deactivateEngines},
	{"deactivatingEngines", "enginesActivatedDuringDeactivation", "activatingEngines", activateEngines},
	{"activatingEngines", "engineActivationComplete", "idle", idling},
	{"idle", "engineDeactivatedDuringIdle", "deactivatingEngines", deactivateEngines},


	--{"deactivatingEngines", "engineShutdownComplete", "inactive", enginesInactive},
	--{"deactivatingEngines", "enginePoweringUpFromShutdown", "activatingEngines", activateEngines},
	--{"idle", "stopEnginesFromIdle", "deactivatingEngines", deactivateEngines},


--	{"idle", "altRaisedFromIdle", "ascend", ascFromIdle},
--	{"ascend", "altReachedFromIdle", "hover", hover},
--	{"ascend", "altLoweredFromAscent", "descend", dscFromAsc},
--	{"hover", "altRaisedFromHover", "ascend", ascFromHover},
--	{"hover", "altLoweredFromHover", "descend", dscFromHover},
--	{"descend", "altRaisedFromDescent", "ascend", ascFromDsc},
--	{"descend", "altReachedFromDescent", "hover", hover},
--	{"descend", "altLoweredToZero", "landing", land},
--	{"landing", "altReachedForLanding", "idle", idleFromLanding},
}

local a = fsm["inactive"]["enginesDeactivated"]
a.action()
state = a.new

besiege.onKeyDown = function(keyCode)
	if keyCode == besiege.keyCodes.z then
		if state == "inactive" then
			changeState("inactive","enginesActivationBegin")
		elseif state == "activatingEngines" then
			changeState("activatingEngines", "enginesDeactivatedDuringActivation")
		elseif state == "deactivatingEngines" then
			changeState("deactivatingEngines", "enginesActivatedDuringDeactivation")
		elseif state == "idle" then
			changeState("idle", "engineDeactivatedDuringIdle")
		end
	end
end

besiege.onKeyHeld = function(keyCode)
	if keyCode == besiege.keyCodes.keypadPlus then
		targetAlt = targetAlt + 5
	end 

	if keyCode == besiege.keyCodes.keypadMinus then
		targetAlt = targetAlt - 5
		if targetAlt < 0 then
			targetAlt = 0
		end
	end
end

besiege.onUpdate = function()
	tG:update()

	if state == "activatingEngines" then
		activateEngines()
	elseif state == "deactivatingEngines" then
		deactivateEngines()
	end

end


function changeState(oldState, event)
	a = fsm[oldState][event]
	a.action()
	state = a.new
end
