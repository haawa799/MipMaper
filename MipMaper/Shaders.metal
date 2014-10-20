//
//  Reflect.metal
//  MetalKernelsPG
//
//  Created by Andrew K. on 8/1/14.
//  Copyright (c) 2014 Andrew K. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


kernel void populateMipmapLevels(texture2d<float, access::read> src [[ texture(0) ]],
                       texture2d<float, access::write> dst [[ texture(1) ]],
                       const device int&  mipmapLevel [[ buffer(0) ]],
                       uint2 gid [[ thread_position_in_grid]])
{
//  int mipLvls = dst.get_num_mip_levels();
  
  int mip = mipmapLevel;
  
  float4 a = src.read(uint2(gid.x * 2, gid.y * 2),mip-1);
  float4 b = src.read(uint2(gid.x * 2 + 1, gid.y * 2),mip-1);
  float4 c = src.read(uint2(gid.x * 2, gid.y * 2 + 1),mip-1);
  float4 d = src.read(uint2(gid.x * 2 + 1, gid.y * 2 + 1),mip-1);
  
  float4 resultPix = (a+b+c+d)/4;
  
  dst.write(resultPix, gid, mip);
}
