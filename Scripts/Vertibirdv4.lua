
--------------------------------------------------------------------------------
-- COMPONENT DEFINES
--------------------------------------------------------------------------------
-- Due to the fact that if you make any change to the vehicle, the order and ID's
-- of the components can change. This should shield the script from this as only 
-- the ID's will need to be changed here and not throughout the entire script. 

--------------------
-- Gyroscope
--------------------
-- front
local fGyroWheelA = 108
local fGyroWheelB = 109
local fGyroWheelC = 110
local fGyroWheelD = 111
local fGyroWheelE = 112

-- center
local cGyroWheelA = 105
local cGyroWheelB = 104
local cGyroWheelC = 103
local cGyroWheelD = 102
local cGyroWheelE = 101
local cGyroWheelF = 100

-- back
local bGyroWheelA = 117
local bGyroWheelB = 116
local bGyroWheelC = 115
local bGyroWheelD = 114
local bGyroWheelE = 113

-- left
local lGyroWheelA = 123
local lGyroWheelB = 124
local lGyroWheelC = 125
local lGyroWheelD = 126
local lGyroWheelE = 127

-- right
local rGyroWheelA = 122
local rGyroWheelB = 121
local rGyroWheelC = 120
local rGyroWheelD = 119
local rGyroWheelE = 118

-- points
local fGyroPt = 107
local cTGyroPt = 128 
local cBGyroPt = 99
local bGyroPt = 106
local lGyroPt = 97
local rGyroPt = 27

--------------------
-- Left Engine
--------------------
local lTEngSBlock = 52
local lTEngSBlade = 54
local lTEngWheel = 50
local lBEngWheel = 56
local lBEngSBlade = 61
local lBEngSBlock = 59

--------------------
-- Right Engine
--------------------
local rTEngSBlock = 51
local rTEngSBlade = 53
local rTEngWheel = 49
local rBEngWheel = 57
local rBEngSBlade = 60
local rBEngSBlock = 58

besiege.setSliderValue(lTEngSBlade, 0) -- left top sawblade
besiege.setSliderValue(lBEngSBlade, 0) -- left bottom sawblade
besiege.setSliderValue(rTEngSBlade, 0) -- right top sawblade
besiege.setSliderValue(rBEngSBlade, 0) -- right bottom sawblade

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

	if keyCode == besiege.keyCodes.keypadPlus then
		if plannedAlt < maxAlt then
			plannedAlt = plannedAlt + 1
		end
	end

	if keyCode == besiege.keyCodes.keypadMinus then
		if plannedAlt >= 1 then
			plannedAlt = plannedAlt - 1
		end
	end
end

besiege.onUpdate = function()
	if engStart == true then
		if engStartComplete == false then
			startEngines()
		end
	end

	if besiege.getRoll(lGyroPt, rGyroPt) > 5 then
		adjRoll(2)
		-- besiege.log("Roll: " .. besiege.getRoll(lGyroPt, rGyroPt) .. " -- Positive?")
	elseif besiege.getRoll(lGyroPt, rGyroPt) < -5 then
		adjRoll(-2)
		-- besiege.log("roll: " .. besiege.getRoll(lGyroPt, rGyroPt) .. " -- Negative?")
	else
		adjRoll(0)
	end

	if besiege.getPitch(fGyroPt, bGyroPt) > 5 then
		adjPitch(2)

	elseif besiege.getPitch(fGyroPt, bGyroPt) < -5 then
		adjPitch(-2)
	else
		adjPitch(0)
	end

	if (besiege.getPositionY(0) < plannedAlt) then
		increaseThrust()
	end 

	if (besiege.getPositionY(0) > plannedAlt) then
		decreaseThrust()
	end
end

function startEngines()
	increaseComponentSpeed(lTEngWheel, lBEngWheel, lEngWheelSpeed, engWheelIdleSpeed, .001, lEngWheelIdling)
	increaseComponentSpeed(lTEngSBlade, lBEngSBlade, lEngSBladeSpeed, engSBladeIdleSpeed, .001, lEngSBladeIdling)
	increaseComponentSpeed(lTEngSBlock, lBEngSBlock, lEngSBlockSpeed, engSBlockIdleSpeed, .001, lEngSBlockIdling)

	increaseComponentSpeed(rTEngWheel, rBEngWheel, rEngWheelSpeed, engWheelIdleSpeed, .001, rEngWheelIdling)
	increaseComponentSpeed(rTEngSBlade, rBEngSBlade, rEngSBladeSpeed, engSBladeIdleSpeed, .001, rEngSBladeIdling)
	increaseComponentSpeed(rTEngSBlock, rBEngSBlock, rEngSBlockSpeed, engSBlockIdleSpeed, .001, rEngSBlockIdling)

	if lEngWheelIdling[1] and lEngSBladeIdling[1] and lEngSBlockIdling[1] then
		if rEngWheelIdling[1] and rEngSBladeIdling[1] and rEngSBlockIdling[1] then
			engStartComplete = true
		end 
	end 
end

-- negative speed rolls right
-- positive speed rolls left
function adjRoll(speed)
	besiege.setSliderValue(fGyroWheelA, speed)
	besiege.setSliderValue(fGyroWheelB, speed)
	besiege.setSliderValue(fGyroWheelC, speed)
	besiege.setSliderValue(fGyroWheelD, speed)
	besiege.setSliderValue(fGyroWheelE, speed)
	besiege.setSliderValue(bGyroWheelA, speed)
	besiege.setSliderValue(bGyroWheelB, speed)
	besiege.setSliderValue(bGyroWheelC, speed)
	besiege.setSliderValue(bGyroWheelD, speed)
	besiege.setSliderValue(bGyroWheelE, speed)
end

-- negative speed increases pitch angle
-- positive speed decreases pitch angle
function adjPitch(speed)
	besiege.setSliderValue(lGyroWheelA, speed)
	besiege.setSliderValue(lGyroWheelB, speed)
	besiege.setSliderValue(lGyroWheelC, speed)
	besiege.setSliderValue(lGyroWheelD, speed)
	besiege.setSliderValue(lGyroWheelE, speed)
	besiege.setSliderValue(rGyroWheelA, speed)
	besiege.setSliderValue(rGyroWheelB, speed)
	besiege.setSliderValue(rGyroWheelC, speed)
	besiege.setSliderValue(rGyroWheelD, speed)
	besiege.setSliderValue(rGyroWheelE, speed)
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