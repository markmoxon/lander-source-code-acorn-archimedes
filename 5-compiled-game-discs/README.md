# Compiled game discs for Lander on the Acorn Archimedes

This folder contains the final disc files for Lander on the Acorn Archimedes, as produced by the build process. There is one folder for each supported variant, plus a folder for zips of each variant. These files can be loaded into an emulator like Arculator, or into a real Archimedes using a device like a Gotek.

The Arthur variant contains the GameCode binary in two formats: as a pair of files (GameCode and GameCode.inf) that is suitable for programs that support inf files, or as a single file (GameCode,8000-A614) that will work with HostFS. Both options contain the load and execution address of the file, and you should choose the one that works for you when copying the game to your emulator or Archimedes.

It also contains LanderSrc,fff, which is a BBC BASIC-compatible file that will build Lander on an Archimedes.

---

_Mark Moxon_