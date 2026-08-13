while true do

    local currentX, currentY, currentZ = getGPS()

    if not currentX then
        print("Brak GPS!")
        stop()
        sleep(0.5)
    else

        local now = os.clock()
        local dt = now - lastTime

        if dt <= 0 then
            dt = 0.1
        end

        -- =====================================
        -- POSITION ERROR
        -- =====================================

        local errorX = TARGET_X - currentX
        local errorY = TARGET_Y - currentY
        local errorZ = TARGET_Z - currentZ

        -- =====================================
        -- VELOCITY
        -- =====================================

        local velocityX =
            (currentX - lastX) / dt

        local velocityY =
            (currentY - lastY) / dt

        local velocityZ =
            (currentZ - lastZ) / dt

        -- =====================================
        -- PD CONTROLLER
        -- =====================================

        local controlX =
            KP_X * errorX -
            KD_X * velocityX

        local controlY =
            KP_Y * errorY -
            KD_Y * velocityY

        local controlZ =
            KP_Z * errorZ -
            KD_Z * velocityZ

        -- Ograniczenie sterowania

        controlX = math.max(
            -MAX_CONTROL,
            math.min(MAX_CONTROL, controlX)
        )

        controlY = math.max(
            -MAX_CONTROL,
            math.min(MAX_CONTROL, controlY)
        )

        controlZ = math.max(
            -MAX_CONTROL,
            math.min(MAX_CONTROL, controlZ)
        )

        -- =====================================
        -- MOTOR MIXING
        -- =====================================

        local frontRPM = BASE_RPM
        local backRPM  = BASE_RPM
        local leftRPM  = BASE_RPM
        local rightRPM = BASE_RPM

        -- X
        leftRPM  = leftRPM  + controlX
        rightRPM = rightRPM - controlX

        -- Z
        frontRPM = frontRPM + controlZ
        backRPM  = backRPM  - controlZ

        -- Y
        frontRPM = frontRPM + controlY
        backRPM  = backRPM + controlY
        leftRPM  = leftRPM + controlY
        rightRPM = rightRPM + controlY

        -- =====================================
        -- SEND RPM
        -- =====================================

        setSpeed(front, frontRPM)
        setSpeed(back, backRPM)
        setSpeed(left, leftRPM)
        setSpeed(right, rightRPM)

        -- =====================================
        -- DISPLAY
        -- =====================================

        term.clear()
        term.setCursorPos(1, 1)

        print("DRONE PD CONTROLLER")
        print("-------------------")

        print(string.format(
            "POS %.1f %.1f %.1f",
            currentX,
            currentY,
            currentZ
        ))

        print(string.format(
            "ERR %.1f %.1f %.1f",
            errorX,
            errorY,
            errorZ
        ))

        print(string.format(
            "VEL %.1f %.1f %.1f",
            velocityX,
            velocityY,
            velocityZ
        ))

        print("")

        print(string.format(
            "PD %.1f %.1f %.1f",
            controlX,
            controlY,
            controlZ
        ))

        print("")

        print(string.format(
            "RPM F:%d B:%d",
            frontRPM,
            backRPM
        ))

        print(string.format(
            "RPM L:%d R:%d",
            leftRPM,
            rightRPM
        ))

        -- =====================================
        -- TARGET CHECK
        -- =====================================

        local distance = math.sqrt(
            errorX^2 +
            errorY^2 +
            errorZ^2
        )

        if distance < 1 then

            print("")
            print("TARGET REACHED!")

            stop()

            break
        end

        -- =====================================
        -- SAVE STATE
        -- =====================================

        lastX = currentX
        lastY = currentY
        lastZ = currentZ

        lastTime = now

        sleep(0.1)
    end
end
