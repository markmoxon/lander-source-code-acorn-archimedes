VASM?=vasmarm_std
PYTHON?=python

# The deploy target deploys !BigLander to a web server so archi.medes.live can load it
#
# LANDER_PATH should be set to the scp path of the server hosting the build
#
# e.g. export $LANDER_PATH=name@server.com:~/path/to
#
# Once deployed, you can load a URL like this to see the compiled game:
#
# https://archi.medes.live/#ff=14400&disc=https://server.com/path/to/!BigLander.zip&autoboot=desktop%20filer_opendir%20HostFS::HostFS.$

.PHONY:all
all:
	@$(PYTHON) 2-build-files/convert-to-vasm.py

	$(VASM) -a2 -m2 -quiet -Fbin -L 3-assembled-output/compile.txt -o 3-assembled-output/GameCode.bin 3-assembled-output/Lander.arm
	cp 3-assembled-output/GameCode.inf 5-compiled-game-discs/arthur/GameCode.inf
	cp 1-source-files/other-sources/arthur/BigLander,ffb 5-compiled-game-discs/arthur/BigLander,ffb
	cp 3-assembled-output/GameCode.bin 5-compiled-game-discs/arthur/GameCode

	@$(PYTHON) 2-build-files/export-symbols.py

	$(VASM) -a2 -m2 -quiet -Fbin -L 3-assembled-output/compile-RunImage.txt -o 3-assembled-output/!RunImage.unprot.bin 3-assembled-output/RunImage.arm
	cp 1-source-files/other-sources/riscos/!Run,feb 5-compiled-game-discs/riscos/!BigLander/!Run,feb
	cp 1-source-files/other-sources/riscos/!Sprites,ff9 5-compiled-game-discs/riscos/!BigLander/!Sprites,ff9
	cp 1-source-files/other-sources/riscos/MemAlloc,ffa 5-compiled-game-discs/riscos/!BigLander/MemAlloc,ffa
	cp 1-source-files/other-sources/riscos/!Help,fff 5-compiled-game-discs/riscos/!BigLander/!Help,fff
	cp 3-assembled-output/!RunImage.unprot.bin 5-compiled-game-discs/riscos/!BigLander/!RunImage,ff8

	@$(PYTHON) 2-build-files/crc32.py 4-reference-binaries 3-assembled-output

deploy:
	cp -r 5-compiled-game-discs/riscos/!BigLander .
	echo " " > T-$$(date +%H-%M-%S),fff
	zip -r \!BigLander.zip !BigLander T*
	scp \!BigLander.zip ${LANDER_PATH}
	rm -fr \!BigLander
	rm T*
	rm \!BigLander.zip
