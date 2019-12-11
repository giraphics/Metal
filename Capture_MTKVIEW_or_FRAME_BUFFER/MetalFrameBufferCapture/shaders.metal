#include <simd/simd.h>
#include "common.h"
#include <metal_stdlib>

using namespace metal;
constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);

struct VertexInput 
{
    float3 position [[ attribute(VertexAttributePosition) ]];
    float2 color    [[ attribute(VertexAttributeColor)    ]];
};

struct ShaderInOut 
{
    float4 position [[position]];
    float2 color;
};

vertex ShaderInOut vert(VertexInput in            [[ stage_in                   ]],
	   constant FrameUniforms& uniforms           [[ buffer(FrameUniformBuffer) ]],
       constant vector_uint2 *viewportSizePointer [[ buffer(ViewportBuffer)     ]]) 
{
    float4 pos4     = float4(in.position.xy, 1.0, 1.0);

    ShaderInOut out;
    out.position    = uniforms.projectionViewModel * pos4;
    out.color       = in.color;

    return out;
}

fragment float4 frag(ShaderInOut in                     [[ stage_in   ]],
                     constant FragUniforms& fragUniform [[ buffer(0)  ]],
                     texture2d<half> colorTexture       [[ texture(0) ]]) 
{
    vector_float2 textureCoordinate;
    textureCoordinate.x = in.color.x;
    textureCoordinate.y = in.color.y;
    return float4(colorTexture.sample(textureSampler, textureCoordinate));
}