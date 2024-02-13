# Fully documented source code for Lander on the Acorn Archimedes

[BBC Micro cassette Elite](https://github.com/markmoxon/cassette-elite-beebasm) | [BBC Micro disc Elite](https://github.com/markmoxon/disc-elite-beebasm) | [6502 Second Processor Elite](https://github.com/markmoxon/6502sp-elite-beebasm) | [BBC Master Elite](https://github.com/markmoxon/master-elite-beebasm) | [Acorn Electron Elite](https://github.com/markmoxon/electron-elite-beebasm) | [NES Elite](https://github.com/markmoxon/nes-elite-beebasm) | [Elite-A](https://github.com/markmoxon/elite-a-beebasm) | [Teletext Elite](https://github.com/markmoxon/teletext-elite) | [Elite Universe Editor](https://github.com/markmoxon/elite-universe-editor) | [Elite Compendium](https://github.com/markmoxon/elite-compendium) | [Elite over Econet](https://github.com/markmoxon/elite-over-econet) | [Flicker-free C64 Elite](https://github.com/markmoxon/c64-elite-flicker-free) | [Aviator](https://github.com/markmoxon/aviator-beebasm) | [Revs](https://github.com/markmoxon/revs-beebasm) | **Archimedes Lander**

![Screenshot of Lander on the Acorn Archimedes](https://lander.bbcelite.com/images/github/Lander.png)

This repository contains source code for Lander on the Acorn Archimedes, with every single line documented and (for the most part) explained.

It is a companion to the [lander.bbcelite.com website](https://lander.bbcelite.com).

See the [introduction](#introduction) for more information.

## Contents

* [Introduction](#introduction)

* [Acknowledgements](#acknowledgements)

  * [A note on licences, copyright etc.](#user-content-a-note-on-licences-copyright-etc)

* [Browsing the source in an IDE](#browsing-the-source-in-an-ide)

* [Folder structure](#folder-structure)

* [Building Lander from the source](#building-lander-from-the-source)

  * [Requirements](#requirements)
  * [Build targets](#build-targets)
  * [Windows](#windows)
  * [Mac and Linux](#mac-and-linux)
  * [Verifying the output](#verifying-the-output)
  * [Log files](#log-files)

## Introduction

This repository contains source code for Lander on the Acorn Archimedes, with every single line documented and (for the most part) explained.

You can build the fully functioning game from this source. Two variants are currently supported: the Arthur variant, and the RISC OS 2 variant.

It is a companion to the [lander.bbcelite.com website](https://lander.bbcelite.com), which contains all the code from this repository, but laid out in a much more human-friendly fashion.

* If you want to browse the source and read about how Lander works under the hood, you will probably find [the website](https://lander.bbcelite.com) is a better place to start than this repository.

* If you would rather explore the source code in your favourite IDE, then the [annotated source](1-source-files/main-sources/Lander.arm) is what you're looking for. It contains the exact same content as the website, so you won't be missing out (the website is generated from the source files, so they are guaranteed to be identical). You might also like to read the section on [Browsing the source in an IDE](#browsing-the-source-in-an-ide) for some tips.

* If you want to build Lander from the source on a modern computer, to produce a working game disc that can be loaded into a Acorn Archimedes or an emulator, then you want the section on [Building Lander from the source](#building-lander-from-the-source).

My hope is that this repository will be useful for those who want to learn more about Lander and what makes it tick. It is provided on an educational and non-profit basis, with the aim of helping people appreciate the magic of David Braben's 32-bit masterpiece, and the first ever game for the ARM platform.

## Acknowledgements

Lander was written by David Braben and is copyright &copy; D.J.Braben 1987.

The code on this site has been reconstructed from a disassembly of the version released on the [application discs for Arthur and RISC OS](http://www.lewisgilbert.co.uk/archiology/osdiscs.html).

The commentary is copyright &copy; Mark Moxon. Any misunderstandings or mistakes in the documentation are entirely my fault.

### A note on licences, copyright etc.

This repository is _not_ provided with a licence, and there is intentionally no `LICENSE` file provided.

According to [GitHub's licensing documentation](https://docs.github.com/en/free-pro-team@latest/github/creating-cloning-and-archiving-repositories/licensing-a-repository), this means that "the default copyright laws apply, meaning that you retain all rights to your source code and no one may reproduce, distribute, or create derivative works from your work".

The reason for this is that my commentary is intertwined with the original Lander game code, and the original game is copyright. The whole site is therefore covered by default copyright law, to ensure that this copyright is respected.

Under GitHub's rules, you have the right to read and fork this repository... but that's it. No other use is permitted, I'm afraid.

My hope is that the educational and non-profit intentions of this repository will enable it to stay hosted and available, but the original copyright holders do have the right to ask for it to be taken down, in which case I will comply without hesitation.  I do hope, though, that along with the various other disassemblies and commentaries of Acornsoft's games for the BBC Micro and Archimedes, it will remain viable.

## Browsing the source in an IDE

If you want to browse the source in an IDE, you might find the following useful.

* The most interesting files are in the [main-sources](1-source-files/main-sources) folder:

  * The main game's source code is in the [Lander.arm](1-source-files/main-sources/Lander.arm) file - this is the motherlode and probably contains all the stuff you're interested in. It produces a file called `GameCode` that contains the entire game.

  * The RISC OS application bundles up the game into a `!RunImage`, whose source is in the [RunImage.arm](1-source-files/main-sources/RunImage.arm) file. In the version on the RISC OS application disc the `!RunImage` binary is encrypted, but in this version the game binary is simply wrapped in a relocation routine (though encryption may be added later).

* It's probably worth skimming through the [notes on terminology and notations](https://lander.bbcelite.com/terminology/) on the accompanying website, as this explains a number of terms used in the commentary, without which it might be a bit tricky to follow at times.

* The entry point for the [main game code](1-source-files/main-sources/lander-source.asm) is routine `Entry`, which you can find by searching for `Name: Entry`.

* The source code is designed to be read at an 80-column width and with a monospaced font, just like in the good old days.

I hope you enjoy exploring the inner workings of Lander as much as I have.

## Folder structure

There are five main folders in this repository, which reflect the order of the build process.

* [1-source-files](1-source-files) contains all the different source files, such as the main assembler source files, BASIC loaders, RISC OS application files and so on.

* [2-build-files](2-build-files) contains build-related scripts, such as the crc32 verification scripts and vasm converter script.

* [3-assembled-output](3-assembled-output) contains the output from the assembly process, when the source files are assembled and the results processed by the build files.

* [4-reference-binaries](4-reference-binaries) contains the correct binaries for each release, so we can verify that our assembled output matches the reference.

* [5-compiled-game-discs](5-compiled-game-discs) contains the final output of the build process: a folder that contains the compiled game and which can be run on real hardware or in an emulator.

## Building Lander from the source

Builds are supported for both Windows and Mac/Linux systems. In all cases the build process is defined in the `Makefile` provided.

### Requirements

You will need the following to build Lander from the source:

* vasm, which can be downloaded from the [vasm homepage](http://sun.hasenbraten.de/vasm/).

* Python. The build process has only been tested on 3.x, but 2.7 should work.

* Mac and Linux users may need to install `make` if it isn't already present (for Windows users, `make.exe` is included in this repository).

Let's look at how to build Lander from the source.

### Windows

For Windows users, there is a batch file called `make.bat` that builds the project. Before this will work, you should edit the batch file and change the values of the `VASM` and `PYTHON` variables to point to the locations of your `vasmarm_std.exe` and `python.exe` executables (you need the `vasmarm_std` executable). You also need to change directory to the repository folder (i.e. the same folder as `make.bat`).

All being well, entering the following into a command window:

```
make.bat
```

will produce folders called `arthur` and `riscos` in the `5-compiled-game-discs` folder, which contain the Arthur and RISC OS variants of the game, which you can then load into an emulator, or into a real Acorn Archimedes using a device like a Gotek.

### Mac and Linux

The build process uses a standard GNU `Makefile`, so you just need to install `make` if your system doesn't already have it. If vasm or Python are not on your path, then you can either fix this, or you can edit the `Makefile` and change the `VASM` and `PYTHON` variables in the first two lines to point to their locations (you need the `vasmarm_std` executable). You also need to change directory to the repository folder (i.e. the same folder as `Makefile`).

All being well, entering the following into a terminal window:

```
make
```

will produce folders called `arthur` and `riscos` in the `5-compiled-game-discs` folder, which contain the Arthur and RISC OS variants of the game, which you can then load into an emulator, or into a real Acorn Archimedes using a device like a Gotek.

### Verifying the output

The build process prints out checksums of all the generated files, along with the checksums of the files from the original sources.

The Python script `crc32.py` in the `2-build-files` folder does the actual verification, and shows the checksums and file sizes of both sets of files, alongside each other, and with a Match column that flags any discrepancies.

The binaries in the `4-reference-binaries` folder are those extracted from the released version of the game, while those in the `3-assembled-output` folder are produced by the build process. For example, if you don't make any changes to the code and build the project with `make`, then this is the output of the verification process:

```
[--originals--]  [---output----]
Checksum   Size  Checksum   Size  Match  Filename
-----------------------------------------------------------
26b5e51a  28703  -             -    -    !RunImage.bin
aa7f1052  39440  aa7f1052  39440   Yes   !RunImage.decrypt.bin
9985364c  39488  9985364c  39488   Yes   !RunImage.unprot.bin
aa7f1052  39440  aa7f1052  39440   Yes   GameCode.bin
```

Of these, the following are produced by the build process:

* GameCode.bin contains the game binary from the Arthur variant, as found on the Arthur applications disc

* !RunImage.unprot.bin contains the game binary wrapped up into an Absolute file

This binary is produced by the [lander-decrypt.py](2-build-files/lander-decrypt.py) script:

* !RunImage.decrypt.bin contains a decrypted version of !RunImage.bin, so this exactly matches GameCode.bin

This binary is not yet produced by the build process:

* !RunImage.bin contains the encrypted game binary from the RISC OS variant, as found on the RISC OS 2 applications disc

In the above example, the compiled GameCode.bin and !RunImage.unprot.bin binaries match the original, so we know we are producing the same final game as the release version.

Note that the build process does not encrypt the `!RunImage` binary, though this may be added later (this is why there is no match for the encrypted `!RunImage.bin` file in the verification process).

### Log files

During compilation, details of every step are output in a file called `compile.txt` in the `3-assembled-output` folder. If you have problems, it might come in handy, and it's a great reference if you need to know the addresses of labels and variables for debugging (or just snooping around).

---

_Mark Moxon_