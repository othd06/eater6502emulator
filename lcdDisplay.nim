import raylib

import wires

#d1-7: io8-15
#e: io0
#rw: io1
#rs: io2


var
    characters: array[80, char]
    cursor: int
    
    bitMode8: bool = false

    displayOn: bool = true
    cursorOn: bool = false
    cursorBlinking: bool = false

    cursorMoveDirection: bool = true        #right: true, left: false
    displayShift: bool = false

    oldE: bool = false

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


proc drawChars()=
    #TODO: implement showing the cursor
    if displayOn == false: return

    drawText($characters[0 ], 100-8, 200-8, 16, Black)
    drawText($characters[1 ], 120-8, 200-8, 16, Black)
    drawText($characters[2 ], 140-8, 200-8, 16, Black)
    drawText($characters[3 ], 160-8, 200-8, 16, Black)
    drawText($characters[4 ], 180-8, 200-8, 16, Black)
    drawText($characters[5 ], 200-8, 200-8, 16, Black)
    drawText($characters[6 ], 220-8, 200-8, 16, Black)
    drawText($characters[7 ], 240-8, 200-8, 16, Black)
    drawText($characters[8 ], 260-8, 200-8, 16, Black)
    drawText($characters[9 ], 280-8, 200-8, 16, Black)
    drawText($characters[10], 300-8, 200-8, 16, Black)
    drawText($characters[11], 320-8, 200-8, 16, Black)
    drawText($characters[12], 340-8, 200-8, 16, Black)
    drawText($characters[13], 360-8, 200-8, 16, Black)
    drawText($characters[14], 380-8, 200-8, 16, Black)
    drawText($characters[15], 400-8, 200-8, 16, Black)

    drawText($characters[40], 100-8, 300-8, 16, Black)
    drawText($characters[41], 120-8, 300-8, 16, Black)
    drawText($characters[42], 140-8, 300-8, 16, Black)
    drawText($characters[43], 160-8, 300-8, 16, Black)
    drawText($characters[44], 180-8, 300-8, 16, Black)
    drawText($characters[45], 200-8, 300-8, 16, Black)
    drawText($characters[46], 220-8, 300-8, 16, Black)
    drawText($characters[47], 240-8, 300-8, 16, Black)
    drawText($characters[48], 260-8, 300-8, 16, Black)
    drawText($characters[49], 280-8, 300-8, 16, Black)
    drawText($characters[50], 300-8, 300-8, 16, Black)
    drawText($characters[51], 320-8, 300-8, 16, Black)
    drawText($characters[52], 340-8, 300-8, 16, Black)
    drawText($characters[53], 360-8, 300-8, 16, Black)
    drawText($characters[54], 380-8, 300-8, 16, Black)
    drawText($characters[55], 400-8, 300-8, 16, Black)

proc doInstruction()=
    if io[15]:          #set DDRAM address
        discard
    elif io[14]:        #set CGRAM address
        discard
    elif io[13]:        #function set
        if io[12]:      #8-bit mode
            bitMode8 = true
        else:           #4-bit mode
            bitMode8 = false
        
        if io[11] == false:
            echo "\aError: the display has two lines but instruction send to display in one line mode"
            quit(1)

        if io[10]:
            echo "\nError: the display is 5*8 dots per character but instruction sent to display in 5*10 mode"
            quit(1)
    elif io[12]:        #cursor or display shift
        discard
    elif io[11]:        #display on/off control
        displayOn = io[10]
        cursorOn = io[9]
        cursorBlinking = io[8]
    elif io[10]:        #entry mode set
        cursorMoveDirection = io[9]
        displayShift = io[8]
    elif io[9]:         #return home
        discard
    elif io[8]:         #clear display
        discard


proc loop*()=

    if isKeyPressed(D):
        echo characters
    
    if isKeyPressed(I):
        echo io

    if io[2] == false and io[1] == false and io[0] == true:
        doInstruction()
    
    if io[2] == true and io[1] == false and testEHigh():
        #echo "Char"
        characters[cursor] = cast[char]([io[8], io[9], io[10], io[11], io[12], io[13], io[14], io[15]].dToNum())
        if cursorMoveDirection == true:
            if displayShift == true:
                for i in 0..<cursor:
                    characters[i] = characters[i+1]
            else:
                cursor += 1
        else:
            if displayShift == true:
                var oldChars = characters
                for i in cursor+1..<characters.len():
                    characters[i] = oldChars[i-1]
            else:
                cursor -= 1
    
    drawChars()




