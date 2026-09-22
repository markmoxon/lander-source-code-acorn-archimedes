VASM?=vasmarm_std
PYTHON?=python

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
	del /q /f 5-compiled-game-discs\arthur\Game\*
	del /q /f 5-compiled-game-discs\riscos\!Lander\*
	del /q /f 5-compiled-game-discs\zip\*
else
	rm -fr 5-compiled-game-discs/arthur/Game/*
	rm -fr 5-compiled-game-discs/riscos/!Lander/*
	rm -fr 5-compiled-game-discs/zip/*
endif

	$(VASM) -a2 -m2 -quiet -Fbin -L 3-assembled-output/compile.txt -o 3-assembled-output/GameCode.bin 3-assembled-output/Lander.arm

ifeq ($(OS), Windows_NT)
	copy 3-assembled-output\GameCode.inf 5-compiled-game-discs\arthur\Game\GameCode.inf
	copy "1-source-files\other-sources\arthur\Lander,ffb" "5-compiled-game-discs\arthur\Game\Lander,ffb"
	copy 3-assembled-output\GameCode.bin 5-compiled-game-discs\arthur\Game\GameCode
else
	cp 3-assembled-output/GameCode.inf 5-compiled-game-discs/arthur/Game/GameCode.inf
	cp 1-source-files/other-sources/arthur/Lander,ffb 5-compiled-game-discs/arthur/Game/Lander,ffb
	cp 3-assembled-output/GameCode.bin 5-compiled-game-discs/arthur/Game/GameCode
endif

	@$(PYTHON) 2-build-files/export-symbols.py

	$(VASM) -a2 -m2 -quiet -Fbin -L 3-assembled-output/compile-RunImage.txt -o 3-assembled-output/!RunImage.bin 3-assembled-output/RunImage.arm

ifeq ($(OS), Windows_NT)
	copy "1-source-files\other-sources\riscos\!Run,feb" "5-compiled-game-discs\riscos\!Lander\!Run,feb"
	copy "1-source-files\other-sources\riscos\!Sprites,ff9" "5-compiled-game-discs\riscos\!Lander\!Sprites,ff9"
	copy "1-source-files\other-sources\riscos\MemAlloc,ffa" "5-compiled-game-discs\riscos\!Lander\MemAlloc,ffa"
	copy 3-assembled-output\!RunImage.bin "5-compiled-game-discs\riscos\!Lander\!RunImage,ff8"
else
	cp 1-source-files/other-sources/riscos/!Run,feb 5-compiled-game-discs/riscos/!Lander/!Run,feb
	cp 1-source-files/other-sources/riscos/!Sprites,ff9 5-compiled-game-discs/riscos/!Lander/!Sprites,ff9
	cp 1-source-files/other-sources/riscos/MemAlloc,ffa 5-compiled-game-discs/riscos/!Lander/MemAlloc,ffa
	cp 3-assembled-output/!RunImage.bin 5-compiled-game-discs/riscos/!Lander/!RunImage,ff8
endif

	@$(PYTHON) 2-build-files/convert-to-basic.py

ifeq ($(OS), Windows_NT)
	copy "3-assembled-output\LanderSrc,fff" "5-compiled-game-discs\LanderSrc,fff"

	xcopy /q /y /i 5-compiled-game-discs\riscos\!Lander !Lander
	tar -ca --exclude ".*" -f !Lander.zip !Lander
	move !Lander.zip "5-compiled-game-discs\zip\"
	rmdir /q /s !Lander

	xcopy /q /y /i 5-compiled-game-discs\arthur\Game Game
	tar -ca --exclude ".*" -f Game.zip Game
	move Game.zip "5-compiled-game-discs\zip\"
	rmdir /q /s Game
else
	cp 3-assembled-output/LanderSrc,fff 5-compiled-game-discs/LanderSrc,fff

	cp -r 5-compiled-game-discs/riscos/!Lander .
	zip -r \!Lander.zip !Lander -x "*/.*"
	mv \!Lander.zip 5-compiled-game-discs/zip
	rm -fr \!Lander

	cp -r 5-compiled-game-discs/arthur/Game .
	zip -r Game.zip Game -x "*/.*"
	mv Game.zip 5-compiled-game-discs/zip
	rm -fr Game
endif

	@$(PYTHON) 2-build-files/crc32.py 4-reference-binaries 3-assembled-output

deploy:
	scp 5-compiled-game-discs/zip/!Lander.zip ${LANDER_PATH}
