#!/usr/bin/env python
#
# ******************************************************************************
#
# CONVERT REPOSITORY ASSEMBLER FORMAT TO BBC BASIC
#
# Written by Mark Moxon
#
# This script converts source code from the repository style into BBC BASIC ARM
# Assembler style.
#
# ******************************************************************************

import re


def convert(input_file, output_file):

    in_code = False

    for line in input_file:

        if in_code:
            if re.match(r"^ *\]", line):
                in_code = False
        else:
            in_code = re.match(r"^ *\[", line)

        # Change (...) in comments to [...]
        while re.search(r"(\\.*)\(", line):
            line = re.sub(r"(\\.*)\(", r"\1[", line)
        while re.search(r"(\\.*)\)", line):
            line = re.sub(r"(\\.*)\)", r"\1]", line)

        # Change " in comments to '
        while re.search(r"(\\.*)\"", line):
            line = re.sub(r"(\\.*)\"", r"\1'", line)

        # Change : in comments to ;
        while re.search(r"(\\.*):", line):
            line = re.sub(r"(\\.*):", r"\1;", line)

        # Replace comma-separated EQUs with individual EQUs
        while re.search(r"\b(EQU.) *([^:\\,\n]+), *", line):
            line = re.sub(r"\b(EQU.) *([^:\\,\n]+), *", r"\1 \2 : \1 ", line)

        if not in_code:
            # Change \ to : REM
            line = re.sub(r"^\\", r"REM", line)
            line = re.sub(r"\\", r": REM", line)

            # Change GameCode.bin to GameCode.bin
            line = re.sub(r"GameCode\.bin", r"GameCode", line)

        if in_code:
            # Change ALIGN to FN_AlignWithZeroes
            line = re.sub(r"ALIGN", r"OPT FN_AlignWithZeroes", line)

        # Write updated line
        output_file.write(line)

    # Write FNs
    output_file.write("\n END\n\n")
    output_file.write(" DEF FN_AlignWithZeroes\n")
    output_file.write("  a = P% AND 3\n")
    output_file.write("  IF a > 0 THEN\n")
    output_file.write("   FOR I% = 1 TO 4 - a\n")
    output_file.write("    [\n")
    output_file.write("     OPT pass%\n")
    output_file.write("     EQUB 0\n")
    output_file.write("    ]\n")
    output_file.write("   NEXT I%\n")
    output_file.write("  ENDIF\n")
    output_file.write(" =pass%\n")


print("Converting 1-source-files/Lander.arm")

source_file = open("1-source-files/main-sources/Lander.arm", "r")
basic_file = open("3-assembled-output/LanderSrc,fff", "w")
convert(source_file, basic_file)
source_file.close()
basic_file.close()

print("3-assembled-output/LanderSrc,fff file saved")

print("Converting 1-source-files/RunImage.arm")

source_file = open("1-source-files/main-sources/RunImage.arm", "r")
basic_file = open("3-assembled-output/RunImgSrc,fff", "w")
convert(source_file, basic_file)
source_file.close()
basic_file.close()

print("3-assembled-output/RunImage,fff file saved")
