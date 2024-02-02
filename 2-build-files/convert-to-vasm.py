#!/usr/bin/env python
#
# ******************************************************************************
#
# CONVERT BBC BASIC ASSEMBLER TO VASM
#
# Written by Mark Moxon
#
# This script converts source code from BBC BASIC ARM Assembler style into
# vasm-compatible ARM assembler.
#
# ******************************************************************************

import re


print("Converting 1-source-files/Lander.arm")

bbc_basic_file = open("1-source-files/main-sources/Lander.arm", "r")
vasm_file = open("3-assembled-output/Lander.arm", "w")

for line in bbc_basic_file:

    # Strip comments
    line = re.sub(r" *[;\\].*$", "", line)

    # .label -> label:
    line = re.sub(r"^\.([^ \n]+)", r"\1:", line)

    # x = y -> .set x, y
    line = re.sub(r"^ ?(.+) = (.+)$", r".set \1, \2", line)

    # ORG -> .org
    line = re.sub(r"^ ?ORG ", ".org ", line)

    # SKIP -> .skip
    line = re.sub(r"^ ?SKIP ", ".skip ", line)

    # P% -> $
    line = re.sub(r"P%", "$", line)

    # Binary % -> 0x
    binary_string = re.search(r"%([0-1]+)", line)
    if binary_string:
        hex_string = hex(int(binary_string.group(1), 2))
        line = re.sub(r"%([0-1]+)", hex_string, line)

    # Hexadecimal & -> 0x
    line = re.sub(r"&", "0x", line)

    # EQUD -> .long
    line = re.sub(r"^ ?EQUD ", ".long ", line)

    # EQUW -> .word
    line = re.sub(r"^ ?EQUW ", ".word ", line)

    # EQUS -> .byte
    line = re.sub(r"^ ?EQUS ", ".byte ", line)

    # EQUB -> .byte
    line = re.sub(r"^ ?EQUB ", ".byte ", line)

    # ALIGN -> .balign
    line = re.sub(r"^ ?ALIGN", ".balign 4", line)

    # IF -> .ifdef
    line = re.sub(r"^ ?IF ", ".ifdef ", line)

    # ENDIF -> .endif
    line = re.sub(r"^ ?ENDIF", ".endif", line)

    # ELSE -> .else
    line = re.sub(r"^ ?ELSE", ".else", line)

    # Write updated line
    if line.strip():
        vasm_file.write(line)

bbc_basic_file.close()

print("3-assembled-output/Lander.arm file saved")
