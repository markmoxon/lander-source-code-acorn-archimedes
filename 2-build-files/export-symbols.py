#!/usr/bin/env python
#
# ******************************************************************************
#
# EXPORT SYMBOLS FROM VASM
#
# Written by Mark Moxon
#
# This script extracts symbol values from the vasm output so they can be
# included in the !RunImage source, and it creates a GameCode.inf file for
# Arthur that contains the correct file size, load and execution addresses.
#
# ******************************************************************************

import re


def convert(input_file, output_file, inf_file):

    export_section_reached = False
    exec_address = ""
    file_size = ""

    for line in input_file:

        if "Symbols by value:" in line:
            export_section_reached = True

        # Export variables
        if export_section_reached:
            exported_variable = re.search(r"^([0-9A-F]{8}) (\w+)$", line)
            if exported_variable:
                export = ".set " + exported_variable.group(2) + ", 0x" + exported_variable.group(1) + "\n"
                output_file.write(export)
                if exported_variable.group(2) == 'Entry':
                    exec_address = exported_variable.group(1)[-6:]
                if exported_variable.group(2) == 'endCode':
                    end_code = exported_variable.group(1)
                    file_size = hex(int(end_code, 16) - 0x8000).replace("0x", "00000000")

    inf = "$.Gamecode        008000 " + exec_address[-6:].upper() + " " + file_size[-6:].upper()
    inf_file.write(inf)


print("Extracting exported variables from 1-source-files/Lander.arm")

compile_file = open("3-assembled-output/compile.txt", "r")
vasm_file = open("3-assembled-output/exports.arm", "w")
inf_file = open("3-assembled-output/GameCode.inf", "w")
convert(compile_file, vasm_file, inf_file)
inf_file.close()
compile_file.close()
vasm_file.close()

print("Variables extracted")
