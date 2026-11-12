VASM?=vasmarm_std
PYTHON?=python
DISC?=oaknut-disc

# A make command with no arguments will build BigLander with 64 x 64 tiles
# (i.e. TILES_X = 65 and TILES_Z = 65)
#
# Optional arguments for the make command are:
#
#   x=<tiles_x>         The value of TILES_X
#
#   z=<tiles_z>         The value of TILES_Z
#
# So, for example:
#
#   make x=122 z=122
#
# will build a version of BigLander with a landscape size of 121 x 121 tiles
# (i.e. TILES_X = 122 and TILES_Z = 122)
#
# The deploy target deploys !BigLander to a web server so archi.medes.live can
# load it
#
# LANDER_PATH should be set to the scp path of the server hosting the build
#
# e.g. export $LANDER_PATH=name@server.com:~/path/to
#
# Once deployed, you can load a URL like this to see the compiled game:
#
# https://archi.medes.live/#ff=14400&disc=https://server.com/path/to/!BigLander.zip&autoboot=desktop%20filer_opendir%20HostFS::HostFS.$

custom=yes

ifndef x
  ifndef z
    custom=no
  endif
endif

ifndef x
  x=65
endif

ifndef z
  z=65
endif

.PHONY:all
ifeq ($(custom), yes)
all: biglander
else
all:
	$(DISC) create 5-compiled-game-discs/big-lander.adf --title "BigLander" --geometry e

	$(MAKE) biglander x=13 z=11
	$(DISC) cp --recursive 5-compiled-game-discs/big-lander-13-11.adf:$$.RISC_OS.!BigLander 5-compiled-game-discs/big-lander.adf:$$.RISC_OS.13x11.!BigLander
	$(DISC) cp --recursive 5-compiled-game-discs/big-lander-13-11.adf:$$.Arthur.Game 5-compiled-game-discs/big-lander.adf:$$.Arthur.13x11.Game

	$(MAKE) biglander x=20 z=20
	$(DISC) cp --recursive 5-compiled-game-discs/big-lander-20-20.adf:$$.RISC_OS.!BigLander 5-compiled-game-discs/big-lander.adf:$$.RISC_OS.20x20.!BigLander
	$(DISC) cp --recursive 5-compiled-game-discs/big-lander-13-11.adf:$$.Arthur.Game 5-compiled-game-discs/big-lander.adf:$$.Arthur.20x20.Game

	$(MAKE) biglander x=122 z=122
	$(DISC) cp --recursive 5-compiled-game-discs/big-lander-122-122.adf:$$.RISC_OS.!BigLander 5-compiled-game-discs/big-lander.adf:$$.RISC_OS.122x122.!BigLander
	$(DISC) cp --recursive 5-compiled-game-discs/big-lander-13-11.adf:$$.Arthur.Game 5-compiled-game-discs/big-lander.adf:$$.Arthur.122x122.Game

	$(MAKE) biglander x=65 z=65
	$(DISC) cp --recursive 5-compiled-game-discs/big-lander-65-65.adf:$$.RISC_OS.!BigLander 5-compiled-game-discs/big-lander.adf:$$.RISC_OS.65x65.!BigLander
	$(DISC) cp --recursive 5-compiled-game-discs/big-lander-13-11.adf:$$.Arthur.Game 5-compiled-game-discs/big-lander.adf:$$.Arthur.65x65.Game
	$(DISC) cp --recursive 5-compiled-game-discs/big-lander-13-11.adf:$$.Arthur.Library 5-compiled-game-discs/big-lander.adf:$$.Arthur.Library

  ifeq ($(OS), Windows_NT)
	del q /f  5-compiled-game-discs\big-lander-13-11.adf
	del q /f  5-compiled-game-discs\big-lander-20-20.adf
	del q /f  5-compiled-game-discs\big-lander-65-65.adf
	del q /f  5-compiled-game-discs\big-lander-122-122.adf
  else
	rm -fr 5-compiled-game-discs/big-lander-13-11.adf
	rm -fr 5-compiled-game-discs/big-lander-20-20.adf
	rm -fr 5-compiled-game-discs/big-lander-65-65.adf
	rm -fr 5-compiled-game-discs/big-lander-122-122.adf
  endif
endif

.PHONY:biglander
biglander:
	@$(PYTHON) 2-build-files/convert-to-vasm.py

ifeq ($(OS), Windows_NT)
	if exist 5-compiled-game-discs\adfs rmdir /s /q 5-compiled-game-discs\adfs
	mkdir 5-compiled-game-discs\adfs
	mkdir 5-compiled-game-discs\adfs\Arthur
	mkdir 5-compiled-game-discs\adfs\Arthur\Game
	mkdir 5-compiled-game-discs\adfs\Arthur\Library
	mkdir 5-compiled-game-discs\adfs\RISC_OS
	mkdir 5-compiled-game-discs\adfs\RISC_OS\!BigLander
else
	rm -fr 5-compiled-game-discs/adfs
	mkdir 5-compiled-game-discs/adfs
	mkdir 5-compiled-game-discs/adfs/Arthur
	mkdir 5-compiled-game-discs/adfs/Arthur/Game
	mkdir 5-compiled-game-discs/adfs/Arthur/Library
	mkdir 5-compiled-game-discs/adfs/RISC_OS
	mkdir 5-compiled-game-discs/adfs/RISC_OS/!BigLander
endif

	$(VASM) -a2 -m2 -quiet -Fbin -DTILES_X=${x} -DTILES_Z=${z} -L 3-assembled-output/compile.txt -o 3-assembled-output/GameCode.bin 3-assembled-output/Lander.arm

ifeq ($(OS), Windows_NT)
	copy "1-source-files\other-sources\arthur\BigLander,ffb" "5-compiled-game-discs\adfs\Arthur\Game\BigLander,ffb"
	copy 3-assembled-output\GameCode.inf 5-compiled-game-discs\adfs\Arthur\Game\GameCode.inf
	copy 3-assembled-output\GameCode.bin 5-compiled-game-discs\adfs\Arthur\Game\GameCode
	copy "1-source-files\other-sources\arthur\UseDeskTop,ffe" "5-compiled-game-discs\adfs\Arthur\Library\UseDeskTop,ffe"
	copy "1-source-files\other-sources\arthur\UseGame,ffe" "5-compiled-game-discs\adfs\Arthur\Library\UseGame,ffe"
else
	cp 1-source-files/other-sources/arthur/BigLander,ffb 5-compiled-game-discs/adfs/Arthur/Game/BigLander,ffb
	cp 3-assembled-output/GameCode.inf 5-compiled-game-discs/adfs/Arthur/Game/GameCode.inf
	cp 3-assembled-output/GameCode.bin 5-compiled-game-discs/adfs/Arthur/Game/GameCode
	cp 1-source-files/other-sources/arthur/UseDeskTop,ffe 5-compiled-game-discs/adfs/Arthur/Library/UseDeskTop,ffe
	cp 1-source-files/other-sources/arthur/UseGame,ffe 5-compiled-game-discs/adfs/Arthur/Library/UseGame,ffe
endif

	@$(PYTHON) 2-build-files/export-symbols.py

	cp 1-source-files/other-sources/riscos/!Help,fff 3-assembled-output/!Help,fff
	echo "\n\nBuild: $$(date +%Y-%m-%d\ %H-%M-%S)" >> 3-assembled-output/!Help,fff
	echo "\nTile corners: TILES_X = ${x}" >> 3-assembled-output/!Help,fff
	echo "              TILES_Z = ${z}" >> 3-assembled-output/!Help,fff
	echo "\nTo get the number of tiles in each direction," >> 3-assembled-output/!Help,fff
	echo "subtract 1 from the number of tile corners." >> 3-assembled-output/!Help,fff

	$(VASM) -a2 -m2 -quiet -Fbin -L 3-assembled-output/compile-RunImage.txt -o 3-assembled-output/!RunImage.bin 3-assembled-output/RunImage.arm

ifeq ($(OS), Windows_NT)
	copy "3-assembled-output\!Run,feb" "5-compiled-game-discs\adfs\RISC_OS\!BigLander\!Run,feb"
	copy "1-source-files\other-sources\riscos\!Sprites,ff9" "5-compiled-game-discs\adfs\RISC_OS\!BigLander\!Sprites,ff9"
	copy 3-assembled-output\!RunImage.bin "5-compiled-game-discs\adfs\RISC_OS\!BigLander\!RunImage,ff8"
	copy "3-assembled-output\!Help,fff" "5-compiled-game-discs\adfs\RISC_OS\!BigLander\!Help,fff"
else
	cp 3-assembled-output/!Run,feb 5-compiled-game-discs/adfs/RISC_OS/!BigLander/!Run,feb
	cp 1-source-files/other-sources/riscos/!Sprites,ff9 5-compiled-game-discs/adfs/RISC_OS/!BigLander/!Sprites,ff9
	cp 3-assembled-output/!RunImage.bin 5-compiled-game-discs/adfs/RISC_OS/!BigLander/!RunImage,ff8
	cp 3-assembled-output/!Help,fff 5-compiled-game-discs/adfs/RISC_OS/!BigLander/!Help,fff
endif

	@$(PYTHON) 2-build-files/convert-to-basic.py ${x} ${z}

	$(DISC) create 5-compiled-game-discs/big-lander-${x}-${z}.adf --title "BigLander" --geometry e
	$(DISC) import 5-compiled-game-discs/big-lander-${x}-${z}.adf 5-compiled-game-discs/adfs

	$(DISC) chmod --recursive 5-compiled-game-discs/big-lander-${x}-${z}.adf:$$.* WR/
	$(DISC) set-datestamp --recursive 5-compiled-game-discs/big-lander-${x}-${z}.adf:$$.* now
	$(DISC) put --force 5-compiled-game-discs/big-lander-${x}-${z}.adf:$$.Arthur.Game.Gamecode 5-compiled-game-discs/adfs/Arthur/Game/Gamecode 

ifeq ($(OS), Windows_NT)
	rmdir /s /q 5-compiled-game-discs\adfs
else
	rm -fr 5-compiled-game-discs/adfs
endif

	@$(PYTHON) 2-build-files/crc32.py 4-reference-binaries 3-assembled-output

deploy:
	scp 5-compiled-game-discs/zip/!BigLander.zip ${LANDER_PATH}
