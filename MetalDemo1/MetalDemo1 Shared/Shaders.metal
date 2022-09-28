//
//  Shaders.metal
//  MetalDemo1 Shared
//
//  Created by Torsten Kammer on 26.09.22.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"

using namespace metal;

typedef struct
{
    float4 position [[position]];
} RasterizerData;

vertex RasterizerData vertexShader(uint inIndex [[ vertex_id ]],
                               constant Vertex *vertices [[ buffer(BufferIndexVertices) ]])
{
    constant Vertex &in = vertices[inIndex];
    
    RasterizerData out;
    
    out.position = float4(in.position.x, in.position.y, 0.0, 1.0);
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    return float4(1.0f, 0.0f, 0.0f, 1.0f);
}
