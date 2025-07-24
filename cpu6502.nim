import strutils, raylib

import wires

var
    oldClk: bool = false

    progCounter: uint16
    aReg: uint8
    xReg: uint8
    stackPointer: uint8

    flags: array[8, bool]

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


proc changeState(newState: (proc(), proc(), proc()))
var fetch: (proc(), proc(), proc())


#region RORa

proc RORaInit()=
    discard

proc RORaMain()=
    if testClkHigh():
        var tmpCarry: bool = flags[0]
        flags[0] = (aReg and 0b00000001) == 1
        aReg = aReg shr 1
        aReg += tmpCarry.uint8 shl 7
        changeState(fetch)

proc RORaEnd()=
    discard

var RORa: (proc(), proc(), proc()) = (RORaInit, RORaMain, RORaEnd)

#endregion

#region JMPa
var
    JMPaClocks: int = 0
    JMPaAddress: uint16 = 0

proc JMPaInit()=
    JMPaClocks = 0

proc JMPaMain()=
    if testClkHigh():
        if JMPaClocks == 0:
            JMPaAddress = d.dToNum()
            progCounter += 1
            for i in 0..<a.len():
                a[i] = ((progCounter shl i) and 0b1000000000000000) == 0b1000000000000000
        elif JMPaCLocks == 1:
            JMPaAddress += d.dToNum.uint16 shl 8
            progCounter = JMPaAddress
            changeState(fetch)
        JMPaClocks += 1

proc JMPaEnd()=
    discard

var JMPa: (proc(), proc(), proc()) = (JMPaInit, JMPaMain, JMPaEnd)
#endregion

#region JSRa
var
    JSRaClocks: int = 0
    JSRaAddress: uint16 = 0

proc JSRaInit()=
    JSRaClocks = 0
    JSRAAddress = 0

proc JSRaMain()=
    if testClkLow():
        if JSRaClocks == 4:
            m[5] = true
    if testClkHigh():
        if JSRaClocks == 0:
            JSRaAddress = d.dToNum()
            progCounter += 1
            for i in 0..<a.len():
                a[i] = (((0x100.uint16 + stackPointer.uint16) shl i) and 0b1000000000000000) == 0b1000000000000000
        elif JSRaClocks == 1:
            for i in 0..<a.len():
                a[i] = (((0x100.uint16 + stackPointer.uint16) shl i) and 0b1000000000000000) == 0b1000000000000000
            for i in 0..<d.len():
                d[i] = (((progCounter shr 8).uint8 shl i) and 0b10000000) == 0b10000000
            m[5] = false
            stackPointer -= 1
        elif JSRaClocks == 2:
            for i in 0..<a.len():
                a[i] = (((0x100.uint16 + stackPointer.uint16) shl i) and 0b1000000000000000) == 0b1000000000000000
            for i in 0..<d.len():
                d[i] = (((progCounter).uint8 shl i) and 0b10000000) == 0b10000000
            m[5] = false
            stackPointer -= 1
        elif JSRaCLocks == 3:
            for i in 0..<a.len():
                a[i] = ((progCounter shl i) and 0b1000000000000000) == 0b1000000000000000
        elif JSRaClocks == 4:
            JSRaAddress += d.dToNum.uint16 shl 8
            progCounter = JSRaAddress
            changeState(fetch)
            
        JSRaClocks += 1

proc JSRaEnd()=
    discard

var JSRa: (proc(), proc(), proc()) = (JSRaInit, JSRaMain, JSRaEnd)
#endregion

#region RTSs
var 
    RTSsClocks: int = 0
    RTSsAddress: uint16 = 0

proc RTSsInit()=
    RTSsClocks = 0
    RTSsAddress = 0

proc RTSsMain()=
    if testClkHigh():
        if RTSsClocks == 0:
            for i in 0..<a.len():
                a[i] = (((0x100.uint16 + stackPointer.uint16) shl i) and 0b1000000000000000) == 0b1000000000000000
            stackPointer += 1
        if RTSsClocks == 1:
            for i in 0..<a.len():
                a[i] = (((0x100.uint16 + stackPointer.uint16) shl i) and 0b1000000000000000) == 0b1000000000000000
            stackPointer += 1
        if RTSsClocks == 2:
            RTSsAddress += d.dToNum()
            for i in 0..<a.len():
                a[i] = (((0x100.uint16 + stackPointer.uint16) shl i) and 0b1000000000000000) == 0b1000000000000000
            #stackPointer += 1
        if RTSsClocks == 3:
            RTSsAddress += (d.dToNum().uint16) shl 8
            progCounter = RTSsAddress
            for i in 0..<a.len():
                a[i] = ((progCounter shl i) and 0b1000000000000000) == 0b1000000000000000
        if RTSsClocks == 4:
            progCounter += 1
            changeState(fetch)
        RTSsClocks += 1

proc RTSsEnd()=
    discard

var RTSs: (proc(), proc(), proc()) = (RTSsInit, RTSsMain, RTSsEnd)
#endregion

#region PHAi
var
    PHAiClocks: int = 0

proc PHAiInit()=
    PHAiClocks = 0

proc PHAiMain()=
    if testClkLow():
        if PHAiClocks == 2:
            changeState(fetch)
    if testClkHigh():
        if PHAiClocks == 0:
            for i in 0..<a.len():
                a[i] = (((0x100 + stackPointer.uint16) shl i) and 0b1000000000000000) == 0b1000000000000000
            m[5] = false
            for i in 0..<d.len():
                d[i] = ((aReg shl i) and 0b10000000) == 0b10000000
        elif PHAiClocks == 1:
            stackPointer -= 1
        PHAiClocks += 1

proc PHAiEnd()=
    discard

var PHAi: (proc(), proc(), proc()) = (PHAiInit, PHAiMain, PHAiEnd)
#endregion

#region PLAs
var
    PLAsClocks: int = 0

proc PLAsInit()=
    PLAsClocks = 0

proc PLAsMain()=
    if testCLkLow():
        if PLAsClocks == 1:
            discard
        if PLAsClocks == 2:
            aReg = d.dToNum()
    if testClkHigh():
        if PLAsClocks == 0:
            for i in 0..<a.len():
                a[i] = (((0x100 + stackPointer.uint16) shl i) and 0b1000000000000000) == 0b1000000000000000
        elif PLAsClocks == 1:
            stackPointer += 1
            for i in 0..<a.len():
                a[i] = (((0x100 + stackPointer.uint16) shl i) and 0b1000000000000000) == 0b1000000000000000
        elif PLAsClocks == 2:
            changeState(fetch)
        PLAsClocks += 1

proc PLAsEnd()=
    flags[1] = aReg==0
    flags[7] = cast[int8](aReg)<0

var PLAs: (proc(), proc(), proc()) = (PLAsInit, PLAsMain, PLAsEnd)
#endregion

#region STAa
var
    STAaAddress: uint16 = 0
    STAaClocks: int = 0

proc STAaInit()=
    STAaAddress = 0
    STAaClocks = 0

proc STAaMain()=
    if testClkHigh():
        if STAaClocks == 0:
            STAaAddress += d.dToNum()
            progCounter += 1
            for i in 0..<a.len():
                a[i] = ((progCounter shl i) and 0b1000000000000000) == 0b1000000000000000
            STAaClocks += 1
        elif STAaClocks == 1:
            STAaAddress += d.dToNum().uint16 shl 8
            progCounter += 1
            for i in 0..<a.len():
                a[i] = ((STAaAddress shl i) and 0b1000000000000000) == 0b1000000000000000
            for i in 0..<d.len():
                d[i] = ((aReg shl i) and 0b10000000) == 0b10000000
            m[5] = false
            STAaClocks += 1
            #echo("address: " & STAaAddress.toHex())
        elif STAaClocks == 2:
            changeState(fetch)


proc STAaEnd()=
    m[5] = true

var STAa: (proc(), proc(), proc()) = (STAaInit, STAaMain, STAaEnd)

#endregion

#region TXSi
proc TXSiInit()=
    discard

proc TXSiMain()=
    if testClkHigh():
        stackPointer = xReg
        changeState(fetch)

proc TXSiEnd()=
    discard

var TXSi: (proc(), proc(), proc()) = (TXSiInit, TXSiMain, TXSiEnd)
#endregion

#region LDXi

var
    LDXiClocked: bool = false

proc LDXiInit()=
    LDXiClocked = false

proc LDXiMain()=
    if testClkLow():
        if LDXiClocked:
            xReg = d.dToNum()
            progCounter += 1
            changeState(fetch)
    if testClkHigh():
        if not LDXiClocked:
            for i in 0..<a.len():
                a[i] = ((progCounter shl i) and 0b1000000000000000) == 0b1000000000000000
            LDXiClocked = true

proc LDXiEnd()=
    discard

var LDXi: (proc(), proc(), proc()) = (LDXiInit, LDXiMain, LDXiEnd)
#endregion

#region LDAi

var
    LDAiClocked: bool = false

proc LDAiInit()=
    LDAiClocked = false

proc LDAiMain()=
    if testClkLow():
        if LDAiClocked:
            aReg = d.dToNum()
            progCounter += 1
            changeState(fetch)
    if testClkHigh():
        if not LDAiClocked:
            for i in 0..<a.len():
                a[i] = ((progCounter shl i) and 0b1000000000000000) == 0b1000000000000000
            LDAiClocked = true

proc LDAiEnd()=
    flags[1] = aReg==0
    flags[7] = cast[int8](aReg)<0

var LDAi: (proc(), proc(), proc()) = (LDAiInit, LDAiMain, LDAiEnd)
#endregion

#region LDAa
var
    LDAaClocks: int = 0
    LDAaAddress: uint16 = 0

proc LDAaInit()=
    LDAaClocks = 0
    LDAaAddress = 0

proc LDAaMain()=
    if testClkHigh():
        if LDAaClocks == 0:
            LDAaAddress += d.dToNum()
            progCounter += 1
            for i in 0..<a.len():
                a[i] = ((progCounter shl i) and 0b1000000000000000) == 0b1000000000000000
        if LDAaClocks == 1:
            LDAaAddress += (d.dToNum().uint16 shl 8)
            for i in 0..<a.len():
                a[i] = ((LDAaAddress shl i) and 0b1000000000000000) == 0b1000000000000000
        if LDAaClocks == 2:
            aReg = d.dToNum()
            progCounter += 1
            changeState(fetch)
        LDAaClocks += 1

proc LDAaEnd()=
    flags[1] = aReg==0
    flags[7] = cast[int8](aReg)<0

var LDAa: (proc(), proc(), proc()) = (LDAaInit, LDAaMain, LDAaEnd)
#endregion

#region LDAax
var
    LDAaxClocks: int = 0
    LDAaxAddress: uint16 = 0
    LDAaxPageCrossed: bool = false

proc LDAaxInit()=
    LDAaxClocks = 0
    LDAaxAddress = 0
    LDAaxPageCrossed = false

proc LDAaxMain()=
    if testClkHigh():
        if LDAaxClocks == 0:
            LDAaxAddress += d.dToNum()
            progCounter += 1
            for i in 0..<a.len():
                a[i] = ((progCounter shl i) and 0b1000000000000000) == 0b1000000000000000
        if LDAaxClocks == 1:
            if LDAaxPageCrossed != true:
                LDAaxAddress += (d.dToNum().uint16 shl 8)
                var highByte: uint8 = (LDAaxAddress shr 8).uint8
                LDAaxAddress += xReg
                if (LDAaxAddress shr 8).uint8 != highByte:
                    LDAaxPageCrossed = true
                    LDAaxClocks -= 1
                else:
                    for i in 0..<a.len():
                        a[i] = ((LDAaxAddress shl i) and 0b1000000000000000) == 0b1000000000000000
            else:
                for i in 0..<a.len():
                    a[i] = ((LDAaxAddress shl i) and 0b1000000000000000) == 0b1000000000000000
        if LDAaxClocks == 2:
            aReg = d.dToNum()
            progCounter += 1
            changeState(fetch)
        LDAaxClocks += 1

proc LDAaxEnd()=
    flags[1] = aReg==0
    flags[7] = cast[int8](aReg)<0

var LDAax: (proc(), proc(), proc()) = (LDAaxInit, LDAaxMain, LDAaxEnd)
#endregion

#region BEQr
var
    BEQrShouldChange: bool = false
    BEQrClocks: int = 0
    BEQrHighByte: uint8 = 0

proc BEQrInit()=
    BEQrShouldChange = false
    BEQrClocks = 0
    BEQrHighByte = 0

proc BEQrMain()=
    if testClkHigh():
        if flags[1]:
            if BEQrClocks == 0:
                progCounter += 1
                BEQrHighByte = (progCounter shr 8).uint8
            if BEQrClocks == 1:
                if d[0]:
                    progCounter -= not d.dToNum()
                    progCounter -= 1
                else:
                    progCounter += d.dToNum()
                if BEQrHighByte == (progCounter shr 8).uint8:
                    changeState(fetch)
            if BEQrClocks == 2:
                changeState(fetch)
            BEQrClocks += 1
        else:
            progCounter += 1
            BEQrShouldChange = true
    if BEQrShouldChange:
        changeState(fetch)

proc BEQrEnd()=
    discard

var BEQr: (proc(), proc(), proc()) = (BEQrInit, BEQrMain, BEQrEnd)
#endregion

#region BNEr
var
    BNErShouldChange: bool = false
    BNErClocks: int = 0
    BNErHighByte: uint8 = 0

proc BNErInit()=
    BNErShouldChange = false
    BNErClocks = 0
    BNErHighByte = 0

proc BNErMain()=
    if testClkHigh():
        if flags[1] == false:
            if BNErClocks == 0:
                progCounter += 1
                BNErHighByte = (progCounter shr 8).uint8
            if BNErClocks == 1:
                if d[0]:
                    progCounter -= not d.dToNum()
                    progCounter -= 1
                else:
                    progCounter += d.dToNum()
                if BNErHighByte == (progCounter shr 8).uint8:
                    changeState(fetch)
            if BNErClocks == 2:
                changeState(fetch)
            BNErClocks += 1
        else:
            progCounter += 1
            BNErShouldChange = true
    if BNErShouldChange:
        changeState(fetch)

proc BNErEnd()=
    discard

var BNEr: (proc(), proc(), proc()) = (BNErInit, BNErMain, BNErEnd)
#endregion

#region INXi

proc INXiInit()=
    discard

proc INXiMain()=
    if testClkHigh():
        xReg += 1
        changeState(fetch)

proc INXiEnd()=
    flags[1] = xReg==0
    flags[7] = cast[int8](xReg)<0

var INXi: (proc(), proc(), proc()) = (INXiInit, INXiMain, INXiEnd)
#endregion

#region LDAi

var
    ANDiClocked: bool = false

proc ANDiInit()=
    ANDiClocked = false

proc ANDiMain()=
    if testClkLow():
        if ANDiClocked:
            aReg = aReg and d.dToNum()
            progCounter += 1
            changeState(fetch)
    if testClkHigh():
        if not ANDiClocked:
            for i in 0..<a.len():
                a[i] = ((progCounter shl i) and 0b1000000000000000) == 0b1000000000000000
            ANDiClocked = true

proc ANDiEnd()=
    flags[1] = aReg==0
    flags[7] = cast[int8](aReg)<0

var ANDi: (proc(), proc(), proc()) = (ANDiInit, ANDiMain, ANDiEnd)
#endregion

#region nop
proc nopInit()=
    return

proc nopMain()=
    if testClkHigh():
        changeState(fetch)

proc nopEnd()=
    return

var NOP: (proc(), proc(), proc()) = (nopInit, nopMain, nopEnd)
#endregion

proc fetchTest()=
    if d.dToNum == 0x20:
        changeState(JSRa)
    elif d.dToNum == 0x29:
        changeState(ANDi)
    elif d.dToNum == 0x48:
        changeState(PHAi)
    elif d.dToNum == 0x4C:
        changeState(JMPa)
    elif d.dToNum == 0x60:
        changeState(RTSs)
    elif d.dToNum == 0x68:
        changeState(PLAs)
    elif d.dToNum == 0x6A:
        changeState(RORa)
    elif d.dToNum == 0x8D:
        changeState(STAa)
    elif d.dToNum == 0x9A:
        changeState(TXSi)
    elif d.dToNum == 0xA2:
        changeState(LDXi)
    elif d.dToNum == 0xA9:
        changeState(LDAi)
    elif d.dToNum == 0xAD:
        changeState(LDAa)
    elif d.dToNum == 0xBD:
        changeState(LDAax)
    elif d.dToNum == 0xD0:
        changeState(BNEr)
    elif d.dToNum == 0xE8:
        changeState(INXi)
    elif d.dToNum == 0xEA:
        changeState(NOP)
    elif d.dToNum == 0xF0:
        changeState(BEQr)
    else:
        echo("\aError: cannot decode instruction with opcode: " & d.dToNum().toHex())
        quit(1)

#region fetch
proc fetchInit()=
    m[5] = true
    for i in 0..<a.len():
        a[i] = ((progCounter shl i) and 0b1000000000000000) == 0b1000000000000000

proc fetchMain()=
    if testClkHigh():
        fetchTest()

proc fetchEnd()=
    progCounter += 1
    for i in 0..<a.len():
        a[i] = ((progCounter shl i) and 0b1000000000000000) == 0b1000000000000000

fetch = (fetchInit, fetchMain, fetchEnd)

#endregion


#region reset
var
    resetClkCount: int = 0

proc resetInit()=
    resetClkCount = 0
    m[5] = true

proc resetMain()=
    if resetClkCount == 9 and testClkLow():
        for i in d:
            progCounter = progCounter shl 1
            progCounter += i.uint16
        progCounter = (progCounter shl 8) + (progCounter shr 8)
        changeState(fetch)
    if testClkHigh():
        resetClkCount += 1
        if resetClkCount == 7:
            a = [true, true, true, true, true, true, true, true, true, true, true, true, true, true, false, false]
        if resetClkCount == 8:
            progCounter = 0
            for i in d:
                progCounter = progCounter shl 1
                progCounter += i.uint16
            a = [true, true, true, true, true, true, true, true, true, true, true, true, true, true, false, true]


proc resetEnd()=
    return

let reset: (proc(), proc(), proc()) = (resetInit, resetMain, resetEnd)

#endregion






var currentState: (proc(), proc(), proc()) = reset


proc changeState(newState: (proc(), proc(), proc()))=
    currentState[2]()
    currentState = newState
    currentState[0]()


proc init*()=
    changeState(reset)

proc loop*()=
    if isKeyPressed(X):
        echo "xReg: " & xReg.toHex()
    if isKeyPressed(S):
        echo "stackPointer: " & stackPointer.toHex()

    if m[1] == true:
        changeState(reset)
    
    currentState[1]()
