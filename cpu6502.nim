import strutils, raylib

import wires, signals

var
    oldClk: bool = false
    oldNMI: bool = false

    progCounter: uint16
    aReg: uint8
    xReg: uint8
    yReg: uint8
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


#region RORA

proc RORAInit()=
    discard

proc RORAMain()=
    if testClkHigh():
        var tmpCarry: bool = flags[0]
        flags[0] = (aReg and 0b00000001) == 1
        aReg = aReg shr 1
        aReg += tmpCarry.uint8 shl 7
        changeState(fetch)

proc RORAEnd()=
    discard

var RORA: (proc(), proc(), proc()) = (RORAInit, RORAMain, RORAEnd)

#endregion

#region ROLa
var
    ROLaClocks: int = 0
    ROLaAddress: uint16 = 0
    ROLaReg: uint8 = 0

proc ROLaInit()=
    ROLaClocks = 0
    ROLaAddress = 0
    ROLaReg = 0

proc ROLaMain()=
    if testClkHigh():
        if ROLaClocks == 0:
            ROLaAddress = d.dToNum().uint16
            progCOunter += 1
            for i in 0..<a.len():
                a[i] = ((progCounter shl i) and 0b1000000000000000) == 0b1000000000000000
        if ROLaClocks == 1:
            ROLaAddress += d.dToNum().uint16 shl 8
            progCounter += 1
            for i in 0..<a.len():
                a[i] = ((ROLaAddress shl i) and 0b1000000000000000) == 0b1000000000000000
        if ROLaClocks == 2:
            ROLaReg = d.dToNum()
            var tempCarry: bool = flags[0]
            flags[0] = (ROLaReg and 0b10000000) == 0b10000000
            ROLaReg = ROLaReg shl 1
            ROLaReg += tempCarry.uint8
        if ROLaClocks == 3:
            m[5] = false
            for i in 0..<d.len():
                d[i] = ((ROLaReg shl i) and 0b10000000) == 0b10000000
        if ROLaClocks == 4:
            m[5] = true
            changeState(fetch)
        ROLaClocks += 1

proc ROLaEnd()=
    flags[1] = aReg == 0        #WARNING: this code may be incorrect
    flags[7] = cast[int8](ROLaReg) < 0

var ROLa: (proc(), proc(), proc()) = (ROLaInit, ROLaMain, ROLaEnd)
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
    if subReturn[0] > 0:
        subReturn[1] = true

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

#region STAay
var
    STAayAddress: uint16 = 0
    STAayClocks: int = 0

proc STAayInit()=
    STAayAddress = 0
    STAayClocks = 0

proc STAayMain()=
    if testClkHigh():
        if STAayClocks == 0:
            STAayAddress += d.dToNum()
            progCounter += 1
            for i in 0..<a.len():
                a[i] = ((progCounter shl i) and 0b1000000000000000) == 0b1000000000000000
            STAayClocks += 1
        elif STAayClocks == 1:
            STAayAddress += d.dToNum().uint16 shl 8
            STAayAddress += yReg.uint16
            progCounter += 1
            for i in 0..<a.len():
                a[i] = ((STAayAddress shl i) and 0b1000000000000000) == 0b1000000000000000
            for i in 0..<d.len():
                d[i] = ((aReg shl i) and 0b10000000) == 0b10000000
            m[5] = false
            STAayClocks += 1
            #echo("address: " & STAaAddress.toHex())
        elif STAayClocks == 2:
            STAayClocks += 1
        elif STAayClocks == 3:
            changeState(fetch)


proc STAayEnd()=
    m[5] = true

var STAay: (proc(), proc(), proc()) = (STAayInit, STAayMain, STAayEnd)

#endregion

#region STYa
var
    STYaAddress: uint16 = 0
    STYaClocks: int = 0

proc STYaInit()=
    STYaAddress = 0
    STYaClocks = 0

proc STYaMain()=
    if testClkHigh():
        if STYaClocks == 0:
            STYaAddress += d.dToNum()
            progCounter += 1
            for i in 0..<a.len():
                a[i] = ((progCounter shl i) and 0b1000000000000000) == 0b1000000000000000
            STYaClocks += 1
        elif STYaClocks == 1:
            STYaAddress += d.dToNum().uint16 shl 8
            progCounter += 1
            for i in 0..<a.len():
                a[i] = ((STYaAddress shl i) and 0b1000000000000000) == 0b1000000000000000
            for i in 0..<d.len():
                d[i] = ((yReg shl i) and 0b10000000) == 0b10000000
            m[5] = false
            STYaClocks += 1
            #echo("address: " & STAaAddress.toHex())
        elif STYaClocks == 2:
            changeState(fetch)


proc STYaEnd()=
    m[5] = true

var STYa: (proc(), proc(), proc()) = (STYaInit, STYaMain, STYaEnd)
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

#region TAYi
proc TAYiInit()=
    discard

proc TAYiMain()=
    if testClkHigh():
        yReg = aReg
        changeState(fetch)

proc TAYiEnd()=
    flags[1] = yReg == 0
    flags[7] = cast[int8](yReg) < 0

var TAYi: (proc(), proc(), proc()) = (TAYiInit, TAYiMain, TAYiEnd)
#endregion

#region TAXi
proc TAXiInit()=
    discard

proc TAXiMain()=
    if testClkHigh():
        xReg = aReg
        changeState(fetch)

proc TAXiEnd()=
    flags[1] = xReg == 0
    flags[7] = cast[int8](xReg) < 0

var TAXi: (proc(), proc(), proc()) = (TAXiInit, TAXiMain, TAXiEnd)
#endregion

#region TXAi
proc TXAiInit()=
    discard

proc TXAiMain()=
    if testClkHigh():
        aReg = xReg
        changeState(fetch)

proc TXAiEnd()=
    flags[1] = aReg == 0
    flags[7] = cast[int8](aReg) < 0

var TXAi: (proc(), proc(), proc()) = (TXAiInit, TXAiMain, TXAiEnd)
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

#region LDYi
var
    LDYiClocked: bool = false

proc LDYiInit()=
    LDYiClocked = false

proc LDYiMain()=
    if testClkLow():
        if LDYiClocked:
            yReg = d.dToNum()
            progCounter += 1
            changeState(fetch)
    if testClkHigh():
        if not LDYiClocked:
            for i in 0..<a.len():
                a[i] = ((progCounter shl i) and 0b1000000000000000) == 0b1000000000000000
            LDYiClocked = true

proc LDYiEnd()=
    flags[1] = yReg==0
    flags[7] = cast[int8](yReg)<0

var LDYi: (proc(), proc(), proc()) = (LDYiInit, LDYiMain, LDYiEnd)
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

#region LDAay
var
    LDAayClocks: int = 0
    LDAayAddress: uint16 = 0
    LDAayPageCrossed: bool = false

proc LDAayInit()=
    LDAayClocks = 0
    LDAayAddress = 0
    LDAayPageCrossed = false

proc LDAayMain()=
    if testClkHigh():
        if LDAayClocks == 0:
            LDAayAddress += d.dToNum()
            progCounter += 1
            for i in 0..<a.len():
                a[i] = ((progCounter shl i) and 0b1000000000000000) == 0b1000000000000000
        if LDAayClocks == 1:
            if LDAayPageCrossed != true:
                LDAayAddress += (d.dToNum().uint16 shl 8)
                var highByte: uint8 = (LDAayAddress shr 8).uint8
                LDAayAddress += yReg
                if (LDAayAddress shr 8).uint8 != highByte:
                    LDAayPageCrossed = true
                    LDAayClocks -= 1
                else:
                    for i in 0..<a.len():
                        a[i] = ((LDAayAddress shl i) and 0b1000000000000000) == 0b1000000000000000
            else:
                for i in 0..<a.len():
                    a[i] = ((LDAayAddress shl i) and 0b1000000000000000) == 0b1000000000000000
        if LDAayClocks == 2:
            aReg = d.dToNum()
            progCounter += 1
            changeState(fetch)
        LDAayClocks += 1

proc LDAayEnd()=
    flags[1] = aReg==0
    flags[7] = cast[int8](aReg)<0

var LDAay: (proc(), proc(), proc()) = (LDAayInit, LDAayMain, LDAayEnd)
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

#region BCCr
var
    BCCrShouldChange: bool = false
    BCCrClocks: int = 0
    BCCrHighByte: uint8 = 0

proc BCCrInit()=
    BCCrShouldChange = false
    BCCrClocks = 0
    BCCrHighByte = 0

proc BCCrMain()=
    if testClkHigh():
        if not flags[0]:
            if BCCrClocks == 0:
                progCounter += 1
                BCCrHighByte = (progCounter shr 8).uint8
            if BCCrClocks == 1:
                if d[0]:
                    progCounter -= not d.dToNum()
                    progCounter -= 1
                else:
                    progCounter += d.dToNum()
                if BCCrHighByte == (progCounter shr 8).uint8:
                    changeState(fetch)
            if BCCrClocks == 2:
                changeState(fetch)
            BCCrClocks += 1
        else:
            progCounter += 1
            BCCrShouldChange = true
    if BCCrShouldChange:
        changeState(fetch)

proc BCCrEnd()=
    discard

var BCCr: (proc(), proc(), proc()) = (BCCrInit, BCCrMain, BCCrEnd)
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

#region INYi

proc INYiInit()=
    discard

proc INYiMain()=
    if testClkHigh():
        yReg += 1
        changeState(fetch)

proc INYiEnd()=
    flags[1] = yReg==0
    flags[7] = cast[int8](yReg)<0

var INYi: (proc(), proc(), proc()) = (INYiInit, INYiMain, INYiEnd)
#endregion

#region DEXi

proc DEXiInit()=
    discard

proc DEXiMain()=
    if testClkHigh():
        xReg -= 1
        changeState(fetch)

proc DEXiEnd()=
    flags[1] = xReg==0
    flags[7] = cast[int8](xReg)<0

var DEXi: (proc(), proc(), proc()) = (DEXiInit, DEXiMain, DEXiEnd)
#endregion

#region ANDi

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

#region ORAa
var
    ORAaClocks: int = 0
    ORAaAddress: uint16 = 0

proc ORAaInit()=
    ORAaClocks = 0

proc ORAaMain()=
    if testClkHigh():
        if ORAaCLocks == 0:
            ORAaAddress = d.dToNum().uint16
            progCounter += 1
            for i in 0..<a.len():
                a[i] = ((progCounter shl i) and 0b1000000000000000) == 0b1000000000000000
        elif ORAaCLocks == 1:
            ORAaAddress += d.dToNum().uint16 shl 8
            progCounter += 1
            for i in 0..<a.len():
                a[i] = ((ORAaAddress shl i) and 0b1000000000000000) == 0b1000000000000000
        elif ORAaCLocks == 2:
            aReg = aReg or d.dToNum()
            changeState(fetch)
        ORAaCLocks += 1

proc ORAaEnd()=
    flags[1] = aReg == 0
    flags[7] = cast[int8](aReg) < 0

var ORAa: (proc(), proc(), proc()) = (ORAaInit, ORAaMain, ORAaEnd)
#endregion

#region CLCi
proc CLCiInit()=
    return

proc CLCiMain()=
    if testClkHigh():
        changeState(fetch)

proc CLCiEnd()=
    flags[0] = false

var CLCi: (proc(), proc(), proc()) = (CLCiInit, CLCiMain, CLCiEnd)
#endregion

#region SECi
proc SECiInit()=
    return

proc SECiMain()=
    if testClkHigh():
        changeState(fetch)

proc SECiEnd()=
    flags[0] = true

var SECi: (proc(), proc(), proc()) = (SECiInit, SECiMain, SECiEnd)
#endregion

#region ADCi
var
    ADCiOperand: uint8 = 0

proc ADCiInit()=
    discard

proc ADCiMain()=
    if testClkHigh():
        ADCiOperand = d.dToNum()
        progCounter += 1
        var
            newA: uint16 = ADCiOperand.uint16 + aReg.uint16 + flags[0].uint16
            isNeg: bool = cast[int8](aReg) < 0
        if newA == newA.uint8.uint16:
            flags[0] = false
        else:
            flags[0] = true
        aReg = newA.uint8
        flags[6] = (cast[int8](aReg) < 0) != isNeg
        changeState(fetch)

proc ADCiEnd()=
    flags[1] = aReg == 0
    flags[7] = cast[int8](aReg) < 0

var ADCi: (proc(), proc(), proc()) = (ADCiInit, ADCiMain, ADCiEnd)
#endregion

#region SBCi
var
    SBCiOperand: uint8 = 0

proc SBCiInit()=
    discard

proc SBCiMain()=
    if testClkHigh():
        SBCiOperand = not d.dToNum()
        progCounter += 1
        var
            newA: uint16 = SBCiOperand.uint16 + aReg.uint16 + flags[0].uint16
            isNeg: bool = cast[int8](aReg) < 0
        if newA == newA.uint8.uint16:
            flags[0] = false
        else:
            flags[0] = true
        aReg = newA.uint8
        flags[6] = (cast[int8](aReg) < 0) != isNeg
        changeState(fetch)

proc SBCiEnd()=
    flags[1] = aReg == 0
    flags[7] = cast[int8](aReg) < 0

var SBCi: (proc(), proc(), proc()) = (SBCiInit, SBCiMain, SBCiEnd)
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
    if d.dToNum == 0x0D:
        changeState(ORAa)
    elif d.dToNum == 0x18:
        changeState(CLCi)
    elif d.dToNum == 0x20:
        changeState(JSRa)
    elif d.dToNum == 0x2E:
        changeState(ROLa)
    elif d.dToNum == 0x29:
        changeState(ANDi)
    elif d.dToNum == 0x38:
        changeState(SECi)
    elif d.dToNum == 0x48:
        changeState(PHAi)
    elif d.dToNum == 0x4C:
        changeState(JMPa)
    elif d.dToNum == 0x60:
        changeState(RTSs)
    elif d.dToNum == 0x68:
        changeState(PLAs)
    elif d.dToNum == 0x69:
        changeState(ADCi)
    elif d.dToNum == 0x6A:
        changeState(RORA)
    elif d.dToNum == 0x8A:
        changeState(TXAi)
    elif d.dToNum == 0x8C:
        changeState(STYa)
    elif d.dToNum == 0x8D:
        changeState(STAa)
    elif d.dToNum == 0x90:
        changeState(BCCr)
    elif d.dToNum == 0x99:
        changeState(STAay)
    elif d.dToNum == 0x9A:
        changeState(TXSi)
    elif d.dToNum == 0xA0:
        changeState(LDYi)
    elif d.dToNum == 0xA2:
        changeState(LDXi)
    elif d.dToNum == 0xA8:
        changeState(TAYi)
    elif d.dToNum == 0xA9:
        changeState(LDAi)
    elif d.dToNum == 0xAA:
        changeState(TAXi)
    elif d.dToNum == 0xAD:
        changeState(LDAa)
    elif d.dToNum == 0xB9:
        changeState(LDAay)
    elif d.dToNum == 0xBD:
        changeState(LDAax)
    elif d.dToNum == 0xC8:
        changeState(INYi)
    elif d.dToNum == 0xCA:
        changeState(DEXi)
    elif d.dToNum == 0xD0:
        changeState(BNEr)
    elif d.dToNum == 0xE8:
        changeState(INXi)
    elif d.dToNum == 0xE9:
        changeState(SBCi)
    elif d.dToNum == 0xEA:
        changeState(NOP)
    elif d.dToNum == 0xF0:
        changeState(BEQr)
    else:
        echo("\aError: cannot decode instruction with opcode: " & d.dToNum().toHex())
        quit(1)

#region NMI
var
    NMIclocks: int = 0
    NMIaddress: uint16 = 0

proc NMIinit()=
    NMIclocks = 0
    progCounter -= 1
    for i in 0..<a.len():
        a[i] = ((progCounter shl i) and 0b1000000000000000) == 0b1000000000000000

proc NMImain()=
    if testClkLow():
        if NMIclocks == 5:
            NMIaddress = d.dToNum().uint16
        if NMIclocks == 6:
            NMIaddress += d.dToNum().uint16 shl 8
    if testClkHigh():
        if NMIclocks == 0:
            for i in 0..<a.len():
                a[i] = ((stackPointer shl i) and 0b1000000000000000) == 0b1000000000000000    
            m[5] = false
            stackPointer -= 1
            for i in 0..<d.len():
                d[i] = ((progCounter.uint8 shl i) and 0b10000000) == 0b10000000
        elif NMIclocks == 1:
            for i in 0..<a.len():
                a[i] = ((stackPointer shl i) and 0b1000000000000000) == 0b1000000000000000    
            m[5] = false
            stackPointer -= 1
            for i in 0..<d.len():
                d[i] = (((progCounter shr 8).uint8 shl i) and 0b10000000) == 0b10000000
        elif NMIclocks == 2:
            for i in 0..<a.len():
                a[i] = ((stackPointer shl i) and 0b1000000000000000) == 0b1000000000000000    
            m[5] = false
            stackPointer -= 1
            d = flags
        elif NMIclocks == 3:
            m[5] = true
        elif NMIclocks == 4:
            for i in 0..<a.len():
                a[i] = (0xFFFA.uint16 and 0b1000000000000000) == 0b1000000000000000
        elif NMIclocks == 5:
            for i in 0..<a.len():
                a[i] = (0xFFFB.uint16 and 0b1000000000000000) == 0b1000000000000000
        elif NMIclocks == 6:
            progCounter = NMIaddress
            changeState(fetch)
        NMIclocks += 1

proc NMIend()=
    discard

var NMI: (proc(), proc(), proc()) = (NMIinit, NMImain, NMIend)
#endregion

#region IRQ
var
    IRQclocks: int = 0
    IRQaddress: uint16 = 0

proc IRQinit()=
    IRQclocks = 0
    progCounter -= 1
    for i in 0..<a.len():
        a[i] = ((progCounter shl i) and 0b1000000000000000) == 0b1000000000000000

proc IRQmain()=
    if testClkLow():
        if IRQclocks == 5:
            IRQaddress = d.dToNum().uint16
        if IRQclocks == 6:
            IRQaddress += d.dToNum().uint16 shl 8
    if testClkHigh():
        if IRQclocks == 0:
            for i in 0..<a.len():
                a[i] = ((stackPointer shl i) and 0b1000000000000000) == 0b1000000000000000    
            m[5] = false
            stackPointer -= 1
            for i in 0..<d.len():
                d[i] = ((progCounter.uint8 shl i) and 0b10000000) == 0b10000000
        elif IRQclocks == 1:
            for i in 0..<a.len():
                a[i] = ((stackPointer shl i) and 0b1000000000000000) == 0b1000000000000000    
            m[5] = false
            stackPointer -= 1
            for i in 0..<d.len():
                d[i] = (((progCounter shr 8).uint8 shl i) and 0b10000000) == 0b10000000
        elif IRQclocks == 2:
            for i in 0..<a.len():
                a[i] = ((stackPointer shl i) and 0b1000000000000000) == 0b1000000000000000    
            m[5] = false
            stackPointer -= 1
            d = flags
        elif IRQclocks == 3:
            m[5] = true
        elif IRQclocks == 4:
            for i in 0..<a.len():
                a[i] = (0xFFFA.uint16 and 0b1000000000000000) == 0b1000000000000000
        elif IRQclocks == 5:
            for i in 0..<a.len():
                a[i] = (0xFFFB.uint16 and 0b1000000000000000) == 0b1000000000000000
        elif IRQclocks == 6:
            progCounter = IRQaddress
            changeState(fetch)
        IRQclocks += 1

proc IRQend()=
    discard

var IRQ: (proc(), proc(), proc()) = (IRQinit, IRQmain, IRQend)
#endregion

#region fetch
proc fetchInit()=
    m[5] = true
    for i in 0..<a.len():
        a[i] = ((progCounter shl i) and 0b1000000000000000) == 0b1000000000000000
    
    if oldNMI == true and false:                                                    #NMI pin tied high on ben eater 6502 computer
        changeState(NMI)
        oldNMI = false
    else:
        oldNMI = false
    
    if m[17] == false:
        changeState(IRQ)

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
