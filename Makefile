VASM?=vasmarm_std
PYTHON?=python

.PHONY:all
all:
	@$(PYTHON) 2-build-files/convert-to-vasm.py
	$(VASM) -a2 -m2 -quiet -Fbin -L 3-assembled-output/compile.txt -o 3-assembled-output/GameCode.bin 3-assembled-output/Lander.arm
	cp 1-source-files/other-sources/GameCode.inf 5-compiled-game-discs/arthur/GameCode.inf
	cp 1-source-files/other-sources/Lander,ffb 5-compiled-game-discs/arthur/Lander,ffb
	cp 3-assembled-output/GameCode.bin 5-compiled-game-discs/arthur/GameCode
	cp 1-source-files/other-sources/!Run,feb 5-compiled-game-discs/riscos/!Lander/!Run,feb
	cp 1-source-files/other-sources/!Sprites,ff9 5-compiled-game-discs/riscos/!Lander/!Sprites,ff9
	cp 1-source-files/other-sources/MemAlloc,ffa 5-compiled-game-discs/riscos/!Lander/MemAlloc,ffa
	cp 3-assembled-output/!RunImage.unprot.bin 5-compiled-game-discs/riscos/!Lande/!RunImage,ff8
	@$(PYTHON) 2-build-files/crc32.py 4-reference-binaries 3-assembled-output
