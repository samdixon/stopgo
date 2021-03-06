# Makefile for StopGo Packaging.
## YOU DO NOT NEED THIS if you are just trying to use StopGo.
## This is only for developers who are 
## building packages to distribute.

PKGDIR = stopgo.AppDir
DOCDIR = usr/doc
PYTHON = python2.7
VLC    = python_vlc-1.1.2-py2.7.egg
CORE   = vlc-core-2.2.6-2.tar.xz
SIX    = six-1.10.0
PARTY  = thirdparty/linux
WX     = wxPython-src-2.8.12.1.tar.bz2
PNG    = libpng-1.4.12.tar.xz
JPG    = jpegsrc.v8a.tar.xz
CURVER := $(shell git describe --tags --exact-match --abbrev=0 || echo "No version found.")

PAT    = $(shell echo $(CURVER) | cut -f3 -d'.')
MIN    = $(shell echo $(CURVER) | cut -f2 -d'.')
MAJ    = $(shell echo $(CURVER) | cut -f1 -d'.')
NEW    = $(shell echo $$(( $(PAT) + 1 )) )

# define arch for thirdpartylibs
LBITS := $(shell getconf LONG_BIT)
ifeq ($(LBITS),64)
LIB = lib64
ARCH = x86_64
else
LIB = lib
ARCH = i386
endif
# no longer needed but keeping as ref for looping in makefile 
#onepm := libpng-1.5.13-5.el7.$(ARCH) \
#	jbigkit-libs-2.0-11.el7.$(ARCH)
#osrc  := $(foreach item,$(onepm),thirdparty/$(item).rpm )

help:
	@echo
	@echo "This is used by developers building packages to distribute."
	@echo "Assuming you're a developer:"
	@echo
	@echo "Please use 'make <target>' where <target> is one of..."
	@echo "  download : download thirdparty libs for linux       "
	@echo "  downwind : download thirdparty libs for windows     "
#	@echo "  all      : make packages for all supported platforms"
	@echo "  linux    : make AppImage for Linux "
	@echo "  windows  : make an .exe for Windows"
	@echo "  release  : new release"
#	@echo "  mac      : make a package for OS X "

all: linux windows mac

release:
	@sed -i 's/'$(MAJ)'.'$(MIN)'.'$(PAT)'/'$(MAJ)'.'$(MIN)'.'$(NEW)'/' usr/share/pyshared/stopgolibs/about.py
	@git tag $(MAJ).$(MIN).$(NEW)
	@echo "Patch version incremented to $(MAJ).$(MIN).$(NEW)"
	@echo "Commit and push changes now."

download:
	@echo 'Fetching thirdparty libraries'
	@wget --no-clobber http://mirror.crucial.com.au/slackware/slackware-14.1/source/l/libpng/$(PNG) -P thirdparty/linux
	@wget --no-clobber http://mirror.crucial.com.au/slackware/slackware-14.1/source/l/libjpeg/$(JPG) -P thirdparty/linux
	@wget --no-clobber http://downloads.sourceforge.net/wxpython/$(WX) -P thirdparty/linux
	@wget --no-clobber https://pypi.python.org/packages/2.7/p/python-vlc/$(VLC) -P $(PARTY)
	@git clone https://github.com/probonopd/AppImageKit.git thirdparty/AppImageKit.clone
	@echo "If you just downloaded a fresh copy, you need to go compile wxPython now."
	@echo "Complete!"

downwind:
	@echo 'Fetching thirdparty libraries for windows'
	@wget --no-clobber https://bootstrap.pypa.io/ez_setup.py -P thirdparty/windows/
	@wget --no-clobber "http://iweb.dl.sourceforge.net/project/nsis/NSIS 2/2.50/nsis-2.50-setup.exe" -P thirdparty/windows/
	@wget --no-clobber https://www.python.org/ftp/python/2.7.9/python-2.7.9.msi -P thirdparty/windows/
	@wget --no-clobber http://iweb.dl.sourceforge.net/project/wxpython/wxPython/3.0.2.0/wxPython3.0-win32-3.0.2.0-py27.exe -P thirdparty/windows/

linux: $(PARTY)/$(VLC)
	@gcc -o thirdparty/AppRun ~/code/AppImageKit.clone/AppRun.c
	#@sh ./genappdir.sh -a ./thirdparty/AppRun -i ./usr/share/icons/stopgo.png -d ./usr/share/applications/stopgo.desktop $(PKGDIR)
	@mkdir $(PKGDIR)
	@cp ./usr/share/applications/stopgo.desktop $(PKGDIR)
	@cp thirdparty/AppRun $(PKGDIR)
	@cp -rv ./usr $(PKGDIR)
	@convert ./usr/share/icons/hicolor/scalable/stopgo.svg -size 256x256 $(PKGDIR)/usr/share/icons/stopgo.png
	@convert ./usr/share/icons/hicolor/scalable/stopgo.svg -size 96x96 $(PKGDIR)/stopgo.png
	@mkdir -p $(PKGDIR)/$(DOCDIR)/stopgo
	@cp AUTHORS TODO COPYING $(PKGDIR)/$(DOCDIR)/stopgo
	@mkdir -p $(PKGDIR)/usr/$(LIB)/$(PYTHON)/site-packages/vlc
	@echo "vlc" > $(PKGDIR)/usr/$(LIB)/$(PYTHON)/site-packages/vlc.pth
	@unzip $(PARTY)/$(VLC) -d $(PKGDIR)/usr/$(LIB)/$(PYTHON)/site-packages/vlc/
	@mkdir -p $(PKGDIR)/usr/$(LIB)/$(PYTHON)/site-packages/six
	@tar xvf $(PARTY)/$(SIX).tar.gz $(SIX)/six.egg-info --strip-component 1
	@tar xvf $(PARTY)/$(SIX).tar.gz $(SIX)/six.py --strip-component 1
	@mv six.egg-info $(PKGDIR)/usr/$(LIB)/$(PYTHON)/site-packages/six/EGG-INFO
	@mv six.py $(PKGDIR)/usr/$(LIB)/$(PYTHON)/site-packages/six
	@echo "six" > $(PKGDIR)/usr/$(LIB)/$(PYTHON)/site-packages/six.pth
	@tar xvf $(PARTY)/$(CORE) -C $(PKGDIR)
# gotta build all the deps here
	@cd ..
	@find $(PKGDIR)/usr/lib64/ -type f -exec sed -i -e 's|/usr|././|g' {} \;
	@find $(PKGDIR)/usr/lib64/ -type f -exec sed -i -e 's|././/bin/env|/usr/bin/env|g' {} \;
	@find $(PKGDIR)/usr/lib64/ -type f -exec sed -i -e 's|././/bin/python|/usr/bin/python|g' {} \;
	@$(HOME)/bin/appimagetool-x86_64.AppImage $(PKGDIR)

mac:
	@echo "Support coming soon-ish."

clean:
	@rm -rf stopgo.AppDir
	@rm stopgo.AppImage || true

