import raylib, nimprof

import
    wires,
    cpu6502,
    clock,
    resetButton,
    arduinoLogger,
    #eaResistors,
    eeprom,
    via65C22,
    #portBleds
    lcdDisplay,
    ram



proc main()=

    initWindow(500, 500, "eater6502emulator")
    setTargetFPS(0)

    
    cpu6502.init()
    clock.init()
    resetButton.init()
    #arduinoLogger.init()
    #eaResistors.init()
    eeprom.init()
    via65C22.init()
    #portBleds.init()
    lcdDisplay.init()
    ram.init()

    m[17] = true


    while not windowShouldClose():
        beginDrawing()
        clearBackground(RayWhite)
        drawFPS(0, 0)

        cpu6502.loop()
        clock.loop()
        resetButton.loop()
        #eaResistors.loop()
        eeprom.loop()
        via65C22.loop()
        #portBleds.loop()
        lcdDisplay.loop()
        ram.loop()

        #arduinoLogger.loop()


        endDrawing()
    
    closeWindow()


main()


