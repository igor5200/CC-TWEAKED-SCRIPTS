-- ============================================================
-- DRONE STABILIZER v3
--
-- Create Aeronautics / Avionics
-- CC:Tweaked
--
-- 4x RSC:
--   front
--   back
--   left
--   right
--
-- Gimbal Sensor:
--   pitch
--   roll
--   pitch rate
--   roll rate
--
-- AUTOMATYCZNA KALIBRACJA
-- ============================================================


-- ============================================================
-- PERIPHERALS
-- ============================================================

local sensor = peripheral.find("gimbal_sensor")

local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")
local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")


if not sensor then
    error("Brak gimbal_sensor")
end

if not front then
    error("Brak RSC: front")
end

if not back then
    error("Brak RSC: back")
end

if not left then
    error("Brak RSC: left")
end

if not right then
    error("Brak RSC: right")
end


-- ============================================================
-- SETTINGS
-- ============================================================

-- USTAW NA RPM, PRZY KTÓRYM DRON POTRAFI ZAWISAĆ
local BASE_RPM = 140

-- Wielkość impulsu kalibracyjnego
local TEST_RPM = 8

-- Czas impulsu
local TEST_TIME = 0.20

-- Czas stabilizacji pomiędzy testami
local SETTLE_TIME = 0.30


-- ============================================================
-- PD
-- ============================================================

local KP_PITCH = 30
local KD_PITCH = 8

local KP_ROLL = 30
local KD_ROLL = 8


-- Maksymalna korekta od BASE
local MAX_CORRECTION = 35

local MAX_RPM = 256

local DT = 0.05


-- ============================================================
-- UTILITY
-- ============================================================

local function clamp(x, minValue, maxValue)

    if x < minValue then
        return minValue
    end

    if x > maxValue then
        return maxValue
    end

    return x

end


local function setAll(rpm)

    front.setTargetSpeed(rpm)
    back.setTargetSpeed(rpm)
    left.setTargetSpeed(rpm)
    right.setTargetSpeed(rpm)

end


-- ============================================================
-- MOTOR TABLE
-- ============================================================

local motors = {
    {
        name = "front",
        rsc = front
    },

    {
        name = "back",
        rsc = back
    },

    {
        name = "left",
        rsc = left
    },

    {
        name = "right",
        rsc = right
    }
}


-- ============================================================
-- SENSOR
-- ============================================================

local function readSensor()

    local angles = sensor.getAnglesRad()
    local rates = sensor.getAngularRatesRad()

    return {
        pitch = angles[1],
        roll = angles[2],

        pitchRate = rates[1],
        rollRate = rates[3]
    }

end


-- ============================================================
-- START
-- ============================================================

term.clear()
term.setCursorPos(1, 1)

print("================================")
print("       DRONE STABILIZER v3")
print("================================")
print("")
print("BASE RPM:", BASE_RPM)
print("")
print("Automatyczna kalibracja")
print("rozpocznie sie za 3 sekundy.")
print("")

sleep(1)
print("3...")
sleep(1)
print("2...")
sleep(1)
print("1...")


-- ============================================================
-- BASE RPM
-- ============================================================

setAll(BASE_RPM)

sleep(1)


-- ============================================================
-- CALIBRATION
-- ============================================================

print("")
print("================================")
print("         KALIBRACJA")
print("================================")
print("")


local effects = {}


for i, data in ipairs(motors) do

    print("TEST:", data.name)

    -- Wszystkie na BASE
    setAll(BASE_RPM)

    sleep(SETTLE_TIME)


    -- --------------------------------
    -- Odczyt przed impulsem
    -- --------------------------------

    local before = readSensor()


    -- --------------------------------
    -- Impuls
    -- --------------------------------

    data.rsc.setTargetSpeed(
        BASE_RPM + TEST_RPM
    )

    sleep(TEST_TIME)


    -- --------------------------------
    -- Odczyt po impulsie
    -- --------------------------------

    local after = readSensor()


    -- --------------------------------
    -- Powrót
    -- --------------------------------

    data.rsc.setTargetSpeed(BASE_RPM)

    sleep(SETTLE_TIME)


    -- --------------------------------
    -- Efekt
    -- --------------------------------

    local pitchDelta =
        after.pitchRate - before.pitchRate

    local rollDelta =
        after.rollRate - before.rollRate


    local pitchEffect =
        pitchDelta / TEST_RPM

    local rollEffect =
        rollDelta / TEST_RPM


    effects[i] = {
        pitch = pitchEffect,
        roll = rollEffect
    }


    print(
        string.format(
            "%s P: %.6f R: %.6f",
            data.name,
            pitchEffect,
            rollEffect
        )
    )

    print("")

end


-- ============================================================
-- PRINT MATRIX
-- ============================================================

print("================================")
print("      WYNIK KALIBRACJI")
print("================================")
print("")

for i, data in ipairs(motors) do

    print(
        string.format(
            "%-6s P:% .6f R:% .6f",
            data.name,
            effects[i].pitch,
            effects[i].roll
        )
    )

end


-- ============================================================
-- FIND PITCH / ROLL AUTHORITY
-- ============================================================

local pitchMax = 0
local rollMax = 0


for i = 1, 4 do

    pitchMax = math.max(
        pitchMax,
        math.abs(effects[i].pitch)
    )

    rollMax = math.max(
        rollMax,
        math.abs(effects[i].roll)
    )

end


print("")
print("Pitch max:", pitchMax)
print("Roll max :", rollMax)


if pitchMax < 0.000001 then

    setAll(0)

    error(
        "Nie wykryto sterowania PITCH"
    )

end


if rollMax < 0.000001 then

    setAll(0)

    error(
        "Nie wykryto sterowania ROLL"
    )

end


-- ============================================================
-- NORMALIZATION
-- ============================================================
--
-- Normalizujemy wpływ każdego silnika.
--
-- Dzięki temu:
--
-- największy pitch effect = 1
-- największy roll effect  = 1
--
-- ============================================================

local normalized = {}


for i = 1, 4 do

    normalized[i] = {

        pitch =
            effects[i].pitch / pitchMax,

        roll =
            effects[i].roll / rollMax

    }

end


print("")
print("================================")
print("       NORMALIZED MIXER")
print("================================")
print("")


for i, data in ipairs(motors) do

    print(
        string.format(
            "%-6s P:% .3f R:% .3f",
            data.name,
            normalized[i].pitch,
            normalized[i].roll
        )
    )

end


-- ============================================================
-- READY
-- ============================================================

print("")
print("================================")
print("      STABILIZER READY")
print("================================")
print("")

sleep(2)


-- ============================================================
-- PD LOOP
-- ============================================================

while true do

    local state = readSensor()


    -- ========================================================
    -- PITCH PD
    -- ========================================================

    local pitchCommand =
        -state.pitch * KP_PITCH
        -state.pitchRate * KD_PITCH


    -- ========================================================
    -- ROLL PD
    -- ========================================================

    local rollCommand =
        -state.roll * KP_ROLL
        -state.rollRate * KD_ROLL


    -- ========================================================
    -- LIMIT
    -- ========================================================

    pitchCommand =
        clamp(
            pitchCommand,
            -MAX_CORRECTION,
            MAX_CORRECTION
        )


    rollCommand =
        clamp(
            rollCommand,
            -MAX_CORRECTION,
            MAX_CORRECTION
        )


    -- ========================================================
    -- MIX
    -- ========================================================

    local rpm = {}


    for i = 1, 4 do

        local pitchPart =
            normalized[i].pitch *
            pitchCommand


        local rollPart =
            normalized[i].roll *
            rollCommand


        local correction =
            pitchPart + rollPart


        correction =
            clamp(
                correction,
                -MAX_CORRECTION,
                MAX_CORRECTION
            )


        rpm[i] =
            clamp(
                BASE_RPM + correction,
                0,
                MAX_RPM
            )

    end


    -- ========================================================
    -- OUTPUT
    -- ========================================================

    front.setTargetSpeed(rpm[1])
    back.setTargetSpeed(rpm[2])
    left.setTargetSpeed(rpm[3])
    right.setTargetSpeed(rpm[4])


    -- ========================================================
    -- DEBUG
    -- ========================================================

    -- Odkomentuj, jeśli chcesz widzieć dane:
    --
    -- print(
    --     string.format(
    --         "P %.2f R %.2f | RPM %.1f %.1f %.1f %.1f",
    --         state.pitch,
    --         state.roll,
    --         rpm[1],
    --         rpm[2],
    --         rpm[3],
    --         rpm[4]
    --     )
    -- )


    sleep(DT)

end
