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
local PAUSE = 2

local function stopSides()
    front.setTargetSpeed(0)
    back.setTargetSpeed(0)
    left.setTargetSpeed(0)
    right.setTargetSpeed(0)
end

local function test(name, propeller)
    print("TEST: " .. name)
    print("RPM: " .. TEST_RPM)

    propeller.setTargetSpeed(TEST_RPM)

    sleep(TEST_TIME)

    propeller.setTargetSpeed(0)

    print(name .. " STOP")
    sleep(PAUSE)
end

-- Wszystkie boczne wyłączone
stopSides()

-- Uruchomienie głównego ciągu
top.setTargetSpeed(HOVER_RPM)

print("=== DRONE PROP TEST ===")
print("Hover RPM: " .. HOVER_RPM)
print("Stabilizacja...")
sleep(5)

-- FRONT
test("FRONT", front)

-- BACK
test("BACK", back)

-- LEFT
test("LEFT", left)

-- RIGHT
test("RIGHT", right)

-- Koniec
stopSides()

print("=== TEST ZAKONCZONY ===")
print("TOP nadal pracuje na " .. HOVER_RPM .. " RPM")
