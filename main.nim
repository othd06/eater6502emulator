import raylib
#import nimprof

import
    wires,
    signals,
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
    setTargetFPS(100)

    
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
        #drawTexture(signals.texture, 0, 0, White)
        clearBackground(RayWhite)
        drawFPS(0, 0)

        for i in 0..<20000:
            clock.loop()
            cpu6502.loop()
            resetButton.loop()
            eeprom.loop()
            via65C22.loop()
            lcdDisplay.loop()
            ram.loop()

            #arduinoLogger.loop()

        lcdDisplay.drawLoop()

        endDrawing()
    
    closeWindow()


main()


