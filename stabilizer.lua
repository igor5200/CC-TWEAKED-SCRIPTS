local top   = peripheral.wrap("Create_RotationSpeedController_0")
local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")
local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")

local HOVER_RPM = 111
local MOVE_RPM = 20

local MOVE_TIME = 3
local PAUSE_TIME = 2

local function stopSides()
    front.setTargetSpeed(0)
    back.setTargetSpeed(0)
    left.setTargetSpeed(0)
    right.setTargetSpeed(0)
end

local function hover()
    stopSides()
    top.setTargetSpeed(HOVER_RPM)
    sleep(PAUSE_TIME)
end

local function forward()
    front.setTargetSpeed(MOVE_RPM)
    back.setTargetSpeed(-MOVE_RPM)
    left.setTargetSpeed(0)
    right.setTargetSpeed(0)

    sleep(MOVE_TIME)

    stopSides()
end

local function backward()
    front.setTargetSpeed(-MOVE_RPM)
    back.setTargetSpeed(MOVE_RPM)
    left.setTargetSpeed(0)
    right.setTargetSpeed(0)

    sleep(MOVE_TIME)

    stopSides()
end

local function leftMove()
    front.setTargetSpeed(0)
    back.setTargetSpeed(0)
    left.setTargetSpeed(-MOVE_RPM)
    right.setTargetSpeed(MOVE_RPM)

    sleep(MOVE_TIME)

    stopSides()
end

local function rightMove()
    front.setTargetSpeed(0)
    back.setTargetSpeed(0)
    left.setTargetSpeed(MOVE_RPM)
    right.setTargetSpeed(-MOVE_RPM)

    sleep(MOVE_TIME)

    stopSides()
end

-- START
stopSides()
top.setTargetSpeed(HOVER_RPM)

print("Dron startuje...")
sleep(5)

print("PRZOD")
forward()
hover()

print("TYŁ")
backward()
hover()

print("LEWO")
leftMove()
hover()

print("PRAWO")
rightMove()
hover()

print("TEST ZAKONCZONY")

stopSides()
top.setTargetSpeed(0)
