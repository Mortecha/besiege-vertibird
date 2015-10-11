
--------------------------------------------------------------------------------
-- COMPONENT DEFINES
--------------------------------------------------------------------------------
-- Due to the fact that if you make any change to the vehicle, the order and ID's
-- of the components can change. This should shield the script from this as only 
-- the ID's will need to be changed here and not throughout the entire script. 

------------------------------
-- Gyroscope Component IDs
------------------------------
local rollGyro = {107, 108, 109, 110, 111, 116, 115, 114, 113, 112}
local yawGyro = {104, 103, 102, 101, 100, 99, 165, 164}
local pitchGyro = {122, 123, 124, 125, 126, 121, 120, 119, 118, 117}

-- points
local fGyroPt = 106
local cTGyroPt = 127 
local cBGyroPt = 0
local bGyroPt = 105
local lGyroPt = 97
local rGyroPt = 27

------------------------------
-- Left Engine Component IDs
------------------------------
local lTEngSBlock = 52
local lTEngSBlade = 54
local lTEngWheel = 50
local lBEngWheel = 56
local lBEngSBlade = 61
local lBEngSBlock = 59

------------------------------
-- Right Engine Component IDs
------------------------------
local rTEngSBlock = 51
local rTEngSBlade = 53
local rTEngWheel = 49
local rBEngWheel = 57
local rBEngSBlade = 60
local rBEngSBlock = 58

--------------------------------------------------------------------------------

besiege.setSliderValue(lTEngSBlade, 0) -- left top sawblade
besiege.setSliderValue(lBEngSBlade, 0) -- left bottom sawblade
besiege.setSliderValue(rTEngSBlade, 0) -- right top sawblade
besiege.setSliderValue(rBEngSBlade, 0) -- right bottom sawblade

local engInitLog = false
local engStart = false
local engStartComplete = false

-- engine component speed initialisations
local lEngWheelSpeed = {0}
local lEngSBladeSpeed = {0}
local lEngSBlockSpeed = {0}
local rEngWheelSpeed = {0}
local rEngSBladeSpeed = {0}
local rEngSBlockSpeed = {0}

-- bounds for engine component speeds to maintain position on ground
local engWheelIdleSpeed = 0.25
local engSBladeIdleSpeed = 0.3
local engSBlockIdleSpeed = 0.25

-- engine component idle states
local lEngWheelIdling = {false}
local lEngSBladeIdling = {false}
local lEngSBlockIdling = {false}
local rEngWheelIdling = {false}
local rEngSBladeIdling = {false}
local rEngSBlockIdling = {false}

-- bounds for engine component speeds to prevent blade damage
local engWheelMaxSpeed = 2
local engSBladeMaxSpeed = 0.85
local engSBlockMaxSpeed = 2

-- bound for engine accent speed to reduce bopping when machine tries to accend to specific alt
local engWheelAccSpeed = 0.3
local engSBladeAccSpeed = 0.4
local engSBlockAccSpeed = 0.3

-- bounds for engine component speeds to prevent vehicle falling out of the sky during descents
local engWheelDescentSpeed = 0.2
local engSBladeDescentSpeed = 0.25
local engSBlockDescentSpeed = 0.2

-- specifications for engine component hover speeds 

-- variables concerning altitude
local plannedAlt = 1
local maxAlt = 100

besiege.onKeyDown = function(keyCode)
	if keyCode == besiege.keyCodes.z then
		if engStart == false then
			engStart = true
		elseif engStart == true then
			engStart = false
		end
	end
end

besiege.onKeyHeld = function(keyCode)
	if keyCode == besiege.keyCodes.keypadPlus then
		if plannedAlt < maxAlt then
			plannedAlt = plannedAlt + 10
			besiege.log("Ascending to: " .. plannedAlt .. " units")
		end
	end 

	if keyCode == besiege.keyCodes.keypadMinus then
		if plannedAlt >= 1 then
			plannedAlt = plannedAlt - 10
			besiege.log("Descending to: " .. plannedAlt .. " units")
		end
	end
end

besiege.onUpdate = function()
	if engStart == true then
		if engStartComplete == false then
			if engInitLog == false then
				engInitLog = true
				besiege.log("Starting engines - Beginning start sequence")
			end
			startEngines()
		end
	end

	if besiege.getRoll(lGyroPt, rGyroPt) > 5 then
		adjAxis(rollGyro, 2)
	elseif besiege.getRoll(lGyroPt, rGyroPt) < -5 then
		adjAxis(rollGyro, -2)
	else
		adjAxis(rollGyro, 0)
	end

	if besiege.getPitch(fGyroPt, bGyroPt) > 5 then
		adjAxis(pitchGyro, 2)

	elseif besiege.getPitch(fGyroPt, bGyroPt) < -5 then
		adjAxis(pitchGyro, -2)
	else
		adjAxis(pitchGyro, 0)
	end

	if besiege.getPositionY(0) < plannedAlt then
		increaseThrust()
	elseif besiege.getPositionY(0) > plannedAlt then
		decreaseThrust()
	end
end

function startEngines()
	increaseComponentSpeed(lTEngWheel, lBEngWheel, lEngWheelSpeed, engWheelIdleSpeed, .004, lEngWheelIdling)
	increaseComponentSpeed(lTEngSBlade, lBEngSBlade, lEngSBladeSpeed, engSBladeIdleSpeed, .004, lEngSBladeIdling)
	increaseComponentSpeed(lTEngSBlock, lBEngSBlock, lEngSBlockSpeed, engSBlockIdleSpeed, .004, lEngSBlockIdling)

	increaseComponentSpeed(rTEngWheel, rBEngWheel, rEngWheelSpeed, engWheelIdleSpeed, .004, rEngWheelIdling)
	increaseComponentSpeed(rTEngSBlade, rBEngSBlade, rEngSBladeSpeed, engSBladeIdleSpeed, .004, rEngSBladeIdling)
	increaseComponentSpeed(rTEngSBlock, rBEngSBlock, rEngSBlockSpeed, engSBlockIdleSpeed, .004, rEngSBlockIdling)

	if lEngWheelIdling[1] and lEngSBladeIdling[1] and lEngSBlockIdling[1] then
		if rEngWheelIdling[1] and rEngSBladeIdling[1] and rEngSBlockIdling[1] then
			engStartComplete = true
			besiege.log("Engines idling - Start sequence complete")
		end 
	end 
end

function adjAxis(gyro, speed)
	for i, v in pairs(gyro) do
		besiege.setSliderValue(v, speed)
	end
end

function increaseThrust()
	if engStartComplete == true then
		increaseComponentSpeed(lTEngWheel, lBEngWheel, lEngWheelSpeed, engWheelAccSpeed, .008)
		increaseComponentSpeed(lTEngSBlade, lBEngSBlade, lEngSBladeSpeed, engSBladeAccSpeed, .008)
		increaseComponentSpeed(lTEngSBlock, lBEngSBlock, lEngSBlockSpeed, engSBlockAccSpeed, .008)

		increaseComponentSpeed(rTEngWheel, rBEngWheel, rEngWheelSpeed, engWheelAccSpeed, .008)
		increaseComponentSpeed(rTEngSBlade, rBEngSBlade, rEngSBladeSpeed, engSBladeAccSpeed, .008)
		increaseComponentSpeed(rTEngSBlock, rBEngSBlock, rEngSBlockSpeed, engSBlockAccSpeed, .008)
	end
end 

function decreaseThrust()
	if engStartComplete == true then
		decreaseComponentSpeed(lTEngWheel, lBEngWheel, lEngWheelSpeed, engWheelDescentSpeed, .008)
		decreaseComponentSpeed(lTEngSBlade, lBEngSBlade, lEngSBladeSpeed, engSBladeDescentSpeed, .008)
		decreaseComponentSpeed(lTEngSBlock, lBEngSBlock, lEngSBlockSpeed, engSBlockDescentSpeed, .008)

		decreaseComponentSpeed(rTEngWheel, rBEngWheel, rEngWheelSpeed, engWheelDescentSpeed, .008)
		decreaseComponentSpeed(rTEngSBlade, rBEngSBlade, rEngSBladeSpeed, engSBladeDescentSpeed, .008)
		decreaseComponentSpeed(rTEngSBlock, rBEngSBlock, rEngSBlockSpeed, engSBlockDescentSpeed, .008)
	end 
end 

-- componentID - the component to increase speed of
-- inverseComponentID - OPTIONAL - for counterprop aircraft where component has matching inverse component
	-- must specify nil when not in use
-- componentSpeed - components current speed
-- maxSpeed - the limit to how fast the component can spin for state
-- incrementAmount - the amount to increment speed by
-- state - OPTIONAL - the state you wish to make true when if condition false
function increaseComponentSpeed(componentID, inverseComponentID, componentSpeed, maxSpeed, incrementAmount, state)
	if componentSpeed[1] < maxSpeed then
		componentSpeed[1] = componentSpeed[1] + incrementAmount
		besiege.setSliderValue(componentID, componentSpeed[1])
		if inverseComponentID ~= nil then
			besiege.setSliderValue(inverseComponentID, componentSpeed[1])
		end
	else
		if state ~= nil then
			state[1] = true
		end
	end
end

-- componentID - the component to decrease speed of
-- inverseComponentID - OPTIONAL - for counterprop aircraft where component has matching inverse component
	-- must specify nil when not in use
-- componentSpeed - components current speed
-- maxSpeed - the limit to how slow the component can spin for state
-- incrementAmount - the amount to decriment speed by
-- state - OPTIONAL - the state you wish to make true when if condition false 
function decreaseComponentSpeed(componentID, inverseComponentID, componentSpeed, minSpeed, decrimentAmount, state )
	if componentSpeed[1] > minSpeed then
		componentSpeed[1] = componentSpeed[1] - decrimentAmount
		besiege.setSliderValue(componentID, componentSpeed[1])
		if inverseComponentID ~= nil then
			besiege.setSliderValue(inverseComponentID, componentSpeed[1])
		end
	else 
		if state ~= nil then
			state[1] = true
		end
	end
end
