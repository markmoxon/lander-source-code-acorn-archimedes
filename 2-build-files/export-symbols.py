#!/usr/bin/env python
#
# ******************************************************************************
#
# EXPORT SYMBOLS FROM VASM
#
# Written by Mark Moxon
#
# This script extracts symbol values from the vasm output so they can be
# included in the !RunImage source.
#
# ******************************************************************************

import re


def convert(input_file, output_file):

    export_section_reached = False

    for line in input_file:

        if "Symbols by value:" in line:
            export_section_reached = True

        # Export variables
        if export_section_reached:
            exported_variable = re.search(r"^([0-9A-F]{8}) (\w+)$", line)
            if exported_variable:
                export = ".set " + exported_variable.group(2) + ", 0x" + exported_variable.group(1) + "\n"
                output_file.write(export)


print("Extracting exported variables from 1-source-files/Lander.arm")

compile_file = open("3-assembled-output/compile.txt", "r")
vasm_file = open("3-assembled-output/exports.arm", "w")
convert(compile_file, vasm_file)
compile_file.close()
vasm_file.close()

print("Variables extracted")
