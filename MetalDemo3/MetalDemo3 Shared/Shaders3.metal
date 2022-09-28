//
//  Shaders.metal
//  MetalDemo3 Shared
//
//  Created by Torsten Kammer on 28.09.22.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes3.h"

typedef struct
{
    float4 position [[position]];
    float2 texCoord;
} RasterizerData;

vertex RasterizerData vertexShader(uint inIndex [[ vertex_id ]],
                               constant Vertex *vertices [[ buffer(BufferIndexVertices) ]])
{
    constant Vertex &in = vertices[inIndex];
    
    RasterizerData out;
    
    out.position = float4(in.position.x, in.position.y, 0.0, 1.0);
    out.texCoord = in.texCoord;
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]],
                               metal::texture2d<float> color [[ texture(TextureIndexColor) ]])
{
    constexpr metal::sampler textureSampler(metal::mag_filter::linear, metal::mip_filter::linear);
    
    return color.sample(textureSampler, in.texCoord);
}
