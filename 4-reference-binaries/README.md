# Reference binaries for Lander on the Acorn Archimedes

This folder contains the binaries from the game disc for Lander on the Acorn Archimedes.

* [GameCode.bin](GameCode.bin) contains the game binary from the Arthur variant, as found on the Arthur applications disc

* [!RunImage.bin](!RunImage.bin) contains the encrypted game binary from the RISC OS variant, as found on the RISC OS 2 applications disc

* [!RunImage.decrypt.bin](!RunImage.decrypt.bin) contains a decrypted version of !RunImage.bin, extracted by the [lander-decrypt.py](../2-build-files/lander-decrypt.py) script (so this exactly matches GameCode.bin)

* [!RunImage.unprot.bin](!RunImage.unprot.bin) contains the game binary wrapped up into an Absolute file, so this is what is currently built by the build process

---

_Mark Moxon_