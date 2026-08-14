local top   = peripheral.wrap("Create_RotationSpeedController_0")
local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")
local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")

local HOVER_RPM = 111
local TEST_RPM = 20
local TEST_TIME = 3
local PAUSE = 2

local function stopSides()
    front.setTargetSpeed(0)
    back.setTargetSpeed(0)
    left.setTargetSpeed(0)
    right.setTargetSpeed(0)
end

local function test(name, propeller, rpm)
    print("TEST: " .. name .. " | " .. rpm .. " RPM")

    propeller.setTargetSpeed(rpm)

    sleep(TEST_TIME)

    propeller.setTargetSpeed(0)

    print(name .. " STOP")
    sleep(PAUSE)
end

stopSides()

-- Główny ciąg
top.setTargetSpeed(HOVER_RPM)

print("Hover...")
sleep(5)

-- Kierunki obrotu śmigieł
test("FRONT", front,  TEST_RPM)
test("BACK",  back,  -TEST_RPM)
test("LEFT",  left,  -TEST_RPM)
test("RIGHT", right,  TEST_RPM)

stopSides()

print("TEST ZAKONCZONY")
