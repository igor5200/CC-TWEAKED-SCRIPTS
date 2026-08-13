local nav = peripheral.find("navigation_table")

local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")
local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")

if not nav then
    error("Nie znaleziono Navigation Table")
end

if not front or not back or not left or not right then
    error("Nie znaleziono wszystkich Rotation Speed Controllerow")
end


--------------------------------------------------
-- USTAWIENIA
--------------------------------------------------

-- Punkt, przy którym dron zaczyna się unosić
local BASE_RPM = 70

-- Maksymalna korekta pojedynczego silnika
local MAX_CORRECTION = 15

-- Wzmocnienie P
local KP_ROLL = 8
local KP_PITCH = 8

-- Wzmocnienie D
local KD_ROLL = 2
local KD_PITCH = 2

-- Jak często działa kontroler
local DT = 0.05


--------------------------------------------------
-- QUATERNION
--------------------------------------------------

local function quaternionMultiply(a, b)
    return {
        a[4] * b[1] + a[1] * b[4] + a[2] * b[3] - a[3] * b[2],
        a[4] * b[2] - a[1] * b[3] + a[2] * b[4] + a[3] * b[1],
        a[4] * b[3] + a[1] * b[2] - a[2] * b[1] + a[3] * b[4],
        a[4] * b[4] - a[1] * b[1] - a[2] * b[2] - a[3] * b[3]
    }
end


local function quaternionInverse(q)
    return {
        -q[1],
        -q[2],
        -q[3],
        q[4]
    }
end


--------------------------------------------------
-- QUATERNION -> ROLL / PITCH
--------------------------------------------------

local function getAngles(q)

    local x = q[1]
    local y = q[2]
    local z = q[3]
    local w = q[4]

    -- Roll
    local sinRoll = 2 * (w * x + y * z)
    local cosRoll = 1 - 2 * (x * x + y * y)

    local roll = math.atan2(sinRoll, cosRoll)

    -- Pitch
    local sinPitch = 2 * (w * y - z * x)

    if sinPitch > 1 then
        sinPitch = 1
    elseif sinPitch < -1 then
        sinPitch = -1
    end

    local pitch = math.asin(sinPitch)

    return math.deg(roll), math.deg(pitch)
end


--------------------------------------------------
-- POMOCNICZE
--------------------------------------------------

local function clamp(value, min, max)

    if value < min then
        return min
    end

    if value > max then
        return max
    end

    return value
end


--------------------------------------------------
-- AUTOMATYCZNA REFERENCJA
--------------------------------------------------

print("Stabilizator uruchamia sie...")
print()
print("Ustaw drona poziomo!")
print("Kalibracja za 3 sekundy...")

sleep(3)

local reference = nav.getOrientation()

if not reference then
    error("Navigation Table nie zwrocil orientacji")
end

print("Poziom zapamietany!")
print()
print("Start stabilizacji...")


--------------------------------------------------
-- ZMIENNE PD
--------------------------------------------------

local previousRoll = 0
local previousPitch = 0


--------------------------------------------------
-- STARTOWE RPM
--------------------------------------------------

front.setSpeed(BASE_RPM)
back.setSpeed(BASE_RPM)
left.setSpeed(BASE_RPM)
right.setSpeed(BASE_RPM)


--------------------------------------------------
-- GLOWNA PETLA
--------------------------------------------------

while true do

    local current = nav.getOrientation()

    if current then

        --------------------------------------------------
        -- RELATYWNA ORIENTACJA
        --------------------------------------------------

        local errorQuaternion =
            quaternionMultiply(
                quaternionInverse(reference),
                current
            )

        local roll, pitch =
            getAngles(errorQuaternion)


        --------------------------------------------------
        -- POCHODNA
        --------------------------------------------------

        local rollRate =
            (roll - previousRoll) / DT

        local pitchRate =
            (pitch - previousPitch) / DT


        previousRoll = roll
        previousPitch = pitch


        --------------------------------------------------
        -- PD
        --------------------------------------------------

        local rollCorrection =
            KP_ROLL * roll -
            KD_ROLL * rollRate

        local pitchCorrection =
            KP_PITCH * pitch -
            KD_PITCH * pitchRate


        --------------------------------------------------
        -- OGRANICZENIE
        --------------------------------------------------

        rollCorrection =
            clamp(
                rollCorrection,
                -MAX_CORRECTION,
                MAX_CORRECTION
            )

        pitchCorrection =
            clamp(
                pitchCorrection,
                -MAX_CORRECTION,
                MAX_CORRECTION
            )


        --------------------------------------------------
        -- 4 SILNIKI
        --
        -- UKLAD:
        --
        --             FRONT
        --               |
        --               |
        -- LEFT -------- PC -------- RIGHT
        --               |
        --               |
        --              BACK
        --
        --------------------------------------------------

        local frontRPM =
            BASE_RPM + pitchCorrection

        local backRPM =
            BASE_RPM - pitchCorrection

        local leftRPM =
            BASE_RPM + rollCorrection

        local rightRPM =
            BASE_RPM - rollCorrection


        --------------------------------------------------
        -- USTAW RPM
        --------------------------------------------------

        front.setSpeed(frontRPM)
        back.setSpeed(backRPM)
        left.setSpeed(leftRPM)
        right.setSpeed(rightRPM)


        --------------------------------------------------
        -- INFORMACJE
        --------------------------------------------------

        term.clear()
        term.setCursorPos(1, 1)

        print("=== DRONE STABILIZER ===")
        print()

        print(string.format(
            "Roll : %7.2f deg",
            roll
        ))

        print(string.format(
            "Pitch: %7.2f deg",
            pitch
        ))

        print()

        print(string.format(
            "Roll correction : %7.2f",
            rollCorrection
        ))

        print(string.format(
            "Pitch correction: %7.2f",
            pitchCorrection
        ))

        print()

        print("RPM:")
        print(string.format(
            "Front: %.1f",
            frontRPM
        ))

        print(string.format(
            "Back : %.1f",
            backRPM
        ))

        print(string.format(
            "Left : %.1f",
            leftRPM
        ))

        print(string.format(
            "Right: %.1f",
            rightRPM
        ))

    end

    sleep(DT)
end
