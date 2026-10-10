VASM?=vasmarm_std
BEEBASM?=beebasm
PYTHON?=python

.PHONY:all
all:
	@$(PYTHON) 2-build-files/convert-to-vasm.py

	$(VASM) -a2 -m2 -quiet -Fbin -L 3-assembled-output/compile.txt -o 3-assembled-output/GameCode.bin 3-assembled-output/Lander.arm
	$(BEEBASM) -i 1-source-files/main-sources/LanderIO.asm -v >> 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/lander-disc.asm -do 5-compiled-game-discs/!Lander.ssd -title "Lander"

	@$(PYTHON) 2-build-files/crc32.py 4-reference-binaries 3-assembled-output
