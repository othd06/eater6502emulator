import strutils

import wires

var
    oldClk: bool = false

    progCounter: uint16
    aReg: uint8

    flags: array[7, bool]

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

proc RORAinit()=
    discard

proc RORAmain()=
    if testClkHigh():
        var tmpCarry: bool = flags[0]
        flags[0] = (aReg and 0b00000001) == 1
        aReg = aReg shr 1
        aReg += tmpCarry.uint8 shl 7
        changeState(fetch)

proc RORAend()=
    discard

var RORA: (proc(), proc(), proc()) = (RORAinit, RORAmain, RORAend)

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
    discard

var LDAi: (proc(), proc(), proc()) = (LDAiInit, LDAiMain, LDAiEnd)
#endregion

#region nop
proc nopInit()=
    return

proc nopMain()=
    if testClkHigh():
        changeState(fetch)

proc nopEnd()=
    return

var nop: (proc(), proc(), proc()) = (nopInit, nopMain, nopEnd)
#endregion

proc fetchTest()=
    if d.dToNum == 0xEA:
        changeState(nop)
    elif d.dToNum == 0x4C:
        changeState(JMPa)
    elif d.dToNum == 0x6A:
        changeState(RORA)
    elif d.dToNum == 0x8D:
        changeState(STAa)
    elif d.dToNum == 0xA9:
        changeState(LDAi)
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

    if m[1] == true:
        changeState(reset)
    
    currentState[1]()
