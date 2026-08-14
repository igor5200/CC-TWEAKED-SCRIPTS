-- ==========================================
-- DRONE STABILIZER v1
-- Create Aeronautics + CC:Tweaked
-- Gimbal Sensor + 4 Rotation Speed Controller
-- ==========================================

local sensor = peripheral.find("gimbal_sensor")

local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")
local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")

if not sensor then
    error("Nie znaleziono gimbal_sensor")
end

if not front or not back or not left or not right then
    error("Nie znaleziono wszystkich 4 Rotation Speed Controller")
end


-- ==========================================
-- USTAWIENIA
-- ==========================================

-- RPM podczas normalnego zawisu
local BASE_RPM = 50

-- Pitch
local KP_PITCH = 20
local KD_PITCH = 5

-- Roll
local KP_ROLL = 20
local KD_ROLL = 5

-- Maksymalna korekta RPM
local MAX_CORRECTION = 30

-- Częstotliwość regulatora
local DT = 0.05


-- ==========================================
-- FUNKCJE
-- ==========================================

local function clamp(x, min, max)
    return math.max(min, math.min(max, x))
end


-- ==========================================
-- PĘTLA
-- ==========================================

while true do

    -- --------------------------------------
    -- Odczyt kąta
    -- --------------------------------------

    local angles = sensor.getAnglesRad()

    local pitch = angles[1]
    local roll  = angles[2]


    -- --------------------------------------
    -- Odczyt prędkości kątowej
    -- --------------------------------------

    local rates = sensor.getAngularRatesRad()

    local pitchRate = rates[1]
    local rollRate  = rates[3]


    -- --------------------------------------
    -- PITCH PD
    -- --------------------------------------

    -- Cel = 0 rad
    local pitchCorrection =
        (-pitch * KP_PITCH)
        + (-pitchRate * KD_PITCH)

    pitchCorrection =
        clamp(
            pitchCorrection,
            -MAX_CORRECTION,
            MAX_CORRECTION
        )


    -- --------------------------------------
    -- ROLL PD
    -- --------------------------------------

    -- Cel = 0 rad
    local rollCorrection =
        (-roll * KP_ROLL)
        + (-rollRate * KD_ROLL)

    rollCorrection =
        clamp(
            rollCorrection,
            -MAX_CORRECTION,
            MAX_CORRECTION
        )


    -- --------------------------------------
    -- MIXER
    -- --------------------------------------

    local frontRPM =
        BASE_RPM + pitchCorrection

    local backRPM =
        BASE_RPM - pitchCorrection

    local leftRPM =
        BASE_RPM + rollCorrection

    local rightRPM =
        BASE_RPM - rollCorrection


    -- --------------------------------------
    -- OGRANICZENIE
    -- --------------------------------------

    frontRPM = clamp(frontRPM, 0, 256)
    backRPM  = clamp(backRPM,  0, 256)
    leftRPM  = clamp(leftRPM,  0, 256)
    rightRPM = clamp(rightRPM, 0, 256)


    -- --------------------------------------
    -- RSC
    -- --------------------------------------

    front.setTargetSpeed(frontRPM)
    back.setTargetSpeed(backRPM)

    left.setTargetSpeed(leftRPM)
    right.setTargetSpeed(rightRPM)


    sleep(DT)
end
