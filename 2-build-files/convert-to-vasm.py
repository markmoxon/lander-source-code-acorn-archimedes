#!/usr/bin/env python
#
# ******************************************************************************
#
# CONVERT REPOSITORY ASSEMBLER FORMAT TO VASM
#
# Written by Mark Moxon
#
# This script converts source code from the repository style into
# vasm-compatible ARM assembler.
#
# ******************************************************************************

import re


def convert(input_file, output_file):

    for line in input_file:

        # Strip comments
        line = re.sub(r" *[;\\].*$", "", line)

        # .label -> label:
        line = re.sub(r"^\.([^ \n]+)", r"\1:", line)

        # Remove INT(...)
        line = re.sub(r" INT\(", " (", line)

        # Remove lines that mention pass%
        line = re.sub(r"^.*pass%.*$", "", line)

        # Remove lines that start with "DIM "
        line = re.sub(r"^ *DIM .*$", "", line)

        # Remove lines that start with "O% = "
        line = re.sub(r"^ *O% = .*$", "", line)

        # Remove lines that start with "OSCLI "
        line = re.sub(r"^ *OSCLI .*$", "", line)

        # Remove lines that start with [ or ]
        line = re.sub(r"^ *(\[|\]).*$", "", line)

        # "P% = " -> .org
        line = re.sub(r"^ *P% = ", ".org ", line)

        # FOR loop -> .rept
        line = re.sub(r"^ *FOR I% = 1 TO ", ".rept ", line)

        # NEXT -> .endr
        line = re.sub(r"^ *NEXT", ".endr", line)

        # x = y -> .set x, y
        line = re.sub(r"^ *(.+) = (.+)$", r".set \1, \2", line)

        # SKIP -> .skip
        line = re.sub(r"^ *SKIP ", ".skip ", line)

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
        line = re.sub(r"^ *EQUD ", ".long ", line)

        # EQUW -> .word
        line = re.sub(r"^ *EQUW ", ".word ", line)

        # EQUS -> .byte
        line = re.sub(r"^ *EQUS ", ".byte ", line)

        # EQUB -> .byte
        line = re.sub(r"^ *EQUB ", ".byte ", line)

        # ALIGN -> .balign
        line = re.sub(r"^ *ALIGN", ".balign 4", line)

        # IF -> .ifdef
        line = re.sub(r"^ *IF ", ".ifdef ", line)

        # ENDIF -> .endif
        line = re.sub(r"^ *ENDIF", ".endif", line)

        # ELSE -> .else
        line = re.sub(r"^ *ELSE", ".else", line)

        # INCBIN -> .incbin
        line = re.sub(r"^ *INCBIN", ".incbin", line)

        # INCLUDE -> .include
        line = re.sub(r"^ *INCLUDE", ".include", line)

        # Write updated line
        if line.strip():
            output_file.write(line)


print("Converting 1-source-files/Lander.arm")

source_file = open("1-source-files/main-sources/Lander.arm", "r")
vasm_file = open("3-assembled-output/Lander.arm", "w")
convert(source_file, vasm_file)
source_file.close()
vasm_file.close()

source_file = open("1-source-files/main-sources/RunImage.arm", "r")
vasm_file = open("3-assembled-output/RunImage.arm", "w")
convert(source_file, vasm_file)
source_file.close()
vasm_file.close()

print("3-assembled-output/Lander.arm file saved")
