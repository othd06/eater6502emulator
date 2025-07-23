import strutils, raylib

import wires

var
    registers: array[16, uint8]
    regSelect: uint8 = 0

    oldClk: bool = false

const
    PORTA: int = 1
    PORTB: int = 0
    DDA: int = 3
    DDB: int = 2

proc testClkLow(): bool =
    if oldClk == true and clk == false:
        return true
    else:
        return false

proc testClkHigh(): bool =
    if oldClk == false and clk == true:
        oldClk = true
        return true
    else:
        oldClk = clk
        return false


proc init*()=
    discard


proc loop*()=
    if isKeyPressed(B):
        echo "PORTB: " & registers[PORTB].toHex()
        echo "DDB: " & registers[DDB].toHex()
    
    if isKeyPressed(A):
        echo "PORTA: " & registers[PORTA].toHex()
        echo "DDA: " & registers[DDA].toHex()

    if m[1] == true:
        #reset
        for i in 0..<registers.len():
            registers[i] = 0
    if a[0] == true or a[1] == false or a[2] == false:
        return
    regSelect = (a.aToNum() and 0b0000000000001111).uint8
    
    for i in 0..<8:
        if ((registers[DDA] shl i) and 0b10000000) == 0b10000000:
            io[i] = ((registers[PORTA] shl i) and 0b10000000) == 0b10000000
    for i in 0..<8:
        if ((registers[DDB] shl i) and 0b10000000) == 0b10000000:
            io[i+8] = ((registers[PORTB] shl i) and 0b10000000) == 0b10000000
    
    if true:#testClkHigh():
        if regSelect in [0.uint8, 1.uint8]:
            if not m[5]:
                for i in 0..<d.len():
                    if ((registers[regSelect+2] shl i) and 0b10000000) == 0b10000000:
                        if d[i]:
                            registers[regSelect] = registers[regSelect] or (1).uint8 shl (7-i)
                        else:
                            registers[regSelect] = registers[regSelect] and (0xff - ((1).uint8 shl (7-i)))
            else:
                for i in 0..<d.len():
                    if ((registers[regSelect+2] shl i) and 0b10000000) == 0b00000000:
                        d[i] = ((registers[regSelect] shl i) and 0b10000000) == 0b10000000
        elif regSelect in [2.uint8, 3.uint8]:
            if not m[5]:
                registers[regSelect] = 0
                for i in 0..<d.len():
                    registers[regSelect] = registers[regSelect] shl 1
                    registers[regSelect] += d[i].uint8
            else:
                for i in 0..<d.len():
                    d[i] = ((registers[regSelect] shr (7-i)) and 0x10000000) == 0x10000000
    
    discard testClkHigh()






