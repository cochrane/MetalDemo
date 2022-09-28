//
//  Shaders.metal
//  MetalDemo2 Shared
//
//  Created by Torsten Kammer on 28.09.22.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes2.h"

using namespace metal;

typedef struct
{
    float4 position [[position]];
    float3 normal;
} RasterizerData;

vertex RasterizerData vertexShader(uint inIndex [[ vertex_id ]],
                               constant Vertex *vertices [[ buffer(BufferIndexVertices) ]],
                               constant Matrices &matrices [[ buffer(BufferIndexMatrices) ]])
{
    constant Vertex &in = vertices[inIndex];
    
    RasterizerData out;
    
    out.position = matrices.modelViewProjection * float4(in.position, 1.0);
    out.normal = (matrices.modelView * float4(in.normal, 0.0)).xyz;
    
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    float3 lightDirection = normalize(float3(-2.0f, 4.0f, -5.0f));
    float diffuseFactor = dot(lightDirection, normalize(in.normal));
    float4 diffuse = diffuseFactor * float4(1.0, 1.0, 1.0, 1.0);
    
    float4 ambient = float4(0.2, 0.2, 0.2, 1.0);
    
    return ambient + diffuseFactor * diffuse;
}
