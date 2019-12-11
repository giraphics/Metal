#ifndef COMMON_H
#define COMMON_H

#include <simd/simd.h>

enum VertexAttributes 
{
    VertexAttributePosition = 0,
    VertexAttributeColor = 1,
};

enum BufferIndex  
{
    FBODisplayQuadVertexBuffer = 0,
    FrameUniformBuffer = 1,
};

enum ViewportIndex  
{
    ViewportBuffer = 2
};

enum DeviceScaleFactorIndex  
{
    DeviceScaleFactorBuffer = 3
};

struct FrameUniforms 
{
    simd::float4x4 projectionViewModel;
};

struct FragUniforms
{
    simd::float2 dimension;
};

#endif
