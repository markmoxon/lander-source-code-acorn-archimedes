VASM?=vasmarm_std
PYTHON?=python
DISC?=oaknut-disc

# The deploy target deploys !Lander to a web server so archi.medes.live can load it
#
# LANDER_PATH should be set to the scp path of the server hosting the build
#
# e.g. export $LANDER_PATH=name@server.com:~/path/to
#
# Once deployed, you can load a URL like this to see the compiled game:
#
# https://archi.medes.live/#ff=14400&disc=https://server.com/path/to/!Lander.zip&autoboot=desktop%20filer_opendir%20HostFS::HostFS.$

.PHONY:all
all:
	@$(PYTHON) 2-build-files/convert-to-vasm.py

ifeq ($(OS), Windows_NT)
	if exist 5-compiled-game-discs\adfs rmdir /s /q 5-compiled-game-discs\adfs
	mkdir 5-compiled-game-discs\adfs
	mkdir 5-compiled-game-discs\adfs\Arthur
	mkdir 5-compiled-game-discs\adfs\Arthur\Game
	mkdir 5-compiled-game-discs\adfs\Arthur\Library
	mkdir 5-compiled-game-discs\adfs\RISC_OS
	mkdir 5-compiled-game-discs\adfs\RISC_OS\!Lander
else
	rm -fr 5-compiled-game-discs/adfs
	mkdir 5-compiled-game-discs/adfs
	mkdir 5-compiled-game-discs/adfs/Arthur
	mkdir 5-compiled-game-discs/adfs/Arthur/Game
	mkdir 5-compiled-game-discs/adfs/Arthur/Library
	mkdir 5-compiled-game-discs/adfs/RISC_OS
	mkdir 5-compiled-game-discs/adfs/RISC_OS/!Lander
endif

	$(VASM) -a2 -m2 -quiet -Fbin -L 3-assembled-output/compile.txt -o 3-assembled-output/GameCode.bin 3-assembled-output/Lander.arm

ifeq ($(OS), Windows_NT)
	copy "1-source-files\other-sources\arthur\Lander,ffb" "5-compiled-game-discs\adfs\Arthur\Game\Lander,ffb"
	copy 3-assembled-output\GameCode.inf 5-compiled-game-discs\adfs\Arthur\Game\GameCode.inf
	copy 3-assembled-output\GameCode.bin 5-compiled-game-discs\adfs\Arthur\Game\GameCode
	copy "1-source-files\other-sources\arthur\UseDeskTop,ffe" "5-compiled-game-discs\adfs\Arthur\Library\UseDeskTop,ffe"
	copy "1-source-files\other-sources\arthur\UseGame,ffe" "5-compiled-game-discs\adfs\Arthur\Library\UseGame,ffe"
else
	cp 1-source-files/other-sources/arthur/Lander,ffb 5-compiled-game-discs/adfs/Arthur/Game/Lander,ffb
	cp 3-assembled-output/GameCode.inf 5-compiled-game-discs/adfs/Arthur/Game/GameCode.inf
	cp 3-assembled-output/GameCode.bin 5-compiled-game-discs/adfs/Arthur/Game/GameCode
	cp 1-source-files/other-sources/arthur/UseDeskTop,ffe 5-compiled-game-discs/adfs/Arthur/Library/UseDeskTop,ffe
	cp 1-source-files/other-sources/arthur/UseGame,ffe 5-compiled-game-discs/adfs/Arthur/Library/UseGame,ffe
endif

	@$(PYTHON) 2-build-files/export-symbols.py

	$(VASM) -a2 -m2 -quiet -Fbin -L 3-assembled-output/compile-RunImage.txt -o 3-assembled-output/!RunImage.bin 3-assembled-output/RunImage.arm

ifeq ($(OS), Windows_NT)
	copy "1-source-files\other-sources\riscos\!Run,feb" "5-compiled-game-discs\adfs\RISC_OS\!Lander\!Run,feb"
	copy "1-source-files\other-sources\riscos\!Sprites,ff9" "5-compiled-game-discs\adfs\RISC_OS\!Lander\!Sprites,ff9"
	copy "1-source-files\other-sources\riscos\MemAlloc,ffa" "5-compiled-game-discs\adfs\RISC_OS\!Lander\MemAlloc,ffa"
	copy 3-assembled-output\!RunImage.bin "5-compiled-game-discs\adfs\RISC_OS\!Lander\!RunImage,ff8"
else
	cp 1-source-files/other-sources/riscos/!Run,feb 5-compiled-game-discs/adfs/RISC_OS/!Lander/!Run,feb
	cp 1-source-files/other-sources/riscos/!Sprites,ff9 5-compiled-game-discs/adfs/RISC_OS/!Lander/!Sprites,ff9
	cp 1-source-files/other-sources/riscos/MemAlloc,ffa 5-compiled-game-discs/adfs/RISC_OS/!Lander/MemAlloc,ffa
	cp 3-assembled-output/!RunImage.bin 5-compiled-game-discs/adfs/RISC_OS/!Lander/!RunImage,ff8
endif

	@$(PYTHON) 2-build-files/convert-to-basic.py

	$(DISC) create 5-compiled-game-discs/lander.adf --title "Lander" --geometry e
	$(DISC) import 5-compiled-game-discs/lander.adf 5-compiled-game-discs/adfs

	$(DISC) create 5-compiled-game-discs/lander-source.adf --title "LanderSrc" --geometry e
	$(DISC) put 5-compiled-game-discs/lander-source.adf:$$.LanderSrc 3-assembled-output/LanderSrc,fff

	$(DISC) chmod --recursive 5-compiled-game-discs/lander.adf:$$.* WR/
	$(DISC) chmod --recursive 5-compiled-game-discs/lander-source.adf:$$.* WR/

	$(DISC) set-datestamp --recursive 5-compiled-game-discs/lander.adf:$$.* now
	$(DISC) set-datestamp --recursive 5-compiled-game-discs/lander-source.adf:$$.* now

ifeq ($(OS), Windows_NT)
	rmdir /s /q 5-compiled-game-discs\adfs
else
	rm -fr 5-compiled-game-discs/adfs
endif

	@$(PYTHON) 2-build-files/crc32.py 4-reference-binaries 3-assembled-output

deploy:
	scp 5-compiled-game-discs/zip/!Lander.zip ${LANDER_PATH}
