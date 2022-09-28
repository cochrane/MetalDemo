//
//  ShaderTypes.h
//  MetalDemo1 Shared
//
//  Created by Torsten Kammer on 26.09.22.
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
    simd_float2 position;
    simd_float2 texCoord;
} Vertex;

typedef NS_ENUM(EnumBackingType, BufferIndex)
{
    BufferIndexVertices = 0
};

typedef NS_ENUM(EnumBackingType, TextureIndex)
{
    TextureIndexColor = 0
};

#endif /* ShaderTypes_h */

