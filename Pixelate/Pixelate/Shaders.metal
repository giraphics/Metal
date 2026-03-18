//
//  Shaders.metal
//  Pixelate

#include <metal_stdlib>

using namespace metal;

//kernel void pixelate(device unsigned char*  inBuffer    [[buffer (1)]],
//                     device unsigned char*  outBuffer   [[buffer (0)]],
//                     uint id [[thread_position_in_grid]])
//{
//    outBuffer[id] = inBuffer[id];
//}

using namespace metal;

kernel void pixelate(device unsigned int*  inBuffer    [[buffer (1)]],
                     device unsigned int*  outBuffer   [[buffer (0)]],
                     uint2 gid [[thread_position_in_grid]])
{
    uint pixelate = 10;
    const uint2 pixellateGrid = uint2((gid.x / pixelate) * pixelate, (gid.y / pixelate) * pixelate);
    //const float4 colorAtPixel = inTexture.read(pixellateGrid);
    const unsigned int colorAtPixel = inBuffer[pixellateGrid.y * 512 + pixellateGrid.x];
    
    
    // Pixelate result
    outBuffer[(gid.y) * 512 + gid.x] = colorAtPixel;
}

