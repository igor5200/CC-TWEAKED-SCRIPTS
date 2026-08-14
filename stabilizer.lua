local top   = peripheral.wrap("Create_RotationSpeedController_0")
local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")
local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")

if not top then error("Brak top") end
if not front then error("Brak front") end
if not back then error("Brak back") end
if not left then error("Brak left") end
if not right then error("Brak right") end

local HOVER_RPM = 111
local TEST_RPM = 20
local TEST_TIME = 3

-- Wszystkie boczne wyłączone
front.setTargetSpeed(0)
back.setTargetSpeed(0)
left.setTargetSpeed(0)
right.setTargetSpeed(0)

-- Start zawisu
top.setTargetSpeed(HOVER_RPM)

print("Dron startuje...")
print("Zawis za 3 sekundy")

sleep(3)

print("FRONT -> " .. TEST_RPM .. " RPM")

front.setTargetSpeed(TEST_RPM)

sleep(TEST_TIME)

print("FRONT STOP")

front.setTargetSpeed(0)

print("Test zakonczony")
print("Dron pozostaje na hover RPM")
