#!/bin/bash

KICAD_SRC_DIR=kicad
KICAD_SRC_DOC_DIR=kicad-doc
KICAD_SRC_LIBRARY_DIR=kicad-library
KICAD_SRC_WXWIDGETS_DIR=wxWidgets-3.0.2

KICAD_BUILD_DIR=build
KICAD_BUILD_DOC_DIR=build-doc
KICAD_BUILD_LIBRARY_DIR=build-library

KICAD_INSTALL_DIR=~/Applications/kicad
KICAD_INSTALL_DOCS_DIR=~/Applications/kicad
KICAD_INSTALL_LIBRARY_DIR=~/

KICAD_APP_DIR=~/Applications/kicad
KICAD_APP_LIBRARY_DIR=~/Library/Application\ Support/kicad

KICAD_BIN_DIR=wx-bin

function remove_brew {
	cd `brew --prefix`
	git checkout master
	git ls-files -z | pbcopy
	rm -rf Cellar
	bin/brew prune
	pbpaste | xargs -0 rm

	rm -r Library/Homebrew 
	rm -r Library/Aliases 
	rm -r Library/Formula 
	rm -r Library/Contributions 
	test -d Library/LinkedKegs && rm -r Library/LinkedKegs
	rmdir -p bin Library share/man/man1 2> /dev/null

	rm -rf .git
	rm -rf ~/Library/Caches/Homebrew
	rm -rf ~/Library/Logs/Homebrew
	sudo rm -rf /Library/Caches/Homebrew
}

function remove_kicad {
	mv $KICAD_SRC_DIR ~/.Trash
	mv $KICAD_SRC_DOC_DIR ~/.Trash
	mv $KICAD_SRC_LIBRARY_DIR ~/.Trash
	mv $KICAD_BUILD_DIR ~/.Trash
	mv $KICAD_BUILD_DOC_DIR ~/.Trash
	mv $KICAD_BUILD_LIBRARY_DIR ~/.Trash
	mv $KICAD_SRC_WXWIDGETS_DIR ~/.Trash
	mv $KICAD_BIN_DIR ~/.Trash
	mv $KICAD_APP_DIR ~/.Trash
	mv $KICAD_APP_LIBRARY_DIR ~/.Trash
}

function get_brew {
	ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

	brew doctor
	brew prune
	brew install cmake
	brew install bzr
	brew install glew
	brew install swig
	brew install doxygen
	brew install python
	brew install cairo
	brew update
}

function get_src {
	bzr whoami "Rohit Priyadarshi <rohit@rishkan.com>"

	# Get KiCad sources
	bzr branch lp:$KICAD_SRC_DIR
	bzr branch lp:~kicad-developers/kicad/doc  
	mv doc $KICAD_SRC_DOC_DIR
	git clone https://github.com/KiCad/$KICAD_SRC_LIBRARY_DIR

	# Manually get wxWidgets
	tar xvfj ~/Downloads/$KICAD_SRC_WXWIDGETS_DIR.tar.bz2

	mkdir $KICAD_BUILD_DIR
	mkdir $KICAD_BUILD_DOC_DIR
	mkdir $KICAD_BUILD_LIBRARY_DIR

	sed -i -- 's/WebKit.h/WebKitLegacy.h/g' $KICAD_SRC_WXWIDGETS_DIR/src/osx/webview_webkit.mm
}

function build_wxwidgets {
	sh $KICAD_SRC_DIR/scripts/osx_build_wx.sh $KICAD_SRC_WXWIDGETS_DIR wx-bin kicad 10.10 "-j4"
}

function build_kicad {
	cd $KICAD_BUILD_DIR
	export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/opt/X11/lib/pkgconfig
	cmake ../$KICAD_SRC_DIR -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DwxWidgets_CONFIG_EXECUTABLE=../wx-bin/bin/wx-config -DKICAD_SCRIPTING=OFF -DKICAD_SCRIPTING_MODULES=OFF -DKICAD_SCRIPTING_WXPYTHON=OFF -DCMAKE_INSTALL_PREFIX=$KICAD_INSTALL_DIR -DBUILD_GITHUB_PLUGIN=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_DEPLOYMENT_TARGET=10.10
	sed -i -- 's/\-framework\ cairo/\-L\/usr\/local\/lib\ \-lcairo/g' pcbnew/CMakeFiles/pcbnew_kiface.dir/link.txt
	make
	make install
	cd ..
}

function build_kicad_docs {
	cd $KICAD_BUILD_DOC_DIR
	cmake ../$KICAD_SRC_DOC_DIR -DCMAKE_INSTALL_PREFIX=$KICAD_INSTALL_DOCS_DIR -DBUILD_GITHUB_PLUGIN=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_DEPLOYMENT_TARGET=10.10
	make
	make install
	cd ..
}

function build_kicad_library {
	cd $KICAD_BUILD_LIBRARY_DIR
	cmake ../$KICAD_SRC_LIBRARY_DIR -DCMAKE_INSTALL_PREFIX=$KICAD_INSTALL_LIBRARY_DIR -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_DEPLOYMENT_TARGET=10.10
	make
	make install
	cd ..
}

function remove_all {
	remove_brew
	remove_kicad
}

function get_all {
	get_brew
	get_src
}

function build_all {
	build_wxwidgets
	build_kicad
	build_kicad_docs
	build_kicad_library
}

function rebuild_all {
	remove_all
	get_all
	build_all
}

function help {
	echo "Options --"
	echo "  Micro options -"
	echo "    --remove_brew         - Completely remove brew"
	echo "    --remove_kicad        - Completely remove kicad"
	echo "    --get_brew            - Download and setup brew"
	echo "    --get_src             - Get all kicad sources and extract wxWidgets"
	echo "    --build_wxwidgets     - Build wxWidgets with minor edits"
	echo "    --build_kicad         - Build kicad with minor edits"
	echo "    --build_kicad_docs    - Build docs and install"
	echo "    --build_kicad_library - Build kicad library and install"
	echo "  Macro options -"
	echo "    --remove_all          - Removes brew and kicad"
	echo "    --get_all             - Gets brew and kicad"
	echo "    --build_all           - Builds and installs brew and kicad"
	echo "    --rebuild_all         - Clean install of brew and kicad"
}

for i in "$@"
do
case $i in
    --remove_brew)
		remove_brew
		shift
    	;;
    --remove_kicad)
		remove_kicad
		shift
    	;;
    --get_brew)
		get_brew
		shift
    	;;
    --get_src)
		get_src
		shift
    	;;
    --build_wxwidgets)
		build_wxwidgets
		shift
    	;;
    --build_kicad)
		build_kicad
		shift
    	;;
    --build_kicad_docs)
		build_kicad_docs
		shift
    	;;
    --build_kicad_library)
		build_kicad_library
    	shift
    	;;
    --remove_all)
    	remove_all
		shift
    	;;
    --get_all)
    	get_all
		shift
    	;;
    --build_all)
    	build_all
		shift
    	;;
    --rebuild_all)
    	rebuild_all
		shift
    	;;
    --help)
    	help
		shift
    	;;
    *)
        # unknown option
    	;;
esac
done
