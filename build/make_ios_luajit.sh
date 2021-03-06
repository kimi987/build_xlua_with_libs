cd "$( dirname "${BASH_SOURCE[0]}" )"
LIPO="xcrun -sdk iphoneos lipo"
STRIP="xcrun -sdk iphoneos strip"

IXCODE=`xcode-select -print-path`
ISDK=$IXCODE/Platforms/iPhoneOS.platform/Developer
ISDKVER=iPhoneOS.sdk
ISDKP=$IXCODE/usr/bin/

if [ ! -e $ISDKP/ar ]; then 
  sudo cp /usr/bin/ar $ISDKP
fi

if [ ! -e $ISDKP/ranlib ]; then
  sudo cp /usr/bin/ranlib $ISDKP
fi

if [ ! -e $ISDKP/strip ]; then
  sudo cp /usr/bin/strip $ISDKP
fi

cd luajit-master

XCODEVER=`xcodebuild -version|head -n 1|sed 's/Xcode \([0-9]*\)/\1/g'`
ISOLD_XCODEVER=`echo "$XCODEVER < 10" | bc`
if [ ISOLD_XCODEVER == 1 ]
then
    MACOSX_DEPLOYMENT_TARGET="10.12" LDFLAGS="-isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX10.12.sdk" make clean
    ISDKF="-arch armv7 -isysroot $ISDK/SDKs/$ISDKVER -miphoneos-version-min=7.0 -DLJ_NO_SYSTEM=1"
    MACOSX_DEPLOYMENT_TARGET="10.12" LDFLAGS="-isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX10.12.sdk" make HOST_CC="gcc -m32 -std=c99" TARGET_FLAGS="$ISDKF" TARGET=armv7 TARGET_SYS=iOS LUAJIT_A=libxluav7.a
    
    
    MACOSX_DEPLOYMENT_TARGET="10.12" LDFLAGS="-isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX10.12.sdk" make clean
    ISDKF="-arch armv7s -isysroot $ISDK/SDKs/$ISDKVER -miphoneos-version-min=7.0 -DLJ_NO_SYSTEM=1"
    MACOSX_DEPLOYMENT_TARGET="10.12" LDFLAGS="-isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX10.12.sdk" make HOST_CC="gcc -m32 -std=c99" TARGET_FLAGS="$ISDKF" TARGET=armv7s TARGET_SYS=iOS LUAJIT_A=libxluav7s.a
fi

MACOSX_DEPLOYMENT_TARGET="10.12" LDFLAGS="-isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX10.12.sdk" make clean
ISDKF="-arch arm64 -isysroot $ISDK/SDKs/$ISDKVER -miphoneos-version-min=7.0 -DLJ_NO_SYSTEM=1"
MACOSX_DEPLOYMENT_TARGET="10.12" LDFLAGS="-isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX10.12.sdk" make HOST_CC="gcc -std=c99" TARGET_FLAGS="$ISDKF" TARGET=arm64 TARGET_SYS=iOS LUAJIT_A=libxlua64.a

cd src
if [ ISOLD_XCODEVER == 1 ]
then
    lipo libxluav7.a -create libxluav7s.a libxlua64.a -output libluajit.a
else
    mv libxlua64.a libluajit.a
fi
cd ../..

mkdir -p build_lj_ios && cd build_lj_ios
cmake -DUSING_LUAJIT=ON -DLUAC_COMPATIBLE_FORMAT=ON -DPBC=ON -DCMAKE_TOOLCHAIN_FILE=../cmake/ios.toolchain.cmake -DPLATFORM=OS64  -GXcode ../
cd ..
cmake --build build_lj_ios --config Release

mkdir -p plugin_luajit/Plugins/iOS/
libtool -static -o plugin_luajit/Plugins/iOS/libxlua.a build_lj_ios/Release-iphoneos/libxlua.a luajit-master/src/libluajit.a
