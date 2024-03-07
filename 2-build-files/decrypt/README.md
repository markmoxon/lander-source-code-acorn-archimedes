# Decryption files for Lander on the Acorn Archimedes

This folder contains support scripts for decrypting the RISC OS version of Lander on the Acorn Archimedes.

* [lander-decrypt.arm](lander-decrypt.arm) contains the decryption code from the RISC OS variant of the game, taken from the end of the !RunImage file

* [lander-decrypt.py](lander-decrypt.py) contains the decryption code from the RISC OS variant of the game, translated into Python

* [!RunImage.bin](!RunImage.bin) contains the encrypted game binary from the RISC OS variant, as found on the RISC OS 2 applications disc

* [!RunImage.decrypt.bin](!RunImage.decrypt.bin) contains the decrypted version of !RunImage.bin, extracted by the [lander-decrypt.py](lander-decrypt.py) script (so this exactly matches GameCode.bin)

---

_Mark Moxon_