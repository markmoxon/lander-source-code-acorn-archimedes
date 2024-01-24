#!/usr/bin/env python
#
# ******************************************************************************
#
# LANDER DECRYPTION SCRIPT
#
# Written by Mark Moxon
#
# ******************************************************************************


def write_word(addr, word):
    if addr < 0x8000:
        print("Write error to !" + hex(addr))
        return
    # print("!" + hex(addr - 0x8000) + " (" + hex(addr) + ") = " + hex(word))
    lander_code[addr - 0x8000] = word & 0xFF
    lander_code[addr - 0x8000 + 1] = ((word & (0xFF << 8)) >> 8)
    lander_code[addr - 0x8000 + 2] = ((word & (0xFF << 16)) >> 16)
    lander_code[addr - 0x8000 + 3] = ((word & (0xFF << 24)) >> 24)


def write_byte(addr, byte):
    if addr < 0x8000:
        print("Write error to ?" + hex(addr))
        return
    # print("?" + hex(addr - 0x8000) + " (" + hex(addr) + ") = " + hex(byte))
    lander_code[addr - 0x8000] = byte & 0xFF


def fetch_word(addr):
    # print("Fetch !" + hex(addr - 0x8000) + " (" + hex(addr) + ")")
    word = lander_code[addr - 0x8000 + 3] << 24
    word += lander_code[addr - 0x8000 + 2] << 16
    word += lander_code[addr - 0x8000 + 1] << 8
    word += lander_code[addr - 0x8000]
    return word


def fetch_byte(addr):
    # print("Fetch ?" + hex(addr - 0x8000)+ " (" + hex(addr) + ")")
    return lander_code[addr - 0x8000]


def run_moved_code():
    global r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13
    # print("run_moved_code() with r4 = " + hex(r4) + ", r7 = " + hex(r7) + ", r8 = " + hex(r8) + ", r9 = " + hex(r9) + ", r10 = " + hex(r10) + ", r11 = " + hex(r11) + ", r12 = " + hex(r12) + ", r13 = " + hex(r13))
    # .0x0000EEF0
    while True:
        r9 += r13                                           # 0000EEF0 ADD     R9, R9, R13
        r8 -= 4                                             # 0000EEF4 SUB     R8, R8, #4
        # .0x0000EEF8
        while True:
            if r10 <= r9:                                   # 0000EEF8 CMP     R10, R9
                # print("run_moved_code() with r10 <= r9 with r10 = " + hex(r10) + ", r9 = " + hex(r10))
                # .0x0000EFE0                               # 0000EEFC BLE     0x0000EFE0
                if r13 <= 0:                                # 0000EFE0 CMP     R13, #0
                    # .0x0000F008
                    r8 += 0x14                              # 0000F008 ADD     R8, R8, #0x14
                    r8 += 0x2600                            # 0000F00C ADD     R8, R8, #0x2600
                    print("[ Info    ] Jump to " + hex(r8) + " to run game")
                    return                                  # 0000F010 MOV     PC, R8
                else:
                    r6 = r9 - r13                           # 0000EFE8 SUB     R6, R9, R13
                    r9 = r7                                 # 0000EFEC MOV     R9, R7
                    r10 = r9 + r13                          # 0000EFF0 ADD     R10, R9, R13
                    # .0x0000EFF4
                    while True:
                        r0 = fetch_word(r6)                 # 0000EFF4 LDMIA   R6!, {R0-R3}        # Copy r13 bytes from r6 to r7
                        r1 = fetch_word(r6 + 4)
                        r2 = fetch_word(r6 + 8)
                        r3 = fetch_word(r6 + 12)
                        r6 += 16
                        write_word(r7, r0)                  # 0000EFF8 STMIA   R7!, {R0-R3}
                        write_word(r7 + 4, r1)
                        write_word(r7 + 8, r2)
                        write_word(r7 + 12, r3)
                        r7 += 16
                        r13 -= 0x10                         # 0000EFFC SUBS    R13, R13, #0x10
                        if r13 > 0:                         # 0000F000 BGT 0x0000EFF4
                            continue
                        else:
                            break
                    continue                                # 0000F004 B       0x0000EEF8
            else:
                # print("run_moved_code() with r10 > r9 with r10 = " + hex(r10) + ", r9 = " + hex(r10))
                r10 -= 1                                    # 0000EF00 LDRB    R6, [R10, #-1]!
                r6 = fetch_byte(r10)
                r3 = r6 & 0xF                               # 0000EF04 AND     R3, R6, #0xF
                r0 = r3 - 9                                 # 0000EF08 SUBS    R0, R3, #9
                if r0 < 0:                                  # 0000EF0C BLT     0x0000EF20
                    # .0x0000EF20
                    r0 = r3 - 2                             # 0000EF20 SUBS    R0, R3, #2
                    if r0 < 0:                              # 0000EF24 BLT     0x0000EF40
                        # .0x0000EF40
                        if r3 == 0:                         # 0000EF40 CMP     R3, #0
                            r4 = r3                         # 0000EF44 MOVEQ   R4, R3
                            pass                            # 0000EF48 BEQ     0x0000EF68
                        else:
                            r10 -= 1                        # 0000EF4C LDRB    R0, [R10, #-1]!
                            r0 = fetch_byte(r10)
                            r10 -= 1                        # 0000EF50 LDRB    R1, [R10, #-1]!
                            r1 = fetch_byte(r10)
                            r0 = r0 | (r1 << 8)             # 0000EF54 ORR     R0, R0, R1, LSL #8
                            r10 -= 1                        # 0000EF58 LDRB    R1, [R10, #-1]!
                            r1 = fetch_byte(r10)
                            r0 = r0 | (r1 << 16)            # 0000EF5C ORR     R0, R0, R1, LSL #16
                            r10 -= 1                        # 0000EF60 LDRB    R1, [R10, #-1]!
                            r1 = fetch_byte(r10)
                            r4 = r0 | (r1 << 24)            # ORR     R4, R0, R1, LSL #24
                            pass                            # Fall through into 0x0000EF68
                    else:
                        r10 -= 1                            # 0000EF28 LDRB    R1, [R10, #-1]!
                        r1 = fetch_byte(r10)
                        r0 = r1 | (r0 << 8)                 # 0000EF2C ORR     R0, R1, R0, LSL #8
                        r0 = fetch_word(r11 + (r0 << 2))    # 0000EF30 LDR     R0, [R11, R0, LSL #2]
                        r10 -= 1                            # 0000EF34 LDRB    R1, [R10, #-1]!
                        r1 = fetch_byte(r10)
                        r4 = r1 | (r0 << 8)                 # 0000EF38 ORR     R4, R1, R0, LSL #8
                        pass                                # 0000EF3C B       0x0000EF68
                else:
                    r10 -= 1                                # 0000EF10 LDRB    R1, [R10, #-1]!
                    r1 = fetch_byte(r10)
                    r0 = r1 | (r0 << 8)                     # 0000EF14 ORR     R0, R1, R0, LSL #8
                    temp = r12 + (r0 << 2)                  # 0000EF18 LDR     R4, [R12, R0, LSL #2]
                    r4 = fetch_word(temp)
                    pass                                    # 0000EF1C B       0x0000EF68

            # .0x0000EF68
            r3 = r6 >> 4                                    # 0000EF68 MOV     R3, R6, LSR #4
            r0 = r3 - 9                                     # 0000EF6C SUBS    R0, R3, #9
            if r0 < 0:                                      # 0000EF70 BLT     0x0000EF88
                # .0x0000EF88
                r0 = r3 - 2                                 # 0000EF88 SUBS    R0, R3, #2
                if r0 < 0:                                  # 0000EF8C BLT     0x0000EFAC
                    # .0x0000EFAC
                    if r3 == 0:                             # 0000EFAC CMP     R3, #0
                        r5 = r3                             # 0000EFB0 MOVEQ   R5, R3
                        # print("1, r10 = " + hex(r10) + ", r9 = " + hex(r9) + ", r8 = " + hex(r8))
                        write_word(r8 - 4, r5)              # 0000EFB4 STMDBEQ R8!, {R4-R5}
                        write_word(r8 - 8, r4)
                        r8 -= 8
                        continue                            # 0000EFB8 BEQ     0x0000EEF8
                    r10 -= 1                                # 0000EFBC LDRB    R0, [R10, #-1]!
                    r0 = fetch_byte(r10)
                    r10 -= 1                                # 0000EFC0 LDRB    R1, [R10, #-1]!
                    r1 = fetch_byte(r10)
                    r0 = r0 | (r1 << 8)                     # 0000EFC4 ORR     R0, R0, R1, LSL #8
                    r10 -= 1                                # 0000EFC8 LDRB    R1, [R10, #-1]!
                    r1 = fetch_byte(r10)
                    r0 = r0 | (r1 << 16)                    # 0000EFCC ORR     R0, R0, R1, LSL #16
                    r10 -= 1                                # 0000EFD0 LDRB    R1, [R10, #-1]!
                    r1 = fetch_byte(r10)
                    r5 = r0 | (r1 << 24)                    # 0000EFD4 ORR     R5, R0, R1, LSL #24
                    # print("2, r10 = " + hex(r10) + ", r9 = " + hex(r9) + ", r8 = " + hex(r8))
                    write_word(r8 - 4, r5)                  # 0000EFD8 STMDB   R8!, {R4-R5}
                    write_word(r8 - 8, r4)
                    r8 -= 8
                    continue                                # 0000EFDC B       0x0000EEF8
                else:
                    r10 -= 1                                # 0000EF90 LDRB    R1, [R10, #-1]!
                    r1 = fetch_byte(r10)
                    r0 = r1 | (r0 << 8)                     # 0000EF94 ORR     R0, R1, R0, LSL #8
                    r0 = fetch_word(r11 + (r0 << 2))        # 0000EF98 LDR     R0, [R11, R0, LSL #2]
                    r10 -= 1                                # 0000EF9C LDRB    R1, [R10, #-1]!
                    r1 = fetch_byte(r10)
                    r5 = r1 | (r0 << 8)                     # 0000EFA0 ORR     R5, R1, R0, LSL #8
                    # print("3, r10 = " + hex(r10) + ", r9 = " + hex(r9) + ", r8 = " + hex(r8))
                    write_word(r8 - 4, r5)                  # 0000EFA4 STMDB   R8!, {R4-R5}
                    write_word(r8 - 8, r4)
                    r8 -= 8
                    continue                                # 0000EFA8 B       0x0000EEF8
            else:
                r10 -= 1                                    # 0000EF74 LDRB    R1, [R10, #-1]!
                r1 = fetch_byte(r10)
                r0 = r1 | (r0 << 8)                         # 0000EF78 ORR     R0, R1, R0, LSL #8
                r5 = fetch_word(r12 + (r0 << 2))            # 0000EF7C LDR     R5, [R12, R0, LSL #2]
                # print("4, r10 = " + hex(r10) + ", r9 = " + hex(r9) + ", r8 = " + hex(r8))
                write_word(r8 - 4, r5)                      # 0000EF80 STMDB   R8!, {R4-R5}
                write_word(r8 - 8, r4)
                r8 -= 8
                continue                                    # 0000EF84 B       0x0000EEF8


print()
print("RISC OS 2 Lander decryption")

lander_code = bytearray()

# Load assembled code file

lander_file = open("4-reference-binaries/riscos2/!RunImage", "rb")
lander_code.extend(lander_file.read())
lander_file.close()

# Extend bytearray to cover 0x8000 to 0x20000
lander_code.extend(bytearray(0x20000 - 0x8000 - len(lander_code)))

print()
print("[ Read    ] 4-reference-binaries/riscos2/!RunImage")

# Do decryption

                        # 0000EDB0   0x00009A10
                        # 0000EDB4   0x000050F2
                        # 0000EDB8   0x00001CBA
                        # 0000EDBC   0x00000700
                        # 0000EDC0   0x00000700
                        # 0000EDC4   0x00000160

r0 = 0x0000EDB0         # 0000EDD8 ADR     R0, 0x0000EDB0
r8 = 0x00009A10         # 0000EDD8 LDMIA   R0, {R8-R13}
r9 = 0x000050F2
r10 = 0x00001CBA
r11 = 0x00000700
r12 = 0x00000700
r13 = 0x00000160

r10 = r0 - r10          # 0000EDDC SUB     R10, R0, R10          # EDB0 - 1CBA = D0F6
r9 = r10 - r9           # 0000EDE0 SUB     R9, R10, R9           # D0F6 - 50F2 = 8004
r8 = r9 + r8            # 0000EDE4 ADD     R8, R9, R8            # 8004 + 9A10 = 11A14
r6 = r8                 # 0000EDE8 MOV     R6, R8                # 11A14
r1 = r11 + r12          # 0000EDEC ADD     R1, R11, R12          # 0700 + 0700 = 1400
r7 = r6 + (r1 << 2)     # 0000EDF0 ADD     R7, R6, R1, LSL #2    # 11A14 + 1400 << 2 = 11A14 + 5000 = 16A14
r5 = r10                # 0000EDF4 MOV     R5, R10               # D0F6
r4 = 0                  # 0000EDF8 MOV     R4, #0                # 0 for first loop, 1 for second loop, controls relocation

# .0x0000EDFC
while True:
    r2 = r6                                 # 0000EDFC MOV     R2, R6
    r3 = -1                                 # 0000EE00 MVN     R3, #0

    # .0x0000EE04
    while True:
        r11 -= 1                            # 0000EE04 SUBS    R11, R11, #1
        if r11 < 0:                         # 0000EE08 BLT     0x0000EEB0
            break
        r1 = fetch_byte(r5)                 # 0000EE0C LDRB    R1, [R5], #1
        r5 += 1
        r0 = r1 - 0xA                       # 0000EE10 SUBS    R0, R1, #0xA
        if r0 >= 0:                         # 0000EE14 BGE     0x0000EE64
            # print("main loop with r0 >= 0 with r0 = " + hex(r0))
            # .0x0000EE64
            if r1 < 0x5C:                   # 0000EE64 CMP     R1, #0x5C
                r3 = r3 + r0                # 0000EE68 ADDLT   R3, R3, R0
                write_word(r6, r3)          # 0000EE6C STRLT   R3, [R6], #4
                r6 += 4
                continue                    # 0000EE70 BLT     0x0000EE04
            r0 = r1 - 0xAE                  # 0000EE74 SUBS    R0, R1, #0xAE
            if r0 < 0:                      # 0000EE78 BLT     0x0000EE98
                # .0x0000EE98
                r0 = r1 - 0x5C              # 0000EE98 SUBS    R0, R1, #0x5C
                r1 = fetch_byte(r5)         # 0000EE9C LDRB    R1, [R5], #1
                r5 += 1
                r0 = r1 | (r0 << 8)         # 0000EEA0 ORR     R0, R1, R0, LSL #8
                r3 += r0                    # 0000EEA4 ADD     R3, R3, R0
                write_word(r6, r3)          # 0000EEA8 STR     R3, [R6], #4
                r6 += 4
                continue                    # 0000EEAC B       0x0000EE04
            r1 = fetch_byte(r5)             # 0000EE7C LDRB    R1, [R5], #1
            r5 += 1
            r0 = r1 | (r0 << 16)            # 0000EE80 ORR     R0, R1, R0, LSL #16
            r1 = fetch_byte(r5)             # 0000EE84 LDRB    R1, [R5], #1
            r5 += 1
            r0 = r0 | (r1 << 8)             # 0000EE88 ORR     R0, R0, R1, LSL #8
            r3 += r0                        # 0000EE8C ADD     R3, R3, R0
            write_word(r6, r3)              # 0000EE90 STR     R3, [R6], #4
            r6 += 4
            continue                        # 0000EE94 B       0x0000EE04
        elif r1 != 0:                       # 0000EE18 CMP     R1, #0
            # print("main loop with r0 < 0 and r1 != 0 with r0 = " + hex(r0) + ", r1 = " + hex(r1))
            # .0x0000EE48                   # 0000EE1C BNE     0x0000EE48
            r11 -= r1                       # 0000EE48 SUB     R11, R11, R1
            r11 += 1                        # 0000EE4C ADD     R11, R11, #1
            # .0x0000EE50
            while True:
                r3 += 1                     # 0000EE50 ADD     R3, R3, #1
                write_word(r6, r3)          # 0000EE54 STR     R3, [R6], #4
                r6 += 4
                r1 -= 1                     # 0000EE58 SUBS    R1, R1, #1
                if r1 > 0:                  # 0000EE5C BGT     0x0000EE50
                    continue
                else:
                    break
            continue                        # 0000EE60 B       0x0000EE04
        else:
            # print("main loop else with r0 = " + hex(r0) + ", r1 = " + hex(r1))
            r0 = fetch_byte(r5)             # 0000EE20 LDRB    R0, [R5], #1
            r5 += 1
            r1 = fetch_byte(r5)             # 0000EE24 LDRB    R1, [R5], #1
            r5 += 1
            r0 = r0 | (r1 << 8)             # 0000EE28 ORR     R0, R0, R1, LSL #8
            r1 = fetch_byte(r5)             # 0000EE2C LDRB    R1, [R5], #1
            r5 += 1
            r0 = r0 | (r1 << 16)            # 0000EE30 ORR     R0, R0, R1, LSL #16
            r1 = fetch_byte(r5)             # 0000EE34 LDRB    R1, [R5], #1
            r5 += 1
            r0 = r0 | (r1 << 24)            # 0000EE38 ORR     R0, R0, R1, LSL #24
            r3 += r0                        # 0000EE3C ADD     R3, R3, R0
            write_word(r6, r3)              # 0000EE40 STR     R3, [R6], #4
            r6 += 4
            continue                        # 0000EE44 B       0x0000EE04

    # 0x0000EEB0
    if r4 != 0:                             # 0000EEB0 CMP     R4, #0
        # print("main loop with r4 != 0 with r4 = " + hex(r4))
        # .0x0000EECC                       # 0000EEB4 BNE     0x0000EECC
        r11 = r2                            # 0000EECC MOV     R11, R2
        r5 = 0x0000EEF0                     # 0000EED0 ADR     R5, 0x0000EEF0
        r6 = 0x0000F018                     # 0000EED4 ADR     R6, 0x0000F018
        r4 = r7                             # 0000EED8 MOV     R4, R7
        # print("Moving code from r5 = " + hex(r5) + " to r7 = " + hex(r7))
        # .0x0000EEDC
        while True:
            r0 = fetch_word(r5)             # 0000EEDC LDMIA   R5!, {R0-R3}        # Copy 0x0000EEF0-0x0000F018 to address in r7
            r1 = fetch_word(r5 + 4)
            r2 = fetch_word(r5 + 8)
            r3 = fetch_word(r5 + 12)
            r5 += 16
            write_word(r7, r0)              # 0000EEE0 STMIA   R7!, {R0-R3}
            write_word(r7 + 4, r1)
            write_word(r7 + 8, r2)
            write_word(r7 + 12, r3)
            r7 += 16
            if r5 < r6:                     # 0000EEE4 CMP     R5, R6
                continue                    # 0000EEE8 BLT     0x0000EEDC
            else:
                break
        run_moved_code()                    # 0000EEEC MOV PC, R4                  # Jump to location in r4, i.e. to start of copied code
        break                               # End program
    else:
        # print("main loop with r4 != 0 with r4 = " + hex(r4))
        r11 = r12                           # 0000EEB8 MOV     R11, R12
        r12 = r2                            # 0000EEBC MOV     R12, R2
        r2 = r6                             # 0000EEC0 MOV     R2, R6
        r4 = 1                              # 0000EEC4 MOV     R4, #1
        continue                            # 0000EEC8 B       0x0000EDFC

print("[ Decrypt ] 4-reference-binaries/riscos2/!RunImage")

# Write output file for !RunImage.decrypt

output_file = open("3-assembled-output/!RunImage.decrypt.bin", "wb")
output_file.write(lander_code[0: 0x9A10])
output_file.close()

print("[ Save    ] 3-assembled-output/!RunImage.decrypt.bin")
print()
