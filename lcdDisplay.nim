import raylib, math

import wires, signals

#d1-7: io8-15
#e: io0
#rw: io1
#rs: io2


var
    characters: array[80, char]
    oldCharacters: array[80, char]
    cursor: int
    
    bitMode8: bool = false

    displayOnB: bool = false
    cursorOn: bool = false
    cursorBlinking: bool = false

    cursorMoveDirection: bool = true        #right: true, left: false
    displayShift: bool = false

    oldE: bool = false

    listeningDraw: bool = false

    screenBlank: bool = true

proc testELow(): bool =
    if oldE == true and io[0] == false:
        return true
    else:
        return false

proc testEHigh(): bool =
    if oldE == false and io[0] == true:
        oldE = true
        return true
    else:
        oldE = io[0]
        return false



proc init*()=
    for i in 0..<characters.len():
        characters[i] = cast[char](0x95)
    cursor = 0
    #signals.image = loadImage("image.png")
    #signals.texture = loadTextureFromImage(signals.image)

proc drawCursor()=
    if not (cursor in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55]):
        return
    var
        posX: int32 = 0
        posY: int32 = 0
    
    if cursor in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]:
        posY= 210
        posX = 92+cursor.int32*20
    else:
        posY = 215
        posX = cursor.int32*20-708
    
    imageDrawLine(signals.image, posX, posY, posX+16, posY, Black)

proc drawChars()=
    if displayOnB:
        if not screenBlank:
            screenBlank = true
            signals.image = loadImage("image.png")
            signals.texture = loadTextureFromImage(signals.image)
        return

    if draw[1]:
        screenBlank = false
        #echo "draw"
        #echo listeningDraw
        if listeningDraw:
            imageDrawText(signals.image, $characters[0 ], 100-8, 200-8, 16, Black)
            imageDrawText(signals.image, $characters[1 ], 120-8, 200-8, 16, Black)
            imageDrawText(signals.image, $characters[2 ], 140-8, 200-8, 16, Black)
            imageDrawText(signals.image, $characters[3 ], 160-8, 200-8, 16, Black)
            imageDrawText(signals.image, $characters[4 ], 180-8, 200-8, 16, Black)
            imageDrawText(signals.image, $characters[5 ], 200-8, 200-8, 16, Black)
            imageDrawText(signals.image, $characters[6 ], 220-8, 200-8, 16, Black)
            imageDrawText(signals.image, $characters[7 ], 240-8, 200-8, 16, Black)
            imageDrawText(signals.image, $characters[8 ], 260-8, 200-8, 16, Black)
            imageDrawText(signals.image, $characters[9 ], 280-8, 200-8, 16, Black)
            imageDrawText(signals.image, $characters[10], 300-8, 200-8, 16, Black)
            imageDrawText(signals.image, $characters[11], 320-8, 200-8, 16, Black)
            imageDrawText(signals.image, $characters[12], 340-8, 200-8, 16, Black)
            imageDrawText(signals.image, $characters[13], 360-8, 200-8, 16, Black)
            imageDrawText(signals.image, $characters[14], 380-8, 200-8, 16, Black)
            imageDrawText(signals.image, $characters[15], 400-8, 200-8, 16, Black)

            imageDrawText(signals.image, $characters[40], 100-8, 300-8, 16, Black)
            imageDrawText(signals.image, $characters[41], 120-8, 300-8, 16, Black)
            imageDrawText(signals.image, $characters[42], 140-8, 300-8, 16, Black)
            imageDrawText(signals.image, $characters[43], 160-8, 300-8, 16, Black)
            imageDrawText(signals.image, $characters[44], 180-8, 300-8, 16, Black)
            imageDrawText(signals.image, $characters[45], 200-8, 300-8, 16, Black)
            imageDrawText(signals.image, $characters[46], 220-8, 300-8, 16, Black)
            imageDrawText(signals.image, $characters[47], 240-8, 300-8, 16, Black)
            imageDrawText(signals.image, $characters[48], 260-8, 300-8, 16, Black)
            imageDrawText(signals.image, $characters[49], 280-8, 300-8, 16, Black)
            imageDrawText(signals.image, $characters[50], 300-8, 300-8, 16, Black)
            imageDrawText(signals.image, $characters[51], 320-8, 300-8, 16, Black)
            imageDrawText(signals.image, $characters[52], 340-8, 300-8, 16, Black)
            imageDrawText(signals.image, $characters[53], 360-8, 300-8, 16, Black)
            imageDrawText(signals.image, $characters[54], 380-8, 300-8, 16, Black)
            imageDrawText(signals.image, $characters[55], 400-8, 300-8, 16, Black)

            if cursorOn:
                if cursorBlinking:
                    if getTime() mod 0.8 < 0.4:
                        drawCursor()
                else:
                    drawCursor()
            

            draw[0] -= 1
            listeningDraw = false
            if draw[0] <= 0:
                signals.texture = loadTextureFromImage(signals.image)
                draw[1] = false
    else:
        if listeningDraw == false:
            #echo "listening"
            listeningDraw = true
            draw[0] += 1
    

    if oldCharacters != characters:
        oldCharacters = characters
        signals.image = loadImage("image.png")
        if draw[0] > 0:
            draw[1] = true

proc doInstruction()=
    if io[8]:          #set DDRAM address
        discard
    elif io[9]:        #set CGRAM address
        discard
    elif io[10]:        #function set
        if io[11]:      #8-bit mode
            bitMode8 = true
        else:           #4-bit mode
            bitMode8 = false
        
        if io[12] == false:
            echo "\aError: the display has two lines but instruction send to display in one line mode"
            quit(1)

        if io[13]:
            echo "\nError: the display is 5*8 dots per character but instruction sent to display in 5*10 mode"
            quit(1)
    elif io[11]:        #cursor or display shift
        discard
    elif io[12]:        #display on/off control
        displayOnB = not io[13]
        cursorOn = io[14]
        cursorBlinking = io[15]
    elif io[13]:        #entry mode set
        cursorMoveDirection = io[14]
        displayShift = io[15]
    elif io[14]:         #return home
        cursor = 0
    elif io[15]:         #clear display
        #echo "clear"
        init()


proc loop*()=
    #imageDrawText(signals.image, $cursor, 400, 100, 50, Black)

    #if isKeyPressed(D):
    #    echo characters
    
    #if isKeyPressed(I):
    #    echo io

    if io[2] == false and io[1] == false and io[0] == true:
        doInstruction()
    
    if (io[0] or io[1] or io[2]) == false:
        io[15] = false
        #TODO: work out what io:14-8 should be
    
    if io[2] == true and io[1] == false and testEHigh():
        #echo "Char"
        if cursorMoveDirection == true:
            if displayShift == true:
                for i in 0..<cursor:
                    characters[i] = characters[i+1]
                characters[cursor] = cast[char]([io[8], io[9], io[10], io[11], io[12], io[13], io[14], io[15]].dToNum())
            else:
                characters[cursor] = cast[char]([io[8], io[9], io[10], io[11], io[12], io[13], io[14], io[15]].dToNum())
                cursor += 1
                if cursor >= characters.len():
                    cursor = 0
        else:
            if displayShift == true:
                var oldChars = characters
                for i in cursor+1..<characters.len():
                    characters[i] = oldChars[i-1]
                characters[cursor] = cast[char]([io[8], io[9], io[10], io[11], io[12], io[13], io[14], io[15]].dToNum())
            else:
                characters[cursor] = cast[char]([io[8], io[9], io[10], io[11], io[12], io[13], io[14], io[15]].dToNum())
                cursor -= 1
                if cursor < 0:
                    cursor = characters.len()-1
    
    drawChars()




