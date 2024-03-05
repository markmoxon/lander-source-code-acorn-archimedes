# Build files for Lander on the Acorn Archimedes

This folder contains support scripts for building Lander on the Acorn Archimedes.

* [convert-to-vasm.py](convert-to-vasm.py) converts the main source files into vasm-compatible syntax so vasm can assemble the game

* [convert-to-basic.py](convert-to-basic.py) converts the main source files into a BBC BASIC-compatible syntax that will build on an Archimedes

* [crc32.py](crc32.py) calculates checksums during the verify stage and compares the results with the relevant binaries in the [4-reference-binaries](../4-reference-binaries) folder

* [export-symbols.py](convert-to-vasm.py) extracts symbol values from the vasm output so they can be included in the !RunImage source (so changing the souce code won't break the !RunImage loader)

* [lander-decrypt.arm](lander-decrypt.arm) contains the decryption code from the RISC OS variant of the game, taken from the end of the !RunImage file

* [lander-decrypt.py](lander-decrypt.py) contains the decryption code from the RISC OS variant of the game, translated into Python

It also contains the `make.exe` executable for Windows, plus the required DLL files.

---

_Mark Moxon_