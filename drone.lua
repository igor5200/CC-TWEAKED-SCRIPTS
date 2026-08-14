local nav = peripheral.find("navigation_table")

local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")
local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")

if not nav then
    error("Nie znaleziono Navigation Table")
end

if not front or not back or not left or not right then
    error("Nie znaleziono wszystkich Rotation Speed Controllerów")
end


--------------------------------------------------
-- USTAWIENIA
--------------------------------------------------

-- Tutaj zmieniasz podstawowe RPM drona
local BASE_RPM = 70

-- Maksymalna korekta względem BASE_RPM
local MAX_CORRECTION = 12

-- Stabilizacja
local KP_ROLL  = 5
local KD_ROLL  = 1.5

local KP_PITCH = 5
local KD_PITCH = 1.5

-- Częstotliwość sterowania
local DT = 0.05


--------------------------------------------------
-- QUATERNION
--------------------------------------------------

local function normalizeQuaternion(q)

    local length = math.sqrt(
        q[1] * q[1] +
        q[2] * q[2] +
        q[3] * q[3] +
        q[4] * q[4]
    )

    return {
        q[1] / length,
        q[2] / length,
        q[3] / length,
        q[4] / length
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


local function quaternionMultiply(a, b)

    return {
        a[4] * b[1] + a[1] * b[4] + a[2] * b[3] - a[3] * b[2],

        a[4] * b[2] - a[1] * b[3] + a[2] * b[4] + a[3] * b[1],

        a[4] * b[3] + a[1] * b[2] - a[2] * b[1] + a[3] * b[4],

        a[4] * b[4] - a[1] * b[1] - a[2] * b[2] - a[3] * b[3]
    }
end


--------------------------------------------------
-- QUATERNION -> ROLL / PITCH
--------------------------------------------------

local function getAngles(q)

    q = normalizeQuaternion(q)

    local x = q[1]
    local y = q[2]
    local z = q[3]
    local w = q[4]

    -- Roll
    local sinRoll =
        2 * (w * x + y * z)

    local cosRoll =
        1 - 2 * (x * x + y * y)

    local roll =
        math.atan2(sinRoll, cosRoll)


    -- Pitch
    local sinPitch =
        2 * (w * y - z * x)

    sinPitch =
        math.max(-1, math.min(1, sinPitch))

    local pitch =
        math.asin(sinPitch)


    return math.deg(roll), math.deg(pitch)
end


--------------------------------------------------
-- CLAMP
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
-- POCZĄTKOWA ORIENTACJA
--------------------------------------------------

-- Odczytujemy orientację automatycznie.
-- NIE MUSISZ PORUSZAĆ DRONEM.

local reference =
    normalizeQuaternion(
        nav.getOrientation()
    )

if not reference then
    error("Nie można odczytać orientacji")
end


--------------------------------------------------
-- START
--------------------------------------------------

peripheral.call("front", "setSpeed", frontRPM)
peripheral.call("back", "setSpeed", backRPM)
peripheral.call("left", "setSpeed", leftRPM)
peripheral.call("right", "setSpeed", rightRPM)

--------------------------------------------------
-- PD
--------------------------------------------------

local previousRoll = 0
local previousPitch = 0


--------------------------------------------------
-- GŁÓWNA PĘTLA
--------------------------------------------------

while true do

    local current =
        nav.getOrientation()

    if current then

        current =
            normalizeQuaternion(current)


        --------------------------------------------------
        -- BŁĄD ORIENTACJI
        --------------------------------------------------

        local errorQ =
            quaternionMultiply(
                quaternionInverse(reference),
                current
            )


        local roll, pitch =
            getAngles(errorQ)


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
        -- RPM
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
        -- BEZPIECZEŃSTWO
        --------------------------------------------------

        frontRPM =
            math.max(0, frontRPM)

        backRPM =
            math.max(0, backRPM)

        leftRPM =
            math.max(0, leftRPM)

        rightRPM =
            math.max(0, rightRPM)


        --------------------------------------------------
        -- RSC
        --------------------------------------------------

        front.setSpeed(frontRPM)
        back.setSpeed(backRPM)
        left.setSpeed(leftRPM)
        right.setSpeed(rightRPM)


        --------------------------------------------------
        -- MONITOR
        --------------------------------------------------

        term.clear()
        term.setCursorPos(1, 1)

        print("=== DRONE STABILIZER ===")
        print()

        print(string.format(
            "BASE RPM : %.1f",
            BASE_RPM
        ))

        print()

        print(string.format(
            "ROLL     : %7.2f",
            roll
        ))

        print(string.format(
            "PITCH    : %7.2f",
            pitch
        ))

        print()

        print(string.format(
            "FRONT    : %7.2f RPM",
            frontRPM
        ))

        print(string.format(
            "BACK     : %7.2f RPM",
            backRPM
        ))

        print(string.format(
            "LEFT     : %7.2f RPM",
            leftRPM
        ))

        print(string.format(
            "RIGHT    : %7.2f RPM",
            rightRPM
        ))
    end

    sleep(DT)
end
