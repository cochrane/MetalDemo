//
//  ShaderTypes.h
//  MetalDemo2 Shared
//
//  Created by Torsten Kammer on 28.09.22.
//

//
//  Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
//
#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
typedef metal::int32_t EnumBackingType;
#else
#import <Foundation/Foundation.h>
typedef NSInteger EnumBackingType;
#endif

#include <simd/simd.h>

typedef struct {
    simd_float3 position;
    // For lighting
    simd_float3 normal;
} Vertex;

typedef NS_ENUM(EnumBackingType, BufferIndex)
{
    BufferIndexVertices = 0,
    BufferIndexMatrices
};

typedef struct {
    // For position
    matrix_float4x4 modelViewProjection;
    // For lighting
    matrix_float4x4 modelView;
} Matrices;

#endif /* ShaderTypes_h */

