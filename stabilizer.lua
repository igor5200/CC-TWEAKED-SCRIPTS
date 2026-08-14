-- ============================================================
-- stabilizer.lua v2
--
-- Create: Aeronautics / Avionics
-- CC:Tweaked
--
-- 4x Rotation Speed Controller:
--   front
--   back
--   left
--   right
--
-- 1x Gimbal Sensor
--
-- AUTOMATYCZNA KALIBRACJA MOMENTU
-- AUTOMATYCZNA STABILIZACJA PITCH + ROLL
--
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
-- KONFIGURACJA
-- ============================================================

-- RPM, przy którym DRON JUŻ POTRAFI ZAWISAĆ.
--
-- Przykład:
-- local BASE_RPM = 140
--
local BASE_RPM = 140


-- Ile RPM dodajemy podczas automatycznego testu.
--
-- Nie ustawiaj bardzo dużej wartości.
local TEST_RPM = 8


-- Jak długo trwa impuls testowy.
local TEST_TIME = 0.20


-- Czas oczekiwania po impulsie.
local SETTLE_TIME = 0.30


-- PD stabilizatora.
--
-- Na początek umiarkowane wartości.
local KP_PITCH = 35
local KD_PITCH = 10

local KP_ROLL = 35
local KD_ROLL = 10


-- Maksymalna zmiana RPM od BASE.
local MAX_CORRECTION = 35


-- Maksymalne RPM RSC.
local MAX_RPM = 256


-- Częstotliwość regulatora.
local DT = 0.05


-- ============================================================
-- UTIL
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
    local rates  = sensor.getAngularRatesRad()

    return {
        pitch = angles[1],
        roll  = angles[2],

        pitchRate = rates[1],
        rollRate  = rates[3]
    }

end


-- ============================================================
-- START
-- ============================================================

term.clear()
term.setCursorPos(1, 1)

print("================================")
print("       DRONE STABILIZER v2")
print("================================")
print("")
print("BASE RPM:", BASE_RPM)
print("")
print("Automatyczna kalibracja.")
print("")
print("Dron musi miec mozliwosc")
print("swobodnego przechylenia sie.")
print("")
print("Start za 3 sekundy...")
print("")

sleep(1)
print("3...")
sleep(1)
print("2...")
sleep(1)
print("1...")


-- ============================================================
-- START BASE RPM
-- ============================================================

setAll(BASE_RPM)

sleep(1)


-- ============================================================
-- KALIBRACJA
-- ============================================================

print("")
print("================================")
print("      ROZPOCZYNAM KALIBRACJE")
print("================================")
print("")


local effects = {}


for i, data in ipairs(motors) do

    print("")
    print("TEST:", data.name)
    print("")


    -- --------------------------------------------------------
    -- Wszystkie silniki wracają do BASE
    -- --------------------------------------------------------

    setAll(BASE_RPM)

    sleep(SETTLE_TIME)


    -- --------------------------------------------------------
    -- Odczyt przed impulsem
    -- --------------------------------------------------------

    local before = readSensor()


    -- --------------------------------------------------------
    -- Zwiekszamy tylko jeden RSC
    -- --------------------------------------------------------

    data.rsc.setTargetSpeed(
        BASE_RPM + TEST_RPM
    )


    sleep(TEST_TIME)


    -- --------------------------------------------------------
    -- Odczyt po impulsie
    -- --------------------------------------------------------

    local after = readSensor()


    -- --------------------------------------------------------
    -- Natychmiast wracamy do BASE
    -- --------------------------------------------------------

    data.rsc.setTargetSpeed(BASE_RPM)


    sleep(SETTLE_TIME)


    -- --------------------------------------------------------
    -- Zmiana predkosci katowej
    --
    -- To jest najwazniejszy pomiar.
    -- --------------------------------------------------------

    local pitchRateDelta =
        after.pitchRate - before.pitchRate

    local rollRateDelta =
        after.rollRate - before.rollRate


    -- --------------------------------------------------------
    -- Przyblizona odpowiedz na 1 RPM
    -- --------------------------------------------------------

    local pitchEffect =
        pitchRateDelta / TEST_RPM

    local rollEffect =
        rollRateDelta / TEST_RPM


    effects[i] = {

        pitch = pitchEffect,
        roll = rollEffect

    }


    print(
        data.name,
        "pitch=",
        string.format("%.5f", pitchEffect),
        "roll=",
        string.format("%.5f", rollEffect)
    )

end


-- ============================================================
-- WYSWIETLENIE MACIERZY
-- ============================================================

print("")
print("================================")
print("      MACIERZ SILNIKOW")
print("================================")
print("")

for i, data in ipairs(motors) do

    print(
        data.name,
        "P:",
        string.format("%.5f", effects[i].pitch),
        "R:",
        string.format("%.5f", effects[i].roll)
    )

end


-- ============================================================
-- SPRAWDZENIE, CZY SENSOR WIDZI SILNIKI
-- ============================================================

local pitchPower = 0
local rollPower = 0

for i = 1, 4 do

    pitchPower =
        pitchPower +
        effects[i].pitch *
        effects[i].pitch

    rollPower =
        rollPower +
        effects[i].roll *
        effects[i].roll

end


print("")

print(
    "Pitch authority:",
    string.format("%.6f", pitchPower)
)

print(
    "Roll authority:",
    string.format("%.6f", rollPower)
)


if pitchPower < 0.0000001 then

    setAll(0)

    error(
        "Kalibracja pitch nieudana."
    )

end


if rollPower < 0.0000001 then

    setAll(0)

    error(
        "Kalibracja roll nieudana."
    )

end


-- ============================================================
-- MACIERZ A
--
-- A =
--
-- [ p1 p2 p3 p4 ]
-- [ r1 r2 r3 r4 ]
--
--
-- Potrzebujemy:
--
-- deltaRPM =
--
-- A^T * inverse(A*A^T) * desired
--
-- Jest to pseudoodwrotność macierzy A.
-- ============================================================


local a11 = 0
local a12 = 0
local a22 = 0


for i = 1, 4 do

    local p = effects[i].pitch
    local r = effects[i].roll

    a11 = a11 + p * p
    a12 = a12 + p * r
    a22 = a22 + r * r

end


-- ============================================================
-- INVERSE 2x2
-- ============================================================

local determinant =
    a11 * a22 -
    a12 * a12


if math.abs(determinant) < 0.000000001 then

    setAll(0)

    error(
        "Macierz kalibracji jest osobliwa."
    )

end


local inv11 =  a22 / determinant
local inv12 = -a12 / determinant
local inv21 = -a12 / determinant
local inv22 =  a11 / determinant


-- ============================================================
-- FUNKCJA MIXERA
-- ============================================================

local function calculateMotorCorrections(
    desiredPitch,
    desiredRoll
)

    -- --------------------------------------------------------
    -- Najpierw:
    --
    -- q = inverse(A*A^T) * desired
    -- --------------------------------------------------------

    local qPitch =
        inv11 * desiredPitch +
        inv12 * desiredRoll

    local qRoll =
        inv21 * desiredPitch +
        inv22 * desiredRoll


    -- --------------------------------------------------------
    -- Następnie:
    --
    -- delta = A^T * q
    -- --------------------------------------------------------

    local result = {}


    for i = 1, 4 do

        local p = effects[i].pitch
        local r = effects[i].roll

        result[i] =
            p * qPitch +
            r * qRoll

    end


    return result

end


-- ============================================================
-- GOTOWE
-- ============================================================

print("")
print("================================")
print("       KALIBRACJA GOTOWA")
print("================================")
print("")
print("Uruchamiam PD stabilizer...")
print("")

sleep(2)


-- ============================================================
-- PD LOOP
-- ============================================================

while true do

    local state = readSensor()


    -- ========================================================
    -- CEL
    --
    -- pitch = 0
    -- roll  = 0
    -- ========================================================

    local desiredPitch =
        -state.pitch * KP_PITCH
        -state.pitchRate * KD_PITCH


    local desiredRoll =
        -state.roll * KP_ROLL
        -state.rollRate * KD_ROLL


    -- ========================================================
    -- OGRANICZENIE ZADANIA
    -- ========================================================

    desiredPitch =
        clamp(
            desiredPitch,
            -MAX_CORRECTION,
            MAX_CORRECTION
        )


    desiredRoll =
        clamp(
            desiredRoll,
            -MAX_CORRECTION,
            MAX_CORRECTION
        )


    -- ========================================================
    -- MACIERZ MIXERA
    -- ========================================================

    local correction =
        calculateMotorCorrections(
            desiredPitch,
            desiredRoll
        )


    -- ========================================================
    -- NORMALIZACJA KOREKCJI
    --
    -- Nie pozwalamy, żeby pojedynczy RSC
    -- dostał absurdalną wartość.
    -- ========================================================

    local biggest = 0

    for i = 1, 4 do

        local value =
            math.abs(correction[i])

        if value > biggest then
            biggest = value
        end

    end


    if biggest > MAX_CORRECTION then

        local scale =
            MAX_CORRECTION / biggest

        for i = 1, 4 do

            correction[i] =
                correction[i] * scale

        end

    end


    -- ========================================================
    -- FINAL RPM
    -- ========================================================

    local rpm = {}


    for i = 1, 4 do

        rpm[i] =
            clamp(
                BASE_RPM + correction[i],
                0,
                MAX_RPM
            )

    end


    -- ========================================================
    -- RSC
    -- ========================================================

    front.setTargetSpeed(rpm[1])
    back.setTargetSpeed(rpm[2])
    left.setTargetSpeed(rpm[3])
    right.setTargetSpeed(rpm[4])


    sleep(DT)

end
