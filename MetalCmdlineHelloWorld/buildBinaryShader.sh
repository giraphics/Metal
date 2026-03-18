# Note Metal complier library should be on path
# export PATH="$PATH:/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/usr/bin"

rm -f Shaders.air Shaders.metal-ar shaders.metallib

xcrun -sdk macosx metal -Wall -Wextra shaders.metal -o shaders.metallib
