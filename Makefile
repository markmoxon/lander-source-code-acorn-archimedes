VASM?=vasmarm_std
PYTHON?=python

.PHONY:all
all:
	@$(PYTHON) 2-build-files/convert-to-vasm.py

	$(VASM) -a2 -m2 -quiet -Fbin -L 3-assembled-output/compile.txt -o 3-assembled-output/GameCode.bin 3-assembled-output/Lander.arm

ifeq ($(OS), Windows_NT)
	copy 3-assembled-output\GameCode.bin 5-compiled-game-discs\GameCode
else
	cp 3-assembled-output/GameCode.bin 5-compiled-game-discs/GameCode
endif

	@$(PYTHON) 2-build-files/crc32.py 4-reference-binaries 3-assembled-output
