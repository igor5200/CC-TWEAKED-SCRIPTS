local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")
local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")

if not front or not back or not left or not right then
    print("Brakuje Speed Controllera!")
    return
end

-- =========================================
-- SETTINGS
-- =========================================

local BASE_RPM = 30
local TEST_DELTA = 10
local TEST_TIME = 2

-- =========================================
-- MOTOR CONTROL
-- =========================================

local function setMotors(f, b, l, r)
    front.setTargetSpeed(f)
    back.setTargetSpeed(b)
    left.setTargetSpeed(l)
    right.setTargetSpeed(r)
end

local function stopMotors()
    setMotors(0, 0, 0, 0)
end

-- =========================================
-- GPS
-- =========================================

local function getGPS()
    local x, y, z = gps.locate(3)

    if not x then
        return nil
    end

    return {
        x = x,
        y = y,
        z = z
    }
end

-- =========================================
-- VECTOR
-- =========================================

local function difference(a, b)
    return {
        x = b.x - a.x,
        y = b.y - a.y,
        z = b.z - a.z
    }
end

local function printVector(v)
    print(string.format(
        "dX = %+7.3f  dY = %+7.3f  dZ = %+7.3f",
        v.x,
        v.y,
        v.z
    ))
end

-- =========================================
-- TEST
-- =========================================

local function test(name, f, b, l, r)

    print("")
    print("================================")
    print("TEST: " .. name)
    print("================================")

    stopMotors()

    sleep(1)

    local start = getGPS()

    if not start then
        print("Brak GPS!")
        return nil
    end

    print(string.format(
        "START: %.2f %.2f %.2f",
        start.x,
        start.y,
        start.z
    ))

    print("")
    print("Silniki:")
    print("FRONT = " .. f)
    print("BACK  = " .. b)
    print("LEFT  = " .. l)
    print("RIGHT = " .. r)

    print("")
    print("Uruchamiam test...")

    setMotors(f, b, l, r)

    local startTime = os.clock()

    while os.clock() - startTime < TEST_TIME do
        sleep(0.1)
    end

    stopMotors()

    sleep(1)

    local finish = getGPS()

    if not finish then
        print("Brak GPS po tescie!")
        return nil
    end

    local delta = difference(start, finish)

    print("")
    print("WYNIK:")
    printVector(delta)

    return delta
end

-- =========================================
-- START
-- =========================================

term.clear()
term.setCursorPos(1, 1)

print("========================================")
print("       DRONE MOTOR MIXER CALIBRATION")
print("========================================")
print("")
print("BASE RPM: " .. BASE_RPM)
print("TEST DELTA: " .. TEST_DELTA)
print("")
print("Dron musi miec wolna przestrzen!")
print("")
print("ENTER aby rozpoczac")

read()

-- =========================================
-- BASE TEST
-- =========================================

print("")
print("Sprawdzam bazowy ciag...")

local base = getGPS()

if not base then
    print("Brak GPS!")
    return
end

setMotors(
    BASE_RPM,
    BASE_RPM,
    BASE_RPM,
    BASE_RPM
)

sleep(2)

stopMotors()

local baseEnd = getGPS()

if baseEnd then
    local delta = difference(base, baseEnd)

    print("")
    print("BAZOWY RUCH:")
    printVector(delta)
end

sleep(1)

-- =========================================
-- PITCH FORWARD
-- =========================================

local pitchPlus = test(
    "PITCH +",
    BASE_RPM + TEST_DELTA,
    BASE_RPM - TEST_DELTA,
    BASE_RPM,
    BASE_RPM
)

print("")
print("ENTER aby kontynuowac")

read()

-- =========================================
-- PITCH BACKWARD
-- =========================================

local pitchMinus = test(
    "PITCH -",
    BASE_RPM - TEST_DELTA,
    BASE_RPM + TEST_DELTA,
    BASE_RPM,
    BASE_RPM
)

print("")
print("ENTER aby kontynuowac")

read()

-- =========================================
-- ROLL RIGHT
-- =========================================

local rollPlus = test(
    "ROLL +",
    BASE_RPM,
    BASE_RPM,
    BASE_RPM + TEST_DELTA,
    BASE_RPM - TEST_DELTA
)

print("")
print("ENTER aby kontynuowac")

read()

-- =========================================
-- ROLL LEFT
-- =========================================

local rollMinus = test(
    "ROLL -",
    BASE_RPM,
    BASE_RPM,
    BASE_RPM - TEST_DELTA,
    BASE_RPM + TEST_DELTA
)

-- =========================================
-- END
-- =========================================

stopMotors()

print("")
print("")
print("========================================")
print("             CALIBRATION DONE")
print("========================================")

print("")
print("PITCH +:")

if pitchPlus then
    printVector(pitchPlus)
end

print("")
print("PITCH -:")

if pitchMinus then
    printVector(pitchMinus)
end

print("")
print("ROLL +:")

if rollPlus then
    printVector(rollPlus)
end

print("")
print("ROLL -:")

if rollMinus then
    printVector(rollMinus)
end

print("")
print("Wszystkie silniki zatrzymane.")
