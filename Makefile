VASM?=vasmarm_std
PYTHON?=python

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

ifndef x
  x=65
endif

ifndef z
  z=65
endif

.PHONY:all
all:
	@$(PYTHON) 2-build-files/convert-to-vasm.py

	rm -fr 5-compiled-game-discs/arthur/Game/*
	rm -fr 5-compiled-game-discs/riscos/!BigLander/*
	rm -fr 5-compiled-game-discs/zip/*

	$(VASM) -a2 -m2 -quiet -Fbin -DTILES_X=${x} -DTILES_Z=${z} -L 3-assembled-output/compile.txt -o 3-assembled-output/GameCode.bin 3-assembled-output/Lander.arm
	cp 3-assembled-output/GameCode.inf 5-compiled-game-discs/arthur/Game/GameCode.inf
	cp 1-source-files/other-sources/arthur/BigLander,ffb 5-compiled-game-discs/arthur/Game/BigLander,ffb
	cp 3-assembled-output/GameCode.bin 5-compiled-game-discs/arthur/Game/GameCode

	@$(PYTHON) 2-build-files/export-symbols.py

	cp 1-source-files/other-sources/riscos/!Help,fff 3-assembled-output/!Help,fff
	echo "\n\nBuild: $$(date +%Y-%m-%d\ %H-%M-%S)" >> 3-assembled-output/!Help,fff
	echo "\nTiles: TILES_X = ${x}" >> 3-assembled-output/!Help,fff
	echo "       TILES_Z = ${z}" >> 3-assembled-output/!Help,fff

	$(VASM) -a2 -m2 -quiet -Fbin -L 3-assembled-output/compile-RunImage.txt -o 3-assembled-output/!RunImage.bin 3-assembled-output/RunImage.arm
	cp 3-assembled-output/!Run,feb 5-compiled-game-discs/riscos/!BigLander/!Run,feb
	cp 1-source-files/other-sources/riscos/!Sprites,ff9 5-compiled-game-discs/riscos/!BigLander/!Sprites,ff9
	cp 3-assembled-output/!Help,fff 5-compiled-game-discs/riscos/!BigLander/!Help,fff
	cp 3-assembled-output/!RunImage.bin 5-compiled-game-discs/riscos/!BigLander/!RunImage,ff8

	@$(PYTHON) 2-build-files/convert-to-basic.py ${x} ${z}
	cp 3-assembled-output/LanderSrc,fff 5-compiled-game-discs/BLanderSrc,fff

	cp -r 5-compiled-game-discs/riscos/!BigLander .
	zip -r \!BigLander.zip !BigLander -x "*/.*"
	mv \!BigLander.zip 5-compiled-game-discs/zip
	rm -fr \!BigLander

	cp -r 5-compiled-game-discs/arthur/Game .
	zip -r Game.zip Game -x "*/.*"
	mv Game.zip 5-compiled-game-discs/zip
	rm -fr Game

	@$(PYTHON) 2-build-files/crc32.py 4-reference-binaries 3-assembled-output

deploy:
	scp 5-compiled-game-discs/zip/!BigLander.zip ${LANDER_PATH}
