/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20230628 (64-bit version)
 * Copyright (c) 2000 - 2023 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of /home/nss-marker/yhr/Cry/feedback-reader-eed81a7/decode/DSDT.dat, Sat Oct 10 05:27:37 2026
 *
 * Original Table Header:
 *     Signature        "DSDT"
 *     Length           0x00013BFA (80890)
 *     Revision         0x29
 *     Checksum         0x19
 *     OEM ID           "ALASKA"
 *     OEM Table ID     "A M I "
 *     OEM Revision     0x01072009 (17244169)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20230331 (539165489)
 */
DefinitionBlock ("", "DSDT", 41, "ALASKA", "A M I ", 0x01072009)
{
    External (_GPE, DeviceObj)
    External (_SB_.APTS, MethodObj)    // 1 Arguments
    External (_SB_.AWAK, MethodObj)    // 1 Arguments
    External (_SB_.PCI0, DeviceObj)
    External (_SB_.PCI0.DADR, IntObj)
    External (_SB_.PCI0.EBUS, IntObj)
    External (_SB_.PCI0.FLG0, IntObj)
    External (_SB_.PCI0.GP17, DeviceObj)
    External (_SB_.PCI0.GP17.ACP_, DeviceObj)
    External (_SB_.PCI0.GP17.AZAL, DeviceObj)
    External (_SB_.PCI0.GP17.VGA_, DeviceObj)
    External (_SB_.PCI0.GP17.VGA_.AFN7, UnknownObj)
    External (_SB_.PCI0.GP17.XHC0, DeviceObj)
    External (_SB_.PCI0.GP17.XHC1, DeviceObj)
    External (_SB_.PCI0.GP18, DeviceObj)
    External (_SB_.PCI0.GP19, DeviceObj)
    External (_SB_.PCI0.GP19.XHC2, DeviceObj)
    External (_SB_.PCI0.GPP0, DeviceObj)
    External (_SB_.PCI0.GPP1, DeviceObj)
    External (_SB_.PCI0.GPP1._ADR, IntObj)
    External (_SB_.PCI0.GPP2, DeviceObj)
    External (_SB_.PCI0.GPP3, DeviceObj)
    External (_SB_.PCI0.GPP4, DeviceObj)
    External (_SB_.PCI0.GPP5, DeviceObj)
    External (_SB_.PCI0.GPP6, DeviceObj)
    External (_SB_.PCI0.GPP7, DeviceObj)
    External (_SB_.PCI0.GPP7._ADR, IntObj)
    External (_SB_.PCI0.GPP7.SINI, MethodObj)    // 0 Arguments
    External (_SB_.PCI0.GPP7.SREG, MethodObj)    // 2 Arguments
    External (_SB_.PCI0.GPP7.SSTA, MethodObj)    // 0 Arguments
    External (_SB_.PCI0.GPP7.UP00.DP60.XH00.RHUB.POT4, DeviceObj)
    External (_SB_.PCI0.GPP7.UP00.DP60.XH00.RHUB.POTA, DeviceObj)
    External (_SB_.PCI0.GPP7.UP00.SINI, MethodObj)    // 0 Arguments
    External (_SB_.PCI0.GPP7.UP00.SREG, MethodObj)    // 2 Arguments
    External (_SB_.PCI0.GPP7.UP00.SSTA, MethodObj)    // 0 Arguments
    External (_SB_.PCI0.GPP8, DeviceObj)
    External (_SB_.PCI0.GPP9, DeviceObj)
    External (_SB_.PCI0.GPPA, DeviceObj)
    External (_SB_.PCI0.GPPB, DeviceObj)
    External (_SB_.PCI0.GPPC, DeviceObj)
    External (_SB_.PCI0.GPPD, DeviceObj)
    External (_SB_.PCI0.GPPE, DeviceObj)
    External (_SB_.PCI0.GPPF, DeviceObj)
    External (_SB_.PCI0.GPPG, DeviceObj)
    External (_SB_.PCI0.GPPH, DeviceObj)
    External (_SB_.PCI0.M641, IntObj)
    External (_SB_.PLTF.C000, DeviceObj)
    External (_SB_.PLTF.C001, DeviceObj)
    External (_SB_.PLTF.C002, DeviceObj)
    External (_SB_.PLTF.C003, DeviceObj)
    External (_SB_.PLTF.C004, DeviceObj)
    External (_SB_.PLTF.C005, DeviceObj)
    External (_SB_.PLTF.C006, DeviceObj)
    External (_SB_.PLTF.C007, DeviceObj)
    External (_SB_.PLTF.C008, DeviceObj)
    External (_SB_.PLTF.C009, DeviceObj)
    External (_SB_.PLTF.C00A, DeviceObj)
    External (_SB_.PLTF.C00B, DeviceObj)
    External (_SB_.PLTF.C00C, DeviceObj)
    External (_SB_.PLTF.C00D, DeviceObj)
    External (_SB_.PLTF.C00E, DeviceObj)
    External (_SB_.PLTF.C00F, DeviceObj)
    External (_SB_.PLTF.C010, DeviceObj)
    External (_SB_.PLTF.C011, DeviceObj)
    External (_SB_.PLTF.C012, DeviceObj)
    External (_SB_.PLTF.C013, DeviceObj)
    External (_SB_.PLTF.C014, DeviceObj)
    External (_SB_.PLTF.C015, DeviceObj)
    External (_SB_.PLTF.C016, DeviceObj)
    External (_SB_.PLTF.C017, DeviceObj)
    External (_SB_.PLTF.C018, DeviceObj)
    External (_SB_.PLTF.C019, DeviceObj)
    External (_SB_.PLTF.C01A, DeviceObj)
    External (_SB_.PLTF.C01B, DeviceObj)
    External (_SB_.PLTF.C01C, DeviceObj)
    External (_SB_.PLTF.C01D, DeviceObj)
    External (_SB_.PLTF.C01E, DeviceObj)
    External (_SB_.PLTF.C01F, DeviceObj)
    External (_SB_.PWRB, DeviceObj)
    External (_SB_.U4PC, IntObj)
    External (_SB_.UBTC, DeviceObj)
    External (AFN7, MethodObj)    // 1 Arguments
    External (CRBI, UnknownObj)
    External (M013, MethodObj)    // 4 Arguments
    External (M014, MethodObj)    // 5 Arguments
    External (M017, MethodObj)    // 6 Arguments
    External (M018, MethodObj)    // 7 Arguments
    External (M037, DeviceObj)
    External (M046, IntObj)
    External (M047, IntObj)
    External (M049, MethodObj)    // 2 Arguments
    External (M04A, MethodObj)    // 2 Arguments
    External (M04B, MethodObj)    // 2 Arguments
    External (M050, DeviceObj)
    External (M051, DeviceObj)
    External (M052, DeviceObj)
    External (M053, DeviceObj)
    External (M054, DeviceObj)
    External (M055, DeviceObj)
    External (M056, DeviceObj)
    External (M057, DeviceObj)
    External (M058, DeviceObj)
    External (M059, DeviceObj)
    External (M062, DeviceObj)
    External (M068, DeviceObj)
    External (M069, DeviceObj)
    External (M070, DeviceObj)
    External (M071, DeviceObj)
    External (M072, DeviceObj)
    External (M074, DeviceObj)
    External (M075, DeviceObj)
    External (M076, DeviceObj)
    External (M077, DeviceObj)
    External (M078, DeviceObj)
    External (M079, DeviceObj)
    External (M080, DeviceObj)
    External (M081, DeviceObj)
    External (M082, FieldUnitObj)
    External (M083, FieldUnitObj)
    External (M084, FieldUnitObj)
    External (M085, FieldUnitObj)
    External (M086, FieldUnitObj)
    External (M087, FieldUnitObj)
    External (M088, FieldUnitObj)
    External (M089, FieldUnitObj)
    External (M090, FieldUnitObj)
    External (M091, FieldUnitObj)
    External (M092, FieldUnitObj)
    External (M093, FieldUnitObj)
    External (M094, FieldUnitObj)
    External (M095, FieldUnitObj)
    External (M096, FieldUnitObj)
    External (M097, FieldUnitObj)
    External (M098, FieldUnitObj)
    External (M099, FieldUnitObj)
    External (M100, FieldUnitObj)
    External (M101, FieldUnitObj)
    External (M102, FieldUnitObj)
    External (M103, FieldUnitObj)
    External (M104, FieldUnitObj)
    External (M105, FieldUnitObj)
    External (M106, FieldUnitObj)
    External (M107, FieldUnitObj)
    External (M108, FieldUnitObj)
    External (M109, FieldUnitObj)
    External (M110, FieldUnitObj)
    External (M115, BuffObj)
    External (M116, BuffFieldObj)
    External (M117, BuffFieldObj)
    External (M118, BuffFieldObj)
    External (M119, BuffFieldObj)
    External (M120, BuffFieldObj)
    External (M122, FieldUnitObj)
    External (M127, DeviceObj)
    External (M128, FieldUnitObj)
    External (M131, FieldUnitObj)
    External (M132, FieldUnitObj)
    External (M133, FieldUnitObj)
    External (M134, FieldUnitObj)
    External (M135, FieldUnitObj)
    External (M136, FieldUnitObj)
    External (M220, FieldUnitObj)
    External (M221, FieldUnitObj)
    External (M226, FieldUnitObj)
    External (M227, DeviceObj)
    External (M229, FieldUnitObj)
    External (M231, FieldUnitObj)
    External (M233, FieldUnitObj)
    External (M235, FieldUnitObj)
    External (M23A, FieldUnitObj)
    External (M251, FieldUnitObj)
    External (M280, FieldUnitObj)
    External (M290, FieldUnitObj)
    External (M29A, FieldUnitObj)
    External (M310, FieldUnitObj)
    External (M31C, FieldUnitObj)
    External (M320, FieldUnitObj)
    External (M321, FieldUnitObj)
    External (M322, FieldUnitObj)
    External (M323, FieldUnitObj)
    External (M324, FieldUnitObj)
    External (M325, FieldUnitObj)
    External (M326, FieldUnitObj)
    External (M327, FieldUnitObj)
    External (M328, FieldUnitObj)
    External (M329, DeviceObj)
    External (M32A, DeviceObj)
    External (M32B, DeviceObj)
    External (M32C, DeviceObj)
    External (M330, DeviceObj)
    External (M331, FieldUnitObj)
    External (M378, FieldUnitObj)
    External (M379, FieldUnitObj)
    External (M380, FieldUnitObj)
    External (M381, FieldUnitObj)
    External (M382, FieldUnitObj)
    External (M383, FieldUnitObj)
    External (M384, FieldUnitObj)
    External (M385, FieldUnitObj)
    External (M386, FieldUnitObj)
    External (M387, FieldUnitObj)
    External (M388, FieldUnitObj)
    External (M389, FieldUnitObj)
    External (M390, FieldUnitObj)
    External (M391, FieldUnitObj)
    External (M392, FieldUnitObj)
    External (M404, BuffObj)
    External (M408, MutexObj)
    External (M414, FieldUnitObj)
    External (M444, FieldUnitObj)
    External (M449, FieldUnitObj)
    External (M453, FieldUnitObj)
    External (M454, FieldUnitObj)
    External (M455, FieldUnitObj)
    External (M456, FieldUnitObj)
    External (M457, FieldUnitObj)
    External (M460, MethodObj)    // 7 Arguments
    External (M4C0, FieldUnitObj)
    External (M4F0, FieldUnitObj)
    External (M610, FieldUnitObj)
    External (M620, FieldUnitObj)
    External (M631, FieldUnitObj)
    External (M644, MethodObj)    // 3 Arguments
    External (M646, MethodObj)    // 2 Arguments
    External (M648, MethodObj)    // 3 Arguments
    External (M652, FieldUnitObj)
    External (MPTS, MethodObj)    // 1 Arguments
    External (MWAK, MethodObj)    // 1 Arguments

    Name (ENTK, 0x87)
    Name (EXTK, 0xAA)
    Name (IO1B, Zero)
    Name (IO1L, Zero)
    Name (IO2B, 0x0290)
    Name (IO2L, 0x10)
    Name (IO4B, Zero)
    Name (IO4L, Zero)
    Name (SP1O, 0x2E)
    Name (KBFG, Zero)
    Name (MSFG, Zero)
    Name (IOES, Zero)
    Name (PEBL, 0x10000000)
    Name (ACPM, One)
    Name (NBTS, 0x5000)
    Name (CPVD, One)
    Name (SMBB, 0x0B20)
    Name (SMBL, 0x20)
    Name (SMB0, 0x0B00)
    Name (SMBM, 0x10)
    Name (PMBS, 0x0800)
    Name (PMLN, 0xA0)
    Name (SMIO, 0xB2)
    Name (GPBS, Zero)
    Name (GPLN, Zero)
    Name (APCB, 0xFEC00000)
    Name (APCL, 0x1000)
    Name (HPTB, 0xFED00000)
    Name (WDTB, 0xFEB00000)
    Name (WDTL, 0x1000)
    Name (GIOB, 0xFED81500)
    Name (IOMB, 0xFED80D00)
    Name (SSMB, 0xFED80200)
    Name (CAFS, 0xBB)
    Name (UTDB, Zero)
    Name (ASSB, Zero)
    Name (AOTB, Zero)
    Name (AAXB, Zero)
    Name (PEHP, One)
    Name (SHPC, One)
    Name (PEPM, One)
    Name (PEER, One)
    Name (PECS, One)
    Name (ITKE, Zero)
    Name (PEBS, 0xE0000000)
    Name (PELN, 0x10000000)
    Name (CSMI, 0x61)
    Name (DSSP, Zero)
    Name (FHPP, One)
    Name (SMIA, 0xB2)
    Name (SMIB, 0xB3)
    Name (OFST, 0x35)
    Name (TRST, 0x02)
    Name (TCMF, Zero)
    Name (TMF1, Zero)
    Name (TMF2, Zero)
    Name (TMF3, Zero)
    Name (TTPF, Zero)
    Name (DTPT, Zero)
    Name (TTDP, One)
    Name (TPMB, 0x6E6DA000)
    Name (TPBS, 0x4000)
    Name (TPMC, 0x6E6DE000)
    Name (TPCS, 0x4000)
    Name (TPMM, 0xF7210510)
    Name (FTPM, 0xF7210510)
    Name (PPIM, 0x719C2A18)
    Name (PPIL, 0x1C)
    Name (TPMF, One)
    Name (PPIV, One)
    Name (AMDT, 0x01)
    Name (HIDK, "MSFT0001")
    Name (HIDM, "MSFT0003")
    Name (CIDK, 0x0303D041)
    Name (CIDM, 0x030FD041)
    Name (MBEC, Zero)
    Name (NBTP, 0xFEC03000)
    Name (HSPB, 0xFFFFFFFF)
    Name (HSPS, 0xFFFFFFFF)
    Name (IOHW, 0x0290)
    Name (IO3B, 0x0200)
    Name (IO3L, 0x40)
    Name (SMIM, 0x80000009)
    Name (SMIP, 0xB2)
    Name (PNPM, One)
    Method (_PIC, 1, NotSerialized)  // _PIC: Interrupt Model
    {
        If (Arg0)
        {
            \_SB.DSPI ()
            \_SB.PCI0.NAPE ()
        }

        PXXX (Arg0)
    }

    Name (PICM, Zero)
    Method (PXXX, 1, NotSerialized)
    {
        If (Arg0)
        {
            DBG8 = 0xAA
        }
        Else
        {
            DBG8 = 0xAC
        }

        PICM = Arg0
    }

    Name (OSVR, Ones)
    Method (OSFL, 0, NotSerialized)
    {
        If ((OSVR != Ones))
        {
            Return (OSVR) /* \OSVR */
        }

        If ((PICM == Zero))
        {
            DBG8 = 0xAC
        }

        OSVR = 0x03
        If (CondRefOf (\_OSI))
        {
            If (_OSI ("Windows 2001"))
            {
                OSVR = 0x04
            }

            If (_OSI ("Windows 2001.1"))
            {
                OSVR = 0x05
            }

            If (_OSI ("FreeBSD"))
            {
                OSVR = 0x06
            }

            If (_OSI ("HP-UX"))
            {
                OSVR = 0x07
            }

            If (_OSI ("OpenVMS"))
            {
                OSVR = 0x08
            }

            If (_OSI ("Windows 2001 SP1"))
            {
                OSVR = 0x09
            }

            If (_OSI ("Windows 2001 SP2"))
            {
                OSVR = 0x0A
            }

            If (_OSI ("Windows 2001 SP3"))
            {
                OSVR = 0x0B
            }

            If (_OSI ("Windows 2006"))
            {
                OSVR = 0x0C
            }

            If (_OSI ("Windows 2006 SP1"))
            {
                OSVR = 0x0D
            }

            If (_OSI ("Windows 2009"))
            {
                OSVR = 0x0E
            }

            If (_OSI ("Windows 2012"))
            {
                OSVR = 0x0F
            }

            If (_OSI ("Windows 2013"))
            {
                OSVR = 0x10
            }
        }
        Else
        {
            If (MCTH (_OS, "Microsoft Windows NT"))
            {
                OSVR = Zero
            }

            If (MCTH (_OS, "Microsoft Windows"))
            {
                OSVR = One
            }

            If (MCTH (_OS, "Microsoft WindowsME: Millennium Edition"))
            {
                OSVR = 0x02
            }

            If (MCTH (_OS, "Linux"))
            {
                OSVR = 0x03
            }

            If (MCTH (_OS, "FreeBSD"))
            {
                OSVR = 0x06
            }

            If (MCTH (_OS, "HP-UX"))
            {
                OSVR = 0x07
            }

            If (MCTH (_OS, "OpenVMS"))
            {
                OSVR = 0x08
            }
        }

        Return (OSVR) /* \OSVR */
    }

    Method (MCTH, 2, NotSerialized)
    {
        If ((SizeOf (Arg0) < SizeOf (Arg1)))
        {
            Return (Zero)
        }

        Local0 = (SizeOf (Arg0) + One)
        Name (BUF0, Buffer (Local0){})
        Name (BUF1, Buffer (Local0){})
        BUF0 = Arg0
        BUF1 = Arg1
        While (Local0)
        {
            Local0--
            If ((DerefOf (BUF0 [Local0]) != DerefOf (BUF1 [Local0]
                )))
            {
                Return (Zero)
            }
        }

        Return (One)
    }

    Name (PRWP, Package (0x02)
    {
        Zero, 
        Zero
    })
    Method (GPRW, 2, NotSerialized)
    {
        PRWP [Zero] = Arg0
        Local0 = (SS1 << One)
        Local0 |= (SS2 << 0x02)
        Local0 |= (SS3 << 0x03)
        Local0 |= (SS4 << 0x04)
        If (((One << Arg1) & Local0))
        {
            PRWP [One] = Arg1
        }
        Else
        {
            Local0 >>= One
            If (((OSFL () == One) || (OSFL () == 0x02)))
            {
                FindSetLeftBit (Local0, PRWP [One])
            }
            Else
            {
                FindSetRightBit (Local0, PRWP [One])
            }
        }

        Return (PRWP) /* \PRWP */
    }

    Name (WAKP, Package (0x02)
    {
        Zero, 
        Zero
    })
    Method (UPWP, 1, NotSerialized)
    {
        If (DerefOf (WAKP [Zero]))
        {
            WAKP [One] = Zero
        }
        Else
        {
            WAKP [One] = Arg0
        }
    }

    OperationRegion (DEB0, SystemIO, 0x80, One)
    Field (DEB0, ByteAcc, NoLock, Preserve)
    {
        DBG8,   8
    }

    OperationRegion (DEB1, SystemIO, 0x90, 0x02)
    Field (DEB1, WordAcc, NoLock, Preserve)
    {
        DBG9,   16
    }

    Name (SS1, Zero)
    Name (SS2, Zero)
    Name (SS3, One)
    Name (SS4, One)
    Name (IOST, 0x0001)
    Name (TOPM, 0x00000000)
    Name (ROMS, 0xFFE00000)
    Name (VGAF, One)
    OperationRegion (DEB2, SystemIO, 0x80, 0x02)
    Field (DEB2, WordAcc, NoLock, Preserve)
    {
        P80H,   16
    }

    Name (OSTY, Ones)
    OperationRegion (ACMS, SystemIO, 0x72, 0x02)
    Field (ACMS, ByteAcc, NoLock, Preserve)
    {
        ACMX,   8, 
        ACMA,   8
    }

    IndexField (ACMX, ACMA, ByteAcc, NoLock, Preserve)
    {
        Offset (0xB9), 
        IMEN,   8
    }

    OperationRegion (PSMI, SystemIO, SMIO, 0x02)
    Field (PSMI, ByteAcc, NoLock, Preserve)
    {
        APMC,   8, 
        APMD,   8
    }

    OperationRegion (PMRG, SystemMemory, 0xFED80300, 0x0100)
    Field (PMRG, AnyAcc, NoLock, Preserve)
    {
            ,   6, 
        HPEN,   1, 
        Offset (0x60), 
        P1EB,   16, 
        Offset (0x80), 
        SI3R,   1, 
        Offset (0xF0), 
            ,   3, 
        RSTU,   1
    }

    OperationRegion (GSMM, SystemMemory, 0xFED80000, 0x1000)
    Field (GSMM, AnyAcc, NoLock, Preserve)
    {
        Offset (0x288), 
            ,   1, 
        CLPS,   1, 
        Offset (0x296), 
            ,   7, 
        TMSE,   1, 
        Offset (0x2B0), 
            ,   2, 
        SLPS,   2, 
        Offset (0x3BB), 
            ,   6, 
        PWDE,   1, 
        Offset (0x3E4), 
        BLNK,   2
    }

    OperationRegion (P1E0, SystemIO, P1EB, 0x04)
    Field (P1E0, ByteAcc, NoLock, Preserve)
    {
        Offset (0x01), 
            ,   6, 
        PEWS,   1, 
        WSTA,   1, 
        Offset (0x03), 
            ,   6, 
        PEWD,   1
    }

    OperationRegion (IOCC, SystemIO, PMBS, 0x80)
    Field (IOCC, ByteAcc, NoLock, Preserve)
    {
        Offset (0x01), 
            ,   2, 
        RTCS,   1
    }

    Method (SPTS, 1, NotSerialized)
    {
        P80H = Arg0
        If ((Arg0 == 0x03))
        {
            BLNK = One
        }

        If (((Arg0 == 0x04) || (Arg0 == 0x05)))
        {
            BLNK = Zero
        }

        If ((Arg0 == 0x03))
        {
            RSTU = Zero
        }

        CLPS = One
        SLPS = One
        PEWS = PEWS /* \PEWS */
        If ((Arg0 == 0x03))
        {
            SLPS = One
        }

        If ((Arg0 == 0x04))
        {
            SLPS = One
            RSTU = One
        }

        If ((Arg0 == 0x05))
        {
            PWDE = One
        }
    }

    Method (SWAK, 1, NotSerialized)
    {
        BLNK = 0x03
        If ((Arg0 == 0x03))
        {
            RSTU = One
        }

        PEWS = PEWS /* \PEWS */
        PEWD = Zero
        If (PICM)
        {
            \_SB.DSPI ()
        }

        If (TMSE)
        {
            TMSE = Zero
        }

        If ((Arg0 == 0x03))
        {
            Notify (\_SB.PWRB, 0x02) // Device Wake
        }

        If ((Arg0 == 0x04))
        {
            Notify (\_SB.PWRB, 0x02) // Device Wake
        }
    }

    Scope (_GPE)
    {
    }

    Scope (_SB)
    {
        OperationRegion (WPBR, SystemMemory, 0x712D3000, 0x0001)
        Field (WPBR, AnyAcc, NoLock, Preserve)
        {
            Offset (0x00), 
            CTRL,   8
        }
    }

    Scope (\)
    {
        Device (AWW0)
        {
            Name (_HID, EisaId ("PNP0C14") /* Windows Management Instrumentation Device */)  // _HID: Hardware ID
            Name (_UID, "AWW")  // _UID: Unique ID
            Name (_WDG, Buffer (0x28)
            {
                /* 0000 */  0x13, 0x12, 0x02, 0xC3, 0xBC, 0xD0, 0xA2, 0x41,  // .......A
                /* 0008 */  0xBA, 0x17, 0x81, 0x6C, 0xD5, 0xED, 0x77, 0x44,  // ...l..wD
                /* 0010 */  0x42, 0x43, 0x01, 0x02, 0x21, 0x12, 0x90, 0x05,  // BC..!...
                /* 0018 */  0x66, 0xD5, 0xD1, 0x11, 0xB2, 0xF0, 0x00, 0xA0,  // f.......
                /* 0020 */  0xC9, 0x06, 0x29, 0x10, 0x4D, 0x4F, 0x01, 0x00   // ..).MO..
            })
            Method (WMBC, 3, NotSerialized)
            {
                Local0 = \_SB.CTRL
                Return (Local0)
            }

            Name (WQMO, Buffer (0x0241)
            {
                /* 0000 */  0x46, 0x4F, 0x4D, 0x42, 0x01, 0x00, 0x00, 0x00,  // FOMB....
                /* 0008 */  0x31, 0x02, 0x00, 0x00, 0x9C, 0x04, 0x00, 0x00,  // 1.......
                /* 0010 */  0x44, 0x53, 0x00, 0x01, 0x1A, 0x7D, 0xDA, 0x54,  // DS...}.T
                /* 0018 */  0x28, 0x5A, 0x82, 0x00, 0x01, 0x06, 0x18, 0x42,  // (Z.....B
                /* 0020 */  0x20, 0xA4, 0x02, 0x89, 0xC0, 0xA1, 0x21, 0x14,  //  .....!.
                /* 0028 */  0x45, 0x01, 0x0C, 0x86, 0xCB, 0x72, 0x20, 0xE4,  // E....r .
                /* 0030 */  0x82, 0x89, 0x09, 0x10, 0x01, 0x21, 0xAF, 0x02,  // .....!..
                /* 0038 */  0x6C, 0x0A, 0x30, 0x09, 0xA2, 0xFE, 0xFD, 0x21,  // l.0....!
                /* 0040 */  0x4A, 0x82, 0x43, 0x09, 0x81, 0x90, 0x44, 0x01,  // J.C...D.
                /* 0048 */  0xE6, 0x05, 0xE8, 0x16, 0x60, 0x58, 0x80, 0x6D,  // ....`X.m
                /* 0050 */  0x01, 0xA6, 0x05, 0x38, 0x86, 0xA4, 0xD2, 0xC0,  // ...8....
                /* 0058 */  0x29, 0x81, 0xA5, 0x40, 0x48, 0xA8, 0x00, 0xE5,  // )..@H...
                /* 0060 */  0x02, 0x7C, 0x0B, 0xD0, 0x8E, 0x28, 0xC9, 0x02,  // .|...(..
                /* 0068 */  0x2C, 0xC3, 0x88, 0xC0, 0xA3, 0x88, 0x6C, 0x34,  // ,.....l4
                /* 0070 */  0x4E, 0x50, 0x36, 0x34, 0x4A, 0x06, 0x84, 0x3C,  // NP64J..<
                /* 0078 */  0x0B, 0xB0, 0x0E, 0x4C, 0x08, 0xEC, 0x5E, 0x80,  // ...L..^.
                /* 0080 */  0x43, 0x01, 0xCE, 0x04, 0x08, 0x13, 0xA0, 0x4C,  // C......L
                /* 0088 */  0x80, 0x31, 0x08, 0x02, 0xD3, 0xD6, 0x70, 0x04,  // .1....p.
                /* 0090 */  0x54, 0x21, 0x98, 0x50, 0xCE, 0x25, 0x52, 0x83,  // T!.P.%R.
                /* 0098 */  0x60, 0x42, 0x09, 0x14, 0x24, 0x4C, 0x6F, 0x28,  // `B..$Lo(
                /* 00A0 */  0x12, 0x07, 0x22, 0x6D, 0x78, 0xC2, 0x6C, 0x4D,  // .."mx.lM
                /* 00A8 */  0x80, 0x45, 0x0C, 0x41, 0x45, 0x08, 0x1A, 0xA1,  // .E.AE...
                /* 00B0 */  0xFD, 0x41, 0x90, 0x58, 0x0B, 0xD6, 0x50, 0x1D,  // .A.X..P.
                /* 00B8 */  0x69, 0x34, 0xA8, 0xE1, 0x25, 0x38, 0x5C, 0x0F,  // i4..%8\.
                /* 00C0 */  0xF5, 0x1C, 0x3B, 0x17, 0x20, 0x7D, 0x92, 0x02,  // ..;. }..
                /* 00C8 */  0x39, 0xC8, 0x73, 0xAB, 0x73, 0x9C, 0x04, 0x24,  // 9.s.s..$
                /* 00D0 */  0x81, 0xB1, 0x12, 0x74, 0x30, 0x70, 0x28, 0xAE,  // ...t0p(.
                /* 00D8 */  0x01, 0x35, 0xE3, 0xE3, 0x65, 0x82, 0xE0, 0x50,  // .5..e..P
                /* 00E0 */  0x43, 0xF4, 0x40, 0xC3, 0x9D, 0xC0, 0x21, 0x32,  // C.@...!2
                /* 00E8 */  0x40, 0xCF, 0xEE, 0x68, 0x30, 0x07, 0x00, 0x8F,  // @..h0...
                /* 00F0 */  0xEC, 0x64, 0xDE, 0x03, 0x4A, 0x15, 0x60, 0x76,  // .d..J.`v
                /* 00F8 */  0xCC, 0x9A, 0x5A, 0x82, 0xE3, 0x31, 0xF4, 0xE9,  // ..Z..1..
                /* 0100 */  0x9E, 0xCF, 0x09, 0x27, 0xB0, 0xFC, 0x41, 0xA0,  // ...'..A.
                /* 0108 */  0x46, 0x66, 0x68, 0xCF, 0xF4, 0xB4, 0x62, 0x86,  // Ffh...b.
                /* 0110 */  0x3C, 0xFC, 0xC3, 0x62, 0x62, 0x21, 0xF4, 0x41,  // <..bb!.A
                /* 0118 */  0xF0, 0x78, 0xE0, 0xFD, 0xFF, 0xC7, 0x03, 0x1E,  // .x......
                /* 0120 */  0xC5, 0x67, 0x02, 0x21, 0xBC, 0x12, 0xC4, 0xF6,  // .g.!....
                /* 0128 */  0x80, 0x12, 0x94, 0x07, 0x8C, 0x1E, 0x90, 0xFD,  // ........
                /* 0130 */  0x0A, 0x40, 0x08, 0x5E, 0xE6, 0x88, 0xE4, 0x14,  // .@.^....
                /* 0138 */  0x41, 0x63, 0xF2, 0xE4, 0x5E, 0x0D, 0x42, 0x3C,  // Ac..^.B<
                /* 0140 */  0x24, 0x14, 0x3E, 0x00, 0xCD, 0xEA, 0x31, 0x81,  // $.>...1.
                /* 0148 */  0x11, 0x14, 0x09, 0x8F, 0x12, 0x03, 0x8F, 0x3A,  // .......:
                /* 0150 */  0x04, 0x44, 0x3E, 0x9A, 0x73, 0x09, 0x7F, 0x34,  // .D>.s..4
                /* 0158 */  0x51, 0x4E, 0xE1, 0x70, 0x7C, 0x62, 0x30, 0x42,  // QN.p|b0B
                /* 0160 */  0xF8, 0x72, 0x0F, 0x0E, 0x44, 0xF3, 0x7C, 0x34,  // .r..D.|4
                /* 0168 */  0x89, 0x33, 0x7A, 0x17, 0xF0, 0xD9, 0x80, 0x1D,  // .3z.....
                /* 0170 */  0x2E, 0x1C, 0x89, 0x42, 0x36, 0x16, 0xEA, 0xA1,  // ...B6...
                /* 0178 */  0x52, 0x61, 0x40, 0x9A, 0x78, 0xDC, 0x98, 0x47,  // Ra@.x..G
                /* 0180 */  0xD1, 0xFB, 0x78, 0x28, 0xCA, 0xEB, 0x01, 0x83,  // ..x(....
                /* 0188 */  0x38, 0x29, 0x8F, 0x4E, 0xF0, 0x14, 0xC2, 0x12,  // 8).N....
                /* 0190 */  0x48, 0xE8, 0x90, 0x3C, 0x02, 0x47, 0x06, 0xA3,  // H..<.G..
                /* 0198 */  0x20, 0x1E, 0xBF, 0xE3, 0x40, 0xC8, 0xC9, 0x51,  //  ...@..Q
                /* 01A0 */  0x00, 0x35, 0x3A, 0xDF, 0x04, 0x3C, 0xAE, 0x53,  // .5:..<.S
                /* 01A8 */  0x3A, 0x8C, 0x03, 0x39, 0x8B, 0x28, 0xAF, 0x0C,  // :..9.(..
                /* 01B0 */  0x26, 0x30, 0xCE, 0x23, 0x03, 0xAC, 0x11, 0x1E,  // &0.#....
                /* 01B8 */  0xCE, 0xD9, 0x79, 0x22, 0x86, 0x33, 0xA4, 0xE1,  // ..y".3..
                /* 01C0 */  0xF8, 0x55, 0xE0, 0x8D, 0x22, 0x01, 0x3F, 0x12,  // .U..".?.
                /* 01C8 */  0xC0, 0xBF, 0x6E, 0xF8, 0x40, 0x70, 0x0A, 0x8F,  // ..n.@p..
                /* 01D0 */  0x1A, 0x6F, 0x19, 0x09, 0x2C, 0xF0, 0x48, 0x00,  // .o..,.H.
                /* 01D8 */  0x0A, 0x20, 0x5F, 0x02, 0xAC, 0xF4, 0x20, 0x40,  // . _... @
                /* 01E0 */  0xE7, 0x10, 0x22, 0x4C, 0x34, 0x13, 0xFC, 0xFF,  // .."L4...
                /* 01E8 */  0xC3, 0x73, 0xC1, 0x63, 0xA5, 0xB2, 0xC6, 0x85,  // .s.c....
                /* 01F0 */  0x1A, 0xAA, 0x4F, 0x07, 0x0C, 0xFB, 0x1D, 0xC0,  // ..O.....
                /* 01F8 */  0xA2, 0x67, 0xA8, 0x1B, 0xC1, 0x41, 0xBD, 0x3D,  // .g...A.=
                /* 0200 */  0x58, 0xA2, 0x53, 0xA9, 0x4E, 0x61, 0x3D, 0x52,  // X.S.Na=R
                /* 0208 */  0x0E, 0x6B, 0xB4, 0xB0, 0x07, 0xFC, 0xE4, 0xE0,  // .k......
                /* 0210 */  0x5B, 0x87, 0x67, 0x66, 0x8C, 0xB0, 0x1E, 0xAD,  // [.gf....
                /* 0218 */  0x15, 0xDA, 0xF4, 0xA9, 0xD1, 0xA8, 0x55, 0x83,  // ......U.
                /* 0220 */  0x32, 0x35, 0xCA, 0x34, 0xA8, 0xD5, 0xA7, 0x52,  // 25.4...R
                /* 0228 */  0x63, 0xC6, 0x4E, 0x22, 0x8E, 0xF1, 0x12, 0xD0,  // c.N"....
                /* 0230 */  0x58, 0x2C, 0x62, 0x39, 0x02, 0xB1, 0x74, 0x0A,  // X,b9..t.
                /* 0238 */  0x19, 0x01, 0x51, 0x10, 0x10, 0x01, 0xF9, 0xFF,  // ..Q.....
                /* 0240 */  0x0F                                             // .
            })
        }
    }

    Scope (_SB)
    {
        Name (PRSA, ResourceTemplate ()
        {
            IRQ (Level, ActiveLow, Shared, )
                {4,5,6,10,11,14,15}
        })
        Alias (PRSA, PRSB)
        Alias (PRSA, PRSC)
        Alias (PRSA, PRSD)
        Alias (PRSA, PRSE)
        Alias (PRSA, PRSF)
        Alias (PRSA, PRSG)
        Alias (PRSA, PRSH)
        Name (PG07, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                LNKE, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                LNKF, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                LNKG, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                LNKH, 
                Zero
            }
        })
        Name (AG07, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                Zero, 
                0x24
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                Zero, 
                0x25
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                Zero, 
                0x26
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                Zero, 
                0x27
            }
        })
        Name (PG09, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                LNKA, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                LNKB, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                LNKC, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                LNKD, 
                Zero
            }
        })
        Name (AG09, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                Zero, 
                0x28
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                Zero, 
                0x29
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                Zero, 
                0x2A
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                Zero, 
                0x2B
            }
        })
        Name (PG0B, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                LNKE, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                LNKF, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                LNKG, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                LNKH, 
                Zero
            }
        })
        Name (AG0B, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                Zero, 
                0x2C
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                Zero, 
                0x2D
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                Zero, 
                0x2E
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                Zero, 
                0x2F
            }
        })
        Name (PG0D, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                LNKE, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                LNKF, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                LNKG, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                LNKH, 
                Zero
            }
        })
        Name (AG0D, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                Zero, 
                0x2C
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                Zero, 
                0x2D
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                Zero, 
                0x2E
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                Zero, 
                0x2F
            }
        })
        Name (PG13, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                LNKC, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                LNKD, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                LNKA, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                LNKB, 
                Zero
            }
        })
        Name (AG13, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                Zero, 
                0x2A
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                Zero, 
                0x2B
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                Zero, 
                0x28
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                Zero, 
                0x29
            }
        })
        Name (PG15, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                LNKG, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                LNKH, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                LNKE, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                LNKF, 
                Zero
            }
        })
        Name (AG15, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                Zero, 
                0x26
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                Zero, 
                0x27
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                Zero, 
                0x24
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                Zero, 
                0x25
            }
        })
        Name (PG17, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                LNKC, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                LNKD, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                LNKA, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                LNKB, 
                Zero
            }
        })
        Name (AG17, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                Zero, 
                0x22
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                Zero, 
                0x23
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                Zero, 
                0x20
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                Zero, 
                0x21
            }
        })
        Name (PG19, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                LNKG, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                LNKH, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                LNKE, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                LNKF, 
                Zero
            }
        })
        Name (AG19, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                Zero, 
                0x1E
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                Zero, 
                0x1F
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                Zero, 
                0x1C
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                Zero, 
                0x1D
            }
        })
        Name (PG1B, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                LNKC, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                LNKD, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                LNKA, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                LNKB, 
                Zero
            }
        })
        Name (AG1B, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                Zero, 
                0x1A
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                Zero, 
                0x1B
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                Zero, 
                0x18
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                Zero, 
                0x19
            }
        })
        Name (PG1D, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                LNKB, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                LNKC, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                LNKD, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                LNKA, 
                Zero
            }
        })
        Name (AG1D, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                Zero, 
                0x19
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                Zero, 
                0x1A
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                Zero, 
                0x1B
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                Zero, 
                0x18
            }
        })
        Name (PG1F, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                LNKF, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                LNKG, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                LNKH, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                LNKE, 
                Zero
            }
        })
        Name (AG1F, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                Zero, 
                0x1D
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                Zero, 
                0x1E
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                Zero, 
                0x1F
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                Zero, 
                0x1C
            }
        })
        Name (PG22, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                LNKC, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                LNKD, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                LNKA, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                LNKB, 
                Zero
            }
        })
        Name (AG22, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                Zero, 
                0x22
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                Zero, 
                0x23
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                Zero, 
                0x20
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                Zero, 
                0x21
            }
        })
        Name (PG24, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                LNKG, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                LNKH, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                LNKE, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                LNKF, 
                Zero
            }
        })
        Name (AG24, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                Zero, 
                0x26
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                Zero, 
                0x27
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                Zero, 
                0x24
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                Zero, 
                0x25
            }
        })
        Name (PG27, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                LNKC, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                LNKD, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                LNKA, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                LNKB, 
                Zero
            }
        })
        Name (AG27, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                Zero, 
                0x2A
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                Zero, 
                0x2B
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                Zero, 
                0x28
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                Zero, 
                0x29
            }
        })
        Name (PD00, Package (0x0A)
        {
            Package (0x04)
            {
                0x0001FFFF, 
                Zero, 
                LNKA, 
                Zero
            }, 

            Package (0x04)
            {
                0x0003FFFF, 
                Zero, 
                LNKB, 
                Zero
            }, 

            Package (0x04)
            {
                0x0004FFFF, 
                Zero, 
                LNKB, 
                Zero
            }, 

            Package (0x04)
            {
                0x0008FFFF, 
                Zero, 
                LNKC, 
                Zero
            }, 

            Package (0x04)
            {
                0x0014FFFF, 
                Zero, 
                LNKA, 
                Zero
            }, 

            Package (0x04)
            {
                0x0014FFFF, 
                One, 
                LNKB, 
                Zero
            }, 

            Package (0x04)
            {
                0x0014FFFF, 
                0x02, 
                LNKC, 
                Zero
            }, 

            Package (0x04)
            {
                0x0014FFFF, 
                0x03, 
                LNKD, 
                Zero
            }, 

            Package (0x04)
            {
                0x0002FFFF, 
                Zero, 
                LNKA, 
                Zero
            }, 

            Package (0x04)
            {
                0x0002FFFF, 
                One, 
                LNKB, 
                Zero
            }
        })
        Name (AR00, Package (0x0A)
        {
            Package (0x04)
            {
                0x0001FFFF, 
                Zero, 
                Zero, 
                0x18
            }, 

            Package (0x04)
            {
                0x0003FFFF, 
                Zero, 
                Zero, 
                0x19
            }, 

            Package (0x04)
            {
                0x0004FFFF, 
                Zero, 
                Zero, 
                0x19
            }, 

            Package (0x04)
            {
                0x0008FFFF, 
                Zero, 
                Zero, 
                0x1A
            }, 

            Package (0x04)
            {
                0x0014FFFF, 
                Zero, 
                Zero, 
                0x10
            }, 

            Package (0x04)
            {
                0x0014FFFF, 
                One, 
                Zero, 
                0x11
            }, 

            Package (0x04)
            {
                0x0014FFFF, 
                0x02, 
                Zero, 
                0x12
            }, 

            Package (0x04)
            {
                0x0014FFFF, 
                0x03, 
                Zero, 
                0x13
            }, 

            Package (0x04)
            {
                0x0002FFFF, 
                Zero, 
                Zero, 
                0x18
            }, 

            Package (0x04)
            {
                0x0002FFFF, 
                One, 
                Zero, 
                0x19
            }
        })
        Name (PG3B, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                LNKG, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                LNKH, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                LNKE, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                LNKF, 
                Zero
            }
        })
        Name (AG3B, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                Zero, 
                0x2E
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                Zero, 
                0x2F
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                Zero, 
                0x2C
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                Zero, 
                0x2D
            }
        })
        Name (PG3C, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                LNKG, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                LNKH, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                LNKE, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                LNKF, 
                Zero
            }
        })
        Name (AG3C, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                Zero, 
                0x2E
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                Zero, 
                0x2F
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                Zero, 
                0x2C
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                Zero, 
                0x2D
            }
        })
        Name (PG3E, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                LNKA, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                LNKB, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                LNKC, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                LNKD, 
                Zero
            }
        })
        Name (AG3E, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                Zero, 
                0x18
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                Zero, 
                0x19
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                Zero, 
                0x1A
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                Zero, 
                0x1B
            }
        })
        Name (PG3F, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                LNKE, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                LNKF, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                LNKG, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                LNKH, 
                Zero
            }
        })
        Name (AG3F, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                Zero, 
                0x1C
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                Zero, 
                0x1D
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                Zero, 
                0x1E
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                Zero, 
                0x1F
            }
        })
        Name (PG40, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                LNKA, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                LNKB, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                LNKC, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                LNKD, 
                Zero
            }
        })
        Name (AG40, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                Zero, 
                0x20
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                Zero, 
                0x21
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                Zero, 
                0x22
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                Zero, 
                0x23
            }
        })
        Name (PG41, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                LNKG, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                LNKH, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                LNKE, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                LNKF, 
                Zero
            }
        })
        Name (AG41, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                Zero, 
                0x2E
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                Zero, 
                0x2F
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                Zero, 
                0x2C
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                Zero, 
                0x2D
            }
        })
        Name (PG42, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                LNKG, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                LNKH, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                LNKE, 
                Zero
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                LNKF, 
                Zero
            }
        })
        Name (AG42, Package (0x04)
        {
            Package (0x04)
            {
                0xFFFF, 
                Zero, 
                Zero, 
                0x2E
            }, 

            Package (0x04)
            {
                0xFFFF, 
                One, 
                Zero, 
                0x2F
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x02, 
                Zero, 
                0x2C
            }, 

            Package (0x04)
            {
                0xFFFF, 
                0x03, 
                Zero, 
                0x2D
            }
        })
    }

    Scope (_SB)
    {
        Device (PCI0)
        {
            Name (_HID, EisaId ("PNP0A08") /* PCI Express Bus */)  // _HID: Hardware ID
            Name (_CID, EisaId ("PNP0A03") /* PCI Bus */)  // _CID: Compatible ID
            Name (_ADR, Zero)  // _ADR: Address
            Method (^BN00, 0, NotSerialized)
            {
                Return (Zero)
            }

            Method (_BBN, 0, NotSerialized)  // _BBN: BIOS Bus Number
            {
                Return (BN00 ())
            }

            Name (_UID, Zero)  // _UID: Unique ID
            Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
            {
                If (PICM)
                {
                    Return (AR00) /* \_SB_.AR00 */
                }

                Return (PD00) /* \_SB_.PD00 */
            }

            Device (AMDN)
            {
                Name (_HID, EisaId ("PNP0C01") /* System Board */)  // _HID: Hardware ID
                Name (_UID, 0xC8)  // _UID: Unique ID
                Name (_STA, 0x0F)  // _STA: Status
                Name (NPTR, ResourceTemplate ()
                {
                    Memory32Fixed (ReadWrite,
                        0x00000000,         // Address Base
                        0x00000000,         // Address Length
                        _Y00)
                })
                Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
                {
                    CreateDWordField (NPTR, \_SB.PCI0.AMDN._Y00._LEN, PL)  // _LEN: Length
                    CreateDWordField (NPTR, \_SB.PCI0.AMDN._Y00._BAS, PB)  // _BAS: Base Address
                    PB = PEBS /* \PEBS */
                    PL = PEBL /* \PEBL */
                    Return (NPTR) /* \_SB_.PCI0.AMDN.NPTR */
                }
            }

            Method (NPTS, 1, NotSerialized)
            {
                APTS (Arg0)
            }

            Method (NWAK, 1, NotSerialized)
            {
                AWAK (Arg0)
            }

            Name (CPRB, One)
            Name (LVGA, 0x01)
            Name (STAV, 0x0F)
            Name (BRB, 0x0000)
            Name (BRL, 0x0100)
            Name (IOB, 0x1000)
            Name (IOL, 0xF000)
            Name (MBB, 0x80000000)
            Name (MBL, 0x60000000)
            Name (MAB, 0x0000001080000000)
            Name (MAL, 0x000000EF80000000)
            Name (MAM, 0x000000FFFFFFFFFF)
            Name (CRS1, ResourceTemplate ()
            {
                WordBusNumber (ResourceProducer, MinFixed, MaxFixed, PosDecode,
                    0x0000,             // Granularity
                    0x0000,             // Range Minimum
                    0x007F,             // Range Maximum
                    0x0000,             // Translation Offset
                    0x0080,             // Length
                    ,, _Y01)
                IO (Decode16,
                    0x0CF8,             // Range Minimum
                    0x0CF8,             // Range Maximum
                    0x01,               // Alignment
                    0x08,               // Length
                    )
                WordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                    0x0000,             // Granularity
                    0x0000,             // Range Minimum
                    0x03AF,             // Range Maximum
                    0x0000,             // Translation Offset
                    0x03B0,             // Length
                    ,, , TypeStatic, DenseTranslation)
                WordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                    0x0000,             // Granularity
                    0x03E0,             // Range Minimum
                    0x0CF7,             // Range Maximum
                    0x0000,             // Translation Offset
                    0x0918,             // Length
                    ,, , TypeStatic, DenseTranslation)
                WordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                    0x0000,             // Granularity
                    0x0000,             // Range Minimum
                    0x0000,             // Range Maximum
                    0x0000,             // Translation Offset
                    0x0000,             // Length
                    ,, _Y03, TypeStatic, DenseTranslation)
                WordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                    0x0000,             // Granularity
                    0x0D00,             // Range Minimum
                    0x0FFF,             // Range Maximum
                    0x0000,             // Translation Offset
                    0x0300,             // Length
                    ,, _Y02, TypeStatic, DenseTranslation)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x00000000,         // Range Minimum
                    0x00000000,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00000000,         // Length
                    ,, _Y04, AddressRangeMemory, TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, NonCacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x000C0000,         // Range Minimum
                    0x000DFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00020000,         // Length
                    ,, , AddressRangeMemory, TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x02000000,         // Range Minimum
                    0xFFDFFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0xFDE00000,         // Length
                    ,, _Y05, AddressRangeMemory, TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x02000000,         // Range Minimum
                    0xFFDFFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0xFDE00000,         // Length
                    ,, _Y06, AddressRangeMemory, TypeStatic)
                QWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x0000000000000000, // Granularity
                    0x0000000000000000, // Range Minimum
                    0x0000000000000000, // Range Maximum
                    0x0000000000000000, // Translation Offset
                    0x0000000000000000, // Length
                    ,, _Y07, AddressRangeMemory, TypeStatic)
            })
            Name (CRS2, ResourceTemplate ()
            {
                WordBusNumber (ResourceProducer, MinFixed, MaxFixed, PosDecode,
                    0x0000,             // Granularity
                    0x0080,             // Range Minimum
                    0x00FF,             // Range Maximum
                    0x0000,             // Translation Offset
                    0x0080,             // Length
                    ,, _Y08)
                WordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                    0x0000,             // Granularity
                    0x0000,             // Range Minimum
                    0x0000,             // Range Maximum
                    0x0000,             // Translation Offset
                    0x0000,             // Length
                    ,, _Y0A, TypeStatic, DenseTranslation)
                WordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                    0x0000,             // Granularity
                    0x0000,             // Range Minimum
                    0x0000,             // Range Maximum
                    0x0000,             // Translation Offset
                    0x0000,             // Length
                    ,, _Y09, TypeStatic, DenseTranslation)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x00000000,         // Range Minimum
                    0x00000000,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00000000,         // Length
                    ,, _Y0B, AddressRangeMemory, TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x80000000,         // Range Minimum
                    0xFFFFFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x80000000,         // Length
                    ,, _Y0C, AddressRangeMemory, TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x80000000,         // Range Minimum
                    0xFFFFFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x80000000,         // Length
                    ,, _Y0D, AddressRangeMemory, TypeStatic)
                QWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x0000000000000000, // Granularity
                    0x0000000000000000, // Range Minimum
                    0x0000000000000000, // Range Maximum
                    0x0000000000000000, // Translation Offset
                    0x0000000000000000, // Length
                    ,, _Y0E, AddressRangeMemory, TypeStatic)
            })
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (STAV) /* \_SB_.PCI0.STAV */
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                If (CPRB)
                {
                    CreateWordField (CRS1, \_SB.PCI0._Y01._MIN, MIN0)  // _MIN: Minimum Base Address
                    CreateWordField (CRS1, \_SB.PCI0._Y01._MAX, MAX0)  // _MAX: Maximum Base Address
                    CreateWordField (CRS1, \_SB.PCI0._Y01._LEN, LEN0)  // _LEN: Length
                    MIN0 = BRB /* \_SB_.PCI0.BRB_ */
                    LEN0 = BRL /* \_SB_.PCI0.BRL_ */
                    Local0 = LEN0 /* \_SB_.PCI0._CRS.LEN0 */
                    MAX0 = (MIN0 + Local0--)
                    CreateWordField (CRS1, \_SB.PCI0._Y02._MIN, MIN1)  // _MIN: Minimum Base Address
                    CreateWordField (CRS1, \_SB.PCI0._Y02._MAX, MAX1)  // _MAX: Maximum Base Address
                    CreateWordField (CRS1, \_SB.PCI0._Y02._LEN, LEN1)  // _LEN: Length
                    If ((IOB == 0x1000))
                    {
                        Local0 = IOL /* \_SB_.PCI0.IOL_ */
                        MAX1 = (IOB + Local0--)
                        Local0 = (MAX1 - MIN1) /* \_SB_.PCI0._CRS.MIN1 */
                        LEN1 = (Local0 + One)
                    }
                    Else
                    {
                        MIN1 = IOB /* \_SB_.PCI0.IOB_ */
                        LEN1 = IOL /* \_SB_.PCI0.IOL_ */
                        Local0 = LEN1 /* \_SB_.PCI0._CRS.LEN1 */
                        MAX1 = (MIN1 + Local0--)
                    }

                    If (((LVGA == One) || (LVGA == 0x55)))
                    {
                        If (VGAF)
                        {
                            CreateWordField (CRS1, \_SB.PCI0._Y03._MIN, IMN1)  // _MIN: Minimum Base Address
                            CreateWordField (CRS1, \_SB.PCI0._Y03._MAX, IMX1)  // _MAX: Maximum Base Address
                            CreateWordField (CRS1, \_SB.PCI0._Y03._LEN, ILN1)  // _LEN: Length
                            IMN1 = 0x03B0
                            IMX1 = 0x03DF
                            ILN1 = 0x30
                            CreateDWordField (CRS1, \_SB.PCI0._Y04._MIN, VMN1)  // _MIN: Minimum Base Address
                            CreateDWordField (CRS1, \_SB.PCI0._Y04._MAX, VMX1)  // _MAX: Maximum Base Address
                            CreateDWordField (CRS1, \_SB.PCI0._Y04._LEN, VLN1)  // _LEN: Length
                            VMN1 = 0x000A0000
                            VMX1 = 0x000BFFFF
                            VLN1 = 0x00020000
                            VGAF = Zero
                        }
                    }

                    CreateDWordField (CRS1, \_SB.PCI0._Y05._MIN, MIN3)  // _MIN: Minimum Base Address
                    CreateDWordField (CRS1, \_SB.PCI0._Y05._MAX, MAX3)  // _MAX: Maximum Base Address
                    CreateDWordField (CRS1, \_SB.PCI0._Y05._LEN, LEN3)  // _LEN: Length
                    CreateDWordField (CRS1, \_SB.PCI0._Y06._MIN, MIN7)  // _MIN: Minimum Base Address
                    CreateDWordField (CRS1, \_SB.PCI0._Y06._MAX, MAX7)  // _MAX: Maximum Base Address
                    CreateDWordField (CRS1, \_SB.PCI0._Y06._LEN, LEN7)  // _LEN: Length
                    Local0 = (MBB + MBL) /* \_SB_.PCI0.MBL_ */
                    If ((Local0 < NBTP))
                    {
                        MIN3 = MBB /* \_SB_.PCI0.MBB_ */
                        LEN3 = MBL /* \_SB_.PCI0.MBL_ */
                        Local0 = LEN3 /* \_SB_.PCI0._CRS.LEN3 */
                        MAX3 = (MIN3 + Local0--)
                        MIN7 = Zero
                        MAX7 = Zero
                        LEN7 = Zero
                    }
                    Else
                    {
                        MIN3 = MBB /* \_SB_.PCI0.MBB_ */
                        LEN3 = (NBTP - MBB)
                        Local0 = LEN3 /* \_SB_.PCI0._CRS.LEN3 */
                        MAX3 = (MIN3 + Local0--)
                        MIN7 = 0xFEE00000
                        Local0 = (0xFEE00000 - NBTP)
                        LEN7 = (MBL - Local0)
                        LEN7 = (LEN7 - LEN3)
                        Local0 = LEN7 /* \_SB_.PCI0._CRS.LEN7 */
                        MAX7 = (MIN7 + Local0--)
                    }

                    If (MAL)
                    {
                        CreateQWordField (CRS1, \_SB.PCI0._Y07._MIN, MN8)  // _MIN: Minimum Base Address
                        CreateQWordField (CRS1, \_SB.PCI0._Y07._MAX, MX8)  // _MAX: Maximum Base Address
                        CreateQWordField (CRS1, \_SB.PCI0._Y07._LEN, LN8)  // _LEN: Length
                        MN8 = MAB /* \_SB_.PCI0.MAB_ */
                        LN8 = MAL /* \_SB_.PCI0.MAL_ */
                        MX8 = MAM /* \_SB_.PCI0.MAM_ */
                    }

                    Return (CRS1) /* \_SB_.PCI0.CRS1 */
                }
                Else
                {
                    CreateWordField (CRS2, \_SB.PCI0._Y08._MIN, MIN2)  // _MIN: Minimum Base Address
                    CreateWordField (CRS2, \_SB.PCI0._Y08._MAX, MAX2)  // _MAX: Maximum Base Address
                    CreateWordField (CRS2, \_SB.PCI0._Y08._LEN, LEN2)  // _LEN: Length
                    MIN2 = BRB /* \_SB_.PCI0.BRB_ */
                    LEN2 = BRL /* \_SB_.PCI0.BRL_ */
                    Local1 = LEN2 /* \_SB_.PCI0._CRS.LEN2 */
                    MAX2 = (MIN2 + Local1--)
                    CreateWordField (CRS2, \_SB.PCI0._Y09._MIN, MIN4)  // _MIN: Minimum Base Address
                    CreateWordField (CRS2, \_SB.PCI0._Y09._MAX, MAX4)  // _MAX: Maximum Base Address
                    CreateWordField (CRS2, \_SB.PCI0._Y09._LEN, LEN4)  // _LEN: Length
                    MIN4 = IOB /* \_SB_.PCI0.IOB_ */
                    LEN4 = IOL /* \_SB_.PCI0.IOL_ */
                    Local1 = LEN4 /* \_SB_.PCI0._CRS.LEN4 */
                    MAX4 = (MIN4 + Local1--)
                    If (LVGA)
                    {
                        CreateWordField (CRS2, \_SB.PCI0._Y0A._MIN, IMN2)  // _MIN: Minimum Base Address
                        CreateWordField (CRS2, \_SB.PCI0._Y0A._MAX, IMX2)  // _MAX: Maximum Base Address
                        CreateWordField (CRS2, \_SB.PCI0._Y0A._LEN, ILN2)  // _LEN: Length
                        IMN2 = 0x03B0
                        IMX2 = 0x03DF
                        ILN2 = 0x30
                        CreateDWordField (CRS2, \_SB.PCI0._Y0B._MIN, VMN2)  // _MIN: Minimum Base Address
                        CreateDWordField (CRS2, \_SB.PCI0._Y0B._MAX, VMX2)  // _MAX: Maximum Base Address
                        CreateDWordField (CRS2, \_SB.PCI0._Y0B._LEN, VLN2)  // _LEN: Length
                        VMN2 = 0x000A0000
                        VMX2 = 0x000BFFFF
                        VLN2 = 0x00020000
                    }

                    CreateDWordField (CRS2, \_SB.PCI0._Y0C._MIN, MIN5)  // _MIN: Minimum Base Address
                    CreateDWordField (CRS2, \_SB.PCI0._Y0C._MAX, MAX5)  // _MAX: Maximum Base Address
                    CreateDWordField (CRS2, \_SB.PCI0._Y0C._LEN, LEN5)  // _LEN: Length
                    MIN5 = MBB /* \_SB_.PCI0.MBB_ */
                    LEN5 = (NBTP - MBB)
                    Local1 = LEN5 /* \_SB_.PCI0._CRS.LEN5 */
                    MAX5 = (MIN5 + Local1--)
                    CreateDWordField (CRS2, \_SB.PCI0._Y0D._MIN, MIN6)  // _MIN: Minimum Base Address
                    CreateDWordField (CRS2, \_SB.PCI0._Y0D._MAX, MAX6)  // _MAX: Maximum Base Address
                    CreateDWordField (CRS2, \_SB.PCI0._Y0D._LEN, LEN6)  // _LEN: Length
                    MIN6 = (NBTP + NBTS) /* \NBTS */
                    LEN6 = (MBL - NBTS)
                    LEN6 = (LEN6 - LEN5)
                    Local0 = LEN6 /* \_SB_.PCI0._CRS.LEN6 */
                    MAX6 = (MIN6 + Local0--)
                    If (MAL)
                    {
                        CreateQWordField (CRS2, \_SB.PCI0._Y0E._MIN, MN9)  // _MIN: Minimum Base Address
                        CreateQWordField (CRS2, \_SB.PCI0._Y0E._MAX, MX9)  // _MAX: Maximum Base Address
                        CreateQWordField (CRS2, \_SB.PCI0._Y0E._LEN, LN9)  // _LEN: Length
                        MN9 = MAB /* \_SB_.PCI0.MAB_ */
                        LN9 = MAL /* \_SB_.PCI0.MAL_ */
                        MX9 = MAM /* \_SB_.PCI0.MAM_ */
                    }

                    Return (CRS2) /* \_SB_.PCI0.CRS2 */
                }
            }

            Method (_OSC, 4, Serialized)  // _OSC: Operating System Capabilities
            {
                Name (SUPP, Zero)
                Name (CTRL, Zero)
                CreateDWordField (Arg3, Zero, CDW1)
                CreateDWordField (Arg3, 0x04, CDW2)
                CreateDWordField (Arg3, 0x08, CDW3)
                If ((Arg0 == ToUUID ("33db4d5b-1ff7-401c-9657-7441c03dd766") /* PCI Host Bridge Device */))
                {
                    SUPP = CDW2 /* \_SB_.PCI0._OSC.CDW2 */
                    CTRL = CDW3 /* \_SB_.PCI0._OSC.CDW3 */
                    If (((SUPP & 0x16) != 0x16))
                    {
                        CTRL &= 0x1E
                    }

                    If (!PEHP)
                    {
                        CTRL &= 0x1E
                    }

                    If (!SHPC)
                    {
                        CTRL &= 0x1D
                    }

                    If (!PEPM)
                    {
                        CTRL &= 0x1B
                    }

                    If (!PEER)
                    {
                        CTRL &= 0x15
                    }

                    If (!PECS)
                    {
                        CTRL &= 0x0F
                    }

                    If ((PNPM != One))
                    {
                        CTRL &= 0x1A
                    }

                    If ((Arg1 != One))
                    {
                        CDW1 |= 0x08
                    }

                    If ((CDW3 != CTRL))
                    {
                        CDW1 |= 0x10
                    }

                    CDW3 = CTRL /* \_SB_.PCI0._OSC.CTRL */
                    Return (Arg3)
                }
                Else
                {
                    CDW1 |= 0x04
                    Return (Arg3)
                }
            }

            OperationRegion (NAPC, PCI_Config, 0xB8, 0x08)
            Field (NAPC, DWordAcc, NoLock, Preserve)
            {
                NAPX,   32, 
                NAPD,   32
            }

            Mutex (NAPM, 0x00)
            Method (NAPE, 0, NotSerialized)
            {
                Acquire (NAPM, 0xFFFF)
                NAPX = 0x14300000
                Local0 = NAPD /* \_SB_.PCI0.NAPD */
                Local0 &= 0xFFFFFFEF
                NAPD = Local0
                Release (NAPM)
            }

            Method (GPTS, 1, NotSerialized)
            {
            }

            Method (GWAK, 1, NotSerialized)
            {
                If (PICM)
                {
                    NAPE ()
                }
            }

            Device (IOMA)
            {
                Name (_ADR, 0x02)  // _ADR: Address
                Name (_HID, EisaId ("PNP0C02") /* PNP Motherboard Resources */)  // _HID: Hardware ID
                Name (_UID, 0x15)  // _UID: Unique ID
                Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
                {
                    Name (CRSB, ResourceTemplate ()
                    {
                        Memory32Fixed (ReadOnly,
                            0xBBAABBAA,         // Address Base
                            0x00080000,         // Address Length
                            _Y0F)
                    })
                    Local0 = (PEBS + 0x2000)
                    OperationRegion (PCIF, SystemMemory, Local0, 0x0100)
                    Field (PCIF, ByteAcc, NoLock, Preserve)
                    {
                        Offset (0x44), 
                        BAR0,   32
                    }

                    Local1 = BAR0 /* \_SB_.PCI0.IOMA._CRS.BAR0 */
                    Local1 &= 0xFFF80000
                    CreateDWordField (CRSB, \_SB.PCI0.IOMA._CRS._Y0F._BAS, CBAR)  // _BAS: Base Address
                    CBAR = Local1
                    Return (CRSB) /* \_SB_.PCI0.IOMA._CRS.CRSB */
                }
            }

            Device (GNBD)
            {
                Name (_ADR, Zero)  // _ADR: Address
                Device (BROD)
                {
                    Name (_HID, EisaId ("PNP0C02") /* PNP Motherboard Resources */)  // _HID: Hardware ID
                    Name (_UID, 0x14)  // _UID: Unique ID
                    Name (UMAS, 0x0000000080000000)
                    Name (UMAB, 0x0000001000000000)
                    Name (UMAM, 0x000000107FFFFFFF)
                    Name (CRS, ResourceTemplate ()
                    {
                        QWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                            0x0000000000000000, // Granularity
                            0x0000000000000000, // Range Minimum
                            0x0000000000000000, // Range Maximum
                            0x0000000000000000, // Translation Offset
                            0x0000000000000000, // Length
                            ,, _Y10, AddressRangeMemory, TypeStatic)
                    })
                    Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
                    {
                        CreateQWordField (CRS, \_SB.PCI0.GNBD.BROD._Y10._MIN, UMIN)  // _MIN: Minimum Base Address
                        CreateQWordField (CRS, \_SB.PCI0.GNBD.BROD._Y10._MAX, UMAX)  // _MAX: Maximum Base Address
                        CreateQWordField (CRS, \_SB.PCI0.GNBD.BROD._Y10._LEN, ULEN)  // _LEN: Length
                        UMIN = UMAB /* \_SB_.PCI0.GNBD.BROD.UMAB */
                        ULEN = UMAS /* \_SB_.PCI0.GNBD.BROD.UMAS */
                        UMAX = UMAM /* \_SB_.PCI0.GNBD.BROD.UMAM */
                        Return (CRS) /* \_SB_.PCI0.GNBD.BROD.CRS_ */
                    }
                }
            }

            Device (D003)
            {
                Name (_ADR, 0x00010000)  // _ADR: Address
            }

            Device (GPP3)
            {
                Name (_ADR, 0x00010004)  // _ADR: Address
                Method (_PRW, 0, NotSerialized)  // _PRW: Power Resources for Wake
                {
                    Return (GPRW (0x0F, 0x04))
                }

                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (PICM)
                    {
                        Return (AG07) /* \_SB_.AG07 */
                    }

                    Return (PG07) /* \_SB_.PG07 */
                }

                Device (D008)
                {
                    Name (_ADR, 0xFF)  // _ADR: Address
                }
            }

            Device (GPP4)
            {
                Name (_ADR, 0x00010005)  // _ADR: Address
                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (PICM)
                    {
                        Return (AG09) /* \_SB_.AG09 */
                    }

                    Return (PG09) /* \_SB_.PG09 */
                }

                Device (D00A)
                {
                    Name (_ADR, 0xFF)  // _ADR: Address
                }
            }

            Device (GPP5)
            {
                Name (_ADR, 0x00010006)  // _ADR: Address
                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (PICM)
                    {
                        Return (AG0B) /* \_SB_.AG0B */
                    }

                    Return (PG0B) /* \_SB_.PG0B */
                }

                Device (D00C)
                {
                    Name (_ADR, 0xFF)  // _ADR: Address
                }
            }

            Device (GPP6)
            {
                Name (_ADR, 0x00010007)  // _ADR: Address
                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (PICM)
                    {
                        Return (AG0D) /* \_SB_.AG0D */
                    }

                    Return (PG0D) /* \_SB_.PG0D */
                }

                Device (D00E)
                {
                    Name (_ADR, 0xFF)  // _ADR: Address
                }
            }

            Device (D00F)
            {
                Name (_ADR, 0x00020000)  // _ADR: Address
            }

            Device (D012)
            {
                Name (_ADR, 0x00030000)  // _ADR: Address
            }

            Device (GPP9)
            {
                Name (_ADR, 0x00030001)  // _ADR: Address
                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (PICM)
                    {
                        Return (AG13) /* \_SB_.AG13 */
                    }

                    Return (PG13) /* \_SB_.PG13 */
                }

                Device (D014)
                {
                    Name (_ADR, 0xFF)  // _ADR: Address
                }
            }

            Device (GPPA)
            {
                Name (_ADR, 0x00030002)  // _ADR: Address
                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (PICM)
                    {
                        Return (AG15) /* \_SB_.AG15 */
                    }

                    Return (PG15) /* \_SB_.PG15 */
                }

                Device (D016)
                {
                    Name (_ADR, 0xFF)  // _ADR: Address
                }
            }

            Device (GPPB)
            {
                Name (_ADR, 0x00030003)  // _ADR: Address
                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (PICM)
                    {
                        Return (AG17) /* \_SB_.AG17 */
                    }

                    Return (PG17) /* \_SB_.PG17 */
                }

                Device (D018)
                {
                    Name (_ADR, 0xFF)  // _ADR: Address
                }
            }

            Device (GPPC)
            {
                Name (_ADR, 0x00030004)  // _ADR: Address
                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (PICM)
                    {
                        Return (AG19) /* \_SB_.AG19 */
                    }

                    Return (PG19) /* \_SB_.PG19 */
                }

                Device (D01A)
                {
                    Name (_ADR, 0xFF)  // _ADR: Address
                }
            }

            Device (GPPD)
            {
                Name (_ADR, 0x00030005)  // _ADR: Address
                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (PICM)
                    {
                        Return (AG1B) /* \_SB_.AG1B */
                    }

                    Return (PG1B) /* \_SB_.PG1B */
                }

                Device (D01C)
                {
                    Name (_ADR, 0xFF)  // _ADR: Address
                }
            }

            Device (GPPE)
            {
                Name (_ADR, 0x00030006)  // _ADR: Address
                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (PICM)
                    {
                        Return (AG1D) /* \_SB_.AG1D */
                    }

                    Return (PG1D) /* \_SB_.PG1D */
                }

                Device (D01E)
                {
                    Name (_ADR, 0xFF)  // _ADR: Address
                }
            }

            Device (GPPF)
            {
                Name (_ADR, 0x00030007)  // _ADR: Address
                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (PICM)
                    {
                        Return (AG1F) /* \_SB_.AG1F */
                    }

                    Return (PG1F) /* \_SB_.PG1F */
                }

                Device (D020)
                {
                    Name (_ADR, 0xFF)  // _ADR: Address
                }
            }

            Device (D021)
            {
                Name (_ADR, 0x00040000)  // _ADR: Address
            }

            Device (GPPG)
            {
                Name (_ADR, 0x00040001)  // _ADR: Address
                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (PICM)
                    {
                        Return (AG22) /* \_SB_.AG22 */
                    }

                    Return (PG22) /* \_SB_.PG22 */
                }

                Device (D023)
                {
                    Name (_ADR, 0xFF)  // _ADR: Address
                }
            }

            Device (GPPH)
            {
                Name (_ADR, 0x00040002)  // _ADR: Address
                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (PICM)
                    {
                        Return (AG24) /* \_SB_.AG24 */
                    }

                    Return (PG24) /* \_SB_.PG24 */
                }

                Device (D025)
                {
                    Name (_ADR, 0xFF)  // _ADR: Address
                }
            }

            Device (D026)
            {
                Name (_ADR, 0x00080000)  // _ADR: Address
            }

            Device (GP17)
            {
                Name (_ADR, 0x00080001)  // _ADR: Address
                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (PICM)
                    {
                        Return (AG27) /* \_SB_.AG27 */
                    }

                    Return (PG27) /* \_SB_.PG27 */
                }

                Device (VGA)
                {
                    Name (_ADR, Zero)  // _ADR: Address
                }

                Device (D02B)
                {
                    Name (_ADR, One)  // _ADR: Address
                }

                Device (ACP)
                {
                    Name (_ADR, 0x05)  // _ADR: Address
                }

                Device (AZAL)
                {
                    Name (_ADR, 0x06)  // _ADR: Address
                }

                Device (XHC0)
                {
                    Name (_ADR, 0x03)  // _ADR: Address
                }

                Device (XHC1)
                {
                    Name (_ADR, 0x04)  // _ADR: Address
                }
            }

            Device (D032)
            {
                Name (_ADR, 0x00140000)  // _ADR: Address
            }

            Device (SBRG)
            {
                Name (_ADR, 0x00140003)  // _ADR: Address
                Device (PIC)
                {
                    Name (_HID, EisaId ("PNP0000") /* 8259-compatible Programmable Interrupt Controller */)  // _HID: Hardware ID
                    Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                    {
                        IO (Decode16,
                            0x0020,             // Range Minimum
                            0x0020,             // Range Maximum
                            0x00,               // Alignment
                            0x02,               // Length
                            )
                        IO (Decode16,
                            0x00A0,             // Range Minimum
                            0x00A0,             // Range Maximum
                            0x00,               // Alignment
                            0x02,               // Length
                            )
                        IRQNoFlags ()
                            {2}
                    })
                }

                Device (DMAD)
                {
                    Name (_HID, EisaId ("PNP0200") /* PC-class DMA Controller */)  // _HID: Hardware ID
                    Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                    {
                        DMA (Compatibility, BusMaster, Transfer8, )
                            {4}
                        IO (Decode16,
                            0x0000,             // Range Minimum
                            0x0000,             // Range Maximum
                            0x00,               // Alignment
                            0x10,               // Length
                            )
                        IO (Decode16,
                            0x0081,             // Range Minimum
                            0x0081,             // Range Maximum
                            0x00,               // Alignment
                            0x03,               // Length
                            )
                        IO (Decode16,
                            0x0087,             // Range Minimum
                            0x0087,             // Range Maximum
                            0x00,               // Alignment
                            0x01,               // Length
                            )
                        IO (Decode16,
                            0x0089,             // Range Minimum
                            0x0089,             // Range Maximum
                            0x00,               // Alignment
                            0x03,               // Length
                            )
                        IO (Decode16,
                            0x008F,             // Range Minimum
                            0x008F,             // Range Maximum
                            0x00,               // Alignment
                            0x01,               // Length
                            )
                        IO (Decode16,
                            0x00C0,             // Range Minimum
                            0x00C0,             // Range Maximum
                            0x00,               // Alignment
                            0x20,               // Length
                            )
                    })
                }

                Device (TMR)
                {
                    Name (_HID, EisaId ("PNP0100") /* PC-class System Timer */)  // _HID: Hardware ID
                    Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                    {
                        IO (Decode16,
                            0x0040,             // Range Minimum
                            0x0040,             // Range Maximum
                            0x00,               // Alignment
                            0x04,               // Length
                            )
                        IRQNoFlags ()
                            {0}
                    })
                }

                Device (RTC0)
                {
                    Name (_HID, EisaId ("PNP0B00") /* AT Real-Time Clock */)  // _HID: Hardware ID
                    Name (BUF0, ResourceTemplate ()
                    {
                        IO (Decode16,
                            0x0070,             // Range Minimum
                            0x0070,             // Range Maximum
                            0x00,               // Alignment
                            0x02,               // Length
                            )
                    })
                    Name (BUF1, ResourceTemplate ()
                    {
                        IO (Decode16,
                            0x0070,             // Range Minimum
                            0x0070,             // Range Maximum
                            0x00,               // Alignment
                            0x02,               // Length
                            )
                        IRQNoFlags ()
                            {8}
                    })
                    Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
                    {
                        If ((HPEN == One))
                        {
                            Return (BUF0) /* \_SB_.PCI0.SBRG.RTC0.BUF0 */
                        }

                        Return (BUF1) /* \_SB_.PCI0.SBRG.RTC0.BUF1 */
                    }
                }

                Device (SPKR)
                {
                    Name (_HID, EisaId ("PNP0800") /* Microsoft Sound System Compatible Device */)  // _HID: Hardware ID
                    Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                    {
                        IO (Decode16,
                            0x0061,             // Range Minimum
                            0x0061,             // Range Maximum
                            0x00,               // Alignment
                            0x01,               // Length
                            )
                    })
                }

                OperationRegion (SMI0, SystemIO, SMIO, One)
                Field (SMI0, ByteAcc, NoLock, Preserve)
                {
                    SMIC,   8
                }

                Scope (\_SB)
                {
                    Scope (PCI0)
                    {
                        Device (S900)
                        {
                            Name (_HID, EisaId ("PNP0C02") /* PNP Motherboard Resources */)  // _HID: Hardware ID
                            Name (_UID, 0x0700)  // _UID: Unique ID
                            Name (_STA, 0x0F)  // _STA: Status
                            Name (CRS, ResourceTemplate ()
                            {
                                IO (Decode16,
                                    0x0010,             // Range Minimum
                                    0x0010,             // Range Maximum
                                    0x00,               // Alignment
                                    0x10,               // Length
                                    )
                                IO (Decode16,
                                    0x0022,             // Range Minimum
                                    0x0022,             // Range Maximum
                                    0x00,               // Alignment
                                    0x1E,               // Length
                                    )
                                IO (Decode16,
                                    0x0063,             // Range Minimum
                                    0x0063,             // Range Maximum
                                    0x00,               // Alignment
                                    0x01,               // Length
                                    )
                                IO (Decode16,
                                    0x0065,             // Range Minimum
                                    0x0065,             // Range Maximum
                                    0x00,               // Alignment
                                    0x01,               // Length
                                    )
                                IO (Decode16,
                                    0x0067,             // Range Minimum
                                    0x0067,             // Range Maximum
                                    0x00,               // Alignment
                                    0x09,               // Length
                                    )
                                IO (Decode16,
                                    0x0072,             // Range Minimum
                                    0x0072,             // Range Maximum
                                    0x00,               // Alignment
                                    0x0E,               // Length
                                    )
                                IO (Decode16,
                                    0x0080,             // Range Minimum
                                    0x0080,             // Range Maximum
                                    0x00,               // Alignment
                                    0x01,               // Length
                                    )
                                IO (Decode16,
                                    0x0084,             // Range Minimum
                                    0x0084,             // Range Maximum
                                    0x00,               // Alignment
                                    0x03,               // Length
                                    )
                                IO (Decode16,
                                    0x0088,             // Range Minimum
                                    0x0088,             // Range Maximum
                                    0x00,               // Alignment
                                    0x01,               // Length
                                    )
                                IO (Decode16,
                                    0x008C,             // Range Minimum
                                    0x008C,             // Range Maximum
                                    0x00,               // Alignment
                                    0x03,               // Length
                                    )
                                IO (Decode16,
                                    0x0090,             // Range Minimum
                                    0x0090,             // Range Maximum
                                    0x00,               // Alignment
                                    0x10,               // Length
                                    )
                                IO (Decode16,
                                    0x00A2,             // Range Minimum
                                    0x00A2,             // Range Maximum
                                    0x00,               // Alignment
                                    0x1E,               // Length
                                    )
                                IO (Decode16,
                                    0x00B1,             // Range Minimum
                                    0x00B1,             // Range Maximum
                                    0x00,               // Alignment
                                    0x01,               // Length
                                    )
                                IO (Decode16,
                                    0x00E0,             // Range Minimum
                                    0x00E0,             // Range Maximum
                                    0x00,               // Alignment
                                    0x10,               // Length
                                    )
                                IO (Decode16,
                                    0x04D0,             // Range Minimum
                                    0x04D0,             // Range Maximum
                                    0x00,               // Alignment
                                    0x02,               // Length
                                    )
                                IO (Decode16,
                                    0x040B,             // Range Minimum
                                    0x040B,             // Range Maximum
                                    0x00,               // Alignment
                                    0x01,               // Length
                                    )
                                IO (Decode16,
                                    0x04D6,             // Range Minimum
                                    0x04D6,             // Range Maximum
                                    0x00,               // Alignment
                                    0x01,               // Length
                                    )
                                IO (Decode16,
                                    0x0C00,             // Range Minimum
                                    0x0C00,             // Range Maximum
                                    0x00,               // Alignment
                                    0x02,               // Length
                                    )
                                IO (Decode16,
                                    0x0C14,             // Range Minimum
                                    0x0C14,             // Range Maximum
                                    0x00,               // Alignment
                                    0x01,               // Length
                                    )
                                IO (Decode16,
                                    0x0C50,             // Range Minimum
                                    0x0C50,             // Range Maximum
                                    0x00,               // Alignment
                                    0x02,               // Length
                                    )
                                IO (Decode16,
                                    0x0C52,             // Range Minimum
                                    0x0C52,             // Range Maximum
                                    0x00,               // Alignment
                                    0x01,               // Length
                                    )
                                IO (Decode16,
                                    0x0C6C,             // Range Minimum
                                    0x0C6C,             // Range Maximum
                                    0x00,               // Alignment
                                    0x01,               // Length
                                    )
                                IO (Decode16,
                                    0x0C6F,             // Range Minimum
                                    0x0C6F,             // Range Maximum
                                    0x00,               // Alignment
                                    0x01,               // Length
                                    )
                                IO (Decode16,
                                    0x0CD8,             // Range Minimum
                                    0x0CD8,             // Range Maximum
                                    0x00,               // Alignment
                                    0x08,               // Length
                                    )
                                IO (Decode16,
                                    0x0000,             // Range Minimum
                                    0x0000,             // Range Maximum
                                    0x00,               // Alignment
                                    0x00,               // Length
                                    _Y11)
                                IO (Decode16,
                                    0x0000,             // Range Minimum
                                    0x0000,             // Range Maximum
                                    0x00,               // Alignment
                                    0x00,               // Length
                                    _Y13)
                                IO (Decode16,
                                    0x0000,             // Range Minimum
                                    0x0000,             // Range Maximum
                                    0x00,               // Alignment
                                    0x00,               // Length
                                    _Y12)
                                IO (Decode16,
                                    0x0900,             // Range Minimum
                                    0x0900,             // Range Maximum
                                    0x00,               // Alignment
                                    0x10,               // Length
                                    )
                                IO (Decode16,
                                    0x0910,             // Range Minimum
                                    0x0910,             // Range Maximum
                                    0x00,               // Alignment
                                    0x10,               // Length
                                    )
                                IO (Decode16,
                                    0x0060,             // Range Minimum
                                    0x0060,             // Range Maximum
                                    0x00,               // Alignment
                                    0x00,               // Length
                                    )
                                IO (Decode16,
                                    0x0064,             // Range Minimum
                                    0x0064,             // Range Maximum
                                    0x00,               // Alignment
                                    0x00,               // Length
                                    )
                                Memory32Fixed (ReadWrite,
                                    0xFEDC0000,         // Address Base
                                    0x00001000,         // Address Length
                                    )
                                Memory32Fixed (ReadWrite,
                                    0xFEE00000,         // Address Base
                                    0x00001000,         // Address Length
                                    )
                                Memory32Fixed (ReadWrite,
                                    0x00000000,         // Address Base
                                    0x00000000,         // Address Length
                                    _Y14)
                                Memory32Fixed (ReadWrite,
                                    0x00000000,         // Address Base
                                    0x00000000,         // Address Length
                                    _Y15)
                                Memory32Fixed (ReadWrite,
                                    0x00000000,         // Address Base
                                    0x00000000,         // Address Length
                                    _Y16)
                            })
                            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
                            {
                                CreateWordField (CRS, \_SB.PCI0.S900._Y11._MIN, PBB)  // _MIN: Minimum Base Address
                                CreateWordField (CRS, \_SB.PCI0.S900._Y11._MAX, PBH)  // _MAX: Maximum Base Address
                                CreateByteField (CRS, \_SB.PCI0.S900._Y11._LEN, PML)  // _LEN: Length
                                PBB = PMBS /* \PMBS */
                                PBH = PMBS /* \PMBS */
                                PML = PMLN /* \PMLN */
                                If (SMBB)
                                {
                                    CreateWordField (CRS, \_SB.PCI0.S900._Y12._MIN, SMB1)  // _MIN: Minimum Base Address
                                    CreateWordField (CRS, \_SB.PCI0.S900._Y12._MAX, SMH1)  // _MAX: Maximum Base Address
                                    CreateByteField (CRS, \_SB.PCI0.S900._Y12._LEN, SML1)  // _LEN: Length
                                    SMB1 = SMBB /* \SMBB */
                                    SMH1 = SMBB /* \SMBB */
                                    SML1 = SMBL /* \SMBL */
                                    CreateWordField (CRS, \_SB.PCI0.S900._Y13._MIN, SMBZ)  // _MIN: Minimum Base Address
                                    CreateWordField (CRS, \_SB.PCI0.S900._Y13._MAX, SMH0)  // _MAX: Maximum Base Address
                                    CreateByteField (CRS, \_SB.PCI0.S900._Y13._LEN, SML0)  // _LEN: Length
                                    SMBZ = SMB0 /* \SMB0 */
                                    SMH0 = SMB0 /* \SMB0 */
                                    SML0 = SMBM /* \SMBM */
                                }

                                CreateDWordField (CRS, \_SB.PCI0.S900._Y14._BAS, SPIB)  // _BAS: Base Address
                                CreateDWordField (CRS, \_SB.PCI0.S900._Y14._LEN, SPIL)  // _LEN: Length
                                SPIB = 0xFEC10000
                                SPIL = 0x1000
                                If (WDTB)
                                {
                                    CreateDWordField (CRS, \_SB.PCI0.S900._Y15._BAS, WDTB)  // _BAS: Base Address
                                    CreateDWordField (CRS, \_SB.PCI0.S900._Y15._LEN, WDTL)  // _LEN: Length
                                    WDTB = \WDTB
                                    WDTL = \WDTL
                                }

                                CreateDWordField (CRS, \_SB.PCI0.S900._Y16._BAS, ROMB)  // _BAS: Base Address
                                CreateDWordField (CRS, \_SB.PCI0.S900._Y16._LEN, ROML)  // _LEN: Length
                                ROMB = 0xFF000000
                                ROML = 0x01000000
                                Return (CRS) /* \_SB_.PCI0.S900.CRS_ */
                            }
                        }
                    }
                }

                Scope (\_SB)
                {
                    Scope (PCI0)
                    {
                        Scope (SBRG)
                        {
                            Method (RRIO, 4, NotSerialized)
                            {
                                Debug = "RRIO"
                            }

                            Method (RDMA, 3, NotSerialized)
                            {
                                Debug = "rDMA"
                            }
                        }
                    }
                }

                Device (SIO1)
                {
                    Name (_HID, EisaId ("PNP0C02") /* PNP Motherboard Resources */)  // _HID: Hardware ID
                    Name (_UID, Zero)  // _UID: Unique ID
                    Name (CRS, ResourceTemplate ()
                    {
                        IO (Decode16,
                            0x0000,             // Range Minimum
                            0x0000,             // Range Maximum
                            0x00,               // Alignment
                            0x00,               // Length
                            _Y17)
                        IO (Decode16,
                            0x0000,             // Range Minimum
                            0x0000,             // Range Maximum
                            0x00,               // Alignment
                            0x00,               // Length
                            _Y18)
                        IO (Decode16,
                            0x0000,             // Range Minimum
                            0x0000,             // Range Maximum
                            0x00,               // Alignment
                            0x00,               // Length
                            _Y19)
                        IO (Decode16,
                            0x0000,             // Range Minimum
                            0x0000,             // Range Maximum
                            0x00,               // Alignment
                            0x00,               // Length
                            _Y1A)
                        IO (Decode16,
                            0x0000,             // Range Minimum
                            0x0000,             // Range Maximum
                            0x00,               // Alignment
                            0x00,               // Length
                            _Y1B)
                    })
                    Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
                    {
                        If (((SP1O < 0x03F0) && (SP1O > 0xF0)))
                        {
                            CreateWordField (CRS, \_SB.PCI0.SBRG.SIO1._Y17._MIN, GPI0)  // _MIN: Minimum Base Address
                            CreateWordField (CRS, \_SB.PCI0.SBRG.SIO1._Y17._MAX, GPI1)  // _MAX: Maximum Base Address
                            CreateByteField (CRS, \_SB.PCI0.SBRG.SIO1._Y17._LEN, GPIL)  // _LEN: Length
                            GPI0 = SP1O /* \SP1O */
                            GPI1 = SP1O /* \SP1O */
                            GPIL = 0x02
                        }

                        If (IO1B)
                        {
                            CreateWordField (CRS, \_SB.PCI0.SBRG.SIO1._Y18._MIN, GP10)  // _MIN: Minimum Base Address
                            CreateWordField (CRS, \_SB.PCI0.SBRG.SIO1._Y18._MAX, GP11)  // _MAX: Maximum Base Address
                            CreateByteField (CRS, \_SB.PCI0.SBRG.SIO1._Y18._LEN, GPL1)  // _LEN: Length
                            GP10 = IO1B /* \IO1B */
                            GP11 = IO1B /* \IO1B */
                            GPL1 = IO1L /* \IO1L */
                        }

                        If (IO2B)
                        {
                            CreateWordField (CRS, \_SB.PCI0.SBRG.SIO1._Y19._MIN, GP20)  // _MIN: Minimum Base Address
                            CreateWordField (CRS, \_SB.PCI0.SBRG.SIO1._Y19._MAX, GP21)  // _MAX: Maximum Base Address
                            CreateByteField (CRS, \_SB.PCI0.SBRG.SIO1._Y19._LEN, GPL2)  // _LEN: Length
                            GP20 = IO2B /* \IO2B */
                            GP21 = IO2B /* \IO2B */
                            GPL2 = IO2L /* \IO2L */
                        }

                        If (IO3B)
                        {
                            CreateWordField (CRS, \_SB.PCI0.SBRG.SIO1._Y1A._MIN, GP30)  // _MIN: Minimum Base Address
                            CreateWordField (CRS, \_SB.PCI0.SBRG.SIO1._Y1A._MAX, GP31)  // _MAX: Maximum Base Address
                            CreateByteField (CRS, \_SB.PCI0.SBRG.SIO1._Y1A._LEN, GPL3)  // _LEN: Length
                            GP30 = IO3B /* \IO3B */
                            GP31 = IO3B /* \IO3B */
                            GPL3 = IO3L /* \IO3L */
                        }

                        If (IO4B)
                        {
                            CreateWordField (CRS, \_SB.PCI0.SBRG.SIO1._Y1B._MIN, GP40)  // _MIN: Minimum Base Address
                            CreateWordField (CRS, \_SB.PCI0.SBRG.SIO1._Y1B._MAX, GP41)  // _MAX: Maximum Base Address
                            CreateByteField (CRS, \_SB.PCI0.SBRG.SIO1._Y1B._LEN, GPL4)  // _LEN: Length
                            GP40 = IO4B /* \IO4B */
                            GP41 = IO4B /* \IO4B */
                            GPL4 = IO4L /* \IO4L */
                        }

                        Return (CRS) /* \_SB_.PCI0.SBRG.SIO1.CRS_ */
                    }

                    Name (DCAT, Package (0x15)
                    {
                        0x02, 
                        0x03, 
                        One, 
                        Zero, 
                        0xFF, 
                        0xFF, 
                        0xFF, 
                        0xFF, 
                        0xFF, 
                        0xFF, 
                        0x05, 
                        0xFF, 
                        0xFF, 
                        0xFF, 
                        0x05, 
                        0xFF, 
                        0x06, 
                        0xFF, 
                        0xFF, 
                        0xFF, 
                        0xFF
                    })
                    Mutex (MUT0, 0x00)
                    Method (ENFG, 1, NotSerialized)
                    {
                        Acquire (MUT0, 0x0FFF)
                        INDX = ENTK /* \ENTK */
                        INDX = ENTK /* \ENTK */
                        LDN = Arg0
                    }

                    Method (EXFG, 0, NotSerialized)
                    {
                        INDX = EXTK /* \EXTK */
                        Release (MUT0)
                    }

                    Method (LPTM, 1, NotSerialized)
                    {
                        ENFG (CGLD (Arg0))
                        Local0 = (OPT0 & 0x02)
                        EXFG ()
                        Return (Local0)
                    }

                    Method (UHID, 1, NotSerialized)
                    {
                        Return (0x0105D041)
                    }

                    OperationRegion (IOID, SystemIO, SP1O, 0x02)
                    Field (IOID, ByteAcc, NoLock, Preserve)
                    {
                        INDX,   8, 
                        DATA,   8
                    }

                    IndexField (INDX, DATA, ByteAcc, NoLock, Preserve)
                    {
                        Offset (0x07), 
                        LDN,    8, 
                        Offset (0x21), 
                        SCF1,   8, 
                        Offset (0x22), 
                        SCF2,   8, 
                        Offset (0x23), 
                        SCF3,   8, 
                        Offset (0x24), 
                        SCF4,   8, 
                        Offset (0x25), 
                        SCF5,   8, 
                        Offset (0x26), 
                        SCF6,   8, 
                        Offset (0x29), 
                        CKCF,   8, 
                        Offset (0x2B), 
                        CR2B,   8, 
                        Offset (0x30), 
                        ACTR,   8, 
                        Offset (0x60), 
                        IOAH,   8, 
                        IOAL,   8, 
                        IOH2,   8, 
                        IOL2,   8, 
                        Offset (0x70), 
                        INTR,   4, 
                        INTT,   4, 
                        Offset (0x74), 
                        DMCH,   8, 
                        Offset (0xE0), 
                        RGE0,   8, 
                        RGE1,   8, 
                        RGE2,   8, 
                        RGE3,   8, 
                        RGE4,   8, 
                        RGE5,   8, 
                        RGE6,   8, 
                        RGE7,   8, 
                        RGE8,   8, 
                        RGE9,   8, 
                        Offset (0xF0), 
                        OPT0,   8, 
                        OPT1,   8, 
                        OPT2,   8, 
                        OPT3,   8, 
                        OPT4,   8, 
                        OPT5,   8, 
                        OPT6,   8, 
                        OPT7,   8, 
                        OPT8,   8, 
                        OPT9,   8
                    }

                    Method (CGLD, 1, NotSerialized)
                    {
                        Return (DerefOf (DCAT [Arg0]))
                    }

                    Method (DSTA, 1, NotSerialized)
                    {
                        ENFG (CGLD (Arg0))
                        Local0 = ACTR /* \_SB_.PCI0.SBRG.SIO1.ACTR */
                        Local1 = ((IOAH << 0x08) | IOAL) /* \_SB_.PCI0.SBRG.SIO1.IOAL */
                        EXFG ()
                        If ((Local0 == 0xFF))
                        {
                            Return (Zero)
                        }

                        Local0 &= One
                        If ((Arg0 < 0x10))
                        {
                            IOST |= (Local0 << Arg0)
                        }

                        If (Local0)
                        {
                            Return (0x0F)
                        }
                        ElseIf ((Arg0 < 0x10))
                        {
                            If (((One << Arg0) & IOST))
                            {
                                Return (0x0D)
                            }
                            Else
                            {
                                Return (Zero)
                            }
                        }
                        Else
                        {
                            If (Local1)
                            {
                                Return (0x0D)
                            }

                            Return (Zero)
                        }
                    }

                    Method (DCNT, 2, NotSerialized)
                    {
                        ENFG (CGLD (Arg0))
                        If (((DMCH < 0x04) && ((Local1 = (DMCH & 0x03)) != Zero)))
                        {
                            RDMA (Arg0, Arg1, Local1++)
                        }

                        ACTR = Arg1
                        Local1 = (IOAH << 0x08)
                        Local1 |= IOAL
                        RRIO (Arg0, Arg1, Local1, 0x08)
                        EXFG ()
                    }

                    Name (CRS1, ResourceTemplate ()
                    {
                        IO (Decode16,
                            0x0000,             // Range Minimum
                            0x0000,             // Range Maximum
                            0x01,               // Alignment
                            0x00,               // Length
                            _Y1E)
                        IRQNoFlags (_Y1C)
                            {}
                        DMA (Compatibility, NotBusMaster, Transfer8, _Y1D)
                            {}
                    })
                    CreateWordField (CRS1, \_SB.PCI0.SBRG.SIO1._Y1C._INT, IRQM)  // _INT: Interrupts
                    CreateByteField (CRS1, \_SB.PCI0.SBRG.SIO1._Y1D._DMA, DMAM)  // _DMA: Direct Memory Access
                    CreateWordField (CRS1, \_SB.PCI0.SBRG.SIO1._Y1E._MIN, IO11)  // _MIN: Minimum Base Address
                    CreateWordField (CRS1, \_SB.PCI0.SBRG.SIO1._Y1E._MAX, IO12)  // _MAX: Maximum Base Address
                    CreateByteField (CRS1, \_SB.PCI0.SBRG.SIO1._Y1E._LEN, LEN1)  // _LEN: Length
                    Name (CRS2, ResourceTemplate ()
                    {
                        IO (Decode16,
                            0x0000,             // Range Minimum
                            0x0000,             // Range Maximum
                            0x01,               // Alignment
                            0x00,               // Length
                            _Y21)
                        IO (Decode16,
                            0x0000,             // Range Minimum
                            0x0000,             // Range Maximum
                            0x01,               // Alignment
                            0x00,               // Length
                            _Y22)
                        IRQNoFlags (_Y1F)
                            {}
                        DMA (Compatibility, NotBusMaster, Transfer8, _Y20)
                            {}
                    })
                    CreateWordField (CRS2, \_SB.PCI0.SBRG.SIO1._Y1F._INT, IRQE)  // _INT: Interrupts
                    CreateByteField (CRS2, \_SB.PCI0.SBRG.SIO1._Y20._DMA, DMAE)  // _DMA: Direct Memory Access
                    CreateWordField (CRS2, \_SB.PCI0.SBRG.SIO1._Y21._MIN, IO21)  // _MIN: Minimum Base Address
                    CreateWordField (CRS2, \_SB.PCI0.SBRG.SIO1._Y21._MAX, IO22)  // _MAX: Maximum Base Address
                    CreateByteField (CRS2, \_SB.PCI0.SBRG.SIO1._Y21._LEN, LEN2)  // _LEN: Length
                    CreateWordField (CRS2, \_SB.PCI0.SBRG.SIO1._Y22._MIN, IO31)  // _MIN: Minimum Base Address
                    CreateWordField (CRS2, \_SB.PCI0.SBRG.SIO1._Y22._MAX, IO32)  // _MAX: Maximum Base Address
                    CreateByteField (CRS2, \_SB.PCI0.SBRG.SIO1._Y22._LEN, LEN3)  // _LEN: Length
                    Name (CRS3, ResourceTemplate ()
                    {
                        IO (Decode16,
                            0x0000,             // Range Minimum
                            0x0000,             // Range Maximum
                            0x01,               // Alignment
                            0x00,               // Length
                            _Y25)
                        IRQ (Level, ActiveLow, Shared, _Y23)
                            {}
                        DMA (Compatibility, NotBusMaster, Transfer8, _Y24)
                            {}
                    })
                    CreateWordField (CRS3, \_SB.PCI0.SBRG.SIO1._Y23._INT, IRQT)  // _INT: Interrupts
                    CreateByteField (CRS3, \_SB.PCI0.SBRG.SIO1._Y23._HE, IRQS)  // _HE_: High-Edge
                    CreateByteField (CRS3, \_SB.PCI0.SBRG.SIO1._Y24._DMA, DMAT)  // _DMA: Direct Memory Access
                    CreateWordField (CRS3, \_SB.PCI0.SBRG.SIO1._Y25._MIN, IO41)  // _MIN: Minimum Base Address
                    CreateWordField (CRS3, \_SB.PCI0.SBRG.SIO1._Y25._MAX, IO42)  // _MAX: Maximum Base Address
                    CreateByteField (CRS3, \_SB.PCI0.SBRG.SIO1._Y25._LEN, LEN4)  // _LEN: Length
                    Method (DCRS, 2, NotSerialized)
                    {
                        ENFG (CGLD (Arg0))
                        IO11 = (IOAH << 0x08)
                        IO11 |= IOAL /* \_SB_.PCI0.SBRG.SIO1.IO11 */
                        IO12 = IO11 /* \_SB_.PCI0.SBRG.SIO1.IO11 */
                        LEN1 = 0x08
                        If (INTR)
                        {
                            IRQM = (One << INTR) /* \_SB_.PCI0.SBRG.SIO1.INTR */
                        }
                        Else
                        {
                            IRQM = Zero
                        }

                        If (((DMCH > 0x03) || (Arg1 == Zero)))
                        {
                            DMAM = Zero
                        }
                        Else
                        {
                            Local1 = (DMCH & 0x03)
                            DMAM = (One << Local1)
                        }

                        EXFG ()
                        Return (CRS1) /* \_SB_.PCI0.SBRG.SIO1.CRS1 */
                    }

                    Method (DCR2, 2, NotSerialized)
                    {
                        ENFG (CGLD (Arg0))
                        IO21 = (IOAH << 0x08)
                        IO21 |= IOAL /* \_SB_.PCI0.SBRG.SIO1.IO21 */
                        IO22 = IO21 /* \_SB_.PCI0.SBRG.SIO1.IO21 */
                        LEN2 = 0x08
                        IO31 = (IOH2 << 0x08)
                        IO31 |= IOL2 /* \_SB_.PCI0.SBRG.SIO1.IO31 */
                        IO32 = IO31 /* \_SB_.PCI0.SBRG.SIO1.IO31 */
                        LEN3 = 0x08
                        If (INTR)
                        {
                            IRQE = (One << INTR) /* \_SB_.PCI0.SBRG.SIO1.INTR */
                        }
                        Else
                        {
                            IRQE = Zero
                        }

                        If (((DMCH > 0x03) || (Arg1 == Zero)))
                        {
                            DMAE = Zero
                        }
                        Else
                        {
                            Local1 = (DMCH & 0x03)
                            DMAE = (One << Local1)
                        }

                        EXFG ()
                        Return (CRS2) /* \_SB_.PCI0.SBRG.SIO1.CRS2 */
                    }

                    Method (DCR3, 2, NotSerialized)
                    {
                        ENFG (CGLD (Arg0))
                        IO41 = (IOAH << 0x08)
                        IO41 |= IOAL /* \_SB_.PCI0.SBRG.SIO1.IO41 */
                        IO42 = IO41 /* \_SB_.PCI0.SBRG.SIO1.IO41 */
                        LEN4 = 0x08
                        If (INTR)
                        {
                            IRQT = (One << INTR) /* \_SB_.PCI0.SBRG.SIO1.INTR */
                        }
                        Else
                        {
                            IRQT = Zero
                        }

                        If (((DMCH > 0x03) || (Arg1 == Zero)))
                        {
                            DMAT = Zero
                        }
                        Else
                        {
                            Local1 = (DMCH & 0x03)
                            DMAT = (One << Local1)
                        }

                        EXFG ()
                        Return (CRS3) /* \_SB_.PCI0.SBRG.SIO1.CRS3 */
                    }

                    Method (DSRS, 2, NotSerialized)
                    {
                        If (((Arg1 == 0x02) & LPTM (Arg1)))
                        {
                            DSR2 (Arg0, Arg1)
                        }
                        Else
                        {
                            CreateWordField (Arg0, 0x09, IRQM)
                            CreateByteField (Arg0, 0x0C, DMAM)
                            CreateWordField (Arg0, 0x02, IO11)
                            ENFG (CGLD (Arg1))
                            IOAL = (IO11 & 0xFF)
                            IOAH = (IO11 >> 0x08)
                            If (IRQM)
                            {
                                FindSetRightBit (IRQM, Local0)
                                INTR = (Local0 - One)
                            }
                            Else
                            {
                                INTR = Zero
                            }

                            If (DMAM)
                            {
                                FindSetRightBit (DMAM, Local0)
                                DMCH = (Local0 - One)
                            }
                            Else
                            {
                                DMCH = 0x04
                            }

                            EXFG ()
                            DCNT (Arg1, One)
                            Local2 = Arg1
                            If ((Local2 > Zero))
                            {
                                Local2 -= One
                            }
                        }
                    }

                    Method (DSR2, 2, NotSerialized)
                    {
                        CreateWordField (Arg0, 0x11, IRQE)
                        CreateByteField (Arg0, 0x14, DMAE)
                        CreateWordField (Arg0, 0x02, IO21)
                        CreateWordField (Arg0, 0x0A, IO31)
                        ENFG (CGLD (Arg1))
                        IOAL = (IO21 & 0xFF)
                        IOAH = (IO21 >> 0x08)
                        IOL2 = (IO31 & 0xFF)
                        IOH2 = (IO31 >> 0x08)
                        If (IRQE)
                        {
                            FindSetRightBit (IRQE, Local0)
                            INTR = (Local0 - One)
                        }
                        Else
                        {
                            INTR = Zero
                        }

                        If (DMAE)
                        {
                            FindSetRightBit (DMAE, Local0)
                            DMCH = (Local0 - One)
                        }
                        Else
                        {
                            DMCH = 0x04
                        }

                        EXFG ()
                        DCNT (Arg1, One)
                        Local2 = Arg1
                        If ((Local2 > Zero))
                        {
                            Local2 -= One
                        }
                    }

                    Method (DSR3, 2, NotSerialized)
                    {
                        CreateWordField (Arg0, 0x02, IO41)
                        CreateWordField (Arg0, 0x09, IRQT)
                        CreateByteField (Arg0, 0x0B, IRQS)
                        CreateByteField (Arg0, 0x0D, DMAT)
                        ENFG (CGLD (Arg1))
                        IOAL = (IO41 & 0xFF)
                        IOAH = (IO41 >> 0x08)
                        If (IRQT)
                        {
                            FindSetRightBit (IRQT, Local0)
                            INTR = (Local0 - One)
                        }
                        Else
                        {
                            INTR = Zero
                        }

                        If (DMAT)
                        {
                            FindSetRightBit (DMAT, Local0)
                            DMCH = (Local0 - One)
                        }
                        Else
                        {
                            DMCH = 0x04
                        }

                        EXFG ()
                        DCNT (Arg1, One)
                        Local2 = Arg1
                        If ((Local2 > Zero))
                        {
                            Local2 -= One
                        }
                    }

                    Name (PMFG, Zero)
                    Method (SIOS, 1, NotSerialized)
                    {
                        Debug = "SIOS"
                        If ((0x05 != Arg0))
                        {
                            ENFG (0x0A)
                            If ((Arg0 == One))
                            {
                                OPT6 = Zero
                                OPT7 = Zero
                                If (KBFG)
                                {
                                    OPT6 |= 0x10
                                }
                                Else
                                {
                                    OPT6 &= 0xEF
                                }

                                If (MSFG)
                                {
                                    OPT6 |= 0x20
                                }
                                Else
                                {
                                    OPT6 &= 0xDF
                                }

                                OPT1 = 0xFF
                                OPT3 = 0xFF
                                OPT4 = 0xFF
                                Local0 = (One | OPT2) /* \_SB_.PCI0.SBRG.SIO1.OPT2 */
                                OPT2 = Local0
                            }

                            If ((Arg0 >= 0x03))
                            {
                                RGE0 &= 0x9F
                                Local0 = RGE3 /* \_SB_.PCI0.SBRG.SIO1.RGE3 */
                                Sleep (0xC8)
                                If (KBFG)
                                {
                                    RGE0 |= 0x41
                                }
                                Else
                                {
                                    RGE0 &= 0xBE
                                }

                                If (MSFG)
                                {
                                    RGE6 &= 0x7F
                                    RGE0 |= 0x22
                                }
                                Else
                                {
                                    RGE0 &= 0xDD
                                }
                            }

                            EXFG ()
                        }
                    }

                    Method (SIOW, 1, NotSerialized)
                    {
                        Debug = "SIOW"
                        ENFG (0x0A)
                        OPT3 = 0xFF
                        OPT6 &= 0xCF
                        OPT2 &= 0xFE
                        RGE0 &= 0xBE
                        RGE0 &= 0xDD
                        EXFG ()
                    }

                    Method (SIOH, 0, NotSerialized)
                    {
                        If ((PMFG & 0x08)){}
                        If ((PMFG & 0x10)){}
                    }
                }

                Device (UAR1)
                {
                    Name (_HID, EisaId ("PNP0501") /* 16550A-compatible COM Serial Port */)  // _HID: Hardware ID
                    Name (_UID, Zero)  // _UID: Unique ID
                    Name (LDN, 0x02)
                    Method (_STA, 0, NotSerialized)  // _STA: Status
                    {
                        Return (^^SIO1.DSTA (Zero))
                    }

                    Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
                    {
                        ^^SIO1.DCNT (Zero, Zero)
                    }

                    Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
                    {
                        Return (^^SIO1.DCRS (Zero, Zero))
                    }

                    Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
                    {
                        ^^SIO1.DSRS (Arg0, Zero)
                    }

                    Name (_DDN, "COM1")  // _DDN: DOS Device Name
                    Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
                    {
                        StartDependentFn (0x00, 0x00)
                        {
                            IO (Decode16,
                                0x03F8,             // Range Minimum
                                0x03F8,             // Range Maximum
                                0x01,               // Alignment
                                0x08,               // Length
                                )
                            IRQ (Edge, ActiveLow, Shared, )
                                {4}
                            DMA (Compatibility, NotBusMaster, Transfer8, )
                                {}
                        }
                        StartDependentFnNoPri ()
                        {
                            IO (Decode16,
                                0x03F8,             // Range Minimum
                                0x03F8,             // Range Maximum
                                0x01,               // Alignment
                                0x08,               // Length
                                )
                            IRQ (Edge, ActiveLow, Shared, )
                                {4}
                            DMA (Compatibility, NotBusMaster, Transfer8, )
                                {}
                        }
                        StartDependentFnNoPri ()
                        {
                            IO (Decode16,
                                0x02F8,             // Range Minimum
                                0x02F8,             // Range Maximum
                                0x01,               // Alignment
                                0x08,               // Length
                                )
                            IRQ (Edge, ActiveLow, Shared, )
                                {3}
                            DMA (Compatibility, NotBusMaster, Transfer8, )
                                {}
                        }
                        StartDependentFnNoPri ()
                        {
                            IO (Decode16,
                                0x03E8,             // Range Minimum
                                0x03E8,             // Range Maximum
                                0x01,               // Alignment
                                0x08,               // Length
                                )
                            IRQ (Edge, ActiveLow, Shared, )
                                {4}
                            DMA (Compatibility, NotBusMaster, Transfer8, )
                                {}
                        }
                        StartDependentFnNoPri ()
                        {
                            IO (Decode16,
                                0x02E8,             // Range Minimum
                                0x02E8,             // Range Maximum
                                0x01,               // Alignment
                                0x08,               // Length
                                )
                            IRQ (Edge, ActiveLow, Shared, )
                                {3}
                            DMA (Compatibility, NotBusMaster, Transfer8, )
                                {}
                        }
                        EndDependentFn ()
                    })
                }

                Device (HHMD)
                {
                    Name (_HID, EisaId ("PNP0C08") /* ACPI Core Hardware */)  // _HID: Hardware ID
                    Name (_UID, Zero)  // _UID: Unique ID
                    Name (LDN, 0x0B)
                    Method (_STA, 0, NotSerialized)  // _STA: Status
                    {
                        Return (Zero)
                    }
                }

                Device (SACP)
                {
                    Name (_HID, EisaId ("PNP0C08") /* ACPI Core Hardware */)  // _HID: Hardware ID
                    Name (_UID, 0x03)  // _UID: Unique ID
                    Name (LDN, 0x0A)
                    Method (_STA, 0, NotSerialized)  // _STA: Status
                    {
                        Return (Zero)
                    }
                }

                Device (SP80)
                {
                    Name (_HID, EisaId ("PNP0C08") /* ACPI Core Hardware */)  // _HID: Hardware ID
                    Name (_UID, 0x04)  // _UID: Unique ID
                    Name (LDN, 0x14)
                    Method (_STA, 0, NotSerialized)  // _STA: Status
                    {
                        Return (Zero)
                    }
                }

                Device (SFED)
                {
                    Name (_HID, EisaId ("PNP0C08") /* ACPI Core Hardware */)  // _HID: Hardware ID
                    Name (_UID, 0x05)  // _UID: Unique ID
                    Name (LDN, 0x15)
                    Method (_STA, 0, NotSerialized)  // _STA: Status
                    {
                        Return (Zero)
                    }
                }

                Device (DSLP)
                {
                    Name (_HID, EisaId ("PNP0C08") /* ACPI Core Hardware */)  // _HID: Hardware ID
                    Name (_UID, 0x06)  // _UID: Unique ID
                    Name (LDN, 0x16)
                    Method (_STA, 0, NotSerialized)  // _STA: Status
                    {
                        Return (Zero)
                    }
                }
            }

            Device (SDIO)
            {
                Name (_ADR, 0x00140007)  // _ADR: Address
            }

            Device (GP18)
            {
                Name (_ADR, 0x00080002)  // _ADR: Address
                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (PICM)
                    {
                        Return (AG3B) /* \_SB_.AG3B */
                    }

                    Return (PG3B) /* \_SB_.PG3B */
                }

                Device (D02E)
                {
                    Name (_ADR, 0xFF)  // _ADR: Address
                }
            }

            Device (GP19)
            {
                Name (_ADR, 0x00080003)  // _ADR: Address
                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (PICM)
                    {
                        Return (AG3C) /* \_SB_.AG3C */
                    }

                    Return (PG3C) /* \_SB_.PG3C */
                }

                Device (XHC2)
                {
                    Name (_ADR, Zero)  // _ADR: Address
                }
            }

            Device (GPP0)
            {
                Name (_ADR, 0x00010001)  // _ADR: Address
                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (PICM)
                    {
                        Return (AG3E) /* \_SB_.AG3E */
                    }

                    Return (PG3E) /* \_SB_.PG3E */
                }

                Device (D004)
                {
                    Name (_ADR, 0xFF)  // _ADR: Address
                }
            }

            Device (GPP1)
            {
                Name (_ADR, 0x00010002)  // _ADR: Address
                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (PICM)
                    {
                        Return (AG3F) /* \_SB_.AG3F */
                    }

                    Return (PG3F) /* \_SB_.PG3F */
                }

                Device (D005)
                {
                    Name (_ADR, 0xFF)  // _ADR: Address
                }
            }

            Device (GPP2)
            {
                Name (_ADR, 0x00010003)  // _ADR: Address
                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (PICM)
                    {
                        Return (AG40) /* \_SB_.AG40 */
                    }

                    Return (PG40) /* \_SB_.PG40 */
                }

                Device (D006)
                {
                    Name (_ADR, 0xFF)  // _ADR: Address
                }
            }

            Device (GPP7)
            {
                Name (_ADR, 0x00020001)  // _ADR: Address
                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (PICM)
                    {
                        Return (AG41) /* \_SB_.AG41 */
                    }

                    Return (PG41) /* \_SB_.PG41 */
                }

                Device (D010)
                {
                    Name (_ADR, 0xFF)  // _ADR: Address
                }
            }

            Device (GPP8)
            {
                Name (_ADR, 0x00020002)  // _ADR: Address
                Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
                {
                    If (PICM)
                    {
                        Return (AG42) /* \_SB_.AG42 */
                    }

                    Return (PG42) /* \_SB_.PG42 */
                }

                Device (D011)
                {
                    Name (_ADR, 0xFF)  // _ADR: Address
                }
            }
        }
    }

    Scope (_GPE)
    {
        Method (_L0F, 0, NotSerialized)  // _Lxx: Level-Triggered GPE, xx=0x00-0xFF
        {
            Notify (\_SB.PCI0.GPP3, 0x02) // Device Wake
            Notify (\_SB.PWRB, 0x02) // Device Wake
        }
    }

    Scope (_SB)
    {
        Device (PWRB)
        {
            Name (_HID, EisaId ("PNP0C0C") /* Power Button Device */)  // _HID: Hardware ID
            Name (_UID, 0xAA)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
        }
    }

    Name (_S0, Package (0x04)  // _S0_: S0 System State
    {
        Zero, 
        Zero, 
        Zero, 
        Zero
    })
    Name (_S3, Package (0x04)  // _S3_: S3 System State
    {
        0x03, 
        Zero, 
        Zero, 
        Zero
    })
    Name (_S4, Package (0x04)  // _S4_: S4 System State
    {
        0x04, 
        Zero, 
        Zero, 
        Zero
    })
    Name (_S5, Package (0x04)  // _S5_: S5 System State
    {
        0x05, 
        Zero, 
        Zero, 
        Zero
    })
    Method (_PTS, 1, NotSerialized)  // _PTS: Prepare To Sleep
    {
        If (Arg0)
        {
            \_SB.PCI0.SBRG.EPTS (Arg0)
            \_SB.TPM.TPTS (Arg0)
            MPTS (Arg0)
            SPTS (Arg0)
            \_SB.PCI0.SBRG.SIO1.SIOS (Arg0)
            \_SB.PCI0.GPTS (Arg0)
            \_SB.PCI0.NPTS (Arg0)
        }
    }

    Method (_WAK, 1, NotSerialized)  // _WAK: Wake
    {
        DBG8 = (Arg0 << 0x04)
        \_SB.PCI0.NWAK (Arg0)
        \_SB.PCI0.GWAK (Arg0)
        \_SB.PCI0.SBRG.SIO1.SIOW (Arg0)
        DBG8 = (Arg0 << 0x04)
        SWAK (Arg0)
        MWAK (Arg0)
        \_SB.PCI0.SBRG.EWAK (Arg0)
        \_SB.PCI0.SBRG.EC0.DOSW (Arg0)
        Return (WAKP) /* \WAKP */
    }

    Scope (_SB)
    {
        OperationRegion (PIRQ, SystemIO, 0x0C00, 0x02)
        Field (PIRQ, ByteAcc, NoLock, Preserve)
        {
            PIDX,   8, 
            PDAT,   8
        }

        IndexField (PIDX, PDAT, ByteAcc, NoLock, Preserve)
        {
            PIRA,   8, 
            PIRB,   8, 
            PIRC,   8, 
            PIRD,   8, 
            PIRE,   8, 
            PIRF,   8, 
            PIRG,   8, 
            PIRH,   8, 
            Offset (0x0C), 
            SIRA,   8, 
            SIRB,   8, 
            SIRC,   8, 
            SIRD,   8, 
            PIRS,   8, 
            Offset (0x13), 
            HDAD,   8, 
            Offset (0x17), 
            SDCL,   8, 
            Offset (0x1A), 
            SDIO,   8, 
            Offset (0x30), 
            USB1,   8, 
            Offset (0x34), 
            USB3,   8, 
            Offset (0x41), 
            SATA,   8, 
            Offset (0x62), 
            GIOC,   8, 
            Offset (0x70), 
            I2C0,   8, 
            I2C1,   8, 
            I2C2,   8, 
            I2C3,   8, 
            URT0,   8, 
            URT1,   8, 
            Offset (0x80), 
            AIRA,   8, 
            AIRB,   8, 
            AIRC,   8, 
            AIRD,   8, 
            AIRE,   8, 
            AIRF,   8, 
            AIRG,   8, 
            AIRH,   8
        }

        OperationRegion (KBDD, SystemIO, 0x64, One)
        Field (KBDD, ByteAcc, NoLock, Preserve)
        {
            PD64,   8
        }

        Method (DSPI, 0, NotSerialized)
        {
            INTA (0x1F)
            INTB (0x1F)
            INTC (0x1F)
            INTD (0x1F)
            Local1 = PD64 /* \_SB_.PD64 */
            PIRE = 0x1F
            PIRF = 0x1F
            PIRG = 0x1F
            PIRH = 0x1F
            Local1 = PD64 /* \_SB_.PD64 */
            AIRA = 0x10
            AIRB = 0x11
            AIRC = 0x12
            AIRD = 0x13
            AIRE = 0x14
            AIRF = 0x15
            AIRG = 0x16
            AIRH = 0x17
        }

        Method (INTA, 1, NotSerialized)
        {
            PIRA = Arg0
            HDAD = Arg0
        }

        Method (INTB, 1, NotSerialized)
        {
            PIRB = Arg0
        }

        Method (INTC, 1, NotSerialized)
        {
            PIRC = Arg0
            USB1 = Arg0
            USB3 = Arg0
        }

        Method (INTD, 1, NotSerialized)
        {
            PIRD = Arg0
            SATA = Arg0
        }

        Name (BUFA, ResourceTemplate ()
        {
            IRQ (Level, ActiveLow, Shared, )
                {15}
        })
        Name (IPRA, ResourceTemplate ()
        {
            IRQ (Level, ActiveLow, Shared, )
                {5,10,11}
        })
        Name (IPRB, ResourceTemplate ()
        {
            IRQ (Level, ActiveLow, Shared, )
                {5,10,11}
        })
        Name (IPRC, ResourceTemplate ()
        {
            IRQ (Level, ActiveLow, Shared, )
                {5,10,11}
        })
        Name (IPRD, ResourceTemplate ()
        {
            IRQ (Level, ActiveLow, Shared, )
                {5,10,11}
        })
        Device (LNKA)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (PIRA)
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (0x09)
                }
            }

            Method (_PRS, 0, NotSerialized)  // _PRS: Possible Resource Settings
            {
                Return (PRSA) /* \_SB_.PRSA */
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                INTA (0x1F)
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                CreateWordField (BUFA, One, IRQX)
                IRQX = (One << PIRA) /* \_SB_.PIRA */
                Return (BUFA) /* \_SB_.BUFA */
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateWordField (Arg0, One, IRA)
                FindSetRightBit (IRA, Local0)
                Local0--
                INTA (Local0)
            }
        }

        Device (LNKB)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (PIRB)
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (0x09)
                }
            }

            Method (_PRS, 0, NotSerialized)  // _PRS: Possible Resource Settings
            {
                Return (PRSB) /* \_SB_.PRSB */
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                INTB (0x1F)
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                CreateWordField (BUFA, One, IRQX)
                IRQX = (One << PIRB) /* \_SB_.PIRB */
                Return (BUFA) /* \_SB_.BUFA */
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateWordField (Arg0, One, IRA)
                FindSetRightBit (IRA, Local0)
                Local0--
                INTB (Local0)
            }
        }

        Device (LNKC)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (PIRC)
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (0x09)
                }
            }

            Method (_PRS, 0, NotSerialized)  // _PRS: Possible Resource Settings
            {
                Return (PRSC) /* \_SB_.PRSC */
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                INTC (0x1F)
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                CreateWordField (BUFA, One, IRQX)
                IRQX = (One << PIRC) /* \_SB_.PIRC */
                Return (BUFA) /* \_SB_.BUFA */
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateWordField (Arg0, One, IRA)
                FindSetRightBit (IRA, Local0)
                Local0--
                INTC (Local0)
            }
        }

        Device (LNKD)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (PIRD)
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (0x09)
                }
            }

            Method (_PRS, 0, NotSerialized)  // _PRS: Possible Resource Settings
            {
                Return (PRSD) /* \_SB_.PRSD */
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                INTD (0x1F)
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                CreateWordField (BUFA, One, IRQX)
                IRQX = (One << PIRD) /* \_SB_.PIRD */
                Return (BUFA) /* \_SB_.BUFA */
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateWordField (Arg0, One, IRA)
                FindSetRightBit (IRA, Local0)
                Local0--
                INTD (Local0)
            }
        }

        Device (LNKE)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x05)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (PIRE)
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (0x09)
                }
            }

            Method (_PRS, 0, NotSerialized)  // _PRS: Possible Resource Settings
            {
                Return (PRSE) /* \_SB_.PRSE */
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                PIRE = 0x1F
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                CreateWordField (BUFA, One, IRQX)
                IRQX = (One << PIRE) /* \_SB_.PIRE */
                Return (BUFA) /* \_SB_.BUFA */
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateWordField (Arg0, One, IRA)
                FindSetRightBit (PIRE, Local0)
                Local0--
                PIRE = Local0
            }
        }

        Device (LNKF)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x06)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (PIRF)
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (0x09)
                }
            }

            Method (_PRS, 0, NotSerialized)  // _PRS: Possible Resource Settings
            {
                Return (PRSF) /* \_SB_.PRSF */
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                PIRF = 0x1F
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                CreateWordField (BUFA, One, IRQX)
                IRQX = (One << PIRF) /* \_SB_.PIRF */
                Return (BUFA) /* \_SB_.BUFA */
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateWordField (Arg0, One, IRA)
                FindSetRightBit (IRA, Local0)
                Local0--
                PIRF = Local0
            }
        }

        Device (LNKG)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x07)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (PIRG)
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (0x09)
                }
            }

            Method (_PRS, 0, NotSerialized)  // _PRS: Possible Resource Settings
            {
                Return (PRSG) /* \_SB_.PRSG */
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                PIRG = 0x1F
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                CreateWordField (BUFA, One, IRQX)
                IRQX = (One << PIRG) /* \_SB_.PIRG */
                Return (BUFA) /* \_SB_.BUFA */
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateWordField (Arg0, One, IRA)
                FindSetRightBit (IRA, Local0)
                Local0--
                PIRG = Local0
            }
        }

        Device (LNKH)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x08)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (PIRH)
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (0x09)
                }
            }

            Method (_PRS, 0, NotSerialized)  // _PRS: Possible Resource Settings
            {
                Return (PRSH) /* \_SB_.PRSH */
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                PIRH = 0x1F
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                CreateWordField (BUFA, One, IRQX)
                IRQX = (One << PIRH) /* \_SB_.PIRH */
                Return (BUFA) /* \_SB_.BUFA */
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateWordField (Arg0, One, IRA)
                FindSetRightBit (IRA, Local0)
                Local0--
                PIRH = Local0
            }
        }
    }

    Device (HPET)
    {
        Name (_HID, EisaId ("PNP0103") /* HPET System Timer */)  // _HID: Hardware ID
        Method (_STA, 0, NotSerialized)  // _STA: Status
        {
            If ((HPEN == One))
            {
                If ((OSVR >= 0x0C))
                {
                    Return (0x0F)
                }

                HPEN = Zero
                Return (One)
            }

            Return (One)
        }

        Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
        {
            Name (BUF0, ResourceTemplate ()
            {
                IRQNoFlags ()
                    {0}
                IRQNoFlags ()
                    {8}
                Memory32Fixed (ReadOnly,
                    0xFED00000,         // Address Base
                    0x00000400,         // Address Length
                    )
            })
            Return (BUF0) /* \HPET._CRS.BUF0 */
        }
    }

    Name (OSTB, Ones)
    Name (TPOS, Zero)
    Name (OSSP, Zero)
    Method (SEQL, 2, Serialized)
    {
        Local0 = SizeOf (Arg0)
        Local1 = SizeOf (Arg1)
        If ((Local0 != Local1))
        {
            Return (Zero)
        }

        Name (BUF0, Buffer (Local0){})
        BUF0 = Arg0
        Name (BUF1, Buffer (Local0){})
        BUF1 = Arg1
        Local2 = Zero
        While ((Local2 < Local0))
        {
            Local3 = DerefOf (BUF0 [Local2])
            Local4 = DerefOf (BUF1 [Local2])
            If ((Local3 != Local4))
            {
                Return (Zero)
            }

            Local2++
        }

        Return (One)
    }

    Method (OSTP, 0, NotSerialized)
    {
        If ((OSTB == Ones))
        {
            If (CondRefOf (\_OSI, Local0))
            {
                OSTB = Zero
                TPOS = Zero
                If (_OSI ("Windows 2001"))
                {
                    OSTB = 0x08
                    TPOS = 0x08
                }

                If (_OSI ("Windows 2001.1"))
                {
                    OSTB = 0x20
                    TPOS = 0x20
                }

                If (_OSI ("Windows 2001 SP1"))
                {
                    OSTB = 0x10
                    TPOS = 0x10
                }

                If (_OSI ("Windows 2001 SP2"))
                {
                    OSTB = 0x11
                    TPOS = 0x11
                }

                If (_OSI ("Windows 2001 SP3"))
                {
                    OSTB = 0x12
                    TPOS = 0x12
                }

                If (_OSI ("Windows 2006"))
                {
                    OSTB = 0x40
                    TPOS = 0x40
                }

                If (_OSI ("Windows 2006 SP1"))
                {
                    OSTB = 0x41
                    TPOS = 0x41
                    OSSP = One
                }

                If (_OSI ("Windows 2009"))
                {
                    OSSP = One
                    OSTB = 0x50
                    TPOS = 0x50
                }

                If (_OSI ("Windows 2012"))
                {
                    OSSP = One
                    OSTB = 0x60
                    TPOS = 0x60
                }

                If (_OSI ("Windows 2013"))
                {
                    OSSP = One
                    OSTB = 0x61
                    TPOS = 0x61
                }

                If (_OSI ("Windows 2015"))
                {
                    OSSP = One
                    OSTB = 0x70
                    TPOS = 0x70
                }
            }
            ElseIf (CondRefOf (\_OS, Local0))
            {
                If (SEQL (_OS, "Microsoft Windows"))
                {
                    OSTB = One
                    TPOS = One
                }
                ElseIf (SEQL (_OS, "Microsoft WindowsME: Millennium Edition"))
                {
                    OSTB = 0x02
                    TPOS = 0x02
                }
                ElseIf (SEQL (_OS, "Microsoft Windows NT"))
                {
                    OSTB = 0x04
                    TPOS = 0x04
                }
                Else
                {
                    OSTB = Zero
                    TPOS = Zero
                }
            }
            Else
            {
                OSTB = Zero
                TPOS = Zero
            }
        }

        Return (OSTB) /* \OSTB */
    }

    Scope (_SB.PCI0)
    {
        Method (_INI, 0, NotSerialized)  // _INI: Initialize
        {
            If ((PICM != Zero))
            {
                DSPI ()
                NAPE ()
            }

            OSTP ()
            OSFL ()
        }
    }

    Device (_SB.TPM)
    {
        Name (TMRQ, 0xFFFFFFFF)
        Name (TLVL, 0xFFFFFFFF)
        Name (ITRV, 0xFFFFFFFF)
        Name (ILVV, 0xFFFFFFFF)
        Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
        {
            If (TCMF)
            {
                Return (0x01013469)
            }
            ElseIf ((TTDP == Zero))
            {
                Return (0x310CD041)
            }
            Else
            {
                Return ("MSFT0101")
            }
        }

        OperationRegion (TMMB, SystemMemory, 0xFED40000, 0x5000)
        Field (TMMB, ByteAcc, Lock, Preserve)
        {
            ACC0,   8, 
            Offset (0x08), 
            INTE,   32, 
            INTV,   8, 
            Offset (0x10), 
            INTS,   32, 
            INTF,   32, 
            TSTS,   32, 
            Offset (0x24), 
            FIFO,   32, 
            Offset (0x30), 
            IDTF,   32, 
            Offset (0x4C), 
            SCMD,   32
        }

        Method (_STR, 0, NotSerialized)  // _STR: Description String
        {
            If ((TTDP == Zero))
            {
                Return (Unicode ("TPM 1.2 Device"))
            }
            Else
            {
                Return (Unicode ("TPM 2.0 Device"))
            }
        }

        Name (_UID, One)  // _UID: Unique ID
        Name (CRST, ResourceTemplate ()
        {
            Memory32Fixed (ReadOnly,
                0x00000000,         // Address Base
                0x00001000,         // Address Length
                _Y26)
            Memory32Fixed (ReadOnly,
                0xFED70000,         // Address Base
                0x00001000,         // Address Length
                _Y27)
        })
        Name (CRSD, ResourceTemplate ()
        {
            Memory32Fixed (ReadWrite,
                0xFED40000,         // Address Base
                0x00005000,         // Address Length
                _Y28)
        })
        Name (CRID, ResourceTemplate ()
        {
            Memory32Fixed (ReadWrite,
                0xFED40000,         // Address Base
                0x00005000,         // Address Length
                _Y29)
        })
        Name (CREI, ResourceTemplate ()
        {
            Memory32Fixed (ReadWrite,
                0xFED40000,         // Address Base
                0x00005000,         // Address Length
                )
            GpioInt (Level, ActiveLow, ExclusiveAndWake, PullNone, 0x0000,
                "\\_SB.GPIO", 0x00, ResourceConsumer, _Y2A,
                )
                {   // Pin list
                    0x0000
                }
        })
        Name (CRSI, ResourceTemplate ()
        {
            Memory32Fixed (ReadWrite,
                0x00000000,         // Address Base
                0x00000000,         // Address Length
                _Y2B)
        })
        Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
        {
            If ((AMDT == One))
            {
                CreateDWordField (CRST, \_SB.TPM._Y26._BAS, MTFB)  // _BAS: Base Address
                CreateDWordField (CRST, \_SB.TPM._Y26._LEN, LTFB)  // _LEN: Length
                MTFB = TPMB /* \TPMB */
                LTFB = TPBS /* \TPBS */
                CreateDWordField (CRST, \_SB.TPM._Y27._BAS, MTFC)  // _BAS: Base Address
                CreateDWordField (CRST, \_SB.TPM._Y27._LEN, LTFC)  // _LEN: Length
                MTFC = TPMC /* \TPMC */
                LTFC = TPCS /* \TPCS */
                Return (CRST) /* \_SB_.TPM_.CRST */
            }
            Else
            {
                If ((DTPT == One))
                {
                    CreateDWordField (CRSD, \_SB.TPM._Y28._BAS, MTFE)  // _BAS: Base Address
                    CreateDWordField (CRSD, \_SB.TPM._Y28._LEN, LTFE)  // _LEN: Length
                    MTFE = 0xFED40000
                    LTFE = 0x5000
                    Return (CRSD) /* \_SB_.TPM_.CRSD */
                }
                ElseIf ((TTPF == One))
                {
                    If (((TMRQ == Zero) && (TMRQ != 0xFFFFFFFF)))
                    {
                        CreateDWordField (CRID, \_SB.TPM._Y29._BAS, MTFD)  // _BAS: Base Address
                        CreateDWordField (CRID, \_SB.TPM._Y29._LEN, LTFD)  // _LEN: Length
                        MTFD = 0xFED40000
                        LTFD = 0x5000
                        Return (CRID) /* \_SB_.TPM_.CRID */
                    }
                    Else
                    {
                        CreateWordField (CREI, 0x23, LIRQ)
                        CreateBitField (CREI, \_SB.TPM._Y2A._POL, LLVL)  // _POL: Polarity
                        LIRQ = TMRQ /* \_SB_.TPM_.TMRQ */
                        LLVL = TLVL /* \_SB_.TPM_.TLVL */
                        Return (CREI) /* \_SB_.TPM_.CREI */
                    }
                }
                ElseIf ((TTPF == Zero))
                {
                    If ((AMDT == 0x02))
                    {
                        CreateDWordField (CRSI, \_SB.TPM._Y2B._BAS, HSPF)  // _BAS: Base Address
                        CreateDWordField (CRSI, \_SB.TPM._Y2B._LEN, HSPL)  // _LEN: Length
                        HSPF = HSPB /* \HSPB */
                        HSPL = HSPS /* \HSPS */
                        Return (CRSI) /* \_SB_.TPM_.CRSI */
                    }

                    CreateDWordField (CRST, \_SB.TPM._Y27._BAS, MTFF)  // _BAS: Base Address
                    MTFF = FTPM /* \FTPM */
                    Return (CRST) /* \_SB_.TPM_.CRST */
                }

                MTFE = Zero
                LTFE = Zero
                Return (CRID) /* \_SB_.TPM_.CRID */
            }

            Return (CRID) /* \_SB_.TPM_.CRID */
        }

        Method (_SRS, 1, Serialized)  // _SRS: Set Resource Settings
        {
            If (((TMRQ != Zero) && (TMRQ != 0xFFFFFFFF)))
            {
                If ((AMDT == 0x02)){}
                Else
                {
                    CreateWordField (Arg0, 0x23, IRQ0)
                    CreateWordField (CREI, 0x23, LIRQ)
                    LIRQ = IRQ0 /* \_SB_.TPM_._SRS.IRQ0 */
                    TMRQ = IRQ0 /* \_SB_.TPM_._SRS.IRQ0 */
                    CreateBitField (Arg0, 0x98, ITRG)
                    CreateBitField (CREI, \_SB.TPM._Y2A._MOD, LTRG)  // _MOD: Mode
                    LTRG = ITRG /* \_SB_.TPM_._SRS.ITRG */
                    ITRV = ITRG /* \_SB_.TPM_._SRS.ITRG */
                    CreateBitField (Arg0, 0x99, ILVL)
                    CreateBitField (CREI, \_SB.TPM._Y2A._POL, LLVL)  // _POL: Polarity
                    LLVL = ILVL /* \_SB_.TPM_._SRS.ILVL */
                    ILVV = ILVL /* \_SB_.TPM_._SRS.ILVL */
                }

                If ((((IDTF & 0x0F) == Zero) || ((IDTF & 0x0F
                    ) == 0x0F)))
                {
                    If ((IRQ0 < 0x10))
                    {
                        INTV = (IRQ0 & 0x0F)
                    }

                    If ((ITRV == One))
                    {
                        INTE |= 0x10
                    }
                    Else
                    {
                        INTE &= 0xFFFFFFEF
                    }

                    If ((ILVV == Zero))
                    {
                        INTE |= 0x08
                    }
                    Else
                    {
                        INTE &= 0xFFFFFFF7
                    }
                }
            }
        }

        OperationRegion (CRBD, SystemMemory, TPMM, 0x48)
        Field (CRBD, AnyAcc, NoLock, Preserve)
        {
            Offset (0x04), 
            HERR,   32, 
            Offset (0x40), 
            HCMD,   32, 
            Offset (0x44), 
            HSTS,   32
        }

        Method (_STA, 0, NotSerialized)  // _STA: Status
        {
            If ((TTDP == Zero))
            {
                If (TPMF)
                {
                    Return (0x0F)
                }

                Return (Zero)
            }
            ElseIf ((TTDP == One))
            {
                If (TPMF)
                {
                    Return (0x0F)
                }

                Return (Zero)
            }

            Return (Zero)
        }

        Method (STRT, 3, Serialized)
        {
            OperationRegion (TPMR, SystemMemory, FTPM, 0x1000)
            Field (TPMR, AnyAcc, NoLock, Preserve)
            {
                Offset (0x04), 
                FERR,   32, 
                Offset (0x0C), 
                BEGN,   32
            }

            Name (TIMR, Zero)
            If ((ToInteger (Arg0) != Zero)){}
            Switch (ToInteger (Arg1))
            {
                Case (Zero)
                {
                    Return (Buffer (One)
                    {
                         0x03                                             // .
                    })
                }
                Case (One)
                {
                    TIMR = Zero
                    If ((AMDT == One))
                    {
                        While (((BEGN == One) && (TIMR < 0x0200)))
                        {
                            If ((BEGN == One))
                            {
                                Sleep (One)
                                TIMR++
                            }
                        }
                    }
                    ElseIf ((((HSTS & 0x02) | (HSTS & One)
                        ) == 0x03))
                    {
                        HCMD = One
                    }
                    Else
                    {
                        FERR = One
                        BEGN = Zero
                    }

                    Return (Zero)
                }

            }

            Return (One)
        }

        Method (CRYF, 3, Serialized)
        {
            If ((ToInteger (Arg0) != One)){}
            Switch (ToInteger (Arg1))
            {
                Case (Zero)
                {
                    Return (Buffer (One)
                    {
                         0x03                                             // .
                    })
                }
                Case (One)
                {
                    Name (TPMV, Package (0x02)
                    {
                        One, 
                        Package (0x02)
                        {
                            One, 
                            0x20
                        }
                    })
                    If ((_STA () == Zero))
                    {
                        Return (Package (0x01)
                        {
                            Zero
                        })
                    }

                    Return (TPMV) /* \_SB_.TPM_.CRYF.TPMV */
                }

            }

            Return (Buffer (One)
            {
                 0x00                                             // .
            })
        }
    }

    Scope (_SB.TPM)
    {
        OperationRegion (TSMI, SystemIO, SMIA, 0x02)
        Field (TSMI, WordAcc, NoLock, Preserve)
        {
            SMI,    16
        }

        OperationRegion (ATNV, SystemMemory, PPIM, PPIL)
        Field (ATNV, AnyAcc, NoLock, Preserve)
        {
            RQST,   32, 
            RCNT,   32, 
            ERRO,   32, 
            FLAG,   32, 
            MISC,   32, 
            OPTN,   32, 
            SRSP,   32
        }

        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
        {
            If ((Arg0 == ToUUID ("3dddfaa6-361b-4eb4-a424-8d10089d1653") /* Physical Presence Interface */))
            {
                Switch (ToInteger (Arg2))
                {
                    Case (Zero)
                    {
                        Return (Buffer (0x02)
                        {
                             0xFF, 0x01                                       // ..
                        })
                    }
                    Case (One)
                    {
                        If ((PPIV == Zero))
                        {
                            Return ("1.2")
                        }
                        Else
                        {
                            Return ("1.3")
                        }
                    }
                    Case (0x02)
                    {
                        RQST = DerefOf (Arg3 [Zero])
                        SRSP = Zero
                        FLAG = 0x02
                        TMF1 = OFST /* \OFST */
                        SRSP = Zero
                        SMI = TMF1 /* \TMF1 */
                        Return (SRSP) /* \_SB_.TPM_.SRSP */
                    }
                    Case (0x03)
                    {
                        Name (PPI1, Package (0x02)
                        {
                            Zero, 
                            Zero
                        })
                        PPI1 [One] = RQST /* \_SB_.TPM_.RQST */
                        Return (PPI1) /* \_SB_.TPM_._DSM.PPI1 */
                    }
                    Case (0x04)
                    {
                        Return (TRST) /* \TRST */
                    }
                    Case (0x05)
                    {
                        Name (PPI2, Package (0x03)
                        {
                            Zero, 
                            Zero, 
                            Zero
                        })
                        SRSP = Zero
                        FLAG = 0x05
                        SMI = OFST /* \OFST */
                        PPI2 [One] = RCNT /* \_SB_.TPM_.RCNT */
                        PPI2 [0x02] = ERRO /* \_SB_.TPM_.ERRO */
                        Return (PPI2) /* \_SB_.TPM_._DSM.PPI2 */
                    }
                    Case (0x06)
                    {
                        Return (0x03)
                    }
                    Case (0x07)
                    {
                        RQST = DerefOf (Arg3 [Zero])
                        FLAG = 0x07
                        OPTN = Zero
                        If ((RQST == 0x17))
                        {
                            ToInteger (DerefOf (Arg3 [One]), OPTN) /* \_SB_.TPM_.OPTN */
                        }

                        TMF1 = OFST /* \OFST */
                        SRSP = Zero
                        SMI = TMF1 /* \TMF1 */
                        Return (SRSP) /* \_SB_.TPM_.SRSP */
                    }
                    Case (0x08)
                    {
                        RQST = DerefOf (Arg3 [Zero])
                        FLAG = 0x08
                        TMF1 = OFST /* \OFST */
                        SRSP = Zero
                        SMI = TMF1 /* \TMF1 */
                        Return (SRSP) /* \_SB_.TPM_.SRSP */
                    }
                    Default
                    {
                    }

                }
            }
            ElseIf ((Arg0 == ToUUID ("376054ed-cc13-4675-901c-4756d7f2d45d") /* Unknown UUID */))
            {
                Switch (ToInteger (Arg2))
                {
                    Case (Zero)
                    {
                        Return (Buffer (One)
                        {
                             0x03                                             // .
                        })
                    }
                    Case (One)
                    {
                        RQST = DerefOf (Arg3 [Zero])
                        FLAG = 0x09
                        TMF1 = OFST /* \OFST */
                        SRSP = Zero
                        SMI = TMF1 /* \TMF1 */
                        Return (SRSP) /* \_SB_.TPM_.SRSP */
                    }
                    Default
                    {
                    }

                }
            }

            If ((Arg0 == ToUUID ("cf8e16a5-c1e8-4e25-b712-4f54a96702c8") /* Unknown UUID */))
            {
                Return (CRYF (Arg1, Arg2, Arg3))
            }

            If ((Arg0 == ToUUID ("6bbf6cab-5463-4714-b7cd-f0203c0368d4") /* Unknown UUID */))
            {
                Return (STRT (Arg1, Arg2, Arg3))
            }

            Return (Buffer (One)
            {
                 0x00                                             // .
            })
        }

        Method (TPTS, 1, Serialized)
        {
            Switch (ToInteger (Arg0))
            {
                Case (0x04)
                {
                    RQST = Zero
                    FLAG = 0x09
                    SRSP = Zero
                    SMI = OFST /* \OFST */
                }
                Case (0x05)
                {
                    RQST = Zero
                    FLAG = 0x09
                    SRSP = Zero
                    SMI = OFST /* \OFST */
                }

            }

            Sleep (0x012C)
        }
    }

    Scope (_SB.PCI0.SBRG)
    {
        OperationRegion (DBGP, SystemIO, 0x80, 0x08)
        Field (DBGP, ByteAcc, NoLock, Preserve)
        {
            DP80,   8
        }

        OperationRegion (SMIP, SystemIO, 0xB2, 0x08)
        Field (SMIP, ByteAcc, NoLock, Preserve)
        {
            DPB2,   8
        }

        Method (IBFX, 0, Serialized)
        {
            OperationRegion (ECR1, SystemIO, 0x66, One)
            Field (ECR1, ByteAcc, Lock, Preserve)
            {
                ECOF,   1, 
                ECIE,   1, 
                Offset (0x01)
            }

            Local0 = 0x1000
            While ((Local0-- && ECIE))
            {
                Sleep (One)
            }
        }

        Method (OBFX, 0, Serialized)
        {
            OperationRegion (ECR1, SystemIO, 0x66, One)
            Field (ECR1, ByteAcc, Lock, Preserve)
            {
                ECOF,   1, 
                ECIE,   1, 
                Offset (0x01)
            }

            Local0 = 0x1000
            While (Local0--)
            {
                If (ECOF)
                {
                    Break
                }

                Sleep (One)
            }
        }

        Name (ECB1, Zero)
        Method (EPTS, 1, NotSerialized)
        {
        }

        Method (EWAK, 1, Serialized)
        {
            OperationRegion (ECR2, SystemIO, 0x66, One)
            Field (ECR2, ByteAcc, Lock, Preserve)
            {
                EC66,   8
            }

            OperationRegion (ECR3, SystemIO, 0x62, One)
            Field (ECR3, ByteAcc, Lock, Preserve)
            {
                EC62,   8
            }

            IBFX ()
            EC66 = 0x91
            IBFX ()
            EC62 = 0xFF
            IBFX ()
            EC62 = Zero
            IBFX ()
            EC66 = 0x90
            IBFX ()
            EC62 = 0xD2
            OBFX ()
            ECB1 = EC62 /* \_SB_.PCI0.SBRG.EWAK.EC62 */
            IBFX ()
            EC66 = 0x91
            IBFX ()
            EC62 = 0xD2
            IBFX ()
            EC62 = (0x10 | ECB1)
        }

        Device (EC0)
        {
            Name (_HID, EisaId ("PNP0C09") /* Embedded Controller Device */)  // _HID: Hardware ID
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                IO (Decode16,
                    0x0062,             // Range Minimum
                    0x0062,             // Range Maximum
                    0x00,               // Alignment
                    0x01,               // Length
                    )
                IO (Decode16,
                    0x0066,             // Range Minimum
                    0x0066,             // Range Maximum
                    0x00,               // Alignment
                    0x01,               // Length
                    )
            })
            Name (_GPE, 0x04)  // _GPE: General Purpose Events
            Name (REGC, Zero)
            Method (_REG, 2, NotSerialized)  // _REG: Region Availability
            {
                If ((Arg0 == 0x03))
                {
                    REGC = Arg1
                }
            }

            Method (_Q01, 0, NotSerialized)  // _Qxx: EC Query, xx=0x00-0xFF
            {
                \RMTW.AMWN (0xA0040001)
            }

            Method (_Q02, 0, NotSerialized)  // _Qxx: EC Query, xx=0x00-0xFF
            {
                \RMTW.AMWN (0xA0040002)
            }

            Method (_Q03, 0, NotSerialized)  // _Qxx: EC Query, xx=0x00-0xFF
            {
                \RMTW.AMWN (0xA0040003)
            }

            Method (_Q0B, 0, NotSerialized)  // _Qxx: EC Query, xx=0x00-0xFF
            {
                \RMTW.AMWN (0xA002000B)
            }

            Method (_Q0D, 0, NotSerialized)  // _Qxx: EC Query, xx=0x00-0xFF
            {
                \RMTW.AMWN (0xA0021000)
            }

            Method (_Q87, 0, NotSerialized)  // _Qxx: EC Query, xx=0x00-0xFF
            {
                \RMTW.AMWN (0xA0040087)
            }

            Method (_Q88, 0, NotSerialized)  // _Qxx: EC Query, xx=0x00-0xFF
            {
                \RMTW.AMWN (0xA0040088)
            }
        }
    }

    Scope (_SB)
    {
        Name (RAMB, 0x712C2018)
        OperationRegion (\RAMW, SystemMemory, RAMB, 0x00010000)
        Field (RAMW, ByteAcc, NoLock, Preserve)
        {
            PAR0,   32, 
            PAR1,   32, 
            PAR2,   32, 
            PINX,   32, 
            PADD,   2048
        }

        Mutex (MPAR, 0x00)
        Name (ARBF, Buffer (0x10){})
        CreateDWordField (ARBF, Zero, REAX)
        CreateDWordField (ARBF, 0x04, REBX)
        CreateDWordField (ARBF, 0x08, RECX)
        CreateDWordField (ARBF, 0x0C, REDX)
        OperationRegion (DEB0, SystemIO, 0x80, One)
        Field (DEB0, ByteAcc, NoLock, Preserve)
        {
            DB80,   8
        }

        OperationRegion (IOG2, SystemIO, SMIP, 0x02)
        Field (IOG2, ByteAcc, NoLock, Preserve)
        {
            SSCP,   8, 
            SSSP,   8
        }

        Method (ISMI, 1, Serialized)
        {
            SSCP = Arg0
        }

        Method (GMSR, 1, Serialized)
        {
            If ((Acquire (MPAR, 0xFFFF) == Zero))
            {
                PINX = 0x80000000
                PAR0 = Arg0
                ISMI (0x90)
                RECX = Arg0
                REAX = PAR1 /* \_SB_.PAR1 */
                REDX = PAR2 /* \_SB_.PAR2 */
                Release (MPAR)
                Return (ARBF) /* \_SB_.ARBF */
            }

            Return (Ones)
        }

        Method (SMSR, 1, Serialized)
        {
            If ((Acquire (MPAR, 0xFFFF) == Zero))
            {
                CreateDWordField (Arg0, Zero, AEAX)
                CreateDWordField (Arg0, 0x04, AEBX)
                CreateDWordField (Arg0, 0x08, AECX)
                CreateDWordField (Arg0, 0x0C, AEDX)
                PINX = 0x80000001
                PAR0 = AECX /* \_SB_.SMSR.AECX */
                PAR1 = AEAX /* \_SB_.SMSR.AEAX */
                PAR2 = AEDX /* \_SB_.SMSR.AEDX */
                ISMI (0x90)
                Release (MPAR)
            }

            Return (Ones)
        }

        Method (GCID, 1, Serialized)
        {
            If ((Acquire (MPAR, 0xFFFF) == Zero))
            {
                PINX = 0x80000002
                PAR0 = Arg0
                ISMI (0x90)
                REAX = PAR1 /* \_SB_.PAR1 */
                REDX = PAR2 /* \_SB_.PAR2 */
                Release (MPAR)
                Return (ARBF) /* \_SB_.ARBF */
            }

            Return (Ones)
        }

        Method (GPRE, 1, Serialized)
        {
            PAR0 = Arg0
            PINX = 0x80000005
            ISMI (0x90)
            Return (PAR0) /* \_SB_.PAR0 */
        }

        Method (GNVS, 1, Serialized)
        {
            PAR0 = Arg0
            PINX = 0x80000003
            ISMI (0x90)
            Return (PAR1) /* \_SB_.PAR1 */
        }

        Method (SNVS, 2, Serialized)
        {
            PAR0 = Arg0
            PAR1 = Arg1
            PINX = 0x80000004
            ISMI (0x90)
        }

        Method (SIRS, 0, Serialized)
        {
            PINX = 0x8000000A
            ISMI (0x90)
        }

        Method (SRDM, 0, Serialized)
        {
            PINX = 0x8000000B
            ISMI (0x90)
        }

        Method (SARM, 1, Serialized)
        {
            If (((Arg0 > 0x03) && (Arg0 < 0x06)))
            {
                ISMI (0x92)
            }
        }

        Method (GAMM, 0, Serialized)
        {
            ISMI (0x91)
        }

        Method (SAMM, 0, Serialized)
        {
            ISMI (0x92)
        }
    }

    Scope (\)
    {
        Device (ALCW)
        {
            Name (_HID, EisaId ("PNP0C14") /* Windows Management Instrumentation Device */)  // _HID: Hardware ID
            Name (_UID, "AsusLedControlWmi")  // _UID: Unique ID
            Name (_WDG, Buffer (0x28)
            {
                /* 0000 */  0x6E, 0x89, 0x6E, 0xD9, 0x11, 0xA0, 0xE4, 0x4A,  // n.n....J
                /* 0008 */  0x87, 0xDF, 0x8B, 0xEF, 0xE1, 0x9D, 0xB1, 0xCD,  // ........
                /* 0010 */  0x42, 0x43, 0x01, 0x02, 0x21, 0x12, 0x90, 0x05,  // BC..!...
                /* 0018 */  0x66, 0xD5, 0xD1, 0x11, 0xB2, 0xF0, 0x00, 0xA0,  // f.......
                /* 0020 */  0xC9, 0x06, 0x29, 0x10, 0x4D, 0x4F, 0x01, 0x00   // ..).MO..
            })
            Method (WMBC, 3, Serialized)
            {
                Switch (Arg1)
                {
                    Case (0x12345678)
                    {
                        Return (WDLC (Arg2))
                    }
                    Case (0xFFFFFFFF)
                    {
                        Return (Zero)
                    }
                    Default
                    {
                        Return (Zero)
                    }

                }

                Return (Zero)
            }

            Name (WQMO, Buffer (0x0238)
            {
                /* 0000 */  0x46, 0x4F, 0x4D, 0x42, 0x01, 0x00, 0x00, 0x00,  // FOMB....
                /* 0008 */  0x28, 0x02, 0x00, 0x00, 0xA4, 0x04, 0x00, 0x00,  // (.......
                /* 0010 */  0x44, 0x53, 0x00, 0x01, 0x1A, 0x7D, 0xDA, 0x54,  // DS...}.T
                /* 0018 */  0x28, 0x5C, 0x82, 0x00, 0x01, 0x06, 0x18, 0x42,  // (\.....B
                /* 0020 */  0x20, 0xE4, 0x02, 0x89, 0xC0, 0xA1, 0x21, 0x14,  //  .....!.
                /* 0028 */  0x48, 0x01, 0x0C, 0x86, 0xCB, 0x72, 0x20, 0xE4,  // H....r .
                /* 0030 */  0x82, 0x89, 0x09, 0x10, 0x01, 0x21, 0xAF, 0x02,  // .....!..
                /* 0038 */  0x6C, 0x0A, 0x30, 0x09, 0xA2, 0xFE, 0xFD, 0x21,  // l.0....!
                /* 0040 */  0x4A, 0x82, 0x43, 0x09, 0x81, 0x90, 0x44, 0x01,  // J.C...D.
                /* 0048 */  0xE6, 0x05, 0xE8, 0x16, 0x60, 0x58, 0x80, 0x6D,  // ....`X.m
                /* 0050 */  0x01, 0xA6, 0x05, 0x38, 0x86, 0xA4, 0xD2, 0xC0,  // ...8....
                /* 0058 */  0x29, 0x81, 0xA5, 0x40, 0x48, 0xA8, 0x00, 0xE5,  // )..@H...
                /* 0060 */  0x02, 0x7C, 0x0B, 0xD0, 0x8E, 0x28, 0xC9, 0x02,  // .|...(..
                /* 0068 */  0x2C, 0xC3, 0x88, 0xC0, 0xA3, 0x88, 0x6C, 0x34,  // ,.....l4
                /* 0070 */  0x4E, 0x50, 0x36, 0x34, 0x4A, 0x06, 0x84, 0x3C,  // NP64J..<
                /* 0078 */  0x0B, 0xB0, 0x0E, 0x4C, 0x08, 0xEC, 0x7E, 0x26,  // ...L..~&
                /* 0080 */  0x32, 0x27, 0x40, 0x9B, 0x00, 0x8B, 0x02, 0xC4,  // 2'@.....
                /* 0088 */  0x81, 0x50, 0x5B, 0x02, 0x0C, 0x0A, 0x10, 0x26,  // .P[....&
                /* 0090 */  0xC0, 0x18, 0x82, 0x50, 0xCE, 0x25, 0x4C, 0xA4,  // ...P.%L.
                /* 0098 */  0x18, 0x51, 0xE2, 0xF5, 0x86, 0x2A, 0x8D, 0x28,  // .Q...*.(
                /* 00A0 */  0x44, 0x21, 0x94, 0x50, 0x42, 0x44, 0x8C, 0x1C,  // D!.PBD..
                /* 00A8 */  0x2A, 0x4E, 0x90, 0x0E, 0x41, 0x64, 0x7F, 0x10,  // *N..Ad..
                /* 00B0 */  0x24, 0xDC, 0x82, 0x35, 0x54, 0x47, 0x1A, 0x0D,  // $..5TG..
                /* 00B8 */  0x6A, 0x78, 0x09, 0x0E, 0xD7, 0x43, 0x3D, 0xC7,  // jx...C=.
                /* 00C0 */  0xCE, 0x05, 0x48, 0x9F, 0xA4, 0x40, 0x0E, 0xF2,  // ..H..@..
                /* 00C8 */  0xDC, 0xEA, 0x1C, 0x27, 0x01, 0x49, 0x60, 0xAC,  // ...'.I`.
                /* 00D0 */  0x04, 0x1D, 0x0C, 0x1C, 0x8A, 0x6B, 0x40, 0xCD,  // .....k@.
                /* 00D8 */  0xF8, 0x78, 0x99, 0x20, 0x38, 0xD4, 0x10, 0x3D,  // .x. 8..=
                /* 00E0 */  0xD0, 0x70, 0x27, 0x70, 0x88, 0x0C, 0xD0, 0xB3,  // .p'p....
                /* 00E8 */  0x3B, 0x1A, 0xCC, 0x01, 0xC0, 0xB3, 0x3A, 0x99,  // ;.....:.
                /* 00F0 */  0xF7, 0x80, 0x52, 0x05, 0x98, 0x1D, 0xB3, 0xE6,  // ..R.....
                /* 00F8 */  0x96, 0xE0, 0x78, 0x0C, 0x7D, 0xBA, 0xE7, 0x73,  // ..x.}..s
                /* 0100 */  0xC2, 0x09, 0x2C, 0x7F, 0x10, 0xA8, 0x91, 0x19,  // ..,.....
                /* 0108 */  0xDA, 0x83, 0x3D, 0xAD, 0x98, 0x21, 0x0F, 0xFF,  // ..=..!..
                /* 0110 */  0xB0, 0x98, 0x58, 0x08, 0x7D, 0x10, 0x3C, 0x1E,  // ..X.}.<.
                /* 0118 */  0x78, 0xFF, 0xFF, 0xF1, 0x80, 0x47, 0xF1, 0x99,  // x....G..
                /* 0120 */  0x40, 0x08, 0xAF, 0x04, 0xB1, 0x3D, 0xA0, 0x04,  // @....=..
                /* 0128 */  0x45, 0x02, 0xA3, 0x07, 0x64, 0xBF, 0x02, 0x10,  // E...d...
                /* 0130 */  0x82, 0x97, 0x39, 0x22, 0x39, 0x45, 0xD0, 0x98,  // ..9"9E..
                /* 0138 */  0x3C, 0xB9, 0x57, 0x83, 0x10, 0x91, 0x62, 0x9F,  // <.W...b.
                /* 0140 */  0x4A, 0xB4, 0x03, 0x88, 0x7E, 0x82, 0x1E, 0x82,  // J...~...
                /* 0148 */  0x4F, 0x0A, 0x6C, 0x08, 0x58, 0x31, 0x43, 0x40,  // O.l.X1C@
                /* 0150 */  0x9D, 0x03, 0xE2, 0x1F, 0xD0, 0xE9, 0x1C, 0xC2,  // ........
                /* 0158 */  0x01, 0x45, 0x09, 0x7F, 0x44, 0x46, 0x37, 0xC2,  // .E..DF7.
                /* 0160 */  0x09, 0x94, 0x7B, 0x76, 0x20, 0x9A, 0xA7, 0xA4,  // ..{v ...
                /* 0168 */  0x79, 0x9C, 0xC2, 0xEB, 0x80, 0x09, 0x86, 0x3A,  // y......:
                /* 0170 */  0x1E, 0xE8, 0x7C, 0xE1, 0x40, 0x14, 0xB2, 0xB1,  // ..|.@...
                /* 0178 */  0x56, 0x13, 0xE8, 0x50, 0x61, 0x59, 0x40, 0x1A,  // V..PaY@.
                /* 0180 */  0x4B, 0xE0, 0xA0, 0xA7, 0xD0, 0xFB, 0x64, 0x84,  // K.....d.
                /* 0188 */  0x7B, 0xE0, 0x45, 0x8F, 0x09, 0x7D, 0x36, 0x20,  // {.E..}6 
                /* 0190 */  0x03, 0xA0, 0x10, 0x8E, 0x0F, 0xA1, 0xF0, 0x63,  // .......c
                /* 0198 */  0xA2, 0x70, 0x8E, 0x0B, 0x46, 0x41, 0x7C, 0x06,  // .p..FA|.
                /* 01A0 */  0x70, 0x14, 0x08, 0x19, 0x39, 0x0E, 0xA0, 0x8E,  // p...9...
                /* 01A8 */  0x18, 0x1E, 0x09, 0x8C, 0xE3, 0x05, 0x3B, 0x35,  // ......;5
                /* 01B0 */  0xC0, 0xB9, 0x20, 0xF8, 0x38, 0xC0, 0xE1, 0x0C,  // .. .8...
                /* 01B8 */  0x69, 0x38, 0x7E, 0x1B, 0x78, 0xA5, 0x48, 0xC0,  // i8~.x.H.
                /* 01C0 */  0x65, 0x9D, 0x0A, 0xA0, 0xDF, 0x38, 0x3C, 0x43,  // e....8<C
                /* 01C8 */  0x5F, 0x32, 0x12, 0x14, 0x78, 0x28, 0x00, 0x05,  // _2..x(..
                /* 01D0 */  0x90, 0xEF, 0x00, 0x56, 0x7A, 0x0E, 0xA0, 0x53,  // ...Vz..S
                /* 01D8 */  0x08, 0xF1, 0xFF, 0x0F, 0x13, 0xCD, 0xF0, 0x18,  // ........
                /* 01E0 */  0xC1, 0x23, 0xA5, 0xE3, 0xF1, 0xB0, 0xF8, 0xB1,  // .#......
                /* 01E8 */  0xC0, 0x87, 0x03, 0x86, 0xFD, 0x38, 0x70, 0x30,  // .....8p0
                /* 01F0 */  0xC7, 0x79, 0xF6, 0xE7, 0x7A, 0x4C, 0xEF, 0x0F,  // .y..zL..
                /* 01F8 */  0x16, 0xAF, 0x55, 0x9A, 0x12, 0x58, 0x0F, 0x94,  // ..U..X..
                /* 0200 */  0xC3, 0x1A, 0x2D, 0x6C, 0xE1, 0x67, 0x07, 0x72,  // ..-l.g.r
                /* 0208 */  0xEF, 0xF0, 0xC4, 0x7C, 0x60, 0xF0, 0x60, 0x99,  // ...|`.`.
                /* 0210 */  0x42, 0x9B, 0x3E, 0x35, 0x1A, 0xB5, 0x6A, 0x50,  // B.>5..jP
                /* 0218 */  0xA6, 0x46, 0x99, 0x06, 0xB5, 0xFA, 0x54, 0x6A,  // .F....Tj
                /* 0220 */  0xCC, 0xD8, 0x59, 0xC4, 0x31, 0xDE, 0x01, 0x1A,  // ..Y.1...
                /* 0228 */  0x8B, 0x45, 0x2C, 0x47, 0x20, 0x0E, 0x40, 0xA1,  // .E,G .@.
                /* 0230 */  0x83, 0x80, 0xE3, 0x80, 0x08, 0xC8, 0xFF, 0x7F   // ........
            })
            OperationRegion (IOSM, SystemIO, SMIP, 0x02)
            Field (IOSM, ByteAcc, NoLock, Preserve)
            {
                SMPT,   8, 
                SMIS,   8
            }

            Method (ISMI, 1, Serialized)
            {
                SMPT = Arg0
            }

            Method (WDLC, 1, Serialized)
            {
                WDLS = Arg0
                ISMI (0x96)
                Return (Zero)
            }

            Name (WDLP, 0x719C2A98)
            OperationRegion (WDLR, SystemMemory, WDLP, One)
            Field (WDLR, ByteAcc, NoLock, Preserve)
            {
                WDLS,   8
            }
        }
    }

    Scope (_SB)
    {
        Name (ANVM, 0x71325000)
        OperationRegion (ANVX, SystemMemory, ANVM, 0x00030000)
        Name (ASFH, 0x712E5000)
        OperationRegion (ASFX, SystemMemory, ASFH, 0x00040000)
    }

    Scope (\)
    {
        Device (RMTW)
        {
            Name (_HID, EisaId ("PNP0C14") /* Windows Management Instrumentation Device */)  // _HID: Hardware ID
            Name (_UID, "AsusMbSwInterface")  // _UID: Unique ID
            Name (_WDG, Buffer (0x50)
            {
                /* 0000 */  0xD0, 0x5E, 0x84, 0x97, 0x6D, 0x4E, 0xDE, 0x11,  // .^..mN..
                /* 0008 */  0x8A, 0x39, 0x08, 0x00, 0x20, 0x0C, 0x9A, 0x66,  // .9.. ..f
                /* 0010 */  0x42, 0x43, 0x01, 0x02, 0x15, 0xB1, 0x2B, 0xB8,  // BC....+.
                /* 0018 */  0xAE, 0x43, 0x35, 0x4B, 0xB7, 0x9D, 0xBD, 0x64,  // .C5K...d
                /* 0020 */  0x16, 0xAB, 0xC3, 0x81, 0x42, 0x43, 0x01, 0x02,  // ....BC..
                /* 0028 */  0x72, 0x0F, 0xBC, 0xAB, 0xA1, 0x8E, 0xD1, 0x11,  // r.......
                /* 0030 */  0x00, 0xA0, 0xC9, 0x06, 0x29, 0x10, 0x00, 0x00,  // ....)...
                /* 0038 */  0xD2, 0x00, 0x01, 0x08, 0x21, 0x12, 0x90, 0x05,  // ....!...
                /* 0040 */  0x66, 0xD5, 0xD1, 0x11, 0xB2, 0xF0, 0x00, 0xA0,  // f.......
                /* 0048 */  0xC9, 0x06, 0x29, 0x10, 0x4D, 0x4F, 0x01, 0x00   // ..).MO..
            })
            Method (WMBC, 3, Serialized)
            {
                Switch (Arg1)
                {
                    Case (0x53564544)
                    {
                        Return (DEVS (Arg2))
                    }
                    Case (0x53544344)
                    {
                        Return (DSTS (Arg2))
                    }
                    Case (0x4C455252)
                    {
                        Return (LERR (Arg2))
                    }
                    Case (0x47424F44)
                    {
                        Return (GBOD (Arg2))
                    }
                    Case (0x53424F44)
                    {
                        Return (SBOD (Arg2))
                    }
                    Case (0x47424F4E)
                    {
                        Return (GBON (Arg2))
                    }
                    Case (0x53415057)
                    {
                        Return (SAPW (Arg2))
                    }
                    Case (0x53555057)
                    {
                        Return (SUPW (Arg2))
                    }
                    Case (0x53555058)
                    {
                        Return (GLBN (Arg2))
                    }
                    Case (0x53555059)
                    {
                        Return (ISLG (Arg2))
                    }
                    Case (0x53555060)
                    {
                        Return (GLBO (Arg2))
                    }
                    Case (0x53555061)
                    {
                        Return (SLBO (Arg2))
                    }
                    Case (0x53424F47)
                    {
                        Return (SBOG (Arg2))
                    }
                    Case (0x4C444654)
                    {
                        Return (LDFT ())
                    }
                    Case (0x53465442)
                    {
                        Return (SFTB (Arg2))
                    }
                    Case (0x53444654)
                    {
                        Return (SDFT (Arg2))
                    }
                    Case (0x5346544D)
                    {
                        Return (SFTM ())
                    }
                    Case (0x4443544C)
                    {
                        Return (DCTL (Arg2))
                    }
                    Case (0x4746414E)
                    {
                        Return (GFAN (Arg2))
                    }
                    Case (0x4446414E)
                    {
                        Return (SFAN (Arg2))
                    }
                    Case (0x47464356)
                    {
                        Return (GFCV (Arg2))
                    }
                    Case (0x44464356)
                    {
                        Return (SFCV (Arg2))
                    }
                    Case (0x43455057)
                    {
                        Return (CKPW (Arg2))
                    }
                    Case (0x47544F44)
                    {
                        Return (GTOD (Arg2))
                    }
                    Case (0x53544F44)
                    {
                        Return (STOD (Arg2))
                    }
                    Case (0x4F505945)
                    {
                        Return (EYPO ())
                    }
                    Case (0x54505945)
                    {
                        Return (EYPT ())
                    }
                    Case (0x45505945)
                    {
                        Return (EYPE ())
                    }
                    Case (0x56505945)
                    {
                        Return (EYPF ())
                    }
                    Case (0x41504631)
                    {
                        Return (APF1 (Arg2))
                    }
                    Case (0x41505057)
                    {
                        Return (APPW (Arg2))
                    }
                    Case (0xFFFFFFFF)
                    {
                        Return (Zero)
                    }
                    Default
                    {
                        Return (Zero)
                    }

                }

                Return (Zero)
            }

            Name (ECD2, Zero)
            Name (EID2, Zero)
            Method (WED2, 1, NotSerialized)
            {
                ECD2 = Arg0
            }

            Method (_WED, 1, NotSerialized)  // _Wxx: Wake Event, xx=0x00-0xFF
            {
                If ((Arg0 == 0xD2))
                {
                    Return (EID2) /* \RMTW.EID2 */
                }

                Return (Zero)
            }

            Method (AMWR, 1, Serialized)
            {
                Local1 = Zero
                If (ECD2)
                {
                    EID2 = Arg0
                    Notify (RMTW, 0xD2) // Hardware-Specific
                    Local1 = One
                }
                Else
                {
                }

                Return (Local1)
            }

            Method (AMWN, 1, Serialized)
            {
                Local0 = AMWR (Arg0)
                Return (Local0)
            }

            Name (WQMO, Buffer (0x1BE0)
            {
                /* 0000 */  0x46, 0x4F, 0x4D, 0x42, 0x01, 0x00, 0x00, 0x00,  // FOMB....
                /* 0008 */  0xD0, 0x1B, 0x00, 0x00, 0xDE, 0xD6, 0x00, 0x00,  // ........
                /* 0010 */  0x44, 0x53, 0x00, 0x01, 0x1A, 0x7D, 0xDA, 0x54,  // DS...}.T
                /* 0018 */  0xA8, 0x38, 0xA5, 0x00, 0x01, 0x06, 0x18, 0x42,  // .8.....B
                /* 0020 */  0x10, 0x07, 0x10, 0xD2, 0xD8, 0x8F, 0x42, 0x04,  // ......B.
                /* 0028 */  0x0A, 0x0D, 0xA1, 0x38, 0x0A, 0x60, 0x30, 0x12,  // ...8.`0.
                /* 0030 */  0x20, 0x24, 0x07, 0x42, 0x2E, 0x98, 0x98, 0x00,  //  $.B....
                /* 0038 */  0x11, 0x10, 0xF2, 0x2A, 0xC0, 0xA6, 0x00, 0x93,  // ...*....
                /* 0040 */  0x20, 0xEA, 0xDF, 0x1F, 0xA2, 0x24, 0x38, 0x94,  //  ....$8.
                /* 0048 */  0x10, 0x08, 0x49, 0x14, 0x60, 0x5E, 0x80, 0x6E,  // ..I.`^.n
                /* 0050 */  0x01, 0x86, 0x05, 0xD8, 0x16, 0x60, 0x5A, 0x80,  // .....`Z.
                /* 0058 */  0x63, 0x48, 0x2A, 0x0D, 0x9C, 0x12, 0x58, 0x0A,  // cH*...X.
                /* 0060 */  0x84, 0x84, 0x0A, 0x50, 0x2E, 0xC0, 0xB7, 0x00,  // ...P....
                /* 0068 */  0xED, 0x88, 0x92, 0x2C, 0xC0, 0x32, 0x8C, 0x08,  // ...,.2..
                /* 0070 */  0x3C, 0x8A, 0xC8, 0x46, 0xE3, 0x04, 0x65, 0x43,  // <..F..eC
                /* 0078 */  0xA3, 0x64, 0x40, 0xC8, 0xB3, 0x00, 0xEB, 0xC0,  // .d@.....
                /* 0080 */  0x84, 0xC0, 0xEE, 0x05, 0x98, 0x13, 0xE0, 0x4D,  // .......M
                /* 0088 */  0x80, 0xB8, 0x61, 0xC8, 0xDA, 0x00, 0x04, 0x55,  // ..a....U
                /* 0090 */  0x98, 0x00, 0x5B, 0x30, 0x42, 0xA9, 0x0D, 0x46,  // ..[0B..F
                /* 0098 */  0x28, 0x8D, 0x21, 0x68, 0x18, 0x46, 0x89, 0x78,  // (.!h.F.x
                /* 00A0 */  0x48, 0x9D, 0xC1, 0x0A, 0x25, 0x62, 0x98, 0x10,  // H...%b..
                /* 00A8 */  0x11, 0x2A, 0xC3, 0x20, 0xC3, 0x0A, 0x15, 0x2D,  // .*. ...-
                /* 00B0 */  0x6E, 0x84, 0xF6, 0x07, 0x41, 0xA2, 0xAD, 0x58,  // n...A..X
                /* 00B8 */  0x43, 0x75, 0xA4, 0xD1, 0xA0, 0x86, 0x97, 0xE0,  // Cu......
                /* 00C0 */  0x70, 0x3D, 0xD4, 0x73, 0xEC, 0x5C, 0x80, 0x74,  // p=.s.\.t
                /* 00C8 */  0x60, 0x81, 0x04, 0x3F, 0x8B, 0x3A, 0xC7, 0x49,  // `..?.:.I
                /* 00D0 */  0x40, 0x12, 0x18, 0xEB, 0xF8, 0xD9, 0xC0, 0xF1,  // @.......
                /* 00D8 */  0xAE, 0x01, 0x35, 0xE3, 0xE3, 0x65, 0x82, 0xE0,  // ..5..e..
                /* 00E0 */  0x50, 0x43, 0xF4, 0x40, 0xC3, 0x9D, 0xC0, 0x21,  // PC.@...!
                /* 00E8 */  0x32, 0x40, 0xCF, 0xE9, 0x68, 0x30, 0x07, 0x00,  // 2@..h0..
                /* 00F0 */  0x3B, 0x9C, 0x8C, 0xEE, 0x01, 0xA5, 0x0A, 0x30,  // ;......0
                /* 00F8 */  0x3B, 0x66, 0x59, 0x04, 0xD2, 0x78, 0x0C, 0x7D,  // ;fY..x.}
                /* 0100 */  0xBA, 0xE7, 0x73, 0xC2, 0x09, 0x2C, 0x7F, 0x10,  // ..s..,..
                /* 0108 */  0xA8, 0x91, 0x19, 0xDA, 0x06, 0xA7, 0x25, 0xCC,  // ......%.
                /* 0110 */  0x90, 0x87, 0x7F, 0x58, 0x4C, 0x2C, 0x84, 0x3E,  // ...XL,.>
                /* 0118 */  0x08, 0x1E, 0x0F, 0xBC, 0xFF, 0xFF, 0x78, 0xC0,  // ......x.
                /* 0120 */  0xA3, 0xF8, 0x4C, 0x20, 0x84, 0x57, 0x82, 0xD8,  // ..L .W..
                /* 0128 */  0x1E, 0xD0, 0x73, 0x82, 0x81, 0xB1, 0x03, 0xB2,  // ..s.....
                /* 0130 */  0x5F, 0x01, 0x08, 0xC1, 0xCB, 0x1C, 0x91, 0x9C,  // _.......
                /* 0138 */  0x22, 0x68, 0x4C, 0xC6, 0x68, 0x15, 0x42, 0x43,  // "hL.h.BC
                /* 0140 */  0x08, 0x6D, 0x88, 0xB3, 0x8B, 0x7F, 0xF0, 0x86,  // .m......
                /* 0148 */  0x39, 0x77, 0x13, 0x14, 0x39, 0x02, 0x94, 0x98,  // 9w..9...
                /* 0150 */  0x11, 0xA0, 0x8E, 0x01, 0xD1, 0x43, 0x9F, 0x4D,  // .....C.M
                /* 0158 */  0xF4, 0xE3, 0x89, 0x72, 0x12, 0x07, 0xE4, 0x33,  // ...r...3
                /* 0160 */  0x83, 0x11, 0x82, 0x97, 0x7B, 0x48, 0x20, 0x9A,  // ....{H .
                /* 0168 */  0xE7, 0xA0, 0x13, 0xC3, 0x39, 0x1D, 0x02, 0xCB,  // ....9...
                /* 0170 */  0x12, 0x0F, 0xA2, 0x3F, 0x10, 0x49, 0x5B, 0xAA,  // ...?.I[.
                /* 0178 */  0x6C, 0x2C, 0xD5, 0x83, 0xA0, 0x01, 0xCF, 0x08,  // l,......
                /* 0180 */  0xC2, 0xF5, 0x3D, 0xC2, 0x87, 0x03, 0x4F, 0xE3,  // ..=...O.
                /* 0188 */  0xB8, 0x3D, 0x85, 0x87, 0x08, 0x87, 0x82, 0xD3,  // .=......
                /* 0190 */  0x69, 0x83, 0xC7, 0xA1, 0x50, 0x18, 0x08, 0x0D,  // i...P...
                /* 0198 */  0xC8, 0xC7, 0x00, 0x02, 0x47, 0x41, 0x7C, 0x4A,  // ....GA|J
                /* 01A0 */  0x70, 0x18, 0x08, 0x39, 0x39, 0x0A, 0xA0, 0x8E,  // p..99...
                /* 01A8 */  0x17, 0x1E, 0x06, 0xF6, 0x4E, 0xC1, 0x84, 0x9F,  // ....N...
                /* 01B0 */  0x18, 0xA0, 0x5D, 0x0E, 0x7C, 0x14, 0xE0, 0x70,  // ..].|..p
                /* 01B8 */  0x86, 0x34, 0x1C, 0xBF, 0x09, 0xBC, 0x02, 0x98,  // .4......
                /* 01C0 */  0x80, 0x9D, 0x08, 0xE0, 0xDF, 0x36, 0x3C, 0x7E,  // .....6<~
                /* 01C8 */  0x1F, 0x31, 0x9E, 0x2F, 0x12, 0x38, 0xCE, 0xB0,  // .1./.8..
                /* 01D0 */  0xD0, 0xA3, 0xF5, 0x44, 0xF9, 0xA8, 0xCE, 0xE9,  // ...D....
                /* 01D8 */  0xC8, 0xA3, 0xBC, 0x58, 0x98, 0xC0, 0xE3, 0x82,  // ...X....
                /* 01E0 */  0xF7, 0xFF, 0x1F, 0x17, 0x38, 0xC6, 0xEC, 0x71,  // ....8..q
                /* 01E8 */  0x81, 0x4F, 0xE0, 0xC1, 0x01, 0x14, 0x40, 0xBE,  // .O....@.
                /* 01F0 */  0x28, 0x58, 0xE9, 0x61, 0x81, 0xCE, 0x21, 0x44,  // (X.a..!D
                /* 01F8 */  0x98, 0x68, 0x86, 0xC7, 0x08, 0x3E, 0x60, 0x50,  // .h...>`P
                /* 0200 */  0x59, 0xE3, 0x42, 0x0D, 0xD5, 0x27, 0x17, 0x86,  // Y.B..'..
                /* 0208 */  0xFD, 0x3E, 0x70, 0x34, 0x45, 0x5F, 0x1B, 0x74,  // .>p4E_.t
                /* 0210 */  0x20, 0x38, 0xA8, 0x27, 0x02, 0x4B, 0xB4, 0xA8,  //  8.'.K..
                /* 0218 */  0xD5, 0x29, 0xAC, 0x47, 0xCA, 0x61, 0x8D, 0x16,  // .).G.a..
                /* 0220 */  0xF6, 0x80, 0x9F, 0x2F, 0x7C, 0x9F, 0xE0, 0x57,  // .../|..W
                /* 0228 */  0x17, 0x8F, 0x96, 0x25, 0x39, 0x3D, 0xA0, 0x06,  // ...%9=..
                /* 0230 */  0x6C, 0x3D, 0x40, 0x3A, 0x27, 0x60, 0x2F, 0x2B,  // l=@:'`/+
                /* 0238 */  0x0C, 0xE2, 0x44, 0xA3, 0x1C, 0x93, 0x00, 0x35,  // ..D....5
                /* 0240 */  0x68, 0x8F, 0xCA, 0xD9, 0x49, 0x94, 0x7C, 0x9C,  // h...I.|.
                /* 0248 */  0x74, 0x00, 0xCE, 0x3A, 0x76, 0x0A, 0x62, 0x40,  // t..:v.b@
                /* 0250 */  0x07, 0x39, 0x3E, 0x80, 0x66, 0x80, 0xC7, 0xC9,  // .9>.f...
                /* 0258 */  0xC6, 0xE6, 0xE1, 0x71, 0x0D, 0xE7, 0x02, 0x04,  // ...q....
                /* 0260 */  0x78, 0x35, 0xE3, 0x45, 0x81, 0xF9, 0xF4, 0x80,  // x5.E....
                /* 0268 */  0xD1, 0x75, 0x2B, 0x00, 0x99, 0xBE, 0x53, 0x01,  // .u+...S.
                /* 0270 */  0x94, 0xFF, 0xFF, 0xA9, 0x00, 0x4C, 0xE8, 0x7C,  // .....L.|
                /* 0278 */  0xA3, 0x9E, 0x2C, 0x8F, 0x3C, 0x59, 0x0A, 0xE2,  // ..,.<Y..
                /* 0280 */  0xC9, 0xFA, 0x52, 0x01, 0x1C, 0xCE, 0x08, 0x67,  // ..R....g
                /* 0288 */  0xF7, 0x98, 0xE2, 0x4B, 0x05, 0x20, 0xD2, 0xA1,  // ...K. ..
                /* 0290 */  0xD4, 0x4B, 0x05, 0xC8, 0xD2, 0xAC, 0x42, 0x97,  // .K....B.
                /* 0298 */  0x0A, 0xCE, 0x61, 0x4D, 0x40, 0xBA, 0x1B, 0xF1,  // ..aM@...
                /* 02A0 */  0x3B, 0x85, 0x91, 0x9F, 0x89, 0x9E, 0x29, 0x0C,  // ;.....).
                /* 02A8 */  0x13, 0xE4, 0x35, 0x2A, 0xBA, 0x6F, 0x0D, 0x82,  // ..5*.o..
                /* 02B0 */  0xD4, 0xAD, 0x82, 0xA7, 0xA7, 0x90, 0xEE, 0x93,  // ........
                /* 02B8 */  0x01, 0x4A, 0xE9, 0x1D, 0x87, 0x82, 0x78, 0x70,  // .J....xp
                /* 02C0 */  0x0E, 0x71, 0x32, 0x40, 0xFE, 0xFF, 0x09, 0xDE,  // .q2@....
                /* 02C8 */  0x99, 0x3C, 0x87, 0x63, 0x3A, 0x90, 0xA7, 0x27,  // .<.c:..'
                /* 02D0 */  0x76, 0xA7, 0x00, 0x9E, 0x11, 0x86, 0x84, 0x46,  // v......F
                /* 02D8 */  0xF7, 0xD9, 0xE1, 0x3C, 0x5F, 0x3A, 0xC0, 0x3C,  // ...<_:.<
                /* 02E0 */  0x53, 0x5F, 0x3A, 0x80, 0x73, 0x88, 0xBB, 0x00,  // S_:.s...
                /* 02E8 */  0x4A, 0xF6, 0x5D, 0x80, 0x82, 0x78, 0x62, 0x8E,  // J.]..xb.
                /* 02F0 */  0x32, 0x53, 0xF4, 0x4C, 0x8C, 0xFF, 0x28, 0xF0,  // 2S.L..(.
                /* 02F8 */  0x32, 0xF0, 0x80, 0x85, 0xB9, 0x72, 0x80, 0xFB,  // 2....r..
                /* 0300 */  0xB2, 0xE0, 0x2B, 0x07, 0xF8, 0x8E, 0x35, 0xB8,  // ..+...5.
                /* 0308 */  0xFF, 0xFF, 0x85, 0x81, 0xDF, 0x06, 0x9E, 0x74,  // .......t
                /* 0310 */  0x0C, 0x71, 0x50, 0xE0, 0x87, 0xF2, 0xB5, 0x04,  // .qP.....
                /* 0318 */  0xF0, 0xA4, 0xD4, 0xE9, 0x79, 0xF3, 0xB5, 0x04,  // ....y...
                /* 0320 */  0x5C, 0x51, 0xAE, 0x25, 0xA8, 0xB3, 0xA6, 0x05,  // \Q.%....
                /* 0328 */  0x01, 0xC9, 0xFB, 0xA5, 0x90, 0x60, 0xFA, 0x5C,  // .....`.\
                /* 0330 */  0x02, 0x8F, 0x60, 0xFC, 0xD3, 0x13, 0x2A, 0x38,  // ..`...*8
                /* 0338 */  0x85, 0xA2, 0x1F, 0x1E, 0x50, 0x61, 0x0F, 0x0F,  // ....Pa..
                /* 0340 */  0x14, 0xC4, 0xC7, 0x49, 0xDF, 0x4B, 0x80, 0xEF,  // ...I.K..
                /* 0348 */  0xFF, 0xFF, 0x5E, 0x02, 0xB8, 0xC9, 0x30, 0x22,  // ..^...0"
                /* 0350 */  0xB4, 0x8A, 0xA3, 0x05, 0x72, 0x46, 0x60, 0x3D,  // ....rF`=
                /* 0358 */  0x11, 0xF8, 0xE4, 0x02, 0x9C, 0xC3, 0x1F, 0xDD,  // ........
                /* 0360 */  0x50, 0x71, 0xE7, 0x4C, 0x41, 0x3C, 0x28, 0x9F,  // Pq.LA<(.
                /* 0368 */  0x5C, 0x80, 0xDF, 0xA9, 0x04, 0xEE, 0xFF, 0xFF,  // \.......
                /* 0370 */  0x54, 0x02, 0xF8, 0xF0, 0x7A, 0x2A, 0x01, 0xDD,  // T...z*..
                /* 0378 */  0xDD, 0x0B, 0x4C, 0x57, 0x93, 0x33, 0x89, 0x16,  // ..LW.3..
                /* 0380 */  0xDC, 0x77, 0x2F, 0x80, 0x0B, 0xFF, 0xFF, 0xBB,  // .w/.....
                /* 0388 */  0x17, 0xC0, 0xFF, 0xFF, 0xFF, 0xDD, 0x0B, 0x64,  // .......d
                /* 0390 */  0x5E, 0xEF, 0x5E, 0xC0, 0xEB, 0x5C, 0x82, 0xB9,  // ^.^..\..
                /* 0398 */  0x7B, 0x01, 0x7C, 0xFB, 0xFF, 0xDF, 0xBD, 0x00,  // {.|.....
                /* 03A0 */  0x02, 0x9F, 0x4A, 0x40, 0x96, 0xED, 0x54, 0x82,  // ..J@..T.
                /* 03A8 */  0x56, 0xE8, 0xE0, 0xFF, 0x7F, 0x8E, 0x86, 0x39,  // V......9
                /* 03B0 */  0x81, 0x43, 0x79, 0xC2, 0xE8, 0x1A, 0x96, 0xE8,  // .Cy.....
                /* 03B8 */  0xB9, 0x7C, 0xA1, 0x94, 0xC0, 0xE8, 0xF2, 0x05,  // .|......
                /* 03C0 */  0xB0, 0x2D, 0xD0, 0x5D, 0x00, 0x15, 0xE1, 0x2E,  // .-.]....
                /* 03C8 */  0x40, 0x41, 0x7C, 0xF9, 0x02, 0x0E, 0xFF, 0xFF,  // @A|.....
                /* 03D0 */  0xCB, 0x17, 0x70, 0x0A, 0x05, 0x21, 0x23, 0x37,  // ..p..!#7
                /* 03D8 */  0x09, 0x7A, 0xF9, 0x82, 0x73, 0x71, 0xF0, 0xFD,  // .z..sq..
                /* 03E0 */  0xC8, 0x83, 0x02, 0xD7, 0x60, 0xCE, 0xBB, 0xD8,  // ....`...
                /* 03E8 */  0x93, 0x22, 0xBD, 0x9E, 0xC0, 0xBD, 0x73, 0x78,  // ."....sx
                /* 03F0 */  0x6C, 0xE0, 0x10, 0x77, 0x05, 0x03, 0xF6, 0x2E,  // l..w....
                /* 03F8 */  0x6F, 0x27, 0xE0, 0xD2, 0xB6, 0x76, 0xDD, 0x4E,  // o'...v.N
                /* 0400 */  0x70, 0x09, 0x8F, 0xD3, 0x90, 0x8F, 0x27, 0x98,  // p.....'.
                /* 0408 */  0x3C, 0xB7, 0x13, 0x54, 0x12, 0x18, 0x65, 0x21,  // <..T..e!
                /* 0410 */  0xD1, 0x11, 0x82, 0xAB, 0xBF, 0x89, 0xD1, 0xFF,  // ........
                /* 0418 */  0x3F, 0x88, 0x2D, 0xDC, 0x4E, 0x00, 0x3A, 0x8C,  // ?.-.N.:.
                /* 0420 */  0x19, 0xCE, 0x88, 0xDE, 0x2B, 0x0C, 0xE9, 0x33,  // ....+..3
                /* 0428 */  0x18, 0x30, 0x0D, 0x74, 0x04, 0x41, 0x5F, 0xD2,  // .0.t.A_.
                /* 0430 */  0xB0, 0x09, 0x6E, 0x20, 0x74, 0x46, 0xF0, 0x2E,  // ..n tF..
                /* 0438 */  0x20, 0x70, 0x27, 0x86, 0xF9, 0xFF, 0x4F, 0x0C,  //  p'...O.
                /* 0440 */  0x77, 0x00, 0x01, 0xDF, 0x59, 0x0D, 0x30, 0x78,  // w...Y.0x
                /* 0448 */  0x00, 0xF0, 0x59, 0x0D, 0x50, 0x75, 0x7B, 0x01,  // ..Y.Pu{.
                /* 0450 */  0xD9, 0x35, 0xC5, 0xB7, 0x17, 0x3E, 0x60, 0x6B,  // .5...>`k
                /* 0458 */  0x00, 0xD2, 0xF1, 0xE1, 0xF4, 0x8F, 0xE3, 0x28,  // .......(
                /* 0460 */  0xCE, 0xEB, 0x34, 0x5E, 0x60, 0x62, 0xD4, 0x2C,  // ..4^`b.,
                /* 0468 */  0xE0, 0xFF, 0x7F, 0xCA, 0xF0, 0x84, 0x7B, 0x03,  // ......{.
                /* 0470 */  0x54, 0xEA, 0x6B, 0x14, 0x1D, 0x95, 0xF3, 0x92,  // T.k.....
                /* 0478 */  0x28, 0xF5, 0xB1, 0x00, 0x95, 0xF3, 0x58, 0x40,  // (.....X@
                /* 0480 */  0x41, 0x0C, 0xE8, 0x8B, 0x87, 0x95, 0x5C, 0x3C,  // A.....\<
                /* 0488 */  0xD0, 0x83, 0x38, 0xD9, 0x37, 0x54, 0x5F, 0x3C,  // ..8.7T_<
                /* 0490 */  0xC0, 0x7C, 0x77, 0x01, 0x97, 0xB1, 0x5B, 0xCF,  // .|w...[.
                /* 0498 */  0x0B, 0x05, 0x10, 0x09, 0x3E, 0x55, 0x54, 0xD4,  // ....>UT.
                /* 04A0 */  0xA9, 0x52, 0x10, 0x4F, 0xD5, 0x31, 0x4E, 0x24,  // .R.O.1N$
                /* 04A8 */  0x9E, 0x2A, 0xFA, 0x24, 0x74, 0x6E, 0x6F, 0x24,  // .*.$tno$
                /* 04B0 */  0xFC, 0x3C, 0xF0, 0x3E, 0x01, 0xE6, 0xA1, 0xF8,  // .<.>....
                /* 04B8 */  0x70, 0x05, 0xFC, 0xFF, 0xFF, 0xD7, 0x09, 0x70,  // p......p
                /* 04C0 */  0x28, 0xF4, 0x69, 0x52, 0xE9, 0x75, 0x02, 0x5C,  // (.iR.u.\
                /* 04C8 */  0x82, 0xAE, 0x13, 0xE8, 0x58, 0x4B, 0xD5, 0x75,  // ....XK.u
                /* 04D0 */  0x02, 0xDE, 0x30, 0x1D, 0xE4, 0x3A, 0x41, 0x8F,  // ..0..:A.
                /* 04D8 */  0x79, 0x3C, 0xC0, 0x61, 0x0F, 0x25, 0x19, 0x8E,  // y<.a.%..
                /* 04E0 */  0x82, 0x78, 0x6C, 0xBE, 0x93, 0xFB, 0x3A, 0x01,  // .xl...:.
                /* 04E8 */  0xF7, 0xCE, 0x02, 0xEF, 0x3A, 0xC1, 0x0E, 0x05,  // ....:...
                /* 04F0 */  0xB0, 0x09, 0x7C, 0x67, 0x01, 0xCF, 0x81, 0x82,  // ..|g....
                /* 04F8 */  0x1D, 0x1C, 0xC0, 0x3C, 0x28, 0x70, 0x1C, 0x1C,  // ...<(p..
                /* 0500 */  0x80, 0xE3, 0xFF, 0xFF, 0xE0, 0x00, 0x34, 0x6E,  // ......4n
                /* 0508 */  0xB4, 0x20, 0xD3, 0x7F, 0x70, 0x40, 0xAB, 0xB8,  // . ..p@..
                /* 0510 */  0xD6, 0x40, 0x94, 0x76, 0x1A, 0x22, 0xB9, 0xAF,  // .@.v."..
                /* 0518 */  0x35, 0xA8, 0xC4, 0xD7, 0x1A, 0x40, 0x76, 0xF4,  // 5....@v.
                /* 0520 */  0xA9, 0xA2, 0xC2, 0x4E, 0x95, 0x82, 0x78, 0xAA,  // ...N..x.
                /* 0528 */  0xBE, 0x72, 0xC0, 0xBA, 0x4E, 0x60, 0x8E, 0x5D,  // .r..N`.]
                /* 0530 */  0x60, 0xF9, 0xFF, 0x5F, 0x27, 0x60, 0x5E, 0x39,  // `.._'`^9
                /* 0538 */  0xC0, 0x77, 0xEC, 0x02, 0xE2, 0xF7, 0x1A, 0xD0,  // .w......
                /* 0540 */  0x49, 0xBA, 0x4F, 0xA0, 0x83, 0xDD, 0x6B, 0x20,  // I.O...k 
                /* 0548 */  0xDE, 0x27, 0x9E, 0xD6, 0x9E, 0xE8, 0x74, 0xAF,  // .'....t.
                /* 0550 */  0x41, 0x85, 0xA0, 0xD0, 0xC5, 0xC6, 0xA7, 0x02,  // A.......
                /* 0558 */  0x2E, 0x1A, 0x8E, 0x82, 0xF8, 0x5E, 0x03, 0x38,  // .....^.8
                /* 0560 */  0x39, 0x39, 0x80, 0xE1, 0xFF, 0x7F, 0xAF, 0x01,  // 99......
                /* 0568 */  0xFB, 0xC9, 0x01, 0x50, 0x75, 0xB1, 0x01, 0x59,  // ...Pu..Y
                /* 0570 */  0x82, 0x93, 0x03, 0x5A, 0xC7, 0xC5, 0x06, 0x2A,  // ...Z...*
                /* 0578 */  0x42, 0x82, 0xC9, 0x2F, 0x36, 0xA8, 0xCC, 0x17,  // B../6...
                /* 0580 */  0x1B, 0x40, 0xD6, 0xFF, 0xFF, 0x7E, 0x0A, 0x7C,  // .@...~.|
                /* 0588 */  0x2F, 0x02, 0x0F, 0x14, 0xB8, 0x9B, 0x0D, 0x30,  // /......0
                /* 0590 */  0xBD, 0x9F, 0x02, 0x7F, 0x89, 0x37, 0x1B, 0xD0,  // .....7..
                /* 0598 */  0x89, 0xBA, 0x50, 0xA0, 0xA3, 0xDD, 0x6C, 0xA0,  // ..P...l.
                /* 05A0 */  0x5A, 0x03, 0x54, 0x98, 0x9B, 0x0D, 0x2A, 0x06,  // Z.T...*.
                /* 05A8 */  0x85, 0xAE, 0x36, 0x3E, 0x16, 0x70, 0xD9, 0x70,  // ..6>.p.p
                /* 05B0 */  0x14, 0xC4, 0x37, 0x1B, 0xFC, 0xFF, 0xFF, 0x66,  // ..7....f
                /* 05B8 */  0x03, 0x38, 0x38, 0x3A, 0x80, 0xFB, 0x6A, 0x03,  // .88:..j.
                /* 05C0 */  0x7C, 0x8E, 0x0E, 0x80, 0x82, 0xAB, 0x0D, 0xC8,  // |.......
                /* 05C8 */  0x62, 0x7C, 0xB0, 0x75, 0x74, 0xC0, 0x89, 0x01,  // b|.ut...
                /* 05D0 */  0xD2, 0xD1, 0x01, 0xD6, 0x5D, 0x20, 0x42, 0x82,  // ....] B.
                /* 05D8 */  0xF1, 0x57, 0xA4, 0xAB, 0x0D, 0x0F, 0x0E, 0xA3,  // .W......
                /* 05E0 */  0xFF, 0x7F, 0x74, 0x12, 0x5D, 0xE4, 0x10, 0x30,  // ..t.]..0
                /* 05E8 */  0xBA, 0xC8, 0x11, 0x10, 0x5D, 0x63, 0x7C, 0x91,  // ....]c|.
                /* 05F0 */  0xF7, 0x39, 0x13, 0x37, 0x4A, 0x2B, 0x1C, 0x83,  // .9.7J+..
                /* 05F8 */  0xE6, 0x91, 0xE0, 0x28, 0xDE, 0x6C, 0xC0, 0x7B,  // ...(.l.{
                /* 0600 */  0xC9, 0x04, 0xD7, 0x84, 0xE0, 0x0C, 0xE1, 0x7C,  // .......|
                /* 0608 */  0x6B, 0x9F, 0x10, 0x88, 0x4F, 0xA1, 0xE0, 0x8B,  // k...O...
                /* 0610 */  0x30, 0x21, 0xB4, 0x0A, 0x10, 0x69, 0x3C, 0x04,  // 0!...i<.
                /* 0618 */  0x10, 0xC7, 0x23, 0x02, 0xF1, 0xA1, 0x81, 0x8F,  // ..#.....
                /* 0620 */  0x08, 0x5C, 0x87, 0x13, 0x1C, 0xB8, 0x6F, 0xFC,  // .\....o.
                /* 0628 */  0xF6, 0x7C, 0x77, 0x02, 0x31, 0x92, 0xEF, 0x4E,  // .|w.1..N
                /* 0630 */  0xEC, 0xFF, 0x7F, 0x33, 0x01, 0x4F, 0x86, 0xA3,  // ...3.O..
                /* 0638 */  0x2E, 0x94, 0x13, 0x46, 0xC4, 0x47, 0x8A, 0x07,  // ...F.G..
                /* 0640 */  0x0C, 0x4F, 0x19, 0xBC, 0x6F, 0x0B, 0x4D, 0x19,  // .O..o.M.
                /* 0648 */  0x64, 0xA7, 0x2B, 0xC0, 0xA0, 0x85, 0x33, 0x0D,  // d.+...3.
                /* 0650 */  0xA0, 0xE3, 0xFF, 0x7F, 0xA6, 0x81, 0x6B, 0xD2,  // ......k.
                /* 0658 */  0xA1, 0xD0, 0xD3, 0x15, 0xC8, 0x64, 0x9E, 0x69,  // .....d.i
                /* 0660 */  0xD0, 0x61, 0x57, 0xA2, 0x33, 0x0D, 0xBC, 0x69,  // .aW.3..i
                /* 0668 */  0x3A, 0xDE, 0x99, 0x86, 0x42, 0x38, 0x18, 0x8C,  // :...B8..
                /* 0670 */  0x62, 0x41, 0xE8, 0x58, 0xC0, 0x83, 0xC0, 0x51,  // bA.X...Q
                /* 0678 */  0x10, 0x7B, 0xB8, 0xFD, 0xD1, 0x33, 0x0D, 0xBC,  // .{...3..
                /* 0680 */  0x93, 0x38, 0xB8, 0x2F, 0x35, 0xE0, 0x1B, 0x12,  // .8./5...
                /* 0688 */  0x9C, 0x4B, 0x0D, 0x3F, 0xAB, 0x03, 0xD7, 0xE3,  // .K.?....
                /* 0690 */  0x3C, 0x9C, 0x63, 0x0D, 0x66, 0x4C, 0x60, 0xFA,  // <.c.fL`.
                /* 0698 */  0xFF, 0x8F, 0x09, 0xCE, 0xC1, 0x06, 0x7C, 0x63,  // ......|c
                /* 06A0 */  0xF2, 0xC1, 0x06, 0xDE, 0xF1, 0x0C, 0xDC, 0x50,  // .......P
                /* 06A8 */  0x3E, 0xC3, 0x81, 0x6F, 0xD8, 0x70, 0x8E, 0x36,  // >..o.p.6
                /* 06B0 */  0xB8, 0x61, 0x83, 0xFB, 0x6E, 0x03, 0xBE, 0x63,  // .a..n..c
                /* 06B8 */  0x1E, 0xF0, 0x3B, 0xC3, 0x00, 0x87, 0xFF, 0xFF,  // ..;.....
                /* 06C0 */  0x19, 0x06, 0xA8, 0x1E, 0xF3, 0x40, 0xA6, 0x62,  // .....@.b
                /* 06C8 */  0x15, 0x3A, 0xC3, 0xE0, 0xB2, 0x5C, 0x88, 0x21,  // .:...\.!
                /* 06D0 */  0x5E, 0x17, 0xDE, 0xCC, 0xAD, 0xFE, 0x7C, 0x47,  // ^.....|G
                /* 06D8 */  0x47, 0x65, 0xDD, 0x14, 0x52, 0x7F, 0xE0, 0x44,  // Ge..R..D
                /* 06E0 */  0xE9, 0x3D, 0x70, 0x52, 0x10, 0x8F, 0xCD, 0x49,  // .=pR...I
                /* 06E8 */  0x0E, 0x17, 0x68, 0x2D, 0x07, 0x4E, 0x32, 0xA7,  // ..h-.N2.
                /* 06F0 */  0x63, 0x38, 0x9F, 0x13, 0x2A, 0xFE, 0x4C, 0x0C,  // c8..*.L.
                /* 06F8 */  0x94, 0xEF, 0x61, 0x70, 0x06, 0x85, 0x39, 0xEB,  // ..ap..9.
                /* 0700 */  0x01, 0xB7, 0xFF, 0xFF, 0x3D, 0x0C, 0x18, 0x05,  // ....=...
                /* 0708 */  0xBF, 0x87, 0xA1, 0xA2, 0xCE, 0x88, 0x82, 0xF8,  // ........
                /* 0710 */  0x5A, 0xE0, 0x7B, 0x09, 0x9C, 0x3B, 0x07, 0xEE,  // Z.{..;..
                /* 0718 */  0x5E, 0x02, 0xEF, 0x1A, 0x06, 0x8E, 0xDB, 0x0D,  // ^.......
                /* 0720 */  0xF8, 0xAE, 0x1C, 0xC0, 0x5B, 0xAC, 0xC4, 0x2B,  // ....[..+
                /* 0728 */  0x33, 0xD8, 0xC2, 0x5D, 0x99, 0xD1, 0x12, 0xAF,  // 3..]....
                /* 0730 */  0x1C, 0x50, 0xCF, 0xF4, 0xBE, 0x3E, 0xFB, 0x16,  // .P...>..
                /* 0738 */  0xC6, 0xE5, 0xC0, 0x48, 0xCC, 0x45, 0x15, 0x15,  // ...H.E..
                /* 0740 */  0xFF, 0xCA, 0x41, 0x41, 0x7C, 0xC7, 0x71, 0x1C,  // ..AA|.q.
                /* 0748 */  0x01, 0xFF, 0xFF, 0x2B, 0x07, 0x76, 0x4C, 0xBE,  // ...+.vL.
                /* 0750 */  0x72, 0xC0, 0xBA, 0x35, 0x03, 0xE3, 0xB3, 0x03,  // r..5....
                /* 0758 */  0x9C, 0x53, 0x07, 0xEE, 0x2E, 0x06, 0xFC, 0x8F,  // .S......
                /* 0760 */  0x17, 0xE0, 0xB8, 0x8B, 0x01, 0xA7, 0xE3, 0x05,  // ........
                /* 0768 */  0xB0, 0xF9, 0xFF, 0x1F, 0x2F, 0x40, 0x76, 0x41,  // ..../@vA
                /* 0770 */  0x02, 0x99, 0x96, 0x0B, 0x12, 0x3A, 0xD1, 0xF1,  // .....:..
                /* 0778 */  0x02, 0xEA, 0x05, 0xDF, 0x19, 0x2E, 0x48, 0xA8,  // ......H.
                /* 0780 */  0x3B, 0x92, 0x53, 0x1F, 0x61, 0x50, 0x39, 0x4F,  // ;.S.aP9O
                /* 0788 */  0x07, 0x14, 0xC4, 0x80, 0xBE, 0x11, 0xFA, 0x1A,  // ........
                /* 0790 */  0x86, 0x3B, 0x37, 0xE0, 0x8F, 0x47, 0xC0, 0xF0,  // .;7..G..
                /* 0798 */  0x10, 0xC6, 0x2E, 0x3F, 0xC0, 0x22, 0xC6, 0xD9,  // ...?."..
                /* 07A0 */  0x0A, 0x25, 0xFC, 0x62, 0x42, 0x41, 0x3C, 0x31,  // .%.bBA<1
                /* 07A8 */  0x9F, 0xE0, 0xE0, 0x5C, 0x27, 0xB8, 0xC8, 0x31,  // ...\'..1
                /* 07B0 */  0xE9, 0x50, 0x0B, 0xFE, 0xFF, 0xFF, 0xB9, 0x1F,  // .P......
                /* 07B8 */  0x9C, 0xA3, 0x82, 0x3B, 0xDC, 0xB3, 0x39, 0x2A,  // ...;..9*
                /* 07C0 */  0xF0, 0x5F, 0x14, 0x7C, 0xCC, 0x03, 0x3C, 0x29,  // ._.|..<)
                /* 07C8 */  0xB5, 0x29, 0xF1, 0x8E, 0x04, 0xB2, 0x78, 0x77,  // .)....xw
                /* 07D0 */  0x24, 0xB4, 0xC8, 0x5B, 0x07, 0xD4, 0x23, 0x8F,  // $..[..#.
                /* 07D8 */  0x65, 0xDD, 0x91, 0x50, 0x82, 0x60, 0x74, 0x49,  // e..P.`tI
                /* 07E0 */  0xF2, 0xD9, 0x81, 0x2F, 0xCD, 0x60, 0x06, 0xF1,  // .../.`..
                /* 07E8 */  0x1D, 0xC9, 0x41, 0x6E, 0x1D, 0xD0, 0x4F, 0x05,  // ..An..O.
                /* 07F0 */  0x70, 0xFE, 0xFF, 0x17, 0x24, 0xE0, 0x74, 0x74,  // p...$.tt
                /* 07F8 */  0x00, 0xC7, 0xF9, 0x02, 0xFE, 0x0D, 0x09, 0x3C,  // .......<
                /* 0800 */  0xE7, 0x0B, 0xE0, 0x7A, 0x47, 0x02, 0xCF, 0xF9,  // ...zG...
                /* 0808 */  0x02, 0x30, 0xA5, 0xD4, 0xEB, 0xFF, 0xFF, 0x7C,  // .0.....|
                /* 0810 */  0x01, 0x2E, 0x3D, 0x07, 0x75, 0x74, 0xAA, 0x83,  // ..=.ut..
                /* 0818 */  0x3A, 0x54, 0x6F, 0x80, 0xCA, 0x71, 0x42, 0xA7,  // :To..qB.
                /* 0820 */  0xA3, 0x72, 0x02, 0x18, 0x5D, 0x92, 0x00, 0xD3,  // .r..]...
                /* 0828 */  0x51, 0x6E, 0x26, 0x28, 0xF1, 0x37, 0x13, 0x0A,  // Qn&(.7..
                /* 0830 */  0xE2, 0xCB, 0xB1, 0xCF, 0x70, 0x9E, 0x2A, 0x0E,  // ....p.*.
                /* 0838 */  0xDA, 0x03, 0x78, 0x04, 0x78, 0x31, 0x81, 0x7B,  // ..x.x1.{
                /* 0840 */  0x45, 0x02, 0x5E, 0x63, 0xFA, 0xFF, 0x1F, 0x13,  // E.^c....
                /* 0848 */  0x1C, 0xC5, 0x63, 0x02, 0x02, 0x37, 0x0E, 0x70,  // ..c..7.p
                /* 0850 */  0x8E, 0x09, 0xD6, 0x1D, 0xFF, 0x98, 0xC0, 0x7F,  // ........
                /* 0858 */  0x83, 0x07, 0xD7, 0x98, 0x60, 0x9F, 0x29, 0x8E,  // ....`.).
                /* 0860 */  0x09, 0xFC, 0x37, 0x23, 0xDF, 0x5B, 0x00, 0x1B,  // ..7#.[..
                /* 0868 */  0xFF, 0xFF, 0x7B, 0x0B, 0xCC, 0xBF, 0x62, 0x87,  // ..{...b.
                /* 0870 */  0xD7, 0x2C, 0x90, 0x1D, 0x34, 0x7C, 0x6F, 0xC1,  // .,..4|o.
                /* 0878 */  0x49, 0xB8, 0x66, 0x41, 0x1C, 0xE6, 0x23, 0xA6,  // I.fA..#.
                /* 0880 */  0x43, 0x5F, 0xF5, 0xE8, 0xA8, 0x1C, 0x97, 0x44,  // C_.....D
                /* 0888 */  0xA1, 0xEF, 0x2D, 0xA8, 0x98, 0x87, 0x0C, 0x0A,  // ..-.....
                /* 0890 */  0x62, 0x40, 0x1F, 0xBC, 0x81, 0x15, 0x81, 0x0F,  // b@......
                /* 0898 */  0xDE, 0x80, 0xE9, 0xD3, 0x2E, 0xAC, 0xFF, 0xFF,  // ........
                /* 08A0 */  0x51, 0x16, 0x30, 0xE2, 0xD0, 0xE2, 0x25, 0x10,  // Q.0...%.
                /* 08A8 */  0x6C, 0x97, 0x3E, 0x1F, 0x27, 0x70, 0xA1, 0x96,  // l.>.'p..
                /* 08B0 */  0xAA, 0xE3, 0x04, 0x3C, 0x73, 0x77, 0x51, 0x7A,  // ...<swQz
                /* 08B8 */  0x09, 0xE4, 0x01, 0x28, 0x24, 0xFF, 0x3E, 0x8A,  // ...($.>.
                /* 08C0 */  0x12, 0x0C, 0x47, 0x41, 0x3C, 0x36, 0x9F, 0xA8,  // ..GA<6..
                /* 08C8 */  0x81, 0xDB, 0x7D, 0x02, 0x7C, 0x27, 0x6A, 0x60,  // ..}.|'j`
                /* 08D0 */  0xF5, 0xFF, 0x3F, 0x37, 0x00, 0xBE, 0x2E, 0x77,  // ..?7...w
                /* 08D8 */  0x60, 0x4B, 0x7F, 0x6E, 0x40, 0x9F, 0xA4, 0x7D,  // `K.n@..}
                /* 08E0 */  0xB9, 0x83, 0x77, 0x6E, 0xB0, 0xEA, 0x13, 0x35,  // ..wn...5
                /* 08E8 */  0x4A, 0x2F, 0x85, 0x54, 0x9F, 0x1B, 0x50, 0x3A,  // J/.T..P:
                /* 08F0 */  0xCF, 0x0D, 0x14, 0xC4, 0x63, 0x73, 0x82, 0x43,  // ....cs.C
                /* 08F8 */  0x01, 0x7A, 0x94, 0x9E, 0xEF, 0x43, 0x40, 0x9D,  // .z...C@.
                /* 0900 */  0x87, 0x1A, 0x20, 0x7A, 0xEB, 0x01, 0x0E, 0xFF,  // .. z....
                /* 0908 */  0xFF, 0x19, 0xC1, 0x38, 0x33, 0x80, 0xEF, 0xD6,  // ...83...
                /* 0910 */  0x03, 0xD8, 0xBB, 0x4F, 0xF0, 0xEB, 0x06, 0xE0,  // ...O....
                /* 0918 */  0xC7, 0xA7, 0x49, 0xA7, 0xB7, 0x1E, 0x90, 0x45,  // ..I....E
                /* 0920 */  0xBA, 0x6E, 0xA0, 0x85, 0x5D, 0x37, 0xA0, 0xFD,  // .n..]7..
                /* 0928 */  0xFF, 0x6F, 0x3D, 0xBE, 0xD4, 0x59, 0xCA, 0x51,  // .o=..Y.Q
                /* 0930 */  0x1A, 0x25, 0xE2, 0x10, 0xED, 0x0B, 0x26, 0xEA,  // .%....&.
                /* 0938 */  0x6A, 0xC6, 0x41, 0x7C, 0xC1, 0xF3, 0xD9, 0xD4,  // j.A|....
                /* 0940 */  0xD7, 0x0D, 0x78, 0x97, 0x1E, 0xE0, 0x7F, 0x2F,  // ..x..../
                /* 0948 */  0x02, 0x1E, 0x37, 0x0E, 0xF0, 0xDD, 0x8B, 0x80,  // ..7.....
                /* 0950 */  0xDB, 0xC9, 0x02, 0xB8, 0xFD, 0xFF, 0x4F, 0x16,  // ......O.
                /* 0958 */  0x40, 0xE7, 0x5E, 0x04, 0xB2, 0xF8, 0x27, 0x0B,  // @.^...'.
                /* 0960 */  0x74, 0x88, 0x93, 0x05, 0xD4, 0x83, 0xD1, 0x13,  // t.......
                /* 0968 */  0x80, 0xEE, 0x45, 0x28, 0xC1, 0x14, 0x92, 0x7D,  // ..E(...}
                /* 0970 */  0x2F, 0x42, 0x09, 0x3D, 0x59, 0x50, 0x10, 0x8F,  // /B.=YP..
                /* 0978 */  0xCD, 0x11, 0x0E, 0x05, 0x68, 0x15, 0x20, 0x52,  // ....h. R
                /* 0980 */  0x38, 0x0F, 0x8D, 0xA1, 0xEB, 0x83, 0x11, 0x40,  // 8......@
                /* 0988 */  0x86, 0xFF, 0xFF, 0xC1, 0x08, 0xE0, 0x91, 0x4D,  // .......M
                /* 0990 */  0xAF, 0x22, 0x0F, 0x46, 0x20, 0x0B, 0x75, 0xDE,  // .".F .u.
                /* 0998 */  0x40, 0x4B, 0x3B, 0x6F, 0x40, 0x3D, 0x32, 0x5B,  // @K;o@=2[
                /* 09A0 */  0xCC, 0xC1, 0x08, 0x25, 0x03, 0x46, 0x27, 0x23,  // ...%.F'#
                /* 09A8 */  0x1F, 0x0A, 0x78, 0xEC, 0xF3, 0x06, 0x05, 0xF1,  // ..x.....
                /* 09B0 */  0xC1, 0xC8, 0x87, 0x02, 0x38, 0xE7, 0x0D, 0xCC,  // ....8...
                /* 09B8 */  0xA1, 0x00, 0xFB, 0xFF, 0x3F, 0x19, 0x01, 0x7C,  // ....?..|
                /* 09C0 */  0x3F, 0x5A, 0xE8, 0x64, 0x84, 0xFC, 0xFF, 0x1F,  // ?Z.d....
                /* 09C8 */  0x2D, 0xE0, 0x67, 0x39, 0x5A, 0xA0, 0x15, 0x1D,  // -.g9Z...
                /* 09D0 */  0x2D, 0x20, 0x4A, 0x13, 0xA0, 0xED, 0x68, 0xE3,  // - J...h.
                /* 09D8 */  0x93, 0x11, 0x2A, 0x3D, 0x89, 0xD2, 0x1F, 0x5F,  // ..*=..._
                /* 09E0 */  0x50, 0x79, 0x4F, 0x07, 0x14, 0xC4, 0x80, 0x0E,  // PyO.....
                /* 09E8 */  0x33, 0x44, 0x14, 0xA4, 0x07, 0xE2, 0xF9, 0x9E,  // 3D......
                /* 09F0 */  0xCE, 0x31, 0xBC, 0x38, 0x60, 0xA6, 0x5B, 0x39,  // .1.8`.[9
                /* 09F8 */  0x82, 0x26, 0xD3, 0x3C, 0x9C, 0xE6, 0xF2, 0x76,  // .&.<...v
                /* 0A00 */  0x04, 0x5E, 0x5D, 0xD7, 0x02, 0xE8, 0xA7, 0x80,  // .^].....
                /* 0A08 */  0xA3, 0x3D, 0x93, 0x43, 0xB0, 0xE7, 0xCB, 0x0F,  // .=.C....
                /* 0A10 */  0x10, 0x89, 0x3F, 0x5D, 0x54, 0xE0, 0xE9, 0x52,  // ..?]T..R
                /* 0A18 */  0x10, 0x4F, 0x17, 0x8E, 0x94, 0x2B, 0x05, 0x6A,  // .O...+.j
                /* 0A20 */  0xB2, 0xB8, 0x5B, 0xC1, 0xC3, 0x3A, 0xD8, 0xAF,  // ..[..:..
                /* 0A28 */  0x89, 0x1E, 0x2E, 0xEC, 0xFF, 0xFF, 0x70, 0x71,  // ......pq
                /* 0A30 */  0xD7, 0x37, 0xE0, 0xAE, 0x54, 0xE1, 0xAD, 0x02,  // .7..T...
                /* 0A38 */  0x5C, 0xB1, 0xD6, 0xA9, 0x5B, 0x05, 0x4E, 0xDC,  // \...[.N.
                /* 0A40 */  0x69, 0x1D, 0xE2, 0xAD, 0xA2, 0x37, 0x48, 0x9F,  // i....7H.
                /* 0A48 */  0xD6, 0x51, 0x42, 0x28, 0x24, 0xE3, 0xFA, 0x86,  // .QB($...
                /* 0A50 */  0xBA, 0x66, 0x19, 0xCC, 0x20, 0x1E, 0x9D, 0x43,  // .f.. ..C
                /* 0A58 */  0x9D, 0x0B, 0xD0, 0x92, 0x6E, 0x15, 0x50, 0xCE,  // ....n.P.
                /* 0A60 */  0x06, 0xE0, 0xBA, 0x05, 0x81, 0xE7, 0x6C, 0x00,  // ......l.
                /* 0A68 */  0xAC, 0xFF, 0xFF, 0x67, 0x03, 0x70, 0x7A, 0x3D,  // ...g.pz=
                /* 0A70 */  0x1B, 0x80, 0x2C, 0xCC, 0x05, 0x06, 0x2D, 0xE9,  // ..,...-.
                /* 0A78 */  0xAA, 0x05, 0xD5, 0xD9, 0x7D, 0x96, 0x5E, 0x60,  // ....}.^`
                /* 0A80 */  0x78, 0x7C, 0x12, 0x1D, 0x41, 0xE0, 0xA6, 0x39,  // x|..A..9
                /* 0A88 */  0x1B, 0xA0, 0xF5, 0x5C, 0xB5, 0x50, 0x27, 0x18,  // ...\.P'.
                /* 0A90 */  0x80, 0x25, 0xFF, 0xFF, 0x13, 0x0C, 0x60, 0xD2,  // .%....`.
                /* 0A98 */  0xE6, 0x83, 0xF0, 0xB1, 0x02, 0x64, 0xC1, 0x4E,  // .....d.N
                /* 0AA0 */  0x30, 0x68, 0x79, 0x27, 0x18, 0x88, 0xC7, 0x8A,  // 0hy'....
                /* 0AA8 */  0x37, 0x98, 0x04, 0x05, 0x9D, 0x60, 0x50, 0x52,  // 7....`PR
                /* 0AB0 */  0x28, 0x74, 0x84, 0xF1, 0xB9, 0x80, 0x47, 0x07,  // (t....G.
                /* 0AB8 */  0xA3, 0x20, 0x1E, 0x9D, 0x63, 0x9D, 0x0B, 0xD0,  // . ..c...
                /* 0AC0 */  0xA2, 0x8E, 0x15, 0x90, 0xEE, 0x06, 0x70, 0x8E,  // ......p.
                /* 0AC8 */  0x30, 0xC0, 0xF7, 0xFF, 0x7F, 0x38, 0x00, 0xEE,  // 0....8..
                /* 0AD0 */  0x47, 0x18, 0x60, 0x66, 0xED, 0x08, 0x03, 0x10,  // G.`f....
                /* 0AD8 */  0xE5, 0xFF, 0x7F, 0x84, 0x01, 0x18, 0xE1, 0xD0,  // ........
                /* 0AE0 */  0xE2, 0x11, 0x06, 0x98, 0x5D, 0x3C, 0x7D, 0x84,  // ....]<}.
                /* 0AE8 */  0x01, 0x6C, 0xFC, 0xFF, 0x8F, 0x30, 0x80, 0xC1,  // .l...0..
                /* 0AF0 */  0xC3, 0xC1, 0x23, 0x0C, 0xD8, 0xE2, 0x1C, 0x0E,  // ..#.....
                /* 0AF8 */  0xD0, 0xA2, 0x80, 0xE4, 0x71, 0x16, 0x64, 0x4C,  // ....q.dL
                /* 0B00 */  0xA7, 0x1F, 0x3B, 0x48, 0xAD, 0x27, 0x00, 0xC1,  // ..;H.'..
                /* 0B08 */  0xBF, 0x1C, 0x84, 0x6A, 0xEC, 0x2E, 0xEE, 0xC3,  // ...j....
                /* 0B10 */  0x01, 0x8A, 0xC2, 0x67, 0x10, 0xF8, 0x4E, 0xCE,  // ...g..N.
                /* 0B18 */  0x20, 0xE8, 0x59, 0xC0, 0x38, 0x83, 0x80, 0xFD,  //  .Y.8...
                /* 0B20 */  0x5C, 0x00, 0x8E, 0xAB, 0x34, 0x3F, 0x04, 0x3E,  // \...4?.>
                /* 0B28 */  0xBF, 0xFB, 0x5C, 0x00, 0xF7, 0xFF, 0x7F, 0x2E,  // ..\.....
                /* 0B30 */  0x00, 0x76, 0x16, 0xCD, 0x0A, 0xF5, 0x79, 0x2E,  // .v....y.
                /* 0B38 */  0x00, 0x5E, 0xD3, 0xF4, 0xB9, 0x00, 0xA0, 0x8F,  // .^......
                /* 0B40 */  0x54, 0xD8, 0xFF, 0xFF, 0x73, 0x01, 0xB0, 0x3A,  // T...s..:
                /* 0B48 */  0xA2, 0xFA, 0x5C, 0x00, 0xD0, 0xC7, 0xE2, 0xB9,  // ..\.....
                /* 0B50 */  0x00, 0x78, 0x9D, 0x31, 0x7D, 0x2E, 0xC0, 0xFC,  // .x.1}...
                /* 0B58 */  0xFF, 0xCF, 0x05, 0x00, 0x69, 0xB4, 0x9E, 0x0B,  // ....i...
                /* 0B60 */  0x80, 0xC5, 0xD0, 0x1E, 0xDD, 0x7C, 0x32, 0xF0,  // .....|2.
                /* 0B68 */  0xF1, 0xCC, 0x13, 0x09, 0x91, 0xC0, 0xE7, 0x02,  // ........
                /* 0B70 */  0x60, 0x30, 0x07, 0x3E, 0xE5, 0xB3, 0xF3, 0xB9,  // `0.>....
                /* 0B78 */  0x00, 0xF6, 0xFF, 0xFF, 0x5C, 0x00, 0xD8, 0x54,  // ....\..T
                /* 0B80 */  0xAA, 0xD4, 0xA2, 0xCC, 0x73, 0x01, 0xB8, 0xA4,  // ....s...
                /* 0B88 */  0x9D, 0x62, 0xD1, 0x01, 0xCF, 0x05, 0x88, 0x9B,  // .b......
                /* 0B90 */  0xE0, 0x59, 0x44, 0x08, 0xD2, 0xE7, 0x11, 0x40,  // .YD....@
                /* 0B98 */  0x27, 0x00, 0x9F, 0x0B, 0x58, 0xA4, 0x73, 0x01,  // '...X.s.
                /* 0BA0 */  0x2A, 0x0C, 0x85, 0xA2, 0x9C, 0x0F, 0x51, 0xE2,  // *.....Q.
                /* 0BA8 */  0xE1, 0x28, 0x88, 0xC7, 0xE6, 0x73, 0x01, 0xE0,  // .(...s..
                /* 0BB0 */  0xE5, 0xB0, 0x8A, 0xFD, 0xFF, 0x0F, 0x8B, 0xCD,  // ........
                /* 0BB8 */  0x15, 0xCE, 0x61, 0x15, 0xF0, 0x2C, 0xD1, 0xA7,  // ..a..,..
                /* 0BC0 */  0x42, 0x8F, 0xA7, 0x07, 0x70, 0xE5, 0x38, 0x3D,  // B...p.8=
                /* 0BC8 */  0xA0, 0xD5, 0x00, 0x69, 0x42, 0x4F, 0x0F, 0x30,  // ...iBO.0
                /* 0BD0 */  0xF3, 0x1F, 0x1B, 0xE8, 0xA8, 0x9C, 0x9C, 0x44,  // .......D
                /* 0BD8 */  0xC9, 0x0F, 0x29, 0xA8, 0xAC, 0x63, 0xA7, 0x20,  // ..)..c. 
                /* 0BE0 */  0x06, 0x74, 0x90, 0x73, 0x01, 0x68, 0xEE, 0xD3,  // .t.s.h..
                /* 0BE8 */  0xC0, 0xE4, 0xFF, 0x7F, 0x9F, 0x06, 0x1C, 0xDC,  // ........
                /* 0BF0 */  0x3C, 0x80, 0xDF, 0x9D, 0x02, 0x1C, 0x17, 0x1C,  // <.......
                /* 0BF8 */  0xC0, 0xC3, 0x9D, 0x42, 0x4E, 0x2F, 0x38, 0x20,  // ...BN/8 
                /* 0C00 */  0x5B, 0x85, 0xEE, 0x14, 0x5C, 0xD2, 0x05, 0xC7,  // [...\...
                /* 0C08 */  0x6B, 0xD1, 0x05, 0x07, 0x7F, 0x35, 0xF3, 0x9D,  // k....5..
                /* 0C10 */  0xDA, 0xE8, 0x75, 0x5E, 0xA6, 0x34, 0x02, 0xDF,  // ..u^.4..
                /* 0C18 */  0xAA, 0x74, 0xEF, 0xA7, 0xFF, 0xFF, 0xDB, 0x04,  // .t......
                /* 0C20 */  0xA1, 0x50, 0xEC, 0x93, 0x01, 0x2A, 0xE8, 0xE8,  // .P...*..
                /* 0C28 */  0x29, 0x88, 0x01, 0x9D, 0x02, 0x42, 0x4A, 0x4E,  // )....BJN
                /* 0C30 */  0x06, 0x28, 0x1D, 0x20, 0x12, 0x79, 0xA3, 0x26,  // .(. .y.&
                /* 0C38 */  0x33, 0x3A, 0x2B, 0x1F, 0x2A, 0x80, 0xDB, 0xB1,  // 3:+.*...
                /* 0C40 */  0x80, 0x5F, 0x89, 0x9F, 0xBF, 0x7D, 0xA8, 0x00,  // ._...}..
                /* 0C48 */  0x16, 0x81, 0x6E, 0x47, 0xA8, 0x08, 0xF7, 0x12,  // ..nG....
                /* 0C50 */  0x0A, 0xE2, 0xDB, 0x11, 0xF0, 0x3C, 0x54, 0x80,  // .....<T.
                /* 0C58 */  0x33, 0xD2, 0xB5, 0x05, 0xFD, 0x59, 0xF0, 0x45,  // 3....Y.E
                /* 0C60 */  0x01, 0xF6, 0xC8, 0xC0, 0xF2, 0xFF, 0x1F, 0x19,  // ........
                /* 0C68 */  0xBC, 0xE3, 0x82, 0x2F, 0x48, 0x80, 0x27, 0x9D,  // .../H.'.
                /* 0C70 */  0x17, 0x24, 0xD0, 0x69, 0x3B, 0x7D, 0xA0, 0x13,  // .$.i;}..
                /* 0C78 */  0x5E, 0x90, 0x10, 0xA3, 0x0A, 0x79, 0x24, 0x06,  // ^....y$.
                /* 0C80 */  0x3E, 0xB2, 0xE7, 0x42, 0x23, 0xF4, 0x7E, 0x5C,  // >..B#.~\
                /* 0C88 */  0x20, 0xE8, 0x26, 0x98, 0xE7, 0xF4, 0x81, 0x4A,  //  .&....J
                /* 0C90 */  0x42, 0xA1, 0x24, 0x47, 0x08, 0x94, 0xF6, 0x23,  // B.$G...#
                /* 0C98 */  0x04, 0x05, 0xF1, 0xE8, 0x1C, 0xE7, 0x70, 0x00,  // ......p.
                /* 0CA0 */  0x65, 0xC8, 0x8F, 0x03, 0xAF, 0x10, 0x1E, 0x14,  // e.......
                /* 0CA8 */  0x9B, 0x08, 0x8C, 0x5B, 0x12, 0xF0, 0x8C, 0x82,  // ...[....
                /* 0CB0 */  0x8B, 0xFA, 0xFF, 0x8F, 0xCB, 0x83, 0xF1, 0xF1,  // ........
                /* 0CB8 */  0xE1, 0xAC, 0x4E, 0xE9, 0xA8, 0x80, 0xC7, 0x94,  // ..N.....
                /* 0CC0 */  0x7D, 0x95, 0x02, 0x9C, 0xDF, 0x3E, 0xC0, 0x71,  // }....>.q
                /* 0CC8 */  0x95, 0x02, 0x3C, 0x78, 0x15, 0x6A, 0xF0, 0x2A,  // ..<x.j.*
                /* 0CD0 */  0xA5, 0xFF, 0xFF, 0xED, 0x03, 0x4C, 0xCA, 0x6E,  // .....L.n
                /* 0CD8 */  0x1F, 0x28, 0x0E, 0xE7, 0xBB, 0x7D, 0x20, 0xAC,  // .(...} .
                /* 0CE0 */  0x5E, 0x1E, 0x74, 0xAC, 0xF3, 0xFD, 0x01, 0xC6,  // ^.t.....
                /* 0CE8 */  0xE5, 0x03, 0x60, 0xE8, 0xFF, 0xFF, 0xF2, 0x01,  // ..`.....
                /* 0CF0 */  0xB0, 0xC5, 0xEA, 0xE5, 0x03, 0x64, 0x02, 0x2F,  // .....d./
                /* 0CF8 */  0x1F, 0xA8, 0x91, 0x3A, 0xE6, 0xB9, 0x10, 0x31,  // ...:...1
                /* 0D00 */  0xB4, 0x18, 0x4F, 0x08, 0xAF, 0x0F, 0x1D, 0x0B,  // ..O.....
                /* 0D08 */  0x30, 0x7F, 0x34, 0x04, 0xFA, 0xFF, 0xFF, 0xA3,  // 0.4.....
                /* 0D10 */  0x21, 0xC0, 0xFF, 0xFF, 0xFF, 0x01, 0x04, 0xB8,  // !.......
                /* 0D18 */  0x8A, 0x3D, 0x80, 0x80, 0x4E, 0xD8, 0xD1, 0x10,  // .=..N...
                /* 0D20 */  0x1D, 0x6F, 0x2D, 0x02, 0x7E, 0x16, 0x7A, 0xFF,  // .o-.~.z.
                /* 0D28 */  0x80, 0x73, 0x0C, 0x79, 0x5D, 0xF0, 0xE0, 0x9F,  // .s.y]...
                /* 0D30 */  0x01, 0x1C, 0xE6, 0xF4, 0x81, 0x8A, 0x71, 0xFA,  // ......q.
                /* 0D38 */  0x00, 0x74, 0xC7, 0x39, 0x7D, 0xA0, 0x02, 0x9C,  // .t.9}...
                /* 0D40 */  0x3E, 0x28, 0x88, 0x4F, 0x1F, 0xF0, 0xFE, 0xFF,  // >(.O....
                /* 0D48 */  0xA7, 0x0F, 0xC0, 0x41, 0xA0, 0xA1, 0xA0, 0x86,  // ...A....
                /* 0D50 */  0xE5, 0x71, 0xF8, 0xA8, 0x80, 0x3F, 0x28, 0xE0,  // .q...?(.
                /* 0D58 */  0x0E, 0x1F, 0xC0, 0x4F, 0xF1, 0x29, 0x82, 0xDC,  // ...O.)..
                /* 0D60 */  0x17, 0x7C, 0x64, 0xF0, 0xE1, 0x03, 0x98, 0x9B,  // .|d.....
                /* 0D68 */  0x3D, 0x7C, 0x80, 0x4E, 0xDC, 0xE1, 0x03, 0x25,  // =|.N...%
                /* 0D70 */  0x0A, 0x42, 0x11, 0x0F, 0x53, 0xD0, 0x0F, 0x77,  // .B..S..w
                /* 0D78 */  0xFE, 0xFF, 0x1F, 0x0F, 0x7D, 0x7C, 0x20, 0x47,  // ....}| G
                /* 0D80 */  0x29, 0x80, 0xC2, 0x37, 0x05, 0xF8, 0x23, 0x83,  // )..7..#.
                /* 0D88 */  0xF3, 0xFF, 0x3F, 0x4A, 0x01, 0x4E, 0x05, 0x1F,  // ..?J.N..
                /* 0D90 */  0xA5, 0x40, 0x7D, 0xFC, 0xF0, 0x51, 0xCA, 0xD7,  // .@}..Q..
                /* 0D98 */  0x5C, 0x76, 0xFC, 0x00, 0x43, 0x94, 0xE3, 0x07,  // \v..C...
                /* 0DA0 */  0x2A, 0x04, 0x85, 0x42, 0x9C, 0x21, 0x50, 0xB2,  // *..B.!P.
                /* 0DA8 */  0xCF, 0x10, 0x14, 0xC4, 0xC3, 0xF3, 0xF1, 0x03,  // ........
                /* 0DB0 */  0x30, 0x71, 0x16, 0xC6, 0xFC, 0xFF, 0xEF, 0x0F,  // 0q......
                /* 0DB8 */  0x60, 0x3A, 0xE6, 0x02, 0xAC, 0xFE, 0xFF, 0x9F,  // `:......
                /* 0DC0 */  0x38, 0x6C, 0xF8, 0xF0, 0x01, 0xBA, 0x50, 0xEB,  // 8l....P.
                /* 0DC8 */  0xD0, 0xE1, 0x03, 0x27, 0xED, 0xF0, 0x81, 0x38,  // ...'...8
                /* 0DD0 */  0x3E, 0xC0, 0x40, 0x7A, 0x3E, 0xC3, 0xCA, 0x38,  // >.@z>..8
                /* 0DD8 */  0x7C, 0xA0, 0x28, 0xC8, 0xE1, 0x03, 0x15, 0xF9,  // |.(.....
                /* 0DE0 */  0x68, 0x40, 0x41, 0xCC, 0xE6, 0x3C, 0x37, 0x0B,  // h@A..<7.
                /* 0DE8 */  0xB4, 0xA2, 0x33, 0x28, 0x72, 0x22, 0xF0, 0x4E,  // ..3(r".N
                /* 0DF0 */  0xED, 0xC0, 0xF3, 0x68, 0x01, 0x58, 0xFC, 0xFF,  // ...h.X..
                /* 0DF8 */  0x9F, 0xA7, 0xC0, 0x79, 0xB4, 0x00, 0xDE, 0x1E,  // ...y....
                /* 0E00 */  0x7D, 0x2A, 0x3C, 0x5A, 0x80, 0xEC, 0xCC, 0xE9,  // }*<Z....
                /* 0E08 */  0xA3, 0x05, 0x1F, 0xB0, 0x45, 0x01, 0x69, 0x62,  // ....E.ib
                /* 0E10 */  0x07, 0xF1, 0xA4, 0x13, 0xF1, 0x7C, 0x83, 0xD6,  // .....|..
                /* 0E18 */  0x8C, 0xA2, 0x71, 0x86, 0x0F, 0xFD, 0x2C, 0x99,  // ..q...,.
                /* 0E20 */  0xC0, 0x32, 0x0E, 0x47, 0x14, 0xC2, 0x14, 0x3E,  // .2.G...>
                /* 0E28 */  0x17, 0x00, 0xFF, 0xE3, 0x3B, 0x3F, 0x17, 0x00,  // ....;?..
                /* 0E30 */  0xB7, 0xFF, 0xFF, 0xB9, 0x00, 0x78, 0x48, 0xD5,  // .....xH.
                /* 0E38 */  0x28, 0x51, 0xE6, 0xB9, 0x00, 0x5C, 0x19, 0x4E,  // (Q...\.N
                /* 0E40 */  0x30, 0x28, 0x58, 0x2B, 0x39, 0xC1, 0x20, 0x34,  // 0(X+9. 4
                /* 0E48 */  0xDE, 0x0A, 0x74, 0x28, 0x78, 0x86, 0xC1, 0x10,  // ..t(x...
                /* 0E50 */  0x4C, 0x7F, 0x2C, 0xA0, 0x83, 0x72, 0x6E, 0x12,  // L.,..rn.
                /* 0E58 */  0xE5, 0x3E, 0x16, 0xA0, 0x92, 0x1E, 0x0B, 0x28,  // .>.....(
                /* 0E60 */  0x88, 0x0F, 0xCB, 0x04, 0x42, 0x46, 0x8E, 0x05,  // ....BF..
                /* 0E68 */  0xA8, 0xC3, 0x98, 0x87, 0xC1, 0xB4, 0x0E, 0x43,  // .......C
                /* 0E70 */  0x63, 0x3A, 0xF8, 0xB7, 0x02, 0x5F, 0x17, 0x9E,  // c:..._..
                /* 0E78 */  0x5C, 0xC0, 0x3B, 0x52, 0x1F, 0x0A, 0xC0, 0x21,  // \.;R...!
                /* 0E80 */  0xEE, 0xE2, 0x02, 0x68, 0xFA, 0xFF, 0x5F, 0x5C,  // ...h.._\
                /* 0E88 */  0x00, 0x9B, 0x0A, 0x7F, 0x14, 0x2F, 0x2E, 0x20,  // ...../. 
                /* 0E90 */  0x13, 0x74, 0x91, 0x47, 0xC7, 0xBA, 0x51, 0x20,  // .t.G..Q 
                /* 0E98 */  0x0E, 0x52, 0xA1, 0x63, 0x1C, 0xC9, 0x71, 0x44,  // .R.c..qD
                /* 0EA0 */  0x7E, 0x76, 0xC1, 0x12, 0xF8, 0xAA, 0xE8, 0x4B,  // ~v.....K
                /* 0EA8 */  0x05, 0x97, 0x4F, 0x21, 0xF9, 0x37, 0x2C, 0x94,  // ..O!.7,.
                /* 0EB0 */  0xE0, 0xBB, 0x05, 0x05, 0xF1, 0xE8, 0x9C, 0xE4,  // ........
                /* 0EB8 */  0x86, 0x85, 0xD6, 0x02, 0xA2, 0x79, 0xE0, 0x74,  // .....y.t
                /* 0EC0 */  0x4E, 0x43, 0xD3, 0xF2, 0xF5, 0x0A, 0x98, 0x86,  // NC......
                /* 0EC8 */  0xB8, 0x3D, 0xA0, 0xFE, 0xFF, 0x93, 0xB2, 0x0C,  // .=......
                /* 0ED0 */  0x10, 0xDD, 0x3B, 0x70, 0x57, 0x45, 0x60, 0x76,  // ..;pWE`v
                /* 0ED8 */  0x74, 0xC0, 0x5E, 0x15, 0x01, 0xC6, 0xDD, 0x8C,  // t.^.....
                /* 0EE0 */  0x74, 0xF0, 0x40, 0xFF, 0xFF, 0xAF, 0x8A, 0xD0,  // t.@.....
                /* 0EE8 */  0x2F, 0x60, 0xA8, 0xAB, 0x22, 0x01, 0xD2, 0xCD,  // /`.."...
                /* 0EF0 */  0x08, 0x73, 0x75, 0x0D, 0xF2, 0x08, 0xE0, 0x03,  // .su.....
                /* 0EF8 */  0xE1, 0x71, 0x85, 0x7A, 0x3A, 0xF2, 0x64, 0x5E,  // .q.z:.d^
                /* 0F00 */  0x02, 0xF8, 0x1D, 0x0C, 0x60, 0x8F, 0xCD, 0x23,  // ....`..#
                /* 0F08 */  0x0E, 0x10, 0x39, 0xDF, 0x58, 0xFB, 0x48, 0x74,  // ..9.X.Ht
                /* 0F10 */  0x36, 0x08, 0xF2, 0x08, 0x60, 0x70, 0xDF, 0x02,  // 6...`p..
                /* 0F18 */  0x3C, 0x84, 0x47, 0x1C, 0xF6, 0xFF, 0x3F, 0xE2,  // <.G...?.
                /* 0F20 */  0x80, 0x7D, 0x1E, 0xB8, 0x23, 0x0E, 0xC0, 0xDA,  // .}..#...
                /* 0F28 */  0xFF, 0xFF, 0x11, 0x07, 0xB0, 0x26, 0x53, 0xAA,  // .....&S.
                /* 0F30 */  0x43, 0x89, 0x07, 0x0F, 0x70, 0x85, 0x95, 0x70,  // C...p..p
                /* 0F38 */  0x65, 0xC5, 0x4A, 0x06, 0xD2, 0xE9, 0xF9, 0x11,  // e.J.....
                /* 0F40 */  0x87, 0xC3, 0x1E, 0xD8, 0x4B, 0x87, 0x8F, 0x18,  // ....K...
                /* 0F48 */  0x3E, 0xE3, 0x24, 0xB0, 0x48, 0x40, 0x1D, 0x3B,  // >.$.H@.;
                /* 0F50 */  0xB8, 0x3C, 0x18, 0xC5, 0x3E, 0x17, 0xA0, 0x82,  // .<..>...
                /* 0F58 */  0x9E, 0x0B, 0x28, 0x88, 0x01, 0x9D, 0xE2, 0x32,  // ..(....2
                /* 0F60 */  0x89, 0x1E, 0xB2, 0x67, 0xC1, 0xA6, 0x7A, 0x0E,  // ...g..z.
                /* 0F68 */  0x27, 0xF5, 0x30, 0x09, 0xD8, 0xF9, 0xFF, 0x1F,  // '.0.....
                /* 0F70 */  0x29, 0x60, 0xC8, 0x5C, 0x92, 0xC6, 0xCA, 0x85,  // )`.\....
                /* 0F78 */  0xC1, 0xE8, 0xC0, 0x48, 0x40, 0x34, 0x2C, 0x1F,  // ...H@4,.
                /* 0F80 */  0x26, 0x01, 0x2F, 0x41, 0xCE, 0x35, 0xE8, 0x2B,  // &./A.5.+
                /* 0F88 */  0x8B, 0xCF, 0x54, 0xB8, 0x63, 0x07, 0xF0, 0x3B,  // ..T.c..;
                /* 0F90 */  0xD6, 0x60, 0x87, 0x0E, 0xEB, 0x3A, 0x6D, 0xEF,  // .`...:m.
                /* 0F98 */  0x18, 0xC2, 0x7C, 0xCA, 0xF0, 0x11, 0x92, 0x0D,  // ..|.....
                /* 0FA0 */  0x0B, 0xDC, 0x50, 0x1E, 0x3A, 0xF8, 0xA2, 0x0C,  // ..P.:...
                /* 0FA8 */  0x1D, 0x0D, 0xFD, 0xFF, 0x4F, 0x10, 0xF5, 0xFD,  // ....O...
                /* 0FB0 */  0xC0, 0x17, 0x8B, 0xA8, 0xCF, 0x1F, 0x1E, 0x15,  // ........
                /* 0FB8 */  0xD8, 0xBF, 0x1E, 0x1A, 0x3B, 0x08, 0x47, 0x05,  // ....;.G.
                /* 0FC0 */  0x07, 0xF2, 0x5C, 0x8C, 0xF9, 0x18, 0xE5, 0xA1,  // ..\.....
                /* 0FC8 */  0x83, 0xDF, 0xC2, 0xA8, 0x40, 0x79, 0xCC, 0x01,  // ....@y..
                /* 0FD0 */  0xDE, 0x3A, 0x0D, 0x6A, 0xF4, 0x78, 0xCC, 0x01,  // .:.j.x..
                /* 0FD8 */  0x57, 0xB2, 0x63, 0x0E, 0x5A, 0x1F, 0x90, 0x0E,  // W.c.Z...
                /* 0FE0 */  0x86, 0x98, 0x63, 0x0E, 0x0C, 0x45, 0xC7, 0x1C,  // ..c..E..
                /* 0FE8 */  0x94, 0x16, 0x18, 0x69, 0x71, 0xF0, 0xFF, 0x3F,  // ...iq..?
                /* 0FF0 */  0xAB, 0x60, 0xD2, 0x9F, 0xD9, 0x28, 0x88, 0xCF,  // .`...(..
                /* 0FF8 */  0x2A, 0x3E, 0xE6, 0x00, 0x26, 0x32, 0x5C, 0x1C,  // *>..&2\.
                /* 1000 */  0xD0, 0x2A, 0xEE, 0x29, 0xC8, 0x9B, 0x1A, 0x30,  // .*.)...0
                /* 1008 */  0xBB, 0x35, 0x60, 0x73, 0x9C, 0x52, 0xD0, 0xD7,  // .5`s.R..
                /* 1010 */  0x78, 0x9F, 0x52, 0x60, 0xCC, 0x09, 0xAC, 0x87,  // x.R`....
                /* 1018 */  0x02, 0x9F, 0xE6, 0xC0, 0x76, 0xD4, 0xF7, 0x15,  // ....v...
                /* 1020 */  0x05, 0xFE, 0x98, 0xC0, 0xF1, 0xFF, 0x1F, 0x13,  // ........
                /* 1028 */  0x0C, 0x24, 0x4F, 0x1B, 0x6C, 0x57, 0x07, 0x8F,  // .$O.lW..
                /* 1030 */  0x09, 0xA7, 0xE3, 0x82, 0x02, 0x61, 0x4A, 0x60,  // .....aJ`
                /* 1038 */  0xBD, 0xC3, 0x78, 0x4A, 0x60, 0xBB, 0x12, 0x02,  // ..xJ`...
                /* 1040 */  0x16, 0x2F, 0x37, 0xE0, 0xB8, 0x12, 0x02, 0x8F,  // ./7.....
                /* 1048 */  0xFF, 0xFF, 0xE5, 0x06, 0x28, 0x5C, 0x09, 0x41,  // ....(\.A
                /* 1050 */  0xA6, 0xFF, 0x9F, 0xA0, 0xAB, 0x2D, 0x4E, 0x05,  // .....-N.
                /* 1058 */  0x90, 0xAE, 0x84, 0x6C, 0x1C, 0xCF, 0x31, 0x1E,  // ...l..1.
                /* 1060 */  0xE6, 0x03, 0xAA, 0x8F, 0x32, 0x6C, 0x7C, 0x2F,  // ....2l|/
                /* 1068 */  0x10, 0x3E, 0xC8, 0x3E, 0x04, 0x38, 0xF3, 0xAA,  // .>.>.8..
                /* 1070 */  0x75, 0xBD, 0xE1, 0x69, 0x61, 0xA4, 0xFC, 0x6A,  // u..ia..j
                /* 1078 */  0x8B, 0xD2, 0x7A, 0xB5, 0xA5, 0x20, 0x1E, 0x9D,  // ..z.. ..
                /* 1080 */  0xAF, 0x37, 0x00, 0x1F, 0x6E, 0x1D, 0x70, 0xFF,  // .7..n.p.
                /* 1088 */  0xFF, 0xB7, 0x0E, 0x30, 0x9D, 0x3E, 0x7D, 0x19,  // ...0.>}.
                /* 1090 */  0xE0, 0x07, 0x4F, 0x0E, 0x62, 0x40, 0x1F, 0x6C,  // ..O.b@.l
                /* 1098 */  0x01, 0x2F, 0xC7, 0x46, 0x5F, 0x19, 0xF0, 0xA7,  // ./.F_...
                /* 10A0 */  0x23, 0x76, 0xB9, 0xF7, 0xCD, 0xC2, 0x04, 0xAF,  // #v......
                /* 10A8 */  0xDC, 0x3E, 0x11, 0x82, 0xFB, 0xD0, 0x00, 0xAE,  // .>......
                /* 10B0 */  0x41, 0xC1, 0x1C, 0xC4, 0xB9, 0xF8, 0x66, 0xE6,  // A.....f.
                /* 10B8 */  0x41, 0x81, 0xFB, 0xF2, 0xE3, 0x41, 0x81, 0xED,  // A....A..
                /* 10C0 */  0xFF, 0x3F, 0x28, 0x18, 0xB0, 0x01, 0xDF, 0x0D,  // .?(.....
                /* 10C8 */  0x0E, 0x1C, 0x58, 0x5C, 0x71, 0x3C, 0x28, 0x60,  // ..X\q<(`
                /* 10D0 */  0x31, 0x70, 0x60, 0x71, 0x03, 0xF1, 0xA0, 0xC0,  // 1p`q....
                /* 10D8 */  0x75, 0xAE, 0xF4, 0xA0, 0x70, 0xC7, 0x0C, 0x8B,  // u...p...
                /* 10E0 */  0x04, 0xD4, 0x2D, 0xE4, 0xF9, 0xE4, 0xC4, 0x31,  // ..-....1
                /* 10E8 */  0xA3, 0x02, 0xBB, 0x87, 0x51, 0x01, 0x95, 0x99,  // ....Q...
                /* 10F0 */  0x63, 0x46, 0x05, 0x9E, 0xFF, 0xFF, 0xA8, 0x60,  // cF.....`
                /* 10F8 */  0xC1, 0x78, 0x54, 0xE0, 0xBA, 0x4F, 0x01, 0x6F,  // .xT..O.o
                /* 1100 */  0xAD, 0x0E, 0x0F, 0x9F, 0x60, 0xD3, 0x7A, 0x9F,  // ....`.z.
                /* 1108 */  0x42, 0x27, 0x7E, 0x58, 0xE8, 0xF0, 0xC9, 0xEE,  // B'~X....
                /* 1110 */  0x53, 0xB0, 0xF3, 0xDD, 0xA7, 0x50, 0xC9, 0x60,  // S....P.`
                /* 1118 */  0x74, 0x1C, 0xF5, 0x99, 0x87, 0x67, 0x39, 0xF3,  // t....g9.
                /* 1120 */  0x50, 0x10, 0x9B, 0xB8, 0x4F, 0x01, 0xC2, 0xFE,  // P...O...
                /* 1128 */  0xFF, 0xF7, 0x29, 0x60, 0x38, 0x68, 0x38, 0x27,  // ..)`8h8'
                /* 1130 */  0x22, 0xFC, 0xA0, 0xC1, 0x7A, 0x75, 0xE0, 0x83,  // "...zu..
                /* 1138 */  0x06, 0xCF, 0x94, 0x60, 0x1E, 0x3F, 0x30, 0x53,  // ...`.?0S
                /* 1140 */  0x02, 0xEB, 0x91, 0x09, 0x7C, 0x53, 0x82, 0x73,  // ....|S.s
                /* 1148 */  0x1C, 0xC2, 0x4F, 0x09, 0xAC, 0x17, 0x26, 0xF0,  // ..O...&.
                /* 1150 */  0xFD, 0xFF, 0xA7, 0x04, 0x73, 0xD4, 0xE0, 0x3F,  // ....s..?
                /* 1158 */  0x2F, 0x81, 0xEF, 0x92, 0xEB, 0x29, 0xE1, 0x0E,  // /....)..
                /* 1160 */  0xC2, 0x3E, 0x0B, 0xC1, 0x18, 0x13, 0x58, 0x8F,  // .>....X.
                /* 1168 */  0x4B, 0xE0, 0x1B, 0x13, 0xDC, 0x61, 0x83, 0xFF,  // K....a..
                /* 1170 */  0xB0, 0x04, 0xBE, 0x53, 0x2E, 0xB0, 0xFB, 0xFF,  // ...S....
                /* 1178 */  0x9F, 0x72, 0x81, 0x27, 0x8C, 0x4F, 0xB9, 0x80,  // .r.'.O..
                /* 1180 */  0xA7, 0x5B, 0x94, 0x4E, 0xB9, 0x20, 0x4B, 0xB3,  // .[.N. K.
                /* 1188 */  0x0E, 0xDD, 0xA2, 0xF8, 0x80, 0xAD, 0x09, 0x48,  // .......H
                /* 1190 */  0x23, 0x3B, 0x89, 0x88, 0xEF, 0xDB, 0x5D, 0xCF,  // #;....].
                /* 1198 */  0x4B, 0xE7, 0xA5, 0xCE, 0x11, 0x74, 0x93, 0x79,  // K....t.y
                /* 11A0 */  0x07, 0x30, 0xB4, 0x55, 0x00, 0xEA, 0x0E, 0xC5,  // .0.U....
                /* 11A8 */  0xF3, 0x93, 0x28, 0xFF, 0xB9, 0x00, 0x95, 0xF8,  // ..(.....
                /* 11B0 */  0x5C, 0x40, 0x41, 0x0C, 0xE8, 0x38, 0x27, 0x24,  // \@A..8'$
                /* 11B8 */  0xF4, 0x4E, 0x7C, 0xAD, 0x62, 0x08, 0x87, 0xC4,  // .N|.b...
                /* 11C0 */  0x06, 0x02, 0xE3, 0x9A, 0x04, 0xAE, 0xFF, 0xFF,  // ........
                /* 11C8 */  0x3D, 0x0A, 0x7B, 0x17, 0x07, 0x9C, 0x0F, 0xC6,  // =.{.....
                /* 11D0 */  0xD7, 0x0A, 0xC0, 0x93, 0x57, 0xA1, 0x16, 0x1D,  // ....W...
                /* 11D8 */  0x5E, 0x2B, 0xC0, 0x25, 0x68, 0x15, 0xBA, 0x56,  // ^+.%h..V
                /* 11E0 */  0xE0, 0x62, 0xAD, 0x45, 0x77, 0x71, 0xE6, 0x13,  // .b.Ewq..
                /* 11E8 */  0x5A, 0x18, 0x47, 0xF2, 0xFF, 0x3F, 0x8E, 0xC8,  // Z.G..?..
                /* 11F0 */  0x87, 0xFC, 0x02, 0x11, 0x26, 0xC4, 0x03, 0xA9,  // ....&...
                /* 11F8 */  0xAE, 0x15, 0xA8, 0x08, 0x14, 0x8A, 0x7E, 0x2E,  // ......~.
                /* 1200 */  0x40, 0x85, 0x1D, 0x3B, 0x05, 0x31, 0xA0, 0x93,  // @..;.1..
                /* 1208 */  0x5C, 0x2B, 0xD0, 0x5A, 0x40, 0x34, 0x0B, 0x9C,  // \+.Z@4..
                /* 1210 */  0xCE, 0x49, 0x68, 0x52, 0x3E, 0x54, 0x00, 0xBE,  // .IhR>T..
                /* 1218 */  0x62, 0x5C, 0xE3, 0x51, 0xC2, 0xAF, 0xF1, 0x14,  // b\.Q....
                /* 1220 */  0xC4, 0x13, 0xF3, 0xA1, 0x02, 0xF0, 0x72, 0xFC,  // ......r.
                /* 1228 */  0xF5, 0xB0, 0x70, 0x32, 0x6E, 0x38, 0x3E, 0x63,  // ..p2n8>c
                /* 1230 */  0x12, 0xD4, 0x83, 0x82, 0xFD, 0xFF, 0x3F, 0x8E,  // ......?.
                /* 1238 */  0x03, 0xAB, 0x83, 0x07, 0xF0, 0x96, 0xE8, 0x53,  // .......S
                /* 1240 */  0xEA, 0xA1, 0x15, 0x64, 0x62, 0x0E, 0x1E, 0xE8,  // ...db...
                /* 1248 */  0x48, 0x6B, 0xD1, 0xA1, 0x95, 0x1D, 0x3C, 0x60,  // Hk....<`
                /* 1250 */  0x85, 0x38, 0x78, 0xA0, 0xE4, 0x53, 0x48, 0xFE,  // .8x..SH.
                /* 1258 */  0xD9, 0x01, 0x25, 0xF8, 0xEC, 0x40, 0x41, 0x3C,  // ..%..@A<
                /* 1260 */  0x36, 0x1F, 0x3C, 0x00, 0x23, 0x21, 0x6E, 0x0E,  // 6.<.#!n.
                /* 1268 */  0x50, 0xFE, 0xFF, 0x37, 0x07, 0xDC, 0xA5, 0x15,  // P..7....
                /* 1270 */  0x98, 0x1D, 0x1C, 0xB0, 0xC7, 0x27, 0xC0, 0xE2,  // .....'..
                /* 1278 */  0xB1, 0x03, 0xD0, 0xE5, 0xF4, 0xD8, 0x01, 0xEB,  // ........
                /* 1280 */  0xFF, 0x7F, 0xEC, 0x80, 0xF5, 0xB2, 0xF4, 0xB1,  // ........
                /* 1288 */  0x83, 0x73, 0x38, 0xC6, 0x5F, 0x41, 0xC7, 0x27,  // .s8._A.'
                /* 1290 */  0x36, 0xA6, 0xEA, 0x07, 0x2C, 0x94, 0xE8, 0x1E,  // 6...,...
                /* 1298 */  0xC8, 0x1B, 0xE7, 0x73, 0x07, 0x46, 0x36, 0xA4,  // ...s.F6.
                /* 12A0 */  0x4E, 0x04, 0x3E, 0x71, 0x10, 0x18, 0xC9, 0x85,  // N.>q....
                /* 12A8 */  0xD0, 0xC1, 0x80, 0x0B, 0x84, 0xA3, 0x20, 0x1E,  // ...... .
                /* 12B0 */  0x91, 0x0F, 0x06, 0xC0, 0x91, 0xC0, 0x07, 0x03,  // ........
                /* 12B8 */  0xF0, 0x05, 0x3A, 0xAE, 0xA2, 0xC7, 0xEB, 0xC9,  // ..:.....
                /* 12C0 */  0xE2, 0xAF, 0x04, 0xB1, 0xC3, 0x44, 0x38, 0x35,  // .....D85
                /* 12C8 */  0x8F, 0xC8, 0x58, 0xCF, 0x4A, 0x60, 0x3F, 0xB3,  // ..X.J`?.
                /* 12D0 */  0x82, 0xEB, 0xCE, 0xE8, 0x81, 0xE1, 0x86, 0x61,  // .......a
                /* 12D8 */  0xAB, 0x63, 0xD2, 0xDC, 0xDF, 0x08, 0x3C, 0xB2,  // .c....<.
                /* 12E0 */  0xC8, 0x67, 0x73, 0x50, 0x81, 0x1F, 0x27, 0x1F,  // .gsP..'.
                /* 12E8 */  0x6C, 0x3D, 0x2E, 0x70, 0xFC, 0xFF, 0x0F, 0x1A,  // l=.p....
                /* 12F0 */  0xB0, 0xC7, 0x05, 0xAE, 0x13, 0x95, 0xAF, 0xD0,  // ........
                /* 12F8 */  0x78, 0xDC, 0xE3, 0x7A, 0x99, 0xC7, 0x0C, 0x0A,  // x..z....
                /* 1300 */  0xEC, 0x27, 0x71, 0xF0, 0x9D, 0x24, 0x7C, 0x3C,  // .'q..$|<
                /* 1308 */  0xF6, 0x49, 0x02, 0x77, 0x42, 0x3E, 0x95, 0x57,  // .I.wB>.W
                /* 1310 */  0xCF, 0xA7, 0x4F, 0xDF, 0x0F, 0xF8, 0x49, 0x02,  // ..O...I.
                /* 1318 */  0xEC, 0x77, 0x71, 0x9F, 0x24, 0xC0, 0x63, 0x4C,  // .wq.$.cL
                /* 1320 */  0x80, 0x36, 0x48, 0x12, 0xE5, 0xD8, 0x84, 0x86,  // .6H.....
                /* 1328 */  0xF6, 0xB0, 0xF8, 0xE0, 0x3D, 0x2A, 0xF0, 0x1F,  // ....=*..
                /* 1330 */  0xC7, 0x3D, 0x2A, 0xF8, 0xC7, 0x26, 0xCC, 0xFF,  // .=*..&..
                /* 1338 */  0xFF, 0xD8, 0xE4, 0x51, 0xC1, 0xBA, 0xF6, 0xFB,  // ...Q....
                /* 1340 */  0x08, 0xF1, 0xDE, 0xE4, 0x59, 0xB1, 0x51, 0x81,  // ....Y.Q.
                /* 1348 */  0xFB, 0xEE, 0xE4, 0x51, 0x81, 0xEF, 0xBA, 0x8B,  // ...Q....
                /* 1350 */  0x3F, 0xDD, 0xF8, 0x3C, 0x62, 0xC5, 0x88, 0xBA,  // ?..<b...
                /* 1358 */  0xD2, 0x18, 0xFE, 0x71, 0xD7, 0x07, 0xE1, 0x83,  // ...q....
                /* 1360 */  0x07, 0xFF, 0xA1, 0xDC, 0xE3, 0x02, 0xDF, 0xD1,  // ........
                /* 1368 */  0xC5, 0xE3, 0xC2, 0x8D, 0xC3, 0x83, 0xC7, 0x5C,  // .......\
                /* 1370 */  0x7D, 0xDE, 0x49, 0xD8, 0xA5, 0x38, 0xC8, 0x23,  // }.I..8.#
                /* 1378 */  0x09, 0xBB, 0x7E, 0x03, 0xBF, 0x81, 0xE1, 0xCF,  // ..~.....
                /* 1380 */  0x1B, 0x1E, 0x18, 0xEE, 0xBC, 0xE1, 0x39, 0xC4,  // ......9.
                /* 1388 */  0x3B, 0xF8, 0xF7, 0x3C, 0xA3, 0xD6, 0x8E, 0x41,  // ;..<...A
                /* 1390 */  0x86, 0xE5, 0xFF, 0xFF, 0xB0, 0xC0, 0x6C, 0x62,  // ......lb
                /* 1398 */  0x58, 0xA0, 0x3C, 0x70, 0x01, 0x71, 0x89, 0x16,  // X.<p.q..
                /* 13A0 */  0x8F, 0x8D, 0x20, 0x93, 0x73, 0x6C, 0x44, 0x71,  // .. .slDq
                /* 13A8 */  0x38, 0xD4, 0xB1, 0x11, 0x71, 0xE0, 0x82, 0x79,  // 8...q..y
                /* 13B0 */  0x6E, 0x04, 0xAC, 0xFD, 0xFF, 0xCF, 0x8D, 0x00,  // n.......
                /* 13B8 */  0xFF, 0xFF, 0xFF, 0xE7, 0x0E, 0x72, 0x6E, 0x04,  // .....rn.
                /* 13C0 */  0x99, 0xA8, 0x73, 0x07, 0x0A, 0xDC, 0xD1, 0xCE,  // ..s.....
                /* 13C8 */  0x1D, 0x10, 0x2F, 0x12, 0xB8, 0xA3, 0x07, 0xE0,  // ../.....
                /* 13D0 */  0x72, 0x52, 0xB8, 0xA3, 0x07, 0x30, 0x3D, 0xEB,  // rR...0=.
                /* 13D8 */  0x03, 0xA7, 0xA3, 0xC7, 0xFF, 0xFF, 0xD1, 0x03,  // ........
                /* 13E0 */  0xA0, 0x8A, 0xC9, 0xA3, 0x07, 0xD8, 0xC4, 0xAF,  // ........
                /* 13E8 */  0x82, 0x86, 0x86, 0x90, 0x5C, 0x18, 0xD4, 0xE9,  // ....\...
                /* 13F0 */  0xD1, 0x63, 0xC7, 0x8F, 0xE6, 0x60, 0x8E, 0x21,  // .c...`.!
                /* 13F8 */  0x38, 0x93, 0x04, 0x87, 0x1A, 0xA8, 0xA7, 0xFE,  // 8.......
                /* 1400 */  0x0A, 0x72, 0x1A, 0x8F, 0x1A, 0x3E, 0xA6, 0x1A,  // .r...>..
                /* 1408 */  0x92, 0x49, 0x1B, 0x22, 0xEA, 0x58, 0xE0, 0xB1,  // .I.".X..
                /* 1410 */  0xBE, 0x15, 0xF8, 0x96, 0x16, 0xF1, 0xA9, 0xC0,  // ........
                /* 1418 */  0xD7, 0x34, 0x0F, 0x91, 0xA3, 0xF1, 0xF3, 0x28,  // .4.....(
                /* 1420 */  0x83, 0xE6, 0xB7, 0x0B, 0xDF, 0x20, 0x5E, 0x03,  // ..... ^.
                /* 1428 */  0xFC, 0xFF, 0x9F, 0x9B, 0x09, 0xBA, 0x1F, 0xBA,  // ........
                /* 1430 */  0x14, 0x22, 0xE8, 0x04, 0xF0, 0x4E, 0x50, 0xA3,  // ."...NP.
                /* 1438 */  0x00, 0x6F, 0x57, 0x01, 0xD9, 0x3A, 0x81, 0x6A,  // .oW..:.j
                /* 1440 */  0xF4, 0xB1, 0xDE, 0x2E, 0xA3, 0x84, 0x88, 0x10,  // ........
                /* 1448 */  0x34, 0x8A, 0xF1, 0x22, 0x84, 0x0A, 0x11, 0x25,  // 4.."...%
                /* 1450 */  0x6A, 0x73, 0x20, 0xBA, 0x64, 0x46, 0x0D, 0x12,  // js .dF..
                /* 1458 */  0x2D, 0x98, 0x11, 0x98, 0xFD, 0x41, 0x10, 0xE9,  // -....A..
                /* 1460 */  0xCF, 0x00, 0xDD, 0x33, 0x1C, 0xE9, 0xE8, 0x07,  // ...3....
                /* 1468 */  0x65, 0xA8, 0x8F, 0x74, 0x3E, 0xB3, 0x18, 0xE4,  // e..t>...
                /* 1470 */  0x20, 0xCF, 0xED, 0x09, 0x05, 0x03, 0xAE, 0x33,  //  ......3
                /* 1478 */  0x04, 0xB4, 0x9B, 0x62, 0xC0, 0x57, 0x40, 0x8F,  // ...b.W@.
                /* 1480 */  0xD7, 0xDF, 0x19, 0xC3, 0xF1, 0x21, 0x7A, 0xA0,  // .....!z.
                /* 1488 */  0xE1, 0x4E, 0xE0, 0x10, 0x19, 0xA0, 0x0F, 0x11,  // .N......
                /* 1490 */  0xF0, 0xC7, 0xE3, 0x53, 0x1D, 0x4E, 0xFE, 0x20,  // ...S.N. 
                /* 1498 */  0x50, 0xE7, 0x4D, 0x3E, 0xD2, 0xD3, 0x7A, 0x92,  // P.M>..z.
                /* 14A0 */  0xF1, 0xD1, 0xCF, 0x04, 0x16, 0x7B, 0x76, 0xA0,  // .....{v.
                /* 14A8 */  0xE3, 0x01, 0xFF, 0xF9, 0xF2, 0x99, 0xE0, 0xC5,  // ........
                /* 14B0 */  0xD8, 0xD8, 0x3E, 0xB4, 0x38, 0xC2, 0x49, 0x04,  // ..>.8.I.
                /* 14B8 */  0x0D, 0x6D, 0xD0, 0xB3, 0xF1, 0x19, 0xC2, 0x37,  // .m.....7
                /* 14C0 */  0x0F, 0x76, 0xB4, 0xE0, 0xA2, 0x8E, 0x16, 0xA8,  // .v......
                /* 14C8 */  0xD3, 0x82, 0x0F, 0x0A, 0xEC, 0x18, 0xC4, 0x4F,  // .......O
                /* 14D0 */  0x16, 0xEC, 0x80, 0xE2, 0x43, 0x08, 0xD8, 0xFE,  // ....C...
                /* 14D8 */  0xFF, 0x04, 0xE5, 0x1D, 0x42, 0x40, 0x01, 0xE2,  // ....B@..
                /* 14E0 */  0x93, 0x05, 0x9B, 0x17, 0x86, 0xC0, 0xC7, 0xDB,  // ........
                /* 14E8 */  0xF0, 0x98, 0x43, 0x87, 0xE1, 0xF9, 0x29, 0xE1,  // ..C...).
                /* 14F0 */  0x71, 0x84, 0x61, 0xBF, 0x91, 0x78, 0x0A, 0x87,  // q.a..x..
                /* 14F8 */  0xE3, 0x23, 0x85, 0x11, 0x82, 0x97, 0x7B, 0xB2,  // .#....{.
                /* 1500 */  0x20, 0x9A, 0x47, 0xA7, 0x29, 0x9D, 0xF2, 0x21,  //  .G.)..!
                /* 1508 */  0xB0, 0xA1, 0x7A, 0x08, 0xFC, 0xBC, 0xE0, 0x21,  // ..z....!
                /* 1510 */  0xF0, 0x01, 0xBC, 0x67, 0x9F, 0x9D, 0xCF, 0x27,  // ...g...'
                /* 1518 */  0xE7, 0x84, 0x1B, 0x2F, 0x1F, 0x13, 0x76, 0x00,  // .../..v.
                /* 1520 */  0x3C, 0xC8, 0x23, 0xD5, 0x67, 0x11, 0x1A, 0x63,  // <.#.g..c
                /* 1528 */  0xF9, 0x3E, 0x8E, 0x00, 0x72, 0x4E, 0x23, 0x8F,  // .>..rN#.
                /* 1530 */  0x22, 0x8F, 0x04, 0xCF, 0x23, 0xBE, 0x89, 0xD8,  // "...#...
                /* 1538 */  0xDA, 0x35, 0x44, 0x23, 0x79, 0x2D, 0x38, 0xD5,  // .5D#y-8.
                /* 1540 */  0xE3, 0x8C, 0x62, 0xAC, 0x30, 0xA1, 0x0C, 0xF2,  // ..b.0...
                /* 1548 */  0x54, 0xF2, 0x28, 0x72, 0x52, 0x51, 0x8C, 0xF1,  // T.(rRQ..
                /* 1550 */  0x36, 0x12, 0xED, 0x1D, 0xDA, 0xA7, 0x13, 0x0F,  // 6.......
                /* 1558 */  0x3B, 0xE2, 0x09, 0xC4, 0x79, 0x1C, 0x61, 0x91,  // ;...y.a.
                /* 1560 */  0x1E, 0x0C, 0x1A, 0xAA, 0x8F, 0x23, 0x60, 0xFA,  // .....#`.
                /* 1568 */  0xFF, 0x1F, 0x47, 0x00, 0xEB, 0x47, 0x04, 0xDC,  // ..G..G..
                /* 1570 */  0x69, 0x03, 0x26, 0xCE, 0xEB, 0x85, 0x4F, 0x0E,  // i.&...O.
                /* 1578 */  0xFC, 0xAC, 0x01, 0x3C, 0x82, 0x3F, 0x0C, 0x34,  // ...<.?.4
                /* 1580 */  0x4A, 0x9F, 0x7C, 0x7C, 0x04, 0xE4, 0x23, 0x32,  // J.||..#2
                /* 1588 */  0x95, 0x8F, 0x80, 0x6C, 0x06, 0x4F, 0x51, 0xA1,  // ...l.OQ.
                /* 1590 */  0x9F, 0x12, 0xC2, 0xEA, 0xD0, 0x47, 0x81, 0x1D,  // .....G..
                /* 1598 */  0x99, 0x44, 0x47, 0x0C, 0x1F, 0xCE, 0x78, 0xCC,  // .DG...x.
                /* 15A0 */  0xC3, 0x0A, 0x05, 0x31, 0xA0, 0x33, 0x9C, 0x61,  // ...1.3.a
                /* 15A8 */  0xD0, 0x2A, 0x40, 0x34, 0x83, 0xB3, 0x39, 0x9E,  // .*@4..9.
                /* 15B0 */  0x87, 0x01, 0x1F, 0xEB, 0xE0, 0xFD, 0xFF, 0x0F,  // ........
                /* 15B8 */  0x7E, 0xC0, 0xE0, 0x80, 0x0A, 0x9C, 0xC2, 0x0F,  // ~.......
                /* 15C0 */  0x15, 0x15, 0x77, 0xA8, 0x14, 0xC4, 0x43, 0xF5,  // ..w...C.
                /* 15C8 */  0xD9, 0xDE, 0xA7, 0x1F, 0xFC, 0xA1, 0xC1, 0x07,  // ........
                /* 15D0 */  0x89, 0x27, 0x01, 0xCC, 0xA9, 0x0E, 0xDC, 0x27,  // .'.....'
                /* 15D8 */  0x20, 0x70, 0x9E, 0xEA, 0x80, 0xB7, 0x31, 0x8D,  //  p....1.
                /* 15E0 */  0x42, 0x0D, 0x9E, 0xEA, 0xC0, 0x75, 0x9A, 0x80,  // B....u..
                /* 15E8 */  0xF1, 0xFF, 0x3F, 0x4D, 0xE0, 0x10, 0x5E, 0xEE,  // ..?M..^.
                /* 15F0 */  0x9F, 0x26, 0x00, 0xBE, 0xFF, 0xFF, 0x4F, 0x13,  // .&....O.
                /* 15F8 */  0x60, 0xF4, 0x2A, 0xF4, 0x34, 0x01, 0x36, 0x85,  // `.*.4.6.
                /* 1600 */  0x36, 0x7D, 0x6A, 0x34, 0x6A, 0xD5, 0xA0, 0x4C,  // 6}j4j..L
                /* 1608 */  0x8D, 0x32, 0x0D, 0x6A, 0xF5, 0xA9, 0xD4, 0x98,  // .2.j....
                /* 1610 */  0xB1, 0x1A, 0x6B, 0x55, 0x8C, 0x83, 0x32, 0x15,  // ..kU..2.
                /* 1618 */  0xB1, 0x1C, 0x81, 0x58, 0x38, 0x85, 0x8C, 0x1C,  // ...X8...
                /* 1620 */  0xCE, 0x0C, 0x22, 0x20, 0xCB, 0x38, 0xF9, 0x08,  // .." .8..
                /* 1628 */  0xC8, 0xA2, 0x40, 0x04, 0xE4, 0x48, 0x16, 0x80,  // ..@..H..
                /* 1630 */  0x58, 0x3E, 0x10, 0x01, 0x39, 0xCF, 0xDF, 0x41,  // X>..9..A
                /* 1638 */  0x40, 0x4E, 0x07, 0x22, 0x20, 0x2B, 0x5B, 0xA3,  // @N." +[.
                /* 1640 */  0x80, 0x2C, 0x13, 0x44, 0x40, 0xCE, 0x06, 0x44,  // .,.D@..D
                /* 1648 */  0x83, 0x02, 0xD1, 0x50, 0x26, 0x80, 0x58, 0x44,  // ...P&.XD
                /* 1650 */  0x10, 0x01, 0x59, 0xDC, 0xD3, 0x42, 0x40, 0x96,  // ..Y..B@.
                /* 1658 */  0x0A, 0x22, 0x20, 0x07, 0x5D, 0xA3, 0x80, 0x9C,  // ." .]...
                /* 1660 */  0x1A, 0x44, 0x40, 0x96, 0xFA, 0x92, 0x12, 0x90,  // .D@.....
                /* 1668 */  0x75, 0x83, 0x08, 0xC8, 0x69, 0x81, 0x68, 0x74,  // u...i.ht
                /* 1670 */  0x20, 0x1A, 0xD3, 0x06, 0x10, 0x0B, 0x0D, 0x22,  //  ......"
                /* 1678 */  0x20, 0x0B, 0xF6, 0x01, 0xC4, 0xD4, 0x83, 0x08,  //  .......
                /* 1680 */  0xC8, 0x91, 0x81, 0x68, 0x7E, 0x20, 0x9A, 0xF5,  // ...h~ ..
                /* 1688 */  0x61, 0x20, 0x20, 0x27, 0x07, 0x11, 0x90, 0x35,  // a  '...5
                /* 1690 */  0xD3, 0x08, 0xC8, 0x09, 0x28, 0x04, 0xE4, 0xFC,  // ....(...
                /* 1698 */  0x4A, 0x80, 0x98, 0x98, 0x97, 0x84, 0x80, 0x9C,  // J.......
                /* 16A0 */  0x00, 0x44, 0x40, 0x8E, 0x03, 0x44, 0x45, 0xBC,  // .D@..DE.
                /* 16A8 */  0xE5, 0x04, 0x64, 0x45, 0x20, 0x02, 0x72, 0x7A,  // ..dE .rz
                /* 16B0 */  0x20, 0xAA, 0xC5, 0xCA, 0xD1, 0x9B, 0x3E, 0xBB,  //  .....>.
                /* 16B8 */  0x05, 0xE4, 0x58, 0x20, 0x02, 0xB2, 0x16, 0x2F,  // ..X .../
                /* 16C0 */  0x40, 0x4C, 0x18, 0x88, 0x06, 0x40, 0x5E, 0x06,  // @L...@^.
                /* 16C8 */  0x02, 0xB2, 0x24, 0x10, 0x01, 0x39, 0x1A, 0x10,  // ..$..9..
                /* 16D0 */  0x0D, 0x2A, 0xE6, 0xFF, 0x0F, 0xC4, 0x44, 0x7E,  // .*....D~
                /* 16D8 */  0x49, 0x04, 0x64, 0xC5, 0x20, 0x1A, 0x28, 0x01,  // I.d. .(.
                /* 16E0 */  0xA2, 0x99, 0x81, 0xA8, 0x54, 0x37, 0x83, 0xA6,  // ....T7..
                /* 16E8 */  0x20, 0x02, 0x72, 0x76, 0x20, 0x2A, 0xE4, 0x91,  //  .rv *..
                /* 16F0 */  0x21, 0x20, 0x67, 0x06, 0x11, 0x90, 0x15, 0xD8,  // ! g.....
                /* 16F8 */  0x01, 0x62, 0xDA, 0xF5, 0x00, 0xB1, 0x20, 0x20,  // .b....  
                /* 1700 */  0x02, 0xB2, 0x64, 0x3F, 0x40, 0x2C, 0x00, 0x88,  // ..d?@,..
                /* 1708 */  0x80, 0x1C, 0xFD, 0x44, 0xA3, 0x01, 0x10, 0x43,  // ...D...C
                /* 1710 */  0x40, 0x2C, 0x02, 0x88, 0x80, 0x1C, 0x08, 0x88,  // @,......
                /* 1718 */  0x0A, 0x71, 0x04, 0xC4, 0x54, 0x81, 0x68, 0xE0,  // .q..T.h.
                /* 1720 */  0x04, 0x88, 0xAA, 0x79, 0x19, 0x6A, 0xB0, 0xC4,  // ...y.j..
                /* 1728 */  0x12, 0x10, 0xCB, 0x05, 0x22, 0x20, 0x2B, 0xD2,  // ...." +.
                /* 1730 */  0x04, 0xC4, 0xF4, 0x81, 0x08, 0xC8, 0xC9, 0x3C,  // .......<
                /* 1738 */  0x01, 0xB1, 0x98, 0x20, 0x3A, 0x40, 0x90, 0xF7,  // ... :@..
                /* 1740 */  0xA7, 0x80, 0x1C, 0x10, 0x44, 0x07, 0x06, 0xA2,  // ....D...
                /* 1748 */  0xEA, 0xC0, 0x40, 0x41, 0x34, 0x58, 0x02, 0x44,  // ..@A4X.D
                /* 1750 */  0x43, 0x03, 0x51, 0xB1, 0x0F, 0x0D, 0x01, 0x59,  // C.Q....Y
                /* 1758 */  0x39, 0x88, 0x0E, 0x0C, 0x04, 0x88, 0x46, 0x07,  // 9.....F.
                /* 1760 */  0xA2, 0x7A, 0x9F, 0x84, 0x81, 0x88, 0x78, 0x10,  // .z....x.
                /* 1768 */  0x01, 0x39, 0x30, 0x10, 0x4D, 0x0F, 0x44, 0x45,  // .90.M.DE
                /* 1770 */  0x3F, 0x70, 0x74, 0x50, 0x20, 0x20, 0x1A, 0x04,  // ?ptP  ..
                /* 1778 */  0xF1, 0x05, 0xC4, 0xA4, 0x83, 0x08, 0xC8, 0xA1,  // ........
                /* 1780 */  0xDF, 0x2A, 0x02, 0xB2, 0x84, 0x97, 0x9A, 0x0E,  // .*......
                /* 1788 */  0x1C, 0x04, 0x44, 0x07, 0x0E, 0x02, 0x44, 0xE3,  // ..D...D.
                /* 1790 */  0x03, 0x51, 0x31, 0x5F, 0x15, 0x0D, 0x9C, 0x80,  // .Q1_....
                /* 1798 */  0x68, 0xE0, 0x04, 0x88, 0x4A, 0x79, 0xB1, 0x3C,  // h...Jy.<
                /* 17A0 */  0x28, 0x30, 0x10, 0x0D, 0x94, 0x00, 0xD1, 0x80,  // (0......
                /* 17A8 */  0x40, 0x54, 0xDF, 0xEB, 0x31, 0x10, 0x11, 0x0B,  // @T..1...
                /* 17B0 */  0x22, 0x20, 0x67, 0x04, 0xA2, 0x81, 0x81, 0x68,  // " g....h
                /* 17B8 */  0xB2, 0xF7, 0x63, 0x20, 0x92, 0x53, 0xDB, 0xFF,  // ..c .S..
                /* 17C0 */  0x1F, 0x88, 0xE9, 0xFC, 0x40, 0x06, 0x22, 0xAA,  // ....@.".
                /* 17C8 */  0x41, 0x04, 0xE4, 0xBC, 0x40, 0x34, 0x3D, 0x10,  // A...@4=.
                /* 17D0 */  0x55, 0xFD, 0x9E, 0x0C, 0x44, 0x32, 0x80, 0xE8,  // U...D2..
                /* 17D8 */  0xC0, 0x40, 0xD4, 0x1D, 0x10, 0xA8, 0xBB, 0x41,  // .@.....A
                /* 17E0 */  0x52, 0x10, 0x0D, 0x92, 0xBC, 0x61, 0x05, 0x64,  // R....a.d
                /* 17E8 */  0xF9, 0x20, 0x02, 0x72, 0x18, 0x20, 0x2A, 0xE4,  // . .r. *.
                /* 17F0 */  0x63, 0x24, 0x20, 0xCB, 0x02, 0xD1, 0xE0, 0x08,  // c$ .....
                /* 17F8 */  0x10, 0x0D, 0x08, 0x44, 0xC5, 0xF9, 0x3B, 0x14,  // ...D..;.
                /* 1800 */  0x50, 0x10, 0x01, 0x39, 0xE4, 0x3B, 0x47, 0x40,  // P..9.;G@
                /* 1808 */  0x4E, 0x0C, 0xA2, 0xC1, 0x91, 0xFF, 0xCD, 0xC1,  // N.......
                /* 1810 */  0x31, 0x10, 0x0D, 0x94, 0x3C, 0x37, 0x03, 0x11,  // 1...<7..
                /* 1818 */  0xB5, 0x20, 0x02, 0x72, 0x4A, 0x20, 0x9A, 0x19,  // . .rJ ..
                /* 1820 */  0x88, 0x6A, 0x7D, 0xF1, 0x3C, 0x20, 0x30, 0x10,  // .j}.< 0.
                /* 1828 */  0x1D, 0x2C, 0xC8, 0x4F, 0x48, 0x40, 0x7E, 0x02,  // .,.OH@~.
                /* 1830 */  0x19, 0xC8, 0x49, 0x41, 0x04, 0xE4, 0xDC, 0x40,  // ..IA...@
                /* 1838 */  0x54, 0xB1, 0x47, 0x20, 0xA6, 0x1F, 0x44, 0x40,  // T.G ..D@
                /* 1840 */  0xCE, 0x0D, 0x44, 0x55, 0xBC, 0x16, 0x75, 0xC8,  // ..DU..u.
                /* 1848 */  0x20, 0x0F, 0x46, 0x1D, 0x32, 0x08, 0x88, 0x0E,  //  .F.2...
                /* 1850 */  0x06, 0x04, 0x88, 0x6A, 0x51, 0x39, 0x60, 0x0A,  // ...jQ9`.
                /* 1858 */  0xA2, 0x01, 0x13, 0x97, 0x40, 0x4C, 0xFA, 0x87,  // ....@L..
                /* 1860 */  0x28, 0x30, 0x03, 0xD1, 0x29, 0x88, 0xFC, 0x80,  // (0..)...
                /* 1868 */  0x02, 0x11, 0x39, 0x20, 0x02, 0x72, 0x0C, 0x20,  // ..9 .r. 
                /* 1870 */  0x1A, 0x0A, 0x88, 0x6A, 0xF1, 0x79, 0x48, 0xA0,  // ...j.yH.
                /* 1878 */  0x20, 0x02, 0x72, 0x1C, 0x20, 0x9A, 0x0D, 0x88,  //  .r. ...
                /* 1880 */  0x86, 0x78, 0x21, 0x05, 0x22, 0x91, 0x40, 0x74,  // .x!.".@t
                /* 1888 */  0x09, 0x23, 0x2F, 0xA4, 0x40, 0x44, 0x1A, 0x88,  // .#/.@D..
                /* 1890 */  0x0E, 0x01, 0x04, 0x88, 0x06, 0x04, 0xA2, 0xC2,  // ........
                /* 1898 */  0x3E, 0x4A, 0x3A, 0xF4, 0x10, 0x10, 0x1D, 0x34,  // >J:....4
                /* 18A0 */  0xC8, 0x73, 0xE9, 0xC0, 0x19, 0x88, 0x80, 0x9C,  // .s......
                /* 18A8 */  0xF0, 0x17, 0x1C, 0x88, 0xE4, 0xB5, 0xFA, 0xFF,  // ........
                /* 18B0 */  0x07, 0x62, 0xBA, 0xDF, 0x4A, 0x81, 0x48, 0x0A,  // .b..J.H.
                /* 18B8 */  0x10, 0x1D, 0x0E, 0xC8, 0x6B, 0xEA, 0x81, 0x84,  // ....k...
                /* 18C0 */  0x81, 0x08, 0xC8, 0x1A, 0xD4, 0x1E, 0x68, 0x28,  // ......h(
                /* 18C8 */  0x88, 0x0E, 0x42, 0xC4, 0x2D, 0x10, 0x4B, 0x0A,  // ..B.-.K.
                /* 18D0 */  0xA2, 0x83, 0x06, 0xB1, 0x7B, 0x18, 0xA0, 0x20,  // ....{.. 
                /* 18D8 */  0x3A, 0x44, 0x10, 0xBD, 0x87, 0x08, 0x0A, 0xA2,  // :D......
                /* 18E0 */  0x03, 0x0A, 0xF9, 0x51, 0x3D, 0xA0, 0xB0, 0xB7,  // ...Q=...
                /* 18E8 */  0x94, 0x80, 0x9C, 0xE6, 0xE1, 0x76, 0xA0, 0x0C,  // .....v..
                /* 18F0 */  0x44, 0x40, 0xD6, 0xF6, 0x10, 0x16, 0x90, 0x95,  // D@......
                /* 18F8 */  0x82, 0xE8, 0x60, 0x40, 0xDE, 0x4F, 0x3A, 0x18,  // ..`@.O:.
                /* 1900 */  0x10, 0x10, 0x0D, 0x8C, 0xBC, 0xE2, 0x0E, 0x8C,  // ........
                /* 1908 */  0x81, 0x08, 0xC8, 0x2A, 0xBE, 0x71, 0x02, 0xB2,  // ...*.q..
                /* 1910 */  0x26, 0x10, 0x01, 0x39, 0xD3, 0xD3, 0x2A, 0x10,  // &..9..*.
                /* 1918 */  0x49, 0x08, 0xA2, 0x83, 0x03, 0x51, 0x7D, 0x70,  // I....Q}p
                /* 1920 */  0xA0, 0x20, 0x3A, 0x10, 0x91, 0x27, 0x6E, 0x20,  // . :..'n 
                /* 1928 */  0x12, 0x1C, 0x44, 0x83, 0x26, 0xAF, 0x62, 0x1D,  // ..D.&.b.
                /* 1930 */  0x56, 0x08, 0x88, 0x0E, 0x45, 0xE4, 0x51, 0xA7,  // V...E.Q.
                /* 1938 */  0x83, 0x0D, 0x01, 0x11, 0x90, 0xE5, 0xFE, 0xB5,  // ........
                /* 1940 */  0x1E, 0x54, 0x18, 0x88, 0x0E, 0x08, 0xE4, 0x9D,  // .T......
                /* 1948 */  0xA6, 0x03, 0x02, 0x01, 0x11, 0x90, 0x63, 0x19,  // ......c.
                /* 1950 */  0x07, 0x62, 0x19, 0x41, 0x04, 0x64, 0x81, 0xDF,  // .b.A.d..
                /* 1958 */  0x65, 0x0D, 0x86, 0x80, 0x68, 0x90, 0xE4, 0xD9,  // e...h...
                /* 1960 */  0x76, 0x90, 0x0C, 0x44, 0x87, 0x10, 0xF2, 0x60,  // v..D...`
                /* 1968 */  0x13, 0x90, 0xC3, 0x83, 0x08, 0xC8, 0xCA, 0xDF,  // ........
                /* 1970 */  0x68, 0x0F, 0x2B, 0x0C, 0x44, 0x87, 0x17, 0xF2,  // h.+.D...
                /* 1978 */  0x74, 0x16, 0x90, 0x23, 0x80, 0x08, 0xC8, 0x3A,  // t..#...:
                /* 1980 */  0xC4, 0x1F, 0xB8, 0x28, 0x88, 0x80, 0x2C, 0xE1,  // ...(..,.
                /* 1988 */  0x45, 0x2C, 0x20, 0x0B, 0x02, 0xD1, 0x21, 0x8B,  // E, ...!.
                /* 1990 */  0x00, 0xD1, 0x88, 0x40, 0x54, 0xE1, 0x13, 0x3A,  // ...@T..:
                /* 1998 */  0x10, 0x91, 0x0B, 0xA2, 0x43, 0x08, 0x79, 0x07,  // ....C.y.
                /* 19A0 */  0xEB, 0x10, 0x42, 0x40, 0x04, 0xE4, 0xB0, 0x40,  // ..B@...@
                /* 19A8 */  0x34, 0x3A, 0x10, 0xD5, 0xAE, 0xFF, 0x60, 0x41,  // 4:....`A
                /* 19B0 */  0xF5, 0xFF, 0xFF, 0x81, 0x98, 0x6C, 0xFF, 0x40,  // .....l.@
                /* 19B8 */  0x2C, 0x04, 0x88, 0x0E, 0x0C, 0x24, 0xC0, 0xE1,  // ,....$..
                /* 19C0 */  0x84, 0x82, 0x08, 0xC8, 0xB9, 0x0A, 0x00, 0xB1,  // ........
                /* 19C8 */  0x90, 0x20, 0x02, 0xB2, 0xCA, 0x04, 0x40, 0x4C,  // . ....@L
                /* 19D0 */  0x32, 0x88, 0x06, 0x4C, 0x1A, 0x0C, 0x88, 0x82,  // 2..L....
                /* 19D8 */  0x08, 0xC8, 0xC9, 0x9F, 0xF9, 0x02, 0xB2, 0x8C,  // ........
                /* 19E0 */  0x0A, 0x07, 0x0F, 0x0A, 0xA2, 0x83, 0x07, 0x79,  // .......y
                /* 19E8 */  0x3C, 0xEA, 0x90, 0x43, 0x3A, 0x1C, 0x72, 0x28,  // <..C:.r(
                /* 19F0 */  0x88, 0x0E, 0x1C, 0xA4, 0xC4, 0x81, 0x83, 0x82,  // ........
                /* 19F8 */  0xE8, 0xA0, 0x40, 0x52, 0x1C, 0x14, 0x28, 0x88,  // ..@R..(.
                /* 1A00 */  0x0E, 0x03, 0xA4, 0xC5, 0x61, 0x80, 0x82, 0x08,  // ....a...
                /* 1A08 */  0xC8, 0xD2, 0x62, 0x00, 0x31, 0x9D, 0x20, 0x02,  // ..b.1. .
                /* 1A10 */  0xB2, 0xAA, 0x1A, 0x40, 0x4C, 0x23, 0x88, 0x0E,  // ...@L#..
                /* 1A18 */  0x10, 0x24, 0xC7, 0x01, 0x82, 0x82, 0xE8, 0x50,  // .$.....P
                /* 1A20 */  0x42, 0x82, 0x00, 0xB1, 0x1C, 0x20, 0x3A, 0xA0,  // B.... :.
                /* 1A28 */  0x10, 0x20, 0xAA, 0xA5, 0xC8, 0xE0, 0x28, 0x88,  // . ....(.
                /* 1A30 */  0x80, 0xAC, 0x23, 0x09, 0x10, 0xCB, 0xD0, 0x64,  // ..#....d
                /* 1A38 */  0x60, 0x14, 0x44, 0x40, 0x56, 0xFF, 0x60, 0x14,  // `.D@V.`.
                /* 1A40 */  0x90, 0xB3, 0x80, 0x68, 0x60, 0xA4, 0xCA, 0xC0,  // ...h`...
                /* 1A48 */  0x28, 0x88, 0x80, 0x9C, 0x08, 0x88, 0xE6, 0x03,  // (.......
                /* 1A50 */  0xA2, 0xDA, 0xB2, 0x1C, 0x18, 0x28, 0x88, 0x0E,  // .....(..
                /* 1A58 */  0x36, 0x04, 0x88, 0x66, 0x06, 0xA2, 0x7A, 0xC3,  // 6..f..z.
                /* 1A60 */  0x1C, 0x24, 0x28, 0x88, 0x80, 0x9C, 0x18, 0x88,  // .$(.....
                /* 1A68 */  0xC6, 0x07, 0xA2, 0xC2, 0xCB, 0x1C, 0x36, 0x28,  // ......6(
                /* 1A70 */  0x88, 0x06, 0x47, 0x80, 0xA8, 0x96, 0x34, 0x03,  // ..G...4.
                /* 1A78 */  0xA3, 0x20, 0x1A, 0x18, 0x01, 0xA2, 0xF2, 0xDB,  // . ......
                /* 1A80 */  0x1C, 0x86, 0x28, 0x88, 0x0E, 0x2E, 0xA4, 0x0E,  // ..(.....
                /* 1A88 */  0x10, 0x53, 0x06, 0xA2, 0x43, 0x0C, 0x01, 0xA2,  // .S..C...
                /* 1A90 */  0xD9, 0x80, 0x68, 0x92, 0x3C, 0x07, 0x30, 0x9A,  // ..h.<.0.
                /* 1A98 */  0xE7, 0xFF, 0x0F, 0xC4, 0x34, 0xF5, 0x01, 0x62,  // ....4..b
                /* 1AA0 */  0x0A, 0x41, 0x74, 0x50, 0x21, 0x40, 0x34, 0x29,  // .AtP!@4)
                /* 1AA8 */  0x10, 0xD5, 0x18, 0xE8, 0xE0, 0x46, 0x41, 0x74,  // .....FAt
                /* 1AB0 */  0x08, 0x21, 0x40, 0x34, 0x39, 0x10, 0x55, 0x5D,  // .!@49.U]
                /* 1AB8 */  0xE8, 0xE0, 0x44, 0x41, 0x74, 0x58, 0x21, 0x40,  // ..DAtX!@
                /* 1AC0 */  0x54, 0x4D, 0x22, 0x20, 0x96, 0xA5, 0x11, 0x10,  // TM" ....
                /* 1AC8 */  0x0B, 0x06, 0x22, 0x20, 0xAB, 0x79, 0xD8, 0xEB,  // .." .y..
                /* 1AD0 */  0x80, 0x43, 0x40, 0x74, 0x40, 0x21, 0x40, 0x34,  // .C@t@!@4
                /* 1AD8 */  0x20, 0x10, 0x15, 0x56, 0x09, 0x88, 0xA9, 0x04,  //  ..V....
                /* 1AE0 */  0x11, 0x90, 0xD3, 0x01, 0xD1, 0xA8, 0x40, 0x54,  // ......@T
                /* 1AE8 */  0x62, 0x26, 0x20, 0xA6, 0x17, 0x44, 0x07, 0x44,  // b& ..D.D
                /* 1AF0 */  0x02, 0x44, 0x53, 0x03, 0x51, 0xB9, 0x9D, 0x80,  // .DS.Q...
                /* 1AF8 */  0x98, 0x76, 0x10, 0x01, 0x59, 0x68, 0x28, 0x20,  // .v..Yh( 
                /* 1B00 */  0x26, 0x1B, 0x44, 0x07, 0x3A, 0x52, 0xEA, 0xB0,  // &.D.:R..
                /* 1B08 */  0x40, 0x53, 0x01, 0xB1, 0xD4, 0x20, 0x02, 0xB2,  // @S... ..
                /* 1B10 */  0x86, 0x56, 0x07, 0x0B, 0x1A, 0x0B, 0x88, 0xE5,  // .V......
                /* 1B18 */  0x01, 0xD1, 0x81, 0x81, 0xD4, 0x3A, 0x30, 0x50,  // .....:0P
                /* 1B20 */  0x10, 0x1D, 0x18, 0x48, 0xAE, 0x03, 0x03, 0x05,  // ...H....
                /* 1B28 */  0xD1, 0x81, 0x88, 0xF4, 0x3A, 0x30, 0x50, 0x10,  // ....:0P.
                /* 1B30 */  0x01, 0x59, 0x56, 0xB0, 0x43, 0x05, 0x05, 0xD1,  // .YV.C...
                /* 1B38 */  0xC1, 0x8E, 0x14, 0x3B, 0xD8, 0x51, 0x10, 0x1D,  // ...;.Q..
                /* 1B40 */  0x88, 0x48, 0xB2, 0x03, 0x11, 0x05, 0xD1, 0x81,  // .H......
                /* 1B48 */  0x86, 0x34, 0x3B, 0xBC, 0x51, 0x10, 0x01, 0x59,  // .4;.Q..Y
                /* 1B50 */  0x41, 0x34, 0x20, 0xA6, 0x07, 0x44, 0x87, 0x03,  // A4 ..D..
                /* 1B58 */  0x02, 0x44, 0x73, 0x01, 0x51, 0x4D, 0xD5, 0x0E,  // .Ds.QM..
                /* 1B60 */  0x07, 0x14, 0x44, 0x03, 0x27, 0x40, 0x34, 0x2B,  // ..D.'@4+
                /* 1B68 */  0x10, 0xD5, 0x99, 0xED, 0x40, 0x44, 0x41, 0x34,  // ....@DA4
                /* 1B70 */  0x50, 0x02, 0x44, 0x35, 0x74, 0x03, 0x62, 0x29,  // P.D5t.b)
                /* 1B78 */  0x40, 0x04, 0xE4, 0x4C, 0xDD, 0xFE, 0xFF, 0x03,  // @..L....
                /* 1B80 */  0xA3, 0xE1, 0x06, 0x46, 0x41, 0x04, 0xE4, 0x80,  // ...FA...
                /* 1B88 */  0xE5, 0x80, 0x58, 0x5A, 0x10, 0x1D, 0x1C, 0x49,  // ..XZ...I
                /* 1B90 */  0xBA, 0x03, 0x03, 0x05, 0xD1, 0x41, 0x88, 0xB4,  // .....A..
                /* 1B98 */  0x3B, 0xEC, 0x50, 0x10, 0x1D, 0x54, 0x48, 0xBC,  // ;.P..TH.
                /* 1BA0 */  0x03, 0x23, 0xAD, 0x77, 0xC0, 0xA0, 0x20, 0x3A,  // .#.w.. :
                /* 1BA8 */  0x60, 0x10, 0x20, 0xAA, 0x39, 0xDF, 0x40, 0x29,  // `. .9.@)
                /* 1BB0 */  0x88, 0x0E, 0x26, 0x24, 0xE0, 0xD0, 0x68, 0x41,  // ..&$..hA
                /* 1BB8 */  0x20, 0x0A, 0x42, 0x55, 0x46, 0x3C, 0xDC, 0x51,  //  .BUF<.Q
                /* 1BC0 */  0x10, 0x2A, 0x22, 0xE3, 0x71, 0x8A, 0x82, 0xE8,  // .*".q...
                /* 1BC8 */  0xB8, 0x49, 0x80, 0xA8, 0x96, 0x8E, 0xC7, 0x0D,  // .I......
                /* 1BD0 */  0x1A, 0xF2, 0x58, 0x40, 0x41, 0x74, 0x74, 0x22,  // ..X@Att"
                /* 1BD8 */  0x25, 0x87, 0x43, 0x41, 0x04, 0xE4, 0xFF, 0x3F   // %.CA...?
            })
            Name (EPY1, 0x92A1BB7B)
            Name (EPY2, 0x6F20A74A)
            Name (EPY3, 0x901F0CFB)
            Name (EPY4, 0x201A56B4)
            Method (EYPO, 0, Serialized)
            {
                Return (EPY1) /* \RMTW.EPY1 */
            }

            Method (EYPT, 0, Serialized)
            {
                Return (EPY2) /* \RMTW.EPY2 */
            }

            Method (EYPE, 0, Serialized)
            {
                Return (EPY3) /* \RMTW.EPY3 */
            }

            Method (EYPF, 0, Serialized)
            {
                Return (EPY4) /* \RMTW.EPY4 */
            }

            Name (RAMA, 0x719AAE98)
            Name (WBUF, Buffer (0x0100){})
            OperationRegion (\RAMX, SystemMemory, RAMA, 0x0200)
            Field (RAMX, ByteAcc, NoLock, Preserve)
            {
                WFUN,   32, 
                WSIZ,   32, 
                Offset (0x10), 
                IDAT,   896, 
                Offset (0x80), 
                ODAT,   2048
            }

            Mutex (WMTX, 0x00)
            Name (LSTF, Buffer (0x04){})
            Name (LSTI, Buffer (0x70){})
            Name (CURF, Buffer (0x04){})
            Name (CURI, Buffer (0x70){})
            Method (WMII, 0, Serialized)
            {
                CURF = WFUN /* \RMTW.WFUN */
                CURI = IDAT /* \RMTW.IDAT */
                If (((CURF == LSTF) && (CURI == LSTI)))
                {
                    Return (Zero)
                }
                Else
                {
                    ODAT = Zero
                    \_SB.ISMI (0xDA)
                    LSTF = WFUN /* \RMTW.WFUN */
                    LSTI = IDAT /* \RMTW.IDAT */
                }
            }

            Method (LERR, 1, Serialized)
            {
                WBUF = ODAT /* \RMTW.ODAT */
                Return (DerefOf (WBUF [Zero]))
            }

            Method (GBOD, 1, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x80000001
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (SBOD, 1, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x80000002
                    IDAT = Arg0
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (GBON, 1, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x80000003
                    IDAT = Arg0
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (GLBN, 1, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x80000006
                    IDAT = Arg0
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (ISLG, 1, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x80000007
                    IDAT = Arg0
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (GLBO, 1, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x80000008
                    IDAT = Arg0
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (SLBO, 1, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x80000009
                    IDAT = Arg0
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (SAPW, 1, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x80000004
                    IDAT = Arg0
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (SUPW, 1, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x80000005
                    IDAT = Arg0
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (SBOG, 1, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x8000000A
                    IDAT = Arg0
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (LDFT, 0, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x8000000B
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (SFTB, 1, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x8000000C
                    IDAT = Arg0
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (SDFT, 1, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x8000000D
                    IDAT = Arg0
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (SFTM, 0, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x8000000E
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (DCTL, 1, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x8000000F
                    IDAT = Arg0
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (GFAN, 1, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x80000010
                    IDAT = Arg0
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (SFAN, 1, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x80000011
                    IDAT = Arg0
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (GFCV, 1, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x80000012
                    IDAT = Arg0
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (SFCV, 1, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x80000013
                    IDAT = Arg0
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (CKPW, 1, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x80000014
                    IDAT = Arg0
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (GTOD, 1, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x80000015
                    IDAT = Arg0
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (STOD, 1, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x80000016
                    IDAT = Arg0
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (AAPD, 1, Serialized)
            {
                Return (Zero)
            }

            Method (GEDD, 0, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x80000017
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (SEDD, 1, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x80000018
                    IDAT = Arg0
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            Method (SEID, 1, Serialized)
            {
                If ((Acquire (WMTX, 0xFFFF) == Zero))
                {
                    WFUN = 0x80000019
                    IDAT = Arg0
                    WMII ()
                    WBUF = ODAT /* \RMTW.ODAT */
                    Release (WMTX)
                    Return (WBUF) /* \RMTW.WBUF */
                }

                Return (Ones)
            }

            OperationRegion (DEB0, SystemIO, 0x80, One)
            Field (DEB0, ByteAcc, NoLock, Preserve)
            {
                DBG8,   8
            }

            OperationRegion (IOB2, SystemIO, SMIP, 0x02)
            Field (IOB2, ByteAcc, NoLock, Preserve)
            {
                SMPT,   8, 
                SMIS,   8
            }

            Method (ISMI, 1, Serialized)
            {
                SMPT = Arg0
            }

            Method (SWMI, 0, Serialized)
            {
                ISMI (0x96)
            }

            Method (APF1, 1, Serialized)
            {
                MBIF = 0x80000004
                MBDA = Arg0
                SWMI ()
                Return (WSTA) /* \RMTW.WSTA */
            }

            Method (APPW, 1, Serialized)
            {
                MBIF = 0x80000008
                MBDA = Arg0
                SWMI ()
                Return (WSTA) /* \RMTW.WSTA */
            }

            Name (AMSB, 0x712D4018)
            OperationRegion (\ACCX, SystemMemory, AMSB, 0x0100)
            Field (ACCX, ByteAcc, NoLock, Preserve)
            {
                MBSI,   32, 
                MBIF,   32, 
                WSTA,   32, 
                MBDA,   1952
            }

            Method (DEVS, 1, Serialized)
            {
                CreateDWordField (Arg0, Zero, DVID)
                CreateDWordField (Arg0, 0x04, CPAR)
                Switch (DVID)
                {
                    Case (Zero)
                    {
                        Return (Zero)
                    }
                    Default
                    {
                        Return (Zero)
                    }

                }
            }

            Method (DSTS, 1, Serialized)
            {
                CreateDWordField (Arg0, Zero, DVID)
                Switch (DVID)
                {
                    Case (0xA0000000)
                    {
                        Local0 = 0x09
                    }
                    Case (Zero)
                    {
                        Return (Zero)
                    }
                    Default
                    {
                        Local0 = Zero
                    }

                }

                Local0 &= 0x0007FFFF
                Return (Local0)
            }

            Method (WMBD, 3, Serialized)
            {
                Local0 = One
                Switch (Arg1)
                {
                    Case (0x424D5352)
                    {
                        Return (RSMB (Arg2))
                    }
                    Case (0x424D5357)
                    {
                        Return (WSMB (Arg2))
                    }
                    Case (0x574D5352)
                    {
                        Return (RSMW (Arg2))
                    }
                    Case (0x574D5357)
                    {
                        Return (WSMW (Arg2))
                    }
                    Case (0x4B4D5352)
                    {
                        Return (RSMK (Arg2))
                    }
                    Case (0x4B4D5357)
                    {
                        Return (WSMK (Arg2))
                    }
                    Case (0x52494F42)
                    {
                        Return (RIOB (Arg2))
                    }
                    Case (0x57494F42)
                    {
                        Return (WIOB (Arg2))
                    }
                    Case (0x52494F57)
                    {
                        Return (RIOW (Arg2))
                    }
                    Case (0x57494F57)
                    {
                        Return (WIOW (Arg2))
                    }
                    Case (0x52494F44)
                    {
                        Return (RIOD (Arg2))
                    }
                    Case (0x57494F44)
                    {
                        Return (WIOD (Arg2))
                    }
                    Case (0x52504349)
                    {
                        Return (RPCI (Arg2))
                    }
                    Case (0x57504349)
                    {
                        Return (WPCI (Arg2))
                    }
                    Case (0x52494458)
                    {
                        Return (RIDX (Arg2))
                    }
                    Case (0x57494458)
                    {
                        Return (WIDX (Arg2))
                    }
                    Case (0x52444D52)
                    {
                        Return (RDMR (Arg2))
                    }
                    Case (0x57524D52)
                    {
                        Return (WRMR (Arg2))
                    }
                    Case (0x52434944)
                    {
                        Return (RCID (Arg2))
                    }
                    Case (0x52444543)
                    {
                        Return (RDEC (Arg2))
                    }
                    Case (0x57524543)
                    {
                        Return (WREC (Arg2))
                    }
                    Case (0x5253494F)
                    {
                        Return (RSIO (Arg2))
                    }
                    Case (0x5753494F)
                    {
                        Return (WSIO (Arg2))
                    }
                    Case (0x5248574D)
                    {
                        Return (RHWM (Arg2))
                    }
                    Case (0x5748574D)
                    {
                        Return (WHWM (Arg2))
                    }
                    Case (0x4252494F)
                    {
                        Return (BRIO (Arg2))
                    }
                    Case (0x4257494F)
                    {
                        Return (BWIO (Arg2))
                    }
                    Case (0x4252484D)
                    {
                        Return (BRHM (Arg2))
                    }
                    Case (0x4257484D)
                    {
                        Return (BWHM (Arg2))
                    }
                    Case (0x42524543)
                    {
                        Return (BREC (Arg2))
                    }
                    Case (0x42574543)
                    {
                        Return (BWEC (Arg2))
                    }
                    Default
                    {
                        Return (Zero)
                    }

                }

                Return (Local0)
            }

            Mutex (ASMX, 0x00)
            Method (RIOB, 1, Serialized)
            {
                If ((Acquire (ASMX, 0xFFFF) == Zero))
                {
                    CreateWordField (Arg0, Zero, W_PT)
                    OperationRegion (TMIO, SystemIO, W_PT, One)
                    Field (TMIO, ByteAcc, NoLock, Preserve)
                    {
                        PT08,   8
                    }

                    Local0 = PT08 /* \RMTW.RIOB.PT08 */
                    Release (ASMX)
                    Return (Local0)
                }

                Return (Ones)
            }

            Method (WIOB, 1, Serialized)
            {
                If ((Acquire (ASMX, 0xFFFF) == Zero))
                {
                    CreateWordField (Arg0, Zero, W_PT)
                    CreateByteField (Arg0, 0x02, B_DT)
                    OperationRegion (TMIO, SystemIO, W_PT, One)
                    Field (TMIO, ByteAcc, NoLock, Preserve)
                    {
                        PT08,   8
                    }

                    PT08 = B_DT /* \RMTW.WIOB.B_DT */
                    Release (ASMX)
                }

                Return (Ones)
            }

            Method (RIOW, 1, Serialized)
            {
                If ((Acquire (ASMX, 0xFFFF) == Zero))
                {
                    CreateWordField (Arg0, Zero, W_PT)
                    OperationRegion (TMIO, SystemIO, W_PT, 0x02)
                    Field (TMIO, WordAcc, NoLock, Preserve)
                    {
                        PT16,   16
                    }

                    Local0 = PT16 /* \RMTW.RIOW.PT16 */
                    Release (ASMX)
                    Return (Local0)
                }

                Return (Ones)
            }

            Method (WIOW, 1, Serialized)
            {
                If ((Acquire (ASMX, 0xFFFF) == Zero))
                {
                    CreateWordField (Arg0, Zero, W_PT)
                    CreateWordField (Arg0, 0x02, W_DT)
                    OperationRegion (TMIO, SystemIO, W_PT, 0x02)
                    Field (TMIO, WordAcc, NoLock, Preserve)
                    {
                        PT16,   16
                    }

                    PT16 = W_DT /* \RMTW.WIOW.W_DT */
                    Release (ASMX)
                }

                Return (Ones)
            }

            Method (RIOD, 1, Serialized)
            {
                If ((Acquire (ASMX, 0xFFFF) == Zero))
                {
                    CreateWordField (Arg0, Zero, W_PT)
                    OperationRegion (TMIO, SystemIO, W_PT, 0x04)
                    Field (TMIO, DWordAcc, NoLock, Preserve)
                    {
                        PT32,   32
                    }

                    Local0 = PT32 /* \RMTW.RIOD.PT32 */
                    Release (ASMX)
                    Return (Local0)
                }

                Return (Ones)
            }

            Method (WIOD, 1, Serialized)
            {
                If ((Acquire (ASMX, 0xFFFF) == Zero))
                {
                    CreateWordField (Arg0, Zero, W_PT)
                    CreateDWordField (Arg0, 0x02, D_DT)
                    OperationRegion (TMIO, SystemIO, W_PT, 0x04)
                    Field (TMIO, DWordAcc, NoLock, Preserve)
                    {
                        PT32,   32
                    }

                    PT32 = D_DT /* \RMTW.WIOD.D_DT */
                    Release (ASMX)
                }

                Return (Ones)
            }

            Method (RPCI, 1, Serialized)
            {
                If ((Acquire (ASMX, 0xFFFF) == Zero))
                {
                    CreateByteField (Arg0, Zero, TBUS)
                    CreateByteField (Arg0, One, TDEV)
                    CreateByteField (Arg0, 0x02, TFUN)
                    CreateWordField (Arg0, 0x04, TREG)
                    CreateByteField (Arg0, 0x06, W_SZ)
                    Local0 = TBUS /* \RMTW.RPCI.TBUS */
                    Local0 <<= 0x05
                    Local0 += TDEV /* \RMTW.RPCI.TDEV */
                    Local0 <<= 0x03
                    Local0 += TFUN /* \RMTW.RPCI.TFUN */
                    Local0 <<= 0x0C
                    Local0 += TREG /* \RMTW.RPCI.TREG */
                    Local0 += PEBS /* \PEBS */
                    OperationRegion (PCFG, SystemMemory, Local0, 0x04)
                    Field (PCFG, ByteAcc, NoLock, Preserve)
                    {
                        BCFG,   8
                    }

                    Field (PCFG, WordAcc, NoLock, Preserve)
                    {
                        WCFG,   16
                    }

                    Field (PCFG, DWordAcc, NoLock, Preserve)
                    {
                        XCFG,   32
                    }

                    Local0 = Zero
                    Switch (ToInteger (W_SZ))
                    {
                        Case (One)
                        {
                            Local0 = BCFG /* \RMTW.RPCI.BCFG */
                        }
                        Case (0x02)
                        {
                            Local0 = WCFG /* \RMTW.RPCI.WCFG */
                        }
                        Case (0x04)
                        {
                            Local0 = XCFG /* \RMTW.RPCI.XCFG */
                        }
                        Default
                        {
                            Local0 = Ones
                        }

                    }

                    Release (ASMX)
                    Return (Local0)
                }

                Return (Ones)
            }

            Method (WPCI, 1, Serialized)
            {
                If ((Acquire (ASMX, 0xFFFF) == Zero))
                {
                    CreateByteField (Arg0, Zero, TBUS)
                    CreateByteField (Arg0, One, TDEV)
                    CreateByteField (Arg0, 0x02, TFUN)
                    CreateWordField (Arg0, 0x04, TREG)
                    CreateByteField (Arg0, 0x06, W_SZ)
                    CreateDWordField (Arg0, 0x08, TDAT)
                    Local0 = TBUS /* \RMTW.WPCI.TBUS */
                    Local0 <<= 0x05
                    Local0 += TDEV /* \RMTW.WPCI.TDEV */
                    Local0 <<= 0x03
                    Local0 += TFUN /* \RMTW.WPCI.TFUN */
                    Local0 <<= 0x0C
                    Local0 += TREG /* \RMTW.WPCI.TREG */
                    Local0 += PEBS /* \PEBS */
                    OperationRegion (PCFG, SystemMemory, Local0, 0x04)
                    Field (PCFG, ByteAcc, NoLock, Preserve)
                    {
                        BCFG,   8
                    }

                    Field (PCFG, WordAcc, NoLock, Preserve)
                    {
                        WCFG,   16
                    }

                    Field (PCFG, DWordAcc, NoLock, Preserve)
                    {
                        XCFG,   32
                    }

                    Local0 = Zero
                    Switch (ToInteger (W_SZ))
                    {
                        Case (One)
                        {
                            BCFG = TDAT /* \RMTW.WPCI.TDAT */
                        }
                        Case (0x02)
                        {
                            WCFG = TDAT /* \RMTW.WPCI.TDAT */
                        }
                        Case (0x04)
                        {
                            XCFG = TDAT /* \RMTW.WPCI.TDAT */
                        }
                        Default
                        {
                            Local0 = Ones
                        }

                    }

                    Release (ASMX)
                    Return (Local0)
                }

                Return (Ones)
            }

            Method (RIDX, 1, Serialized)
            {
                If ((Acquire (ASMX, 0xFFFF) == Zero))
                {
                    CreateWordField (Arg0, Zero, W_PT)
                    CreateByteField (Arg0, 0x02, W_ID)
                    OperationRegion (TMIO, SystemIO, W_PT, 0x02)
                    Field (TMIO, ByteAcc, NoLock, Preserve)
                    {
                        IDXP,   8, 
                        DATP,   8
                    }

                    IDXP = ToInteger (W_ID)
                    Local0 = DATP /* \RMTW.RIDX.DATP */
                    Release (ASMX)
                    Return (Local0)
                }

                Return (Ones)
            }

            Method (WIDX, 1, Serialized)
            {
                If ((Acquire (ASMX, 0xFFFF) == Zero))
                {
                    CreateWordField (Arg0, Zero, W_PT)
                    CreateByteField (Arg0, 0x02, W_ID)
                    CreateByteField (Arg0, 0x03, W_DT)
                    OperationRegion (TMIO, SystemIO, W_PT, 0x02)
                    Field (TMIO, ByteAcc, NoLock, Preserve)
                    {
                        IDXP,   8, 
                        DATP,   8
                    }

                    IDXP = ToInteger (W_ID)
                    DATP = W_DT /* \RMTW.WIDX.W_DT */
                    Release (ASMX)
                    Return (Zero)
                }

                Return (Ones)
            }

            Name (RGBF, Buffer (0x10){})
            CreateDWordField (RGBF, Zero, REAX)
            CreateDWordField (RGBF, 0x04, REBX)
            CreateDWordField (RGBF, 0x08, RECX)
            CreateDWordField (RGBF, 0x0C, REDX)
            Name (MRBF, Buffer (0x08){})
            CreateDWordField (MRBF, Zero, MEDX)
            CreateDWordField (MRBF, 0x04, MEAX)
            Method (RDMR, 1, Serialized)
            {
                If ((Acquire (ASMX, 0xFFFF) == Zero))
                {
                    CreateDWordField (Arg0, Zero, W_ID)
                    RGBF = \_SB.GMSR (W_ID)
                    MEDX = REDX /* \RMTW.REDX */
                    MEAX = REAX /* \RMTW.REAX */
                    Release (ASMX)
                    Return (MRBF) /* \RMTW.MRBF */
                }

                Return (Ones)
            }

            Method (WRMR, 1, Serialized)
            {
                If ((Acquire (ASMX, 0xFFFF) == Zero))
                {
                    CreateDWordField (Arg0, Zero, W_ID)
                    CreateDWordField (Arg0, 0x04, W_HI)
                    CreateDWordField (Arg0, 0x08, W_LW)
                    RECX = W_ID /* \RMTW.WRMR.W_ID */
                    REDX = W_HI /* \RMTW.WRMR.W_HI */
                    REAX = W_LW /* \RMTW.WRMR.W_LW */
                    Local0 = \_SB.SMSR (RGBF)
                    Release (ASMX)
                    Return (Local0)
                }

                Return (Ones)
            }

            Method (RCID, 1, Serialized)
            {
                If ((Acquire (ASMX, 0xFFFF) == Zero))
                {
                    CreateDWordField (Arg0, Zero, W_ID)
                    RGBF = \_SB.GCID (W_ID)
                    Release (ASMX)
                    Return (RGBF) /* \RMTW.RGBF */
                }

                Return (Ones)
            }

            Method (RDEC, 1, Serialized)
            {
                Return (Ones)
                Return (Ones)
            }

            Method (WREC, 1, Serialized)
            {
                Return (Ones)
                Return (Ones)
            }

            Method (RSIO, 1, Serialized)
            {
                If ((Acquire (ASMX, 0xFFFF) == Zero))
                {
                    CreateByteField (Arg0, Zero, W_LN)
                    CreateByteField (Arg0, One, W_ID)
                    Local0 = Ones
                    If ((Acquire (\_SB.PCI0.SBRG.SIO1.MUT0, 0xFFFF) == Zero))
                    {
                        \_SB.PCI0.SBRG.SIO1.ENFG (W_LN)
                        \_SB.PCI0.SBRG.SIO1.INDX = W_ID /* \RMTW.RSIO.W_ID */
                        Local0 = \_SB.PCI0.SBRG.SIO1.DATA
                        \_SB.PCI0.SBRG.SIO1.EXFG ()
                    }

                    Release (ASMX)
                    Return (Local0)
                }

                Return (Ones)
            }

            Method (WSIO, 1, Serialized)
            {
                If ((Acquire (ASMX, 0xFFFF) == Zero))
                {
                    CreateByteField (Arg0, Zero, W_LN)
                    CreateByteField (Arg0, One, W_ID)
                    CreateByteField (Arg0, 0x02, W_DT)
                    Local0 = Ones
                    If ((Acquire (\_SB.PCI0.SBRG.SIO1.MUT0, 0xFFFF) == Zero))
                    {
                        \_SB.PCI0.SBRG.SIO1.ENFG (W_LN)
                        \_SB.PCI0.SBRG.SIO1.INDX = W_ID /* \RMTW.WSIO.W_ID */
                        \_SB.PCI0.SBRG.SIO1.DATA = W_DT /* \RMTW.WSIO.W_DT */
                        \_SB.PCI0.SBRG.SIO1.EXFG ()
                    }

                    Release (ASMX)
                    Return (Local0)
                }

                Return (Ones)
            }

            IndexField (\_SB.PCI0.SBRG.SIO1.INDX, \_SB.PCI0.SBRG.SIO1.DATA, ByteAcc, NoLock, Preserve)
            {
                Offset (0x28), 
                    ,   4, 
                HMLK,   1
            }

            Name (LCKS, Zero)
            Method (RHWM, 1, Serialized)
            {
                If ((Acquire (ASMX, 0xFFFF) == Zero))
                {
                    CreateByteField (Arg0, Zero, W_BK)
                    CreateByteField (Arg0, One, W_ID)
                    OperationRegion (SHWM, SystemIO, IOHW, 0x0A)
                    Field (SHWM, ByteAcc, NoLock, Preserve)
                    {
                        Offset (0x05), 
                        HIDX,   8, 
                        HDAT,   8
                    }

                    IndexField (HIDX, HDAT, ByteAcc, Lock, Preserve)
                    {
                        Offset (0x4E), 
                        BANK,   4
                    }

                    \_SB.PCI0.SBRG.SIO1.ENFG (0x07)
                    LCKS = HMLK /* \RMTW.HMLK */
                    HMLK = Zero
                    BANK = W_BK /* \RMTW.RHWM.W_BK */
                    HIDX = W_ID /* \RMTW.RHWM.W_ID */
                    Local0 = HDAT /* \RMTW.RHWM.HDAT */
                    HMLK = LCKS /* \RMTW.LCKS */
                    \_SB.PCI0.SBRG.SIO1.EXFG ()
                    Release (ASMX)
                    Return (Local0)
                }

                Return (Ones)
            }

            Method (WHWM, 1, Serialized)
            {
                If ((Acquire (ASMX, 0xFFFF) == Zero))
                {
                    CreateByteField (Arg0, Zero, W_BK)
                    CreateByteField (Arg0, One, W_ID)
                    CreateByteField (Arg0, 0x02, W_DT)
                    OperationRegion (SHWM, SystemIO, IOHW, 0x0A)
                    Field (SHWM, ByteAcc, NoLock, Preserve)
                    {
                        Offset (0x05), 
                        HIDX,   8, 
                        HDAT,   8
                    }

                    IndexField (HIDX, HDAT, ByteAcc, Lock, Preserve)
                    {
                        Offset (0x4E), 
                        BANK,   4
                    }

                    \_SB.PCI0.SBRG.SIO1.ENFG (0x07)
                    LCKS = HMLK /* \RMTW.HMLK */
                    HMLK = Zero
                    BANK = W_BK /* \RMTW.WHWM.W_BK */
                    HIDX = W_ID /* \RMTW.WHWM.W_ID */
                    HDAT = W_DT /* \RMTW.WHWM.W_DT */
                    HMLK = LCKS /* \RMTW.LCKS */
                    \_SB.PCI0.SBRG.SIO1.EXFG ()
                    Release (ASMX)
                    Return (Zero)
                }

                Return (Ones)
            }

            Method (ATOH, 1, Serialized)
            {
                Local0 = Ones
                If (((Arg0 >= 0x61) && (Arg0 <= 0x66)))
                {
                    Local0 = (Arg0 - 0x57)
                }

                If (((Arg0 >= 0x41) && (Arg0 <= 0x46)))
                {
                    Local0 = (Arg0 - 0x37)
                }

                If (((Arg0 >= 0x30) && (Arg0 <= 0x39)))
                {
                    Local0 = (Arg0 - 0x30)
                }

                Return (Local0)
            }

            Method (HTOA, 1, Serialized)
            {
                Local0 = Ones
                If (((Arg0 >= Zero) && (Arg0 <= 0x09)))
                {
                    Local0 = (Arg0 + 0x30)
                }

                If (((Arg0 >= 0x0A) && (Arg0 <= 0x0F)))
                {
                    Local0 = (Arg0 - 0x0A)
                    Local0 += 0x41
                }

                Return (Local0)
            }

            Name (STRB, Buffer (0x0100){})
            Name (HEXB, Buffer (0x0100){})
            Method (STOH, 1, Serialized)
            {
                STRB = Arg0
                CreateByteField (Arg0, Zero, DCNT)
                DCNT >>= 0x02
                Local0 = Zero
                While ((Local0 < DCNT))
                {
                    Local1 = ((0x04 * Local0) + 0x02)
                    Local2 = (Local1 + 0x02)
                    Local3 = ATOH (DerefOf (STRB [Local1]))
                    Local3 <<= 0x04
                    Local3 += ATOH (DerefOf (STRB [Local2]))
                    HEXB [Local0] = Local3
                    Local0++
                }

                Return (HEXB) /* \RMTW.HEXB */
            }

            Method (HTOS, 2, Serialized)
            {
                HEXB = Arg0
                STRB [Zero] = (Arg1 << 0x02)
                STRB [One] = Zero
                Local0 = Zero
                While ((Local0 < Arg1))
                {
                    Local3 = DerefOf (HEXB [Local0])
                    Local4 = (Local3 >> 0x04)
                    Local4 &= 0x0F
                    Local3 &= 0x0F
                    Local1 = ((0x04 * Local0) + 0x02)
                    Local2 = (Local1 + 0x02)
                    STRB [Local1] = HTOA (Local4)
                    Local1++
                    STRB [Local1] = Zero
                    STRB [Local2] = HTOA (Local3)
                    Local2++
                    STRB [Local2] = Zero
                    Local0++
                }

                Return (STRB) /* \RMTW.STRB */
            }

            Name (IDBF, Buffer (0x60){})
            Name (OSBF, Buffer (0x82){})
            Name (ODBF, Buffer (0x20){})
            Name (B_CT, Zero)
            Name (B_BK, Zero)
            Name (B_ID, Zero)
            Name (B_DT, Zero)
            Method (BRIO, 1, Serialized)
            {
                CreateByteField (Arg0, Zero, WLEN)
                B_CT = (WLEN >> 0x02)
                If ((B_CT > 0x20))
                {
                    Return (Ones)
                }

                If ((Acquire (ASMX, 0xFFFF) == Zero))
                {
                    IDBF = STOH (Arg0)
                    \_SB.PCI0.SBRG.SIO1.ENFG (0x07)
                    Local0 = Zero
                    Local1 = Zero
                    While ((Local0 < B_CT))
                    {
                        B_BK = DerefOf (IDBF [Local0])
                        Local0++
                        B_ID = DerefOf (IDBF [Local0])
                        Local0++
                        \_SB.PCI0.SBRG.SIO1.LDN = B_BK /* \RMTW.B_BK */
                        \_SB.PCI0.SBRG.SIO1.INDX = B_ID /* \RMTW.B_ID */
                        ODBF [Local1] = \_SB.PCI0.SBRG.SIO1.DATA
                        Local1++
                    }

                    \_SB.PCI0.SBRG.SIO1.EXFG ()
                    OSBF = HTOS (ODBF, Local1)
                    Release (ASMX)
                    Return (OSBF) /* \RMTW.OSBF */
                }

                Return (Ones)
            }

            Method (BWIO, 1, Serialized)
            {
                CreateByteField (Arg0, Zero, WLEN)
                B_CT = (WLEN >> 0x02)
                If ((B_CT > 0x20))
                {
                    Return (Ones)
                }

                If ((Acquire (ASMX, 0xFFFF) == Zero))
                {
                    IDBF = STOH (Arg0)
                    \_SB.PCI0.SBRG.SIO1.ENFG (0x07)
                    Local0 = Zero
                    While ((Local0 < B_CT))
                    {
                        B_BK = DerefOf (IDBF [Local0])
                        Local0++
                        B_ID = DerefOf (IDBF [Local0])
                        Local0++
                        B_DT = DerefOf (IDBF [Local0])
                        Local0++
                        \_SB.PCI0.SBRG.SIO1.LDN = B_BK /* \RMTW.B_BK */
                        \_SB.PCI0.SBRG.SIO1.INDX = B_ID /* \RMTW.B_ID */
                        \_SB.PCI0.SBRG.SIO1.DATA = B_DT /* \RMTW.B_DT */
                    }

                    \_SB.PCI0.SBRG.SIO1.EXFG ()
                    Release (ASMX)
                    Return (Zero)
                }

                Return (Ones)
            }

            Method (BRHM, 1, Serialized)
            {
                CreateByteField (Arg0, Zero, WLEN)
                B_CT = (WLEN >> 0x02)
                If ((B_CT > 0x20))
                {
                    Return (Ones)
                }

                If ((Acquire (ASMX, 0xFFFF) == Zero))
                {
                    IDBF = STOH (Arg0)
                    OperationRegion (SHWM, SystemIO, IOHW, 0x0A)
                    Field (SHWM, ByteAcc, NoLock, Preserve)
                    {
                        Offset (0x05), 
                        HIDX,   8, 
                        HDAT,   8
                    }

                    IndexField (HIDX, HDAT, ByteAcc, Lock, Preserve)
                    {
                        Offset (0x4E), 
                        BANK,   4
                    }

                    \_SB.PCI0.SBRG.SIO1.ENFG (0x07)
                    LCKS = HMLK /* \RMTW.HMLK */
                    HMLK = Zero
                    Local0 = Zero
                    Local1 = Zero
                    While ((Local0 < B_CT))
                    {
                        B_BK = DerefOf (IDBF [Local0])
                        Local0++
                        B_ID = DerefOf (IDBF [Local0])
                        Local0++
                        BANK = B_BK /* \RMTW.B_BK */
                        HIDX = B_ID /* \RMTW.B_ID */
                        ODBF [Local1] = HDAT /* \RMTW.BRHM.HDAT */
                        Local1++
                    }

                    HMLK = LCKS /* \RMTW.LCKS */
                    \_SB.PCI0.SBRG.SIO1.EXFG ()
                    OSBF = HTOS (ODBF, Local1)
                    Release (ASMX)
                    Return (OSBF) /* \RMTW.OSBF */
                }

                Return (Ones)
            }

            Method (BWHM, 1, Serialized)
            {
                CreateByteField (Arg0, Zero, WLEN)
                B_CT = (WLEN >> 0x02)
                If ((B_CT > 0x20))
                {
                    Return (Ones)
                }

                If ((Acquire (ASMX, 0xFFFF) == Zero))
                {
                    IDBF = STOH (Arg0)
                    OperationRegion (SHWM, SystemIO, IOHW, 0x0A)
                    Field (SHWM, ByteAcc, NoLock, Preserve)
                    {
                        Offset (0x05), 
                        HIDX,   8, 
                        HDAT,   8
                    }

                    IndexField (HIDX, HDAT, ByteAcc, Lock, Preserve)
                    {
                        Offset (0x4E), 
                        BANK,   4
                    }

                    \_SB.PCI0.SBRG.SIO1.ENFG (0x07)
                    LCKS = HMLK /* \RMTW.HMLK */
                    HMLK = Zero
                    Local0 = Zero
                    While ((Local0 < B_CT))
                    {
                        B_BK = DerefOf (IDBF [Local0])
                        Local0++
                        B_ID = DerefOf (IDBF [Local0])
                        Local0++
                        B_DT = DerefOf (IDBF [Local0])
                        Local0++
                        BANK = B_BK /* \RMTW.B_BK */
                        HIDX = B_ID /* \RMTW.B_ID */
                        HDAT = B_DT /* \RMTW.B_DT */
                    }

                    HMLK = LCKS /* \RMTW.LCKS */
                    \_SB.PCI0.SBRG.SIO1.EXFG ()
                    Release (ASMX)
                    Return (Zero)
                }

                Return (Ones)
            }

            Name (ECBK, Zero)
            Method (BREC, 1, Serialized)
            {
                Return (Ones)
                Return (Ones)
            }

            Method (BWEC, 1, Serialized)
            {
                Return (Ones)
                Return (Ones)
            }

            Method (RSMB, 1, Serialized)
            {
                Return (Zero)
            }

            Method (WSMB, 1, Serialized)
            {
                Return (Zero)
            }

            Method (RSMW, 1, Serialized)
            {
                Return (Zero)
            }

            Method (WSMW, 1, Serialized)
            {
                Return (Zero)
            }

            Method (RSMK, 1, Serialized)
            {
                Return (Zero)
            }

            Method (WSMK, 1, Serialized)
            {
                Return (Zero)
            }
        }
    }

    Scope (_SB.PCI0.SBRG.EC0)
    {
        Name (DOSS, 0xFF)
        Name (SMUV, 0x04)
        Name (MLBS, 0xFFFF)
        Name (SMNI, 0xF8)
        Name (SMND, 0xFC)
        Name (PCOR, 0xFF)
        Name (NTRD, 0x20)
        Name (CCD0, Package (0x08)
        {
            One, 
            One, 
            One, 
            One, 
            One, 
            One, 
            One, 
            One
        })
        Name (CCD1, Package (0x08)
        {
            One, 
            One, 
            One, 
            One, 
            One, 
            One, 
            One, 
            One
        })
        Name (C0SA, Package (0x08)
        {
            Zero, 
            One, 
            0x02, 
            0x03, 
            0x04, 
            0x05, 
            0x06, 
            0x07
        })
        Name (C1SA, Package (0x08)
        {
            Zero, 
            One, 
            0x02, 
            0x03, 
            0x04, 
            0x05, 
            0x06, 
            0x07
        })
        Name (C0HI, Package (0x08)
        {
            One, 
            One, 
            One, 
            One, 
            One, 
            One, 
            One, 
            One
        })
        Name (C1HI, Package (0x08)
        {
            One, 
            One, 
            One, 
            One, 
            One, 
            One, 
            One, 
            One
        })
        Name (C0LO, Package (0x08)
        {
            One, 
            One, 
            One, 
            One, 
            One, 
            One, 
            One, 
            One
        })
        Name (C1LO, Package (0x08)
        {
            One, 
            One, 
            One, 
            One, 
            One, 
            One, 
            One, 
            One
        })
        Name (TPKG, Package (0x08)
        {
            One, 
            One, 
            One, 
            One, 
            One, 
            One, 
            One, 
            One
        })
        Name (C0SZ, Zero)
        Name (C1SZ, Zero)
        Name (MCC0, 0xFF)
        Name (MCC1, 0xFF)
        Name (XCC0, One)
        Name (XCC1, One)
        Name (SWST, Zero)
        Name (EPPA, Zero)
        Name (WRBF, Buffer (0x10)
        {
            /* 0000 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
            /* 0008 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   // ........
        })
        Name (SLBF, Buffer (0x10)
        {
            /* 0000 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
            /* 0008 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   // ........
        })
        Name (BASE, 0xFFFFFFFF)
        Name (TRES, 0x042E)
        Name (HYST, 0x04)
        Name (HCNT, Zero)
        Name (INI0, Zero)
        Name (TRS1, 0x0000)
        Name (HYS1, 0x03)
        Name (HCT1, Zero)
        Name (INI2, Zero)
        Name (ASPO, 0xFFFF)
        Name (ASCI, 0xFFFFFFFE)
        Name (PO00, 0xFFFF)
        Name (CI00, 0xFFFFFFFE)
        Name (PO01, 0xFFFF)
        Name (CI01, 0xFFFFFFFE)
        Name (PO02, 0xFFFF)
        Name (CI02, 0xFFFFFFFE)
        Name (PO03, 0xFFFF)
        Name (CI03, 0xFFFFFFFE)
        Name (PO04, 0xFFFF)
        Name (CI04, 0xFFFFFFFE)
        Name (PO05, 0xFFFF)
        Name (CI05, 0xFFFFFFFE)
        Name (PO06, 0xFFFF)
        Name (CI06, 0xFFFFFFFE)
        Name (PO07, 0xFFFF)
        Name (CI07, 0xFFFFFFFE)
        Name (PO08, 0xFFFF)
        Name (CI08, 0xFFFFFFFE)
        Name (PO09, 0xFFFF)
        Name (CI09, 0xFFFFFFFE)
        Name (PO10, 0xFFFF)
        Name (CI10, 0xFFFFFFFE)
        Name (PO11, 0xFFFF)
        Name (CI11, 0xFFFFFFFE)
        Name (PO12, 0xFFFF)
        Name (CI12, 0xFFFFFFFE)
        Name (PO13, 0xFFFF)
        Name (CI13, 0xFFFFFFFE)
        Name (PO14, 0xFFFF)
        Name (CI14, 0xFFFFFFFE)
        Name (PO15, 0xFFFF)
        Name (CI15, 0xFFFFFFFE)
        Name (PO16, 0xFFFF)
        Name (CI16, 0xFFFFFFFE)
        Name (PO17, 0xFFFF)
        Name (CI17, 0xFFFFFFFE)
        Name (PO18, 0xFFFF)
        Name (CI18, 0xFFFFFFFE)
        Name (PO19, 0xFFFF)
        Name (CI19, 0xFFFFFFFE)
        Name (PO20, 0xFFFF)
        Name (CI20, 0xFFFFFFFE)
        Name (PO21, 0xFFFF)
        Name (CI21, 0xFFFFFFFE)
        Name (PO22, 0xFFFF)
        Name (CI22, 0xFFFFFFFE)
        Name (PO23, 0xFFFF)
        Name (CI23, 0xFFFFFFFE)
        Name (PO24, 0xFFFF)
        Name (CI24, 0xFFFFFFFE)
        Name (PO25, 0xFFFF)
        Name (CI25, 0xFFFFFFFE)
        Name (PO26, 0xFFFF)
        Name (CI26, 0xFFFFFFFE)
        Name (PO27, 0xFFFF)
        Name (CI27, 0xFFFFFFFE)
        Name (PO28, 0xFFFF)
        Name (CI28, 0xFFFFFFFE)
        Name (PO29, 0xFFFF)
        Name (CI29, 0xFFFFFFFE)
        Name (PO30, 0xFFFF)
        Name (CI30, 0xFFFFFFFE)
        Name (PO31, 0xFFFF)
        Name (CI31, 0xFFFFFFFE)
        Name (PO32, 0xFFFF)
        Name (CI32, 0xFFFFFFFE)
        Name (PO33, 0xFFFF)
        Name (CI33, 0xFFFFFFFE)
        Name (PO34, 0xFFFF)
        Name (CI34, 0xFFFFFFFE)
        Name (PO35, 0xFFFF)
        Name (CI35, 0xFFFFFFFE)
        Name (PO36, 0xFFFF)
        Name (CI36, 0xFFFFFFFE)
        Name (PO37, 0xFFFF)
        Name (CI37, 0xFFFFFFFE)
        Name (PO38, 0xFFFF)
        Name (CI38, 0xFFFFFFFE)
        Name (PO39, 0xFFFF)
        Name (CI39, 0xFFFFFFFE)
        Name (PO40, 0xFFFF)
        Name (CI40, 0xFFFFFFFE)
        Name (PO41, 0xFFFF)
        Name (CI41, 0xFFFFFFFE)
        Name (PO42, 0xFFFF)
        Name (CI42, 0xFFFFFFFE)
        Name (PO43, 0xFFFF)
        Name (CI43, 0xFFFFFFFE)
        Name (PO44, 0xFFFF)
        Name (CI44, 0xFFFFFFFE)
        Name (PO45, 0xFFFF)
        Name (CI45, 0xFFFFFFFE)
        Name (PO46, 0xFFFF)
        Name (CI46, 0xFFFFFFFE)
        Name (PO47, 0xFFFF)
        Name (CI47, 0xFFFFFFFE)
        Name (PO48, 0xFFFF)
        Name (CI48, 0xFFFFFFFE)
        Name (PO49, 0xFFFF)
        Name (CI49, 0xFFFFFFFE)
        Name (PO50, 0xFFFF)
        Name (CI50, 0xFFFFFFFE)
        Name (PO51, 0xFFFF)
        Name (CI51, 0xFFFFFFFE)
        Name (PO52, 0xFFFF)
        Name (CI52, 0xFFFFFFFE)
        Name (PO53, 0xFFFF)
        Name (CI53, 0xFFFFFFFE)
        Name (PO54, 0xFFFF)
        Name (CI54, 0xFFFFFFFE)
        Name (PO55, 0xFFFF)
        Name (CI55, 0xFFFFFFFE)
        Name (PO56, 0xFFFF)
        Name (CI56, 0xFFFFFFFE)
        Name (PO57, 0xFFFF)
        Name (CI57, 0xFFFFFFFE)
        Name (PO58, 0xFFFF)
        Name (CI58, 0xFFFFFFFE)
        Name (PO59, 0xFFFF)
        Name (CI59, 0xFFFFFFFE)
        Name (PO60, 0xFFFF)
        Name (CI60, 0xFFFFFFFE)
        Name (PO61, 0xFFFF)
        Name (CI61, 0xFFFFFFFE)
        Name (PO62, 0xFFFF)
        Name (CI62, 0xFFFFFFFE)
        Name (PO63, 0xFFFF)
        Name (CI63, 0xFFFFFFFE)
        Name (PO64, 0xFFFF)
        Name (CI64, 0xFFFFFFFE)
        Name (POBF, Package (0x41)
        {
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF, 
            0xFFFF
        })
        Name (CIBF, Package (0x41)
        {
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE, 
            0xFFFFFFFE
        })
        Name (INI1, Zero)
        Method (RM32, 4, Serialized)
        {
            Local0 = (Arg0 + Arg1)
            OperationRegion (VARM, SystemMemory, Local0, 0x04)
            Field (VARM, DWordAcc, NoLock, Preserve)
            {
                VARR,   32
            }

            Local1 = VARR /* \_SB_.PCI0.SBRG.EC0_.RM32.VARR */
            Local5 = 0x7FFFFFFF
            Local5 |= 0x80000000
            Local2 = ((Local1 >> Arg2) & (Local5 >> (0x20 - Arg3)
                ))
            Return (Local2)
        }

        OperationRegion (ECR2, SystemIO, 0x66, One)
        Field (ECR2, ByteAcc, NoLock, Preserve)
        {
            EC66,   8
        }

        OperationRegion (ECR3, SystemIO, 0x62, One)
        Field (ECR3, ByteAcc, NoLock, Preserve)
        {
            EC62,   8
        }

        Method (IBFX, 0, Serialized)
        {
            OperationRegion (ECR1, SystemIO, 0x66, One)
            Field (ECR1, ByteAcc, NoLock, Preserve)
            {
                ECOF,   1, 
                ECIE,   1, 
                Offset (0x01)
            }

            Local0 = 0x1000
            While ((Local0-- && ECIE))
            {
                Sleep (One)
            }
        }

        Method (OBFX, 0, Serialized)
        {
            OperationRegion (ECR1, SystemIO, 0x66, One)
            Field (ECR1, ByteAcc, NoLock, Preserve)
            {
                ECOF,   1, 
                ECIE,   1, 
                Offset (0x01)
            }

            Local0 = 0x1000
            While (Local0--)
            {
                If (ECOF)
                {
                    Break
                }

                Sleep (One)
            }
        }

        Method (ECRB, 1, Serialized)
        {
            Local0 = Zero
            IBFX ()
            EC66 = 0x90
            IBFX ()
            EC62 = Arg0
            OBFX ()
            Local0 = EC62 /* \_SB_.PCI0.SBRG.EC0_.EC62 */
            Return (Local0)
        }

        Method (ECWB, 2, Serialized)
        {
            IBFX ()
            EC66 = 0x91
            IBFX ()
            EC62 = Arg0
            IBFX ()
            EC62 = Arg1
        }

        Method (ECCR, 1, Serialized)
        {
            ECWB (0xFF, Arg0)
        }

        Method (WM32, 5, Serialized)
        {
            Local0 = (Arg0 + Arg1)
            OperationRegion (VARM, SystemMemory, Local0, 0x04)
            Field (VARM, DWordAcc, NoLock, Preserve)
            {
                VARR,   32
            }

            Local1 = VARR /* \_SB_.PCI0.SBRG.EC0_.WM32.VARR */
            Local5 = 0x7FFFFFFF
            Local5 |= 0x80000000
            Local2 = (Arg2 + Arg3)
            Local2 = (0x20 - Local2)
            Local2 = (((Local5 << Local2) & Local5) >> Local2)
            Local2 = ((Local2 >> Arg2) << Arg2)
            Local3 = (Arg4 << Arg2)
            Local4 = ((Local1 & (Local5 ^ Local2)) | Local3)
            VARR = Local4
        }

        Method (WSMU, 7, Serialized)
        {
            If ((((SMUV & One) == One) || ((SMUV & 0x04
                ) == 0x04)))
            {
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B1057C)
                WM32 (0xE0000000, SMND, Zero, 0x20, Zero)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B109C4)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg0)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B109C8)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg1)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B109CC)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg2)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B109D0)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg3)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B109D4)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg4)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B109D8)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg5)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10530)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg6)
                Local0 = Zero
                Local1 = Zero
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B1057C)
                Local0 = RM32 (0xE0000000, SMND, Zero, 0x20)
                While (((Local0 != Zero) && (Local1 < 0x0A)))
                {
                    WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B1057C)
                    Local0 = RM32 (0xE0000000, SMND, Zero, 0x20)
                    Local1++
                }

                If ((DOSS == 0x02))
                {
                    Sleep (One)
                }
            }
            ElseIf ((SMUV == 0x02))
            {
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10578)
                WM32 (0xE0000000, SMND, Zero, 0x20, Zero)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10998)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg0)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B1099C)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg1)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B109A0)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg2)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B109A4)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg3)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B109A8)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg4)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B109AC)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg5)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10528)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg6)
                Local0 = Zero
                Local1 = Zero
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10578)
                Local0 = RM32 (0xE0000000, SMND, Zero, 0x20)
                While (((Local0 != Zero) && (Local1 < 0x0A)))
                {
                    WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10578)
                    Local0 = RM32 (0xE0000000, SMND, Zero, 0x20)
                    Local1++
                }

                If ((DOSS == 0x02))
                {
                    Sleep (One)
                }
            }
        }

        Method (WTMU, 7, Serialized)
        {
            If ((((SMUV & One) == One) || ((SMUV & 0x04
                ) == 0x04)))
            {
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10570)
                WM32 (0xE0000000, SMND, Zero, 0x20, Zero)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10A40)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg0)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10A44)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg1)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10A48)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg2)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10A4C)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg3)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10AD0)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg4)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10AD4)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg5)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10524)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg6)
                Local0 = Zero
                Local1 = Zero
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10570)
                Local0 = RM32 (0xE0000000, SMND, Zero, 0x20)
                While (((Local0 != Zero) && (Local1 < 0x0A)))
                {
                    WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10570)
                    Local0 = RM32 (0xE0000000, SMND, Zero, 0x20)
                    Local1++
                }
            }
            ElseIf ((SMUV == 0x02))
            {
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10A80)
                WM32 (0xE0000000, SMND, Zero, 0x20, Zero)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10A88)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg0)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10A8C)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg1)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10A90)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg2)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10A94)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg3)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10A98)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg4)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10A9C)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg5)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10A20)
                WM32 (0xE0000000, SMND, Zero, 0x20, Arg6)
                Local0 = Zero
                Local1 = Zero
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10A80)
                Local0 = RM32 (0xE0000000, SMND, Zero, 0x20)
                While (((Local0 != Zero) && (Local1 < 0x0A)))
                {
                    WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10A80)
                    Local0 = RM32 (0xE0000000, SMND, Zero, 0x20)
                    Local1++
                }
            }
        }

        OperationRegion (DBGP, SystemIO, 0x80, 0x08)
        Field (DBGP, ByteAcc, NoLock, Preserve)
        {
            DP80,   8
        }

        Method (_QB0, 0, NotSerialized)  // _Qxx: EC Query, xx=0x00-0xFF
        {
            If ((DOSS == One))
            {
                If ((((SMUV & One) == One) || ((SMUV & 0x04
                    ) == 0x04)))
                {
                    If ((Acquire (_GL, 0x03E8) == Zero))
                    {
                        WSMU (Zero, Zero, Zero, Zero, Zero, Zero, 0x24)
                        Local0 = ECRB (0xFF)
                        ECCR (One)
                        ECWB (0x84, 0x24)
                        ECCR (Local0)
                        Release (_GL)
                    }
                }
                ElseIf ((SMUV == 0x02))
                {
                    If ((Acquire (_GL, 0x03E8) == Zero))
                    {
                        WTMU (One, Zero, Zero, Zero, Zero, Zero, 0x17)
                        Local0 = ECRB (0xFF)
                        ECCR (One)
                        ECWB (0x84, 0x24)
                        ECCR (Local0)
                        Release (_GL)
                    }
                }
            }
            ElseIf ((DOSS == 0x02))
            {
                If ((INI1 == Zero))
                {
                    CINI ()
                    INI1 = One
                }

                If ((((SMUV & One) == One) || ((SMUV & 0x04
                    ) == 0x04)))
                {
                    If ((Acquire (_GL, 0x03E8) == Zero))
                    {
                        Local0 = Zero
                        While ((Local0 < 0x41))
                        {
                            If ((DerefOf (CIBF [Local0]) == 0xFFFFFFFE))
                            {
                                Break
                            }

                            If ((DerefOf (CIBF [Local0]) != 0xFFFFFFFE))
                            {
                                If ((DerefOf (CIBF [Local0]) != 0xFFFFFFFF))
                                {
                                    Local1 = DerefOf (CIBF [Local0])
                                    Local1 &= 0xFFF00000
                                    Local1 |= DerefOf (POBF [Local0])
                                    WSMU (Local1, Zero, Zero, Zero, Zero, Zero, 0x35)
                                }
                                Else
                                {
                                    WSMU (DerefOf (POBF [Local0]), Zero, Zero, Zero, Zero, Zero, 0x36)
                                }
                            }

                            Local0 += One
                        }

                        Local0 = ECRB (0xFF)
                        ECCR (One)
                        ECWB (0x84, 0x24)
                        ECCR (Local0)
                        Release (_GL)
                    }
                }
                ElseIf ((SMUV == 0x02))
                {
                    If ((Acquire (_GL, 0x03E8) == Zero))
                    {
                        Local0 = Zero
                        While ((Local0 < 0x41))
                        {
                            If ((DerefOf (CIBF [Local0]) == 0xFFFFFFFE))
                            {
                                Break
                            }

                            If ((DerefOf (CIBF [Local0]) != 0xFFFFFFFE))
                            {
                                If ((DerefOf (CIBF [Local0]) != 0xFFFFFFFF))
                                {
                                    Local1 = DerefOf (CIBF [Local0])
                                    Local1 &= 0xFFF00000
                                    Local1 |= DerefOf (POBF [Local0])
                                    WSMU (Local1, Zero, Zero, Zero, Zero, Zero, 0x4B)
                                }
                                Else
                                {
                                    WSMU (DerefOf (POBF [Local0]), Zero, Zero, Zero, Zero, Zero, 0x4C)
                                }
                            }

                            Local0 += One
                        }

                        Local0 = ECRB (0xFF)
                        ECCR (One)
                        ECWB (0x84, 0x24)
                        ECCR (Local0)
                        Release (_GL)
                    }
                }
            }
        }

        Method (NOSP, 0, Serialized)
        {
            Notify (^^^^PLTF.C000, 0x85) // Device-Specific
            If ((NTRD > One))
            {
                Notify (^^^^PLTF.C001, 0x85) // Device-Specific
            }

            If ((NTRD > 0x02))
            {
                Notify (^^^^PLTF.C002, 0x85) // Device-Specific
            }

            If ((NTRD > 0x03))
            {
                Notify (^^^^PLTF.C003, 0x85) // Device-Specific
            }

            If ((NTRD > 0x04))
            {
                Notify (^^^^PLTF.C004, 0x85) // Device-Specific
            }

            If ((NTRD > 0x05))
            {
                Notify (^^^^PLTF.C005, 0x85) // Device-Specific
            }

            If ((NTRD > 0x06))
            {
                Notify (^^^^PLTF.C006, 0x85) // Device-Specific
            }

            If ((NTRD > 0x07))
            {
                Notify (^^^^PLTF.C007, 0x85) // Device-Specific
            }

            If ((NTRD > 0x08))
            {
                Notify (^^^^PLTF.C008, 0x85) // Device-Specific
            }

            If ((NTRD > 0x09))
            {
                Notify (^^^^PLTF.C009, 0x85) // Device-Specific
            }

            If ((NTRD > 0x0A))
            {
                Notify (^^^^PLTF.C00A, 0x85) // Device-Specific
            }

            If ((NTRD > 0x0B))
            {
                Notify (^^^^PLTF.C00B, 0x85) // Device-Specific
            }

            If ((NTRD > 0x0C))
            {
                Notify (^^^^PLTF.C00C, 0x85) // Device-Specific
            }

            If ((NTRD > 0x0D))
            {
                Notify (^^^^PLTF.C00D, 0x85) // Device-Specific
            }

            If ((NTRD > 0x0E))
            {
                Notify (^^^^PLTF.C00E, 0x85) // Device-Specific
            }

            If ((NTRD > 0x0F))
            {
                Notify (^^^^PLTF.C00F, 0x85) // Device-Specific
            }

            If ((NTRD > 0x10))
            {
                Notify (^^^^PLTF.C010, 0x85) // Device-Specific
            }

            If ((NTRD > 0x11))
            {
                Notify (^^^^PLTF.C011, 0x85) // Device-Specific
            }

            If ((NTRD > 0x12))
            {
                Notify (^^^^PLTF.C012, 0x85) // Device-Specific
            }

            If ((NTRD > 0x13))
            {
                Notify (^^^^PLTF.C013, 0x85) // Device-Specific
            }

            If ((NTRD > 0x14))
            {
                Notify (^^^^PLTF.C014, 0x85) // Device-Specific
            }

            If ((NTRD > 0x15))
            {
                Notify (^^^^PLTF.C015, 0x85) // Device-Specific
            }

            If ((NTRD > 0x16))
            {
                Notify (^^^^PLTF.C016, 0x85) // Device-Specific
            }

            If ((NTRD > 0x17))
            {
                Notify (^^^^PLTF.C017, 0x85) // Device-Specific
            }

            If ((NTRD > 0x18))
            {
                Notify (^^^^PLTF.C018, 0x85) // Device-Specific
            }

            If ((NTRD > 0x19))
            {
                Notify (^^^^PLTF.C019, 0x85) // Device-Specific
            }

            If ((NTRD > 0x1A))
            {
                Notify (^^^^PLTF.C01A, 0x85) // Device-Specific
            }

            If ((NTRD > 0x1B))
            {
                Notify (^^^^PLTF.C01B, 0x85) // Device-Specific
            }

            If ((NTRD > 0x1C))
            {
                Notify (^^^^PLTF.C01C, 0x85) // Device-Specific
            }

            If ((NTRD > 0x1D))
            {
                Notify (^^^^PLTF.C01D, 0x85) // Device-Specific
            }

            If ((NTRD > 0x1E))
            {
                Notify (^^^^PLTF.C01E, 0x85) // Device-Specific
            }

            If ((NTRD > 0x1F))
            {
                Notify (^^^^PLTF.C01F, 0x85) // Device-Specific
            }
        }

        Method (_QB1, 0, NotSerialized)  // _Qxx: EC Query, xx=0x00-0xFF
        {
            If ((DOSS == One))
            {
                If ((((SMUV & One) == One) || ((SMUV & 0x04
                    ) == 0x04)))
                {
                    If ((Acquire (_GL, 0x03E8) == Zero))
                    {
                        WSMU (Zero, Zero, Zero, Zero, Zero, Zero, 0x25)
                        Local0 = ECRB (0xFF)
                        ECCR (One)
                        ECWB (0x84, 0x25)
                        ECCR (Local0)
                        If ((MLBS != 0xFFFF))
                        {
                            WTMU (MLBS, Zero, Zero, Zero, Zero, Zero, 0x70)
                            If ((PCOR == One))
                            {
                                NOSP ()
                            }
                        }

                        Release (_GL)
                    }
                }
                ElseIf ((SMUV == 0x02))
                {
                    If ((Acquire (_GL, 0x03E8) == Zero))
                    {
                        WTMU (One, Zero, Zero, Zero, Zero, Zero, 0x18)
                        Local0 = ECRB (0xFF)
                        ECCR (One)
                        ECWB (0x84, 0x25)
                        ECCR (Local0)
                        If ((MLBS != 0xFFFF))
                        {
                            WTMU (MLBS, Zero, Zero, Zero, Zero, Zero, 0x70)
                            If ((PCOR == One))
                            {
                                NOSP ()
                            }
                        }

                        Release (_GL)
                    }
                }
            }
            ElseIf ((DOSS == 0x02))
            {
                If ((((SMUV & One) == One) || ((SMUV & 0x04
                    ) == 0x04)))
                {
                    If ((Acquire (_GL, 0x03E8) == Zero))
                    {
                        If ((ASCI == 0xFFFFFFFF))
                        {
                            WSMU (ASPO, Zero, Zero, Zero, Zero, Zero, 0x36)
                        }

                        Local0 = ECRB (0xFF)
                        ECCR (One)
                        ECWB (0x84, 0x25)
                        ECCR (Local0)
                        Release (_GL)
                    }
                }
                ElseIf ((SMUV == 0x02))
                {
                    If ((Acquire (_GL, 0x03E8) == Zero))
                    {
                        If ((ASCI == 0xFFFFFFFF))
                        {
                            WSMU (ASPO, Zero, Zero, Zero, Zero, Zero, 0x4C)
                        }

                        Local0 = ECRB (0xFF)
                        ECCR (One)
                        ECWB (0x84, 0x25)
                        ECCR (Local0)
                        Release (_GL)
                    }
                }
            }
        }

        Method (WKDO, 0, Serialized)
        {
            If ((DOSS == One))
            {
                If ((((SMUV & One) == One) || ((SMUV & 0x04
                    ) == 0x04)))
                {
                    If ((Acquire (_GL, 0x03E8) == Zero))
                    {
                        WSMU (Zero, Zero, Zero, Zero, Zero, Zero, 0x25)
                        Local0 = ECRB (0xFF)
                        ECCR (One)
                        ECWB (0x84, 0x25)
                        ECCR (Local0)
                        If ((MLBS != 0xFFFF))
                        {
                            WTMU (MLBS, Zero, Zero, Zero, Zero, Zero, 0x70)
                        }

                        Release (_GL)
                    }
                }
                ElseIf ((SMUV == 0x02))
                {
                    If ((Acquire (_GL, 0x03E8) == Zero))
                    {
                        WTMU (One, Zero, Zero, Zero, Zero, Zero, 0x18)
                        Local0 = ECRB (0xFF)
                        ECCR (One)
                        ECWB (0x84, 0x25)
                        ECCR (Local0)
                        If ((MLBS != 0xFFFF))
                        {
                            WTMU (MLBS, Zero, Zero, Zero, Zero, Zero, 0x70)
                        }

                        Release (_GL)
                    }
                }
            }
        }

        Method (WOTF, 0, Serialized)
        {
            If ((Acquire (_GL, 0x03E8) == Zero))
            {
                If ((EPPA == 0x02))
                {
                    WTMU (Zero, Zero, Zero, Zero, Zero, Zero, 0x92)
                    EPPA = One
                }

                Release (_GL)
            }
        }

        Method (STMN, 1, Serialized)
        {
            If ((((SMUV & One) == One) || ((SMUV & 0x04
                ) == 0x04)))
            {
                If ((Arg0 == Zero))
                {
                    WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10570)
                    WM32 (0xE0000000, SMND, Zero, 0x20, Zero)
                    WM32 (0xE0000000, SMND, Zero, 0x20, One)
                    WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10524)
                    WM32 (0xE0000000, SMND, Zero, 0x20, 0x04)
                    Sleep (One)
                }

                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10570)
                WM32 (0xE0000000, SMND, Zero, 0x20, Zero)
                WM32 (0xE0000000, SMND, Zero, 0x20, One)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10524)
                WM32 (0xE0000000, SMND, Zero, 0x20, 0x03)
                If ((Arg0 == Zero))
                {
                    WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10A40)
                    Local0 = RM32 (0xE0000000, SMND, Zero, 0x20)
                    Local1 = Zero
                    While (((Local0 == Zero) && (Local1 < 0x0F)))
                    {
                        Local0 = RM32 (0xE0000000, SMND, Zero, 0x20)
                        Local1 += One
                    }

                    BASE = Local0
                    If (((SMUV & One) == One))
                    {
                        BASE += 0x017C
                    }
                    ElseIf (((SMUV & 0x04) == 0x04))
                    {
                        BASE += 0x0180
                    }
                }
            }
            ElseIf ((SMUV == 0x02))
            {
                If ((Arg0 == Zero))
                {
                    WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10A80)
                    WM32 (0xE0000000, SMND, Zero, 0x20, Zero)
                    WM32 (0xE0000000, SMND, Zero, 0x20, One)
                    WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10A20)
                    WM32 (0xE0000000, SMND, Zero, 0x20, 0x66)
                }

                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10A80)
                WM32 (0xE0000000, SMND, Zero, 0x20, Zero)
                WM32 (0xE0000000, SMND, Zero, 0x20, One)
                WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10A20)
                WM32 (0xE0000000, SMND, Zero, 0x20, 0x65)
                If ((Arg0 == Zero))
                {
                    WM32 (0xE0000000, SMNI, Zero, 0x20, 0x03B10A88)
                    Local0 = RM32 (0xE0000000, SMND, Zero, 0x20)
                    Local1 = Zero
                    While (((Local0 == Zero) && (Local1 < 0x0F)))
                    {
                        Local0 = RM32 (0xE0000000, SMND, Zero, 0x20)
                        Local1 += One
                    }

                    BASE = Local0
                    BASE += 0x0320
                }
            }
        }

        Method (INIT, 0, Serialized)
        {
            CreateDWordField (WRBF, Zero, REAX)
            CreateDWordField (WRBF, 0x04, REBX)
            CreateDWordField (WRBF, 0x08, RECX)
            CreateDWordField (WRBF, 0x0C, REDX)
            Local0 = Zero
            While ((Local0 < 0x08))
            {
                Local3 = 0xC0010068
                If ((Local0 > 0x03))
                {
                    Local3 += One
                }

                WRBF = GMSR (Local3)
                Local1 = REAX /* \_SB_.PCI0.SBRG.EC0_.INIT.REAX */
                Local7 = (Local0 % 0x04)
                Local7 *= 0x08
                Local1 >>= Local7
                Local1 &= 0xFF
                CCD0 [Local0] = Local1
                If ((Local1 > One))
                {
                    C0SZ += One
                    If ((Local1 < MCC0))
                    {
                        MCC0 = Local1
                    }

                    If ((Local1 > XCC0))
                    {
                        XCC0 = Local1
                    }
                }

                Local3 = 0xC001006A
                If ((Local0 > 0x03))
                {
                    Local3 += One
                }

                WRBF = GMSR (Local3)
                Local2 = REAX /* \_SB_.PCI0.SBRG.EC0_.INIT.REAX */
                Local2 >>= Local7
                Local2 &= 0xFF
                CCD1 [Local0] = Local2
                If ((Local2 > One))
                {
                    C1SZ += One
                    If ((Local2 < MCC1))
                    {
                        MCC1 = Local2
                    }

                    If ((Local2 > XCC1))
                    {
                        XCC1 = Local2
                    }
                }

                If (((Local1 <= One) && (Local2 <= One)))
                {
                    Break
                }

                Local0 += One
            }

            If ((C1SZ > Zero))
            {
                STMN (Zero)
                Local0 = Zero
                While ((Local0 < C0SZ))
                {
                    Local5 = DerefOf (CCD0 [Local0])
                    TPKG [Local0] = Local5
                    C0LO [Local0] = Local5
                    C0HI [Local0] = Local5
                    Local0 += One
                }

                Local0 = Zero
                While ((Local0 < C0SZ))
                {
                    Local1 = (Local0 + One)
                    While ((Local1 < C0SZ))
                    {
                        Local2 = DerefOf (TPKG [Local0])
                        Local3 = DerefOf (TPKG [Local1])
                        If ((Local2 < Local3))
                        {
                            TPKG [Local0] = Local3
                            TPKG [Local1] = Local2
                            Local2 = DerefOf (C0SA [Local0])
                            Local3 = DerefOf (C0SA [Local1])
                            C0SA [Local0] = Local3
                            C0SA [Local1] = Local2
                        }

                        Local1 += One
                    }

                    Local0 += One
                }

                Local0 = Zero
                While ((Local0 < C1SZ))
                {
                    Local2 = DerefOf (CCD1 [Local0])
                    TPKG [Local0] = Local2
                    C1LO [Local0] = Local2
                    C1HI [Local0] = Local2
                    Local0 += One
                }

                Local0 = Zero
                While ((Local0 < C1SZ))
                {
                    Local1 = (Local0 + One)
                    While ((Local1 < C1SZ))
                    {
                        Local2 = DerefOf (TPKG [Local0])
                        Local3 = DerefOf (TPKG [Local1])
                        If ((Local2 < Local3))
                        {
                            TPKG [Local0] = Local3
                            TPKG [Local1] = Local2
                            Local2 = DerefOf (C1SA [Local0])
                            Local3 = DerefOf (C1SA [Local1])
                            C1SA [Local0] = Local3
                            C1SA [Local1] = Local2
                        }

                        Local1 += One
                    }

                    Local0 += One
                }

                If ((XCC1 > XCC0))
                {
                    If ((MCC1 <= XCC0))
                    {
                        Local0 = (XCC0 - MCC1) /* \_SB_.PCI0.SBRG.EC0_.MCC1 */
                        Local0 += One
                        Local2 = DerefOf (C1SA [(C1SZ - One)])
                        Local1 = DerefOf (CCD1 [Local2])
                        Local1 += Local0
                        If ((Local1 > 0xFF))
                        {
                            Local1 = 0xFF
                        }

                        C1LO [Local2] = Local1
                        If ((C1SZ > One))
                        {
                            Local1 = (C1SZ - 0x02)
                            While ((Local1 > Zero))
                            {
                                Local2 = DerefOf (C1SA [Local1])
                                Local3 = DerefOf (C1SA [(Local1 + One)])
                                If ((DerefOf (C1LO [Local2]) <= DerefOf (C1LO [Local3]
                                    )))
                                {
                                    Local4 = (DerefOf (C1LO [Local3]) - DerefOf (C1LO [Local2]))
                                    Local4 += One
                                    Local5 = DerefOf (C1LO [Local2])
                                    Local5 += Local4
                                    If ((Local5 > 0xFF))
                                    {
                                        Local5 = 0xFF
                                    }

                                    C1LO [Local2] = Local5
                                }

                                Local1 -= One
                            }

                            Local1 = Zero
                            Local2 = DerefOf (C1SA [Local1])
                            Local3 = DerefOf (C1SA [(Local1 + One)])
                            If ((DerefOf (C1LO [Local2]) <= DerefOf (C1LO [Local3]
                                )))
                            {
                                Local4 = (DerefOf (C1LO [Local3]) - DerefOf (C1LO [Local2]))
                                Local4 += One
                                Local5 = DerefOf (C1LO [Local2])
                                Local5 += Local4
                                If ((Local5 > 0xFF))
                                {
                                    Local5 = 0xFF
                                }

                                C1LO [Local2] = Local5
                            }
                        }

                        If ((MCC0 <= XCC1))
                        {
                            Local0 = (XCC1 - MCC0) /* \_SB_.PCI0.SBRG.EC0_.MCC0 */
                            Local0 += One
                            Local2 = DerefOf (C0SA [(C0SZ - One)])
                            Local1 = DerefOf (CCD0 [Local2])
                            Local1 += Local0
                            If ((Local1 > 0xFF))
                            {
                                Local1 = 0xFF
                            }

                            C0HI [Local2] = Local1
                            If ((C0SZ > One))
                            {
                                Local1 = (C0SZ - 0x02)
                                While ((Local1 > Zero))
                                {
                                    Local2 = DerefOf (C0SA [Local1])
                                    Local3 = DerefOf (C0SA [(Local1 + One)])
                                    If ((DerefOf (C0HI [Local2]) <= DerefOf (C0HI [Local3]
                                        )))
                                    {
                                        Local4 = (DerefOf (C0HI [Local3]) - DerefOf (C0HI [Local2]))
                                        Local4 += One
                                        Local5 = DerefOf (C0HI [Local2])
                                        Local5 += Local4
                                        If ((Local5 > 0xFF))
                                        {
                                            Local5 = 0xFF
                                        }

                                        C0HI [Local2] = Local5
                                    }

                                    Local1 -= One
                                }

                                Local1 = Zero
                                Local2 = DerefOf (C0SA [Local1])
                                Local3 = DerefOf (C0SA [(Local1 + One)])
                                If ((DerefOf (C0HI [Local2]) <= DerefOf (C0HI [Local3]
                                    )))
                                {
                                    Local4 = (DerefOf (C0HI [Local3]) - DerefOf (C0HI [Local2]))
                                    Local4 += One
                                    Local5 = DerefOf (C0HI [Local2])
                                    Local5 += Local4
                                    If ((Local5 > 0xFF))
                                    {
                                        Local5 = 0xFF
                                    }

                                    C0HI [Local2] = Local5
                                }
                            }
                        }
                    }
                    ElseIf ((MCC0 <= XCC1))
                    {
                        Local0 = (XCC1 - MCC0) /* \_SB_.PCI0.SBRG.EC0_.MCC0 */
                        Local0 += One
                        Local2 = DerefOf (C0SA [(C0SZ - One)])
                        Local1 = DerefOf (CCD0 [Local2])
                        Local1 += Local0
                        If ((Local1 > 0xFF))
                        {
                            Local1 = 0xFF
                        }

                        C0HI [Local2] = Local1
                        If ((C0SZ > One))
                        {
                            Local1 = (C0SZ - 0x02)
                            While ((Local1 > Zero))
                            {
                                Local2 = DerefOf (C0SA [Local1])
                                Local3 = DerefOf (C0SA [(Local1 + One)])
                                If ((DerefOf (C0HI [Local2]) <= DerefOf (C0HI [Local3]
                                    )))
                                {
                                    Local4 = (DerefOf (C0HI [Local3]) - DerefOf (C0HI [Local2]))
                                    Local4 += One
                                    Local5 = DerefOf (C0HI [Local2])
                                    Local5 += Local4
                                    If ((Local5 > 0xFF))
                                    {
                                        Local5 = 0xFF
                                    }

                                    C0HI [Local2] = Local5
                                }

                                Local1 -= One
                            }

                            Local1 = Zero
                            Local2 = DerefOf (C0SA [Local1])
                            Local3 = DerefOf (C0SA [(Local1 + One)])
                            If ((DerefOf (C0HI [Local2]) <= DerefOf (C0HI [Local3]
                                )))
                            {
                                Local4 = (DerefOf (C0HI [Local3]) - DerefOf (C0HI [Local2]))
                                Local4 += One
                                Local5 = DerefOf (C0HI [Local2])
                                Local5 += Local4
                                If ((Local5 > 0xFF))
                                {
                                    Local5 = 0xFF
                                }

                                C0HI [Local2] = Local5
                            }
                        }
                    }
                }
                ElseIf ((MCC0 <= XCC1))
                {
                    Local0 = (XCC1 - MCC0) /* \_SB_.PCI0.SBRG.EC0_.MCC0 */
                    Local0 += One
                    Local2 = DerefOf (C0SA [(C0SZ - One)])
                    Local1 = DerefOf (CCD0 [Local2])
                    Local1 += Local0
                    If ((Local1 > 0xFF))
                    {
                        Local1 = 0xFF
                    }

                    C0HI [Local2] = Local1
                    If ((C0SZ > One))
                    {
                        Local1 = (C0SZ - 0x02)
                        While ((Local1 > Zero))
                        {
                            Local2 = DerefOf (C0SA [Local1])
                            Local3 = DerefOf (C0SA [(Local1 + One)])
                            If ((DerefOf (C0HI [Local2]) <= DerefOf (C0HI [Local3]
                                )))
                            {
                                Local4 = (DerefOf (C0HI [Local3]) - DerefOf (C0HI [Local2]))
                                Local4 += One
                                Local5 = DerefOf (C0HI [Local2])
                                Local5 += Local4
                                If ((Local5 > 0xFF))
                                {
                                    Local5 = 0xFF
                                }

                                C0HI [Local2] = Local5
                            }

                            Local1 -= One
                        }

                        Local1 = Zero
                        Local2 = DerefOf (C0SA [Local1])
                        Local3 = DerefOf (C0SA [(Local1 + One)])
                        If ((DerefOf (C0HI [Local2]) <= DerefOf (C0HI [Local3]
                            )))
                        {
                            Local4 = (DerefOf (C0HI [Local3]) - DerefOf (C0HI [Local2]))
                            Local4 += One
                            Local5 = DerefOf (C0HI [Local2])
                            Local5 += Local4
                            If ((Local5 > 0xFF))
                            {
                                Local5 = 0xFF
                            }

                            C0HI [Local2] = Local5
                        }
                    }

                    If ((MCC1 <= XCC0))
                    {
                        Local0 = (XCC0 - MCC1) /* \_SB_.PCI0.SBRG.EC0_.MCC1 */
                        Local0 += One
                        Local2 = DerefOf (C1SA [(C1SZ - One)])
                        Local1 = DerefOf (CCD1 [Local2])
                        Local1 += Local0
                        If ((Local1 > 0xFF))
                        {
                            Local1 = 0xFF
                        }

                        C1LO [Local2] = Local1
                        If ((C1SZ > One))
                        {
                            Local1 = (C1SZ - 0x02)
                            While ((Local1 > Zero))
                            {
                                Local2 = DerefOf (C1SA [Local1])
                                Local3 = DerefOf (C1SA [(Local1 + One)])
                                If ((DerefOf (C1LO [Local2]) <= DerefOf (C1LO [Local3]
                                    )))
                                {
                                    Local4 = (DerefOf (C1LO [Local3]) - DerefOf (C1LO [Local2]))
                                    Local4 += One
                                    Local5 = DerefOf (C1LO [Local2])
                                    Local5 += Local4
                                    If ((Local5 > 0xFF))
                                    {
                                        Local5 = 0xFF
                                    }

                                    C1LO [Local2] = Local5
                                }

                                Local1 -= One
                            }

                            Local1 = Zero
                            Local2 = DerefOf (C1SA [Local1])
                            Local3 = DerefOf (C1SA [(Local1 + One)])
                            If ((DerefOf (C1LO [Local2]) <= DerefOf (C1LO [Local3]
                                )))
                            {
                                Local4 = (DerefOf (C1LO [Local3]) - DerefOf (C1LO [Local2]))
                                Local4 += One
                                Local5 = DerefOf (C1LO [Local2])
                                Local5 += Local4
                                If ((Local5 > 0xFF))
                                {
                                    Local5 = 0xFF
                                }

                                C1LO [Local2] = Local5
                            }
                        }
                    }
                }
                ElseIf ((MCC1 <= XCC0))
                {
                    Local0 = (XCC0 - MCC1) /* \_SB_.PCI0.SBRG.EC0_.MCC1 */
                    Local0 += One
                    Local2 = DerefOf (C1SA [(C1SZ - One)])
                    Local1 = DerefOf (C1LO [Local2])
                    Local1 += Local0
                    If ((Local1 > 0xFF))
                    {
                        Local1 = 0xFF
                    }

                    C1LO [Local2] = Local1
                    If ((C1SZ > One))
                    {
                        Local1 = (C1SZ - 0x02)
                        While ((Local1 > Zero))
                        {
                            Local2 = DerefOf (C1SA [Local1])
                            Local3 = DerefOf (C1SA [(Local1 + One)])
                            If ((DerefOf (C1LO [Local2]) <= DerefOf (C1LO [Local3]
                                )))
                            {
                                Local4 = (DerefOf (C1LO [Local3]) - DerefOf (C1LO [Local2]))
                                Local4 += One
                                Local5 = DerefOf (C1LO [Local2])
                                Local5 += Local4
                                If ((Local5 > 0xFF))
                                {
                                    Local5 = 0xFF
                                }

                                C1LO [Local2] = Local5
                            }

                            Local1 -= One
                        }

                        Local1 = Zero
                        Local2 = DerefOf (C1SA [Local1])
                        Local3 = DerefOf (C1SA [(Local1 + One)])
                        If ((DerefOf (C1LO [Local2]) <= DerefOf (C1LO [Local3]
                            )))
                        {
                            Local4 = (DerefOf (C1LO [Local3]) - DerefOf (C1LO [Local2]))
                            Local4 += One
                            Local5 = DerefOf (C1LO [Local2])
                            Local5 += Local4
                            If ((Local5 > 0xFF))
                            {
                                Local5 = 0xFF
                            }

                            C1LO [Local2] = Local5
                        }
                    }
                }

                Local0 = DerefOf (C0LO [One])
                Local1 = Local0
                Local1 &= 0x3F
                If ((Local1 == Zero))
                {
                    Local0 += One
                    C0LO [One] = Local0
                }

                Local0 = DerefOf (C1LO [One])
                Local1 = Local0
                Local1 &= 0x3F
                If ((Local1 == Zero))
                {
                    Local0 += One
                    C1LO [One] = Local0
                }

                Local0 = DerefOf (C0HI [One])
                Local1 = Local0
                Local1 &= 0x3F
                If ((Local1 == Zero))
                {
                    Local0 += One
                    C0HI [One] = Local0
                }

                Local0 = DerefOf (C1HI [One])
                Local1 = Local0
                Local1 &= 0x3F
                If ((Local1 == Zero))
                {
                    Local0 += One
                    C1HI [One] = Local0
                }
            }
            Else
            {
                SWST = 0xFF
            }
        }

        Method (QSW0, 1, Serialized)
        {
            CreateDWordField (WRBF, Zero, REAX)
            CreateDWordField (WRBF, 0x04, REBX)
            CreateDWordField (WRBF, 0x08, RECX)
            CreateDWordField (WRBF, 0x0C, REDX)
            Local0 = Zero
            REAX = Zero
            While ((Local0 < C0SZ))
            {
                If ((Arg0 == One))
                {
                    Local1 = DerefOf (C0HI [Local0])
                }
                Else
                {
                    Local1 = DerefOf (C0LO [Local0])
                }

                Local7 = Local0
                Local7 %= 0x04
                Local7 *= 0x08
                Local1 <<= Local7
                REAX |= Local1
                If (((Local0 == 0x03) || (Local0 == (C0SZ - One))))
                {
                    Local3 = 0xC0010068
                    If ((Local0 > 0x03))
                    {
                        Local3 += One
                    }

                    RECX = Local3
                    REDX = Zero
                    SMSR (WRBF)
                    REAX = Zero
                }

                Local0 += One
            }

            Local0 = Zero
            REAX = Zero
            While ((Local0 < C1SZ))
            {
                If ((Arg0 == One))
                {
                    Local1 = DerefOf (C1HI [Local0])
                }
                Else
                {
                    Local1 = DerefOf (C1LO [Local0])
                }

                Local7 = Local0
                Local7 %= 0x04
                Local7 *= 0x08
                Local1 <<= Local7
                REAX |= Local1
                If (((Local0 == 0x03) || (Local0 == (C1SZ - One))))
                {
                    Local3 = 0xC001006A
                    If ((Local0 > 0x03))
                    {
                        Local3 += One
                    }

                    RECX = Local3
                    REDX = Zero
                    SMSR (WRBF)
                    REAX = Zero
                }

                Local0 += One
            }

            SWST = Arg0
        }

        Method (CINI, 0, Serialized)
        {
            POBF [Zero] = PO00 /* \_SB_.PCI0.SBRG.EC0_.PO00 */
            CIBF [Zero] = CI00 /* \_SB_.PCI0.SBRG.EC0_.CI00 */
            POBF [One] = PO01 /* \_SB_.PCI0.SBRG.EC0_.PO01 */
            CIBF [One] = CI01 /* \_SB_.PCI0.SBRG.EC0_.CI01 */
            POBF [0x02] = PO02 /* \_SB_.PCI0.SBRG.EC0_.PO02 */
            CIBF [0x02] = CI02 /* \_SB_.PCI0.SBRG.EC0_.CI02 */
            POBF [0x03] = PO03 /* \_SB_.PCI0.SBRG.EC0_.PO03 */
            CIBF [0x03] = CI03 /* \_SB_.PCI0.SBRG.EC0_.CI03 */
            POBF [0x04] = PO04 /* \_SB_.PCI0.SBRG.EC0_.PO04 */
            CIBF [0x04] = CI04 /* \_SB_.PCI0.SBRG.EC0_.CI04 */
            POBF [0x05] = PO05 /* \_SB_.PCI0.SBRG.EC0_.PO05 */
            CIBF [0x05] = CI05 /* \_SB_.PCI0.SBRG.EC0_.CI05 */
            POBF [0x06] = PO06 /* \_SB_.PCI0.SBRG.EC0_.PO06 */
            CIBF [0x06] = CI06 /* \_SB_.PCI0.SBRG.EC0_.CI06 */
            POBF [0x07] = PO07 /* \_SB_.PCI0.SBRG.EC0_.PO07 */
            CIBF [0x07] = CI07 /* \_SB_.PCI0.SBRG.EC0_.CI07 */
            POBF [0x08] = PO08 /* \_SB_.PCI0.SBRG.EC0_.PO08 */
            CIBF [0x08] = CI08 /* \_SB_.PCI0.SBRG.EC0_.CI08 */
            POBF [0x09] = PO09 /* \_SB_.PCI0.SBRG.EC0_.PO09 */
            CIBF [0x09] = CI09 /* \_SB_.PCI0.SBRG.EC0_.CI09 */
            POBF [0x0A] = PO10 /* \_SB_.PCI0.SBRG.EC0_.PO10 */
            CIBF [0x0A] = CI10 /* \_SB_.PCI0.SBRG.EC0_.CI10 */
            POBF [0x0B] = PO11 /* \_SB_.PCI0.SBRG.EC0_.PO11 */
            CIBF [0x0B] = CI11 /* \_SB_.PCI0.SBRG.EC0_.CI11 */
            POBF [0x0C] = PO12 /* \_SB_.PCI0.SBRG.EC0_.PO12 */
            CIBF [0x0C] = CI12 /* \_SB_.PCI0.SBRG.EC0_.CI12 */
            POBF [0x0D] = PO13 /* \_SB_.PCI0.SBRG.EC0_.PO13 */
            CIBF [0x0D] = CI13 /* \_SB_.PCI0.SBRG.EC0_.CI13 */
            POBF [0x0E] = PO14 /* \_SB_.PCI0.SBRG.EC0_.PO14 */
            CIBF [0x0E] = CI14 /* \_SB_.PCI0.SBRG.EC0_.CI14 */
            POBF [0x0F] = PO15 /* \_SB_.PCI0.SBRG.EC0_.PO15 */
            CIBF [0x0F] = CI15 /* \_SB_.PCI0.SBRG.EC0_.CI15 */
            POBF [0x10] = PO16 /* \_SB_.PCI0.SBRG.EC0_.PO16 */
            CIBF [0x10] = CI16 /* \_SB_.PCI0.SBRG.EC0_.CI16 */
            POBF [0x11] = PO17 /* \_SB_.PCI0.SBRG.EC0_.PO17 */
            CIBF [0x11] = CI17 /* \_SB_.PCI0.SBRG.EC0_.CI17 */
            POBF [0x12] = PO18 /* \_SB_.PCI0.SBRG.EC0_.PO18 */
            CIBF [0x12] = CI18 /* \_SB_.PCI0.SBRG.EC0_.CI18 */
            POBF [0x13] = PO19 /* \_SB_.PCI0.SBRG.EC0_.PO19 */
            CIBF [0x13] = CI19 /* \_SB_.PCI0.SBRG.EC0_.CI19 */
            POBF [0x14] = PO20 /* \_SB_.PCI0.SBRG.EC0_.PO20 */
            CIBF [0x14] = CI20 /* \_SB_.PCI0.SBRG.EC0_.CI20 */
            POBF [0x15] = PO21 /* \_SB_.PCI0.SBRG.EC0_.PO21 */
            CIBF [0x15] = CI21 /* \_SB_.PCI0.SBRG.EC0_.CI21 */
            POBF [0x16] = PO22 /* \_SB_.PCI0.SBRG.EC0_.PO22 */
            CIBF [0x16] = CI22 /* \_SB_.PCI0.SBRG.EC0_.CI22 */
            POBF [0x17] = PO23 /* \_SB_.PCI0.SBRG.EC0_.PO23 */
            CIBF [0x17] = CI23 /* \_SB_.PCI0.SBRG.EC0_.CI23 */
            POBF [0x18] = PO24 /* \_SB_.PCI0.SBRG.EC0_.PO24 */
            CIBF [0x18] = CI24 /* \_SB_.PCI0.SBRG.EC0_.CI24 */
            POBF [0x19] = PO25 /* \_SB_.PCI0.SBRG.EC0_.PO25 */
            CIBF [0x19] = CI25 /* \_SB_.PCI0.SBRG.EC0_.CI25 */
            POBF [0x1A] = PO26 /* \_SB_.PCI0.SBRG.EC0_.PO26 */
            CIBF [0x1A] = CI26 /* \_SB_.PCI0.SBRG.EC0_.CI26 */
            POBF [0x1B] = PO27 /* \_SB_.PCI0.SBRG.EC0_.PO27 */
            CIBF [0x1B] = CI27 /* \_SB_.PCI0.SBRG.EC0_.CI27 */
            POBF [0x1C] = PO28 /* \_SB_.PCI0.SBRG.EC0_.PO28 */
            CIBF [0x1C] = CI28 /* \_SB_.PCI0.SBRG.EC0_.CI28 */
            POBF [0x1D] = PO29 /* \_SB_.PCI0.SBRG.EC0_.PO29 */
            CIBF [0x1D] = CI29 /* \_SB_.PCI0.SBRG.EC0_.CI29 */
            POBF [0x1E] = PO30 /* \_SB_.PCI0.SBRG.EC0_.PO30 */
            CIBF [0x1E] = CI30 /* \_SB_.PCI0.SBRG.EC0_.CI30 */
            POBF [0x1F] = PO31 /* \_SB_.PCI0.SBRG.EC0_.PO31 */
            CIBF [0x1F] = CI31 /* \_SB_.PCI0.SBRG.EC0_.CI31 */
            POBF [0x20] = PO32 /* \_SB_.PCI0.SBRG.EC0_.PO32 */
            CIBF [0x20] = CI32 /* \_SB_.PCI0.SBRG.EC0_.CI32 */
            POBF [0x21] = PO33 /* \_SB_.PCI0.SBRG.EC0_.PO33 */
            CIBF [0x21] = CI33 /* \_SB_.PCI0.SBRG.EC0_.CI33 */
            POBF [0x22] = PO34 /* \_SB_.PCI0.SBRG.EC0_.PO34 */
            CIBF [0x22] = CI34 /* \_SB_.PCI0.SBRG.EC0_.CI34 */
            POBF [0x23] = PO35 /* \_SB_.PCI0.SBRG.EC0_.PO35 */
            CIBF [0x23] = CI35 /* \_SB_.PCI0.SBRG.EC0_.CI35 */
            POBF [0x24] = PO36 /* \_SB_.PCI0.SBRG.EC0_.PO36 */
            CIBF [0x24] = CI36 /* \_SB_.PCI0.SBRG.EC0_.CI36 */
            POBF [0x25] = PO37 /* \_SB_.PCI0.SBRG.EC0_.PO37 */
            CIBF [0x25] = CI37 /* \_SB_.PCI0.SBRG.EC0_.CI37 */
            POBF [0x26] = PO38 /* \_SB_.PCI0.SBRG.EC0_.PO38 */
            CIBF [0x26] = CI38 /* \_SB_.PCI0.SBRG.EC0_.CI38 */
            POBF [0x27] = PO39 /* \_SB_.PCI0.SBRG.EC0_.PO39 */
            CIBF [0x27] = CI39 /* \_SB_.PCI0.SBRG.EC0_.CI39 */
            POBF [0x28] = PO40 /* \_SB_.PCI0.SBRG.EC0_.PO40 */
            CIBF [0x28] = CI40 /* \_SB_.PCI0.SBRG.EC0_.CI40 */
            POBF [0x29] = PO41 /* \_SB_.PCI0.SBRG.EC0_.PO41 */
            CIBF [0x29] = CI41 /* \_SB_.PCI0.SBRG.EC0_.CI41 */
            POBF [0x2A] = PO42 /* \_SB_.PCI0.SBRG.EC0_.PO42 */
            CIBF [0x2A] = CI42 /* \_SB_.PCI0.SBRG.EC0_.CI42 */
            POBF [0x2B] = PO43 /* \_SB_.PCI0.SBRG.EC0_.PO43 */
            CIBF [0x2B] = CI43 /* \_SB_.PCI0.SBRG.EC0_.CI43 */
            POBF [0x2C] = PO44 /* \_SB_.PCI0.SBRG.EC0_.PO44 */
            CIBF [0x2C] = CI44 /* \_SB_.PCI0.SBRG.EC0_.CI44 */
            POBF [0x2D] = PO45 /* \_SB_.PCI0.SBRG.EC0_.PO45 */
            CIBF [0x2D] = CI45 /* \_SB_.PCI0.SBRG.EC0_.CI45 */
            POBF [0x2E] = PO46 /* \_SB_.PCI0.SBRG.EC0_.PO46 */
            CIBF [0x2E] = CI46 /* \_SB_.PCI0.SBRG.EC0_.CI46 */
            POBF [0x2F] = PO47 /* \_SB_.PCI0.SBRG.EC0_.PO47 */
            CIBF [0x2F] = CI47 /* \_SB_.PCI0.SBRG.EC0_.CI47 */
            POBF [0x30] = PO48 /* \_SB_.PCI0.SBRG.EC0_.PO48 */
            CIBF [0x30] = CI48 /* \_SB_.PCI0.SBRG.EC0_.CI48 */
            POBF [0x31] = PO49 /* \_SB_.PCI0.SBRG.EC0_.PO49 */
            CIBF [0x31] = CI49 /* \_SB_.PCI0.SBRG.EC0_.CI49 */
            POBF [0x32] = PO50 /* \_SB_.PCI0.SBRG.EC0_.PO50 */
            CIBF [0x32] = CI50 /* \_SB_.PCI0.SBRG.EC0_.CI50 */
            POBF [0x33] = PO51 /* \_SB_.PCI0.SBRG.EC0_.PO51 */
            CIBF [0x33] = CI51 /* \_SB_.PCI0.SBRG.EC0_.CI51 */
            POBF [0x34] = PO52 /* \_SB_.PCI0.SBRG.EC0_.PO52 */
            CIBF [0x34] = CI52 /* \_SB_.PCI0.SBRG.EC0_.CI52 */
            POBF [0x35] = PO53 /* \_SB_.PCI0.SBRG.EC0_.PO53 */
            CIBF [0x35] = CI53 /* \_SB_.PCI0.SBRG.EC0_.CI53 */
            POBF [0x36] = PO54 /* \_SB_.PCI0.SBRG.EC0_.PO54 */
            CIBF [0x36] = CI54 /* \_SB_.PCI0.SBRG.EC0_.CI54 */
            POBF [0x37] = PO55 /* \_SB_.PCI0.SBRG.EC0_.PO55 */
            CIBF [0x37] = CI55 /* \_SB_.PCI0.SBRG.EC0_.CI55 */
            POBF [0x38] = PO56 /* \_SB_.PCI0.SBRG.EC0_.PO56 */
            CIBF [0x38] = CI56 /* \_SB_.PCI0.SBRG.EC0_.CI56 */
            POBF [0x39] = PO57 /* \_SB_.PCI0.SBRG.EC0_.PO57 */
            CIBF [0x39] = CI57 /* \_SB_.PCI0.SBRG.EC0_.CI57 */
            POBF [0x3A] = PO58 /* \_SB_.PCI0.SBRG.EC0_.PO58 */
            CIBF [0x3A] = CI58 /* \_SB_.PCI0.SBRG.EC0_.CI58 */
            POBF [0x3B] = PO59 /* \_SB_.PCI0.SBRG.EC0_.PO59 */
            CIBF [0x3B] = CI59 /* \_SB_.PCI0.SBRG.EC0_.CI59 */
            POBF [0x3C] = PO60 /* \_SB_.PCI0.SBRG.EC0_.PO60 */
            CIBF [0x3C] = CI60 /* \_SB_.PCI0.SBRG.EC0_.CI60 */
            POBF [0x3D] = PO61 /* \_SB_.PCI0.SBRG.EC0_.PO61 */
            CIBF [0x3D] = CI61 /* \_SB_.PCI0.SBRG.EC0_.CI61 */
            POBF [0x3E] = PO62 /* \_SB_.PCI0.SBRG.EC0_.PO62 */
            CIBF [0x3E] = CI62 /* \_SB_.PCI0.SBRG.EC0_.CI62 */
            POBF [0x3F] = PO63 /* \_SB_.PCI0.SBRG.EC0_.PO63 */
            CIBF [0x3F] = CI63 /* \_SB_.PCI0.SBRG.EC0_.CI63 */
            POBF [0x40] = PO64 /* \_SB_.PCI0.SBRG.EC0_.PO64 */
            CIBF [0x40] = CI64 /* \_SB_.PCI0.SBRG.EC0_.CI64 */
        }

        Method (_QE0, 0, NotSerialized)  // _Qxx: EC Query, xx=0x00-0xFF
        {
            If ((Acquire (_GL, 0x03E8) == Zero))
            {
                If ((((HCNT >= HYST) || (SWST == 0xFF)) || (SWST == 
                    One)))
                {
                    Local0 = ECRB (0xFF)
                    ECCR (One)
                    ECWB (0xDB, Zero)
                    ECCR (Local0)
                }

                If (((SWST == Zero) && (INI0 == Zero)))
                {
                    STMN (Zero)
                    INIT ()
                    INI0 = One
                }

                If (((SWST != One) && (SWST != 0xFF)))
                {
                    If ((TRES == Zero))
                    {
                        If ((HCNT >= HYST))
                        {
                            QSW0 (One)
                            NOSP ()
                            If ((((SMUV & One) == One) || ((SMUV & 0x04
                                ) == 0x04)))
                            {
                                WSMU (Zero, Zero, Zero, Zero, Zero, Zero, 0x6D)
                            }

                            HCNT = Zero
                        }

                        HCNT += One
                    }
                    Else
                    {
                        OperationRegion (MEMR, SystemMemory, BASE, 0x04)
                        Field (MEMR, DWordAcc, NoLock, Preserve)
                        {
                            MERD,   32
                        }

                        Local5 = Zero
                        Local0 = Zero
                        While ((Local5 < 0x03))
                        {
                            STMN (One)
                            Local5 += One
                            Local1 = MERD /* \_SB_.PCI0.SBRG.EC0_._QE0.MERD */
                            Local0 += Local1
                        }

                        Divide (Local0, 0x002DC6C0, Local7, Local6)
                        If ((Local6 > TRES))
                        {
                            If ((HCNT >= HYST))
                            {
                                QSW0 (One)
                                NOSP ()
                                If ((((SMUV & One) == One) || ((SMUV & 0x04
                                    ) == 0x04)))
                                {
                                    WSMU (Zero, Zero, Zero, Zero, Zero, Zero, 0x6D)
                                }

                                HCNT = Zero
                            }

                            HCNT += One
                        }
                    }
                }
                Else
                {
                    HCNT = Zero
                }

                Release (_GL)
            }
        }

        Method (_QE1, 0, NotSerialized)  // _Qxx: EC Query, xx=0x00-0xFF
        {
            If ((Acquire (_GL, 0x03E8) == Zero))
            {
                If ((((HCNT >= HYST) || (SWST == 0xFF)) || (SWST == 
                    0x02)))
                {
                    Local0 = ECRB (0xFF)
                    ECCR (One)
                    ECWB (0xDB, Zero)
                    ECCR (Local0)
                }

                If (((SWST == Zero) && (INI0 == Zero)))
                {
                    STMN (Zero)
                    INIT ()
                    INI0 = One
                }

                If (((SWST != 0x02) && (SWST != 0xFF)))
                {
                    If ((TRES == Zero))
                    {
                        If ((HCNT >= HYST))
                        {
                            QSW0 (0x02)
                            NOSP ()
                            If ((((SMUV & One) == One) || ((SMUV & 0x04
                                ) == 0x04)))
                            {
                                WSMU (Zero, Zero, Zero, Zero, Zero, Zero, 0x6D)
                            }

                            HCNT = Zero
                        }

                        HCNT += One
                    }
                    Else
                    {
                        OperationRegion (MEMR, SystemMemory, BASE, 0x04)
                        Field (MEMR, DWordAcc, NoLock, Preserve)
                        {
                            MERD,   32
                        }

                        Local5 = Zero
                        Local0 = Zero
                        While ((Local5 < 0x03))
                        {
                            STMN (One)
                            Local5 += One
                            Local1 = MERD /* \_SB_.PCI0.SBRG.EC0_._QE1.MERD */
                            Local0 += Local1
                        }

                        Divide (Local0, 0x002DC6C0, Local7, Local6)
                        If ((Local6 <= TRES))
                        {
                            If ((HCNT >= HYST))
                            {
                                QSW0 (0x02)
                                NOSP ()
                                If ((((SMUV & One) == One) || ((SMUV & 0x04
                                    ) == 0x04)))
                                {
                                    WSMU (Zero, Zero, Zero, Zero, Zero, Zero, 0x6D)
                                }

                                HCNT = Zero
                            }

                            HCNT += One
                        }
                    }
                }
                Else
                {
                    HCNT = Zero
                }

                Release (_GL)
            }
        }

        Method (_QE2, 0, NotSerialized)  // _Qxx: EC Query, xx=0x00-0xFF
        {
            If ((Acquire (_GL, 0x03E8) == Zero))
            {
                If ((((HCT1 >= HYS1) || (EPPA == 0xFF)) || (EPPA == 
                    One)))
                {
                    Local0 = ECRB (0xFF)
                    ECCR (One)
                    ECWB (0xDB, Zero)
                    ECCR (Local0)
                }

                If (((EPPA == Zero) && (INI2 == Zero)))
                {
                    STMN (Zero)
                    INI2 = One
                }

                If (((EPPA != One) && (EPPA != 0xFF)))
                {
                    If ((TRS1 == Zero))
                    {
                        If ((HCT1 >= HYS1))
                        {
                            WTMU (Zero, Zero, Zero, Zero, Zero, Zero, 0x92)
                            EPPA = One
                            HCT1 = Zero
                        }

                        HCT1 += One
                    }
                    Else
                    {
                        OperationRegion (MEMR, SystemMemory, BASE, 0x04)
                        Field (MEMR, DWordAcc, NoLock, Preserve)
                        {
                            MERD,   32
                        }

                        Local5 = Zero
                        Local0 = Zero
                        While ((Local5 < 0x03))
                        {
                            STMN (One)
                            Local5 += One
                            Local1 = MERD /* \_SB_.PCI0.SBRG.EC0_._QE2.MERD */
                            Local0 += Local1
                        }

                        Divide (Local0, 0x002DC6C0, Local7, Local6)
                        If ((Local6 <= TRS1))
                        {
                            If ((HCT1 >= HYS1))
                            {
                                WTMU (Zero, Zero, Zero, Zero, Zero, Zero, 0x92)
                                EPPA = One
                                HCT1 = Zero
                            }

                            HCT1 += One
                        }
                    }
                }
                Else
                {
                    HCT1 = Zero
                }

                Release (_GL)
            }
        }

        Method (_QE3, 0, NotSerialized)  // _Qxx: EC Query, xx=0x00-0xFF
        {
            If ((Acquire (_GL, 0x03E8) == Zero))
            {
                If ((((HCT1 >= HYS1) || (EPPA == 0xFF)) || (EPPA == 
                    0x02)))
                {
                    Local0 = ECRB (0xFF)
                    ECCR (One)
                    ECWB (0xDB, Zero)
                    ECCR (Local0)
                }

                If (((EPPA == Zero) && (INI2 == Zero)))
                {
                    STMN (Zero)
                    INI2 = One
                }

                If (((EPPA != 0x02) && (EPPA != 0xFF)))
                {
                    If ((TRS1 == Zero))
                    {
                        If ((HCT1 >= HYS1))
                        {
                            WTMU (One, Zero, Zero, Zero, Zero, Zero, 0x92)
                            EPPA = 0x02
                            HCT1 = Zero
                        }

                        HCT1 += One
                    }
                    Else
                    {
                        OperationRegion (MEMR, SystemMemory, BASE, 0x04)
                        Field (MEMR, DWordAcc, NoLock, Preserve)
                        {
                            MERD,   32
                        }

                        Local5 = Zero
                        Local0 = Zero
                        While ((Local5 < 0x03))
                        {
                            STMN (One)
                            Local5 += One
                            Local1 = MERD /* \_SB_.PCI0.SBRG.EC0_._QE3.MERD */
                            Local0 += Local1
                        }

                        Divide (Local0, 0x002DC6C0, Local7, Local6)
                        If ((Local6 > TRS1))
                        {
                            If ((HCT1 >= HYS1))
                            {
                                WTMU (One, Zero, Zero, Zero, Zero, Zero, 0x92)
                                EPPA = 0x02
                                HCT1 = Zero
                            }

                            HCT1 += One
                        }
                    }
                }
                Else
                {
                    HCT1 = Zero
                }

                Release (_GL)
            }
        }

        Method (DOSW, 1, NotSerialized)
        {
            WKDO ()
            WOTF ()
        }
    }

    Name (BDID, 0x00)
    Scope (_SB.PCI0.GP17.XHC0)
    {
        Device (RHUB)
        {
            Name (_ADR, Zero)  // _ADR: Address
            Name (PTGN, Package (0x06)
            {
                One, 
                0x02, 
                One, 
                0x02, 
                0x03, 
                0x04
            })
            Method (GUPC, 1, Serialized)
            {
                Name (PCKG, Package (0x04)
                {
                    Zero, 
                    0xFF, 
                    Zero, 
                    Zero
                })
                Local1 = Zero
                Local2 = Zero
                If ((Arg0 >= 0x03))
                {
                    Local0 = (Arg0 - 0x03)
                }
                Else
                {
                    Local0 = (Arg0 - One)
                }

                Local1 = Zero
                Local2 = Zero
                If ((Arg0 <= 0x02))
                {
                    If ((Local2 & (One << Local0)))
                    {
                        PCKG [Zero] = 0xFF
                        PCKG [One] = Zero
                    }
                }
                ElseIf ((Local1 & (One << Local0)))
                {
                    PCKG [Zero] = 0xFF
                    PCKG [One] = 0x03
                }

                Return (PCKG) /* \_SB_.PCI0.GP17.XHC0.RHUB.GUPC.PCKG */
            }

            Method (GPLD, 1, Serialized)
            {
                Name (PCKG, Package (0x01)
                {
                    Buffer (0x14)
                    {
                        /* 0000 */  0x82, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                        /* 0008 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                        /* 0010 */  0xFF, 0xFF, 0xFF, 0xFF                           // ....
                    }
                })
                CreateField (DerefOf (PCKG [Zero]), 0x40, One, VISI)
                CreateField (DerefOf (PCKG [Zero]), 0x57, 0x08, GPOS)
                If ((Arg0 >= 0x03))
                {
                    Local0 = (Arg0 - 0x03)
                }
                Else
                {
                    Local0 = (Arg0 - One)
                }

                Local2 = Zero
                Local3 = Zero
                Local1 = 0x0001300C
                Local2 = (Local1 & 0x03)
                Local3 = ((Local1 >> 0x08) & 0x0F)
                If ((Arg0 <= 0x02))
                {
                    If ((Local3 & (One << Local0)))
                    {
                        VISI = One
                        Local4 = (Arg0 - One)
                        GPOS = DerefOf (PTGN [Local4])
                    }
                    Else
                    {
                        VISI = Zero
                    }
                }
                ElseIf ((Local2 & (One << Local0)))
                {
                    VISI = One
                    Local4 = (Arg0 - One)
                    GPOS = DerefOf (PTGN [Local4])
                }
                Else
                {
                    VISI = Zero
                }

                Return (PCKG) /* \_SB_.PCI0.GP17.XHC0.RHUB.GPLD.PCKG */
            }

            Device (PRT1)
            {
                Name (_ADR, One)  // _ADR: Address
                Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                {
                    Return (GUPC (One))
                }

                Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                {
                    Return (GPLD (One))
                }
            }

            Device (PRT3)
            {
                Name (_ADR, 0x03)  // _ADR: Address
                Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                {
                    Return (GUPC (0x03))
                }

                Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                {
                    Return (GPLD (0x03))
                }
            }

            Device (PRT2)
            {
                Name (_ADR, 0x02)  // _ADR: Address
                Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                {
                    Return (GUPC (0x02))
                }

                Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                {
                    Return (GPLD (0x02))
                }
            }

            Device (PRT4)
            {
                Name (_ADR, 0x04)  // _ADR: Address
                Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                {
                    Return (GUPC (0x04))
                }

                Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                {
                    Return (GPLD (0x04))
                }
            }
        }
    }

    Scope (_SB.PCI0.GP17.XHC1)
    {
        Device (RHUB)
        {
            Name (_ADR, Zero)  // _ADR: Address
            Name (PTGN, Package (0x06)
            {
                0x05, 
                0x06, 
                0x05, 
                0x06, 
                0x07, 
                0x08
            })
            Method (GUPC, 1, Serialized)
            {
                Name (PCKG, Package (0x04)
                {
                    Zero, 
                    0xFF, 
                    Zero, 
                    Zero
                })
                Local1 = Zero
                Local2 = Zero
                If ((Arg0 >= 0x03))
                {
                    Local0 = (Arg0 - 0x03)
                }
                Else
                {
                    Local0 = (Arg0 - One)
                }

                Local1 = 0x03
                Local2 = 0x03
                If ((Arg0 <= 0x02))
                {
                    If ((Local2 & (One << Local0)))
                    {
                        PCKG [Zero] = 0xFF
                        PCKG [One] = Zero
                    }
                }
                ElseIf ((Local1 & (One << Local0)))
                {
                    PCKG [Zero] = 0xFF
                    PCKG [One] = 0x03
                }

                Return (PCKG) /* \_SB_.PCI0.GP17.XHC1.RHUB.GUPC.PCKG */
            }

            Method (GPLD, 1, Serialized)
            {
                Name (PCKG, Package (0x01)
                {
                    Buffer (0x14)
                    {
                        /* 0000 */  0x82, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                        /* 0008 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                        /* 0010 */  0xFF, 0xFF, 0xFF, 0xFF                           // ....
                    }
                })
                CreateField (DerefOf (PCKG [Zero]), 0x40, One, VISI)
                CreateField (DerefOf (PCKG [Zero]), 0x57, 0x08, GPOS)
                If ((Arg0 >= 0x03))
                {
                    Local0 = (Arg0 - 0x03)
                }
                Else
                {
                    Local0 = (Arg0 - One)
                }

                Local2 = Zero
                Local3 = Zero
                Local1 = 0x0001300C
                Local2 = ((Local1 >> 0x02) & 0x03)
                Local3 = ((Local1 >> 0x0C) & 0x0F)
                If ((Arg0 <= 0x02))
                {
                    If ((Local3 & (One << Local0)))
                    {
                        VISI = One
                        Local4 = (Arg0 - One)
                        GPOS = DerefOf (PTGN [Local4])
                    }
                    Else
                    {
                        VISI = Zero
                    }
                }
                ElseIf ((Local2 & (One << Local0)))
                {
                    VISI = One
                    Local4 = (Arg0 - One)
                    GPOS = DerefOf (PTGN [Local4])
                }
                Else
                {
                    VISI = Zero
                }

                Return (PCKG) /* \_SB_.PCI0.GP17.XHC1.RHUB.GPLD.PCKG */
            }

            Device (PRT1)
            {
                Name (_ADR, One)  // _ADR: Address
                Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                {
                    Return (GUPC (One))
                }

                Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                {
                    Return (GPLD (One))
                }
            }

            Device (PRT3)
            {
                Name (_ADR, 0x03)  // _ADR: Address
                Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                {
                    Return (GUPC (0x03))
                }

                Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                {
                    Return (GPLD (0x03))
                }
            }

            Device (PRT2)
            {
                Name (_ADR, 0x02)  // _ADR: Address
                Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                {
                    Return (GUPC (0x02))
                }

                Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                {
                    Return (GPLD (0x02))
                }
            }

            Device (PRT4)
            {
                Name (_ADR, 0x04)  // _ADR: Address
                Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                {
                    Return (GUPC (0x04))
                }

                Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                {
                    Return (GPLD (0x04))
                }
            }
        }
    }

    Scope (_SB.PCI0.GP19.XHC2)
    {
        Device (RHUB)
        {
            Name (_ADR, Zero)  // _ADR: Address
            Name (PTGN, Package (0x04)
            {
                0x09, 
                0x0A, 
                0x0B, 
                0x0C
            })
            Method (GUPC, 1, Serialized)
            {
                Name (PCKG, Package (0x04)
                {
                    Zero, 
                    0xFF, 
                    Zero, 
                    Zero
                })
                Local1 = Zero
                Local2 = Zero
                If ((Arg0 >= 0x03))
                {
                    Local0 = (Arg0 - 0x03)
                }
                Else
                {
                    Local0 = (Arg0 - One)
                }

                Local1 = Zero
                Local2 = One
                If ((Local2 & (One << Local0)))
                {
                    If ((Local1 & (One << Local0)))
                    {
                        PCKG [Zero] = 0xFF
                        PCKG [One] = 0x03
                    }
                    Else
                    {
                        PCKG [Zero] = 0xFF
                        PCKG [One] = Zero
                    }
                }

                Return (PCKG) /* \_SB_.PCI0.GP19.XHC2.RHUB.GUPC.PCKG */
            }

            Method (GPLD, 1, Serialized)
            {
                Name (PCKG, Package (0x01)
                {
                    Buffer (0x14)
                    {
                        /* 0000 */  0x82, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                        /* 0008 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                        /* 0010 */  0xFF, 0xFF, 0xFF, 0xFF                           // ....
                    }
                })
                CreateField (DerefOf (PCKG [Zero]), 0x40, One, VISI)
                CreateField (DerefOf (PCKG [Zero]), 0x57, 0x08, GPOS)
                If ((Arg0 >= 0x03))
                {
                    Local0 = (Arg0 - 0x03)
                }
                Else
                {
                    Local0 = (Arg0 - One)
                }

                Local2 = Zero
                Local3 = Zero
                Local1 = 0x0001300C
                Local2 = ((Local1 >> 0x04) & 0x03)
                Local3 = ((Local1 >> 0x10) & 0x0F)
                If ((Arg0 <= Zero))
                {
                    If ((Local2 & (One << Local0)))
                    {
                        VISI = One
                        Local4 = (Arg0 - One)
                        GPOS = DerefOf (PTGN [Local4])
                    }
                    Else
                    {
                        VISI = Zero
                    }
                }
                ElseIf ((Local3 & (One << Local0)))
                {
                    VISI = One
                    Local4 = (Arg0 - One)
                    GPOS = DerefOf (PTGN [Local4])
                }
                Else
                {
                    VISI = Zero
                }

                Return (PCKG) /* \_SB_.PCI0.GP19.XHC2.RHUB.GPLD.PCKG */
            }

            Device (PRT1)
            {
                Name (_ADR, One)  // _ADR: Address
                Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                {
                    Return (GUPC (One))
                }

                Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                {
                    Return (GPLD (One))
                }
            }
        }
    }

    OperationRegion (CPVS, SystemMemory, 0x712BE000, 0x0100)
    Field (CPVS, AnyAcc, Lock, Preserve)
    {
        Offset (0x00), 
        G000,   8, 
        Offset (0x01), 
        G001,   8, 
        Offset (0x02), 
        G002,   8, 
        Offset (0x03), 
        G003,   8, 
        Offset (0x04), 
        G004,   32, 
        Offset (0x08), 
        G005,   16, 
        Offset (0x0A), 
        G006,   16, 
        Offset (0x0C), 
        G007,   32, 
        Offset (0x10), 
        G008,   32, 
        Offset (0x14), 
        G009,   32, 
        Offset (0x18), 
        G00A,   32, 
        Offset (0x1C), 
        G00B,   64, 
        Offset (0x24), 
        G00C,   64, 
        Offset (0x2C), 
        G00D,   64, 
        Offset (0x34), 
        G00E,   64, 
        Offset (0x3C), 
        G00F,   16, 
        Offset (0x3E), 
        G010,   16, 
        Offset (0x40), 
        G011,   8, 
        Offset (0x41), 
        G012,   32, 
        Offset (0x45), 
        G013,   32, 
        Offset (0x49), 
        G014,   32, 
        Offset (0x4D), 
        G015,   32, 
        Offset (0x51), 
        G016,   32, 
        Offset (0x55), 
        G017,   8, 
        Offset (0x56), 
        G018,   32, 
        Offset (0x5A), 
        G019,   32, 
        Offset (0x5E), 
        G01A,   32, 
        Offset (0x62), 
        G01B,   32, 
        Offset (0x66), 
        G01C,   32, 
        Offset (0x6A), 
        G01D,   8, 
        Offset (0x6B), 
        G01E,   8, 
        Offset (0x6C), 
        G01F,   8, 
        Offset (0x6D), 
        G020,   8, 
        Offset (0x6E), 
        G021,   8, 
        Offset (0x6F), 
        G022,   8, 
        Offset (0x70), 
        G023,   8, 
        Offset (0x71), 
        G024,   8, 
        Offset (0x72), 
        G025,   8, 
        Offset (0x73), 
        G026,   8, 
        Offset (0x74), 
        G027,   8, 
        Offset (0x75), 
        G028,   32, 
        Offset (0x79), 
        G029,   32, 
        Offset (0x7D), 
        G02A,   32, 
        Offset (0x81), 
        G02B,   32, 
        Offset (0x85), 
        G02C,   8, 
        Offset (0x86), 
        G02D,   8
    }

    Name (PWVA, 0xFFFFFFFF)
    Method (PWGS, 1, NotSerialized)
    {
        Local0 = M013 (G015, Zero, G016, One)
        If ((Local0 == One))
        {
            PWVA = Zero
            M014 (G015, Zero, G016, One, Zero)
        }

        Local0 = Arg0
        Local1 = (One << Local0)
        Local2 = (Local1 & PWVA) /* \PWVA */
        If ((Local2 == Zero))
        {
            PWVA |= Local1 /* \PWVA */
            M460 ("  OEM-ASL PWGS 0x%X don\'t Unlock from S0I3, PWVA = 0x%X\n", Arg0, PWVA, Zero, Zero, Zero, Zero)
            Return (Zero)
        }

        Return (One)
    }

    Method (UPWD, 0, NotSerialized)
    {
        M460 ("PLA-ASL-UPWD Unlock Nvme Password SMI\n", Zero, Zero, Zero, Zero, Zero, Zero)
    }

    Method (SPWD, 0, NotSerialized)
    {
        M460 ("PLA-ASL-SPWD Save Nvme Password SMI\n", Zero, Zero, Zero, Zero, Zero, Zero)
    }

    If ((G002 != One))
    {
        Scope (\_SB.PCI0.GPP0)
        {
            Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
            {
                0x08, 
                0x04
            })
        }

        Scope (\_SB.PCI0.GPP2)
        {
            Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
            {
                0x08, 
                0x04
            })
        }

        Scope (\_GPE)
        {
            Method (_L08, 0, NotSerialized)  // _Lxx: Level-Triggered GPE, xx=0x00-0xFF
            {
                M460 ("  OEM-ASL-\\_GPE._L08 ()\n", Zero, Zero, Zero, Zero, Zero, Zero)
                M460 ("    Notify (\\_SB.PCI0.GPP0, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                Notify (\_SB.PCI0.GPP0, 0x02) // Device Wake
                M460 ("    Notify (\\_SB.PCI0.GPP2, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                Notify (\_SB.PCI0.GPP2, 0x02) // Device Wake
            }
        }
    }

    If (((G000 == One) && ((G002 >= 0x04) && (
        G002 <= 0x07)))){}
    If (((G000 == One) && (G002 == 0x07))){}
    If (((G002 != 0x03) && (G000 != Zero))){}
    If ((G002 != 0x03))
    {
        Scope (\_SB.PCI0.GPP7)
        {
            Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
            {
                0x02, 
                0x04
            })
            If ((G002 >= 0x04))
            {
                Name (DVTP, 0xEE)
                Name (DADR, 0xEEEEEEEE)
                Name (DSTA, 0xEE)
                Name (DBUS, 0xEEEE)
                Name (PCSA, Zero)
                Name (PWST, 0xD3)
                Name (ESTA, 0xEE)
                Name (EBUS, 0xEEEE)
                Name (PW3S, Zero)
                Name (FLG0, 0xEE)
                Name (M640, 0x33)
                Name (M641, 0x33)
                Name (M642, 0x33)
                Method (_STA, 0, Serialized)  // _STA: Status
                {
                    Local5 = Zero
                    If ((CondRefOf (^^FLG0) && CondRefOf (^^EBUS)))
                    {
                        Local5 |= One
                        If (((^^FLG0 == 0x16) && (^^EBUS != DBUS)))
                        {
                            Local5 |= 0x02
                            M640 = 0x33
                            M641 = 0x33
                            M642 = 0x33
                            FLG0 = 0xEE
                            ESTA = 0xEE
                            DBUS = 0xEEEE
                            DADR = 0xEEEEEEEE
                        }
                    }

                    If (((DSTA == 0xEE) || (ESTA == 0xEE)))
                    {
                        Local5 |= 0x04
                        If ((DBUS == 0xEEEE))
                        {
                            If (CondRefOf (^^EBUS))
                            {
                                Local5 |= 0x08
                                DBUS = ^^EBUS /* External reference */
                            }
                            Else
                            {
                                Local5 |= 0x10
                                DBUS = Zero
                            }
                        }

                        If ((DBUS != 0xEEEE))
                        {
                            Local5 |= 0x20
                            If ((DADR == 0xEEEEEEEE))
                            {
                                Local5 |= 0x40
                                Local0 = (((_ADR << 0x0C) & 0x7000) | ((_ADR >> 
                                    One) & 0x000F8000))
                                Local0 |= ((DBUS << 0x14) & 0x0FF00000)
                                DADR = (M083 + Local0)
                            }

                            Local0 = 0x7FFFFFFF
                            Local0 |= 0x80000000
                            Local1 = M04B (DADR, Zero)
                            If (((Local1 == Local0) || (Local1 == Zero)))
                            {
                                Local5 |= 0x80
                                DSTA = Zero
                                ESTA = Zero
                                If ((DBUS != Zero))
                                {
                                    Local5 |= 0x0100
                                    If ((CondRefOf (^^M641) && CondRefOf (^^DADR)))
                                    {
                                        If ((^^M641 == 0x33))
                                        {
                                            Local5 |= 0x0200
                                            Local2 = M646 (^^DADR, 0x10)
                                            ^^M641 = Local2
                                        }
                                        Else
                                        {
                                            Local5 |= 0x0400
                                            Local2 = ^^M641 /* External reference */
                                        }

                                        If (((M049 (^^DADR, (Local2 + 0x14)) & 0x40) == 0x40))
                                        {
                                            Local5 |= 0x0800
                                            DSTA = 0x0F
                                            ESTA = 0xEE
                                        }
                                    }
                                }
                            }
                            ElseIf ((M04A (DADR, 0x0A) == 0x0604))
                            {
                                EBUS = ((M04B (DADR, 0x18) >> 0x08) & 0xFF)
                                If ((M641 == 0x33))
                                {
                                    Local5 |= 0x1000
                                    Local2 = M646 (DADR, 0x10)
                                    M641 = Local2
                                }
                                Else
                                {
                                    Local5 |= 0x2000
                                    Local2 = M641 /* \_SB_.PCI0.GPP7.M641 */
                                }

                                Local3 = ((M049 (DADR, (Local2 + 0x02)) >> 0x04) & 0x0F)
                                If ((Local3 == 0x05))
                                {
                                    If ((EBUS == Zero))
                                    {
                                        Local5 |= 0x4000
                                        DSTA = 0x0F
                                        ESTA = 0xEE
                                    }
                                    ElseIf ((M648 (EBUS, 0x0D, Zero) == Zero))
                                    {
                                        Local5 |= 0x8000
                                        DSTA = Zero
                                        ESTA = Zero
                                    }
                                    Else
                                    {
                                        Local5 |= 0x00010000
                                        DSTA = 0x0F
                                        ESTA = 0x0F
                                    }
                                }
                                ElseIf (((M049 (DADR, (Local2 + 0x1A)) & 0x40) == 
                                    Zero))
                                {
                                    If (((M049 (DADR, (Local2 + 0x14)) & 0x40) == Zero))
                                    {
                                        Local5 |= 0x00020000
                                        DSTA = Zero
                                        ESTA = Zero
                                    }
                                    Else
                                    {
                                        Local5 |= 0x00040000
                                        DSTA = 0x0F
                                        ESTA = 0xEE
                                    }
                                }
                                ElseIf ((EBUS == Zero))
                                {
                                    Local5 |= 0x00080000
                                    DSTA = 0x0F
                                    ESTA = 0xEE
                                }
                                Else
                                {
                                    Local5 |= 0x00100000
                                    DSTA = 0x0F
                                    ESTA = 0x0F
                                }

                                If (((FLG0 == 0xEE) && (Local3 == 0x06)))
                                {
                                    If ((M642 == 0x33))
                                    {
                                        Local5 |= 0x00200000
                                        Local4 = M646 (DADR, 0x15)
                                    }
                                    Else
                                    {
                                        Local5 |= 0x00400000
                                        Local4 = M642 /* \_SB_.PCI0.GPP7.M642 */
                                    }

                                    If ((Local4 != Zero))
                                    {
                                        Local5 |= 0x00800000
                                        FLG0 = 0x16
                                    }
                                }
                            }
                            Else
                            {
                                Local5 |= 0x01000000
                                DSTA = 0x0F
                                ESTA = Zero
                            }
                        }
                        Else
                        {
                            Local5 |= 0x02000000
                            DSTA = Zero
                            ESTA = 0xEE
                        }
                    }

                    If ((FLG0 == 0x16))
                    {
                        Local5 |= 0x04000000
                        If ((M049 (DADR, 0x19) == Zero))
                        {
                            Local5 |= 0x08000000
                            ESTA = 0xEE
                        }
                    }

                    If ((((PCSA == One) && (PWST == 0xD3)) && (PW3S == One)))
                    {
                        Local5 |= 0x10000000
                        PWST = 0xD0
                    }

                    If ((((PCSA == Zero) && (PWST == 0xD0)) && (PW3S == Zero)))
                    {
                        Local5 |= 0x40000000
                        PWST = 0xD3
                    }

                    If (CondRefOf (SSTA))
                    {
                        SSTA ()
                    }

                    If ((DADR != 0xEEEEEEEE))
                    {
                        M460 ("  OEM-ASL-PCIe Address (0x%X)._STA = 0x%X  PWST = 0x%X  DBUS = 0x%X  ESTA = 0x%X  EBUS = 0x%X", DADR, DSTA, PWST, DBUS, ESTA, EBUS)
                        M460 ("  PCSA = 0x%X  PW3S = 0x%X  FLG0 = 0x%X  Local5 = 0x%X\n", PCSA, PW3S, FLG0, Local5, Zero, Zero)
                    }

                    Return (DSTA) /* \_SB_.PCI0.GPP7.DSTA */
                }

                Method (_INI, 0, Serialized)  // _INI: Initialize
                {
                    Local0 = 0x7FFFFFFF
                    Local0 |= 0x80000000
                    Local1 = M04B (DADR, Zero)
                    If (((Local1 == Local0) || (Local1 == Zero)))
                    {
                        PCSA = Zero
                        PWST = 0xD3
                        PW3S = Zero
                    }
                    Else
                    {
                        PCSA = One
                        PWST = 0xD0
                        PW3S = One
                    }

                    If ((PCSA == One))
                    {
                        If ((M641 == 0x33))
                        {
                            Local2 = M646 (DADR, 0x10)
                            M641 = Local2
                        }

                        If ((M640 == 0x33))
                        {
                            Local2 = M646 (DADR, One)
                            M640 = Local2
                        }

                        If ((DVTP == 0xEE))
                        {
                            Local1 = M049 (DADR, 0x0E)
                            Local1 &= 0x3F
                            If ((Local1 == Zero))
                            {
                                DVTP = Zero
                            }

                            If ((Local1 == One))
                            {
                                DVTP = One
                            }
                        }
                    }

                    M460 ("  OEM-ASL-PCIe Address (0x%X)._INI  PCSA = 0x%X  PWST = 0x%X  PW3S = 0x%X  DVTP = 0x%X\n", DADR, PCSA, PWST, PW3S, DVTP, Zero)
                    If (CondRefOf (SINI))
                    {
                        SINI ()
                    }
                }

                Method (_REG, 2, Serialized)  // _REG: Region Availability
                {
                    If (((Arg0 == 0x02) && (Arg1 == One)))
                    {
                        If ((DSTA == 0x0F))
                        {
                            If (((M049 (DADR, 0x04) & 0xFC) == 0x04))
                            {
                                PCSA = One
                            }
                        }
                    }

                    If (((Arg0 == 0x02) && (Arg1 == Zero)))
                    {
                        PCSA = Zero
                    }

                    If (CondRefOf (SREG))
                    {
                        SREG (Arg0, Arg1)
                    }

                    M460 ("  OEM-ASL-PCIe Address (0x%X)._REG (%d %d)  PCSA = %d\n", DADR, Arg0, Arg1, PCSA, Zero, Zero)
                }
            }
        }
    }

    If ((G002 < 0x03))
    {
        Scope (\_SB.PCI0.GPP7)
        {
        }
    }

    If (((G002 != 0x03) && (G000 == One)))
    {
        Scope (\_SB.PCI0.GPP7)
        {
            Device (UP00)
            {
                Name (_ADR, Zero)  // _ADR: Address
                Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                {
                    0x02, 
                    0x04
                })
                If ((G002 >= 0x04))
                {
                    Name (DVTP, 0xEE)
                    Name (DADR, 0xEEEEEEEE)
                    Name (DSTA, 0xEE)
                    Name (DBUS, 0xEEEE)
                    Name (PCSA, Zero)
                    Name (PWST, 0xD3)
                    Name (ESTA, 0xEE)
                    Name (EBUS, 0xEEEE)
                    Name (PW3S, Zero)
                    Name (FLG0, 0xEE)
                    Name (M640, 0x33)
                    Name (M641, 0x33)
                    Name (M642, 0x33)
                    Method (_STA, 0, Serialized)  // _STA: Status
                    {
                        Local5 = Zero
                        If ((CondRefOf (^^FLG0) && CondRefOf (^^EBUS)))
                        {
                            Local5 |= One
                            If (((^^FLG0 == 0x16) && (^^EBUS != DBUS)))
                            {
                                Local5 |= 0x02
                                M640 = 0x33
                                M641 = 0x33
                                M642 = 0x33
                                FLG0 = 0xEE
                                ESTA = 0xEE
                                DBUS = 0xEEEE
                                DADR = 0xEEEEEEEE
                            }
                        }

                        If (((DSTA == 0xEE) || (ESTA == 0xEE)))
                        {
                            Local5 |= 0x04
                            If ((DBUS == 0xEEEE))
                            {
                                If (CondRefOf (^^EBUS))
                                {
                                    Local5 |= 0x08
                                    DBUS = ^^EBUS /* \_SB_.PCI0.GPP7.EBUS */
                                }
                                Else
                                {
                                    Local5 |= 0x10
                                    DBUS = Zero
                                }
                            }

                            If ((DBUS != 0xEEEE))
                            {
                                Local5 |= 0x20
                                If ((DADR == 0xEEEEEEEE))
                                {
                                    Local5 |= 0x40
                                    Local0 = (((_ADR << 0x0C) & 0x7000) | ((_ADR >> 
                                        One) & 0x000F8000))
                                    Local0 |= ((DBUS << 0x14) & 0x0FF00000)
                                    DADR = (M083 + Local0)
                                }

                                Local0 = 0x7FFFFFFF
                                Local0 |= 0x80000000
                                Local1 = M04B (DADR, Zero)
                                If (((Local1 == Local0) || (Local1 == Zero)))
                                {
                                    Local5 |= 0x80
                                    DSTA = Zero
                                    ESTA = Zero
                                    If ((DBUS != Zero))
                                    {
                                        Local5 |= 0x0100
                                        If ((CondRefOf (^^M641) && CondRefOf (^^DADR)))
                                        {
                                            If ((^^M641 == 0x33))
                                            {
                                                Local5 |= 0x0200
                                                Local2 = M646 (^^DADR, 0x10)
                                                ^^M641 = Local2
                                            }
                                            Else
                                            {
                                                Local5 |= 0x0400
                                                Local2 = ^^M641 /* \_SB_.PCI0.GPP7.M641 */
                                            }

                                            If (((M049 (^^DADR, (Local2 + 0x14)) & 0x40) == 0x40))
                                            {
                                                Local5 |= 0x0800
                                                DSTA = 0x0F
                                                ESTA = 0xEE
                                            }
                                        }
                                    }
                                }
                                ElseIf ((M04A (DADR, 0x0A) == 0x0604))
                                {
                                    EBUS = ((M04B (DADR, 0x18) >> 0x08) & 0xFF)
                                    If ((M641 == 0x33))
                                    {
                                        Local5 |= 0x1000
                                        Local2 = M646 (DADR, 0x10)
                                        M641 = Local2
                                    }
                                    Else
                                    {
                                        Local5 |= 0x2000
                                        Local2 = M641 /* \_SB_.PCI0.GPP7.UP00.M641 */
                                    }

                                    Local3 = ((M049 (DADR, (Local2 + 0x02)) >> 0x04) & 0x0F)
                                    If ((Local3 == 0x05))
                                    {
                                        If ((EBUS == Zero))
                                        {
                                            Local5 |= 0x4000
                                            DSTA = 0x0F
                                            ESTA = 0xEE
                                        }
                                        ElseIf ((M648 (EBUS, 0x0D, Zero) == Zero))
                                        {
                                            Local5 |= 0x8000
                                            DSTA = Zero
                                            ESTA = Zero
                                        }
                                        Else
                                        {
                                            Local5 |= 0x00010000
                                            DSTA = 0x0F
                                            ESTA = 0x0F
                                        }
                                    }
                                    ElseIf (((M049 (DADR, (Local2 + 0x1A)) & 0x40) == 
                                        Zero))
                                    {
                                        If (((M049 (DADR, (Local2 + 0x14)) & 0x40) == Zero))
                                        {
                                            Local5 |= 0x00020000
                                            DSTA = Zero
                                            ESTA = Zero
                                        }
                                        Else
                                        {
                                            Local5 |= 0x00040000
                                            DSTA = 0x0F
                                            ESTA = 0xEE
                                        }
                                    }
                                    ElseIf ((EBUS == Zero))
                                    {
                                        Local5 |= 0x00080000
                                        DSTA = 0x0F
                                        ESTA = 0xEE
                                    }
                                    Else
                                    {
                                        Local5 |= 0x00100000
                                        DSTA = 0x0F
                                        ESTA = 0x0F
                                    }

                                    If (((FLG0 == 0xEE) && (Local3 == 0x06)))
                                    {
                                        If ((M642 == 0x33))
                                        {
                                            Local5 |= 0x00200000
                                            Local4 = M646 (DADR, 0x15)
                                        }
                                        Else
                                        {
                                            Local5 |= 0x00400000
                                            Local4 = M642 /* \_SB_.PCI0.GPP7.UP00.M642 */
                                        }

                                        If ((Local4 != Zero))
                                        {
                                            Local5 |= 0x00800000
                                            FLG0 = 0x16
                                        }
                                    }
                                }
                                Else
                                {
                                    Local5 |= 0x01000000
                                    DSTA = 0x0F
                                    ESTA = Zero
                                }
                            }
                            Else
                            {
                                Local5 |= 0x02000000
                                DSTA = Zero
                                ESTA = 0xEE
                            }
                        }

                        If ((FLG0 == 0x16))
                        {
                            Local5 |= 0x04000000
                            If ((M049 (DADR, 0x19) == Zero))
                            {
                                Local5 |= 0x08000000
                                ESTA = 0xEE
                            }
                        }

                        If ((((PCSA == One) && (PWST == 0xD3)) && (PW3S == One)))
                        {
                            Local5 |= 0x10000000
                            PWST = 0xD0
                        }

                        If ((((PCSA == Zero) && (PWST == 0xD0)) && (PW3S == Zero)))
                        {
                            Local5 |= 0x40000000
                            PWST = 0xD3
                        }

                        If (CondRefOf (SSTA))
                        {
                            SSTA ()
                        }

                        If ((DADR != 0xEEEEEEEE))
                        {
                            M460 ("  OEM-ASL-PCIe Address (0x%X)._STA = 0x%X  PWST = 0x%X  DBUS = 0x%X  ESTA = 0x%X  EBUS = 0x%X", DADR, DSTA, PWST, DBUS, ESTA, EBUS)
                            M460 ("  PCSA = 0x%X  PW3S = 0x%X  FLG0 = 0x%X  Local5 = 0x%X\n", PCSA, PW3S, FLG0, Local5, Zero, Zero)
                        }

                        Return (DSTA) /* \_SB_.PCI0.GPP7.UP00.DSTA */
                    }

                    Method (_INI, 0, Serialized)  // _INI: Initialize
                    {
                        Local0 = 0x7FFFFFFF
                        Local0 |= 0x80000000
                        Local1 = M04B (DADR, Zero)
                        If (((Local1 == Local0) || (Local1 == Zero)))
                        {
                            PCSA = Zero
                            PWST = 0xD3
                            PW3S = Zero
                        }
                        Else
                        {
                            PCSA = One
                            PWST = 0xD0
                            PW3S = One
                        }

                        If ((PCSA == One))
                        {
                            If ((M641 == 0x33))
                            {
                                Local2 = M646 (DADR, 0x10)
                                M641 = Local2
                            }

                            If ((M640 == 0x33))
                            {
                                Local2 = M646 (DADR, One)
                                M640 = Local2
                            }

                            If ((DVTP == 0xEE))
                            {
                                Local1 = M049 (DADR, 0x0E)
                                Local1 &= 0x3F
                                If ((Local1 == Zero))
                                {
                                    DVTP = Zero
                                }

                                If ((Local1 == One))
                                {
                                    DVTP = One
                                }
                            }
                        }

                        M460 ("  OEM-ASL-PCIe Address (0x%X)._INI  PCSA = 0x%X  PWST = 0x%X  PW3S = 0x%X  DVTP = 0x%X\n", DADR, PCSA, PWST, PW3S, DVTP, Zero)
                        If (CondRefOf (SINI))
                        {
                            SINI ()
                        }
                    }

                    Method (_REG, 2, Serialized)  // _REG: Region Availability
                    {
                        If (((Arg0 == 0x02) && (Arg1 == One)))
                        {
                            If ((DSTA == 0x0F))
                            {
                                If (((M049 (DADR, 0x04) & 0xFC) == 0x04))
                                {
                                    PCSA = One
                                }
                            }
                        }

                        If (((Arg0 == 0x02) && (Arg1 == Zero)))
                        {
                            PCSA = Zero
                        }

                        If (CondRefOf (SREG))
                        {
                            SREG (Arg0, Arg1)
                        }

                        M460 ("  OEM-ASL-PCIe Address (0x%X)._REG (%d %d)  PCSA = %d\n", DADR, Arg0, Arg1, PCSA, Zero, Zero)
                    }
                }

                Device (DP00)
                {
                    Name (_ADR, Zero)  // _ADR: Address
                }

                Device (DP08)
                {
                    Name (_ADR, 0x00010000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (EP00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                        Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                        {
                            Return (Zero)
                        }
                    }
                }

                Device (DP10)
                {
                    Name (_ADR, 0x00020000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (WN00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                    }
                }

                Device (DP18)
                {
                    Name (_ADR, 0x00030000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (LN00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                        Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                        {
                            Return (Zero)
                        }
                    }
                }

                Device (DP20)
                {
                    Name (_ADR, 0x00040000)  // _ADR: Address
                }

                Device (DP28)
                {
                    Name (_ADR, 0x00050000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (EP00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                        Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                        {
                            Return (Zero)
                        }
                    }
                }

                Device (DP30)
                {
                    Name (_ADR, 0x00060000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (EP00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                        Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                        {
                            Return (Zero)
                        }
                    }
                }

                Device (DP38)
                {
                    Name (_ADR, 0x00070000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (EP00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                        Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                        {
                            Return (Zero)
                        }
                    }
                }

                Device (DP40)
                {
                    Name (_ADR, 0x00080000)  // _ADR: Address
                }

                Device (DP48)
                {
                    Name (_ADR, 0x00090000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (EP00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                        Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                        {
                            Return (Zero)
                        }
                    }
                }

                Device (DP50)
                {
                    Name (_ADR, 0x000A0000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (EP00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                        Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                        {
                            Return (Zero)
                        }
                    }
                }

                Device (DP58)
                {
                    Name (_ADR, 0x000B0000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (EP00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                        Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                        {
                            Return (Zero)
                        }
                    }
                }

                Device (DP60)
                {
                    Name (_ADR, 0x000C0000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (XH00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                        Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                        {
                            Return (Zero)
                        }
                    }
                }

                Device (DP68)
                {
                    Name (_ADR, 0x000D0000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (SA00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                        Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                        {
                            Return (Zero)
                        }
                    }
                }
            }
        }
    }

    If (((G002 != 0x03) && ((G000 == One) && (
        G004 != 0x43FA1022))))
    {
        Scope (\_SB.PCI0.GPP7.UP00.DP60.XH00)
        {
            Device (RHUB)
            {
                Name (_ADR, Zero)  // _ADR: Address
                Name (PTGN, Package (0x16)
                {
                    0x0B, 
                    0x0C, 
                    0x0D, 
                    0x0E, 
                    0x0F, 
                    0x10, 
                    0x0B, 
                    0x0C, 
                    0x0D, 
                    0x0E, 
                    0x0F, 
                    0x10, 
                    0x11, 
                    0x12, 
                    0x13, 
                    0x14, 
                    0x15, 
                    0x16, 
                    0x17, 
                    0x18, 
                    0x19, 
                    0x1A
                })
                Method (GUPC, 2, Serialized)
                {
                    Name (PCKG, Package (0x04)
                    {
                        Zero, 
                        0xFF, 
                        Zero, 
                        Zero
                    })
                    If ((Arg0 > 0x06))
                    {
                        Local0 = ((Arg0 - 0x06) + 0x07)
                    }
                    Else
                    {
                        Local0 = (Arg0 - One)
                    }

                    Local5 = 0x000F3434
                    If ((Local5 & (One << Local0)))
                    {
                        If ((Arg0 <= 0x06))
                        {
                            PCKG [Zero] = 0xFF
                            PCKG [One] = 0x03
                        }
                        Else
                        {
                            Local1 = (Arg0 - 0x07)
                            If ((Local5 & (One << Local1)))
                            {
                                PCKG [Zero] = 0xFF
                                PCKG [One] = 0x03
                            }
                            Else
                            {
                                PCKG [Zero] = 0xFF
                                PCKG [One] = Zero
                            }
                        }
                    }

                    If ((Arg0 > 0x06))
                    {
                        Local2 = (Arg0 - 0x07)
                        If ((One & (One << Local2)))
                        {
                            Local3 = 0x03
                            If (Local3)
                            {
                                Local4 = Zero
                                While (Local3)
                                {
                                    If ((Local3 & One))
                                    {
                                        Local4 += One
                                    }

                                    Local3 >>= One
                                }

                                If ((Local4 > One))
                                {
                                    PCKG [Zero] = 0xFF
                                    PCKG [One] = 0x0A
                                }
                                Else
                                {
                                    PCKG [Zero] = 0xFF
                                    PCKG [One] = 0x09
                                }
                            }
                            Else
                            {
                                PCKG [Zero] = 0xFF
                                PCKG [One] = 0x08
                            }
                        }
                    }
                    Else
                    {
                        Local2 = (Arg0 - One)
                        Local3 = 0x03
                        If ((Local3 & (One << Local2)))
                        {
                            Local4 = Zero
                            While (Local3)
                            {
                                If ((Local3 & One))
                                {
                                    Local4 += One
                                }

                                Local3 >>= One
                            }

                            If ((Local4 > One))
                            {
                                PCKG [Zero] = 0xFF
                                PCKG [One] = 0x0A
                            }
                            Else
                            {
                                PCKG [Zero] = 0xFF
                                PCKG [One] = 0x09
                            }
                        }
                    }

                    Return (PCKG) /* \_SB_.PCI0.GPP7.UP00.DP60.XH00.RHUB.GUPC.PCKG */
                }

                Method (GPLD, 2, Serialized)
                {
                    Name (PCKG, Package (0x01)
                    {
                        Buffer (0x14)
                        {
                            /* 0000 */  0x82, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                            /* 0008 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                            /* 0010 */  0xFF, 0xFF, 0xFF, 0xFF                           // ....
                        }
                    })
                    CreateField (DerefOf (PCKG [Zero]), 0x40, One, VISI)
                    CreateField (DerefOf (PCKG [Zero]), 0x57, 0x08, GPOS)
                    Local0 = Zero
                    Local1 = Zero
                    If ((Arg0 > 0x06))
                    {
                        Local0 = ((Arg0 - 0x06) + 0x07)
                    }
                    Else
                    {
                        Local0 = (Arg0 - One)
                    }

                    Local1 = 0x000F3434
                    Local1 |= 0x0103
                    If ((Local1 & (One << Local0)))
                    {
                        VISI = One
                    }
                    Else
                    {
                        VISI = Zero
                    }

                    If ((0x0103 & (One << Local0)))
                    {
                        Local2 = 0x03
                        If ((Arg1 == One))
                        {
                            Local2 &= 0xFFFFFFFD
                        }

                        If ((Local2 & (One << Local0)))
                        {
                            Local3 = Zero
                            While (Local2)
                            {
                                If ((Local2 & One))
                                {
                                    Break
                                }

                                Local3 += One
                                Local2 >>= One
                            }
                        }
                        ElseIf ((0x0100 & (One << Local0)))
                        {
                            Local3 = Zero
                            While (Local2)
                            {
                                If ((Local2 & One))
                                {
                                    Break
                                }

                                Local3 += One
                                Local2 >>= One
                            }
                        }
                    }
                    Else
                    {
                        Local3 = (Arg0 - One)
                    }

                    GPOS = DerefOf (PTGN [Local3])
                    Return (PCKG) /* \_SB_.PCI0.GPP7.UP00.DP60.XH00.RHUB.GPLD.PCKG */
                }

                Device (POT1)
                {
                    Name (_ADR, One)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (One, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (One, One))
                    }
                }

                Device (POT7)
                {
                    Name (_ADR, 0x06)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x07, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x07, One))
                    }
                }

                Device (POT8)
                {
                    Name (_ADR, 0x10)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x08, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x08, One))
                    }
                }

                Device (POT3)
                {
                    Name (_ADR, 0x02)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x03, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x03, One))
                    }
                }

                Device (POT9)
                {
                    Name (_ADR, 0x07)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x09, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x09, One))
                    }
                }

                Device (POT4)
                {
                    Name (_ADR, 0x03)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x04, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x04, One))
                    }
                }

                Device (POTA)
                {
                    Name (_ADR, 0x08)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x0A, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x0A, One))
                    }
                }

                Device (POT5)
                {
                    Name (_ADR, 0x04)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x05, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x05, One))
                    }
                }

                Device (POTB)
                {
                    Name (_ADR, 0x09)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x0B, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x0B, One))
                    }
                }

                Device (POT6)
                {
                    Name (_ADR, 0x05)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x06, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x06, One))
                    }
                }

                Device (POTC)
                {
                    Name (_ADR, 0x0A)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x0C, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x0C, One))
                    }
                }

                Device (POTD)
                {
                    Name (_ADR, 0x0B)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x0D, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x0D, One))
                    }
                }

                Device (POTE)
                {
                    Name (_ADR, 0x0C)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x0E, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x0E, One))
                    }
                }

                Device (POTF)
                {
                    Name (_ADR, 0x0D)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x0F, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x0F, One))
                    }
                }

                Device (POTG)
                {
                    Name (_ADR, 0x0E)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x10, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x10, One))
                    }
                }

                Device (POTH)
                {
                    Name (_ADR, 0x0F)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x11, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x11, One))
                    }
                }

                Device (POTI)
                {
                    Name (_ADR, 0x11)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x12, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x12, One))
                    }
                }
            }
        }
    }

    If (((G002 != 0x03) && (G000 == 0x02)))
    {
        Scope (\_SB.PCI0.GPP7)
        {
            Device (XH00)
            {
                Name (_ADR, Zero)  // _ADR: Address
                Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                {
                    0x02, 
                    0x04
                })
            }

            Device (EP01)
            {
                Name (_ADR, One)  // _ADR: Address
                Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                {
                    0x02, 
                    0x04
                })
            }

            Device (UP02)
            {
                Name (_ADR, 0x02)  // _ADR: Address
                Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                {
                    0x02, 
                    0x04
                })
                If ((G002 >= 0x04))
                {
                    Name (DVTP, 0xEE)
                    Name (DADR, 0xEEEEEEEE)
                    Name (DSTA, 0xEE)
                    Name (DBUS, 0xEEEE)
                    Name (PCSA, Zero)
                    Name (PWST, 0xD3)
                    Name (ESTA, 0xEE)
                    Name (EBUS, 0xEEEE)
                    Name (PW3S, Zero)
                    Name (FLG0, 0xEE)
                    Name (M640, 0x33)
                    Name (M641, 0x33)
                    Name (M642, 0x33)
                    Method (_STA, 0, Serialized)  // _STA: Status
                    {
                        Local5 = Zero
                        If ((CondRefOf (^^FLG0) && CondRefOf (^^EBUS)))
                        {
                            Local5 |= One
                            If (((^^FLG0 == 0x16) && (^^EBUS != DBUS)))
                            {
                                Local5 |= 0x02
                                M640 = 0x33
                                M641 = 0x33
                                M642 = 0x33
                                FLG0 = 0xEE
                                ESTA = 0xEE
                                DBUS = 0xEEEE
                                DADR = 0xEEEEEEEE
                            }
                        }

                        If (((DSTA == 0xEE) || (ESTA == 0xEE)))
                        {
                            Local5 |= 0x04
                            If ((DBUS == 0xEEEE))
                            {
                                If (CondRefOf (^^EBUS))
                                {
                                    Local5 |= 0x08
                                    DBUS = ^^EBUS /* \_SB_.PCI0.GPP7.EBUS */
                                }
                                Else
                                {
                                    Local5 |= 0x10
                                    DBUS = Zero
                                }
                            }

                            If ((DBUS != 0xEEEE))
                            {
                                Local5 |= 0x20
                                If ((DADR == 0xEEEEEEEE))
                                {
                                    Local5 |= 0x40
                                    Local0 = (((_ADR << 0x0C) & 0x7000) | ((_ADR >> 
                                        One) & 0x000F8000))
                                    Local0 |= ((DBUS << 0x14) & 0x0FF00000)
                                    DADR = (M083 + Local0)
                                }

                                Local0 = 0x7FFFFFFF
                                Local0 |= 0x80000000
                                Local1 = M04B (DADR, Zero)
                                If (((Local1 == Local0) || (Local1 == Zero)))
                                {
                                    Local5 |= 0x80
                                    DSTA = Zero
                                    ESTA = Zero
                                    If ((DBUS != Zero))
                                    {
                                        Local5 |= 0x0100
                                        If ((CondRefOf (^^M641) && CondRefOf (^^DADR)))
                                        {
                                            If ((^^M641 == 0x33))
                                            {
                                                Local5 |= 0x0200
                                                Local2 = M646 (^^DADR, 0x10)
                                                ^^M641 = Local2
                                            }
                                            Else
                                            {
                                                Local5 |= 0x0400
                                                Local2 = ^^M641 /* \_SB_.PCI0.GPP7.M641 */
                                            }

                                            If (((M049 (^^DADR, (Local2 + 0x14)) & 0x40) == 0x40))
                                            {
                                                Local5 |= 0x0800
                                                DSTA = 0x0F
                                                ESTA = 0xEE
                                            }
                                        }
                                    }
                                }
                                ElseIf ((M04A (DADR, 0x0A) == 0x0604))
                                {
                                    EBUS = ((M04B (DADR, 0x18) >> 0x08) & 0xFF)
                                    If ((M641 == 0x33))
                                    {
                                        Local5 |= 0x1000
                                        Local2 = M646 (DADR, 0x10)
                                        M641 = Local2
                                    }
                                    Else
                                    {
                                        Local5 |= 0x2000
                                        Local2 = M641 /* \_SB_.PCI0.GPP7.UP02.M641 */
                                    }

                                    Local3 = ((M049 (DADR, (Local2 + 0x02)) >> 0x04) & 0x0F)
                                    If ((Local3 == 0x05))
                                    {
                                        If ((EBUS == Zero))
                                        {
                                            Local5 |= 0x4000
                                            DSTA = 0x0F
                                            ESTA = 0xEE
                                        }
                                        ElseIf ((M648 (EBUS, 0x0D, Zero) == Zero))
                                        {
                                            Local5 |= 0x8000
                                            DSTA = Zero
                                            ESTA = Zero
                                        }
                                        Else
                                        {
                                            Local5 |= 0x00010000
                                            DSTA = 0x0F
                                            ESTA = 0x0F
                                        }
                                    }
                                    ElseIf (((M049 (DADR, (Local2 + 0x1A)) & 0x40) == 
                                        Zero))
                                    {
                                        If (((M049 (DADR, (Local2 + 0x14)) & 0x40) == Zero))
                                        {
                                            Local5 |= 0x00020000
                                            DSTA = Zero
                                            ESTA = Zero
                                        }
                                        Else
                                        {
                                            Local5 |= 0x00040000
                                            DSTA = 0x0F
                                            ESTA = 0xEE
                                        }
                                    }
                                    ElseIf ((EBUS == Zero))
                                    {
                                        Local5 |= 0x00080000
                                        DSTA = 0x0F
                                        ESTA = 0xEE
                                    }
                                    Else
                                    {
                                        Local5 |= 0x00100000
                                        DSTA = 0x0F
                                        ESTA = 0x0F
                                    }

                                    If (((FLG0 == 0xEE) && (Local3 == 0x06)))
                                    {
                                        If ((M642 == 0x33))
                                        {
                                            Local5 |= 0x00200000
                                            Local4 = M646 (DADR, 0x15)
                                        }
                                        Else
                                        {
                                            Local5 |= 0x00400000
                                            Local4 = M642 /* \_SB_.PCI0.GPP7.UP02.M642 */
                                        }

                                        If ((Local4 != Zero))
                                        {
                                            Local5 |= 0x00800000
                                            FLG0 = 0x16
                                        }
                                    }
                                }
                                Else
                                {
                                    Local5 |= 0x01000000
                                    DSTA = 0x0F
                                    ESTA = Zero
                                }
                            }
                            Else
                            {
                                Local5 |= 0x02000000
                                DSTA = Zero
                                ESTA = 0xEE
                            }
                        }

                        If ((FLG0 == 0x16))
                        {
                            Local5 |= 0x04000000
                            If ((M049 (DADR, 0x19) == Zero))
                            {
                                Local5 |= 0x08000000
                                ESTA = 0xEE
                            }
                        }

                        If ((((PCSA == One) && (PWST == 0xD3)) && (PW3S == One)))
                        {
                            Local5 |= 0x10000000
                            PWST = 0xD0
                        }

                        If ((((PCSA == Zero) && (PWST == 0xD0)) && (PW3S == Zero)))
                        {
                            Local5 |= 0x40000000
                            PWST = 0xD3
                        }

                        If (CondRefOf (SSTA))
                        {
                            SSTA ()
                        }

                        If ((DADR != 0xEEEEEEEE))
                        {
                            M460 ("  OEM-ASL-PCIe Address (0x%X)._STA = 0x%X  PWST = 0x%X  DBUS = 0x%X  ESTA = 0x%X  EBUS = 0x%X", DADR, DSTA, PWST, DBUS, ESTA, EBUS)
                            M460 ("  PCSA = 0x%X  PW3S = 0x%X  FLG0 = 0x%X  Local5 = 0x%X\n", PCSA, PW3S, FLG0, Local5, Zero, Zero)
                        }

                        Return (DSTA) /* \_SB_.PCI0.GPP7.UP02.DSTA */
                    }

                    Method (_INI, 0, Serialized)  // _INI: Initialize
                    {
                        Local0 = 0x7FFFFFFF
                        Local0 |= 0x80000000
                        Local1 = M04B (DADR, Zero)
                        If (((Local1 == Local0) || (Local1 == Zero)))
                        {
                            PCSA = Zero
                            PWST = 0xD3
                            PW3S = Zero
                        }
                        Else
                        {
                            PCSA = One
                            PWST = 0xD0
                            PW3S = One
                        }

                        If ((PCSA == One))
                        {
                            If ((M641 == 0x33))
                            {
                                Local2 = M646 (DADR, 0x10)
                                M641 = Local2
                            }

                            If ((M640 == 0x33))
                            {
                                Local2 = M646 (DADR, One)
                                M640 = Local2
                            }

                            If ((DVTP == 0xEE))
                            {
                                Local1 = M049 (DADR, 0x0E)
                                Local1 &= 0x3F
                                If ((Local1 == Zero))
                                {
                                    DVTP = Zero
                                }

                                If ((Local1 == One))
                                {
                                    DVTP = One
                                }
                            }
                        }

                        M460 ("  OEM-ASL-PCIe Address (0x%X)._INI  PCSA = 0x%X  PWST = 0x%X  PW3S = 0x%X  DVTP = 0x%X\n", DADR, PCSA, PWST, PW3S, DVTP, Zero)
                        If (CondRefOf (SINI))
                        {
                            SINI ()
                        }
                    }

                    Method (_REG, 2, Serialized)  // _REG: Region Availability
                    {
                        If (((Arg0 == 0x02) && (Arg1 == One)))
                        {
                            If ((DSTA == 0x0F))
                            {
                                If (((M049 (DADR, 0x04) & 0xFC) == 0x04))
                                {
                                    PCSA = One
                                }
                            }
                        }

                        If (((Arg0 == 0x02) && (Arg1 == Zero)))
                        {
                            PCSA = Zero
                        }

                        If (CondRefOf (SREG))
                        {
                            SREG (Arg0, Arg1)
                        }

                        M460 ("  OEM-ASL-PCIe Address (0x%X)._REG (%d %d)  PCSA = %d\n", DADR, Arg0, Arg1, PCSA, Zero, Zero)
                    }
                }

                Device (DP00)
                {
                    Name (_ADR, Zero)  // _ADR: Address
                }

                Device (DP40)
                {
                    Name (_ADR, 0x00040000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (NV00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                    }
                }

                Device (DP80)
                {
                    Name (_ADR, 0x00080000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (WN00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                    }
                }

                Device (DP90)
                {
                    Name (_ADR, 0x00090000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (LN00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                    }
                }
            }
        }

        Scope (\_SB.PCI0.GPP7.XH00)
        {
            Device (RHUB)
            {
                Name (_ADR, Zero)  // _ADR: Address
                Name (PTGN, Package (0x16)
                {
                    0x0B, 
                    0x0C, 
                    0x0D, 
                    0x0E, 
                    0x0F, 
                    0x10, 
                    0x0B, 
                    0x0C, 
                    0x0D, 
                    0x0E, 
                    0x0F, 
                    0x10, 
                    0x11, 
                    0x12, 
                    0x13, 
                    0x14, 
                    0x15, 
                    0x16, 
                    0x17, 
                    0x18, 
                    0x19, 
                    0x1A
                })
                Method (GUPC, 2, Serialized)
                {
                    Name (PCKG, Package (0x04)
                    {
                        Zero, 
                        0xFF, 
                        Zero, 
                        Zero
                    })
                    If ((Arg0 > 0x06))
                    {
                        Local0 = ((Arg0 - 0x06) + 0x07)
                    }
                    Else
                    {
                        Local0 = (Arg0 - One)
                    }

                    Local5 = 0x000F3434
                    If ((Local5 & (One << Local0)))
                    {
                        If ((Arg0 <= 0x06))
                        {
                            PCKG [Zero] = 0xFF
                            PCKG [One] = 0x03
                        }
                        Else
                        {
                            Local1 = (Arg0 - 0x07)
                            If ((Local5 & (One << Local1)))
                            {
                                PCKG [Zero] = 0xFF
                                PCKG [One] = 0x03
                            }
                            Else
                            {
                                PCKG [Zero] = 0xFF
                                PCKG [One] = Zero
                            }
                        }
                    }

                    If ((Arg0 > 0x06))
                    {
                        Local2 = (Arg0 - 0x07)
                        If ((One & (One << Local2)))
                        {
                            Local3 = 0x03
                            If (Local3)
                            {
                                Local4 = Zero
                                While (Local3)
                                {
                                    If ((Local3 & One))
                                    {
                                        Local4 += One
                                    }

                                    Local3 >>= One
                                }

                                If ((Local4 > One))
                                {
                                    PCKG [Zero] = 0xFF
                                    PCKG [One] = 0x0A
                                }
                                Else
                                {
                                    PCKG [Zero] = 0xFF
                                    PCKG [One] = 0x09
                                }
                            }
                            Else
                            {
                                PCKG [Zero] = 0xFF
                                PCKG [One] = 0x08
                            }
                        }
                    }
                    Else
                    {
                        Local2 = (Arg0 - One)
                        Local3 = 0x03
                        If ((Local3 & (One << Local2)))
                        {
                            Local4 = Zero
                            While (Local3)
                            {
                                If ((Local3 & One))
                                {
                                    Local4 += One
                                }

                                Local3 >>= One
                            }

                            If ((Local4 > One))
                            {
                                PCKG [Zero] = 0xFF
                                PCKG [One] = 0x0A
                            }
                            Else
                            {
                                PCKG [Zero] = 0xFF
                                PCKG [One] = 0x09
                            }
                        }
                    }

                    Return (PCKG) /* \_SB_.PCI0.GPP7.XH00.RHUB.GUPC.PCKG */
                }

                Method (GPLD, 2, Serialized)
                {
                    Name (PCKG, Package (0x01)
                    {
                        Buffer (0x14)
                        {
                            /* 0000 */  0x82, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                            /* 0008 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                            /* 0010 */  0xFF, 0xFF, 0xFF, 0xFF                           // ....
                        }
                    })
                    CreateField (DerefOf (PCKG [Zero]), 0x40, One, VISI)
                    CreateField (DerefOf (PCKG [Zero]), 0x57, 0x08, GPOS)
                    Local0 = Zero
                    Local1 = Zero
                    If ((Arg0 > 0x06))
                    {
                        Local0 = ((Arg0 - 0x06) + 0x07)
                    }
                    Else
                    {
                        Local0 = (Arg0 - One)
                    }

                    Local1 = 0x000F3434
                    Local1 |= 0x0103
                    If ((Local1 & (One << Local0)))
                    {
                        VISI = One
                    }
                    Else
                    {
                        VISI = Zero
                    }

                    If ((0x0103 & (One << Local0)))
                    {
                        Local2 = 0x03
                        If ((Arg1 == One))
                        {
                            Local2 &= 0xFFFFFFFD
                        }

                        If ((Local2 & (One << Local0)))
                        {
                            Local3 = Zero
                            While (Local2)
                            {
                                If ((Local2 & One))
                                {
                                    Break
                                }

                                Local3 += One
                                Local2 >>= One
                            }
                        }
                        ElseIf ((0x0100 & (One << Local0)))
                        {
                            Local3 = Zero
                            While (Local2)
                            {
                                If ((Local2 & One))
                                {
                                    Break
                                }

                                Local3 += One
                                Local2 >>= One
                            }
                        }
                    }
                    Else
                    {
                        Local3 = (Arg0 - One)
                    }

                    GPOS = DerefOf (PTGN [Local3])
                    Return (PCKG) /* \_SB_.PCI0.GPP7.XH00.RHUB.GPLD.PCKG */
                }

                Device (POT1)
                {
                    Name (_ADR, One)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (One, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (One, One))
                    }
                }

                Device (POT7)
                {
                    Name (_ADR, 0x06)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x07, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x07, One))
                    }
                }

                Device (POT8)
                {
                    Name (_ADR, 0x10)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x08, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x08, One))
                    }
                }

                Device (POT3)
                {
                    Name (_ADR, 0x02)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x03, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x03, One))
                    }
                }

                Device (POT9)
                {
                    Name (_ADR, 0x07)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x09, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x09, One))
                    }
                }

                Device (POT4)
                {
                    Name (_ADR, 0x03)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x04, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x04, One))
                    }
                }

                Device (POTA)
                {
                    Name (_ADR, 0x08)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x0A, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x0A, One))
                    }
                }

                Device (POT5)
                {
                    Name (_ADR, 0x04)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x05, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x05, One))
                    }
                }

                Device (POTB)
                {
                    Name (_ADR, 0x09)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x0B, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x0B, One))
                    }
                }

                Device (POT6)
                {
                    Name (_ADR, 0x05)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x06, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x06, One))
                    }
                }

                Device (POTC)
                {
                    Name (_ADR, 0x0A)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x0C, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x0C, One))
                    }
                }

                Device (POTD)
                {
                    Name (_ADR, 0x0B)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x0D, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x0D, One))
                    }
                }

                Device (POTE)
                {
                    Name (_ADR, 0x0C)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x0E, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x0E, One))
                    }
                }

                Device (POTF)
                {
                    Name (_ADR, 0x0D)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x0F, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x0F, One))
                    }
                }

                Device (POTG)
                {
                    Name (_ADR, 0x0E)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x10, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x10, One))
                    }
                }

                Device (POTH)
                {
                    Name (_ADR, 0x0F)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x11, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x11, One))
                    }
                }

                Device (POTI)
                {
                    Name (_ADR, 0x11)  // _ADR: Address
                    Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
                    {
                        Return (GUPC (0x12, One))
                    }

                    Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
                    {
                        Return (GPLD (0x12, One))
                    }
                }
            }
        }
    }

    If (((G002 < 0x03) && (G000 == One))){}
    If (((G002 != 0x03) && ((G000 == One) && (
        G002 != 0x04))))
    {
        Scope (\_SB.PCI0.GPP7.UP00.DP40)
        {
            Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
            {
                0x02, 
                0x04
            })
        }
    }

    If (((G002 != 0x03) && ((G000 == One) && (
        G002 != 0x05))))
    {
        Scope (\_SB.PCI0.GPP7.UP00.DP20)
        {
            Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
            {
                0x02, 
                0x04
            })
            Device (NV00)
            {
                Name (_ADR, Zero)  // _ADR: Address
                Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                {
                    0x02, 
                    0x04
                })
                Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                {
                    Return (Zero)
                }
            }
        }
    }

    If (((G002 != 0x03) && ((G000 == One) && (
        G002 != 0x06))))
    {
        Scope (\_SB.PCI0.GPP7.UP00.DP00)
        {
            Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
            {
                0x02, 
                0x04
            })
            Device (NV00)
            {
                Name (_ADR, Zero)  // _ADR: Address
                Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                {
                    0x02, 
                    0x04
                })
                Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                {
                    Return (Zero)
                }
            }
        }
    }

    If ((((G002 != 0x03) && (G000 == One)) && (
        (G002 != 0x04) && (G003 != Zero))))
    {
        Scope (\_SB.PCI0.GPP7.UP00.DP40)
        {
            Device (UP00)
            {
                Name (_ADR, Zero)  // _ADR: Address
                Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                {
                    0x02, 
                    0x04
                })
                Name (GPB1, 0x5A5A5A5A)
                Name (IOR0, 0x5A5A5A5A)
                Name (IOR1, 0x5A5A5A5A)
                Name (IOR2, 0x5A5A5A5A)
                Name (IOR3, 0x5A5A5A5A)
                Device (DP00)
                {
                    Name (_ADR, Zero)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (NV00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                        Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                        {
                            Return (Zero)
                        }
                    }
                }

                Device (DP08)
                {
                    Name (_ADR, 0x00010000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (EP00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                        Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                        {
                            Return (Zero)
                        }
                    }
                }

                Device (DP10)
                {
                    Name (_ADR, 0x00020000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (WN00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                    }
                }

                Device (DP18)
                {
                    Name (_ADR, 0x00030000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (LN00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                        Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                        {
                            Return (Zero)
                        }
                    }
                }

                Device (DP20)
                {
                    Name (_ADR, 0x00040000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (NV00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                        Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                        {
                            Return (Zero)
                        }
                    }
                }

                Device (DP28)
                {
                    Name (_ADR, 0x00050000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (EP00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                        Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                        {
                            Return (Zero)
                        }
                    }
                }

                Device (DP30)
                {
                    Name (_ADR, 0x00060000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (EP00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                        Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                        {
                            Return (Zero)
                        }
                    }
                }

                Device (DP38)
                {
                    Name (_ADR, 0x00070000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (EP00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                        Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                        {
                            Return (Zero)
                        }
                    }
                }

                Device (DP40)
                {
                    Name (_ADR, 0x00080000)  // _ADR: Address
                }

                Device (DP48)
                {
                    Name (_ADR, 0x00090000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (EP00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                        Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                        {
                            Return (Zero)
                        }
                    }
                }

                Device (DP50)
                {
                    Name (_ADR, 0x000A0000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (EP00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                        Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                        {
                            Return (Zero)
                        }
                    }
                }

                Device (DP58)
                {
                    Name (_ADR, 0x000B0000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (EP00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                        Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                        {
                            Return (Zero)
                        }
                    }
                }

                Device (DP60)
                {
                    Name (_ADR, 0x000C0000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (XH00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                        Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                        {
                            Return (Zero)
                        }
                    }
                }

                Device (DP68)
                {
                    Name (_ADR, 0x000D0000)  // _ADR: Address
                    Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                    {
                        0x02, 
                        0x04
                    })
                    Device (SA00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                        {
                            0x02, 
                            0x04
                        })
                        Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                        {
                            Return (Zero)
                        }
                    }
                }
            }
        }
    }

    If (((G000 == One) && ((G002 == 0x07) && (G003 != 
        Zero))))
    {
        Scope (\_SB.PCI0.GPP7.UP00.DP40.UP00.DP40)
        {
            Name (XHGP, 0x03)
        }
    }

    If ((((G002 != 0x03) && (G000 == One)) && (
        (G002 != 0x04) && ((G002 != 0x07) && (G003 != Zero)))))
    {
        Scope (\_SB.PCI0.GPP7.UP00.DP40.UP00.DP40)
        {
            Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
            {
                0x02, 
                0x04
            })
            Device (EP00)
            {
                Name (_ADR, Zero)  // _ADR: Address
                Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                {
                    0x02, 
                    0x04
                })
                Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                {
                    Return (Zero)
                }
            }
        }
    }

    If ((((G002 != 0x03) && (G000 == One)) && (
        (G002 != 0x04) && (G003 == Zero))))
    {
        Scope (\_SB.PCI0.GPP7.UP00.DP40)
        {
            Device (EP00)
            {
                Name (_ADR, Zero)  // _ADR: Address
                Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
                {
                    0x02, 
                    0x04
                })
                Method (_RMV, 0, Serialized)  // _RMV: Removal Status
                {
                    Return (Zero)
                }
            }
        }
    }

    If ((G002 != 0x03))
    {
        Scope (\_GPE)
        {
            Method (_L02, 0, Serialized)  // _Lxx: Level-Triggered GPE, xx=0x00-0xFF
            {
                M460 ("  OEM-ASL-\\_GPE._L02 ()\n", Zero, Zero, Zero, Zero, Zero, Zero)
                M460 ("  OEM-ASL-Notify (\\_SB.PCI0.GPP7, 0x00)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                Notify (\_SB.PCI0.GPP7, Zero) // Bus Check
                M460 ("  OEM-ASL-Notify (\\_SB.PCI0.GPP7, 0x02)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                Notify (\_SB.PCI0.GPP7, 0x02) // Device Wake
            }
        }
    }

    Scope (\_SB.PCI0.GP17)
    {
        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
        {
            0x19, 
            0x04
        })
    }

    Scope (\_SB.PCI0.GP17.XHC0)
    {
        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
        {
            0x19, 
            0x04
        })
    }

    Scope (\_SB.PCI0.GP17.XHC1)
    {
        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
        {
            0x19, 
            0x04
        })
    }

    Scope (\_SB.PCI0.GP17.VGA)
    {
        Name (DOSA, Zero)
        Method (_DOS, 1, NotSerialized)  // _DOS: Disable Output Switching
        {
            DOSA = Arg0
        }

        Method (_DOD, 0, NotSerialized)  // _DOD: Display Output Devices
        {
            M460 ("CPM-ASL-\\_SB.PCI0.GP17.VGA._DOD\n", Zero, Zero, Zero, Zero, Zero, Zero)
            Return (Package (0x07)
            {
                0x00010110, 
                0x00010210, 
                0x00010220, 
                0x00010230, 
                0x00010240, 
                0x00031000, 
                0x00032000
            })
        }

        Device (LCD)
        {
            Name (_ADR, 0x0110)  // _ADR: Address
            Name (BCLB, Package (0x34)
            {
                0x5A, 
                0x3C, 
                0x02, 
                0x04, 
                0x06, 
                0x08, 
                0x0A, 
                0x0C, 
                0x0E, 
                0x10, 
                0x12, 
                0x14, 
                0x16, 
                0x18, 
                0x1A, 
                0x1C, 
                0x1E, 
                0x20, 
                0x22, 
                0x24, 
                0x26, 
                0x28, 
                0x2A, 
                0x2C, 
                0x2E, 
                0x30, 
                0x32, 
                0x34, 
                0x36, 
                0x38, 
                0x3A, 
                0x3C, 
                0x3E, 
                0x40, 
                0x42, 
                0x44, 
                0x46, 
                0x48, 
                0x4A, 
                0x4C, 
                0x4E, 
                0x50, 
                0x52, 
                0x54, 
                0x56, 
                0x58, 
                0x5A, 
                0x5C, 
                0x5E, 
                0x60, 
                0x62, 
                0x64
            })
            Method (_BCL, 0, NotSerialized)  // _BCL: Brightness Control Levels
            {
                M460 ("CPM-ASL-\\_SB.PCI0.GP17.VGA.LCD._BCL\n", Zero, Zero, Zero, Zero, Zero, Zero)
                Return (BCLB) /* \_SB_.PCI0.GP17.VGA_.LCD_.BCLB */
            }

            Method (_BCM, 1, NotSerialized)  // _BCM: Brightness Control Method
            {
                M460 ("CPM-ASL-\\_SB.PCI0.GP17.VGA.LCD._BCM Arg0 = 0x%X\n", ToInteger (Arg0), Zero, Zero, Zero, Zero, Zero)
                Divide ((Arg0 * 0xFF), 0x64, Local1, Local0)
                AFN7 (Local0)
            }
        }
    }

    Scope (\_GPE)
    {
        Method (_L19, 0, NotSerialized)  // _Lxx: Level-Triggered GPE, xx=0x00-0xFF
        {
            Notify (\_SB.PCI0.GP17, 0x02) // Device Wake
            Notify (\_SB.PCI0.GP17.XHC0, 0x02) // Device Wake
            Notify (\_SB.PCI0.GP17.XHC1, 0x02) // Device Wake
            Notify (\_SB.PCI0.GP17.AZAL, 0x02) // Device Wake
            Notify (\_SB.PCI0.GP17.ACP, 0x02) // Device Wake
            Notify (\_SB.PWRB, 0x02) // Device Wake
        }
    }

    Scope (\_SB.PCI0.GP19.XHC2)
    {
        Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
        {
            0x1A, 
            0x04
        })
    }

    Scope (\_GPE)
    {
        Method (_L1A, 0, NotSerialized)  // _Lxx: Level-Triggered GPE, xx=0x00-0xFF
        {
            Notify (\_SB.PCI0.GP19.XHC2, 0x02) // Device Wake
        }
    }

    Name (TSOS, 0x75)
    Name (UR0I, 0x03)
    Name (UR1I, 0x0E)
    Name (UR2I, 0x05)
    Name (UR3I, 0x0F)
    Name (UR4I, 0x10)
    Name (IC0I, 0x0A)
    Name (IC1I, 0x0B)
    Name (IC2I, 0x04)
    Name (IC3I, 0x06)
    Name (IC4I, 0x16)
    If (CondRefOf (\_OSI))
    {
        If (\_OSI ("Windows 2009"))
        {
            TSOS = 0x50
        }

        If (\_OSI ("Windows 2015"))
        {
            TSOS = 0x70
        }
    }

    Scope (\_SB)
    {
        OperationRegion (SMIC, SystemMemory, 0xFED80000, 0x00800000)
        Field (SMIC, ByteAcc, NoLock, Preserve)
        {
            Offset (0x36A), 
            SMIB,   8
        }

        OperationRegion (SSMI, SystemIO, SMIB, 0x02)
        Field (SSMI, AnyAcc, NoLock, Preserve)
        {
            SMIW,   16
        }

        OperationRegion (ECMC, SystemIO, 0x72, 0x02)
        Field (ECMC, AnyAcc, NoLock, Preserve)
        {
            ECMI,   8, 
            ECMD,   8
        }

        IndexField (ECMI, ECMD, ByteAcc, NoLock, Preserve)
        {
            Offset (0x08), 
            FRTB,   32
        }

        OperationRegion (FRTP, SystemMemory, FRTB, 0x0100)
        Field (FRTP, AnyAcc, NoLock, Preserve)
        {
            PEBA,   32, 
            Offset (0x04), 
                ,   5, 
            IC0E,   1, 
            IC1E,   1, 
            IC2E,   1, 
            IC3E,   1, 
            IC4E,   1, 
            IC5E,   1, 
            UT0E,   1, 
            UT1E,   1, 
            I31E,   1, 
            I32E,   1, 
            I33E,   1, 
            UT2E,   1, 
                ,   1, 
            EMMD,   2, 
            UT4E,   1, 
            I30E,   1, 
                ,   1, 
            XHCE,   1, 
                ,   1, 
                ,   1, 
            UT3E,   1, 
            ESPI,   1, 
            EMME,   1, 
            HFPE,   1, 
            HD0E,   1, 
            Offset (0x08), 
            PCEF,   1, 
                ,   4, 
            IC0D,   1, 
            IC1D,   1, 
            IC2D,   1, 
            IC3D,   1, 
            IC4D,   1, 
            IC5D,   1, 
            UT0D,   1, 
            UT1D,   1, 
            I31D,   1, 
            I32D,   1, 
            I33D,   1, 
            UT2D,   1, 
                ,   1, 
            EHCD,   1, 
                ,   1, 
            UT4D,   1, 
            I30D,   1, 
                ,   1, 
            XHCD,   1, 
            SD_D,   1, 
                ,   1, 
            UT3D,   1, 
                ,   1, 
            EMD3,   1, 
                ,   2, 
            S03D,   1, 
            Offset (0x1C), 
            I30M,   1, 
            I31M,   1, 
            I32M,   1, 
            I33M,   1
        }

        OperationRegion (FCFG, SystemMemory, PEBA, 0x01000000)
        Field (FCFG, DWordAcc, NoLock, Preserve)
        {
            Offset (0xA3078), 
                ,   2, 
            LDQ0,   1, 
            Offset (0xA30CB), 
                ,   7, 
            AUSS,   1
        }

        OperationRegion (IOMX, SystemMemory, 0xFED80D00, 0x0100)
        Field (IOMX, AnyAcc, NoLock, Preserve)
        {
            Offset (0x15), 
            IM15,   8, 
            Offset (0x16), 
            IM16,   8, 
            Offset (0x1F), 
            IM1F,   8, 
            Offset (0x20), 
            IM20,   8, 
            Offset (0x44), 
            IM44,   8, 
            Offset (0x46), 
            IM46,   8, 
            Offset (0x4A), 
            IM4A,   8, 
            Offset (0x4B), 
            IM4B,   8, 
            Offset (0x57), 
            IM57,   8, 
            Offset (0x58), 
            IM58,   8, 
            Offset (0x68), 
            IM68,   8, 
            Offset (0x69), 
            IM69,   8, 
            Offset (0x6A), 
            IM6A,   8, 
            Offset (0x6B), 
            IM6B,   8, 
            Offset (0x6D), 
            IM6D,   8
        }

        OperationRegion (FACR, SystemMemory, 0xFED81E00, 0x0100)
        Field (FACR, AnyAcc, NoLock, Preserve)
        {
            Offset (0x80), 
                ,   28, 
            RD28,   1, 
                ,   1, 
            RQTY,   1, 
            Offset (0x84), 
                ,   28, 
            SD28,   1, 
                ,   1, 
            Offset (0xA0), 
            PGA0,   1
        }

        OperationRegion (LUIE, SystemMemory, 0xFEDC0020, 0x04)
        Field (LUIE, AnyAcc, NoLock, Preserve)
        {
            IER0,   1, 
            IER1,   1, 
            IER2,   1, 
            IER3,   1, 
            UOL0,   1, 
            UOL1,   1, 
            UOL2,   1, 
            UOL3,   1, 
            WUR0,   2, 
            WUR1,   2, 
            WUR2,   2, 
            WUR3,   2
        }

        Method (FRUI, 1, Serialized)
        {
            If ((Arg0 == Zero))
            {
                Return (IUA0) /* \_SB_.IUA0 */
            }
            ElseIf ((Arg0 == One))
            {
                Return (IUA1) /* \_SB_.IUA1 */
            }
            ElseIf ((Arg0 == 0x02))
            {
                Return (IUA2) /* \_SB_.IUA2 */
            }
            ElseIf ((Arg0 == 0x03))
            {
                Return (IUA3) /* \_SB_.IUA3 */
            }
            Else
            {
                Return (0x03)
            }
        }

        Method (FUIO, 1, Serialized)
        {
            If ((IER0 == One))
            {
                If ((WUR0 == Arg0))
                {
                    Return (Zero)
                }
            }

            If ((IER1 == One))
            {
                If ((WUR1 == Arg0))
                {
                    Return (One)
                }
            }

            If ((IER2 == One))
            {
                If ((WUR2 == Arg0))
                {
                    Return (0x02)
                }
            }

            If ((IER3 == One))
            {
                If ((WUR3 == Arg0))
                {
                    Return (0x03)
                }
            }

            Return (0x0F)
        }

        Method (SRAD, 2, Serialized)
        {
            Local0 = (Arg0 << One)
            Local0 += 0xFED81E40
            OperationRegion (ADCR, SystemMemory, Local0, 0x02)
            Field (ADCR, ByteAcc, NoLock, Preserve)
            {
                ADTD,   2, 
                ADPS,   1, 
                ADPD,   1, 
                ADSO,   1, 
                ADSC,   1, 
                ADSR,   1, 
                ADIS,   1, 
                ADDS,   3
            }

            ADIS = One
            ADSR = Zero
            Stall (Arg1)
            ADSR = One
            ADIS = Zero
            Stall (Arg1)
        }

        Method (DSAD, 2, Serialized)
        {
            Local0 = (Arg0 << One)
            Local0 += 0xFED81E40
            OperationRegion (ADCR, SystemMemory, Local0, 0x02)
            Field (ADCR, ByteAcc, NoLock, Preserve)
            {
                ADTD,   2, 
                ADPS,   1, 
                ADPD,   1, 
                ADSO,   1, 
                ADSC,   1, 
                ADSR,   1, 
                ADIS,   1, 
                ADDS,   3
            }

            If ((Arg1 != ADTD))
            {
                If ((Arg1 == Zero))
                {
                    ADTD = Zero
                    ADPD = One
                    Local0 = ADDS /* \_SB_.DSAD.ADDS */
                    While ((Local0 != 0x07))
                    {
                        Local0 = ADDS /* \_SB_.DSAD.ADDS */
                    }
                }

                If ((Arg1 == 0x03))
                {
                    ADPD = Zero
                    Local0 = ADDS /* \_SB_.DSAD.ADDS */
                    While ((Local0 != Zero))
                    {
                        Local0 = ADDS /* \_SB_.DSAD.ADDS */
                    }

                    ADTD = 0x03
                }
            }
        }

        Method (HSAD, 2, Serialized)
        {
            Local3 = (One << Arg0)
            Local0 = (Arg0 << One)
            Local0 += 0xFED81E40
            OperationRegion (ADCR, SystemMemory, Local0, 0x02)
            Field (ADCR, ByteAcc, NoLock, Preserve)
            {
                ADTD,   2, 
                ADPS,   1, 
                ADPD,   1, 
                ADSO,   1, 
                ADSC,   1, 
                ADSR,   1, 
                ADIS,   1, 
                ADDS,   3
            }

            If ((Arg1 != ADTD))
            {
                If ((Arg1 == Zero))
                {
                    PGA0 = One
                    ADTD = Zero
                    ADPD = One
                    Local0 = ADDS /* \_SB_.HSAD.ADDS */
                    While ((Local0 != 0x07))
                    {
                        Local0 = ADDS /* \_SB_.HSAD.ADDS */
                    }

                    RQTY = One
                    RD28 = One
                    Local0 = SD28 /* \_SB_.SD28 */
                    While (!Local0)
                    {
                        Local0 = SD28 /* \_SB_.SD28 */
                    }
                }

                If ((Arg1 == 0x03))
                {
                    RQTY = Zero
                    RD28 = One
                    Local0 = SD28 /* \_SB_.SD28 */
                    While (Local0)
                    {
                        Local0 = SD28 /* \_SB_.SD28 */
                    }

                    ADPD = Zero
                    Local0 = ADDS /* \_SB_.HSAD.ADDS */
                    While ((Local0 != Zero))
                    {
                        Local0 = ADDS /* \_SB_.HSAD.ADDS */
                    }

                    ADTD = 0x03
                    PGA0 = Zero
                }
            }
        }

        OperationRegion (FPIC, SystemIO, 0x0C00, 0x02)
        Field (FPIC, AnyAcc, NoLock, Preserve)
        {
            FPII,   8, 
            FPID,   8
        }

        IndexField (FPII, FPID, ByteAcc, NoLock, Preserve)
        {
            Offset (0xF4), 
            IUA0,   8, 
            Offset (0xF5), 
            IUA1,   8, 
            Offset (0xF8), 
            IUA2,   8, 
            Offset (0xF9), 
            IUA3,   8
        }

        Device (HFP1)
        {
            Name (_HID, "AMDI0060")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (HFPE)
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Name (RBUF, ResourceTemplate ()
                {
                    Memory32Fixed (ReadWrite,
                        0xFEC11000,         // Address Base
                        0x00000100,         // Address Length
                        )
                })
                Return (RBUF) /* \_SB_.HFP1._CRS.RBUF */
            }
        }

        Device (HID0)
        {
            Name (_HID, "AMDI0063")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (HD0E)
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Name (RBUF, ResourceTemplate ()
                {
                    Memory32Fixed (ReadWrite,
                        0xFEC13000,         // Address Base
                        0x00000200,         // Address Length
                        )
                    GpioInt (Edge, ActiveHigh, SharedAndWake, PullNone, 0x0000,
                        "\\_SB.GPIO", 0x00, ResourceConsumer, ,
                        )
                        {   // Pin list
                            0x00AB
                        }
                })
                Return (RBUF) /* \_SB_.HID0._CRS.RBUF */
            }
        }

        Device (GPIO)
        {
            Name (_HID, "AMDI0030")  // _HID: Hardware ID
            Name (_CID, "AMDI0030")  // _CID: Compatible ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Name (RBUF, ResourceTemplate ()
                {
                    Interrupt (ResourceConsumer, Level, ActiveLow, Shared, ,, )
                    {
                        0x00000007,
                    }
                    Memory32Fixed (ReadWrite,
                        0xFED81500,         // Address Base
                        0x00000400,         // Address Length
                        )
                })
                Return (RBUF) /* \_SB_.GPIO._CRS.RBUF */
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((TSOS >= 0x70))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }
        }

        Device (PPKG)
        {
            Name (_HID, "AMDI0052")  // _HID: Hardware ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }
        }

        Device (FUR0)
        {
            Name (_HID, "AMDI0020")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (BUF0, ResourceTemplate ()
                {
                    IRQ (Edge, ActiveHigh, Exclusive, )
                        {3}
                    Memory32Fixed (ReadWrite,
                        0xFEDC9000,         // Address Base
                        0x00001000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0xFEDC7000,         // Address Base
                        0x00001000,         // Address Length
                        )
                })
                CreateWordField (BUF0, One, IRQW)
                IRQW = (One << (UR0I & 0x0F))
                Return (BUF0) /* \_SB_.FUR0._CRS.BUF0 */
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((TSOS >= 0x70))
                {
                    If ((UT0E == One))
                    {
                        If ((FUIO (Zero) != 0x0F))
                        {
                            Return (Zero)
                        }

                        Return (0x0F)
                    }

                    Return (Zero)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_S0W, 0, NotSerialized)  // _S0W: S0 Device Wake State
            {
                If ((UT0D && UT0E))
                {
                    Return (0x04)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_PS0, 0, NotSerialized)  // _PS0: Power State 0
            {
                If ((UT0D && UT0E))
                {
                    DSAD (0x0B, Zero)
                }
            }

            Method (_PS3, 0, NotSerialized)  // _PS3: Power State 3
            {
                If ((UT0D && UT0E))
                {
                    DSAD (0x0B, 0x03)
                }
            }
        }

        Device (FUR1)
        {
            Name (_HID, "AMDI0020")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (BUF0, ResourceTemplate ()
                {
                    IRQ (Edge, ActiveHigh, Exclusive, )
                        {4}
                    Memory32Fixed (ReadWrite,
                        0xFEDCA000,         // Address Base
                        0x00001000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0xFEDC8000,         // Address Base
                        0x00001000,         // Address Length
                        )
                })
                CreateWordField (BUF0, One, IRQW)
                IRQW = (One << (UR1I & 0x0F))
                Return (BUF0) /* \_SB_.FUR1._CRS.BUF0 */
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((TSOS >= 0x70))
                {
                    If ((UT1E == One))
                    {
                        If ((FUIO (One) != 0x0F))
                        {
                            Return (Zero)
                        }

                        Return (0x0F)
                    }

                    Return (Zero)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_S0W, 0, NotSerialized)  // _S0W: S0 Device Wake State
            {
                If ((UT1D && UT1E))
                {
                    Return (0x04)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_PS0, 0, NotSerialized)  // _PS0: Power State 0
            {
                If ((UT1D && UT1E))
                {
                    DSAD (0x0C, Zero)
                }
            }

            Method (_PS3, 0, NotSerialized)  // _PS3: Power State 3
            {
                If ((UT1D && UT1E))
                {
                    DSAD (0x0C, 0x03)
                }
            }
        }

        Device (FUR2)
        {
            Name (_HID, "AMDI0020")  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (BUF0, ResourceTemplate ()
                {
                    IRQ (Edge, ActiveHigh, Exclusive, )
                        {3}
                    Memory32Fixed (ReadWrite,
                        0xFEDCE000,         // Address Base
                        0x00001000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0xFEDCC000,         // Address Base
                        0x00001000,         // Address Length
                        )
                })
                CreateWordField (BUF0, One, IRQW)
                IRQW = (One << (UR2I & 0x0F))
                Return (BUF0) /* \_SB_.FUR2._CRS.BUF0 */
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((TSOS >= 0x70))
                {
                    If ((UT2E == One))
                    {
                        If ((FUIO (0x02) != 0x0F))
                        {
                            Return (Zero)
                        }

                        Return (0x0F)
                    }

                    Return (Zero)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_S0W, 0, NotSerialized)  // _S0W: S0 Device Wake State
            {
                If ((UT2D && UT2E))
                {
                    Return (0x04)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_PS0, 0, NotSerialized)  // _PS0: Power State 0
            {
                If ((UT2D && UT2E))
                {
                    DSAD (0x10, Zero)
                }
            }

            Method (_PS3, 0, NotSerialized)  // _PS3: Power State 3
            {
                If ((UT2D && UT2E))
                {
                    DSAD (0x10, 0x03)
                }
            }
        }

        Device (FUR3)
        {
            Name (_HID, "AMDI0020")  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (BUF0, ResourceTemplate ()
                {
                    IRQ (Edge, ActiveHigh, Exclusive, )
                        {4}
                    Memory32Fixed (ReadWrite,
                        0xFEDCF000,         // Address Base
                        0x00001000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0xFEDCD000,         // Address Base
                        0x00001000,         // Address Length
                        )
                })
                CreateWordField (BUF0, One, IRQW)
                IRQW = (One << (UR3I & 0x0F))
                Return (BUF0) /* \_SB_.FUR3._CRS.BUF0 */
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((TSOS >= 0x70))
                {
                    If ((UT3E == One))
                    {
                        If ((FUIO (0x03) != 0x0F))
                        {
                            Return (Zero)
                        }

                        Return (0x0F)
                    }

                    Return (Zero)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_S0W, 0, NotSerialized)  // _S0W: S0 Device Wake State
            {
                If ((UT3D && UT3E))
                {
                    Return (0x04)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_PS0, 0, NotSerialized)  // _PS0: Power State 0
            {
                If ((UT3D && UT3E))
                {
                    DSAD (0x1A, Zero)
                }
            }

            Method (_PS3, 0, NotSerialized)  // _PS3: Power State 3
            {
                If ((UT3D && UT3E))
                {
                    DSAD (0x1A, 0x03)
                }
            }
        }

        Device (FUR4)
        {
            Name (_HID, "AMDI0020")  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (BUF0, ResourceTemplate ()
                {
                    IRQ (Edge, ActiveHigh, Exclusive, )
                        {15}
                    Memory32Fixed (ReadWrite,
                        0xFEDD1000,         // Address Base
                        0x00001000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0xFEDD0000,         // Address Base
                        0x00001000,         // Address Length
                        )
                })
                CreateWordField (BUF0, One, IRQW)
                IRQW = (One << (UR4I & 0x0F))
                Return (BUF0) /* \_SB_.FUR4._CRS.BUF0 */
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((TSOS >= 0x70))
                {
                    If ((UT4E == One))
                    {
                        Return (0x0F)
                    }

                    Return (Zero)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_S0W, 0, NotSerialized)  // _S0W: S0 Device Wake State
            {
                If ((UT4D && UT4E))
                {
                    Return (0x04)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_PS0, 0, NotSerialized)  // _PS0: Power State 0
            {
                If ((UT4D && UT4E))
                {
                    DSAD (0x14, Zero)
                }
            }

            Method (_PS3, 0, NotSerialized)  // _PS3: Power State 3
            {
                If ((UT4D && UT4E))
                {
                    DSAD (0x14, 0x03)
                }
            }
        }

        Device (I2CA)
        {
            Name (_HID, "AMDI0010")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (BUF0, ResourceTemplate ()
                {
                    IRQ (Edge, ActiveHigh, Exclusive, )
                        {10}
                    Memory32Fixed (ReadWrite,
                        0xFEDC2000,         // Address Base
                        0x00001000,         // Address Length
                        )
                })
                CreateWordField (BUF0, One, IRQW)
                IRQW = (One << (IC0I & 0x0F))
                Return (BUF0) /* \_SB_.I2CA._CRS.BUF0 */
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((TSOS >= 0x70))
                {
                    If ((IC0E == One))
                    {
                        Return (0x0F)
                    }

                    Return (Zero)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
            {
                If ((Arg0 == ToUUID ("d93e4d1c-58bb-493c-a06a-605a717f9e2e") /* Unknown UUID */))
                {
                    Switch (ToInteger (Arg2))
                    {
                        Case (Zero)
                        {
                            Return (Buffer (One)
                            {
                                 0x03                                             // .
                            })
                        }
                        Case (One)
                        {
                            Return (Buffer (0x04)
                            {
                                 0xE5, 0x00, 0x6A, 0x00                           // ..j.
                            })
                        }

                    }
                }
                Else
                {
                    Return (Buffer (One)
                    {
                         0x00                                             // .
                    })
                }
            }

            Method (RSET, 0, NotSerialized)
            {
                SRAD (0x05, 0xC8)
            }

            Method (_S0W, 0, NotSerialized)  // _S0W: S0 Device Wake State
            {
                If ((IC0D && IC0E))
                {
                    Return (0x04)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_PS0, 0, NotSerialized)  // _PS0: Power State 0
            {
                If ((IC0D && IC0E))
                {
                    DSAD (0x05, Zero)
                }
            }

            Method (_PS3, 0, NotSerialized)  // _PS3: Power State 3
            {
                If ((IC0D && IC0E))
                {
                    DSAD (0x05, 0x03)
                }
            }
        }

        Device (I2CB)
        {
            Name (_HID, "AMDI0010")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (BUF0, ResourceTemplate ()
                {
                    IRQ (Edge, ActiveHigh, Exclusive, )
                        {11}
                    Memory32Fixed (ReadWrite,
                        0xFEDC3000,         // Address Base
                        0x00001000,         // Address Length
                        )
                })
                CreateWordField (BUF0, One, IRQW)
                IRQW = (One << (IC1I & 0x0F))
                Return (BUF0) /* \_SB_.I2CB._CRS.BUF0 */
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((TSOS >= 0x70))
                {
                    If ((IC1E == One))
                    {
                        Return (0x0F)
                    }

                    Return (Zero)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
            {
                If ((Arg0 == ToUUID ("d93e4d1c-58bb-493c-a06a-605a717f9e2e") /* Unknown UUID */))
                {
                    Switch (ToInteger (Arg2))
                    {
                        Case (Zero)
                        {
                            Return (Buffer (One)
                            {
                                 0x03                                             // .
                            })
                        }
                        Case (One)
                        {
                            Return (Buffer (0x04)
                            {
                                 0xE5, 0x00, 0x6A, 0x00                           // ..j.
                            })
                        }

                    }
                }
                Else
                {
                    Return (Buffer (One)
                    {
                         0x00                                             // .
                    })
                }
            }

            Method (RSET, 0, NotSerialized)
            {
                SRAD (0x06, 0xC8)
            }

            Method (_S0W, 0, NotSerialized)  // _S0W: S0 Device Wake State
            {
                If ((IC1D && IC1E))
                {
                    Return (0x04)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_PS0, 0, NotSerialized)  // _PS0: Power State 0
            {
                If ((IC1D && IC1E))
                {
                    DSAD (0x06, Zero)
                }
            }

            Method (_PS3, 0, NotSerialized)  // _PS3: Power State 3
            {
                If ((IC1D && IC1E))
                {
                    DSAD (0x06, 0x03)
                }
            }
        }

        Device (I2CC)
        {
            Name (_HID, "AMDI0010")  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (BUF0, ResourceTemplate ()
                {
                    IRQ (Edge, ActiveHigh, Exclusive, )
                        {4}
                    Memory32Fixed (ReadWrite,
                        0xFEDC4000,         // Address Base
                        0x00001000,         // Address Length
                        )
                })
                CreateWordField (BUF0, One, IRQW)
                IRQW = (One << (IC2I & 0x0F))
                Return (BUF0) /* \_SB_.I2CC._CRS.BUF0 */
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((TSOS >= 0x70))
                {
                    If ((IC2E == One))
                    {
                        Return (0x0F)
                    }

                    Return (Zero)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
            {
                If ((Arg0 == ToUUID ("d93e4d1c-58bb-493c-a06a-605a717f9e2e") /* Unknown UUID */))
                {
                    Switch (ToInteger (Arg2))
                    {
                        Case (Zero)
                        {
                            Return (Buffer (One)
                            {
                                 0x03                                             // .
                            })
                        }
                        Case (One)
                        {
                            Return (Buffer (0x04)
                            {
                                 0xE5, 0x00, 0x6A, 0x00                           // ..j.
                            })
                        }

                    }
                }
                Else
                {
                    Return (Buffer (One)
                    {
                         0x00                                             // .
                    })
                }
            }

            Method (RSET, 0, NotSerialized)
            {
                SRAD (0x07, 0xC8)
            }

            Method (_S0W, 0, NotSerialized)  // _S0W: S0 Device Wake State
            {
                If ((IC2D && IC2E))
                {
                    Return (0x04)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_PS0, 0, NotSerialized)  // _PS0: Power State 0
            {
                If ((IC2D && IC2E))
                {
                    DSAD (0x07, Zero)
                }
            }

            Method (_PS3, 0, NotSerialized)  // _PS3: Power State 3
            {
                If ((IC2D && IC2E))
                {
                    DSAD (0x07, 0x03)
                }
            }
        }

        Device (I2CD)
        {
            Name (_HID, "AMDI0010")  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (BUF0, ResourceTemplate ()
                {
                    IRQ (Edge, ActiveHigh, Exclusive, )
                        {6}
                    Memory32Fixed (ReadWrite,
                        0xFEDC5000,         // Address Base
                        0x00001000,         // Address Length
                        )
                })
                CreateWordField (BUF0, One, IRQW)
                IRQW = (One << (IC3I & 0x0F))
                Return (BUF0) /* \_SB_.I2CD._CRS.BUF0 */
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((TSOS >= 0x70))
                {
                    If ((IC3E == One))
                    {
                        Return (0x0F)
                    }

                    Return (Zero)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
            {
                If ((Arg0 == ToUUID ("d93e4d1c-58bb-493c-a06a-605a717f9e2e") /* Unknown UUID */))
                {
                    Switch (ToInteger (Arg2))
                    {
                        Case (Zero)
                        {
                            Return (Buffer (One)
                            {
                                 0x03                                             // .
                            })
                        }
                        Case (One)
                        {
                            Return (Buffer (0x04)
                            {
                                 0xE5, 0x00, 0x6A, 0x00                           // ..j.
                            })
                        }

                    }
                }
                Else
                {
                    Return (Buffer (One)
                    {
                         0x00                                             // .
                    })
                }
            }

            Method (RSET, 0, NotSerialized)
            {
                SRAD (0x08, 0xC8)
            }

            Method (_S0W, 0, NotSerialized)  // _S0W: S0 Device Wake State
            {
                If ((IC3D && IC3E))
                {
                    Return (0x04)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_PS0, 0, NotSerialized)  // _PS0: Power State 0
            {
                If ((IC3D && IC3E))
                {
                    DSAD (0x08, Zero)
                }
            }

            Method (_PS3, 0, NotSerialized)  // _PS3: Power State 3
            {
                If ((IC3D && IC3E))
                {
                    DSAD (0x08, 0x03)
                }
            }
        }

        Name (I3ID, "AMDI0015")
        Name (I2ID, "AMDI0016")
        Device (I3CA)
        {
            Method (_HID, 0, Serialized)  // _HID: Hardware ID
            {
                If ((I30M == Zero))
                {
                    Return (I3ID) /* \_SB_.I3ID */
                }
                Else
                {
                    Return (I2ID) /* \_SB_.I2ID */
                }
            }

            Name (_UID, Zero)  // _UID: Unique ID
            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (BUF0, ResourceTemplate ()
                {
                    IRQ (Edge, ActiveHigh, Exclusive, )
                        {10}
                    Memory32Fixed (ReadWrite,
                        0xFEDD2000,         // Address Base
                        0x00001000,         // Address Length
                        )
                })
                CreateWordField (BUF0, One, IRQW)
                IRQW = (One << (IC0I & 0x0F))
                Return (BUF0) /* \_SB_.I3CA._CRS.BUF0 */
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((TSOS >= 0x70))
                {
                    If ((I30E == One))
                    {
                        Return (0x0F)
                    }

                    Return (Zero)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (RSET, 0, NotSerialized)
            {
                SRAD (0x15, 0xC8)
            }

            Method (_S0W, 0, NotSerialized)  // _S0W: S0 Device Wake State
            {
                If ((I30D && I30E))
                {
                    Return (0x04)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_PS0, 0, NotSerialized)  // _PS0: Power State 0
            {
                If ((I30D && I30E))
                {
                    DSAD (0x15, Zero)
                }
            }

            Method (_PS3, 0, NotSerialized)  // _PS3: Power State 3
            {
                If ((I30D && I30E))
                {
                    DSAD (0x15, 0x03)
                }
            }
        }

        Device (I3CB)
        {
            Method (_HID, 0, Serialized)  // _HID: Hardware ID
            {
                If ((I31M == Zero))
                {
                    Return (I3ID) /* \_SB_.I3ID */
                }
                Else
                {
                    Return (I2ID) /* \_SB_.I2ID */
                }
            }

            Name (_UID, One)  // _UID: Unique ID
            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (BUF0, ResourceTemplate ()
                {
                    IRQ (Edge, ActiveHigh, Exclusive, )
                        {11}
                    Memory32Fixed (ReadWrite,
                        0xFEDD3000,         // Address Base
                        0x00001000,         // Address Length
                        )
                })
                CreateWordField (BUF0, One, IRQW)
                IRQW = (One << (IC1I & 0x0F))
                Return (BUF0) /* \_SB_.I3CB._CRS.BUF0 */
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((TSOS >= 0x70))
                {
                    If ((I31E == One))
                    {
                        Return (0x0F)
                    }

                    Return (Zero)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (RSET, 0, NotSerialized)
            {
                SRAD (0x0D, 0xC8)
            }

            Method (_S0W, 0, NotSerialized)  // _S0W: S0 Device Wake State
            {
                If ((I31D && I31E))
                {
                    Return (0x04)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_PS0, 0, NotSerialized)  // _PS0: Power State 0
            {
                If ((I31D && I31E))
                {
                    DSAD (0x0D, Zero)
                }
            }

            Method (_PS3, 0, NotSerialized)  // _PS3: Power State 3
            {
                If ((I31D && I31E))
                {
                    DSAD (0x0D, 0x03)
                }
            }
        }

        Device (I3CC)
        {
            Method (_HID, 0, Serialized)  // _HID: Hardware ID
            {
                If ((I32M == Zero))
                {
                    Return (I3ID) /* \_SB_.I3ID */
                }
                Else
                {
                    Return (I2ID) /* \_SB_.I2ID */
                }
            }

            Name (_UID, 0x02)  // _UID: Unique ID
            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (BUF0, ResourceTemplate ()
                {
                    IRQ (Edge, ActiveHigh, Exclusive, )
                        {4}
                    Memory32Fixed (ReadWrite,
                        0xFEDD4000,         // Address Base
                        0x00001000,         // Address Length
                        )
                })
                CreateWordField (BUF0, One, IRQW)
                IRQW = (One << (IC2I & 0x0F))
                Return (BUF0) /* \_SB_.I3CC._CRS.BUF0 */
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((TSOS >= 0x70))
                {
                    If ((I32E == One))
                    {
                        Return (0x0F)
                    }

                    Return (Zero)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (RSET, 0, NotSerialized)
            {
                SRAD (0x0E, 0xC8)
            }

            Method (_S0W, 0, NotSerialized)  // _S0W: S0 Device Wake State
            {
                If ((I32D && I32E))
                {
                    Return (0x04)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_PS0, 0, NotSerialized)  // _PS0: Power State 0
            {
                If ((I32D && I32E))
                {
                    DSAD (0x0E, Zero)
                }
            }

            Method (_PS3, 0, NotSerialized)  // _PS3: Power State 3
            {
                If ((I32D && I32E))
                {
                    DSAD (0x0E, 0x03)
                }
            }
        }

        Device (I3CD)
        {
            Method (_HID, 0, Serialized)  // _HID: Hardware ID
            {
                If ((I33M == Zero))
                {
                    Return (I3ID) /* \_SB_.I3ID */
                }
                Else
                {
                    Return (I2ID) /* \_SB_.I2ID */
                }
            }

            Name (_UID, 0x03)  // _UID: Unique ID
            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (BUF0, ResourceTemplate ()
                {
                    IRQ (Edge, ActiveHigh, Exclusive, )
                        {6}
                    Memory32Fixed (ReadWrite,
                        0xFEDD6000,         // Address Base
                        0x00001000,         // Address Length
                        )
                })
                CreateWordField (BUF0, One, IRQW)
                IRQW = (One << (IC3I & 0x0F))
                Return (BUF0) /* \_SB_.I3CD._CRS.BUF0 */
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((TSOS >= 0x70))
                {
                    If ((I33E == One))
                    {
                        Return (0x0F)
                    }

                    Return (Zero)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (RSET, 0, NotSerialized)
            {
                SRAD (0x0F, 0xC8)
            }

            Method (_S0W, 0, NotSerialized)  // _S0W: S0 Device Wake State
            {
                If ((I33D && I33E))
                {
                    Return (0x04)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_PS0, 0, NotSerialized)  // _PS0: Power State 0
            {
                If ((I33D && I33E))
                {
                    DSAD (0x0F, Zero)
                }
            }

            Method (_PS3, 0, NotSerialized)  // _PS3: Power State 3
            {
                If ((I33D && I33E))
                {
                    DSAD (0x0F, 0x03)
                }
            }
        }
    }

    Scope (\_SB.PCI0)
    {
        Device (UAR1)
        {
            Name (_HID, EisaId ("PNP0500") /* Standard PC COM Serial Port */)  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_DDN, "COM1")  // _DDN: DOS Device Name
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((FUIO (Zero) != 0x0F))
                {
                    Return (0x0F)
                }

                Return (Zero)
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (BUF0, ResourceTemplate ()
                {
                    IO (Decode16,
                        0x02E8,             // Range Minimum
                        0x02E8,             // Range Maximum
                        0x01,               // Alignment
                        0x08,               // Length
                        _Y2C)
                    IRQNoFlags (_Y2D)
                        {3}
                })
                CreateByteField (BUF0, \_SB.PCI0.UAR1._CRS._Y2C._MIN, IOLO)  // _MIN: Minimum Base Address
                CreateByteField (BUF0, 0x03, IOHI)
                CreateByteField (BUF0, \_SB.PCI0.UAR1._CRS._Y2C._MAX, IORL)  // _MAX: Maximum Base Address
                CreateByteField (BUF0, 0x05, IORH)
                CreateWordField (BUF0, \_SB.PCI0.UAR1._CRS._Y2D._INT, IRQL)  // _INT: Interrupts
                Local0 = FUIO (Zero)
                Switch (ToInteger (Local0))
                {
                    Case (Zero)
                    {
                        IOLO = 0xE8
                        IOHI = 0x02
                        IORL = 0xE8
                        IORH = 0x02
                    }
                    Case (One)
                    {
                        IOLO = 0xF8
                        IOHI = 0x02
                        IORL = 0xF8
                        IORH = 0x02
                    }
                    Case (0x02)
                    {
                        IOLO = 0xE8
                        IOHI = 0x03
                        IORL = 0xE8
                        IORH = 0x03
                    }
                    Case (0x03)
                    {
                        IOLO = 0xF8
                        IOHI = 0x03
                        IORL = 0xF8
                        IORH = 0x03
                    }

                }

                IRQL = (One << (FRUI (Zero) & 0x0F))
                Return (BUF0) /* \_SB_.PCI0.UAR1._CRS.BUF0 */
            }
        }

        Device (UAR2)
        {
            Name (_HID, EisaId ("PNP0500") /* Standard PC COM Serial Port */)  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Name (_DDN, "COM2")  // _DDN: DOS Device Name
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((FUIO (One) != 0x0F))
                {
                    Return (0x0F)
                }

                Return (Zero)
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (BUF0, ResourceTemplate ()
                {
                    IO (Decode16,
                        0x02F8,             // Range Minimum
                        0x02F8,             // Range Maximum
                        0x01,               // Alignment
                        0x08,               // Length
                        _Y2E)
                    IRQNoFlags (_Y2F)
                        {4}
                })
                CreateByteField (BUF0, \_SB.PCI0.UAR2._CRS._Y2E._MIN, IOLO)  // _MIN: Minimum Base Address
                CreateByteField (BUF0, 0x03, IOHI)
                CreateByteField (BUF0, \_SB.PCI0.UAR2._CRS._Y2E._MAX, IORL)  // _MAX: Maximum Base Address
                CreateByteField (BUF0, 0x05, IORH)
                CreateWordField (BUF0, \_SB.PCI0.UAR2._CRS._Y2F._INT, IRQL)  // _INT: Interrupts
                Local0 = FUIO (One)
                Switch (ToInteger (Local0))
                {
                    Case (Zero)
                    {
                        IOLO = 0xE8
                        IOHI = 0x02
                        IORL = 0xE8
                        IORH = 0x02
                    }
                    Case (One)
                    {
                        IOLO = 0xF8
                        IOHI = 0x02
                        IORL = 0xF8
                        IORH = 0x02
                    }
                    Case (0x02)
                    {
                        IOLO = 0xE8
                        IOHI = 0x03
                        IORL = 0xE8
                        IORH = 0x03
                    }
                    Case (0x03)
                    {
                        IOLO = 0xF8
                        IOHI = 0x03
                        IORL = 0xF8
                        IORH = 0x03
                    }

                }

                IRQL = (One << (FRUI (One) & 0x0F))
                Return (BUF0) /* \_SB_.PCI0.UAR2._CRS.BUF0 */
            }
        }

        Device (UAR3)
        {
            Name (_HID, EisaId ("PNP0500") /* Standard PC COM Serial Port */)  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Name (_DDN, "COM3")  // _DDN: DOS Device Name
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((FUIO (0x02) != 0x0F))
                {
                    Return (0x0F)
                }

                Return (Zero)
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (BUF0, ResourceTemplate ()
                {
                    IO (Decode16,
                        0x03E8,             // Range Minimum
                        0x03E8,             // Range Maximum
                        0x01,               // Alignment
                        0x08,               // Length
                        _Y30)
                    IRQNoFlags (_Y31)
                        {3}
                })
                CreateByteField (BUF0, \_SB.PCI0.UAR3._CRS._Y30._MIN, IOLO)  // _MIN: Minimum Base Address
                CreateByteField (BUF0, 0x03, IOHI)
                CreateByteField (BUF0, \_SB.PCI0.UAR3._CRS._Y30._MAX, IORL)  // _MAX: Maximum Base Address
                CreateByteField (BUF0, 0x05, IORH)
                CreateWordField (BUF0, \_SB.PCI0.UAR3._CRS._Y31._INT, IRQL)  // _INT: Interrupts
                Local0 = FUIO (0x02)
                Switch (ToInteger (Local0))
                {
                    Case (Zero)
                    {
                        IOLO = 0xE8
                        IOHI = 0x02
                        IORL = 0xE8
                        IORH = 0x02
                    }
                    Case (One)
                    {
                        IOLO = 0xF8
                        IOHI = 0x02
                        IORL = 0xF8
                        IORH = 0x02
                    }
                    Case (0x02)
                    {
                        IOLO = 0xE8
                        IOHI = 0x03
                        IORL = 0xE8
                        IORH = 0x03
                    }
                    Case (0x03)
                    {
                        IOLO = 0xF8
                        IOHI = 0x03
                        IORL = 0xF8
                        IORH = 0x03
                    }

                }

                IRQL = (One << (FRUI (0x02) & 0x0F))
                Return (BUF0) /* \_SB_.PCI0.UAR3._CRS.BUF0 */
            }
        }

        Device (UAR4)
        {
            Name (_HID, EisaId ("PNP0500") /* Standard PC COM Serial Port */)  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Name (_DDN, "COM4")  // _DDN: DOS Device Name
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((FUIO (0x03) != 0x0F))
                {
                    Return (0x0F)
                }

                Return (Zero)
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (BUF0, ResourceTemplate ()
                {
                    IO (Decode16,
                        0x03F8,             // Range Minimum
                        0x03F8,             // Range Maximum
                        0x01,               // Alignment
                        0x08,               // Length
                        _Y32)
                    IRQNoFlags (_Y33)
                        {4}
                })
                CreateByteField (BUF0, \_SB.PCI0.UAR4._CRS._Y32._MIN, IOLO)  // _MIN: Minimum Base Address
                CreateByteField (BUF0, 0x03, IOHI)
                CreateByteField (BUF0, \_SB.PCI0.UAR4._CRS._Y32._MAX, IORL)  // _MAX: Maximum Base Address
                CreateByteField (BUF0, 0x05, IORH)
                CreateWordField (BUF0, \_SB.PCI0.UAR4._CRS._Y33._INT, IRQL)  // _INT: Interrupts
                Local0 = FUIO (0x03)
                Switch (ToInteger (Local0))
                {
                    Case (Zero)
                    {
                        IOLO = 0xE8
                        IOHI = 0x02
                        IORL = 0xE8
                        IORH = 0x02
                    }
                    Case (One)
                    {
                        IOLO = 0xF8
                        IOHI = 0x02
                        IORL = 0xF8
                        IORH = 0x02
                    }
                    Case (0x02)
                    {
                        IOLO = 0xE8
                        IOHI = 0x03
                        IORL = 0xE8
                        IORH = 0x03
                    }
                    Case (0x03)
                    {
                        IOLO = 0xF8
                        IOHI = 0x03
                        IORL = 0xF8
                        IORH = 0x03
                    }

                }

                IRQL = (One << (FRUI (0x03) & 0x0F))
                Return (BUF0) /* \_SB_.PCI0.UAR4._CRS.BUF0 */
            }
        }
    }

    If ((G027 == One))
    {
        Scope (\_GPE)
        {
            Name (ETP0, 0x55)
            Name (ETP1, 0x55)
            Name (ETP2, 0x55)
            Name (ETP3, 0x55)
            Name (ETP4, 0x55)
            Name (ETP5, 0x55)
            Name (ETP6, 0x55)
            Name (ETP7, 0x55)
            Name (ETP8, 0x55)
            Name (ETP9, 0x55)
            Name (ETPA, 0x55)
            Name (ETPB, 0x55)
            Name (ETPC, 0x55)
            Name (ETPD, 0x55)
            Name (ETPE, 0x55)
            Name (ETPF, 0x55)
            Name (ETPG, 0x55)
            Name (ETPH, 0x55)
            Name (ET17, 0x55)
            Name (ET18, 0x55)
            Name (ET19, 0x55)
            Method (_E10, 0, NotSerialized)  // _Exx: Edge-Triggered GPE, xx=0x00-0xFF
            {
                M460 ("  OEM-ASL-\\_GPE._E10\n", Zero, Zero, Zero, Zero, Zero, Zero)
                M644 (0xFED80200, 0x04, 0x10)
                If ((\_GPE.ETP0 != 0xFF))
                {
                    \_GPE.ETP0 = (M017 (Zero, One, One, 0x78, Zero, 0x18) >> 0x10)
                    If (((\_GPE.ETP0 == One) || (\_GPE.ETP0 == 0x03)))
                    {
                        If (CondRefOf (\_SB.PCI0.GPP0))
                        {
                            If ((M620 != Zero))
                            {
                                If ((M049 (M620, 0x10) == One))
                                {
                                    If (((M049 (M620, 0x5A) & 0x02) == Zero))
                                    {
                                        M460 ("    Notify (\\_SB.PCI0.GPP0, 0x0)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                                        Notify (\_SB.PCI0.GPP0, Zero) // Bus Check
                                    }
                                }
                            }

                            M460 ("    Notify (\\_SB.PCI0.GPP0, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                            Notify (\_SB.PCI0.GPP0, 0x02) // Device Wake
                            Sleep (0x64)
                            Local0 = M017 (Zero, One, One, 0x78, Zero, 0x20)
                            If (((Local0 & 0x00030000) != Zero))
                            {
                                M018 (Zero, One, One, 0x78, Zero, 0x20, Local0)
                                Local0 = M017 (Zero, One, One, 0x78, Zero, 0x20)
                                If (((Local0 & 0x00030000) != Zero))
                                {
                                    M018 (Zero, One, One, 0x78, Zero, 0x20, Local0)
                                    Local0 = M017 (Zero, One, One, 0x78, Zero, 0x20)
                                }
                            }
                        }
                    }
                }

                If ((\_GPE.ETP1 != 0xFF))
                {
                    \_GPE.ETP1 = (M017 (Zero, One, 0x02, 0x78, Zero, 0x18) >> 0x10)
                    If (((\_GPE.ETP1 == One) || (\_GPE.ETP1 == 0x03)))
                    {
                        If (CondRefOf (\_SB.PCI0.GPP1))
                        {
                            M460 ("    Notify (\\_SB.PCI0.GPP1, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                            Notify (\_SB.PCI0.GPP1, 0x02) // Device Wake
                            Sleep (0x64)
                            Local0 = M017 (Zero, One, 0x02, 0x78, Zero, 0x20)
                            If (((Local0 & 0x00030000) != Zero))
                            {
                                M018 (Zero, One, 0x02, 0x78, Zero, 0x20, Local0)
                                Local0 = M017 (Zero, One, 0x02, 0x78, Zero, 0x20)
                                If (((Local0 & 0x00030000) != Zero))
                                {
                                    M018 (Zero, One, 0x02, 0x78, Zero, 0x20, Local0)
                                    Local0 = M017 (Zero, One, 0x02, 0x78, Zero, 0x20)
                                }
                            }
                        }
                    }
                }

                If ((\_GPE.ETP2 != 0xFF))
                {
                    \_GPE.ETP2 = (M017 (Zero, One, 0x03, 0x78, Zero, 0x18) >> 0x10)
                    If (((\_GPE.ETP2 == One) || (\_GPE.ETP2 == 0x03)))
                    {
                        If (CondRefOf (\_SB.PCI0.GPP2))
                        {
                            M460 ("    Notify (\\_SB.PCI0.GPP2, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                            Notify (\_SB.PCI0.GPP2, 0x02) // Device Wake
                            Sleep (0x64)
                            Local0 = M017 (Zero, One, 0x03, 0x78, Zero, 0x20)
                            If (((Local0 & 0x00030000) != Zero))
                            {
                                M018 (Zero, One, 0x03, 0x78, Zero, 0x20, Local0)
                                Local0 = M017 (Zero, One, 0x03, 0x78, Zero, 0x20)
                                If (((Local0 & 0x00030000) != Zero))
                                {
                                    M018 (Zero, One, 0x03, 0x78, Zero, 0x20, Local0)
                                    Local0 = M017 (Zero, One, 0x03, 0x78, Zero, 0x20)
                                }
                            }
                        }
                    }
                }

                If ((\_GPE.ETP3 != 0xFF))
                {
                    \_GPE.ETP3 = (M017 (Zero, One, 0x04, 0x78, Zero, 0x18) >> 0x10)
                    If (((\_GPE.ETP3 == One) || (\_GPE.ETP3 == 0x03)))
                    {
                        If (CondRefOf (\_SB.PCI0.GPP3))
                        {
                            M460 ("    Notify (\\_SB.PCI0.GPP3, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                            Notify (\_SB.PCI0.GPP3, 0x02) // Device Wake
                            Sleep (0x64)
                            Local0 = M017 (Zero, One, 0x04, 0x78, Zero, 0x20)
                            If (((Local0 & 0x00030000) != Zero))
                            {
                                M018 (Zero, One, 0x04, 0x78, Zero, 0x20, Local0)
                                Local0 = M017 (Zero, One, 0x04, 0x78, Zero, 0x20)
                                If (((Local0 & 0x00030000) != Zero))
                                {
                                    M018 (Zero, One, 0x04, 0x78, Zero, 0x20, Local0)
                                    Local0 = M017 (Zero, One, 0x04, 0x78, Zero, 0x20)
                                }
                            }
                        }
                    }
                }

                If ((\_GPE.ETP4 != 0xFF))
                {
                    \_GPE.ETP4 = (M017 (Zero, One, 0x05, 0x78, Zero, 0x18) >> 0x10)
                    If (((\_GPE.ETP4 == One) || (\_GPE.ETP4 == 0x03)))
                    {
                        If (CondRefOf (\_SB.PCI0.GPP4))
                        {
                            M460 ("    Notify (\\_SB.PCI0.GPP4, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                            Notify (\_SB.PCI0.GPP4, 0x02) // Device Wake
                            Sleep (0x64)
                            Local0 = M017 (Zero, One, 0x05, 0x78, Zero, 0x20)
                            If (((Local0 & 0x00030000) != Zero))
                            {
                                M018 (Zero, One, 0x05, 0x78, Zero, 0x20, Local0)
                                Local0 = M017 (Zero, One, 0x05, 0x78, Zero, 0x20)
                                If (((Local0 & 0x00030000) != Zero))
                                {
                                    M018 (Zero, One, 0x05, 0x78, Zero, 0x20, Local0)
                                    Local0 = M017 (Zero, One, 0x05, 0x78, Zero, 0x20)
                                }
                            }
                        }
                    }
                }

                If ((\_GPE.ETP5 != 0xFF))
                {
                    \_GPE.ETP5 = (M017 (Zero, One, 0x06, 0x78, Zero, 0x18) >> 0x10)
                    If (((\_GPE.ETP5 == One) || (\_GPE.ETP5 == 0x03)))
                    {
                        If (CondRefOf (\_SB.PCI0.GPP5))
                        {
                            M460 ("    Notify (\\_SB.PCI0.GPP5, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                            Notify (\_SB.PCI0.GPP5, 0x02) // Device Wake
                            Sleep (0x64)
                            Local0 = M017 (Zero, One, 0x06, 0x78, Zero, 0x20)
                            If (((Local0 & 0x00030000) != Zero))
                            {
                                M018 (Zero, One, 0x06, 0x78, Zero, 0x20, Local0)
                                Local0 = M017 (Zero, One, 0x06, 0x78, Zero, 0x20)
                                If (((Local0 & 0x00030000) != Zero))
                                {
                                    M018 (Zero, One, 0x06, 0x78, Zero, 0x20, Local0)
                                    Local0 = M017 (Zero, One, 0x06, 0x78, Zero, 0x20)
                                }
                            }
                        }
                    }
                }

                If ((\_GPE.ETP6 != 0xFF))
                {
                    \_GPE.ETP6 = (M017 (Zero, One, 0x07, 0x78, Zero, 0x18) >> 0x10)
                    If (((\_GPE.ETP6 == One) || (\_GPE.ETP6 == 0x03)))
                    {
                        If (CondRefOf (\_SB.PCI0.GPP6))
                        {
                            M460 ("    Notify (\\_SB.PCI0.GPP6, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                            Notify (\_SB.PCI0.GPP6, 0x02) // Device Wake
                            Sleep (0x64)
                            Local0 = M017 (Zero, One, 0x07, 0x78, Zero, 0x20)
                            If (((Local0 & 0x00030000) != Zero))
                            {
                                M018 (Zero, One, 0x07, 0x78, Zero, 0x20, Local0)
                                Local0 = M017 (Zero, One, 0x07, 0x78, Zero, 0x20)
                                If (((Local0 & 0x00030000) != Zero))
                                {
                                    M018 (Zero, One, 0x07, 0x78, Zero, 0x20, Local0)
                                    Local0 = M017 (Zero, One, 0x07, 0x78, Zero, 0x20)
                                }
                            }
                        }
                    }
                }

                If ((\_GPE.ETP7 != 0xFF))
                {
                    \_GPE.ETP7 = (M017 (Zero, 0x02, One, 0x78, Zero, 0x18) >> 0x10)
                    If (((\_GPE.ETP7 == One) || (\_GPE.ETP7 == 0x03)))
                    {
                        If (CondRefOf (\_SB.PCI0.GPP7))
                        {
                            If ((M620 != Zero))
                            {
                                If ((M049 (M620, 0x10) == 0x03))
                                {
                                    If (((M049 (M620, 0x5A) & 0x02) == Zero))
                                    {
                                        M460 ("    Notify (\\_SB.PCI0.GPP7, 0x0)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                                        Notify (\_SB.PCI0.GPP7, Zero) // Bus Check
                                    }
                                }
                                ElseIf ((M049 (M620, 0x10) == 0x04))
                                {
                                    If (((M049 (M620, 0x5A) & 0x02) == Zero))
                                    {
                                        M460 ("    Notify (\\_SB.PCI0.GPP7, 0x0)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                                        Notify (\_SB.PCI0.GPP7, Zero) // Bus Check
                                    }
                                }
                                ElseIf ((M049 (M620, 0x10) == 0x05))
                                {
                                    If (((M049 (M620, 0x5A) & 0x02) == Zero))
                                    {
                                        M460 ("    Notify (\\_SB.PCI0.GPP7, 0x0)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                                        Notify (\_SB.PCI0.GPP7, Zero) // Bus Check
                                    }
                                }
                                ElseIf ((M049 (M620, 0x10) == 0x06))
                                {
                                    If (((M049 (M620, 0x5A) & 0x02) == Zero))
                                    {
                                        M460 ("    Notify (\\_SB.PCI0.GPP7, 0x0)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                                        Notify (\_SB.PCI0.GPP7, Zero) // Bus Check
                                    }
                                }
                                ElseIf ((M049 (M620, 0x10) == 0x07))
                                {
                                    If (((M049 (M620, 0x5A) & 0x02) == Zero))
                                    {
                                        M460 ("    Notify (\\_SB.PCI0.GPP7, 0x0)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                                        Notify (\_SB.PCI0.GPP7, Zero) // Bus Check
                                    }
                                }
                            }

                            M460 ("    Notify (\\_SB.PCI0.GPP7, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                            Notify (\_SB.PCI0.GPP7, 0x02) // Device Wake
                            Sleep (0x64)
                            Local0 = M017 (Zero, 0x02, One, 0x78, Zero, 0x20)
                            If (((Local0 & 0x00030000) != Zero))
                            {
                                M018 (Zero, 0x02, One, 0x78, Zero, 0x20, Local0)
                                Local0 = M017 (Zero, 0x02, One, 0x78, Zero, 0x20)
                                If (((Local0 & 0x00030000) != Zero))
                                {
                                    M018 (Zero, 0x02, One, 0x78, Zero, 0x20, Local0)
                                    Local0 = M017 (Zero, 0x02, One, 0x78, Zero, 0x20)
                                }
                            }
                        }
                    }
                }

                If ((\_GPE.ETP8 != 0xFF))
                {
                    \_GPE.ETP8 = (M017 (Zero, 0x02, 0x02, 0x78, Zero, 0x18) >> 0x10)
                    If (((\_GPE.ETP8 == One) || (\_GPE.ETP8 == 0x03)))
                    {
                        If (CondRefOf (\_SB.PCI0.GPP8))
                        {
                            If ((M620 != Zero))
                            {
                                If ((M049 (M620, 0x10) == 0x02))
                                {
                                    If (((M049 (M620, 0x5A) & 0x02) == Zero))
                                    {
                                        M460 ("    Notify (\\_SB.PCI0.GPP8, 0x0)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                                        Notify (\_SB.PCI0.GPP8, Zero) // Bus Check
                                    }
                                }
                            }

                            M460 ("    Notify (\\_SB.PCI0.GPP8, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                            Notify (\_SB.PCI0.GPP8, 0x02) // Device Wake
                            Sleep (0x64)
                            Local0 = M017 (Zero, 0x02, 0x02, 0x78, Zero, 0x20)
                            If (((Local0 & 0x00030000) != Zero))
                            {
                                M018 (Zero, 0x02, 0x02, 0x78, Zero, 0x20, Local0)
                                Local0 = M017 (Zero, 0x02, 0x02, 0x78, Zero, 0x20)
                                If (((Local0 & 0x00030000) != Zero))
                                {
                                    M018 (Zero, 0x02, 0x02, 0x78, Zero, 0x20, Local0)
                                    Local0 = M017 (Zero, 0x02, 0x02, 0x78, Zero, 0x20)
                                }
                            }
                        }
                    }
                }

                If ((\_GPE.ETP9 != 0xFF))
                {
                    \_GPE.ETP9 = (M017 (Zero, 0x03, One, 0x78, Zero, 0x18) >> 0x10)
                    If (((\_GPE.ETP9 == One) || (\_GPE.ETP9 == 0x03)))
                    {
                        If (CondRefOf (\_SB.PCI0.GPP9))
                        {
                            M460 ("    Notify (\\_SB.PCI0.GPP9, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                            Notify (\_SB.PCI0.GPP9, 0x02) // Device Wake
                            Sleep (0x64)
                            Local0 = M017 (Zero, 0x03, One, 0x78, Zero, 0x20)
                            If (((Local0 & 0x00030000) != Zero))
                            {
                                M018 (Zero, 0x03, One, 0x78, Zero, 0x20, Local0)
                                Local0 = M017 (Zero, 0x03, One, 0x78, Zero, 0x20)
                                If (((Local0 & 0x00030000) != Zero))
                                {
                                    M018 (Zero, 0x03, One, 0x78, Zero, 0x20, Local0)
                                    Local0 = M017 (Zero, 0x03, One, 0x78, Zero, 0x20)
                                }
                            }
                        }
                    }
                }

                If ((\_GPE.ETPA != 0xFF))
                {
                    \_GPE.ETPA = (M017 (Zero, 0x03, 0x02, 0x78, Zero, 0x18) >> 0x10)
                    If (((\_GPE.ETPA == One) || (\_GPE.ETPA == 0x03)))
                    {
                        If (CondRefOf (\_SB.PCI0.GPPA))
                        {
                            M460 ("    Notify (\\_SB.PCI0.GPPA, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                            Notify (\_SB.PCI0.GPPA, 0x02) // Device Wake
                            Sleep (0x64)
                            Local0 = M017 (Zero, 0x03, 0x02, 0x78, Zero, 0x20)
                            If (((Local0 & 0x00030000) != Zero))
                            {
                                M018 (Zero, 0x03, 0x02, 0x78, Zero, 0x20, Local0)
                                Local0 = M017 (Zero, 0x03, 0x02, 0x78, Zero, 0x20)
                                If (((Local0 & 0x00030000) != Zero))
                                {
                                    M018 (Zero, 0x03, 0x02, 0x78, Zero, 0x20, Local0)
                                    Local0 = M017 (Zero, 0x03, 0x02, 0x78, Zero, 0x20)
                                }
                            }
                        }
                    }
                }

                If ((\_GPE.ETPB != 0xFF))
                {
                    \_GPE.ETPB = (M017 (Zero, 0x03, 0x03, 0x78, Zero, 0x18) >> 0x10)
                    If (((\_GPE.ETPB == One) || (\_GPE.ETPB == 0x03)))
                    {
                        If (CondRefOf (\_SB.PCI0.GPPB))
                        {
                            M460 ("    Notify (\\_SB.PCI0.GPPB, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                            Notify (\_SB.PCI0.GPPB, 0x02) // Device Wake
                            Sleep (0x64)
                            Local0 = M017 (Zero, 0x03, 0x03, 0x78, Zero, 0x20)
                            If (((Local0 & 0x00030000) != Zero))
                            {
                                M018 (Zero, 0x03, 0x03, 0x78, Zero, 0x20, Local0)
                                Local0 = M017 (Zero, 0x03, 0x03, 0x78, Zero, 0x20)
                                If (((Local0 & 0x00030000) != Zero))
                                {
                                    M018 (Zero, 0x03, 0x03, 0x78, Zero, 0x20, Local0)
                                    Local0 = M017 (Zero, 0x03, 0x03, 0x78, Zero, 0x20)
                                }
                            }
                        }
                    }
                }

                If ((\_GPE.ETPC != 0xFF))
                {
                    \_GPE.ETPC = (M017 (Zero, 0x03, 0x04, 0x78, Zero, 0x18) >> 0x10)
                    If (((\_GPE.ETPC == One) || (\_GPE.ETPC == 0x03)))
                    {
                        If (CondRefOf (\_SB.PCI0.GPPC))
                        {
                            M460 ("    Notify (\\_SB.PCI0.GPPC, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                            Notify (\_SB.PCI0.GPPC, 0x02) // Device Wake
                            Sleep (0x64)
                            Local0 = M017 (Zero, 0x03, 0x04, 0x78, Zero, 0x20)
                            If (((Local0 & 0x00030000) != Zero))
                            {
                                M018 (Zero, 0x03, 0x04, 0x78, Zero, 0x20, Local0)
                                Local0 = M017 (Zero, 0x03, 0x04, 0x78, Zero, 0x20)
                                If (((Local0 & 0x00030000) != Zero))
                                {
                                    M018 (Zero, 0x03, 0x04, 0x78, Zero, 0x20, Local0)
                                    Local0 = M017 (Zero, 0x03, 0x04, 0x78, Zero, 0x20)
                                }
                            }
                        }
                    }
                }

                If ((\_GPE.ETPD != 0xFF))
                {
                    \_GPE.ETPD = (M017 (Zero, 0x03, 0x05, 0x78, Zero, 0x18) >> 0x10)
                    If (((\_GPE.ETPD == One) || (\_GPE.ETPD == 0x03)))
                    {
                        If (CondRefOf (\_SB.PCI0.GPPD))
                        {
                            M460 ("    Notify (\\_SB.PCI0.GPPD, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                            Notify (\_SB.PCI0.GPPD, 0x02) // Device Wake
                            Sleep (0x64)
                            Local0 = M017 (Zero, 0x03, 0x05, 0x78, Zero, 0x20)
                            If (((Local0 & 0x00030000) != Zero))
                            {
                                M018 (Zero, 0x03, 0x05, 0x78, Zero, 0x20, Local0)
                                Local0 = M017 (Zero, 0x03, 0x05, 0x78, Zero, 0x20)
                                If (((Local0 & 0x00030000) != Zero))
                                {
                                    M018 (Zero, 0x03, 0x05, 0x78, Zero, 0x20, Local0)
                                    Local0 = M017 (Zero, 0x03, 0x05, 0x78, Zero, 0x20)
                                }
                            }
                        }
                    }
                }

                If ((\_GPE.ETPE != 0xFF))
                {
                    \_GPE.ETPE = (M017 (Zero, 0x03, 0x06, 0x78, Zero, 0x18) >> 0x10)
                    If (((\_GPE.ETPE == One) || (\_GPE.ETPE == 0x03)))
                    {
                        If (CondRefOf (\_SB.PCI0.GPPE))
                        {
                            M460 ("    Notify (\\_SB.PCI0.GPPE, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                            Notify (\_SB.PCI0.GPPE, 0x02) // Device Wake
                            Sleep (0x64)
                            Local0 = M017 (Zero, 0x03, 0x06, 0x78, Zero, 0x20)
                            If (((Local0 & 0x00030000) != Zero))
                            {
                                M018 (Zero, 0x03, 0x06, 0x78, Zero, 0x20, Local0)
                                Local0 = M017 (Zero, 0x03, 0x06, 0x78, Zero, 0x20)
                                If (((Local0 & 0x00030000) != Zero))
                                {
                                    M018 (Zero, 0x03, 0x06, 0x78, Zero, 0x20, Local0)
                                    Local0 = M017 (Zero, 0x03, 0x06, 0x78, Zero, 0x20)
                                }
                            }
                        }
                    }
                }

                If ((\_GPE.ETPF != 0xFF))
                {
                    \_GPE.ETPF = (M017 (Zero, 0x03, 0x07, 0x78, Zero, 0x18) >> 0x10)
                    If (((\_GPE.ETPF == One) || (\_GPE.ETPF == 0x03)))
                    {
                        If (CondRefOf (\_SB.PCI0.GPPF))
                        {
                            M460 ("    Notify (\\_SB.PCI0.GPPF, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                            Notify (\_SB.PCI0.GPPF, 0x02) // Device Wake
                            Sleep (0x64)
                            Local0 = M017 (Zero, 0x03, 0x07, 0x78, Zero, 0x20)
                            If (((Local0 & 0x00030000) != Zero))
                            {
                                M018 (Zero, 0x03, 0x07, 0x78, Zero, 0x20, Local0)
                                Local0 = M017 (Zero, 0x03, 0x07, 0x78, Zero, 0x20)
                                If (((Local0 & 0x00030000) != Zero))
                                {
                                    M018 (Zero, 0x03, 0x07, 0x78, Zero, 0x20, Local0)
                                    Local0 = M017 (Zero, 0x03, 0x07, 0x78, Zero, 0x20)
                                }
                            }
                        }
                    }
                }

                If ((\_GPE.ETPG != 0xFF))
                {
                    \_GPE.ETPG = (M017 (Zero, 0x04, One, 0x78, Zero, 0x18) >> 0x10)
                    If (((\_GPE.ETPG == One) || (\_GPE.ETPG == 0x03)))
                    {
                        If (CondRefOf (\_SB.PCI0.GPPG))
                        {
                            M460 ("    Notify (\\_SB.PCI0.GPPG, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                            Notify (\_SB.PCI0.GPPG, 0x02) // Device Wake
                            Sleep (0x64)
                            Local0 = M017 (Zero, 0x04, One, 0x78, Zero, 0x20)
                            If (((Local0 & 0x00030000) != Zero))
                            {
                                M018 (Zero, 0x04, One, 0x78, Zero, 0x20, Local0)
                                Local0 = M017 (Zero, 0x04, One, 0x78, Zero, 0x20)
                                If (((Local0 & 0x00030000) != Zero))
                                {
                                    M018 (Zero, 0x04, One, 0x78, Zero, 0x20, Local0)
                                    Local0 = M017 (Zero, 0x04, One, 0x78, Zero, 0x20)
                                }
                            }
                        }
                    }
                }

                If ((\_GPE.ETPH != 0xFF))
                {
                    \_GPE.ETPH = (M017 (Zero, 0x04, 0x02, 0x78, Zero, 0x18) >> 0x10)
                    If (((\_GPE.ETPH == One) || (\_GPE.ETPH == 0x03)))
                    {
                        If (CondRefOf (\_SB.PCI0.GPPH))
                        {
                            M460 ("    Notify (\\_SB.PCI0.GPPH, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                            Notify (\_SB.PCI0.GPPH, 0x02) // Device Wake
                            Sleep (0x64)
                            Local0 = M017 (Zero, 0x04, 0x02, 0x78, Zero, 0x20)
                            If (((Local0 & 0x00030000) != Zero))
                            {
                                M018 (Zero, 0x04, 0x02, 0x78, Zero, 0x20, Local0)
                                Local0 = M017 (Zero, 0x04, 0x02, 0x78, Zero, 0x20)
                                If (((Local0 & 0x00030000) != Zero))
                                {
                                    M018 (Zero, 0x04, 0x02, 0x78, Zero, 0x20, Local0)
                                    Local0 = M017 (Zero, 0x04, 0x02, 0x78, Zero, 0x20)
                                }
                            }
                        }
                    }
                }

                If ((\_GPE.ET17 != 0xFF))
                {
                    \_GPE.ET17 = (M017 (Zero, 0x08, One, 0x78, Zero, 0x18) >> 0x10)
                    If (((\_GPE.ET17 == One) || (\_GPE.ET17 == 0x03)))
                    {
                        If (CondRefOf (\_SB.PCI0.GP17))
                        {
                            M460 ("    Notify (\\_SB.PCI0.GP17, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                            Notify (\_SB.PCI0.GP17, 0x02) // Device Wake
                            Sleep (0x64)
                            Local0 = M017 (Zero, 0x08, One, 0x78, Zero, 0x20)
                            If (((Local0 & 0x00030000) != Zero))
                            {
                                M018 (Zero, 0x08, One, 0x78, Zero, 0x20, Local0)
                                Local0 = M017 (Zero, 0x08, One, 0x78, Zero, 0x20)
                                If (((Local0 & 0x00030000) != Zero))
                                {
                                    M018 (Zero, 0x08, One, 0x78, Zero, 0x20, Local0)
                                    Local0 = M017 (Zero, 0x08, One, 0x78, Zero, 0x20)
                                }
                            }
                        }
                    }
                }

                If ((\_GPE.ET18 != 0xFF))
                {
                    \_GPE.ET18 = (M017 (Zero, 0x08, 0x02, 0x78, Zero, 0x18) >> 0x10)
                    If (((\_GPE.ET18 == One) || (\_GPE.ET18 == 0x03)))
                    {
                        If (CondRefOf (\_SB.PCI0.GP18))
                        {
                            M460 ("    Notify (\\_SB.PCI0.GP18, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                            Notify (\_SB.PCI0.GP18, 0x02) // Device Wake
                            Sleep (0x64)
                            Local0 = M017 (Zero, 0x08, 0x02, 0x78, Zero, 0x20)
                            If (((Local0 & 0x00030000) != Zero))
                            {
                                M018 (Zero, 0x08, 0x02, 0x78, Zero, 0x20, Local0)
                                Local0 = M017 (Zero, 0x08, 0x02, 0x78, Zero, 0x20)
                                If (((Local0 & 0x00030000) != Zero))
                                {
                                    M018 (Zero, 0x08, 0x02, 0x78, Zero, 0x20, Local0)
                                    Local0 = M017 (Zero, 0x08, 0x02, 0x78, Zero, 0x20)
                                }
                            }
                        }
                    }
                }

                If ((\_GPE.ET19 != 0xFF))
                {
                    \_GPE.ET19 = (M017 (Zero, 0x08, 0x03, 0x78, Zero, 0x18) >> 0x10)
                    If (((\_GPE.ET19 == One) || (\_GPE.ET19 == 0x03)))
                    {
                        If (CondRefOf (\_SB.PCI0.GP19))
                        {
                            M460 ("    Notify (\\_SB.PCI0.GP19, 0x2)\n", Zero, Zero, Zero, Zero, Zero, Zero)
                            Notify (\_SB.PCI0.GP19, 0x02) // Device Wake
                            Sleep (0x64)
                            Local0 = M017 (Zero, 0x08, 0x03, 0x78, Zero, 0x20)
                            If (((Local0 & 0x00030000) != Zero))
                            {
                                M018 (Zero, 0x08, 0x03, 0x78, Zero, 0x20, Local0)
                                Local0 = M017 (Zero, 0x08, 0x03, 0x78, Zero, 0x20)
                                If (((Local0 & 0x00030000) != Zero))
                                {
                                    M018 (Zero, 0x08, 0x03, 0x78, Zero, 0x20, Local0)
                                    Local0 = M017 (Zero, 0x08, 0x03, 0x78, Zero, 0x20)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Scope (\_SB.PCI0.GPP7.UP00.DP60.XH00.RHUB.POT4)
    {
        Method (GHPC, 2, Serialized)
        {
            Name (PCKG, Package (0x04)
            {
                Zero, 
                0xFF, 
                Zero, 
                Zero
            })
            PCKG [Zero] = Arg0
            PCKG [One] = Arg1
            Return (PCKG) /* \_SB_.PCI0.GPP7.UP00.DP60.XH00.RHUB.POT4.GHPC.PCKG */
        }

        Method (GHLD, 2, Serialized)
        {
            Name (PCKG, Package (0x01)
            {
                Buffer (0x14)
                {
                    /* 0000 */  0x82, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                    /* 0008 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                    /* 0010 */  0xFF, 0xFF, 0xFF, 0xFF                           // ....
                }
            })
            CreateField (DerefOf (PCKG [Zero]), Zero, 0x07, REV)
            REV = 0x02
            CreateField (DerefOf (PCKG [Zero]), 0x40, One, VISI)
            VISI = Arg0
            CreateField (DerefOf (PCKG [Zero]), 0x57, 0x08, GPOS)
            GPOS = Arg1
            Return (PCKG) /* \_SB_.PCI0.GPP7.UP00.DP60.XH00.RHUB.POT4.GHLD.PCKG */
        }

        Device (PRT1)
        {
            Name (_ADR, One)  // _ADR: Address
            Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
            {
                Return (GHPC (One, 0x03))
            }

            Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
            {
                Return (GHLD (One, 0x37))
            }
        }

        Device (PRT2)
        {
            Name (_ADR, 0x02)  // _ADR: Address
            Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
            {
                Return (GHPC (One, 0x03))
            }

            Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
            {
                Return (GHLD (One, 0x38))
            }
        }

        Device (PRT3)
        {
            Name (_ADR, 0x03)  // _ADR: Address
            Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
            {
                Return (GHPC (One, 0x03))
            }

            Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
            {
                Return (GHLD (One, 0x39))
            }
        }

        Device (PRT4)
        {
            Name (_ADR, 0x04)  // _ADR: Address
            Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
            {
                Return (GHPC (One, 0x03))
            }

            Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
            {
                Return (GHLD (One, 0x3A))
            }
        }
    }

    Scope (\_SB.PCI0.GPP7.UP00.DP60.XH00.RHUB.POTA)
    {
        Method (GHPC, 2, Serialized)
        {
            Name (PCKG, Package (0x04)
            {
                Zero, 
                0xFF, 
                Zero, 
                Zero
            })
            PCKG [Zero] = Arg0
            PCKG [One] = Arg1
            Return (PCKG) /* \_SB_.PCI0.GPP7.UP00.DP60.XH00.RHUB.POTA.GHPC.PCKG */
        }

        Method (GHLD, 2, Serialized)
        {
            Name (PCKG, Package (0x01)
            {
                Buffer (0x14)
                {
                    /* 0000 */  0x82, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                    /* 0008 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                    /* 0010 */  0xFF, 0xFF, 0xFF, 0xFF                           // ....
                }
            })
            CreateField (DerefOf (PCKG [Zero]), Zero, 0x07, REV)
            REV = 0x02
            CreateField (DerefOf (PCKG [Zero]), 0x40, One, VISI)
            VISI = Arg0
            CreateField (DerefOf (PCKG [Zero]), 0x57, 0x08, GPOS)
            GPOS = Arg1
            Return (PCKG) /* \_SB_.PCI0.GPP7.UP00.DP60.XH00.RHUB.POTA.GHLD.PCKG */
        }

        Device (PRT1)
        {
            Name (_ADR, One)  // _ADR: Address
            Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
            {
                Return (GHPC (One, Zero))
            }

            Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
            {
                Return (GHLD (One, 0x37))
            }
        }

        Device (PRT2)
        {
            Name (_ADR, 0x02)  // _ADR: Address
            Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
            {
                Return (GHPC (One, Zero))
            }

            Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
            {
                Return (GHLD (One, 0x38))
            }
        }

        Device (PRT3)
        {
            Name (_ADR, 0x03)  // _ADR: Address
            Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
            {
                Return (GHPC (One, Zero))
            }

            Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
            {
                Return (GHLD (One, 0x39))
            }
        }

        Device (PRT4)
        {
            Name (_ADR, 0x04)  // _ADR: Address
            Method (_UPC, 0, NotSerialized)  // _UPC: USB Port Capabilities
            {
                Return (GHPC (One, Zero))
            }

            Method (_PLD, 0, NotSerialized)  // _PLD: Physical Location of Device
            {
                Return (GHLD (One, 0x3A))
            }
        }
    }

    Scope (\_SB.I2CA)
    {
        Device (U4RH)
        {
            Name (_HID, "MSFT8000")  // _HID: Hardware ID
            Name (_CID, "MSFT8000")  // _CID: Compatible ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((M620 != Zero))
                {
                    If ((M049 (M620, 0x10) != Zero))
                    {
                        Return (0x0F)
                    }
                }

                Return (Zero)
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                I2cSerialBusV2 (0x0040, ControllerInitiated, 0x00061A80,
                    AddressingMode7Bit, "\\_SB.I2CA",
                    0x00, ResourceConsumer, , Exclusive,
                    )
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "bus-I2C-I2CA", 
                        Package (0x01)
                        {
                            Zero
                        }
                    }
                }
            })
        }

        Device (U4PD)
        {
            Name (_HID, "ITE8853")  // _HID: Hardware ID
            Name (_CID, "PNP0CA0")  // _CID: Compatible ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((M620 != Zero))
                {
                    If ((M049 (M620, 0x10) != Zero))
                    {
                        Return (0x0F)
                    }
                }

                Return (Zero)
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Name (SBUF, ResourceTemplate ()
                {
                    I2cSerialBusV2 (0x004C, ControllerInitiated, 0x00061A80,
                        AddressingMode7Bit, "\\_SB.I2CA",
                        0x00, ResourceConsumer, , Exclusive,
                        )
                    GpioInt (Level, ActiveLow, Exclusive, PullDefault, 0x0000,
                        "\\_SB.GPIO", 0x00, ResourceConsumer, ,
                        )
                        {   // Pin list
                            0x0020
                        }
                    GpioIo (Shared, PullUp, 0x0000, 0x0000, IoRestrictionInputOnly,
                        "\\_SB.GPIO", 0x00, ResourceConsumer, ,
                        )
                        {   // Pin list
                            0x0020
                        }
                })
                Return (SBUF) /* \_SB_.I2CA.U4PD._CRS.SBUF */
            }
        }
    }

    Scope (\_SB.I2CA)
    {
        Device (TYPC)
        {
            Name (_HID, "RTK5452")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Name (SBUF, ResourceTemplate ()
                {
                    I2cSerialBusV2 (0x0065, ControllerInitiated, 0x00061A80,
                        AddressingMode7Bit, "\\_SB.I2CA",
                        0x00, ResourceConsumer, , Exclusive,
                        )
                    I2cSerialBusV2 (0x000C, ControllerInitiated, 0x00061A80,
                        AddressingMode7Bit, "\\_SB.I2CA",
                        0x00, ResourceConsumer, , Exclusive,
                        )
                    GpioInt (Level, ActiveLow, Exclusive, PullDefault, 0x0000,
                        "\\_SB.GPIO", 0x00, ResourceConsumer, ,
                        )
                        {   // Pin list
                            0x0054
                        }
                    GpioIo (Shared, PullUp, 0x0000, 0x0000, IoRestrictionInputOnly,
                        "\\_SB.GPIO", 0x00, ResourceConsumer, ,
                        )
                        {   // Pin list
                            0x0054
                        }
                })
                Return (SBUF) /* \_SB_.I2CA.TYPC._CRS.SBUF */
            }
        }
    }
}

