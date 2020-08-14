##
#
# LZVN encode/decode routines
#
# Intel 64-bit (x86_64) version
#
##

PREFIX=/usr/local

AR=ar
CC=gcc
RANLIB=ranlib
INSTALL=install
CODESIGN=codesign
ARFLAGS=cru
CFLAGS=-g0 -arch arm64 -arch x86_64 -Ofast

### Change to "" for no signing or "Something: Me..." for signing ###
SIGNCERT="Apple Development"
# PKGSIGNCERT="Developer ID Installer: Andy Vandijck (GSF3NR4NQ5)"

all: lzvn

.c.o:
	$(CC) $(CFLAGS) -c $< -o $@

libFastCompression.a: lzvn_encode.o lzvn_decode.o
	$(AR) $(ARFLAGS) $@ lzvn_encode.o lzvn_decode.o
	$(RANLIB) libFastCompression.a

lzvn: lzvn.o libFastCompression.a
	$(CC) $(CFLAGS) -o $@ lzvn.o -L. -lFastCompression
	if [ $(SIGNCERT) != "" ]; then $(CODESIGN) -s $(SIGNCERT) $@; fi

clean:
	sudo rm -Rf *.o *.a lzvn lzvninst lzvnpkg Payload Bom lzvncombopkg lzvn.pkg lzvn-apple.pkg

install: lzvn.h
	$(INSTALL) lzvn $(PREFIX)/bin

installer:  libFastCompression.a lzvn
	sudo mkdir -p lzvninst/usr/bin
	sudo mkdir -p lzvninst/usr/lib
	sudo mkdir -p lzvninst/usr/include
	mkdir -p lzvnpkg
	mkdir -p lzvncombopkg
	sudo $(INSTALL) FastCompression.h lzvninst/usr/include/FastCompression.h
	sudo $(INSTALL) libFastCompression.a lzvninst/usr/lib/libFastCompression.a
	sudo $(INSTALL) lzvn lzvninst/usr/bin/lzvn
	sudo chown -R root:wheel lzvninst
	cd lzvninst && sudo rm -f .DS_Store */.DS_Store */*/.DS_Store && sudo cpio -o < ../lzvn_pkg.txt > ../lzvnpkg/Payload && sudo rm -f .DS_Store */.DS_Store */*/.DS_Store && sudo mkbom . ../lzvnpkg/Bom && cd ..
	sudo rm -Rf lzvninst
	sudo cp -Rf PackageInfo lzvnpkg/PackageInfo
	cd lzvnpkg && sudo rm -Rf .DS_Store && sudo xar -cjf ../lzvncombopkg/lzvn-1.0.pkg . && cd ..
	sudo rm  -Rf lzvnpkg Payload Bom
	if [ $(PKGSIGNCERT) != "" ]; then sudo productsign --sign $(PKGSIGNCERT) lzvncombopkg/lzvn-1.0.pkg lzvncombopkg/lzvn-1.0-apple.pkg && sudo rm -Rf lzvncombopkg/lzvn-1.0.pkg; else mv lzvncombopkg/lzvn-1.0.pkg lzvncombopkg/lzvn-1.0-apple.pkg; fi
	sudo cp -Rf Resources lzvncombopkg/Resources
	sudo cp -f Distribution lzvncombopkg/Distribution
	cd lzvncombopkg &&  sudo rm -Rf .DS_Store */.DS_Store */*/.DS_Store && sudo productbuild --distribution Distribution --resources Resources --package-path $(PWD) ../lzvn-apple.pkg && cd ..
	sudo rm -Rf lzvncombopkg
	if [ $(PKGSIGNCERT) != "" ]; then sudo productsign --sign $(PKGSIGNCERT) lzvn-apple.pkg lzvn.pkg && sudo rm -Rf lzvn-apple.pkg; else mv lzvn-apple.pkg lzvn.pkg; fi

