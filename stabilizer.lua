-- =========================================================
-- DRONE STABILIZER
-- Create: Aeronautics / Avionics + CC:Tweaked
--
-- 4x Rotation Speed Controller:
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
-- Program automatycznie kalibruje kierunek działania
-- każdego RSC.
-- =========================================================


-- =========================================================
-- PERIPHERALS
-- =========================================================

local sensor = peripheral.find("gimbal_sensor")

local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")
local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")


if not sensor then
    error("Nie znaleziono gimbal_sensor")
end

if not front then
    error("Nie znaleziono RSC: front")
end

if not back then
    error("Nie znaleziono RSC: back")
end

if not left then
    error("Nie znaleziono RSC: left")
end

if not right then
    error("Nie znaleziono RSC: right")
end


-- =========================================================
-- SETTINGS
-- =========================================================

-- RPM zawisu.
-- Zacznij od niewielkiej wartości.
local BASE_RPM = 30

-- RPM używane podczas automatycznej kalibracji.
local CALIBRATION_RPM = 8

-- Jak długo trwa pojedynczy impuls kalibracyjny.
local CALIBRATION_TIME = 0.25

-- Czas stabilizacji po impulsie.
local CALIBRATION_SETTLE = 0.35

-- PD pitch
local KP_PITCH = 25
local KD_PITCH = 8

-- PD roll
local KP_ROLL = 25
local KD_ROLL = 8

-- Maksymalna korekta RPM.
local MAX_CORRECTION = 20

-- Częstotliwość regulatora.
local DT = 0.05


-- =========================================================
-- UTIL
-- =========================================================

local function clamp(x, min, max)
    if x < min then
        return min
    end

    if x > max then
        return max
    end

    return x
end


local function setAll(rpm)

    front.setTargetSpeed(rpm)
    back.setTargetSpeed(rpm)
    left.setTargetSpeed(rpm)
    right.setTargetSpeed(rpm)

end


local function getAngles()

    local a = sensor.getAnglesRad()

    return a[1], a[2]

end


local function getRates()

    local r = sensor.getAngularRatesRad()

    return r[1], r[3]

end


-- =========================================================
-- INITIALIZATION
-- =========================================================

print("")
print("==============================")
print(" DRONE STABILIZER")
print("==============================")
print("")

print("BASE RPM:", BASE_RPM)
print("")

print("Upewnij sie, ze dron jest")
print("ZABEZPIECZONY podczas kalibracji.")
print("")

print("Kalibracja rozpocznie sie za 3 sekundy...")

sleep(1)
print("3...")
sleep(1)
print("2...")
sleep(1)
print("1...")

print("")
print("START KALIBRACJI")
print("")


-- =========================================================
-- SET BASE RPM
-- =========================================================

setAll(BASE_RPM)

sleep(1)


-- =========================================================
-- READ INITIAL ANGLES
-- =========================================================

local initialPitch, initialRoll = getAngles()

print("Initial pitch:", initialPitch)
print("Initial roll :", initialRoll)

print("")


-- =========================================================
-- CALIBRATION
-- =========================================================

local motors = {
    {
        name = "FRONT",
        motor = front
    },

    {
        name = "BACK",
        motor = back
    },

    {
        name = "LEFT",
        motor = left
    },

    {
        name = "RIGHT",
        motor = right
    }
}


-- Matrix:
--
-- motor -> pitch effect
-- motor -> roll effect
--
-- calibration[motor].pitch
-- calibration[motor].roll

local calibration = {}


for i, data in ipairs(motors) do

    print("--------------------------------")
    print("Kalibracja:", data.name)
    print("--------------------------------")

    -- Upewnij się, że wszystkie mają BASE RPM.
    setAll(BASE_RPM)

    sleep(CALIBRATION_SETTLE)


    -- Aktualne kąty przed impulsem.
    local pitchBefore, rollBefore = getAngles()

    local pitchRateBefore, rollRateBefore = getRates()


    -- ---------------------------------------------
    -- IMPULS
    -- ---------------------------------------------

    data.motor.setTargetSpeed(
        BASE_RPM + CALIBRATION_RPM
    )

    sleep(CALIBRATION_TIME)


    -- ---------------------------------------------
    -- ODCZYT
    -- ---------------------------------------------

    local pitchAfter, rollAfter = getAngles()

    local pitchRateAfter, rollRateAfter = getRates()


    -- ---------------------------------------------
    -- STOP IMPULSU
    -- ---------------------------------------------

    data.motor.setTargetSpeed(BASE_RPM)

    sleep(CALIBRATION_SETTLE)


    -- ---------------------------------------------
    -- DIFFERENCE
    -- ---------------------------------------------

    local pitchDelta =
        pitchAfter - pitchBefore

    local rollDelta =
        rollAfter - rollBefore


    local pitchRateDelta =
        pitchRateAfter - pitchRateBefore

    local rollRateDelta =
        rollRateAfter - rollRateBefore


    calibration[i] = {
        pitch = pitchDelta,
        roll = rollDelta,

        pitchRate = pitchRateDelta,
        rollRate = rollRateDelta
    }


    print("Pitch delta:", pitchDelta)
    print("Roll delta :", rollDelta)

    print("Pitch rate :", pitchRateDelta)
    print("Roll rate  :", rollRateDelta)

    print("")

end


-- =========================================================
-- PRINT CALIBRATION
-- =========================================================

print("")
print("==============================")
print(" CALIBRATION RESULT")
print("==============================")

for i, data in ipairs(motors) do

    local c = calibration[i]

    print(
        data.name,
        "P=" .. string.format("%.4f", c.pitch),
        "R=" .. string.format("%.4f", c.roll)
    )

end

print("")


-- =========================================================
-- DETERMINE EFFECT
-- =========================================================
--
-- We determine which motors affect:
--
--   pitch
--   roll
--
-- The sign of the measured response is important.
--
-- We don't assume that:
--
-- FRONT = +
-- BACK  = -
--
-- etc.
--
-- The sensor tells us what actually happened.
-- =========================================================


local pitchEffect = {}
local rollEffect = {}


for i = 1, 4 do

    local c = calibration[i]

    pitchEffect[i] = c.pitch
    rollEffect[i] = c.roll

end


-- =========================================================
-- FIND STRONGEST MOTOR FOR EACH AXIS
-- =========================================================

local pitchMotorPositive = nil
local pitchMotorNegative = nil

local rollMotorPositive = nil
local rollMotorNegative = nil

local bestPitchPositive = 0
local bestPitchNegative = 0

local bestRollPositive = 0
local bestRollNegative = 0


for i = 1, 4 do

    local p = pitchEffect[i]
    local r = rollEffect[i]


    -- PITCH

    if p > bestPitchPositive then

        bestPitchPositive = p
        pitchMotorPositive = i

    end


    if p < bestPitchNegative then

        bestPitchNegative = p
        pitchMotorNegative = i

    end


    -- ROLL

    if r > bestRollPositive then

        bestRollPositive = r
        rollMotorPositive = i

    end


    if r < bestRollNegative then

        bestRollNegative = r
        rollMotorNegative = i

    end

end


print("==============================")
print(" EFFECTIVE MOTORS")
print("==============================")

print(
    "Pitch +:",
    pitchMotorPositive
        and motors[pitchMotorPositive].name
        or "NONE"
)

print(
    "Pitch -:",
    pitchMotorNegative
        and motors[pitchMotorNegative].name
        or "NONE"
)

print(
    "Roll +:",
    rollMotorPositive
        and motors[rollMotorPositive].name
        or "NONE"
)

print(
    "Roll -:",
    rollMotorNegative
        and motors[rollMotorNegative].name
        or "NONE"
)

print("")


-- =========================================================
-- SAFETY CHECK
-- =========================================================

if not pitchMotorPositive or not pitchMotorNegative then

    print("UWAGA!")
    print("Nie udalo sie wykryc obu kierunkow PITCH.")

    print("")
    print("Kalibracja nieudana.")

    setAll(0)

    error("Brak wystarczajacej odpowiedzi PITCH")

end


if not rollMotorPositive or not rollMotorNegative then

    print("UWAGA!")
    print("Nie udalo sie wykryc obu kierunkow ROLL.")

    print("")
    print("Kalibracja nieudana.")

    setAll(0)

    error("Brak wystarczajacej odpowiedzi ROLL")

end


-- =========================================================
-- READY
-- =========================================================

print("==============================")
print(" CALIBRATION COMPLETE")
print("==============================")

print("")
print("Stabilizator rozpocznie prace.")
print("")

sleep(2)


-- =========================================================
-- PD CONTROLLER
-- =========================================================

local previousPitch = 0
local previousRoll = 0


while true do

    -- =====================================================
    -- SENSOR
    -- =====================================================

    local pitch, roll = getAngles()

    local pitchRate, rollRate = getRates()


    -- =====================================================
    -- PITCH PD
    -- =====================================================

    --
    -- Target:
    --
    -- pitch = 0
    --

    local pitchError = -pitch


    local pitchCorrection =
        pitchError * KP_PITCH
        - pitchRate * KD_PITCH


    pitchCorrection =
        clamp(
            pitchCorrection,
            -MAX_CORRECTION,
            MAX_CORRECTION
        )


    -- =====================================================
    -- ROLL PD
    -- =====================================================

    --
    -- Target:
    --
    -- roll = 0
    --

    local rollError = -roll


    local rollCorrection =
        rollError * KP_ROLL
        - rollRate * KD_ROLL


    rollCorrection =
        clamp(
            rollCorrection,
            -MAX_CORRECTION,
            MAX_CORRECTION
        )


    -- =====================================================
    -- MOTOR OUTPUT
    -- =====================================================

    local frontRPM = BASE_RPM
    local backRPM  = BASE_RPM
    local leftRPM  = BASE_RPM
    local rightRPM = BASE_RPM


    -- =====================================================
    -- PITCH MIXING
    -- =====================================================

    --
    -- We use the measured calibration response.
    --
    -- If a motor creates positive pitch,
    -- its RPM must change opposite to the
    -- required correction.
    --

    for i = 1, 4 do

        local effect = pitchEffect[i]

        if math.abs(effect) > 0.0001 then

            local correction =
                pitchCorrection * effect

            if i == 1 then
                frontRPM = frontRPM + correction

            elseif i == 2 then
                backRPM = backRPM + correction

            elseif i == 3 then
                leftRPM = leftRPM + correction

            elseif i == 4 then
                rightRPM = rightRPM + correction

            end

        end

    end


    -- =====================================================
    -- ROLL MIXING
    -- =====================================================

    for i = 1, 4 do

        local effect = rollEffect[i]

        if math.abs(effect) > 0.0001 then

            local correction =
                rollCorrection * effect

            if i == 1 then
                frontRPM = frontRPM + correction

            elseif i == 2 then
                backRPM = backRPM + correction

            elseif i == 3 then
                leftRPM = leftRPM + correction

            elseif i == 4 then
                rightRPM = rightRPM + correction

            end

        end

    end


    -- =====================================================
    -- LIMIT RPM
    -- =====================================================

    frontRPM = clamp(frontRPM, 0, 256)
    backRPM  = clamp(backRPM, 0, 256)
    leftRPM  = clamp(leftRPM, 0, 256)
    rightRPM = clamp(rightRPM, 0, 256)


    -- =====================================================
    -- APPLY
    -- =====================================================

    front.setTargetSpeed(frontRPM)
    back.setTargetSpeed(backRPM)
    left.setTargetSpeed(leftRPM)
    right.setTargetSpeed(rightRPM)


    -- =====================================================
    -- LOOP
    -- =====================================================

    sleep(DT)

end
