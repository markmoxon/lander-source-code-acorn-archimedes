# Build files for Lander on the Acorn Archimedes

This folder contains support scripts for building Lander on the Acorn Archimedes.

* [convert-to-vasm.py](convert-to-vasm.py) converts the BBC BASIC Asssembler format of the main source files into vasm-compatible syntax so vasm can assemble the game

* [crc32.py](crc32.py) calculates checksums during the verify stage and compares the results with the relevant binaries in the [4-reference-binaries](../4-reference-binaries) folder

* [lander-decrypt.arm](lander-decrypt.arm) contains the decryption code from the RISC OS variant of the game, taken from the end of the !RunImage file

* [lander-decrypt.py](lander-decrypt.py) contains the decryption code from the RISC OS variant of the game, translated into Python

It also contains the `make.exe` executable for Windows, plus the required DLL files.

---

_Mark Moxon_