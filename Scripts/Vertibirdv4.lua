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
	self.thrustPercent = 0
	self.idleThrustPercent = 20
	self.raiseAltThrustPercent = 50
	self.lowerAltThrustPercent = 20

	function Engine:adjThrustTo(val)
		for i, v in pairs(self.c) do
			v[2] = v[3] / 100 * val
			besiege.setSliderValue(v[1], v[2])
		end
	end

	return self
end

function Engine:getThrust()
	return self.thrustPercent
end

function Engine:getIdleThrustPercent()
	return self.idleThrustPercent
end

function Engine:activate()
	if self.thrustPercent < self.idleThrustPercent then
		self:adjThrustTo(self.thrustPercent + 0.2)
		self.thrustPercent = self.thrustPercent + 0.2
		if(self.thrustPercent > self.idleThrustPercent) then
			self.thrustPercent = self.idleThrustPercent
		end
	end
end

function Engine:deactivate()
	if self.thrustPercent > 0 then
		self:adjThrustTo(self.thrustPercent - 0.2)
		self.thrustPercent = self.thrustPercent - 0.2
		if(self.thrustPercent < 0) then
			self.thrustPercent = 0
		end
	end
end

-- will be updated with a logistic algorithm
function Engine:increaseAltitude()
	if self.thrustPercent < self.raiseAltThrustPercent then
		self:adjThrustTo(self.thrustPercent + 0.2)
		self.thrustPercent = self.thrustPercent + 0.2
	end
end

-- will be updated with a logistic algorithm
function Engine:decreaseAltitude()
	if self.thrustPercent > self.lowerAltThrustPercent then
		self:adjThrustTo(self.thrustPercent - 0.4)
		self.thrustPercent = self.thrustPercent - 0.4
	end
end

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

local targetAlt = 0

function enginesInactive()
	besiege.log("Engines inactive")
end

function activateEngines()
	lEng:activate()
	rEng:activate()
end

function deactivateEngines()
	lEng:deactivate()
	rEng:deactivate()
end

function idling() end

function increaseAltitude()
	lEng:increaseAltitude()
	rEng:increaseAltitude()
end 

function decreaseAltitude()
	lEng:decreaseAltitude()
	rEng:decreaseAltitude()
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
		if lEng:getThrust() == lEng:getIdleThrustPercent() and rEng:getThrust() == rEng:getIdleThrustPercent() then
			changeState("activatingEngines", "engineActivationComplete")
		end

	elseif state == "deactivatingEngines" then
		logStatus(deactivationLog, "Engines deactivated")
		activationLog[1] = false
		idleLog[1] = false
		deactivateEngines()

		if lEng:getThrust() == 0 and rEng:getThrust() == 0 then
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