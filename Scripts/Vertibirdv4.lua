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

	if self.latVal > 2 then
		self.rotate(self.c[2], 2)
	elseif self.latVal < -2 then
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

local idleThrustPercent = 20
local incAltThrustPercent = 50
local decAltThrustPercent = 20
local lEngThrustPercent = 0
local rEngThrustPercent = 0
local targetAlt = 0

function enginesInactive()
	besiege.log("Engines inactive")
end

function activateEngines()
	if lEngThrustPercent < idleThrustPercent then
		lEng:adjThrustTo(rEngThrustPercent + 0.2)
		lEngThrustPercent = lEngThrustPercent + 0.2
		if(lEngThrustPercent > idleThrustPercent) then
			lEngThrustPercent = idleThrustPercent
		end
	end

	if rEngThrustPercent < idleThrustPercent then
		rEng:adjThrustTo(rEngThrustPercent + 0.2)
		rEngThrustPercent = rEngThrustPercent + 0.2
		if(rEngThrustPercent > idleThrustPercent) then
			rEngThrustPercent = idleThrustPercent
		end
	end
end

function deactivateEngines()
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
end

function idling()

end

-- will be updated with a logistic algorithm
function increaseAltitude()
	if lEngThrustPercent < incAltThrustPercent then
		lEng:adjThrustTo(lEngThrustPercent + 0.2)
		lEngThrustPercent = lEngThrustPercent + 0.2
	end
	if rEngThrustPercent < incAltThrustPercent then
		rEng:adjThrustTo(rEngThrustPercent + 0.2)
		rEngThrustPercent = rEngThrustPercent + 0.2
	end
end 

-- will be updated with a logistic algorithm
function decreaseAltitude()
	if lEngThrustPercent > decAltThrustPercent then
		lEng:adjThrustTo(lEngThrustPercent - 0.4)
		lEngThrustPercent = lEngThrustPercent - 0.4
	end
	if rEngThrustPercent > decAltThrustPercent then
		rEng:adjThrustTo(rEngThrustPercent - 0.4)
		rEngThrustPercent = rEngThrustPercent - 0.4
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
	{"activatingEngines", "engineActivationComplete", "idle", idling},
	{"deactivatingEngines", "enginesActivatedDuringDeactivation", "activatingEngines", activateEngines},
	{"idle", "engineDeactivatedDuringIdle", "deactivatingEngines", deactivateEngines},
	{"idle", "targetAltitudeSetAboveCurrentAltitude", "increaseAltitude", increaseAltitude},
	{"increaseAltitude", "targetAltitudeBelowCurrentAltitude", "decreaseAltitude", decreaseAltitude},
	{"decreaseAltitude", "targetAltitudeAboveCurrentAltitude", "increaseAltitude", increaseAltitude},
	{"decreaseAltitude", "targetAltZeroAndVertibirdLanded", "idle", idling}
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
		besiege.log("Target altitude: " .. targetAlt)
	end 

	if keyCode == besiege.keyCodes.keypadMinus then
		targetAlt = targetAlt - 5
		if targetAlt < 0 then
			targetAlt = 0
		end
		besiege.log("Target altitude: " .. targetAlt)
	end
end

local activationLog = {false}
local deactivationLog = {false}
local idleLog = {false}
local increaseAltitudeLog = {false}
local decreaseAltitudeLog = {false}

besiege.onUpdate = function()
	tG:update()
	if state == "activatingEngines" then		
		logStatus(activationLog, "Engines activated")
		deactivationLog[1] = false
		activateEngines()
		if(lEngThrustPercent == idleThrustPercent and rEngThrustPercent == idleThrustPercent) then
			changeState("activatingEngines", "engineActivationComplete")
		end

	elseif state == "deactivatingEngines" then
		logStatus(deactivationLog, "Engines deactivated")
		activationLog[1] = false
		idleLog[1] = false
		deactivateEngines()

		if(lEngThrustPercent == 0 and rEngThrustPercent == 0) then
			changeState("inactive", "enginesDeactivated")
		end

	elseif state == "idle" then
		logStatus(idleLog, "Engines idling")
		activationLog[1] = false
		decreaseAltitudeLog[1] = false
		idling()

		if targetAlt > 0 then
			changeState("idle", "targetAltitudeSetAboveCurrentAltitude")
		end

	elseif state == "increaseAltitude" then
		logStatus(increaseAltitudeLog, "Increasing altitude")
		idleLog[1] = false
		decreaseAltitudeLog[1] = false
		increaseAltitude()

		if targetAlt < besiege.getPositionY(0) then
			changeState("increaseAltitude", "targetAltitudeBelowCurrentAltitude")
		end

	elseif state == "decreaseAltitude" then
		logStatus(decreaseAltitudeLog, "Decreasing altitude")
		increaseAltitudeLog[1] = false
		decreaseAltitude()
		
		if targetAlt == 0 and besiege.getPositionY(0) < 3 then
			changeState("decreaseAltitude", "targetAltZeroAndVertibirdLanded")
		end
		if targetAlt > besiege.getPositionY(0) then
			changeState("decreaseAltitude", "targetAltitudeAboveCurrentAltitude")
		end
	end
end

function changeState(oldState, event)
	a = fsm[oldState][event]
	a.action()
	state = a.new
end

function logStatus(log, msg)
	if log[1] == false then
		log[1] = true
		besiege.log(msg)
	end
end