-- ============================================
-- SIMPLE DRONE STABILIZER v1
-- ============================================

local gimbal = peripheral.wrap("top")

local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")
local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")

if not gimbal then
    error("Brak gimbal_sensor na top")
end

if not front or not back or not left or not right then
    error("Brak jednego z 4 Rotation Speed Controller")
end

-- ============================================
-- USTAWIENIA
-- ============================================

local BASE_RPM = 100

-- Stabilizacja P
local P_PITCH = 2.0
local P_ROLL  = 2.0

-- Stabilizacja D
local D_PITCH = 0.5
local D_ROLL  = 0.5

-- Maksymalna korekta od stabilizatora
local MAX_CORRECTION = 40

-- ============================================
-- FUNKCJA OGRANICZAJĄCA
-- ============================================

local function clamp(x, min, max)
    return math.max(min, math.min(max, x))
end

-- ============================================
-- START
-- ============================================

front.setTargetSpeed(BASE_RPM)
back.setTargetSpeed(BASE_RPM)
left.setTargetSpeed(BASE_RPM)
right.setTargetSpeed(BASE_RPM)

print("Drone stabilizer started")
print("BASE RPM:", BASE_RPM)

-- ============================================
-- GŁÓWNA PĘTLA
-- ============================================

while true do

    -- getAngles() zwraca:
    -- { pitch, roll }
    local angles = gimbal.getAngles()

    local pitch = angles[1]
    local roll  = angles[2]

    -- getAngularRates() zwraca:
    -- { pitchRate, yawRate, rollRate }
    local rates = gimbal.getAngularRates()

    local pitchRate = rates[1]
    local rollRate  = rates[3]

    -- Chcemy:
    -- pitch = 0
    -- roll  = 0

    local pitchError = -pitch
    local rollError  = -roll

    -- PD
    local pitchCorrection =
        P_PITCH * pitchError -
        D_PITCH * pitchRate

    local rollCorrection =
        P_ROLL * rollError -
        D_ROLL * rollRate

    pitchCorrection =
        clamp(pitchCorrection, -MAX_CORRECTION, MAX_CORRECTION)

    rollCorrection =
        clamp(rollCorrection, -MAX_CORRECTION, MAX_CORRECTION)

    -- ========================================
    -- MIXOWANIE SILNIKÓW
    -- ========================================

    -- Pitch:
    --
    -- FRONT
    --   ↓
    -- zmniejszamy / zwiększamy
    --
    -- BACK
    --   ↑
    --
    local frontRPM = BASE_RPM - pitchCorrection
    local backRPM  = BASE_RPM + pitchCorrection

    -- Roll:
    --
    -- LEFT  zwiększamy
    -- RIGHT zmniejszamy
    --
    local leftRPM  = BASE_RPM + rollCorrection
    local rightRPM = BASE_RPM - rollCorrection

    -- Połącz pitch + roll
    frontRPM = frontRPM
    backRPM  = backRPM
    leftRPM  = leftRPM
    rightRPM = rightRPM

    front.setTargetSpeed(clamp(frontRPM, -256, 256))
    back.setTargetSpeed(clamp(backRPM, -256, 256))
    left.setTargetSpeed(clamp(leftRPM, -256, 256))
    right.setTargetSpeed(clamp(rightRPM, -256, 256))

    sleep(0.05)
end
