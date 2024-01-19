VASM?=vasmarm_std
PYTHON?=python

.PHONY:all
all:
	$(VASM) -a2 -m2 -quiet -Fbin -L 3-assembled-output/output.txt -o 3-assembled-output/GameCode.bin 1-source-files/main-sources/Lander.arm
	cp 1-source-files/other-sources/GameCode.inf 5-compiled-game-discs/arthur/GameCode.inf
	cp 1-source-files/other-sources/Lander,ffb 5-compiled-game-discs/arthur/Lander,ffb
	cp 3-assembled-output/GameCode.bin 5-compiled-game-discs/arthur/GameCode
	@$(PYTHON) 2-build-files/crc32.py 4-reference-binaries/arthur 3-assembled-output
