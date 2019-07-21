# Note Metal complier library should be on path
# export PATH="$PATH:/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/usr/bin" 
mkdir libs

xcrun -sdk macosx metal -Wall -Wextra -std=osx-metal2.0 AAPLBufferExamination.metal -o libs/AAPLBufferExamination.air
xcrun -sdk macosx metal-ar rcs libs/AAPLBufferExamination.metal-ar libs/AAPLBufferExamination.air
xcrun -sdk macosx metallib -o libs/AAPLBufferExamination.metallib libs/AAPLBufferExamination.metal-ar
rm -rf libs/AAPLBufferExamination.air
rm -rf libs/AAPLBufferExamination.metal-ar 

xcrun -sdk macosx metal -Wall -Wextra -std=osx-metal2.0 AAPLDirectionalLight.metal -o libs/AAPLDirectionalLight.air
xcrun -sdk macosx metal-ar rcs libs/AAPLDirectionalLight.metal-ar libs/AAPLDirectionalLight.air
xcrun -sdk macosx metallib -o libs/AAPLDirectionalLight.metallib libs/AAPLDirectionalLight.metal-ar
rm -rf libs/AAPLDirectionalLight.air
rm -rf libs/AAPLDirectionalLight.metal-ar 

xcrun -sdk macosx metal -Wall -Wextra -std=osx-metal2.0 AAPLFairy.metal -o libs/AAPLFairy.air
xcrun -sdk macosx metal-ar rcs libs/AAPLFairy.metal-ar libs/AAPLFairy.air
xcrun -sdk macosx metallib -o libs/AAPLFairy.metallib libs/AAPLFairy.metal-ar 
rm -rf libs/AAPLFairy.air
rm -rf libs/AAPLFairy.metal-ar

xcrun -sdk macosx metal -Wall -Wextra -std=osx-metal2.0 AAPLGBuffer.metal -o libs/AAPLGBuffer.air
xcrun -sdk macosx metal-ar rcs libs/AAPLGBuffer.metal-ar libs/AAPLGBuffer.air #| 
xcrun -sdk macosx metallib -o libs/AAPLGBuffer.metallib libs/AAPLGBuffer.metal-ar #| 
rm -rf libs/AAPLGBuffer.air
rm -rf libs/AAPLGBuffer.metal-ar 

xcrun -sdk macosx metal -Wall -Wextra -std=osx-metal2.0 AAPLPointLights.metal -o libs/AAPLPointLights.air
xcrun -sdk macosx metal-ar rcs libs/AAPLPointLights.metal-ar libs/AAPLPointLights.air
xcrun -sdk macosx metallib -o libs/AAPLPointLights.metallib libs/AAPLPointLights.metal-ar
rm -rf libs/AAPLPointLights.air
rm -rf libs/AAPLPointLights.metal-ar 

xcrun -sdk macosx metal -Wall -Wextra -std=osx-metal2.0 AAPLShadow.metal -o libs/AAPLShadow.air
xcrun -sdk macosx metal-ar rcs libs/AAPLShadow.metal-ar libs/AAPLShadow.air
xcrun -sdk macosx metallib -o libs/AAPLShadow.metallib libs/AAPLShadow.metal-ar
rm -rf libs/AAPLShadow.air
rm -rf libs/AAPLShadow.metal-ar 

xcrun -sdk macosx metal -Wall -Wextra -std=osx-metal2.0 AAPLSkybox.metal -o libs/AAPLSkybox.air
xcrun -sdk macosx metal-ar rcs libs/AAPLSkybox.metal-ar libs/AAPLSkybox.air
xcrun -sdk macosx metallib -o libs/AAPLSkybox.metallib libs/AAPLSkybox.metal-ar
rm -rf libs/AAPLSkybox.air
rm -rf libs/AAPLSkybox.metal-ar 



