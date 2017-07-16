# Note Metal complier library should be on path
# export PATH="$PATH:/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/usr/bin" 
xcrun -sdk macosx metal -Wall -Wextra -std=osx-metal1.1 Shaders.metal -o Shaders.air
xcrun -sdk macosx metal-ar rcs Shaders.metal-ar Shaders.air
xcrun -sdk macosx metallib -o shaders.metallib Shaders.metal-ar
