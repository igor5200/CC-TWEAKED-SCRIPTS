local sensor = peripheral.find("gimbal_sensor")

local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")
local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")

-- USTAW NA WARTOŚĆ, PRZY KTÓREJ DRON NORMALNIE ZAWISA
local BASE_RPM = 120

local KP_ROLL = 80
local KD_ROLL = 15

local KP_PITCH = 80
local KD_PITCH = 15

local MAX_CORRECTION = 30

local function clamp(x, min, max)
    return math.max(min, math.min(max, x))
end

while true do

    local angles = sensor.getAnglesRad()
    local rates = sensor.getAngularRatesRad()

    local pitch = angles[1]
    local roll  = angles[2]

    local pitchRate = rates[1]
    local rollRate  = rates[3]

    -- stabilizacja pitch
    local pitchCorrection =
        -pitch * KP_PITCH
        - pitchRate * KD_PITCH

    -- stabilizacja roll
    local rollCorrection =
        -roll * KP_ROLL
        - rollRate * KD_ROLL

    pitchCorrection =
        clamp(pitchCorrection, -MAX_CORRECTION, MAX_CORRECTION)

    rollCorrection =
        clamp(rollCorrection, -MAX_CORRECTION, MAX_CORRECTION)


    -- MIXER
    local frontRPM =
        BASE_RPM - pitchCorrection

    local backRPM =
        BASE_RPM + pitchCorrection

    local leftRPM =
        BASE_RPM - rollCorrection

    local rightRPM =
        BASE_RPM + rollCorrection


    front.setTargetSpeed(clamp(frontRPM, 0, 256))
    back.setTargetSpeed(clamp(backRPM, 0, 256))
    left.setTargetSpeed(clamp(leftRPM, 0, 256))
    right.setTargetSpeed(clamp(rightRPM, 0, 256))

    sleep(0.02)
end
