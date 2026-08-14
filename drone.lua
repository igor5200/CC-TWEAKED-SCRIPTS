-- ============================================================
-- DRONE V2
-- navigation_table_0 + gimbal_sensor_0
-- 4x Create Rotation Speed Controller
--
-- front / back / left / right
--
-- Sterowanie:
--   navigation -> kierunek celu
--   navigation -> wymagany pitch/roll
--   gimbal     -> rzeczywisty pitch/roll
--   PD         -> korekta RPM
-- ============================================================


-- ============================================================
-- PERIPHERALS
-- ============================================================

local nav = peripheral.wrap("navigation_table_0")
local gimbal = peripheral.wrap("gimbal_sensor_0")

local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")
local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")


if not nav then
    error("Brak navigation_table_0")
end

if not gimbal then
    error("Brak gimbal_sensor_0")
end

if not front then
    error("Brak kontrolera: front")
end

if not back then
    error("Brak kontrolera: back")
end

if not left then
    error("Brak kontrolera: left")
end

if not right then
    error("Brak kontrolera: right")
end


-- ============================================================
-- USTAWIENIA
-- ============================================================

-- RPM potrzebne do unoszenia drona.
--
-- MUSISZ to dobrać eksperymentalnie.
--
-- Przykład:
--   jeśli 180 RPM utrzymuje drona mniej więcej w miejscu:
--
--   HOVER_RPM = 180
--
local HOVER_RPM = 180


-- Maksymalny przechył podczas lotu.
--
-- 5 stopni = bardzo spokojny
-- 10 stopni = normalny
-- 15 stopni = agresywny
--
local MAX_TILT = math.rad(8)


-- Jak mocno odległość od celu wpływa na przechył.
--
-- Im większa odległość, tym większy przechył.
--
local DISTANCE_FOR_MAX_TILT = 20


-- ============================================================
-- PD PITCH
-- ============================================================

-- P:
-- im większy, tym mocniej dron próbuje osiągnąć zadany pitch.
local KP_PITCH = 450


-- D:
-- tłumi ruch i przeciwdziała oscylacjom.
local KD_PITCH = 90


-- ============================================================
-- PD ROLL
-- ============================================================

local KP_ROLL = 450
local KD_ROLL = 90


-- ============================================================
-- OGRANICZENIA
-- ============================================================

local MAX_RPM = 256

-- Maksymalna różnica RPM między przeciwległymi silnikami.
--
-- NIE ustawiaj od razu bardzo dużej wartości.
local MAX_CORRECTION = 50


-- ============================================================
-- ODWRÓCENIE OSI
-- ============================================================
--
-- TE WARTOŚCI MOGĄ WYMAGAĆ ZMIANY.
--
-- Jeśli dron po zadaniu pitch do przodu zaczyna lecieć do tyłu:
--
-- PITCH_SIGN = -1
--
-- Jeśli przy próbie lotu w prawo przechyla się w lewo:
--
-- ROLL_SIGN = -1
--
-- ============================================================

local PITCH_SIGN = 1
local ROLL_SIGN  = 1


-- ============================================================
-- FUNKCJE
-- ============================================================

local function clamp(x, min, max)
    if x < min then
        return min
    end

    if x > max then
        return max
    end

    return x
end


local function setRPM(controller, rpm)
    rpm = clamp(rpm, -MAX_RPM, MAX_RPM)
    controller.setTargetSpeed(rpm)
end


-- ============================================================
-- START
-- ============================================================

print("DRONE V2")
print()
print("Starting...")

-- Najpierw wszystkie silniki na hover RPM.
setRPM(front, HOVER_RPM)
setRPM(back, HOVER_RPM)
setRPM(left, HOVER_RPM)
setRPM(right, HOVER_RPM)

sleep(1)


-- ============================================================
-- MAIN LOOP
-- ============================================================

while true do

    ------------------------------------------------------------
    -- ODCZYT GIMBALA
    ------------------------------------------------------------

    local angles = gimbal.getAnglesRad()
    local rates = gimbal.getAngularRatesRad()

    -- Dokumentacja:
    --
    -- angles[1] = pitch
    -- angles[2] = roll
    --
    -- rates[1] = pitch angular velocity
    -- rates[2] = yaw angular velocity
    -- rates[3] = roll angular velocity

    local pitch = angles[1]
    local roll  = angles[2]

    local pitchRate = rates[1]
    local rollRate  = rates[3]


    ------------------------------------------------------------
    -- DOMYŚLNY CEL
    ------------------------------------------------------------

    local targetPitch = 0
    local targetRoll = 0


    ------------------------------------------------------------
    -- NAVIGATION
    ------------------------------------------------------------

    local hasTarget = nav.hasTarget()

    local bearing = 0
    local distance = 0

    if hasTarget then

        bearing = nav.getBearingRad()
        distance = nav.getDistanceToTarget()


        --------------------------------------------------------
        -- OKREŚLENIE SIŁY PRZECHYŁU
        --------------------------------------------------------
        --
        -- Daleko od celu:
        --     większy przechył
        --
        -- Blisko celu:
        --     mniejszy przechył
        --

        local distanceFactor =
            clamp(
                distance / DISTANCE_FOR_MAX_TILT,
                0,
                1
            )


        local requestedTilt =
            MAX_TILT * distanceFactor


        --------------------------------------------------------
        -- ROZŁOŻENIE KIERUNKU NA PITCH / ROLL
        --------------------------------------------------------
        --
        -- bearing:
        --
        --   0°       = przód
        --   +90°     = prawo
        --   -90°     = lewo
        --   ±180°    = tył
        --
        --
        -- cos() -> przód / tył
        -- sin() -> lewo / prawo
        --

        targetPitch =
            math.cos(bearing) *
            requestedTilt *
            PITCH_SIGN


        targetRoll =
            math.sin(bearing) *
            requestedTilt *
            ROLL_SIGN

    end


    ------------------------------------------------------------
    -- PD PITCH
    ------------------------------------------------------------

    local pitchError =
        targetPitch - pitch


    local pitchCorrection =
        KP_PITCH * pitchError
        -
        KD_PITCH * pitchRate


    pitchCorrection =
        clamp(
            pitchCorrection,
            -MAX_CORRECTION,
            MAX_CORRECTION
        )


    ------------------------------------------------------------
    -- PD ROLL
    ------------------------------------------------------------

    local rollError =
        targetRoll - roll


    local rollCorrection =
        KP_ROLL * rollError
        -
        KD_ROLL * rollRate


    rollCorrection =
        clamp(
            rollCorrection,
            -MAX_CORRECTION,
            MAX_CORRECTION
        )


    ------------------------------------------------------------
    -- MIXER
    ------------------------------------------------------------
    --
    -- PITCH:
    --
    -- front  -
    -- back   +
    --
    -- ROLL:
    --
    -- left   +
    -- right  -
    --
    ------------------------------------------------------------

    local frontRPM =
        HOVER_RPM
        - pitchCorrection

    local backRPM =
        HOVER_RPM
        + pitchCorrection


    local leftRPM =
        HOVER_RPM
        + rollCorrection

    local rightRPM =
        HOVER_RPM
        - rollCorrection


    ------------------------------------------------------------
    -- RPM LIMIT
    ------------------------------------------------------------

    frontRPM = clamp(frontRPM, 0, MAX_RPM)
    backRPM  = clamp(backRPM, 0, MAX_RPM)
    leftRPM  = clamp(leftRPM, 0, MAX_RPM)
    rightRPM = clamp(rightRPM, 0, MAX_RPM)


    ------------------------------------------------------------
    -- APPLY
    ------------------------------------------------------------

    setRPM(front, frontRPM)
    setRPM(back, backRPM)
    setRPM(left, leftRPM)
    setRPM(right, rightRPM)


    ------------------------------------------------------------
    -- DEBUG
    ------------------------------------------------------------

    term.clear()
    term.setCursorPos(1, 1)

    print("================================")
    print("          DRONE V2")
    print("================================")
    print()

    if hasTarget then
        print("TARGET: YES")
        print(
            string.format(
                "Bearing: %6.1f deg",
                math.deg(bearing)
            )
        )

        print(
            string.format(
                "Distance: %6.2f",
                distance
            )
        )
    else
        print("TARGET: NO")
    end

    print()

    print(
        string.format(
            "Pitch: %6.2f deg",
            math.deg(pitch)
        )
    )

    print(
        string.format(
            "Roll:  %6.2f deg",
            math.deg(roll)
        )
    )

    print()

    print(
        string.format(
            "Target pitch: %6.2f",
            math.deg(targetPitch)
        )
    )

    print(
        string.format(
            "Target roll:  %6.2f",
            math.deg(targetRoll)
        )
    )

    print()

    print(
        string.format(
            "Pitch PD: %6.2f",
            pitchCorrection
        )
    )

    print(
        string.format(
            "Roll PD:  %6.2f",
            rollCorrection
        )
    )

    print()

    print(
        string.format(
            "FRONT: %3d",
            math.floor(frontRPM)
        )
    )

    print(
        string.format(
            "BACK:  %3d",
            math.floor(backRPM)
        )
    )

    print(
        string.format(
            "LEFT:  %3d",
            math.floor(leftRPM)
        )
    )

    print(
        string.format(
            "RIGHT: %3d",
            math.floor(rightRPM)
        )
    )

    sleep(0.05)
end
